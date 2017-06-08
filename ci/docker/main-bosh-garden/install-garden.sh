#!/bin/bash

set -xe

source /etc/profile.d/chruby.sh
chruby 2.3.1

mkdir -p /opt/garden/bin
cd /opt/garden

wget https://github.com/cloudfoundry/garden-runc-release/releases/download/v1.8.0/gdn-1.8.0
mv gdn* bin/gdn
chmod +x bin/gdn

wget https://github.com/cloudfoundry/grootfs/releases/download/v0.19.0/grootfs-0.19.0
mv grootfs-* bin/grootfs
chmod +x bin/grootfs

wget https://github.com/cloudfoundry/grootfs/releases/download/v0.19.0/tardis-0.19.0
mv tardis-* bin/tardis
chmod +x bin/tardis

wget https://github.com/cloudfoundry/grootfs/releases/download/v0.19.0/drax-0.19.0
mv drax-* bin/drax
chmod +x bin/drax

