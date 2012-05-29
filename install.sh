#!/bin/bash
# You should run this script as ROOT

PROJECT_NAME="monitor"
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get install -q -y $(< apt-requirements.txt)

# In Ubuntu 64bits these libs are not installed in a directory where PIL can find them
if [ ! -f /usr/lib/libjpeg.so ]; then
	ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
	ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib
	ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib
fi

# Install nginx configuration
if [ -d /etc/nginx/sites-enabled ]; then
	ln -s "${SCRIPT_DIR}/etc/nginx.conf" "/etc/nginx/sites-available/${PROJECT_NAME}-nginx.conf"
	ln -s "/etc/nginx/sites-available/${PROJECT_NAME}-nginx.conf" "/etc/nginx/sites-enabled/${PROJECT_NAME}-nginx.conf"
elif [ -d /etc/nginx/conf.d ]; then
	ln -s "${SCRIPT_DIR}/etc/nginx.conf" "/etc/nginx/conf.d/${PROJECT_NAME}-nginx.conf"
else
	echo "Install nginx before you run this script (directory /etc/nginx/sites-enabled or /etc/nginx/conf.d doesn't exist)."
	exit 1
fi

# Install supervisor processes
if [ -d /etc/supervisor/conf.d ]; then
	for fn in "${SCRIPT_DIR}"/etc/supervisor/*.conf; do
		base_fn=$(basename $fn)
		ln -s "$fn" "/etc/supervisor/conf.d/${PROJECT_NAME}-${base_fn}"
	done
else
	echo "Install supervisor before you run this script (directory /etc/supervisor/conf.d doesn't exist)."
fi

# Installs the projects' crontab, if it has any
if [ -d /etc/cron.d -a -f "${SCRIPT_DIR}/etc/crontab" ]; then
	ln -s "${SCRIPT_DIR}/etc/crontab" "/etc/cron.d/${PROJECT_NAME}-crontab"
fi

# Install the Microsoft Windows Vista fonts
if [ ! -d /usr/share/fonts/vista ]; then
	wget http://cuenca-stuff.s3.amazonaws.com/install/vista-fonts.zip
	unzip vista-fonts.zip -d /usr/share/fonts
	mv /usr/share/fonts/Fonts /usr/share/fonts/vista
	rm vista-fonts.zip
	fc-cache -vf
fi

mkdir -p /opt/var/log /opt/var/pid /opt/graphite
chown www-data:www-data /opt/var /opt/var/log /opt/var/pid /opt/var/pid

# mkvirtualenv -r /opt/monitor/requirements.txt monitor
