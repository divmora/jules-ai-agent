.PHONY: build run docker-build clean

# Name of the binary
BINARY_NAME=jules-ai-agent
DOCKER_IMAGE=ghcr.io/divmora/jules-ai-agent:latest

build:
	go build -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

docker-build:
	docker build -t $(DOCKER_IMAGE) .

clean:
	rm -f $(BINARY_NAME)
