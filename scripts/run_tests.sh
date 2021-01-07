#!/bin/bash
echo "This script runs tests in the docker-compose setup."
echo "Running $0 with args $@"

until [ -f ${DB_DATALOAD_DONE} ]
do
    echo "Waiting for DB load to complete"
    sleep 2
done
echo "DB load complete"

if [ -L $0 ] ; then
  current_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
  current_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

base_dir=$(cd $current_dir && cd .. && pwd);

export KB_AUTH_TOKEN=`cat /kb/module/work/token`
export TEST_DIR='/kb/module/t'
echo "Removing temp files..."
rm -rf /kb/module/work/tmp/*
cd $base_dir
echo "Starting tests!"
prove -lvrm -I t/
