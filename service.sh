#!/bin/bash

die() {
  echo "$@"
  exit 1
}

usage() {
  die "usage: $0 (start|stop|forward|daemon|stop-forward|stop-daemon) <configfile>"
}

[ $# -lt 2 ] && usage

## Include configuration file.
if [ -f $2 ]; then
  . $2
else
  die "invalid configuration file specified"
fi

[ -z "$REMOTE_SERVER" ] && die "no REMOTE_SERVER defined"
[ -z "$DAEMON_USER" ] && die "no DAEMON_USER defined"
[ -z "$WEB_APP" ] && die "no WEB_APP defined"

case "$1" in
    forward)
        echo -n "Starting SSH forward... "
        ssh -R 8118:localhost:8118 -f -N $REMOTE_SERVER
        ps x | grep "ssh -R 8118" | grep -v 'grep' | awk '{ print $1 }' > forward.pid
        echo "done."
    ;;
    daemon)
        sudo -u $DAEMON_USER ./apps/$WEB_APP.scgi &
        echo $! > daemon.pid
    ;;
    start)
        $0 forward
        $0 daemon
    ;;
    stop-forward)
        echo -n "Stopping SSH forward... "
        kill `cat forward.pid`
        rm forward.pid
        echo "done."
    ;;
    stop-daemon)
        echo -n "Stopping SCGI Daemon... "
        sudo -u nobody kill `cat daemon.pid`
        rm daemon.pid
        echo "done."
    ;;
    stop)
        $0 stop-daemon
        $0 stop-forward
    ;;
    restart)
        $0 stop
        sleep 1
        $0 start
    ;;
    *)
        usage
    ;;
esac

