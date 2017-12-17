#!/bin/bash -e

# The original idea is taken from:
# http://kbeckmann.github.io/2017/05/26/QEMU-instead-of-cross-compiling/
#
# Assuming qemu-user-static and binfmt-support have already been installed.
# Also, binfmt support has been enabled:
#   sudo update-binfmts --enable

[[ -d alarm ]] || {
    wget -c -O /tmp/alarm.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
    mkdir -p alarm
    bsdtar -xpf /tmp/alarm.tar.gz -C alarm
}

cd alarm

function cleanup
{
    rm -rf /tmp/alarm.tar.gz
    sudo umount ./proc
    sudo umount ./dev
}

trap cleanup EXIT

diff -q ./usr/bin/qemu-arm-static /usr/bin/qemu-arm-static || {
    sudo cp /usr/bin/qemu-arm-static ./usr/bin/
}

# Mount the /proc file system
sudo mount -t proc proc proc
# Hack: Replace ./etc/mtab with a copy of your mounts
unlink ./etc/mtab
cat /proc/self/mounts > ./etc/mtab
# Hack: Hard code a nameserver in ./etc/resolv.conf since systemd isn't running
unlink ./etc/resolv.conf
echo "nameserver 8.8.8.8" > ./etc/resolv.conf
# Sometimes it's nice to have /dev/null. If needed, mount it in:
sudo mount -o bind /dev ./dev
sudo mount -o bind /tmp ./tmp

sudo chroot . ./bin/bash
