use Test::Most;

use feature qw( say );
use Data::Dumper::Concise;
use Bio::KBase::Config;
use installed_clients::KBaseReportClient;
use Path::Tiny;
use JSON::MaybeXS;
use Ref::Util qw( is_hashref );

use TestData;

# get the current test/data directory path
my $app_dir       = $ENV{ APP_DIR };
my $results_file  = path( $app_dir, 'relation_engine', 'spec', 'test', 'djornl', 'results.json' );
my $contents      = path( $results_file )->slurp_utf8;
my $test_queries  = decode_json( $contents );

require_ok "Bio::KBase::CytoscapeClient";

subtest 'general client tests' => sub {

    my $client  = Bio::KBase::CytoscapeClient->new;
    my $uuid    = $client->run_uuid;

    my $client2 = Bio::KBase::CytoscapeClient->new;
    ok $uuid ne $client2->run_uuid, 'Clients have different run UUIDs';

    my $expected_run_dir = path( Bio::KBase::Config->instance->scratch )->child( $uuid );
    is $client->run_directory->canonpath,
        $expected_run_dir->canonpath,
        'the expected run directory was created under the scratch dir';
};

subtest 'general errors' => sub {
    undef local $ENV{ SDK_CALLBACK_URL };

    my $client  = Bio::KBase::CytoscapeClient->new;

    throws_ok {
        $client->config->callback_url
    } qr{SDK_CALLBACK_URL env var not set}, 'no callback url set';

    throws_ok {
        $client->kb_report_client
    } qr{SDK_CALLBACK_URL env var not set},
        'cannot init the kb_report_client attribute without a callback URL';

    # will die if we try to perform an action that requires the callback url
    throws_ok {
        $client->create_kbase_report( 12345 );
    } qr{SDK_CALLBACK_URL env var not set},
        'cannot create a report without the callback URL';

};

subtest 'sanitise_and_remap_params' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ SDK_CALLBACK_URL } = 'whatever!';

    my $client  = Bio::KBase::CytoscapeClient->new;
    my $test_data = TestData::get_data();

    for my $item ( @$test_data ) {
        my $result  = $client->sanitise_and_remap_params( $item->{ input } );
        cmp_deeply $result,
            $item->{ clean },
            'correct result after sanitising'
            or diag explain {
                output  => $result,
                expect  => $item->{ clean },
            };
    }
};

subtest 'get report data' => sub {

    my $client = Bio::KBase::CytoscapeClient->new;

    my $data = $client->get_report_data;

    cmp_deeply
        [ sort keys %$data ],
        [ 'djornl_edge', 'djornl_node' ],
        'retrieved the node and edge data'
        or diag explain $data;
};

subtest '$client->run (without creating a report)' => sub {

    my $use_docker_re_api = 1;
    Bio::KBase::Config->_clear_instance();
    local $ENV{ USE_DOCKER_RE_API } = $use_docker_re_api;
    my $file_write_test_done;

    my $client = Bio::KBase::CytoscapeClient->new;
    my $valid_stored_queries = {
        map { $_ => 1 } keys %{ $client->config->re_stored_queries_paths }
    };

    # override prepare_report so that we don't create a ton of redundant files
    no strict 'refs';
    no warnings 'redefine';
    local *Bio::KBase::CytoscapeClient::prepare_report = sub {
        my ( $self, $response_data, $ws_id ) = @_;
        return { content => $response_data };
    };
    use strict;
    use warnings;

    for my $query ( sort keys %{ $test_queries->{ queries } } ) {
        # the Perl app doesn't use $query, so it does not know that $query is invalid in these tests
        # => skip them
        next unless $valid_stored_queries->{ $query };

        QUERY_LOOP:
        for my $test ( @{ $test_queries->{ queries }{ $query } } ) {

            unless ( is_hashref $test->{ params } ) {
                throws_ok {
                    $client->run( $test->{ params } )
                } qr{Invalid parameter format},
                  "Params must be a hashref";
                next QUERY_LOOP;
            }

            my $param_str = encode_json $test->{ params };
            my $description = "query $query with params $param_str";

            if ( $test->{ error } && $test->{ results }
                || !$test->{ error } && !$test->{ results } ) {
                say "Check test set-up for $query with params $description";
                next QUERY_LOOP;
            }

            my $output;
            if ( $test->{ results } || $test->{ coerce } ) {
                lives_ok {
                    $output = $client->run( { %{ $test->{ params } }, workspace_id => 12345 } )
                } '$client->run was successful';

                ok is_hashref $output, 'the output is a hashref, as expected';
                test_success_response( $output, $test, $description );

                unless ( $file_write_test_done || $test->{ coerce } ) {
                    test_create_results_file( $client, $output->{ content }, $test );
                    test_create_cytoscape_template( $client, $output->{ content }, $test );
                    $file_write_test_done++;
                }

                next QUERY_LOOP;
            }

            throws_ok {
                $output = $client->run( { %{ $test->{ params } }, workspace_id => 12345 } )
            } qr{Invalid input parameters entered},
              "invalid input for $description"
            or diag explain {
                params    => $test->{ params },
            };
        }
    }
};

