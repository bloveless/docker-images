#!/usr/bin/env bash

# set -e makes the script exit when a command fails.
set -e

if [[ "$FFNODE" == 'true' || "$FFNODE" == '1' || "$1" = '--node' ]]; then

    # check if there is an upgrade to apply
    if test -f "/app/NodeUpdate/node-upgrade.sh"; then
        echo "Upgrade found"
        chmod +x /app/NodeUpdate/node-upgrade.sh
        cd /app/NodeUpdate
        echo "bash node-upgrade.sh docker"
        bash node-upgrade.sh docker
    fi

    printf "Launching node\n"
    cd /app/Node
    exec /root/.dotnet/dotnet FileFlows.Node.dll --docker true

else

    # check if there is an upgrade to apply
    if test -f "/app/Update/server-upgrade.sh"; then
        echo "Upgrade found"
        chmod +x /app/Update/server-upgrade.sh
        cd /app/Update
        echo "bash server-upgrade.sh docker"
        bash server-upgrade.sh docker
    fi

    printf "Launching server\n"
    cd /app/Server
    exec /root/.dotnet/dotnet FileFlows.Server.dll --urls=http://*:5000 --docker
fi
