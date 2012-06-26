#!/bin/bash
PIDFILE="/opt/graphite/storage/carbon-cache-a.pid"

if [[ -e "$PIDFILE" && ! $(kill -0 $(cat "$PIDFILE")) ]]; then
    rm -f "$PIDFILE"
fi

# exec will change this process by carbon-cache, instead of forking a new process
# we need to change the process because *this* is the process managed by supervisor
# supervisor will only restart carbon-cache if *this* process dies, not if a forked process dies.
exec /opt/graphite/bin/carbon-cache.py "$@"
