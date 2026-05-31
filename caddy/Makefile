TAG=2.10.2-0.1.0

build:
	docker build -t bloveless/caddy:$(TAG) .

publish: 
	docker build --platform linux/amd64,linux/arm64 --push -t bloveless/caddy:$(TAG) .

