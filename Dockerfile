FROM ubuntu:18.04
MAINTAINER Phil Hawthorne <me@philhawthorne.com>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

# Default versions
ENV INFLUXDB_VERSION 1.2.0
ENV GRAFANA_VERSION  4.1.1-1484211277

# Database Defaults
ENV INFLUXDB_GRAFANA_DB datasource
ENV INFLUXDB_GRAFANA_USER datasource
ENV INFLUXDB_GRAFANA_PW datasource

ENV GF_DATABASE_TYPE=sqlite3

# Fix bad proxy issue
COPY system/99fixbadproxy /etc/apt/apt.conf.d/99fixbadproxy

# Clear previous sources
RUN rm /var/lib/apt/lists/* -vf

# Base dependencies
RUN apt-get -y update && \
 apt-get -y dist-upgrade && \
 apt-get -y install \
  build-essential \
  apt-utils \
  ca-certificates \
  curl \
  git \
  htop \
  libfontconfig \
  nano \
  net-tools \
  openssh-server \
  supervisor \
  gnupg2 \
  wget && \
  wget -qO- https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y nodejs && \
  npm install npm@latest

WORKDIR /root

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/run/sshd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd && \
    rm -rf .ssh && \
    rm -rf .profile && \
    mkdir .ssh

# Install InfluxDB
RUN wget https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# Install Grafana
RUN wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${GRAFANA_VERSION}_amd64.deb && \
    dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && rm grafana_${GRAFANA_VERSION}_amd64.deb

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure Supervisord, SSH and base env
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ssh/id_rsa .ssh/id_rsa
COPY bash/profile .profile

# Configure InfluxDB
COPY influxdb/influxdb.conf /etc/influxdb/influxdb.conf
COPY influxdb/init.sh /etc/init.d/influxdb

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini

RUN chmod 0755 /etc/init.d/influxdb

CMD ["/usr/bin/supervisord"]
