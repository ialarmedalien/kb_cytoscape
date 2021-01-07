use Test::Most;
use feature qw( say );

use Bio::KBase::AuthToken;
use Bio::KBase::LocalCallContext;
use installed_clients::WorkspaceClient;
use Data::Dumper::Concise;
use LWP::UserAgent;
use JSON::MaybeXS;
use Bio::KBase::JSONRPCClient;

use TestData;

require_ok "kb_cytoscape::kb_cytoscapeImpl";

local $| = 1;
my $token        = $ENV{ 'KB_AUTH_TOKEN' };
# my $callback_url = $ENV{ 'SDK_CALLBACK_URL' };

my $config       = Bio::KBase::Config->instance;

my ( $ws_name, $ws_id, $ws_client );

my $scratch      = $config->scratch;

my $auth_token   = Bio::KBase::AuthToken->new(
    token           => $token,
    ignore_authrc   => 1,
    auth_svc        => $config->auth_service_url,
);

# my $ctx = Bio::KBase::LocalCallContext->new( $token, $auth_token->user_id );
# $kb_cytoscape::kb_cytoscapeServer::CallContext = $ctx;

sub get_ws_client {
    my $ws_url  = $config->workspace_url;
    $ws_client  //= installed_clients::WorkspaceClient->new( $ws_url, token => $token );
    return $ws_client;
}

sub get_ws_id {
    get_ws_name() unless $ws_id;
    return $ws_id;
}

sub get_ws_name {
    unless ( $ws_name ) {
        $ws_client  = get_ws_client();
        my $suffix  = int( time * 1000 );
        $ws_name    = 'test_kb_cytoscape_' . $suffix;
        my $resp    = $ws_client->create_workspace( { workspace => $ws_name } );
        $ws_id      = $resp->[ 0 ];
    }
    return $ws_name;
}

my $impl;

subtest 'creating the new kb_cytoscapeImpl object' => sub {

    lives_ok {
        $impl = kb_cytoscape::kb_cytoscapeImpl->new();
    } 'kb_cytoscapeImpl object can be created';

    isa_ok $impl, 'kb_cytoscape::kb_cytoscapeImpl';

};

subtest 'version' => sub {
    ok $impl->version =~ m/\d+\.\d+\.\d+/, 'version string has format n.n.n';
};

subtest 'status' => sub {
    cmp_deeply $impl->status,
        {
            "state"           => "OK",
            "message"         => "All quiet on the western front",
            "version"         => re('\d+\.\d+\.\d+'),
            "git_url"         => re('^https://github.com/.+'),
            "git_commit_hash" => re('^[0-9a-f]{40}$')
        },
        'impl status is as expected';
};

subtest 'dry run' => sub {
    my $test_data = TestData::get_data();

    ok $test_data && @$test_data, 'got some test cases to test';

    for my $item ( @$test_data ) {
        my $result  = $impl->run_kb_cytoscape({
            dry_run         => 1,
            workspace_id    => 12345,
            %{ $item->{ input } },
        });
        my $expected = {
            query_params => {
                params  => $item->{ clean },
                query   => $item->{ query },
            }
        };

        cmp_deeply $result,
            $expected,
            'got the expected result from the dry run'
            or diag explain {
                output  => $result,
                expect  => $expected,
            };
    }
};

# tests that should be run against CI
subtest 'Tests to be run against CI' => sub {
    if ( $ENV{ DOCKER_COMPOSE_ENV } ) {
        ok 1, 'Skipping CI tests as running in the docker-compose environment';
        return;
    }

    subtest 'checking workspace name' => sub {

        my $ws_name = get_ws_name();
        ok $ws_name =~ /test_kb_cytoscape_\d+/, 'workspace name is appropriate';

    };

    # subtest 'tests requiring kb-sdk' => sub {
    #     is $ENV{ KB_SDK_TEST }, 1, 'kb-sdk is active';
    # };

    subtest 'testing run_kb_cytoscape' => sub {

        my $result  = $impl->run_kb_cytoscape( {
            # applies to all queries
            edge_types          => [],
            # applies to filtered queries
            distance            => 0,
            # specific query params
            cluster_ids         => '',
            phenotype_keys      => '',
            gene_keys           => '',
            search_text         => 'this is unlikely to be matched',
            workspace_id        => get_ws_id(),
        } );

        my $expect  = {
            report_name     => 'Cytoscape_Report',
            report_ref      => re('\d+\/\d+\/\d+'),
            query_params    => {
                distance    => 0,
                search_text => 'this is unlikely to be matched',
            },
        };

        cmp_deeply
            $result,
            $expect,
            'the expected report was returned'
            or diag explain {
                got         => $result,
                expected    => $expect,
            };

        # fetch the report and check that the contents are as expected
        my $report_object = $ws_client->get_objects2({
            objects => [ { ref => $result->{ report_ref } } ]
        });
        my $report = $report_object->{ data }[ 0 ]{ data };

        my $expected_report_data = {
            'text_message'  => undef,
            'file_links'    => [],
            'html_links'    => [
                {
                    URL         => re('https:.*?\.kbase\.us.+'),
                    name        => 'cytoscape.html',
                    description => 'Cytoscape graph viewer',
                    handle      => re('.*?'),
                    label       => '',
                }
            ],
            'warnings'      => [],
            'direct_html'   => undef,
            'direct_html_link_index'=> 0,
            'objects_created'       => [],
            'html_window_height'    => undef,
            'summary_window_height' => undef,
        };

        cmp_deeply $report, $expected_report_data, 'report contents as expected'
            or diag explain $report;
    };

    # clean up
    if ( $ws_name ) {
        lives_ok {
            $ws_client->delete_workspace( { workspace => $ws_name } );
        } 'Test workspace successfully deleted';
    }

};


done_testing();
