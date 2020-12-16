#!/bin/bash
echo "Running $0 with args $@"
script_dir=$(dirname "$(readlink -f "$0")")
export KB_DEPLOYMENT_CONFIG=$script_dir/../deploy.cfg
export PERL5LIB=$script_dir/../lib:$PERL5LIB
plackup $script_dir/../lib/kb_cytoscape.psgi
