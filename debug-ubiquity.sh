#!/bin/sh
# apt-get install ubiquity ubiquity-front-gtk ubiquity-slideshow-ubuntu ubiquity-ubuntu-artwork
# apt-get install oem-config oem-config-gtk oem-config-slideshow-ubuntu oem-config-remaster

case $1 in
    start)
        # ubiquity-dm <vt> <display> <username> <args of dm.run>
        #sudo ubiquity-dm vt7 :0 ubuntu /usr/sbin/oem-config-wrapper --only
        sudo ubiquity-dm vt7 :0 root /usr/sbin/oem-config-wrapper --only --debug
        ;;
    stop)
        sudo pkill Xorg
        ;;
    *)
        echo "debug-ubiquity start|stop"
        ;;
esac
