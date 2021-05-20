#!/bin/bash

[ "$(id -un)" != "root" ] && echo "this script must be executed by root" && exit 1

if [ $# -ne 5 ]
then
    cat <<EOF
   use : 
       $0 sdName ssidWifi passwdWifi pathBuildRep "azerty|qwerty"

   example :

       $0 sdb wifi wifipass /home/user/Development-tools azerty
EOF
    exit 1
fi

dev=$1
ssid=$2
passwd=$3
buildrep=$4
language=$5

set -e

ls -l ${buildrep}/output/images/sdcard.img
echo -e "\n dd is working...\n"
dd if=${buildrep}/output/images/sdcard.img of=/dev/$dev

echo -e "\n configuration... \n"

dev1=$(ls /dev/${dev}*1)
dev2=$(ls /dev/${dev}*2)

mkdir -p /mnt/system /mnt/boot

set +e
umount /mnt/boot /mnt/system 2> /dev/null
set -e
sync
sync
mount $dev1 /mnt/boot
mount $dev2 /mnt/system
sync
sync

cat >> /mnt/system/etc/network/interfaces <<EOF

auto wlan0
iface wlan0 inet dhcp
    wireless-essid $ssid
    pre-up wpa_supplicant -B w -D wext -i wlan0 -c /etc/wpa_supplicant.conf -dd
    post-down killall -q wpa_supplicant
EOF

sync
sync

cat >/mnt/system/etc/wpa_supplicant.conf <<EOF
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1

network={
    ssid="$ssid"
    scan_ssid=1
    proto=WPA RSN
    key_mgmt=WPA-PSK
    pairwise=CCMP TKIP
    group=CCMP TKIP
    psk="$passwd"
}
EOF

sync
sync

sed -i "s:#PermitRootLogin.*:PermitRootLogin yes:" /mnt/system/etc/ssh/sshd_config

sync
sync

busybox dumpkmap > /mnt/system/etc/azerty.kmap

sync
sync

if [ "$language" = "azerty" ]
then
    cat >/mnt/system/etc/init.d/S15keyboard <<EOF
#!/bin/sh


case "\$1" in
     start)
	echo -n "gpio conf "
	loadkmap < /etc/azerty.kmap
	echo "OK"
	;;
     *)
	echo "Usage : \$0 {start}"
	exit 1
esac
EOF
fi

sync
sync

chmod 755 /mnt/system/etc/init.d/S15keyboard

sync
sync

cat >/mnt/system/etc/init.d/S20gpio <<EOF
#!/bin/sh


case "\$1" in
     start)
	echo -n "gpio conf "
        echo 17 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio17/direction
	echo 18 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio18/direction
	echo 23 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio23/direction
	echo 24 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio24/direction
	echo "OK"
	;;
     *)
	echo "Usage : \$0 {start}"
	exit 1
esac
EOF

sync
sync

chmod 755 /mnt/system/etc/init.d/S20gpio


echo "work is done"
