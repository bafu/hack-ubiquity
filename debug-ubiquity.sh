#!/bin/sh

case $1 in
    start)
        sudo ubiquity-dm vt7 :0 ubuntu /usr/sbin/oem-config-wrapper --only
        ;;
    stop)
        sudo pkill Xorg
        ;;
    *)
        echo "debug-ubiquity start|stop"
        ;;
esac
