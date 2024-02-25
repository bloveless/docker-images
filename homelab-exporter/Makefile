TAG=0.3.0

build:
	docker build -t bloveless/homelab-exporter:$(TAG) .

publish: build
	docker push bloveless/homelab-exporter:$(TAG)
