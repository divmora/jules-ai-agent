.PHONY: build run test lint clean \
	build-all build-linux-amd64 build-linux-arm64 build-darwin-amd64 build-darwin-arm64 build-windows-amd64 \
	docker-build docker-build-multi docker-build-push

# Configuration
BINARY_NAME ?= jules-ai-agent
BIN_DIR ?= bin
DOCKER_IMAGE ?= ghcr.io/divmora/jules-ai-agent:latest
PLATFORMS ?= linux/amd64,linux/arm64
GO_LDFLAGS ?= -s -w

# Local build
build:
	go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

test:
	go test -race -count=1 ./...

lint:
	golangci-lint run ./...

# Multi-arch Binary Builds
build-all: build-linux-amd64 build-linux-arm64 build-darwin-amd64 build-darwin-arm64 build-windows-amd64

build-linux-amd64:
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-linux-amd64 .

build-linux-arm64:
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-linux-arm64 .

build-darwin-amd64:
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-darwin-amd64 .

build-darwin-arm64:
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-darwin-arm64 .

build-windows-amd64:
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="$(GO_LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-windows-amd64.exe .

# Docker Builds
docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-build-multi:
	docker buildx build --platform $(PLATFORMS) -t $(DOCKER_IMAGE) .

docker-build-push:
	docker buildx build --platform $(PLATFORMS) -t $(DOCKER_IMAGE) --push .

clean:
	rm -rf $(BINARY_NAME) $(BIN_DIR)
