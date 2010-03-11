#!/bin/bash

case "$1" in
    forward)
        echo -n "Starting SSH forward... "
        ssh -R 8118:localhost:8118 -f -N huri.net
        ps x | grep "ssh -R 8118" | grep -v 'grep' | awk '{ print $1 }' > forward.pid
        echo "done."
    ;;
    daemon)
        ./ww6.scgi &
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
        kill `cat daemon.pid`
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
        echo "usage: $0 (start|stop|forward|daemon|stop-forward|stop-daemon)"
    ;;
esac

