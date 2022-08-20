TAG=2.38-0.1.15

.PHONY: build run

build:
	docker buildx build --platform=linux/amd64,linux/arm64 . -t bloveless/pgbackrest:$(TAG)

run: build
	docker run --rm bloveless/pgbackrest:$(TAG)

push:
	docker buildx build --push --platform=linux/amd64,linux/arm64 . -t bloveless/pgbackrest:$(TAG)
