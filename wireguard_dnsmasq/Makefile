TAG=0.3.11

.PHONY: build run

build:
	docker buildx build --platform=linux/amd64,linux/arm64 . -t bloveless/wireguard-dnsmasq:$(TAG)

run: build
	docker run -it --rm --entrypoint bash bloveless/wireguard-dnsmasq:$(TAG)

push:
	docker buildx build --platform=linux/amd64,linux/arm64 . -t bloveless/wireguard-dnsmasq:$(TAG) --push
