SERVICE = kb_cytoscape
SERVICE_CAPS = kb_cytoscape
SPEC_FILE = kb_cytoscape.spec
URL = https://kbase.us/services/kb_cytoscape
DIR = $(shell pwd)
LIB_DIR = lib
SCRIPTS_DIR = scripts
TEST_DIR = test
LBIN_DIR = bin
WORK_DIR = /kb/module/work/tmp
EXECUTABLE_SCRIPT_NAME = run_$(SERVICE_CAPS)_async_job.sh
STARTUP_SCRIPT_NAME = start_server.sh
TEST_SCRIPT_NAME = run_kb_sdk_tests.sh

.PHONY: test

default: compile

all: compile build

compile:
	kb-sdk compile $(SPEC_FILE) \
		--out $(LIB_DIR) \
		--plsrvname $(SERVICE_CAPS)::$(SERVICE_CAPS)Server \
		--plimplname $(SERVICE_CAPS)::$(SERVICE_CAPS)Impl \
		--plpsginame $(SERVICE_CAPS).psgi;

build:
	chmod +x $(SCRIPTS_DIR)/entrypoint.sh

docker-build:
	docker build --rm -t test/kb_cytoscape:latest .

# start up the docker container and access the 'docker_test' entrypoint
docker-test:
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml down --remove-orphans
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml build
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml run perl docker_test

docker-shell:
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml down --remove-orphans
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml build
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml run perl bash

# generate the files required for the kbase UI
file-gen:
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml down --remove-orphans
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml build
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml run perl file_gen
	docker-compose -f relation_engine/docker-compose.yaml -f docker-compose.override.yaml down --remove-orphans

test:
	if [ ! -d /kb/module/work ]; then echo -e '\nOutside a docker container please run "kb-sdk test" rather than "make test"\n' && exit 1; fi
	sh ./scripts/run_tests.sh

run_kbsdk_test:
	bash $(SCRIPTS_DIR)/$(TEST_SCRIPT_NAME)

run_docker_tests:
	sh ./scripts/run_tests.sh

clean:
	rm -rfv $(LBIN_DIR)
