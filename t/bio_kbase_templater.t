use Test::Most;
use Test::Output;
use Path::Tiny;

require_ok 'Bio::KBase::Templater';

my $test_dir  = $ENV{ TEST_DIR };
my $template_path = path( $test_dir, 'data', 'test.tt' )->canonpath;

subtest 'populate_template' => sub {

    my $tests = [
    {   args    => [ 'does/not/exist' ],
        error   => qr/template rendering error: file error/i,
        desc    => 'template not found',
    } ];

    for ( @$tests ) {
        throws_ok {
            Bio::KBase::Templater::render_template( @{ $_->{ args } } );
        } $_->{ error }, $_->{ desc };
    }

    # output to STDOUT
    my $stdout = stdout_from {
        ok  Bio::KBase::Templater::render_template(
                $template_path,
                { thing => 'world' },
            ), 'valid output, includes template vars, output to STDOUT';
    };

    my @content = parse_template_string( $stdout );
    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected';

    # output to a scalar
    my $string;
    ok  Bio::KBase::Templater::render_template(
            $template_path,
            {},
            \$string
        ), 'valid output, no template vars, saved to scalar ref';

    @content = parse_template_string( $string );
    cmp_deeply
        \@content,
        [ "Hello", "G'day sport!" ],
        'content as expected'
        or diag explain {
            string  => $string,
            content => \@content,
        };

    undef $string;
    ok  Bio::KBase::Templater::render_template(
            $template_path,
            { thing => 'world' },
            \$string
        ), 'valid output, includes template vars, saved to scalar ref';

    @content = parse_template_string( $string );
    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected'
        or diag explain {
            string  => $string,
            content => \@content,
        };

    my $temp_file = Path::Tiny->tempfile;
    ok  Bio::KBase::Templater::render_template(
            $template_path,
            { thing => 'world' },
            $temp_file->canonpath,
        ), 'valid output, includes template vars, saved to a file';

    @content = parse_template_string( $temp_file->slurp_utf8 );
    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected'
        or diag explain {
            file_slurp  => $temp_file->slurp_utf8,
            content     => \@content,
        };


};

sub parse_template_string {
    my ( $template_string ) = @_;

    return
        # remove leading and trailing whitespace
        map { my $line = $_;
            $line =~ s/(^\s*|\s*$)//g;
            $line;
        }
        # ensure the line has non-whitespace content
        grep { /\S/ }
        # split on any line break type
        split /[\n\r]+/, $template_string;
}

done_testing;
