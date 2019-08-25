#!/bin/bash -e

# We need to ensure this directory is writeable on start of the container
chmod 0777 /var/lib/grafana
chown influxdb:influxdb /var/run/influxdb/influxd.pid

exec /usr/bin/supervisord