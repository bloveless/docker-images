FROM clux/muslrust as builder

RUN useradd -ms /bin/bash appuser

WORKDIR /app

COPY Cargo.lock Cargo.toml /app/

RUN cargo fetch

COPY src /app/src

RUN cargo build --release

CMD ["ecr-credential-helper"]

###### ------- PRODUCTION IMAGE ------- ######
FROM gcr.io/distroless/static

COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/ecr-credential-helper /usr/local/bin/

USER appuser

WORKDIR /home/appuser

ENTRYPOINT ["ecr-credential-helper"]

