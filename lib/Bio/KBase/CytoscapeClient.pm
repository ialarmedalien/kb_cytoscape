package Bio::KBase::CytoscapeClient;

use strict;
use warnings;
use feature qw( say );
use Data::Dumper::Concise;

use Moo;
use Bio::KBase::Exceptions;
use Bio::KBase::Config;
use Bio::KBase::RelationEngine::Client;
use Bio::KBase::Templater qw( render_template );
use installed_clients::KBaseReportClient;

use Try::Tiny;
use Path::Tiny;
use Ref::Util qw( :all );
use Data::UUID;
use JSON::MaybeXS;
use JSON::Validator;
use JSON::Validator::Util qw( data_type );
use Test::Deep::NoTest;

has config => (
    is      => 'lazy',
    builder => 1,
);

sub _build_config {
    Bio::KBase::Config->instance;
}

has kb_report_client => (
    is      => 'lazy',
    builder => 1,
);

sub _build_kb_report_client {
    my $self = shift;
    # this will die if $self->config->callback_url is not set
    return installed_clients::KBaseReportClient->new( $self->config->callback_url );
}

has re_client => (
    is      => 'lazy',
    builder => 1,
);

sub _build_re_client {
    Bio::KBase::RelationEngine::Client->new;
}

# template file for generating the cytoscape viewer page
has cytoscape_template_path => (
    is      => 'lazy',
    builder => 1,
);

sub _build_cytoscape_template_path {
    path( shift->config->app_dir, 'views', 'cytoscape.tt' )
}

has run_uuid => (
    is      => 'lazy',
    builder => 1,
);

sub _build_run_uuid {
    Data::UUID->new->create_str;
};

has run_directory => (
    is      => 'lazy',
    builder => 1,
);

sub _build_run_directory {
    my ( $self ) = @_;
    path( $self->config->scratch, $self->run_uuid )->mkpath;
    return path( $self->config->scratch, $self->run_uuid );
}

=head1 NAME

Bio::KBase::CytoscapeClient

=head1 DESCRIPTION

Runner for the Cytoscape workflow

=cut


=head2 run

Run the query, generate results, and then create a report from the output!

@param {hashref} $params    # input from the app

@return {hashref} (anon)    # hashref containing report_ref, report_name, and
                            # the query_params sent to the database API

=cut

sub run {
    my ( $self, $params ) = @_;

    die 'Invalid parameter format: parameters must be a hashref' unless defined $params && is_hashref $params;

    my $workspace_id = delete $params->{ workspace_id }
        or die 'No workspace ID provided: cannot save results';

    # if present, this param indicates that the tool should return the
    # parsed query params without hitting the DB or processing results.
    my $dry_run = delete $params->{ dry_run };

    my $clean_params = $self->sanitise_and_remap_params( $params );
    my $re_output    = $self->re_client->run_query( $clean_params, $dry_run );
    my $output       = { query_params => $re_output->{ query_params } };

    return $output if $dry_run;

    die 'No results found in response' unless is_hashref $re_output->{ query_results }
        && %{ $re_output->{ query_results } };

    return {
        %$output,
        %{  $self->prepare_report(
                $re_output->{ query_results },
                $re_output->{ query_params },
                $workspace_id
            )
        },
    };
}


=head2 sanitise_and_remap_params

Clean out any parameters with no value or filled with whitespace.

Coerce parameters to the appropriate form (splitting strings to arrays, etc.).

@param {hashref}  $params       # input parameters from the app, minus workspace ID

@return {hashref} $clean_params # cleaned up parameters

=cut

sub sanitise_and_remap_params {
    my ( $self, $params ) = @_;

    my $stored_queries = $self->config->re_stored_query_params_by_query;

    # collect all possible params from the stored queries
    my $valid_params;
    for my $query ( keys %$stored_queries ) {
        my $query_data = $stored_queries->{ $query }{ properties };
        $valid_params->{ $_ } = $query_data->{ $_ } for keys %$query_data;
    }

    # Coerce parameters to the appropriate form from the app input
    my $type_coercions = {
        number  => {
            integer => sub { $_[ 0 ] },
            array   => sub { [ $_[ 0 ] ] },
        },
        string  => {
            array   => sub {
                my @split_up = grep { m/\S/msx } split /\n/, $_[ 0 ];
                return @split_up ? \@split_up : undef;
            },
            number  => sub { $_[ 0 ] + 0 },
            integer => sub { $_[ 0 ] + 0 },
        },
        null    => {
            '*'     => sub { undef },
        }
    };

    my $clean_params    = {};
    for my $p ( keys %$params ) {

        # anything that isn't in valid_params will get caught by the JSON validator
        unless ( $valid_params->{ $p } ) {
            $clean_params->{ $p } = $params->{ $p };
            next;
        }

        my $value       = $params->{ $p };
        my $type        = data_type( $value );
        my $type_wanted = $valid_params->{ $p }{ type };

        if ( $type_wanted ne $type ) {
            if ( $type_coercions->{ $type } ) {
                if ( $type_coercions->{ $type }{ $type_wanted } ) {
                    # say "Parameter $p: coercing $type to $type_wanted";
                    $value = $type_coercions->{ $type }{ $type_wanted }->( $value );
                }
                elsif ( $type_coercions->{ $type }{ '*' } ) {
                    $value = $type_coercions->{ $type }{ '*' }->( $value );
                }
            }
            else {
                # leave this to be caught by the validator
                warn "Parameter $p: cannot coerce $type to $type_wanted";
            }
        }

        # remove undefined values
        next unless defined $value;

        # don't include scalars unless there's a non-space character
        next unless is_ref $value || $value =~ m/\S/msx;

        # clean up array params
        if ( $type_wanted eq 'array' ) {
            # remove empty list items
            $value = [ grep { m/\S/msx } @$value ];
            # remove any dupes if the param requires unique items
            if ( $valid_params->{ $p }{ uniqueItems } ) {
                my %unique;
                my @new_value;
                for ( @$value ) {
                    next if $unique{ $_ };
                    push @new_value, $_;
                    $unique{ $_ }++;
                }
                $value = \@new_value;
            }
        }
        $clean_params->{ $p } = $value;
    }

    return $clean_params;
}


