#
# Build Kill Bill image:
# > make # Build raw image and will download latest KB image at installation time
# > make -e VERSION=<version> # Build specific tagged KB image (e.g make -e VERSION=0.12.1)
#
DOCKER=docker
DOCKER_TEMPLATE="./dockerTemplate.sh"
VERSION?=LATEST
ifeq ($(VERSION),LATEST)
IMAGE=killbill/killbill
TEMPLATE=templates/latest
else
IMAGE=killbill/killbill:$(VERSION)
TEMPLATE=templates/tagged
endif

all: build

build:
	@echo "Building image $(IMAGE) from template $(TEMPLATE)"
	$(DOCKER_TEMPLATE) $(VERSION)
	$(DOCKER) build -t $(IMAGE) $(TEMPLATE)

rebuild:
	@echo "Rebuilding image $(IMAGE) from template $(TEMPLATE)"
	$(DOCKER_TEMPLATE) $(VERSION)
	$(DOCKER) build --no-cache -t $(IMAGE) $(TEMPLATE)

run:
	@echo "Running image $(IMAGE)"
	$(DOCKER) run -t -i -p 8080:8080 $(IMAGE) /bin/bash


run-container:
	@echo "Running container image $(IMAGE)"
	$(DOCKER) run -p 8080:8080 -d $(IMAGE)

clean:
	$(DOCKER) rm `$(DOCKER) ps -a -q` || true
	#$(DOCKER) images | grep none | awk '{print $3}' | xargs $(DOCKER) rmi
	#$(DOCKER) images -a --no-trunc | grep $(IMAGE) | awk '{print $$3}' | xargs $(DOCKER) rmi


.PHONY: build rebuild run run-container clean
