#!/bin/bash
# You should run this script as your regular user
pip install -r requirements.txt
ln -s /opt/monitor/etc/graphite/{carbon.conf,storage-schemas.conf} /opt/graphite/conf/
ln -s /opt/monitor/etc/graphite/local_settings.py /opt/graphite/webapp/graphite/
mysql -u root -p -e "CREATE DATABASE graphite"
python /opt/graphite/webapp/graphite/manage.py syncdb
sudo chown -R www-data.www-data /opt/graphite
