#!/bin/bash
# You should run this script as ROOT

PROJECT_NAME="monitor"
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
USER=www-data
GROUP="$USER"

sudo apt-get install -q -y $(< apt-requirements.txt)

# In Ubuntu 64bits these libs are not installed in a directory where PIL can find them
if [[ ! -f /usr/lib/libjpeg.so ]]; then
	sudo ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
	sudo ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib
	sudo ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib
fi

sudo mkdir -p /opt/var/log/monitor /opt/var/pid /opt/graphite /opt/envs
sudo chown "$USER":"$GROUP" /opt/var /opt/var/log /opt/var/log/monitor /opt/var/pid /opt/var/pid /opt/graphite /opt/envs
groupadd collectd

if [[ ! -d "/opt/envs/${PROJECT_NAME}" ]]; then
    virtualenv --distribute "/opt/envs/${PROJECT_NAME}"
fi

if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
    pip install -r "${SCRIPT_DIR}/requirements.txt" -E "/opt/envs/${PROJECT_NAME}"
fi

cp -R system/* /

sudo /etc/init.d/collectd restart

echo "Enter the MySQL password of root"
mysql -u root -p -e "CREATE DATABASE graphite"
/opt/graphite/webapp/graphite/manage.py syncdb

sudo supervisorctl -c /etc/supervisor/supervisord.conf reread "${PROJECT_NAME}"
# TODO: Verify if we need update. I.e., does restart takes care of update?
sudo supervisorctl -c /etc/supervisor/supervisord.conf update "${PROJECT_NAME}":*
sudo supervisorctl -c /etc/supervisor/supervisord.conf restart "${PROJECT_NAME}":*
