#!/usr/bin/env bash

uid=$(id -u)
# Execution command.
backrest_command="pgbackrest"

if [ "${uid}" = "0" ]; then
    # Exec pgBackRest from specific user.
    backrest_command="gosu ${BACKREST_USER} pgbackrest"
    # Custom time zone.
    if [ "${TZ}" != "Etc/UTC" ]; then
        cp /usr/share/zoneinfo/${TZ} /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
    # Custom user group.
    if [ "${BACKREST_GROUP}" != "pgbackrest" ] || [ "${BACKREST_GID}" != "2001" ]; then
        groupmod -g ${BACKREST_GID} -n ${BACKREST_GROUP} pgbackrest
    fi
    # Custom user.
    if [ "${BACKREST_USER}" != "pgbackrest" ] || [ "${BACKREST_UID}" != "2001" ]; then
        usermod -g ${BACKREST_GID} -l ${BACKREST_USER} -u ${BACKREST_UID} -m -d /home/${BACKREST_USER} pgbackrest
    fi
    # Correct user:group.
    chown -R ${BACKREST_USER}:${BACKREST_GROUP} \
        /home/${BACKREST_USER} \
        /var/log/pgbackrest \
        /var/lib/pgbackrest \
        /var/spool/pgbackrest \
        /etc/pgbackrest
fi

if [ "${uid}" = "0" ]; then
    exec gosu ${BACKREST_USER} "$@"
else
    exec "$@"
fi

