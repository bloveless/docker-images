up:
	docker build -t bloveless-ddclient:latest .
	docker run -v $(shell pwd)/ddclient.conf:/etc/ddclient/ddclient.conf bloveless-ddclient:latest

push:
	docker buildx build --push --tag bloveless/ddclient:v0.1.0 --platform linux/arm/v7,linux/arm64/v8,linux/amd64 .
