package kb_cytoscape::kb_cytoscapeImpl;

use strict;
use warnings;

use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION = '0.0.1';
our $GIT_URL = 'https://github.com/ialarmedalien/kb_cytoscape.git';
our $GIT_COMMIT_HASH = '705b53941a72c9c671df726499c9958a865b3d51';

=head1 NAME

kb_cytoscape

=head1 DESCRIPTION

A KBase module: kb_cytoscape

=cut

#BEGIN_HEADER

use feature qw( say );
use File::Spec::Functions qw( catfile catdir );
use File::Copy;
use Bio::KBase::AuthToken;
use Bio::KBase::Templater qw( render_template );
use installed_clients::KBaseReportClient;
use installed_clients::WorkspaceClient;
use Config::IniFiles;
use Data::UUID;
#END_HEADER

sub new {
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;

    #BEGIN_CONSTRUCTOR

    my $config_file = $ENV{ 'KB_DEPLOYMENT_CONFIG' };
    my $cfg         = Config::IniFiles->new( -file => $config_file );

    my $auth_token  = Bio::KBase::AuthToken->new(
        token           => $ENV{ 'KB_AUTH_TOKEN' },
        ignore_authrc   => 1,
        auth_svc        => $cfg->val( 'kb_cytoscape', 'auth-service-url' ),
    );

    $self->{ appdir }       = $cfg->val( 'kb_cytoscape', 'appdir' );
    $self->{ scratch }      = $cfg->val( 'kb_cytoscape', 'scratch' );
    $self->{ ws_url }       = $cfg->val( 'kb_cytoscape', 'workspace-url' );
    $self->{ callbackURL }  = $ENV{ SDK_CALLBACK_URL };
    $self->{ ws_client }    = installed_clients::WorkspaceClient->new(
        $self->{ ws_url }, token => $ENV{ 'KB_AUTH_TOKEN' },
    );

    #END_CONSTRUCTOR

    $self->_init_instance() if $self->can( '_init_instance' );

    return $self;
}

=head1 METHODS



=head2 run_kb_cytoscape

  $output = $obj->run_kb_cytoscape($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a kb_cytoscape.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a kb_cytoscape.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description

This example function accepts any number of parameters and returns results in a KBaseReport

=back

=cut

sub run_kb_cytoscape {
    my ( $self, $params ) = @_;
    my @bad_arguments;

    push @bad_arguments,
        { argument => "params", value => $params }
        unless ref($params) eq 'HASH';

    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error       => format_error_string( 'argument', 'run_kb_cytoscape', \@bad_arguments ),
        method_name => 'run_kb_cytoscape',
    ) if @bad_arguments;

    my $ctx = $kb_cytoscape::kb_cytoscapeServer::CallContext;
    my ( $output );
    #BEGIN run_kb_cytoscape
    say 'Starting run_kb_cytoscape at ' . localtime(time);

    my $kb_report_client = installed_clients::KBaseReportClient->new( $self->{ callbackURL } );

    # create the cytoscape report
    my $uuid = Data::UUID->new->create->to_string;
    mkdir( catdir( $self->{ scratch }, $uuid ) );
    my $cytoscape_path = catfile( $self->{ scratch }, $uuid, 'cytoscape.html' );


    render_template(
        catfile( $self->{ appdir }, 'views', 'cytoscape.tt' ),
        { template_data => '' },
        $cytoscape_path,
    );

    my $data_dir = catdir( $self->{ appdir }, 'data' );
    copy(
        catfile( $data_dir, 'djornl_dataset.json' ),
        catfile( $self->{ scratch }, $uuid, 'djornl_dataset.json' )
    );

    my $report = $kb_report_client->create_extended_report( {
        workspace_name => $params->{ workspace_name },
        html_links      => [
            {
                name        => 'cytoscape',
                path        => catdir( $self->{ scratch }, $uuid ),
                description => 'Cytoscape graph viewer',
            }
        ],
        direct_html_link_index  => 0,
        report_object_name      => 'Cytoscape_Report',
    } );

    $output = {
        report_name => $report->{ name },
        report_ref  => $report->{ ref }
    };

    say 'Finishing run at ' . localtime(time);
    #END run_kb_cytoscape
    my @bad_returns;
    push @bad_returns,
        { argument => "output", value => $output }
        unless ref($output) eq 'HASH';

    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error       => format_error_string( 'return', 'run_kb_cytoscape', \@bad_returns ),
        method_name => 'run_kb_cytoscape',
    ) if @bad_returns;

    return ( $output );
}




=head2 status

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my $return;
    #BEGIN_STATUS
    $return = {
        "state"           => "OK",
        "message"         => "",
        "version"         => $VERSION,
        "git_url"         => $GIT_URL,
        "git_commit_hash" => $GIT_COMMIT_HASH
    };

    #END_STATUS
    return ( $return );
}

=head1 TYPES



=head2 ReportResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=cut

sub format_error_string {
    my ( $type, $method_name, $values ) = @_;

    $type = 'return value' if $type ne 'argument';

    my @strings = map {
        "\tInvalid type for $type '"
        . $_->{ argument } . "' "
        . "(value was '" . $_->{ value } . "')"
    } @$values;

    return join "\n", "Invalid " . $type . "s passed to $method_name:", @strings;
}


1;
