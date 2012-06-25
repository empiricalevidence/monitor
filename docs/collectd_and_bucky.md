Collectd
========

Url of collectd documentation:

    http://collectd.org/wiki/index.php/First_steps

To install collectd:

    sudo apt-get install -y collectd-core

To run or stop collectd:

    sudo /etc/init.d/collectd start
    sudo /etc/init.d/collectd restart
    sudo /etc/init.d/collectd stop


Bucky
=====

Url of Bucky documentation:

    http://pypi.python.org/pypi/bucky

To install bucky:

    pip install bucky

Config collectd to work with bucky:

    sudo vi /etc/collectd/collectd.conf

    LoadPlugin "network"
    
    <Plugin "network">
      Server "<host>" "<bucky-port>"
    </Plugin>

Collectd config example with default bucky port:

    LoadPlugin "network"
    
    <Plugin "network">
      Server "127.0.0.1" "25826"
    </Plugin>

Restart collectd:

    sudo /etc/init.d/collectd restart

Start bucky:

    bucky /opt/monitor/etc/graphite/bucky.py

Now in your Graphite url you can show the new graphs.


NOTE:
-----

Collectd problem with perl modules

    http://mailman.verplant.org/pipermail/collectd/2008-March/001616.html
    http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=612784
    https://github.com/joemiller/collectd-graphite