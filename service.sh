#!/bin/bash

case "$1" in
    forward)
        ssh -R 8118:localhost:8118 -f -N huri.net
        ps x | grep "ssh -R 8118" | grep -v 'grep' | awk '{ print $1 }' > forward.pid
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
        kill `cat forward.pid`
        rm -v forward.pid
    ;;
    stop-daemon)
        kill `cat daemon.pid`
        rm -v daemon.pid
    ;;
    stop)
        $0 stop-daemon
        $0 stop-forward
    ;;
    *)
        echo "usage: $0 (start|stop|forward|daemon|stop-forward|stop-daemon)"
    ;;
esac

