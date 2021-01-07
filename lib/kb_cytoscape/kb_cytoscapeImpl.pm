package kb_cytoscape::kb_cytoscapeImpl;

use strict;
use warnings;

use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION            = version();
our $GIT_URL            = 'https://github.com/ialarmedalien/kb_cytoscape.git';
our $GIT_COMMIT_HASH    = '445b2c262e1224d844468b1cf4a8619edce9f36a';

=head1 NAME

kb_cytoscape

=head1 DESCRIPTION

kb_cytoscape

=cut

#BEGIN_HEADER
use feature qw( say );
use Path::Tiny;
use Bio::KBase::Config;
use Bio::KBase::CytoscapeClient;

sub version { Bio::KBase::Config->instance->version }

# ugly but necessary
$VERSION = version();

#END_HEADER

sub new {
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;

    #BEGIN_CONSTRUCTOR

    #END_CONSTRUCTOR

    if ( $self->can( '_init_instance' ) ) {
        $self->_init_instance();
    }
    return $self;
}

=head1 METHODS


=head2 run_kb_cytoscape

  $output = $obj->run_kb_cytoscape($params)

=over

=item Parameter and return types

=begin html

<pre>
$params is a kb_cytoscape.run_kb_cytoscape_input
$output is a kb_cytoscape.ReportResults
run_kb_cytoscape_input is a reference to a hash where the following keys are defined:
	dry_run has a value which is an int
	workspace_id has a value which is a string
	cluster_ids has a value which is a reference to a list where each element is a string
	distance has a value which is an int
	edge_types has a value which is a reference to a list where each element is a string
	gene_keys has a value which is a reference to a list where each element is a string
	phenotype_keys has a value which is a reference to a list where each element is a string
	search_text has a value which is a string
ReportResults is a reference to a hash where the following keys are defined:
	query_params has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_cytoscape.run_kb_cytoscape_input
$output is a kb_cytoscape.ReportResults
run_kb_cytoscape_input is a reference to a hash where the following keys are defined:
	dry_run has a value which is an int
	workspace_id has a value which is a string
	cluster_ids has a value which is a reference to a list where each element is a string
	distance has a value which is an int
	edge_types has a value which is a reference to a list where each element is a string
	gene_keys has a value which is a reference to a list where each element is a string
	phenotype_keys has a value which is a reference to a list where each element is a string
	search_text has a value which is a string
ReportResults is a reference to a hash where the following keys are defined:
	query_params has a value which is a string
	report_name has a value which is a string
	report_ref has a value which is a string


=end text


=item Description

run_kb_cytoscape accepts input in the form specified by run_kb_cytoscape_input
and returns results in a KBaseReport

=back

=cut

sub run_kb_cytoscape {
    my $self = shift;
    my ( $params ) = @_;

    my @bad_arguments;
    ( ref($params) eq 'HASH' ) or push @bad_arguments,
        "Invalid type for argument \"params\" "
        . "(value was \"$params\")";
    if ( @bad_arguments ) {
        my $msg = "Invalid arguments passed to run_kb_cytoscape:\n"
            . join "", map { "\t$_\n" } @bad_arguments;
        Bio::KBase::Exceptions::ArgumentValidationError->throw(
            error       => $msg,
            method_name => 'run_kb_cytoscape'
        );
    }

#    my $ctx = $kb_cytoscape::kb_cytoscapeServer::CallContext;
    my ( $output );
    #BEGIN run_kb_cytoscape

    say 'Starting run at ' . localtime(time);
    my $cytoscape_client = Bio::KBase::CytoscapeClient->new;
    $output = $cytoscape_client->run( $params );
    say 'Finished run at ' . localtime(time);

    #END run_kb_cytoscape
    my @bad_returns;
    ( ref($output) eq 'HASH' ) or push @bad_returns,
        "Invalid type for return variable \"output\" "
        . "(value was \"$output\")";
    if ( @bad_returns ) {
        my $msg = "Invalid returns passed to run_kb_cytoscape:\n"
            . join "", map { "\t$_\n" } @bad_returns;
        Bio::KBase::Exceptions::ArgumentValidationError->throw(
            error       => $msg,
            method_name => 'run_kb_cytoscape'
        );
    }
    return ( $output );
}




=head2 status

  $return = $obj->status()

=over

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
        "message"         => "All quiet on the western front",
        "version"         => Bio::KBase::Config->instance->version,
        "git_url"         => $GIT_URL,
        "git_commit_hash" => $GIT_COMMIT_HASH
    };
    #END_STATUS
    return ( $return );
}

=head1 TYPES


=head2 run_kb_cytoscape_input

=over


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
dry_run has a value which is an int
workspace_id has a value which is a string
cluster_ids has a value which is a reference to a list where each element is a string
distance has a value which is an int
edge_types has a value which is a reference to a list where each element is a string
gene_keys has a value which is a reference to a list where each element is a string
phenotype_keys has a value which is a reference to a list where each element is a string
search_text has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
dry_run has a value which is an int
workspace_id has a value which is a string
cluster_ids has a value which is a reference to a list where each element is a string
distance has a value which is an int
edge_types has a value which is a reference to a list where each element is a string
gene_keys has a value which is a reference to a list where each element is a string
phenotype_keys has a value which is a reference to a list where each element is a string
search_text has a value which is a string


=end text

=back


=head2 ReportResults

=over


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
query_params has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
query_params has a value which is a string
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back


=cut

1;
