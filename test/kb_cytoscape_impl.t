use strict;
use warnings;
use feature qw( say );

use Test::Most;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
use Bio::KBase::LocalCallContext;
use installed_clients::WorkspaceClient;

require_ok "kb_cytoscape::kb_cytoscapeImpl";

local $| = 1;
my $token        = $ENV{ 'KB_AUTH_TOKEN' };
my $config_file  = $ENV{ 'KB_DEPLOYMENT_CONFIG' };
my $callback_url = $ENV{ 'SDK_CALLBACK_URL' };

my $config       = Config::Simple->new( $config_file )->get_block( 'kb_cytoscape' );
my ( $ws_name, $ws_client );

my $scratch      = $config->{ scratch };

my $auth_token   = Bio::KBase::AuthToken->new(
    token           => $token,
    ignore_authrc   => 1,
    auth_svc        => $config->{ 'auth-service-url' }
);

my $ctx     = Bio::KBase::LocalCallContext->new( $token, $auth_token->user_id );
$kb_cytoscape::kb_cytoscapeServer::CallContext = $ctx;

sub get_ws_client {

    my $ws_url  = $config->{ "workspace-url" };
    $ws_client  //= installed_clients::WorkspaceClient->new( $ws_url, token => $token );
    return $ws_client;
}

sub get_ws_name {

    $ws_client = get_ws_client();
    unless ( $ws_name ) {
        my $suffix  = int( time * 1000 );
        $ws_name    = 'test_kb_cytoscape_' . $suffix;
        $ws_client->create_workspace( { workspace => $ws_name } );
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


# tests that should be run on CI
if ( $ENV{ KB_SDK_ACTIVE } ) {

    subtest 'tests requiring kb-sdk' => sub {

        is $ENV{ KB_SDK_ACTIVE }, 1, 'kb-sdk is active';

    };

}

subtest 'testing run_kb_cytoscape' => sub {

    # Prepare test data using the appropriate uploader for that data (see the KBase function
    # catalog for help, https://narrative.kbase.us/#catalog/functions)
    # Run your method using
    # my $result = $impl->your_method( $parameters... );
    #
    # Check returned data with methods from Test::Most; e.g.
    # cmp_deeply
    #   $result,
    #   $expected,
    #   "$impl->your_method returns the expected data with params ...";

    my $result  = $impl->run_kb_cytoscape( {
        workspace_name  => get_ws_name(),
    } );

    my $expect  = {
        report_name => 'Cytoscape_Report',
        report_ref  => re('\d+\/\d+\/\d+'),
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
        objects => [ { ref => $result->{ report_ref } ]
    });
    my $report = $report_object->{ data }[ 0 ]{ data };

    # expect
    my $expected_report_data = {
        'text_message': undef,
        'file_links': [],
        'html_links': [
            {
                name    => 'cytoscape.html',
                path    => 'something or other',

            }, {
                # data directory
                path    => 'whatever!',
                name    => 'data',
            },
        ],
        'warnings': [],
        'direct_html': undef,
        'direct_html_link_index': 0,
        'objects_created': [],
        'html_window_height': undef,
        'summary_window_height': undef,
    };

    cmp_deeply $report, $expected_report_data, 'report contents as expected'
        or diag explain $report;

};


if ( $ws_name ) {
    lives_ok {
        $ws_client->delete_workspace( { workspace => $ws_name } );
    } 'Test workspace successfully deleted';
}

done_testing();
