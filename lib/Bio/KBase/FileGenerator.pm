package Bio::KBase::FileGenerator;

use strict;
use warnings;
use feature qw( say );
use Data::Dumper::Concise;
use Bio::KBase::Config;
use Bio::KBase::Templater qw( render_template );
use Moo;
use JSON::Validator;
use Path::Tiny;
use JSON::MaybeXS;
use YAML::XS qw( :all );
$YAML::XS::Boolean = "JSON::PP";

has config => (
    is      => 'lazy',
    builder => 1,
);

sub _build_config {
    Bio::KBase::Config->instance;
}

has app_metadata => (
    is      => 'lazy',
    builder => 1,
);

sub _build_app_metadata {
    my ( $self ) = @_;
    my $metadata_file = $self->metadata_yaml_path;

    # metadata file does not exist or it is not a file
    die 'No metadata file: cannot build app metadata' unless $metadata_file->is_file;

    LoadFile $self->metadata_yaml_path->canonpath;
    # check that it validates against the spec

}

has app_metadata_spec => (
    is      => 'lazy',
    builder => 1,
);

sub _build_app_metadata_spec {
    my ( $self ) = @_;
    LoadFile path( $self->config->app_dir, 'metadata.spec.yaml' )->canonpath;
}

has validator => (
    is      => 'lazy',
    builder => 1,
);

sub _build_validator {
    JSON::Validator->new;
}

has app_spec_path => (
    is      => 'lazy',
    builder => 1,
);

# module_name + ".spec"
sub _build_app_spec_path {
    my ( $self ) = @_;
    path( $self->config->app_dir, $self->app_metadata->{ module_name } . '.spec' );
}

# template file for generating the app spec
has app_spec_template_path => (
    is      => 'lazy',
    builder => 1,
);

sub _build_app_spec_template_path {
    path( shift->config->app_dir, 'views', 'module.spec.tt' );
}

has kbase_yaml_path => (
    is      => 'lazy',
    builder => 1,
);

sub _build_kbase_yaml_path {
    path( shift->config->app_dir, 'kbase.yml' );
}

has metadata_yaml_path => (
    is      => 'lazy',
    builder => 1,
);

sub _build_metadata_yaml_path {
    path( shift->config->app_dir, 'metadata.yaml' );
}

has param_join_str => (
    is      => 'ro',
    default => '____',
);

=head2 display_yaml_path

Given a method name, generate the path for the display.yaml file.

If no method name is given, the first method found in the metadata.yaml file will be used.

=cut

sub display_yaml_path {
    my ( $self, $method_name ) = @_;

    $method_name ||= $self->app_metadata->{ methods }[ 0 ]{ method_name };

    return path( $self->config->app_dir, 'ui', 'narrative', 'methods', $method_name, 'display.yaml' );
}

=head2 spec_json_path

Given a method name, generate the path for the spec.json file.

If no method name is given, the first method found in the metadata.yaml file will be used.

=cut

sub spec_json_path {
    my ( $self, $method_name ) = @_;

    $method_name ||= $self->app_metadata->{ methods }[ 0 ]{ method_name };

    return path( $self->config->app_dir, 'ui', 'narrative', 'methods', $method_name, 'spec.json' );
}

=head2 switch_old_new_files

Given two files, $target_file and $target_file . ".new", rename the files from
$target_file to $target_file . ".old", and $target_file . ".new" to $target_file.

Both $target_file and $target_file.new must exist for the switch to take place.

@param {string} $target_file      # file to switch over

=cut


sub switch_old_new_files {
    my ( $self, $target_file ) = @_;

    die "New file $target_file.new does not exist" unless path( "$target_file.new" )->is_file;
    die "Existing file $target_file does not exist" unless path( $target_file )->is_file;

    # switch over the old and new files
    path( $target_file )->move( "$target_file.old" ) or die "Could not move files: $!";
    path( "$target_file.new" )->move( $target_file ) or die "Could not move files: $!";

    return;
}

sub compile_data {
    my ( $self )  = @_;

    my $data = $self->app_metadata;
    $data->{ version }        = $self->config->version;
    $data->{ stored_queries } = $self->get_stored_queries;

    return $data;
}

