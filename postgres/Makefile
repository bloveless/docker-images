TAG=14-bullseye-0.1.3

.PHONY: build run

build:
	docker buildx build --platform=linux/arm64,linux/amd64 -t bloveless/postgres:$(TAG) .

run: build
	docker run --rm bloveless/postgres:$(TAG)

push: build
	docker buildx build --push --platform=linux/arm64,linux/amd64 -t bloveless/postgres:$(TAG) .
