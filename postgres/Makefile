TAG=14-bullseye-0.1.1

.PHONY: build run

build:
	docker build . -t bloveless/postgres:$(TAG)

run: build
	docker run --rm bloveless/postgres:$(TAG)

push: build
	docker push bloveless/postgres:$(TAG)
