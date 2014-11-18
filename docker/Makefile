DOCKER=docker
IMAGE=killbill/killbill

all: build

build:
	$(DOCKER) build -t $(IMAGE) .

rebuild:
	$(DOCKER) build --no-cache -t $(IMAGE) .

run:
	$(DOCKER) run -t -i -p 8080:8080 $(IMAGE) /bin/bash

run-container:
	$(DOCKER) run -p 8080:8080 -d $(IMAGE)

clean:
	$(DOCKER) rm `$(DOCKER) ps -a -q` || true
	#$(DOCKER) images | grep none | awk '{print $3}' | xargs $(DOCKER) rmi
	#$(DOCKER) images -a --no-trunc | grep $(IMAGE) | awk '{print $$3}' | xargs $(DOCKER) rmi

.PHONY: build rebuild run run-container clean
