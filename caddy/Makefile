TAG=2.5.2-0.1.0

build:
	docker build -t bloveless/caddy:$(TAG) .

publish: build
	docker push bloveless/caddy:$(TAG)

