FROM ubuntu:22.04 as builder

ARG TARGETARCH

WORKDIR /tmp

RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*

RUN curl -sLO https://go.dev/dl/go1.18.2.linux-${TARGETARCH}.tar.gz \
    && tar -C /usr/local -xzf go1.18.2.linux-${TARGETARCH}.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

RUN env

RUN mkdir /app

WORKDIR /app

COPY ./go.mod ./
COPY ./go.sum ./

RUN go mod download

COPY . .

RUN go build -o ./build/sealed-secrets-keys-backup . && chmod 544 ./build/sealed-secrets-keys-backup

FROM ubuntu:22.04

RUN mkdir /app

WORKDIR /app

COPY --from=builder /app/build/sealed-secrets-keys-backup /app/sealed-secrets-keys-backup

ENTRYPOINT ["/app/sealed-secrets-keys-backup"]

