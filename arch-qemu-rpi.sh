#!/bin/bash -e

# The original idea is taken from:
# http://kbeckmann.github.io/2017/05/26/QEMU-instead-of-cross-compiling/
#
# Assuming qemu-user-static has already been installed.

target=alarm

[[ -d $target ]] || {
    wget -c -O /tmp/alarm.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
    mkdir -p $target
    bsdtar -xpf /tmp/alarm.tar.gz -C $target
}

# Ensure binfmt support is enabled
pacman -Qi binfmt-qemu-static >/dev/null 2>&1

diff -q $target/usr/bin/qemu-arm-static /usr/bin/qemu-arm-static || {
    sudo cp /usr/bin/qemu-arm-static $target/usr/bin/
}

sudo arch-chroot $target /bin/bash
