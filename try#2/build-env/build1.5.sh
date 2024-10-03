#!/bin/bash

################################################################################################
################################################################################################

# shellcheck disable=SC2155
# shellcheck disable=SC2086

################################################################################################
################################################################################################

set +h
umask 022

export NTE_HOME=$HOME/nte
export NTE_TGT=x86_64-unknown-linux-gnu
export LC_ALL=POSIX
export MAKEFLAGS=-j$(nproc)
export PATH=$NTE_HOME/tools/bin:$PATH
export CONFIG_SITE=$NTE_HOME/usr/share/config.site

################################################################################################
################################################################################################

sudo chown -R root:root $NTE_HOME/{usr,lib,lib64,var,etc,bin,sbin,tools}

################################################################################################
################################################################################################

sudo mount --bind /dev $NTE_HOME/dev
sudo mount -t devpts devpts -o gid=5,mode=0620 $NTE_HOME/dev/pts
sudo mount -t proc proc $NTE_HOME/proc
sudo mount -t sysfs sysfs $NTE_HOME/sys
sudo mount -t tmpfs tmpfs $NTE_HOME/run

if [ -h $NTE_HOME/dev/shm ]; then
	sudo install -d -m 1777 $NTE_HOME/dev/shm
else
	sudo mount -t tmpfs -o nosuid,nodev tmpfs $NTE_HOME/dev/shm
fi

################################################################################################
################################################################################################

sudo chroot "$NTE_HOME" /usr/bin/env -i \
	HOME=/root \
	TERM="$TERM" \
	PS1='\u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin \
	MAKEFLAGS="-j$(nproc)" \
	/bin/bash --login