package kb_cytoscape::kb_cytoscapeImpl;

use strict;
use warnings;
use Bio::KBase::Exceptions;

# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION = '0.0.1';
our $GIT_URL = '';
our $GIT_COMMIT_HASH = '';

=head1 NAME

kb_cytoscape

=head1 DESCRIPTION

A KBase module: kb_cytoscape

=cut

#BEGIN_HEADER

use File::Spec::Functions qw( catfile catdir );
use Bio::KBase::AuthToken;
use Bio::KBase::Templater qw( render_template );
use installed_clients::KBaseReportClient;
use Config::IniFiles;

#END_HEADER

sub new {
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;

    #BEGIN_CONSTRUCTOR

    my $config_file         = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg                 = Config::IniFiles->new( -file => $config_file );

    $self->{ scratch }      = $cfg->val( 'kb_cytoscape', 'scratch' );
    $self->{ appdir }       = $cfg->val( 'kb_cytoscape', 'appdir' );
    $self->{ callbackURL }  = $ENV{ SDK_CALLBACK_URL };

    #END_CONSTRUCTOR

    $self->_init_instance() if $self->can( '_init_instance' );

    return $self;
}

=head1 METHODS

=head2 run_kb_cytoscape

  $output = $obj->run_kb_cytoscape($params)

=item Description

The actual function is declared using 'funcdef' to specify the name
and input/return arguments to the function.  For all typical KBase
Apps that run in the Narrative, your function should have the
'authentication required' modifier.

=back

=cut

sub run_kb_cytoscape {
    my $self = shift;
    my $params  = @_;
    my @bad_arguments;


    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error       => format_error_string( 'argument', '${method.name}', \@bad_returns ),
        method_name => '${method.name}',
    ) if @bad_arguments;

    my $ctx = $kb_cytoscape::kb_cytoscapeServer::CallContext;
    my $output;
    #BEGIN run_kb_cytoscape
    my $kb_report_client = installed_clients::KBaseReportClient->new( $self->{ callbackURL } );

    # create the cytoscape report
    my $cytoscape_path = catfile( $self->{ scratch }, 'cytoscape.html' );

    render_template(
        catfile( $self->{ appdir }, 'views', 'cytoscape.tt' ),
        { template_data => '' },
        $cytoscape_path,
    );

    my $data_dir = catdir( $self->{ appdir }, 'data' );

    my $report = $kb_report_client->create_extended_report( {
        workspace_name => $params->{ workspace_name },
        html_files      => [
            {
                name    => 'cytoscape.html',
                path    => $cytoscape_path,

            }, {
                # data directory
                path    => $data_dir,
                name    => 'data',
            },
        ],
        direct_html_link_index  => 0,
        report_object_name      => 'Cytoscape_Report',
    } );

    $output = {
        report_name => $report->{ name },
        report_ref  => $report->{ ref }
    };

    #END run_kb_cytoscape
    my @bad_returns;
    push @bad_returns, { argument => ${return.name}, value => ${return.perl_var} }
        unless ${return.validator};

    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error       => format_error_string( 'return', '${method.name}', \@bad_returns ),
        method_name => '${method.name}',
    ) if @bad_returns;

    return ( ${method.ret_vars} );
}


=head2 status

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my $return;
    #BEGIN_STATUS
    $return = {
        "state"           => "OK",
        "message"         => "",
        "version"         => $VERSION,
        "git_url"         => $GIT_URL,
        "git_commit_hash" => $GIT_COMMIT_HASH
    };
    #END_STATUS
    return ( $return );
}

sub format_error_string {
    my ( $type, $method_name, $values ) = @_;

    $type = 'return value' if $type ne 'argument';

    my @strings = map {
        "\tInvalid type for $type '"
        . $_->{ argument } . "' "
        . "(value was '" . $_->{ value } . "')"
    } @$values;

    return join "\n", "Invalid " . $type . "s passed to $method_name:", @strings;
}

1;
