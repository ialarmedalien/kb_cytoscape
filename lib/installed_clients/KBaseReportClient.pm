=cut

default_service_url: ${default_service_url}
client_package_name: installed_clients::KBaseReportClient
server_package_name: ${server_package_name}
enable_client_retry: ${enable_client_retry}
display: org.apache.commons.lang.StringUtils@17497425
async_version: release
dynserv_ver: ${dynserv_ver}
service_ver: release

# if async
any_async: ${any_async}

=cut
package installed_clients::KBaseReportClient;

use strict;
use warnings;

use JSON::RPC::Client;
use POSIX;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Time::HiRes;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

installed_clients::KBaseReportClient

=head1 DESCRIPTION


Module for workspace data object reports, which show the results of running a job in an SDK app.


=cut

sub new {
    my ( $class, $url, @args ) = @_;

    my $self = {
        client  => installed_clients::KBaseReportClient::RpcClient->new,
        url     => $url,
        headers => [],
    };
    my %arg_hash = @args;

    $self->{ async_job_check_time } = 0.1;
    if ( exists $arg_hash{ async_job_check_time_ms } ) {
        $self->{ async_job_check_time } = $arg_hash{ async_job_check_time_ms } / 1000.0;
    }

    $self->{ async_job_check_time_scale_percent } = 150;
    if ( exists $arg_hash{ async_job_check_time_scale_percent } ) {
        $self->{ async_job_check_time_scale_percent } = $arg_hash{ async_job_check_time_scale_percent };
    }

    $self->{ async_job_check_max_time } = 300;    # 5 minutes
    if ( exists $arg_hash{ async_job_check_max_time_ms } ) {
        $self->{ async_job_check_max_time } = $arg_hash{ async_job_check_max_time_ms } / 1000.0;
    }

    my $service_version = 'release';

    $service_version    = $arg_hash{ service_version }
        if exists $arg_hash{ service_version };
    $self->{ service_version }  = $service_version;

    chomp( $self->{ hostname } = `hostname` );
    $self->{ hostname } ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ( $ENV{ KBRPC_TAG } ) {
        $self->{ kbrpc_tag } = $ENV{ KBRPC_TAG };
    }
    else {
        my ( $t, $us )       = &$get_time();
        $us                  = sprintf( "%06d", $us );
        my $ts               = strftime( "%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t );
        $self->{ kbrpc_tag } = "C:$0:$self->{hostname}:$$:$ts";
    }
    push @{ $self->{ headers } }, 'Kbrpc-Tag', $self->{ kbrpc_tag };

    if ( $ENV{ KBRPC_METADATA } ) {
        $self->{ kbrpc_metadata } = $ENV{ KBRPC_METADATA };
        push @{ $self->{ headers } }, 'Kbrpc-Metadata', $self->{ kbrpc_metadata };
    }

    if ( $ENV{ KBRPC_ERROR_DEST } ) {
        $self->{ kbrpc_error_dest } = $ENV{ KBRPC_ERROR_DEST };
        push @{ $self->{ headers } }, 'Kbrpc-Errordest', $self->{ kbrpc_error_dest };
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.
    if ( exists $arg_hash{ token } ) {
        $self->{ token } = $arg_hash{ token };
    }
    elsif ( exists $arg_hash{ user_id } ) {
        my $token = Bio::KBase::AuthToken->new( @args );
        $self->{ token } = $token->token unless $token->error_message;
    }

    $self->{ client }{ token } = $self->{ token } if $self->{ token };

    my $ua      = $self->{ client }->ua;
    my $timeout = $ENV{ CDMI_TIMEOUT } || ( 30 * 60 );
    $ua->timeout( $timeout );
    bless $self, $class;
    return $self;
}

# Authentication: ${method.authentication}
sub _check_job {
    my ( $self, @args ) = @_;

    my $job_id = shift @args;

    my $args_specs = [
        {
            index       => 0,
            name        => 'job_id',
            value       => $job_id,
            validator   => sub { ! ref $job_id },
        }
    ];

    $self->_validate_params( '_check_job', 1, $args_specs, [ $job_id ] );

    my $result = $self->_client_call(
        '_check_job',
        $self->{ url },
        $self->{ headers },
        {
            method => "KBaseReport._check_job",
            params => [ $job_id ],
        }
    );

    return $result->result->[ 0 ];
}




=head2 create

  $info = $obj->create($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBaseReport.CreateParams
$info is a KBaseReport.ReportInfo
CreateParams is a reference to a hash where the following keys are defined:
	report has a value which is a KBaseReport.SimpleReport
	workspace_name has a value which is a string
	workspace_id has a value which is an int
SimpleReport is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	direct_html has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.CreateParams
$info is a KBaseReport.ReportInfo
CreateParams is a reference to a hash where the following keys are defined:
	report has a value which is a KBaseReport.SimpleReport
	workspace_name has a value which is a string
	workspace_id has a value which is an int
SimpleReport is a reference to a hash where the following keys are defined:
	text_message has a value which is a string
	direct_html has a value which is a string
	warnings has a value which is a reference to a list where each element is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

Function signature for the create() method -- generate a simple,
text-based report for an app run.
@deprecated KBaseReport.create_extended_report

=back

=cut

sub create {
    my ( $self, @args ) = @_;
    my $job_id          = $self->_create_submit( @args );
    return $self->_async_job_check( $job_id );
}

# Authentication: required
sub _create_submit {
    my ( $self, @args ) = @_;

    my ( $params ) = @args;
    my $args_specs = [
        {   index       => 1,
            name        => 'params',
            value       => $params,
            validator   => sub { ref($params) eq 'HASH' },
            baretype    => 'struct',
        },
    ];
    $self->_validate_params( '_create_submit', 1, $args_specs, \@args );


    my $context = undef;
    if ( $self->{ service_version } ) {
        $context = { 'service_ver' => $self->{ service_version } };
    }

    my $result = $self->_client_call(
        '_create_submit',
        $self->{ url },
        $self->{ headers },
        {
            method  => "KBaseReport._create_submit",
            params  => \@args,
            context => $context
        }
    );

    return $result->result->[ 0 ];
}

 

=head2 create_extended_report

  $info = $obj->create_extended_report($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a KBaseReport.CreateExtendedReportParams
$info is a KBaseReport.ReportInfo
CreateExtendedReportParams is a reference to a hash where the following keys are defined:
	message has a value which is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	warnings has a value which is a reference to a list where each element is a string
	html_links has a value which is a reference to a list where each element is a KBaseReport.File
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
	workspace_id has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string

</pre>

=end html

=begin text

$params is a KBaseReport.CreateExtendedReportParams
$info is a KBaseReport.ReportInfo
CreateExtendedReportParams is a reference to a hash where the following keys are defined:
	message has a value which is a string
	objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
	warnings has a value which is a reference to a list where each element is a string
	html_links has a value which is a reference to a list where each element is a KBaseReport.File
	direct_html has a value which is a string
	direct_html_link_index has a value which is an int
	file_links has a value which is a reference to a list where each element is a KBaseReport.File
	report_object_name has a value which is a string
	html_window_height has a value which is a float
	summary_window_height has a value which is a float
	workspace_name has a value which is a string
	workspace_id has a value which is an int
WorkspaceObject is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	description has a value which is a string
ws_id is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
	name has a value which is a string
	label has a value which is a string
	description has a value which is a string
ReportInfo is a reference to a hash where the following keys are defined:
	ref has a value which is a KBaseReport.ws_id
	name has a value which is a string


=end text

=item Description

Create a report for the results of an app run. This method handles file
and HTML zipping, uploading, and linking as well as HTML rendering.

=back

=cut

sub create_extended_report {
    my ( $self, @args ) = @_;
    my $job_id          = $self->_create_extended_report_submit( @args );
    return $self->_async_job_check( $job_id );
}

# Authentication: required
sub _create_extended_report_submit {
    my ( $self, @args ) = @_;

    my ( $params ) = @args;
    my $args_specs = [
        {   index       => 1,
            name        => 'params',
            value       => $params,
            validator   => sub { ref($params) eq 'HASH' },
            baretype    => 'struct',
        },
    ];
    $self->_validate_params( '_create_extended_report_submit', 1, $args_specs, \@args );


    my $context = undef;
    if ( $self->{ service_version } ) {
        $context = { 'service_ver' => $self->{ service_version } };
    }

    my $result = $self->_client_call(
        '_create_extended_report_submit',
        $self->{ url },
        $self->{ headers },
        {
            method  => "KBaseReport._create_extended_report_submit",
            params  => \@args,
            context => $context
        }
    );

    return $result->result->[ 0 ];
}

  
sub status {
    my ( $self, @args ) = @_;

    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error   =>  "Invalid argument count for function status "
                    . "(received " . scalar @args . ", expecting 0)"
    ) if @args;

    my $context = undef;
    $context = { 'service_ver' => $self->{ service_version } }
        if $self->{ service_version };

    my $result = $self->_client_call(
        '_status_submit',
        $self->{ url },
        $self->{ headers },
        {
            method  => "KBaseReport._status_submit",
            params  => \@args,
            context => $context
        }
    );

    my $job_id = $result->result->[ 0 ];

    return $self->_async_job_check( $job_id );

}
   
sub version {
    my ( $self ) = @_;

    my $result = $self->_client_call(
        'create_extended_report',
        $self->{ url },
        $self->{ headers },
        {
            method => "KBaseReport.version",
            params => [],
        }
    );

    return wantarray
        ? @{ $result->result }
        : $result->result->[ 0 ];
}

sub _validate_version {
    my ($self) = @_;
    my $server_version = $self->version();
    my $client_version = $VERSION;
    my ( $client_major, $client_minor ) = split(/\./, $client_version);
    my ( $server_major, $server_minor ) = split(/\./, $server_version);

    if ( $server_major != $client_major ) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error           => "Major version numbers differ.",
            server_version  => $server_version,
            client_version  => $client_version
        );
    }

    if ( $server_minor < $client_minor ) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error           => "Client minor version greater than server minor version.",
            server_version  => $server_version,
            client_version  => $client_version
        );
    }

    if ( $server_minor > $client_minor ) {
        warn "New client version available for installed_clients::KBaseReportClient\n";
    }

    if ( $server_major == 0 ) {
        warn "installed_clients::KBaseReportClient version is $server_version. API subject to change.\n";
    }
}

