TAG=0.1.0

build:
	docker build -t bloveless/tiddlywiki:5.2.3-$(TAG) .

publish: build
	docker push bloveless/tiddlywiki:5.2.3-$(TAG)

