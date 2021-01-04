package Bio::KBase::RelationEngine::Client;

use strict;
use warnings;

use feature qw( say );
use Data::Dumper::Concise;

use Moo;
use Bio::KBase::Config;
use JSON::Validator;
use JSON::MaybeXS;
use LWP::UserAgent;
use Ref::Util qw( :all );
use Try::Tiny;

has config => (
    is      => 'lazy',
    builder => 1,
);

sub _build_config {
    Bio::KBase::Config->instance;
}

has ua => (
    is      => 'lazy',
    builder => 1,
);

sub _build_ua {
    my $ua = LWP::UserAgent->new();

#     Debug requests to the RE API
#     $ua->add_handler( request_prepare => sub {
#         my $req = shift;
#         say Dumper {
#             request => {
#                 method  => $req->method,
#                 uri     => $req->uri,
#                 headers => { $req->headers->flatten },
#                 content => $req->content, # may be undef
#             }
#         };
#     } );

    return $ua;
}

=head2 run_query

Run a query against the ArangoDB API

@param {hashref} $params    # parameters for the query

@return {object} $response  # response object from the server

=cut

sub run_query {
    my ( $self, $params, $dry_run ) = @_;

    my $parsed_params = $self->parse_params( $params );

    return { query_params => $parsed_params } if $dry_run;

    my $url = $self->config->use_docker_re_api
      ? $self->config->docker_re_api_endpoint
      : $self->config->re_api_endpoint;

    my $response = $self->ua->post(
        $url . $self->config->re_api_stored_query_url . $parsed_params->{ query },
        'Content-Type'  => 'application/json',
        'Content'       => encode_json $parsed_params->{ params },
    );

    # decode and return the response
    my $json_data;
    try {
        $json_data = decode_json $response->content;
    }
    catch {
        die "The database API returned invalid JSON.\n"
            . "Response status: " . $response->code . "\n"
            . "Response content: " . $response->content . "\n";
    };

    unless ( $response->is_success ) {
        die "The database API returned an error:\n"
            . "Response status: " . $response->code . "\n"
            . "Response content: " . Dumper $json_data;
    }

    # make sure that the results are present and correct
    die "The database API returned an invalid response.\n"
        . "Response status: " . $response->code . "\n"
        . "Response content: " . $response->content . "\n"
        unless is_hashref $json_data
            && is_arrayref $json_data->{ results }
            # the first array entry should be a hashref of { nodes => ..., edges => ...}
            && is_hashref $json_data->{ results }[ 0 ]
            && %{ $json_data->{ results }[ 0 ] };

    return {
        query_params    => $parsed_params,
        query_results   => $json_data->{ results }[ 0 ],
    };
}

=head2 parse_params

Parse the incoming arguments against the existing JSONschema stored queries to ensure that they are
correct, and to work out which query should be run.

@param {hashref} $params        # parameters for the query

@return {hashref} in the form

   { query => '$query_name', params => {...} }

=cut

sub parse_params {
    my ( $self, $params ) = @_;

    my $jv             = JSON::Validator->new;
    my $stored_queries = $self->config->re_stored_query_params_by_query;

    my @possible_queries;
    my $query_errors;
    for my $query ( keys %$stored_queries ) {
        my @errors = $jv->validate( $params, $stored_queries->{ $query } );
        @errors
            ? $query_errors->{ $query } = \@errors
            : push @possible_queries, $query;
    }

    die 'Invalid input parameters entered: ' . Dumper $query_errors
        unless @possible_queries && @possible_queries == 1;

    return { query => $possible_queries[ 0 ], params => $params };
}

1;
