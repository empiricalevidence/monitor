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

# Install nginx configuration
if [[ -d /etc/nginx/sites-enabled ]]; then
	sudo ln -s "${SCRIPT_DIR}/etc/nginx.conf" "/etc/nginx/sites-available/${PROJECT_NAME}-nginx.conf"
	sudo ln -s "/etc/nginx/sites-available/${PROJECT_NAME}-nginx.conf" "/etc/nginx/sites-enabled/${PROJECT_NAME}-nginx.conf"
elif [[ -d /etc/nginx/conf.d ]]; then
	sudo ln -s "${SCRIPT_DIR}/etc/nginx.conf" "/etc/nginx/conf.d/${PROJECT_NAME}-nginx.conf"
else
	echo "Install nginx before you run this script (directory /etc/nginx/sites-enabled or /etc/nginx/conf.d doesn't exist)."
	exit 1
fi

sudo mkdir -p /opt/var/log /opt/var/pid /opt/graphite /opt/envs
sudo chown "$USER":"$GROUP" /opt/var /opt/var/log /opt/var/pid /opt/var/pid /opt/graphite /opt/envs

if [[ ! -d "/opt/envs/${PROJECT_NAME}" ]]; then
    virtualenv --distribute "/opt/envs/${PROJECT_NAME}"
fi

if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
    pip install -r "${SCRIPT_DIR}/requirements.txt" -E "/opt/envs/${PROJECT_NAME}"
fi

ln -s -f  "${SCRIPT_DIR}/etc/graphite/"*.conf /opt/graphite/conf
ln -s "${SCRIPT_DIR}/etc/graphite/local_settings.py" /opt/graphite/webapp/graphite/

# Installs the projects' collectd config, if it has any
if [[ -d /etc/collectd && -f "${SCRIPT_DIR}/etc/collectd.conf" ]]; then
	sudo ln -sf "${SCRIPT_DIR}/etc/collectd.conf" "/etc/collectd/collectd.conf"
    sudo /etc/init.d/collectd restart
fi

echo "Enter the MySQL password of root"
mysql -u root -p -e "CREATE DATABASE graphite"
/opt/graphite/webapp/graphite/manage.py syncdb

sudo apt-get install supervisor
# Install supervisor processes
if [ -d /etc/supervisor/conf.d ]; then
	for fn in "${SCRIPT_DIR}"/etc/supervisor/*.conf; do
		base_fn=$(basename $fn)
		sudo ln -s "$fn" "/etc/supervisor/conf.d/${PROJECT_NAME}-${base_fn}"
	done
else
	echo "Install supervisor before you run this script (directory /etc/supervisor/conf.d doesn't exist)."
fi

sudo supervisorctl -c /etc/supervisor/supervisord.conf reread "${PROJECT_NAME}"
# TODO: Verify if we need update. I.e., does restart takes care of update?
sudo supervisorctl -c /etc/supervisor/supervisord.conf update "${PROJECT_NAME}":*
sudo supervisorctl -c /etc/supervisor/supervisord.conf restart "${PROJECT_NAME}":*

# Installs the projects' crontab, if it has any
if [[ -d /etc/cron.d && -f "${SCRIPT_DIR}/etc/crontab" ]]; then
	sudo ln -s "${SCRIPT_DIR}/etc/crontab" "/etc/cron.d/${PROJECT_NAME}-crontab"
fi