=head2 generate_files

Generate application files: kbase.yml, display.yaml, spec.json, and the app .spec file

=cut

sub generate_files {
    my ( $self ) = @_;

    my $data = $self->compile_data;

    for my $file ( qw( app_spec display_yaml kbase_yaml spec_json ) ) {
        my $path_attr   = $file . "_path";
        my $output_file = $self->$path_attr;

        # check whether the file (and its path) already exist
        my $file_exists = $self->_file_write_checks( $output_file );
        my $new_file    = $file_exists
            ? $output_file->canonpath . '.new'
            : $output_file->canonpath;

        # generate the file
        my $gen_fn  = "generate_" . $file;
        $self->$gen_fn( $data, $new_file );

        # switch over the files if required
        $self->switch_old_new_files( $output_file->canonpath ) if $file_exists;
    }
    return;
}

# checks to perform before writing a file

sub _file_write_checks {
    my ( $self, $path ) = @_;
    # make sure that the parent directory is present
    path( $path )->parent->mkpath;
    return path( $path )->exists;
}

sub get_stored_queries {
    my ( $self ) = @_;

    my $jv = $self->validator;
    my $sq_data;

    for my $sq ( keys %{ $self->config->re_stored_queries_paths } ) {
        # set the schema
        $jv->schema( $self->config->re_stored_queries_paths->{ $sq } );

        $sq_data->{ by_query }{ $sq }{ id } = $sq;
        for ( qw( name title description ) ) {
            $sq_data->{ by_query }{ $sq }{ $_ } = $jv->get( '/' . $_ )
                if $jv->get( '/' . $_ );
        }

        for my $param ( keys %{ $jv->get( '/params/properties' ) } ) {
            # we have already seen this param
            if ( $sq_data->{ param }{ $param } ) {
                # delete $sq_data->{ param }{ $param }{ display }{ 'long-hint' };
                $sq_data->{ by_query }{ $sq }{ params }{ $param } = $sq_data->{ param }{ $param };
                next;
            }

            $sq_data->{ param }{ $param }{ spec } = $self->extract_spec_data(
                $jv, $param, '/params/properties/' . $param
            );

            $sq_data->{ param }{ $param }{ display } = {
                'ui-name'     => $jv->get( '/params/properties/' . $param . '/title' ),
                'short-hint'  => $jv->get( '/params/properties/' . $param . '/description' ),
            };

            my $type = $jv->get( '/params/properties/' . $param . '/type' );
            if ( $type eq 'array' ) {
                my $item_type = $jv->get( '/params/properties/' . $param . '/items/type' ) || 'string';
                $type = 'list<' . $item_type . '>';
            }
            $sq_data->{ param }{ $param }{ type } = $type;

            # $sq_data->{ $param }{ bundle } = $jv->bundle( {
            #     schema => $jv->get( '/params/properties/' . $param )
            # } );

            if ( $sq_data->{ param }{ $param }{ spec }{ field_type } eq 'textarea' ) {
                $sq_data->{ param }{ $param }{ display }{ 'short-hint' } .= ". Enter each ID on a new line.";
            }
            $sq_data->{ by_query }{ $sq }{ params }{ $param } = $sq_data->{ param }{ $param };
        }
        my $grouper = $self->_generate_param_group( $sq_data->{ by_query }{ $sq } );

    }

    return $sq_data;
}

=head2 extract_spec_data

Given the JSON schema for a parameter, generate the spec.json data structure

@param {object} $schema
@param {string} $param
@param {prefix} $prefix

=cut

