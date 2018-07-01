#!/bin/bash -e

# Prepare chroot directory raspbian, install kerberos.io in it.
# If run on a different architecture, qemu-user-static will be used
# for emulation.

target=raspbian
machinery_version=2.6.1
web_version=2.5.1

[[ -d $target ]] || {
    mkdir -p $target
}

if [[ `uname -m` != 'armv7l' ]]; then
    # Ensure binfmt support is enabled
    pacman -Qi binfmt-qemu-static >/dev/null 2>&1

    sudo mkdir -p $target/usr/bin
    diff -q $target/usr/bin/qemu-arm-static /usr/bin/qemu-arm-static || {
        sudo cp /usr/bin/qemu-arm-static $target/usr/bin/
    }
fi

sudo debootstrap --arch=armhf stretch $target http://raspbian.raspberrypi.org/raspbian

cat >$target/install.sh <<EOF
#!/bin/bash -x

export PATH=/bin:/sbin/:/usr/sbin:$PATH

cd /tmp

# Add more repositories
sed -i -f - /etc/apt/sources.list <<XXX
s/main$/main contrib non-free rpi firmware/
XXX

apt-get update

# Install generic dependencies not mentioned on the kerberos.io page
apt-get install -y libraspberrypi-bin ca-certificates
# Install machinery dependencies
apt-get install -y libav-tools libssl-dev

# Install kerberos.io machinery
wget https://github.com/kerberos-io/machinery/releases/download/v$machinery_version/rpi3-machinery-kerberosio-armhf-$machinery_version.deb
dpkg -i rpi3-machinery-kerberosio-armhf-$machinery_version.deb
chmod a-x /etc/systemd/system/kerberosio.service
systemctl enable kerberosio

# Install kerberos.io web dependencies
apt-get install -y nginx php7.0 php7.0-curl php7.0-gd php7.0-fpm php7.0-cli php7.0-opcache php7.0-mbstring php7.0-xml php7.0-zip php7.0-mcrypt

# Configure web
rm -f /etc/nginx/sites-enabled/default
cat >/etc/nginx/sites-enabled/kerberosio.conf <<'XXX'
server
{
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/web/public;
    server_name kerberos.rpi;
    index index.php index.html index.htm;
    location /
    {
            autoindex on;
            try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$
    {
            fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
    }
}
XXX

# Install kerberos.io web
mkdir -p /var/www/web && chown www-data:www-data /var/www/web
wget https://github.com/kerberos-io/web/releases/download/v$web_version/web.tar.gz
tar xvf web.tar.gz -C /var/www/web
chown -R www-data:www-data /var/www/web

# Adjust permissions
cd /var/www/web
chown www-data -R storage bootstrap/cache config/kerberos.php
chmod -R 775 storage bootstrap/cache
chmod 0600 config/kerberos.php

# Tune journald
mkdir /etc/systemd/journald.conf.d/
cat >/etc/systemd/journald.conf.d/00-journal-size.conf <<XXX
[Journal]
SystemMaxUse=50M
XXX
EOF
chmod +x $target/install.sh

sudo arch-chroot $target /bin/bash -x -c "/install.sh"
