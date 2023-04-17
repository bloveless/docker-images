TAG=0.1.0

push:
	docker buildx build --push --platform=linux/amd64 . -t bloveless/homelab-exporter:$(TAG)-rust

build:
	docker buildx build --platform=linux/amd64 . -t bloveless/homelab-exporter:$(TAG)-rust

run: build
	docker run -p 8080:9090 bloveless/homelab-exporter:$(TAG)-rust

