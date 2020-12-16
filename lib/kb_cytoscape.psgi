use strict;
use warnings;

use kb_cytoscape::kb_cytoscapeImpl;
use kb_cytoscape::kb_cytoscapeServer;
use Plack::Middleware::CrossOrigin;

my %dispatch = (
    'kb_cytoscape' => kb_cytoscape::kb_cytoscapeImpl->new,
);

my $server = kb_cytoscape::kb_cytoscapeServer->new(
    instance_dispatch => \%dispatch,
    allow_get         => 0,
);

my $handler    = Plack::Middleware::CrossOrigin->wrap(
    sub { $server->handle_input(@_) },
    origins => "*",
    headers => "*"
);
