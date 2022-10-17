FROM node:16.18-bullseye-slim

ENV TIDDLYWIKI_VERSION=5.2.3

# https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
RUN apt-get update && apt-get install tini && apt-get clean && rm -rf /var/lib/{apt,dpkg,cache,log}/
RUN npm install -g tiddlywiki@${TIDDLYWIKI_VERSION}

EXPOSE 8080

VOLUME /tiddlywiki
WORKDIR /tiddlywiki

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