sub extract_spec_data {
    my ( $self, $schema, $param, $prefix ) = @_;

    my $input_type;
    my $type = $schema->get( $prefix . '/type' );
    if ( $type eq 'array' ) {
        # oneOf: multi-select at the moment
        $input_type = 'dropdown' if $schema->get( $prefix . '/items/oneOf' );

        # otherwise, use a text area
        $input_type //= 'textarea';
    }
    # anything else: use a text box
    $input_type //= 'text';

    my $spec = {
        id              => $param,
        optional        => \1,
        advanced        => \0,
        allow_multiple  => \0,
        field_type      => $input_type,
    };

    # set the min / max if the schema specifies them
    if ( $type eq 'integer' ) {
        $spec->{ text_options } = { validate_as => 'int' };
        $spec->{ text_options }{ min_int } = $schema->get( $prefix . '/minimum' )
            if defined $schema->get( $prefix . '/minimum' );
        $spec->{ text_options }{ max_int } = $schema->get( $prefix . '/maximum' )
            if defined $schema->get( $prefix . '/maximum' );
    }

    if ( $input_type eq 'dropdown' ) {
        $spec->{ dropdown_options } = {
            # set up the label and value for each dropdown option
            options => [ map {
                { display => $_->{ title }, value => $_->{ const } }
            } @{ $schema->get( $prefix . '/items/oneOf' ) } ],
            # this param should allow multiple selection, but the narrative UI
            # does not have an implementation for it yet
            multiselection => \1,
        };
        $spec->{ allow_multiple } = \1;
    }

    # default to 4 rows for textareas
    if ( $input_type eq 'textarea' ) {
        $spec->{ textarea_options } = { n_rows => 4 };
    }

    return $spec;
}

=head2 generate_app_spec

Generate the <appname>.spec file from a template

Note: this will overwrite any existing file at $output_file.

Note 2: this is nowhere near a complete generator for the spec file; it only really generates
the specs for a single stored_queries method

@param {hashref} $data        # data from the compile_data method

@param {string}  $output_file # path for the output file

@param {string}  $method_name # name of the method to generate the file for; if not specified,
                              # uses the first method in the app metadata

=cut

sub generate_app_spec {
    my ( $self, $data, $output_file, $method_name ) = @_;

    my $method_data = $self->_get_method_data( $data, $method_name );

    $self->_file_write_checks( $output_file );
    render_template(
        $self->app_spec_template_path->canonpath,
        {
            template_data =>  $data,
            method_data   =>  $method_data,
        },
        ref $output_file ? $output_file->canonpath : $output_file
    );
    return;
}

=head3 _get_method_data

Given a method name, retrieve the information about it from app metadata

If no method is supplied, return data for the first method.

=cut

sub _get_method_data {
    my ( $self, $data, $method_name ) = @_;

    return $data->{ methods }[ 0 ] unless $method_name;

    my @matches = grep { $method_name eq $_->{ method_name } } @{ $data->{ methods } };
    die "Metadata for method $method_name not found" unless @matches;
    return $matches[ 0 ];
}

=head2 generate_display_yaml

Generate the display.yaml file used to generate UI elements

Note: no checks are done when writing the file.

@param {hashref} $data        # data from the compile_data method

@param {string}  $output_file # path for the output file

@param {string}  $method_name # name of the method to generate the file for; if not specified,
                              # uses the first method in the app metadata

=cut

sub generate_display_yaml {
    my ( $self, $data, $output_file, $method_name ) = @_;

    my $method_data = $self->_get_method_data( $data, $method_name );

    my $metadata_params = {};
    # any params specified in the metadata.yaml file that have display info
    if ( $method_data->{ parameters } && $method_data->{ parameters }{ input } ) {
        for ( keys %{ $method_data->{ parameters }{ input } } ) {
            $metadata_params->{ $_ } = $method_data->{ parameters }{ input }{ $_ }{ display }
                if $method_data->{ parameters }{ input }{ $_ }{ display };
        }
    }

    my $display_data = {
        # name of the method listed in the UI
        name          => $method_data->{ human_method_name }
            // $method_data->{ method_name },
        # more detailed explanation of the method shown on a mouse-over event
        tooltip       => $method_data->{ tooltip }
            // $method_data->{ human_method_name } . '!'
            // $method_data->{ method_name } . '!',

        # list of names of screenshot files from the img sub-folder
        screenshots   => $method_data->{ screenshots } // [],

        # (optional) name of an icon file from the img sub-folder.
        icon          => $method_data->{ icon } // 'icon.png',

        # very detailed explanation of what this method does, appearing on a separate page
        description   => $method_data->{ description },

        # parameter IDs (defined in spec.json) mapped to objects to objects
        # that define textual information for these parameters (see details below)
        parameters    => {
            # metadata.yaml params
            %$metadata_params,
            # data from the stored queries
            map {
                $_ => $data->{ stored_queries }{ param }{ $_ }{ display }
            } keys %{ $data->{ stored_queries }{ param } }
        },

        # related methods
        # 'method-suggestions'  => [],

        # publications          => [],

    };

    $self->_file_write_checks( $output_file );
    DumpFile( ref $output_file ? $output_file->canonpath : $output_file, $display_data );
    return;
}

