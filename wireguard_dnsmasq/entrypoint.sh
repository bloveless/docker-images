#!/usr/bin/env bash
# copied from https://github.com/k8s-at-home/container-images/blob/main/apps/wireguard/entrypoint.sh

set -v -e -x

INTERFACE_UP=false
SEPARATOR=${SEPARATOR:- }

_shutdown () {
    local exitCode=$?
    if [[ ${exitCode} -gt 0 ]]; then
        echo "[ERROR] Received non-zero exit code (${exitCode}) executing the command "${BASH_COMMAND}" on line ${LINENO}."
    else
        echo "[INFO] Caught signal to shutdown."
    fi

    if [[ "${INTERFACE_UP}" == 'true' ]]; then
        echo "[INFO] Shutting down VPN!"
        sudo /usr/bin/wg-quick down "${INTERFACE}"
    fi
}

trap _shutdown EXIT

#Get K8S DNS
K8S_DNS=$(grep nameserver /etc/resolv.conf | cut -d' ' -f2)
echo "K8S_DNS ${K8S_DNS}"

source "/shim/iptables-backend.sh"

CONFIGS=`sudo /usr/bin/find /etc/wireguard -type f -printf "%f\n"`
if [[ -z "${CONFIGS}" ]]; then
    echo "[ERROR] No configuration files found in /etc/wireguard" >&2
    exit 1
fi

CONFIG=`echo $CONFIGS | head -n 1`
INTERFACE="${CONFIG%.*}"
NAMESERVERS=$(/usr/local/bin/get_nameservers.pl "/etc/wireguard/${CONFIG}" "${SEPARATOR}")

echo "Using wireguard nameservers ${NAMESERVERS}"

sudo /usr/bin/wg-quick up "${INTERFACE}"
INTERFACE_UP=true

source "/shim/killswitch.sh"

sed -i "s:\#conf-dir=/etc/dnsmasq.d/,\*.conf:conf-dir=/etc/dnsmasq.d/,\*.conf:g" /etc/dnsmasq.conf

cat << EOF > /etc/dnsmasq.d/local-k8s.conf
# For debugging purposes, log each DNS query as it passes through
# dnsmasq.
log-queries

# Log to stdout
log-facility=-

# Clear DNS cache on reload
clear-on-reload

# /etc/resolv.conf cannot be monitored by dnsmasq since it is in a different file system
# and dnsmasq monitors directories only
# copy_resolv.sh is used to copy the file on changes
resolv-file=/etc/resolv_copy.conf
EOF


IFS="${SEPARATOR}" read -r -a nameservers <<< "${NAMESERVERS}"
for nameserver in "${nameservers[@]}"; do
  cat << EOF >> /etc/dnsmasq.d/local-k8s.conf
  # Setup the default wireguard nameserver: ${nameserver}
  server=${nameserver}
EOF
done


IFS="${SEPARATOR}" read -r -a locals <<< "${DNS_LOCAL_CIDRS}"
for local_cidr in "${locals[@]}"; do
  cat << EOF >> /etc/dnsmasq.d/local-k8s.conf
  # Send ${local_cidr} DNS queries to the K8S DNS server
  server=/${local_cidr}/${K8S_DNS}
EOF
done

# Dnsmasq daemon
dnsmasq -k &
dnsmasq=$!

_kill_procs() {
  echo "Signal received -> killing processes"
  kill -TERM $dnsmasq
  wait $dnsmasq
}

# Set it so the containers will use the localhost dnsmasq as the default dns server
sed -i "s:\#name_servers=127.0.0.1:name_servers=127.0.0.1:g" /etc/resolvconf.conf

# Update the resolv.conf file to use localhost as the nameserver
resolvconf -u

# Setup a trap to catch SIGTERM and relay it to child processes
trap _kill_procs SIGTERM

echo "Monitoring for changes in /etc/resolv.conf"
cp /etc/resolv.conf /etc/resolv_copy.conf
while inotifywait -e modify -e attrib /etc/resolv.conf; do
    echo "Detected changes in /etc/resolv.conf... copying to /etc/resolv_copy.conf"
    cp /etc/resolv.conf /etc/resolv_copy.conf
done

#Wait for dnsmasq
wait $dnsmasq

echo "TERMINATING"

