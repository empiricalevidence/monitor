#!/bin/bash
# This function gets three parameters:
#   $1 (string) Pidfile
#   $2 (string) Protocol [TCP|UDP]
#   $3 (number) Port
#   $4 (string) Command to execute
#
# Example: start-app-wrapper.sh /opt/var/pid/thumbrit.pid TCP 6000 /opt/envs/thumbrit/bin/gunicorn --config etc/gunicorn.conf thumbrit
#
PIDFILE="$1"
PROTOCOL="$2"
PORT="$3"
EXE="$4"

# This exe critically depends on this port, if any process is listening here we have to kill it
if [[ $PROTOCOL = "UDP" ]]; then
    PIDS_TO_KILL="$(lsof -iUDP:$PORT -t)"
    echo "lsof -i$PROTOCOL:$PORT -t"
fi

if [[ $PROTOCOL = "TCP" ]]; then
    PIDS_TO_KILL="$(lsof -iTCP:$PORT -sTCP:LISTEN -t)"
fi

if [[ ! -z "$PIDS_TO_KILL" ]]; then
    DATE="$(date --rfc-3339=seconds)"
    echo "[$DATE] Deleting (lingering?) processes that were listening on port $PORT ($PROTOCOL): $PIDS_TO_KILL" >&2
    kill -9 $PIDS_TO_KILL
fi

if [[ -e "$PIDFILE" && ! $(kill -0 $(< "$PIDFILE")) ]]; then
    DATE="$(date --rfc-3339=seconds)"
    echo "[$DATE] Deleting $PIDFILE" >&2
    rm -f "$PIDFILE"
fi

# exec will change this process by EXE, instead of forking a new process
# we need to change the process because *this* is the process managed by supervisor
# supervisor will only restart EXE if *this* process dies, not if a forked process dies.
shift 4
exec "$EXE" "$@"