=head2 prepare_report

Collate data that will be used in the cytoscape report, render the template, and then save it as a KBase extended report.

@param {hashref}  $results        # results of the query to the RE API

@param {hashref}  $query_params   # parameters used for the query, in the form { query => '...', params => { ... } }

@param {string}   $workspace_id   # the all-important workspace ID

@return {hashref} $output         # hashref containing the name and ref of the KBase report created

=cut

sub prepare_report {
    my ( $self, $results, $query_params, $workspace_id ) = @_;

    $self->create_results_file( $results );
    $self->create_cytoscape_template( $results, $query_params );
    $self->copy_js;
    # $self->create_data_config_file;
    # create the kbase report
    return $self->create_kbase_report( $workspace_id );
}

=head2 create_results_file

Save the results from running the relation engine query to a file as JSON.

Dies if the results are not in the expected form, a hashref.

@param {hashref}  $results  # content from the query to the RE API

=cut

sub create_results_file {
    my ( $self, $results ) = @_;

    path( $self->run_directory, 'dataset.json' )
        ->spew_utf8( encode_json $results );

    return;
}

=head2 create_cytoscape_template

Render the cytoscape page template.

@param {hashref}  $results        # results of the query to the RE API

@param {hashref}  $query_params   # parameters used for the query, in the form { query => '...', params => { ... } }

=cut

sub create_cytoscape_template {
    my ( $self, $results, $query_params ) = @_;

    # create the cytoscape report
    my $template_data = $self->get_report_data;
    render_template(
        $self->cytoscape_template_path->canonpath,
        {
            template_data   => $template_data,
            query_params    => $query_params,
            results         => $results,
        },
        path( $self->run_directory, 'cytoscape.html' )->canonpath,
    );
}

=head2 get_report_data

Collate data that will be used in the cytoscape report, such as schema details for nodes and edges.

Returns a hashref of data used to populate fields in the cytoscape template.

=cut

sub get_report_data {
    my ( $self ) = @_;

    # gather the data needed for the report
    my $jv = JSON::Validator->new;
    my $template_data;

    # fetch node and edge field names
    for my $schema_type ( keys %{ $self->config->re_collections_paths } ) {
        $jv->schema( $self->config->re_collections_paths->{ $schema_type } );
        for my $prop ( keys %{ $jv->get( '/schema/properties' ) } ) {
            $template_data->{ $schema_type }{ $prop } = $jv->bundle( {
                schema => $jv->get( '/schema/properties/' . $prop )
            } );
        }
    }

    return $template_data;
}


=head2 create_kbase_report

Generate a KBase Extended Report containing the Cytoscape viewer page and supporting data files

@param {string}   $workspace_id   # the all-important workspace ID

@return {hashref} in the form

{ report_name => <report name>, report_ref => <workspace reference> }

=cut

sub create_kbase_report {
    my ( $self, $workspace_id ) = @_;

    try {
        my $report = $self->kb_report_client->create_extended_report( {
            workspace_id    => $workspace_id,
            html_links      => [
                {
                    name        => 'cytoscape.html',
                    path        => $self->run_directory->canonpath,
                    description => 'Cytoscape graph viewer',
                }
            ],
            direct_html_link_index  => 0,
            report_object_name      => 'Cytoscape_Report',
        } );

        return {
            report_name => $report->{ name },
            report_ref  => $report->{ ref }
        };
    }
    catch {
        die 'Report generation failed: ' . $_;
    };
}

# copy the cytoscape JS file over into the run directory
sub copy_js {
    my ( $self ) = @_;

    path( $self->config->app_dir, 'views', 'kb-cytoscape.umd.js' )
        ->copy( $self->run_directory, 'kb-cytoscape.umd.js' );

    return;
}

1;
