FROM rust:1.68.2-bullseye AS builder

RUN mkdir /app

WORKDIR /app

COPY . .

RUN cargo build --release

FROM debian:bullseye

COPY --from=builder /app/target/release/homelab-exporter-rs /usr/local/bin/homelab-exporter-rs

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/usr/local/bin/homelab-exporter-rs"]