sub get_service_status {
    my ( $self, $module_name ) = @_;

    return $self->_client_call(
        'ServiceWizard.get_service_status',
        $self->{ url },
        $self->{ headers },
        {
            method => "ServiceWizard.get_service_status",
            params => [ {
                module_name => $module_name,
                version     => $self->{ service_version }
            } ]
        }
    );
}

sub _client_call {
    my ( $self, $method, @call_args ) = @_;

    my $result = $self->{ client }->call( @call_args );

    Bio::KBase::Exceptions::HTTP->throw(
        error       => "Error invoking method $method",
        status_line => $self->{ client }->status_line,
        method_name => $method,
    ) unless $result;

    Bio::KBase::Exceptions::JSONRPC->throw(
        error       => $result->error_message,
        code        => $result->content->{ error }{ code },
        method_name => $method,
        # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
        data        => $result->content->{ error }{ error }
    ) if $result->is_error;

    return $result;
}

sub _async_job_check {
    my ( $self, $job_id ) = @_;
    my $async_job_check_time = $self->{ async_job_check_time };

    while ( 1 ) {
        Time::HiRes::sleep( $async_job_check_time );

        $async_job_check_time *= $self->{ async_job_check_time_scale_percent } / 100.0;
        if ( $async_job_check_time > $self->{ async_job_check_max_time } ) {
            $async_job_check_time = $self->{ async_job_check_max_time };
        }

        my $job_state_ref = $self->_check_job( $job_id );

        if ( $job_state_ref->{ finished } != 0 ) {
            $job_state_ref->{ result } //= [];

            return wantarray
                ? @{ $job_state_ref->{ result } }
                : $job_state_ref->{ result }->[ 0 ];
        }
    }
}

