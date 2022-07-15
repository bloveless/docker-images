FROM ubuntu:jammy

WORKDIR /tmp

RUN apt-get update \
    && apt-get install -y curl \
    && curl -L0 https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh && ./dotnet-install.sh -c 6.0 \
    && rm -rf /var/lib/apt/lists/*

