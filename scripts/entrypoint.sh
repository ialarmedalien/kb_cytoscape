#!/bin/bash
echo "Running $0 with args $@"

export KBASE_ENDPOINT="https://ci.kbase.us"

. /kb/deployment/user-env.sh

python ./scripts/prepare_deploy_cfg.py ./deploy.cfg ./work/config.properties

if [ -f ./work/token ] ; then
  export KB_AUTH_TOKEN=$(<./work/token)
fi

if [ $# -eq 0 ] ; then
  sh ./scripts/start_server.sh
elif [ "${1}" = "test" ] ; then
  echo "Run Tests"
  make test
elif [ "${1}" = "docker_test" ] ; then
  echo "Run tests in the docker-compose setup"
  sh ./scripts/run_tests.sh
elif [ "${1}" = "file_gen" ] ; then
  echo "Generate app metadata files"
  sh ./scripts/generate_files.sh
elif [ "${1}" = "async" ] ; then
  sh ./scripts/run_async.sh
elif [ "${1}" = "init" ] ; then
  echo "Initialize module"
elif [ "${1}" = "bash" ] ; then
  bash
elif [ "${1}" = "filegen" ] ; then
  sh ./scripts/generate_files.sh
elif [ "${1}" = "report" ] ; then
  export KB_SDK_COMPILE_REPORT_FILE=./work/compile_report.json
  make compile
else
  echo Unknown entrypoint command: ${1}
fi
