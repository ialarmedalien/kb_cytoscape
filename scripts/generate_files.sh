#!/bin/bash
echo "Running $0 with args $@"
script_dir=$(dirname "$(readlink -f "$0")")
cd $script_dir/..

perl -I lib/ $script_dir/generate_files.pl
