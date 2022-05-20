FROM ubuntu:22.04

RUN mkdir /app

WORKDIR /app

COPY ./build/sealed-secrets-keys-backup /app/sealed-secrets-keys-backup

ENTRYPOINT ["/app/sealed-secrets-keys-backup"]

