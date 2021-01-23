use Test::Most;

use strict;
use warnings;
use feature qw( say );
use Data::Dumper::Concise;
use JSON::MaybeXS;
use JSON::Validator;
use Path::Tiny;
use Bio::KBase::Config;
use LWP::UserAgent;

require_ok "Bio::KBase::RelationEngine::Client";

unless ( $ENV{ DOCKER_COMPOSE_ENV } ) {
    say 'Skipping RelationEngine::Client tests: not in docker-compose set up';
    done_testing;
    exit 0;
}

# get the current test/data directory path
my $app_dir       = $ENV{ APP_DIR };
my $results_file  = path( $app_dir, 'relation_engine', 'spec', 'test', 'djornl', 'results.json' );
my $contents      = path( $results_file )->slurp_utf8;
my $test_queries  = decode_json( $contents );
my $valid_stored_queries;

subtest 'RE errors' => sub {

    # Mock the 'parse_params' method to generate errors in the database API.
    # These particular errors are not likely to occur in reality, but we can at
    # least ensure that error output is formatted in a reasonable way.
    no strict 'refs';
    no warnings 'redefine';
    local *Bio::KBase::RelationEngine::Client::parse_params = sub {
        # return the input, unchanged
        $_[1];
    };
    use strict;
    use warnings;

    my $rec = Bio::KBase::RelationEngine::Client->new;

    throws_ok {
        $rec->run_query( { query => 'nothing', params => {} } );
    }   qr{The database API returned an error:.*?Response status: 404}sm,
        'invalid query method';

    throws_ok {
        $rec->run_query( { query => 'djornl_search_nodes', params => { 'this' => 'that' } } );
    }   qr{The database API returned an error:.*?Response status: 400}sm,
        'invalid params';

    # make sure that the appropriate checks are done on the returned data
    no strict 'refs';
    no warnings 'redefine';

    my $dodgy_returns = [
        {
            data    => 'this is not JSON',
            desc    => 'Invalid JSON',
            error   => 'The database API returned invalid JSON.',
        },
        {
            data    => '{"this": "that',
            desc    => 'more invalid JSON',
            error   => 'The database API returned invalid JSON.',
        },
        {
            data    => encode_json( [ "error" ] ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( {} ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( { "results" => {} } ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( { "results" => [] } ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( { "results" => [ "hello" ] } ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( { "results" => [ [] ] } ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
        {
            data    => encode_json( { "results" => [ {} ] } ),
            desc    => 'invalid response structure',
            error   => 'The database API returned an invalid response',
        },
    ];

    for my $test ( @$dodgy_returns ) {
        local *Bio::KBase::RelationEngine::Client::_build_ua = sub {
            my $ua = LWP::UserAgent->new;
            $ua->add_handler( request_send => sub {
                return HTTP::Response->new(
                    200,
                    '',
                    [ "Content-type" => "application/json" ],
                    $test->{ data },
                );
            } );
            return $ua;
        };

        my $rel_engine_client = Bio::KBase::RelationEngine::Client->new;

        my $error = $test->{ error };
        throws_ok {
            $rel_engine_client->run_query( { query => 'djornl_fetch_all', params => {} } );
        } qr{$error}, $test->{ desc } . ": " . $test->{ data };
    }

};

subtest 'parse_args and run_query' => sub {

    my $use_docker_re_api = 1;
    Bio::KBase::Config->_clear_instance();
    local $ENV{ USE_DOCKER_RE_API } = $use_docker_re_api;

    my $rec = Bio::KBase::RelationEngine::Client->new;

    is $use_docker_re_api, $rec->config->use_docker_re_api, 'client will use the docker RE API';

    my $url = $rec->config->use_docker_re_api
      ? $rec->config->docker_re_api_endpoint
      : $rec->config->re_api_endpoint;

    $valid_stored_queries //= {
        map { $_ => 1 } keys %{ $rec->config->re_stored_queries_paths }
    };

    # indexing schema in results.json
    # self.json_data['queries'][query_name]
    # e.g. for fetch_clusters data:
    # "djornl_fetch_clusters": {
    #   "params": { "cluster_ids": ["markov_i2:6", "markov_i4:3"], "distance": "1"},
    #   "results": {
    #     "nodes": [ node IDs ],
    #     "edges": [ edge data ]
    #   }
    # }
    # nodes are represented as a list of node[_key]
    # edges are objects with keys _to, _from, edge_type and score

    for my $query ( sort keys %{ $test_queries->{ queries } } ) {
        # the Perl app doesn't use $query, so it does not know that $query is invalid in these tests
        # => skip them
        next unless $valid_stored_queries->{ $query };

        QUERY_LOOP:
        for my $test ( @{ $test_queries->{ queries }{ $query } } ) {

            my $param_str = ref $test->{ params }
                ? encode_json( $test->{ params } )
                : $test->{ params };
            my $description = "query $query with params $param_str";

            if ( $test->{ error } && $test->{ results }
                || !$test->{ error } && !$test->{ results } ) {
                say "Check test set-up for $query with params $description";
                next QUERY_LOOP;
            }

            if ( $test->{ error } ) {
                my $parsed_args;
                for my $method ( qw( parse_params run_query ) ) {
                    throws_ok {
                        $parsed_args = $rec->$method( $test->{ params } )
                    } qr{Invalid input parameters entered},
                      "invalid input to $method for $description"
                    or diag explain {
                        %$parsed_args,
                        test  => $test
                    };
                }
                next;
            }

            my $response;
            # ensure the query to use is correctly calculated
            lives_ok {
                my $parsed_args = $rec->parse_params( $test->{ params } );
                is $parsed_args->{ query }, $query, 'correct query figured out';

                $response = $rec->run_query( $test->{ params } );
            } 'parse_params and run_query run successfully';

            test_success_response( $response, $test, $description ) if $response;

        }
    }
};

sub test_success_response {
    my ( $response, $test, $description ) = @_;

    my $results = {
        nodes => [ sort map { $_->{ _key } } @{ $response->{ query_results }{ nodes } } ],
        edges => [ sort map { $_->{ _key } } @{ $response->{ query_results }{ edges } } ],
    };

    # extract the node and edge _key data from the results
    cmp_deeply
        $results,
        {
            nodes => [ sort @{ $test->{ results }{ nodes } } ],
            edges => [ sort @{ $test->{ results }{ edges } } ],
        },
        'query results as expected'
        or diag explain {
            got       => $results,
            expected  => $test->{ results },
        };

}


done_testing();
