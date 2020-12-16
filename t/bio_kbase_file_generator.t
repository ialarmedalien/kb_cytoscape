use Test::Most;
use Test::Output;
use Path::Tiny;
use feature qw( say );
use Data::Dumper::Concise;
use Try::Tiny;
use Bio::KBase::Config;

use JSON::MaybeXS;
use YAML::XS qw( :all );
$YAML::XS::Boolean = "JSON::PP";

require_ok 'Bio::KBase::FileGenerator';

# get the current test/data directory path
my $data_dir        = path( $ENV{ TEST_DIR }, 'data' );
my $original_app_spec_template_path = Bio::KBase::FileGenerator->new->app_spec_template_path;

my $expected_data = {
    version           => '6.6.6',
    module_name       => 'yet_another_kbase_module',
    service_language  => 'whitespace',
    owners            => [
      { id => "Tintin", email => 'tintin@herge.org' },
      { id => "Snowy",  email => 'snowy@herge.org' },
    ],
    authors           => [
      { id => "Tintin",             email => 'tintin@herge.org' },
      { id => "Snowy",              email => 'snowy@herge.org' },
      { id => "Captain Haddock",    email => 'capn.haddock@gmail.com' },
      { id => "Bianca Castafiore",  email => 'b.castafiore@gmail.com' },
    ],
    description       => 'Something we came up with on the spur of the moment',
    methods => [{
      method_name       => 'run_yet_another_kbase_method',
      human_method_name => 'Run yet another KBase method',
      description       => 'A long description of all the cool things that this method does.',
      categories        => [
        'active',
        'awesome',
        'cool',
        'things to tell all your friends about',
      ],
      parameters       => {
        input => {
          five_by_five => {
            type    => "int",
            mapping => "constant_value",
          },

          system_variable_a => {
            type    => "string",
            mapping => "narrative_system_variable",
          },

          zero_or_one => {
            type => "int",
            mapping => "input_parameter",
            display => {
              'ui-name'     => "Zero or one?",
              'short-hint'  => "Is this zero or is it one?",
            },
            spec    => {
              id    => "zero_or_one",
              advanced        => JSON::PP::true, # true
              default_values  => [0],
              field_type      => "dropdown",
              optional        => JSON::PP::false, # false
              dropdown_options => {
                options => [{
                  display => "zero",
                  value   => 0,
                },{
                  display => "one",
                  value   => 1,
                }],
              }
            }
          }
        },
        output => {
          report_name => {
            type      => "string",
          },
          report_ref  => {
            type      => "string",
          },
          another_param => {
            type        => "int",
          },
        }
      }
    }],
    # 'method-suggestions' => [],
    stored_queries    => {
      cluster_ids   => {
        spec => {
          'id'               => 'cluster_ids',
          'advanced'         => \0,
          'allow_multiple'   => \0,
          'field_type'       => 'textarea',
          'optional'         => \1,
          'textarea_options' => { 'n_rows' => 4 }
        },
        display => {
          'ui-name'     => 'Cluster IDs',
          'short-hint'  => 'Fetch nodes by cluster ID, in the form "clustering_system_name:cluster_id". Enter each ID on a new line.',
          'long-hint'   => 'Fetch all nodes that are members of the specified cluster(s), and the edges and nodes within the specified distance (number of hops) of those nodes.',
        },
        type => 'list<string>',
      },
      distance => {
        spec => {
          'id'             => 'distance',
          'advanced'       => \0,
          'allow_multiple' => \0,
          'field_type'     => 'text',
          'optional'       => \1,
          'text_options'   => {
            'max_int'      => 100,
            'min_int'      => 0,
            'validate_as'  => 'int'
          },
        },
        display => {
          'ui-name'     => 'Traversal Distance',
          'short-hint'  => 'Number of hops to find neighbors and neighbors-of-neighbors',
        },
        type => 'integer',
      },
      edge_types => {
        spec  => {
          'id'               => 'edge_types',
          'advanced'         => \0,
          'allow_multiple'   => \1,
          'dropdown_options' => {
            'multiselection' => \1,
            'options' => [ {
              'display' => 'AraGWAS phenotype associations',
              'value'   => 'phenotype-association_AraGWAS'
            },
            {
              'display' => 'AraNetv2 pairwise gene coexpression',
              'value'   => 'pairwise-gene-coexpression_AraNet_v2'
            },
            {
              'display' => 'AraNetv2 domain co-occurrence',
              'value'   => 'domain-co-occurrence_AraNet_v2'
            },
            {
              'display' =>
                  'AraNetv2 high-throughput protein-protein interaction',
              'value' => 'protein-protein-interaction_high-throughput_AraNet_v2'
            },
            {
              'display' =>
                  'AraNetv2 literature-curated protein-protein interaction',
              'value' => 'protein-protein-interaction_literature-curation_AraNet_v2'
            } ]
          },
          'field_type' => 'dropdown',
          'optional'   => \1,
        },
        display => {
          'ui-name'     => 'Edge Types',
          'short-hint'  => 'Edge types to filter on',
        },
        type => 'list<string>',
      },
      search_text => {
        spec => {
          'id'             => 'search_text',
          'advanced'       => \0,
          'allow_multiple' => \0,
          'field_type'     => 'text',
          'optional'       => \1,
        },
        display => {
          'ui-name'     => 'Search text',
          'short-hint'  => 'Search nodes and their metadata for the search string',
          'long-hint'   => 'Search for nodes using a simple fuzzy search on node metadata; return the matching nodes, and the edges and nodes within the specified distance (number of hops) of those nodes.',
        },
        type => 'string',
      }
    },
};

