FROM debian:bullseye-slim AS builder

RUN apt update \
    && apt install -y build-essential autoconf libdata-validate-ip-perl libio-socket-ssl-perl libjson-pp-perl libio-socket-inet6-perl net-tools \
    && rm -rf /var/lib/apt/lists/*

COPY ./ddclient-develop /tmp/ddclient

WORKDIR /tmp/ddclient

RUN ./autogen \
    && ./configure \
       --prefix=/usr \
       --sysconfdir=/etc/ddclient \
       --localstatedir=/var \
    && make \
    && make VERBOSE=1 check


FROM debian:bullseye-slim

RUN apt update \
    && apt install -y libdata-validate-ip-perl libio-socket-ssl-perl libjson-pp-perl libio-socket-inet6-perl ca-certificates sendmail \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

COPY --from=builder /tmp/ddclient/ddclient /usr/sbin/ddclient

CMD /usr/sbin/ddclient -daemon 300 -syslog -file /etc/ddclient/ddclient.conf -foreground

