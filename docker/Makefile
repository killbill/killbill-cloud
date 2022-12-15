#
# Build Kill Bill image:
# > make -e TARGET=<killbill|kaui|mariadb|postgresql> # Build raw image and will download latest KB image at installation time
# > make -e VERSION=<version> -e TARGET=<killbill|kaui|mariadb|postgresql> # Build specific tagged KB image (e.g make -e VERSION=0.12.1)
#
DOCKER=docker
DOCKER_TEMPLATE="./dockerTemplate.sh"

TARGET?=killbill
PARENT_VERSION?=latest

VERSION?=latest
ifeq ($(VERSION),latest)
IMAGE=killbill/$(TARGET)
TEMPLATE=templates/$(TARGET)/latest
else
IMAGE=killbill/$(TARGET):$(VERSION)
TEMPLATE=templates/$(TARGET)/tagged
endif

all: build

build:
	@echo "Building image $(IMAGE) for version $(VERSION) from template $(TEMPLATE) with parent $(PARENT_VERSION)"
	$(DOCKER_TEMPLATE) -p $(PARENT_VERSION) -v $(VERSION) -t $(TARGET) -i
	$(DOCKER) build -t $(IMAGE) $(TEMPLATE)
	$(DOCKER_TEMPLATE) -t $(TARGET) -c

rebuild:
	@echo "Rebuilding image $(IMAGE) for version $(VERSION) from template $(TEMPLATE) with parent $(PARENT_VERSION)"
	$(DOCKER_TEMPLATE) -p $(PARENT_VERSION) -v $(VERSION) -t $(TARGET) -i
	$(DOCKER) build --no-cache -t $(IMAGE) $(TEMPLATE)
	$(DOCKER_TEMPLATE) -t $(TARGET) -c

multi-arch:
	@echo "Rebuilding and pushing multi-arch images $(IMAGE) for version $(VERSION) from template $(TEMPLATE) with parent $(PARENT_VERSION)"
	$(DOCKER_TEMPLATE) -p $(PARENT_VERSION) -v $(VERSION) -t $(TARGET) -i
	$(DOCKER) buildx build --push --platform=linux/arm64,linux/amd64 --no-cache -t $(IMAGE) $(TEMPLATE)
	$(DOCKER_TEMPLATE) -t $(TARGET) -c

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
