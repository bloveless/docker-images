ARG PGBACKREST_TAG=2.38
ARG TZ="Etc/UTC"

FROM debian:bullseye-slim as builder

ARG PGBACKREST_TAG

RUN mkdir /build

WORKDIR /build

RUN apt update \
    && apt-get install -y make gcc libpq-dev libssl-dev libxml2-dev pkg-config \
       liblz4-dev libzstd-dev libbz2-dev libz-dev libyaml-dev curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL \
       https://github.com/pgbackrest/pgbackrest/archive/release/${PGBACKREST_TAG}.tar.gz | \
       tar zx -C /build

WORKDIR /build/pgbackrest-release-${PGBACKREST_TAG}/src

RUN ./configure && make

FROM postgres:14-bullseye

ARG PGBACKREST_TAG
ARG TZ

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        postgresql-client \
        tzdata \
        libxml2 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p -m 750 \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
        /etc/pgbackrest/conf.d \
        /etc/pgbackrest/cert \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 640 /etc/pgbackrest/pgbackrest.conf \
    && chown -R postgres:postgres \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
    && unlink /etc/localtime \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY --from=builder /build/pgbackrest-release-${PGBACKREST_TAG}/src/pgbackrest /usr/local/bin/pgbackrest

