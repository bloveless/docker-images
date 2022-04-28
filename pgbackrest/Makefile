TAG=2.38-0.1.13

.PHONY: build run

build:
	docker build . -t bloveless/pgbackrest:$(TAG)

run: build
	docker run --rm bloveless/pgbackrest:$(TAG)

push: build
	docker push bloveless/pgbackrest:$(TAG)
