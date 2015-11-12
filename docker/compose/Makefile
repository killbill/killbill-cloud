ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

ELK_FILE=$(ROOT_DIR)/docker-compose.elk.yml
GI_FILE=$(ROOT_DIR)/docker-compose.gi.yml
KB_FILE=$(ROOT_DIR)/docker-compose.kb.yml

BUILD_FILE=$(ROOT_DIR)/docker-compose.yml

COMPOSE=docker-compose

DOCKER_MACHINE=dev

default: all

elk:
	$(COMPOSE) -p elk -f $(ELK_FILE) up -d

run-elk:
	$(COMPOSE) -p elk -f $(ELK_FILE) up

run-gi:
	$(COMPOSE) -p gi -f $(GI_FILE) up

run-kb:
	$(COMPOSE) -p kb -f $(KB_FILE) up

build-docker-compose:
	ruby build_docker-compose.rb > $(BUILD_FILE)

# Logstash needs to be up first (TODO block until started)
run-all: elk build-docker-compose
	HOST_IP=$(docker-machine ip $(DOCKER_MACHINE)) $(COMPOSE) -p kb -f $(BUILD_FILE) up

# Logstash needs to be up first (TODO block until started)
all: elk build-docker-compose
	HOST_IP=$(docker-machine ip $(DOCKER_MACHINE)) $(COMPOSE) -p kb -f $(BUILD_FILE) up -d
