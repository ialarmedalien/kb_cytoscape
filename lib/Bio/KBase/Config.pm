package Bio::KBase::Config;

use strict;
use warnings;
use feature qw( say );
use Data::Dumper::Concise;

use Moo;
with 'MooX::Singleton';
use Config::Any;
use Path::Tiny;
use Try::Tiny;
use JSON::Validator;

has config_file => (
    is        => 'ro',
    required  => 1,
);

has original_config => (
    is        => 'ro',
    required  => 1,
);

has app_dir => (
    is        => 'ro',
    required  => 1,
);

has auth_service_url => (
    is => 'ro',
);

has callback_url => (
    is      => 'lazy',
    builder => 1,
);

sub _build_callback_url {
    $ENV{ SDK_CALLBACK_URL } or die 'SDK_CALLBACK_URL env var not set';
}

# which dataset to query in the Relation Engine repo
has dataset => (
    is      => 'ro',
    required => 1,
);

has docker_re_api_endpoint => (
    is      => 'ro',
);

has re_api_endpoint => (
    is      => 'ro',
);

has re_api_stored_query_url => (
    is      => 'lazy',
    builder => 1,
);

sub _build_re_api_stored_query_url {
    '/api/v1/query_results?stored_query='
}

has re_spec_base_dir => (
    is        => 'ro',
    required  => 1,
);

has re_collections_paths => (
    is      => 'lazy',
    builder => 1,
);

sub _build_re_collections_paths {
    shift->_get_spec_files( "collections" );
}

has re_stored_queries_paths => (
    is      => 'lazy',
    builder => 1,
);

sub _build_re_stored_queries_paths {
    shift->_get_spec_files( "stored_queries" );
}

has re_stored_query_params_by_query => (
    is      => 'lazy',
    builder => 1,
);

sub _build_re_stored_query_params_by_query {
    my ( $self ) = @_;
    my $jv       = JSON::Validator->new;
    my $stored_queries;
    # build a hash of each stored query params schema, indexed by query name
    for my $query ( keys %{ $self->re_stored_queries_paths } ) {
        $jv->schema( $self->re_stored_queries_paths->{ $query } );
        $stored_queries->{ $query } = $jv->bundle( { schema => $jv->get( '/params' ) } );
    }
    return $stored_queries;
}

# return a hashref of file basename to file path for all JSON and YAML files in a directory
sub _get_spec_files {
    my ( $self, $spec_type ) = @_;

    try {
        # any file in this dir ending in .yaml or .json
        my @file_list = path( $self->re_spec_base_dir, $spec_type, $self->dataset )->children( qr/\.(yaml|json)\z/ );
        return { map { path( $_ )->basename( qr/\.(yaml|json)\z/ ) => $_->stringify } @file_list };
    }
    catch {
        die "Cannot retrieve " . $self->dataset . " $spec_type specs: $_";
    };
}

has scratch => (
    is        => 'ro',
    required  => 1,
);

has token => (
    is      => 'lazy',
    builder => 1,
);

sub _build_token {
    $ENV{ KB_AUTH_TOKEN } or die 'KB_AUTH_TOKEN env var not set';
}

has use_docker_re_api => (
    is      => 'ro',
);

has workspace_url => (
    is => 'ro',
);

has version => (
    is      => 'lazy',
    builder => 1,
);

sub _build_version {
    my $version_content = path( shift->app_dir, 'VERSION' )->slurp_utf8;
    $version_content =~ s/\s//gm;
    return $version_content;
}

sub BUILDARGS {
    my ( @args ) = @_;

    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG }
        or die 'Cannot create config without ENV{ KB_DEPLOYMENT_CONFIG } defined';

    die 'Cannot read config file ' . $config_file unless -r $config_file;

    my $config  = Config::Any->load_files( {
        files           => [ $config_file ],
        flatten_to_hash => 1,
        force_plugins   => [ 'Config::Any::INI' ],
    } );

    my $cytoscape_config  = $config->{ $config_file }{ 'kb_cytoscape' };
    die 'No cytoscape configuration section found in config file ' . $config_file
        unless $cytoscape_config && %$cytoscape_config;

    my $args  = {
        config_file     => $config_file,
        original_config => $config,
    };

    my @attrs_to_copy = qw(
        app_dir
        auth-service-url
        docker-re-api-endpoint
        re-api-endpoint
        re-spec-base-dir
        dataset
        scratch
        workspace-url
    );

    for my $attr ( @attrs_to_copy ) {
        ( my $clean_attr = $attr ) =~ s/-/_/g;
        $args->{ $clean_attr } = $cytoscape_config->{ $attr };
    }

    $args->{ use_docker_re_api } = $ENV{ USE_DOCKER_RE_API } ? 1 : 0;

    return $args;

}

1;
