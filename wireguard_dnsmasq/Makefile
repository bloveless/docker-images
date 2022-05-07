TAG=0.3.2

.PHONY: build run

build:
	docker build . -t bloveless/wireguard-dnsmasq:$(TAG)

run: build
	docker run -it --rm --entrypoint bash bloveless/wireguard-dnsmasq:$(TAG)

push: build
	docker push bloveless/wireguard-dnsmasq:$(TAG)
