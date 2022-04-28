ARG PGBACKREST_TAG=2.38
ARG TZ="Etc/UTC"
ARG BACKREST_USER="postgres"
ARG BACKREST_UID=999
ARG BACKREST_GROUP="postgres"
ARG BACKREST_GID=999

FROM debian:bullseye-slim as builder

ARG PGBACKREST_TAG

RUN mkdir /build && mkdir /build-scheduler

WORKDIR /build

RUN apt update \
    && apt-get install -y make gcc libpq-dev libssl-dev libxml2-dev pkg-config \
       liblz4-dev libzstd-dev libbz2-dev libz-dev libyaml-dev curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -L --output /root/go1.18.1.linux-arm64.tar.gz https://go.dev/dl/go1.18.1.linux-arm64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /root/go1.18.1.linux-arm64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

RUN curl -sL \
       https://github.com/pgbackrest/pgbackrest/archive/release/${PGBACKREST_TAG}.tar.gz | \
       tar zx -C /build

WORKDIR /build/pgbackrest-release-${PGBACKREST_TAG}/src

RUN ./configure && make

WORKDIR /build-scheduler

COPY ./main.go ./go.mod ./go.sum ./

RUN go build -o scheduler .

FROM debian:bullseye-slim

ARG PGBACKREST_TAG
ARG TZ
ARG BACKREST_USER
ARG BACKREST_UID
ARG BACKREST_GROUP
ARG BACKREST_GID

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        postgresql-client \
        tzdata \
        libxml2 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Copied from https://github.com/woblerr/docker-pgbackrest/blob/master/Dockerfile
    && groupadd --gid ${BACKREST_GID} ${BACKREST_GROUP} \
    && useradd --shell /bin/bash --uid ${BACKREST_UID} --gid ${BACKREST_GID} -m ${BACKREST_USER} \
    && mkdir -p -m 750 \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
        /etc/pgbackrest/conf.d \
        /etc/pgbackrest/cert \
    && touch /etc/pgbackrest/pgbackrest.conf \
    && chmod 640 /etc/pgbackrest/pgbackrest.conf \
    && chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest \
    && unlink /etc/localtime \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY entrypoint.sh /entrypoint.sh
COPY --from=builder /build/pgbackrest-release-${PGBACKREST_TAG}/src/pgbackrest /usr/local/bin/pgbackrest
COPY --from=builder /build-scheduler/scheduler /usr/local/bin/scheduler
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["pgbackrest", "version"]

