use strict;
use warnings;
use feature qw( say );
use Data::Dumper::Concise;

use Test::Most;
use Path::Tiny;

require_ok "Bio::KBase::Config";

local $ENV{ KB_AUTH_TOKEN } = 'auth_token';

my $test_dir     = $ENV{ TEST_DIR };
my $token        = $ENV{ KB_AUTH_TOKEN };
my $config_file  = $ENV{ KB_DEPLOYMENT_CONFIG };
my $callback_url = $ENV{ SDK_CALLBACK_URL };
my $app_dir;

subtest 'config initialisation, standard env' => sub {

    Bio::KBase::Config->_clear_instance();
    my $config = Bio::KBase::Config->instance;

    is $config->token, $token, 'token picked up correctly';
    is $config->scratch, '/kb/module/work/tmp', 'scratch dir is set correctly';
    is $config->use_docker_re_api, 0, 'use_docker_re_api set correctly';

    $app_dir = $config->app_dir;
};

subtest 'errors' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = undef;
    throws_ok {
        Bio::KBase::Config->instance
    } qr{Cannot create config without ENV\{ KB_DEPLOYMENT_CONFIG \} defined},
      'no KB_DEPLOYMENT_CONFIG specified';

};

subtest 'invalid path to conf file' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $test_dir, 'path', 'to', 'file' )->canonpath;
    throws_ok {
        Bio::KBase::Config->instance
    } qr{Cannot read config file },
      'invalid path to conf file';

};

subtest 'invalid conf file format' => sub {
    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $test_dir, 'data', 'test.tt' )->canonpath;
    # shows up as a "no cytoscape config" section
    throws_ok {
        Bio::KBase::Config->instance
    } qr{No cytoscape configuration section found in config file},
      'invalid config file format';
};

subtest 'no kb_cytoscape config segment' => sub {
    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $test_dir, 'data', 'config', 'test-no-cfg.ini' )->canonpath;
    throws_ok {
        Bio::KBase::Config->instance
    } qr{No cytoscape configuration section found in config file},
      'no kb_cytoscape config section';
};

subtest 'empty config segment' => sub {
    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $test_dir, 'data', 'config', 'test-empty-cfg.cfg' )->canonpath;
    throws_ok {
        Bio::KBase::Config->instance
    } qr{No cytoscape configuration section found in config file},
      'empty kb_cytoscape config section';
};

subtest 'config initialisation, valid conf, GO dataset, different env' => sub {

    Bio::KBase::Config->_clear_instance();

    local $ENV{ KB_DEPLOYMENT_CONFIG }  = path( $test_dir, 'data', 'config', 'test-GO-dataset.ini' )->canonpath;
    local $ENV{ KB_AUTH_TOKEN }         = 'abracadabra';
    local $ENV{ USE_DOCKER_RE_API }     = 'yes';
    local $ENV{ SDK_CALLBACK_URL }      = 'insert_url_here';

    my $config = Bio::KBase::Config->instance;

    is $config->token, 'abracadabra', 'token as expected';
    is $config->callback_url, 'insert_url_here', 'callback URL as expected';
    is $config->workspace_url, 'http://workspace.com/this-is-the-url', 'workspace url as expected';
    is $config->app_dir, '/kb/module', 'app_dir as expected';
    is $config->use_docker_re_api, 1, 'use_docker_re_api as expected';
    is $config->dataset, 'GO', 'dataset as expected';

    cmp_deeply $config->re_collections_paths, {},
        'no collections in ' . $test_dir . '/data/test_spec/collections';

    my $sq_path = path( $test_dir, "data", "test_spec", "stored_queries", "GO" )->canonpath;
    cmp_deeply $config->re_stored_queries_paths,
        {
            GO_get_terms    => "$sq_path/GO_get_terms.yaml",
        },
        'found the correct stored queries in ' . $test_dir . '/data/test_spec/stored_queries';

};

subtest 'dataset issues' => sub {

    Bio::KBase::Config->_clear_instance();

    local $ENV{ KB_DEPLOYMENT_CONFIG }  = path( $test_dir, 'data', 'config', 'test-ncbi-dataset.ini' )->canonpath;
    undef local $ENV{ KB_AUTH_TOKEN };
    local $ENV{ USE_DOCKER_RE_API } = 'yes';
    undef local $ENV{ SDK_CALLBACK_URL };

    my $config = Bio::KBase::Config->instance;
    is $config->dataset, 'ncbi', 'dataset as expected';

    throws_ok {
        $config->token
    } qr{KB_AUTH_TOKEN env var not set}, 'no kb auth token set';

    throws_ok {
        $config->callback_url
    } qr{SDK_CALLBACK_URL env var not set}, 'no callback url set';

    throws_ok {
        $config->re_collections_paths
    } qr{Cannot retrieve ncbi collections specs: .*? No such file or directory},
        'No collections specs directory';

    throws_ok {
        $config->re_stored_query_params_by_query
    } qr{Cannot retrieve ncbi stored_queries specs: .*? No such file or directory},
        'No stored query specs directory';

};

done_testing();
