FROM golang:1.19.2 AS builder

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN go build -o homelab_exporter ./...

FROM debian:bullseye-slim

RUN mkdir /app
WORKDIR /app

COPY --from=builder /app/homelab_exporter /app/homelab_exporter

CMD ["/app/homelab_exporter"]