sub test_success_response {
    my ( $output, $test, $description ) = @_;

    ok exists $output->{ content } && %{ $output->{ content } }
        && exists $output->{ query_params } &&  %{ $output->{ query_params } },
        'content and query params are present in output';

    my $response_data = $output->{ content };
    unless ( $response_data->{ results } ) {
        ok exists $response_data->{ results }
            && exists $response_data->{ results }[ 0 ],
            'results key is defined in the response content';
        return;
    }
    my $got      = $response_data ->{ results }[ 0 ];
    my $expected = $test->{ results } || $test->{ coerce };

    compare_results( $got, $expected, $output );

}

sub compare_results {
    my ( $got, $expected, $output ) = @_;

    my $results = {
        nodes => [ sort map { $_->{ _key } } @{ $got->{ nodes } } ],
        edges => [ sort map { $_->{ _key } } @{ $got->{ edges } } ],
    };

    # extract the node and edge _key data from the results
    cmp_deeply
        $results,
        {
            nodes => [ sort @{ $expected->{ nodes } } ],
            edges => [ sort @{ $expected->{ edges } } ],
        },
        'query results as expected'
        or diag explain {
            params    => $output->{ query_params },
            got       => $results,
            expected  => $expected,
        };
}

sub test_create_results_file {
    my ( $client, $response, $test ) = @_;

    subtest 'create results file' => sub {

        my $run_dir = $client->run_directory;
        ok !path( $run_dir, 'dataset.json' )->is_file, 'dataset file does not exist';
        $client->create_results_file( $response );
        ok path( $run_dir, 'dataset.json' )->is_file, 'dataset file now exists';
        # read in the file
        my $dataset_encoded = path( $run_dir, 'dataset.json' )->slurp_utf8;
        my $decoded_dataset = decode_json $dataset_encoded;
        compare_results( $decoded_dataset, $test->{ results }, $response );
    };
}

sub test_create_cytoscape_template {

    my ( $client, $response, $test ) = @_;

    subtest 'create cytoscape template' => sub {
        my $run_dir = $client->run_directory;
        ok !path( $run_dir, 'cytoscape.html' )->is_file, 'cytoscape file does not exist';
        $client->create_cytoscape_template( $response );
        ok path( $run_dir, 'cytoscape.html' )->is_file, 'cytoscape file now exists';
        # read in the file
        my $cytoscape_content = path( $run_dir, 'cytoscape.html' )->slurp_utf8;
        # test the file contents here...
        ok $cytoscape_content =~ m/cytoscape demo/i, 'Page contains expected content'
            or diag explain $cytoscape_content;
        say 'cytoscape file: ' . path( $run_dir, 'cytoscape.html' )->canonpath;
    };
}

subtest 'run with create_extended_report mocked' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ SDK_CALLBACK_URL } = 'whatever!';

    my $client        = Bio::KBase::CytoscapeClient->new;
    my $run_directory = $client->run_directory->canonpath;
    my $workspace_id  = 12345;

    # redefine create_extended_report to test the input structure and output
    # the expected report name / ref
    no strict 'refs';
    no warnings 'redefine';
    local *installed_clients::KBaseReportClient::create_extended_report = sub {
        my ( $self, $input ) = @_;

        cmp_deeply
            $input,
            {
                workspace_id    => $workspace_id,
                html_links      => [
                    {
                        name        => 'cytoscape.html',
                        path        => $run_directory,
                        description => 'Cytoscape graph viewer',
                    }
                ],
                direct_html_link_index  => 0,
                report_object_name      => 'Cytoscape_Report',
            },
            'KB Report Client got the expected data structure'
            or diag explain $input;

        return {
            name   => 'Mary',
            ref    => 'Poppins',
        };
    };
    use strict;
    use warnings;

    my $test_data = TestData::get_data();

    for my $item ( @$test_data ) {
        my $result  = $client->run( {
            %{ $item->{ input } },
            workspace_id => $workspace_id
        } );
        my $expected = {
            report_name     => 'Mary',
            report_ref      => 'Poppins',
            query_params    => {
                params  => $item->{ clean },
                query   => $item->{ query },
            }
        };

        cmp_deeply $result, $expected,
            'correct result after running the cytoscape client'
            or diag explain {
                output  => $result,
                expect  => $expected,
            };
    }

};


done_testing();
