TAG=0.4.0

build:
	docker buildx build --platform=linux/amd64,linux/arm64 . -t bloveless/homelab-exporter:$(TAG)

run: build
	docker run -it --rm bloveless/homelab-exporter:$(TAG)

publish:
	docker buildx build --platform=linux/amd64,linux/arm64 . -t bloveless/homelab-exporter:$(TAG) --push
