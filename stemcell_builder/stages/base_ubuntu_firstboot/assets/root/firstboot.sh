#!/bin/bash

set -e

rm -f /etc/ssh/ssh_host*key*

RECONFIGURED=1
COUNT=60

while [ $COUNT -gt 0 ] && [ $RECONFIGURED != '0' ]; do
	dpkg-reconfigure -fnoninteractive -pcritical openssh-server &&
		dpkg-reconfigure -fnoninteractive sysstat
	RECONFIGURED=$?
	COUNT=$(( COUNT - 1 ))
	sleep 1
done
