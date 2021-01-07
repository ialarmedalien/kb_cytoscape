#!/bin/bash
echo "Running $0 with args $@"
script_dir=$(dirname "$(readlink -f "$0")")
cd $script_dir/..

perl -I lib/ $script_dir/generate_files.pl

cd $script_dir/../js
yarn run build
cp dist/kb-cytoscape.umd.js $script_dir/../views/kb-cytoscape.umd.js

