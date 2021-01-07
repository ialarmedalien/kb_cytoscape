#!/bin/bash
echo "Running $0 with args $@"
if [ -L $0 ] ; then
    current_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    current_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi
echo $current_dir
current_dir=$(cd $current_dir && cd .. && pwd);
$current_dir/run_docker.sh run -it -v $current_dir/workdir:/kb/module/work \
-v $base_dir:/kb/module \
test/kb_cytoscape:latest bash
