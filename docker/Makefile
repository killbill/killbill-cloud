DOCKER=docker
IMAGE=killbill/killbill

all: build

build:
	$(DOCKER) build -t $(IMAGE) .

run:
	$(DOCKER) run -t -i -p 8080:8080 $(IMAGE) /bin/bash

run-container:
	$(DOCKER) run -p 8080:8080 -d $(IMAGE)

clean:
	$(DOCKER) ps -a -q | grep $(IMAGE) | awk '{print $$1}' | xargs $(DOCKER) rm
	$(DOCKER) images -a --no-trunc | grep $(IMAGE) | awk '{print $$3}' | xargs $(DOCKER) rmi

.PHONY: build run run-container clean