export OK_HOME=$HOME/ok
export OK_TARGET=x86_64-ok-linux-gnu
export MAKEFLAGS=-j$(nproc)
export LC_ALL=POSIX
export PATH=$OK_HOME/tools/bin:$PATH
export CONFIG_SITE=$OK_HOME/usr/share/config.site

export OK_HOME=/mnt
sudo chown -R root:root $OK_HOME/{usr,lib,var,etc,bin,sbin,tools,lib64}
sudo mkdir -pv $OK_HOME/{dev,proc,sys,run}
sudo mount -v --bind /dev $OK_HOME/dev
sudo mount -vt devpts devpts -o gid=5,mode=0620 $OK_HOME/dev/pts
sudo mount -vt proc proc $OK_HOME/proc
sudo mount -vt sysfs sysfs $OK_HOME/sys
sudo mount -vt tmpfs tmpfs $OK_HOME/run

if [ -h $OK_HOME/dev/shm ]; then
    sudo install -v -d -m 1777 $OK_HOME$(realpath /dev/shm)
else
    sudo mount -vt tmpfs -o nosuid,nodev tmpfs $OK_HOME/dev/shm
fi

sudo chroot "$OK_HOME" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash --login

    
export OK_HOME=$HOME/builddir   
sudo mountpoint -q $OK_HOME/dev/shm && sudo umount $OK_HOME/dev/shm
sudo umount $OK_HOME/dev/pts
sudo umount $OK_HOME/{sys,proc,run,dev}

tar -cvJpf - . | pigz -p $(nproc) > cin-os.tar.gz