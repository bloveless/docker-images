#!/usr/bin/env bash

uid=$(id -u)

if [ "${uid}" = "0" ]; then
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

command_prefix=""

if [ "${uid}" = "0" ]; then
    command_prefix="gosu ${BACKREST_USER}"
fi

if [ "$1" = "restore" ]; then
     eval "${command_prefix} pgbackrest --stanza=pg --log-level-console=info restore"
    return_val="$?"
    echo "Return value: ${return_val}"
    if [ "${return_val}" = "40" ]; then
        echo "Restore failed because there are already files. Assuming that everything is okay and moving on. If you need to perform a restore then delete all the postgres data files and attempt the restore again"
        exit 0
    fi
    if [ "${return_val}" = "0" ]; then
        echo "Restore was successful"
    fi
elif [ "$1" = "cron" ]; then
    # Run full backup every saturday at 2:20 am
    echo "20 2 * * 6 /usr/local/bin/pgbackrest --stanza=pg --log-level-console=info --type=full backup" >> /home/postgres/schedule
    # Run diff backup every hour on the 40's
    echo "40 * * * * /usr/local/bin/pgbackrest --stanza=pg --log-level-console=info --type=diff backup" >> /home/postgres/schedule
    echo "Starting backup cron"
    exec scheduler /home/postgres/schedule
else
    exec ${command_prefix} "$@"
fi

