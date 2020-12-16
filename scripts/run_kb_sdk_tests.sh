#!/bin/bash
echo "Running $0 with args $@"
if [[ -n $2 ]]; then
    env_vars="-e $2"
else
    env_vars=""
fi

if [ -L $0 ] ; then
    current_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    current_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

base_dir=$(cd $current_dir && cd .. && pwd);
cd $base_dir

$current_dir/run_docker.sh run -v $current_dir/workdir:/kb/module/work -e "SDK_CALLBACK_URL=$1" ${env_vars} test/kb_cytoscape:latest test
