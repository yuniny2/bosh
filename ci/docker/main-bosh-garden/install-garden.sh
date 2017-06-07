#!/bin/bash

set -xe

source /etc/profile.d/chruby.sh
chruby 2.3.1

mkdir -p /opt/garden/bin
cd /opt/garden

wget https://github.com/cloudfoundry/garden-runc-release/releases/download/v1.8.0/gdn-1.8.0
mv gdn* bin/gdn
chmod +x bin/gdn
