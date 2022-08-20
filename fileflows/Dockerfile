FROM ubuntu as builder

RUN mkdir -p /tmp/sqlite-netfx

WORKDIR /tmp/sqlite-netfx

RUN apt-get update && apt-get install -y curl unzip build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*

# http://blog.wezeku.com/2016/10/09/using-system-data-sqlite-under-linux-and-mono/
RUN curl -LO https://system.data.sqlite.org/blobs/1.0.116.0/sqlite-netFx-full-source-1.0.116.0.zip && unzip sqlite-netFx-full-source-1.0.116.0.zip && cd Setup && chmod +x compile-interop-assembly-release.sh && ./compile-interop-assembly-release.sh

FROM ubuntu

ENV PATH="$PATH:/root/.dotnet:/root/.dotnet/tools"
ENV DOTNET_ROOT=/root/.dotnet
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /app /root/.dotnet

RUN apt-get update && apt-get install -y curl unzip ffmpeg && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /root/.dotnet

RUN curl -sLo /root/.dotnet/dotnet-sdk.tar.gz https://download.visualstudio.microsoft.com/download/pr/33389348-a7d7-41ae-850f-ec46d3ca9612/36bad11f948b05a4fa9faac93c35e574/dotnet-sdk-6.0.302-linux-arm64.tar.gz && tar xvvfz dotnet-sdk.tar.gz && rm dotnet-sdk.tar.gz

WORKDIR /app

RUN curl -sLo fileflows.zip https://fileflows.com/downloads/zip && unzip fileflows.zip && rm fileflows.zip

COPY --from=builder /tmp/sqlite-netfx/bin/2013/Release/bin/SQLite.Interop.dll /app/Server/runtimes/linux-arm64/native/SQLite.Interop.dll

COPY ./docker-entrypoint.sh /app/docker-entrypoint.sh

CMD ["/app/docker-entrypoint.sh"]

