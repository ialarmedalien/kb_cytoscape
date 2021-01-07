#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export PERL5LIB=$script_dir/../lib:$PERL5LIB
perl $script_dir/../lib/kb_cytoscape/kb_cytoscapeServer.pm $1 $2 $3
