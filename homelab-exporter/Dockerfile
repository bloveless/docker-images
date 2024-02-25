FROM golang:1.19.2 AS builder

RUN mkdir /app
WORKDIR /app

COPY . /app

RUN go build -o homelab-exporter ./...

FROM debian:bullseye-slim

RUN mkdir /app
WORKDIR /app

COPY --from=builder /app/homelab-exporter /app/homelab-exporter

CMD ["/app/homelab-exporter"]