sub _validate_params {
    my ( $self, $method, $expected_arg_count, $specs, $args ) = @_;

    Bio::KBase::Exceptions::ArgumentValidationError->throw(
        error   =>  "Invalid argument count for function $method "
                    . "(received " . ( scalar @$args ) . ", expecting $expected_arg_count)"
    ) unless @$args == $expected_arg_count;

    my @bad_arguments;

    for ( @$specs ) {
        push @bad_arguments,
             'Invalid type for argument ' . $_->{ index }
             . ' "' . $_->{ name } . '" '
             . '(value was "'
             . $_->{ value } . '")'
            unless $_->{ validator }->();
    }
# foreach( $param in $method.params )
#     push @bad_arguments,
#         "Invalid type for argument ${param.index} \"${param.name}\" (value was \"${param.perl_var}\")"
#         unless ${param.validator};
# end
    if ( @bad_arguments ) {

        my $msg = "Invalid arguments passed to $method:\n"
            . join "", map { "\t$_\n" } @bad_arguments;

        Bio::KBase::Exceptions::ArgumentValidationError->throw(
            error       => $msg,
            method_name => '$method',
        );
    }

}

=head1 TYPES



=head2 ws_id

=over 4



=item Description

* Workspace ID reference in the format 'workspace_id/object_id/version'
* @id ws


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 WorkspaceObject

=over 4



=item Description

* Represents a Workspace object with some brief description text
* that can be associated with the object.
* Required arguments:
*     ws_id ref - workspace ID in the format 'workspace_id/object_id/version'
* Optional arguments:
*     string description - A plaintext, human-readable description of the
*         object created


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
description has a value which is a string


=end text

=back



=head2 SimpleReport

=over 4



=item Description