=head2 generate_kbase_yaml

Generate the kbase.yml file, which contains general information about the module

Note: this will overwrite any existing file at $output_file.

@param {hashref} $data        # data from the compile_data method

@param {string}  $output_file # path for the output file

=cut

sub generate_kbase_yaml {
    my ( $self, $data, $output_file ) = @_;

    my $output = {
        'module-name'         => $data->{ module_name },
        'module-description'  => $data->{ description },
        'service-language'    => $data->{ service_language },
        'module-version'      => $data->{ version },
        'owners'              => [ map { $_->{ id } } @{ $data->{ owners } } ],
    };

    $self->_file_write_checks( $output_file );
    DumpFile( ref $output_file ? $output_file->canonpath : $output_file, $output );

    return;
}

=head2 generate_spec_json

Generate the spec.json file used to generate UI elements

Note: this will overwrite any existing file at $output_file.

@param {hashref} $data        # data from the compile_data method

@param {string}  $output_file # path for the output file

@param {string}  $method_name # name of the method to generate the file for; if not specified,
                              # uses the first method in the app metadata

=cut

sub generate_spec_json {
    my ( $self, $data, $output_file, $method_name ) = @_;

    my $method_data = $self->_get_method_data( $data, $method_name );

    my $params;
    my $input_mapping;

    if ( $method_data->{ parameters } && $method_data->{ parameters }{ input } ) {
        for ( keys %{ $method_data->{ parameters }{ input } } ) {

            push @$params, $method_data->{ parameters }{ input }{ $_ }{ spec }
                if $method_data->{ parameters }{ input }{ $_ }{ spec };

            push @$input_mapping, {
                $method_data->{ parameters }{ input }{ $_ }{ mapping } => $_,
                target_property => $_,
            };
        }
    }

    for ( keys %{ $data->{ stored_queries }{ param } } ) {
        push @$params, $data->{ stored_queries }{ param }{ $_ }{ spec };
        push @$input_mapping, {
            input_parameter => $_,
            target_property => $_,
        };
    }

    my $output = [ sort keys %{ $method_data->{ parameters }{ output } } ];

    my $spec = {
        ver        => $data->{ version },
        authors    => [ map { $_->{ id } } @{ $data->{ authors } } ],
        contact    => $data->{ owners }[ 0 ]{ email },
        categories => $method_data->{ categories } // [ 'inactive' ],
        widgets             => {
            input   => undef,
            output  => undef,
        },
        parameters => [ sort { $a->{ id } cmp $b->{ id } } @$params ],
        job_id_output_field => "docker",
        behavior => {
            'service-mapping'   => {
                url           => '',
                name          => $data->{ module_name },
                method        => $method_data->{ method_name },
                input_mapping => [ sort {
                    $a->{ target_property } cmp $b->{ target_property }
                } @$input_mapping ],
                output_mapping => [
                    map {
                        {
                            service_method_output_path  => [0, $_],
                            target_property             => $_,
                        }
                    } @$output
                ]
            }
        }
    };

    $self->_file_write_checks( $output_file );
    path( $output_file )->spew_utf8( encode_json $spec );

    return;
}

sub _generate_param_group {
    my ( $self, $stored_query_data ) = @_;

    return {
        id              => $stored_query_data->{ id },
        # stored query name
        ui_name         => $stored_query_data->{ title } || $stored_query_data->{ name },
        # stored query description
        description     => $stored_query_data->{ description } || '',
        # the permissible params for the query
        parameter_ids   => [map {
            $stored_query_data->{ id } . $self->param_join_str . $_
        } sort keys %{ $stored_query_data->{ params } } ],
        optional        => 1,  # default 0
        advanced        => 1,  # default 0
        with_border     => 1,
    };
}

1;