subtest 'switch_old_new_files' => sub {

    my $file_generator = Bio::KBase::FileGenerator->new;

    # ensure that the file switch is done correctly
    throws_ok {
        $file_generator->switch_old_new_files( '/path/to/file' )
    }
    qr{New file .*? does not exist}, 'new file does not exist';

    my $temp_dir          = Path::Tiny->tempdir();
    my $target_file       = path( $temp_dir )->child( 'file.txt' )->touch;
    my $target_file_path  = path( $target_file )->canonpath;
    ok path( $target_file_path )->exists, $target_file_path . " exists";
    throws_ok {
        $file_generator->switch_old_new_files( $target_file_path )
    }
    qr{New file .*? does not exist}, 'new file does not exist';

    my $new_target_file_path  = $target_file_path . ".new";
    path( $target_file_path )->move( $new_target_file_path );

    ok path( $new_target_file_path )->exists, $new_target_file_path . " exists";
    throws_ok {
        $file_generator->switch_old_new_files( $target_file_path )
    }
    qr{Existing file .*? does not exist}, 'original file does not exist';

    # recreate the original file
    my $new_file = path( $target_file_path )->touch;
    ok path( $new_file )->exists, path( $new_file )->canonpath . " exists";
    lives_ok {
        $file_generator->switch_old_new_files( $target_file_path )
    }
    'file switch lives ok';

    ok path( $target_file_path . '.old' )->exists,  'old target file exists';
    ok path( $target_file_path )->exists,           'target file exists';
    ok !path( $new_target_file_path )->exists,      'new target file no longer exists';

};

subtest 'amass data' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $data_dir, 'test-metadata-read.cfg' )->canonpath;

    my $file_generator  = Bio::KBase::FileGenerator->new;

    my $metadata        = $file_generator->app_metadata;
    cmp_deeply
        $metadata,
        {
            map   { $_ => $expected_data->{ $_ } }
            grep  { $_ ne 'version' && $_ ne 'stored_queries' } keys %$expected_data
        },
        'read metadata correctly'
        or diag explain $metadata;

    my $stored_queries  = $file_generator->get_stored_queries;
    for my $param ( keys %$stored_queries ) {
        cmp_deeply
            $stored_queries->{ $param },
            $expected_data->{ stored_queries }{ $param },
            'stored query data for ' . $param . ' matches'
        or diag explain {
            got     => $stored_queries->{ $param },
            expect  => $expected_data->{ stored_queries }{ $param },
        };
    }

    cmp_deeply
        $stored_queries,
        $expected_data->{ stored_queries },
        'read stored queries correctly';

    # recreate the file generator and do the whole data gathering routine
    $file_generator  = Bio::KBase::FileGenerator->new;

    my $data = $file_generator->compile_data;
    cmp_deeply
        $data,
        $expected_data,
        'amassed all the data expected';

};

subtest 'generate_files' => sub {

    Bio::KBase::Config->_clear_instance();
    local $ENV{ KB_DEPLOYMENT_CONFIG } = path( $data_dir, 'test-metadata-read.cfg' )->canonpath;
    my $file_generator = Bio::KBase::FileGenerator->new;
    my $app_dir         = $file_generator->config->app_dir;

    my $suffix = {
        kbase_yaml    => 'yaml',
        display_yaml  => 'yaml',
        spec_json     => 'json',
        app_spec      => 'spec',
    };

    # copy the template file over
    path( $file_generator->app_spec_template_path )->parent->mkpath;
    path( $original_app_spec_template_path )->copy( $file_generator->app_spec_template_path );

    path( $app_dir, 'test_files' )->mkpath;

    for my $file_type ( qw( kbase_yaml display_yaml  app_spec spec_json ) ) {

        say 'running tests for ' . $file_type;

        subtest 'generating ' . $file_type => sub {

            my $function  = 'generate_' . $file_type;
            my $path_attr = $file_type . "_path";

            # work out the location of the target file
            my $new_file  = path( $app_dir, 'test_files', $file_type . "." . $suffix->{ $file_type } );

            # remove any existing files
            path( $new_file )->remove;
            ok ! path( $new_file )->exists, 'no ' . $new_file . ' exists';

            $file_generator->$function( $expected_data, $new_file );

            ok path( $new_file )->exists, 'newly-generated file exists';
            my $generated_file_contents = read_file( $new_file );
            my $expected_file_contents = read_file( $file_generator->$path_attr );

            cmp_deeply
                $generated_file_contents,
                $expected_file_contents,
                'generated file matches expected file contents'
                or diag explain {
                  got     => $generated_file_contents,
                  expect  => $expected_file_contents
                };
    #        path( $new_file )->remove;
        };
    }
};

sub read_file {
    my ( $path, $file_format ) = @_;

    $file_format //= $path->canonpath =~ /\.json/
        ? 'json'
        : $path->canonpath =~ /\.(yml|yaml)/
            ? 'yaml'
            : 'text';

    my $actions = {
        json  => sub { decode_json( $path->slurp_utf8 ) },
        yaml  => sub { LoadFile $path->canonpath },
        # remove troublesome whitespace
        text  => sub { [ grep { /\S/ } split /\n/, $path->slurp_utf8 ] },
    };

    return $actions->{ $file_format }->();
}

done_testing;