* A simple report for use in create()
* Optional arguments:
*     string text_message - Readable plain-text report message
*     string direct_html - Simple HTML text that will be rendered within the report widget
*     list<string> warnings - A list of plain-text warning messages
*     list<WorkspaceObject> objects_created - List of result workspace objects that this app
*         has created. They will get linked in the report view


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
text_message has a value which is a string
direct_html has a value which is a string
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
text_message has a value which is a string
direct_html has a value which is a string
warnings has a value which is a reference to a list where each element is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject


=end text

=back



=head2 CreateParams

=over 4



=item Description

* Parameters for the create() method
*
* Pass in *either* workspace_name or workspace_id -- only one is needed.
* Note that workspace_id is preferred over workspace_name because workspace_id immutable.
*
* Required arguments:
*     SimpleReport report - See the structure above
*     string workspace_name - Workspace name of the running app. Required
*         if workspace_id is absent
*     int workspace_id - Workspace ID of the running app. Required if
*         workspace_name is absent


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.SimpleReport
workspace_name has a value which is a string
workspace_id has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report has a value which is a KBaseReport.SimpleReport
workspace_name has a value which is a string
workspace_id has a value which is an int


=end text

=back



=head2 ReportInfo

=over 4



=item Description

* The reference to the saved KBaseReport. This is the return object for
* both create() and create_extended()
* Returned data:
*    ws_id ref - reference to a workspace object in the form of
*        'workspace_id/object_id/version'. This is a reference to a saved
*        Report object (see KBaseReportWorkspace.spec)
*    string name - Plaintext unique name for the report. In
*        create_extended, this can optionally be set in a parameter


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a KBaseReport.ws_id
name has a value which is a string


=end text

=back



=head2 File

=over 4



=item Description

* A file to be linked in the report. Pass in *either* a shock_id or a
* path. If a path to a file is given, then the file will be uploaded. If a
* path to a directory is given, then it will be zipped and uploaded.
* Required arguments:
*     string path - Can be a file or directory path. Required if shock_id is absent
*     string shock_id - Shock node ID. Required if path is absent
*     string name - Plain-text filename (eg. "results.zip") -- shown to the user
* Optional arguments:
*     string label - A short description for the file (eg. "Filter results")
*     string description - A more detailed, human-readable description of the file


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
name has a value which is a string
label has a value which is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string
name has a value which is a string
label has a value which is a string
description has a value which is a string


=end text

=back



=head2 CreateExtendedReportParams

=over 4



=item Description

* Parameters used to create a more complex report with file and HTML links
*
* Pass in *either* workspace_name or workspace_id -- only one is needed.
* Note that workspace_id is preferred over workspace_name because workspace_id immutable.
*
* Required arguments:
*     string workspace_name - Name of the workspace where the report
*         should be saved. Required if workspace_id is absent
*     int workspace_id - ID of workspace where the report should be saved.
*         Required if workspace_name is absent
* Optional arguments:
*     string message - Simple text message to store in the report object
*     list<WorkspaceObject> objects_created - List of result workspace objects that this app
*         has created. They will be linked in the report view
*     list<string> warnings - A list of plain-text warning messages
*     list<File> html_links - A list of paths or shock IDs pointing to HTML files or directories.
*         If you pass in paths to directories, they will be zipped and uploaded
*     int direct_html_link_index - Index in html_links to set the direct/default view in the
*         report. Set either direct_html_link_index or direct_html, but not both
*     string direct_html - Simple HTML text content that will be rendered within the report
*         widget. Set either direct_html or direct_html_link_index, but not both
*     list<File> file_links - A list of file paths or shock node IDs. Allows the user to
*         specify files that the report widget should link for download. If you pass in paths
*         to directories, they will be zipped
*     string report_object_name - Name to use for the report object (will
*         be auto-generated if unspecified)
*     html_window_height - Fixed height in pixels of the HTML window for the report
*     summary_window_height - Fixed height in pixels of the summary window for the report


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string
workspace_id has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
message has a value which is a string
objects_created has a value which is a reference to a list where each element is a KBaseReport.WorkspaceObject
warnings has a value which is a reference to a list where each element is a string
html_links has a value which is a reference to a list where each element is a KBaseReport.File
direct_html has a value which is a string
direct_html_link_index has a value which is an int
file_links has a value which is a reference to a list where each element is a KBaseReport.File
report_object_name has a value which is a string
html_window_height has a value which is a float
summary_window_height has a value which is a float
workspace_name has a value which is a string
workspace_id has a value which is an int


=end text

=back



=cut

package installed_clients::KBaseReportClient::RpcClient;
use parent 'Bio::KBase::JSONRPCClient';

1;
