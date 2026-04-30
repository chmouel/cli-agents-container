IMAGE_NAME ?= agents-image
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: all ubuntu ubi buildx-ubuntu buildx-ubi buildx-all

all: ubuntu ubi

ubuntu:
	docker build -t $(IMAGE_NAME) .

ubi:
	docker build -f Dockerfile.ubi -t $(IMAGE_NAME):ubi .

buildx-all: buildx-ubuntu buildx-ubi

buildx-ubuntu:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE_NAME) .

buildx-ubi:
	docker buildx build --platform $(PLATFORMS) -f Dockerfile.ubi -t $(IMAGE_NAME):ubi .
