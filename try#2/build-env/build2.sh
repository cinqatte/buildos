#!/bin/bash

################################################################################################
################################################################################################

# shellcheck disable=SC2164

################################################################################################
################################################################################################

create_directory() {
	mkdir -p /{boot,home,mnt,opt,srv}
	mkdir -p /etc/{opt,sysconfig}
	mkdir -p /lib/firmware
	mkdir -p /media/{floppy,cdrom}
	mkdir -p /usr/{,local/}{include,src}
	mkdir -p /usr/lib/locale
	mkdir -p /usr/local/{bin,lib,sbin}
	mkdir -p /usr/{,local/}share/{color,dict,doc,info,locale,man}
	mkdir -p /usr/{,local/}share/{misc,terminfo,zoneinfo}
	mkdir -p /usr/{,local/}share/man/man{1..8}
	mkdir -p /var/{cache,local,log,mail,opt,spool}
	mkdir -p /var/lib/{color,misc,locate}

	ln -sf /run /var/run
	ln -sf /run/lock /var/lock

	install -d -m 0750 /root
	install -d -m 1777 /tmp /var/tmp
}

create_file() {
	ln -s /proc/self/mounts /etc/mtab

	cat > /etc/hosts <<- "EOF"
	127.0.0.1  localhost nte
	::1        localhost
	EOF

	cat > /etc/passwd <<- "EOF"
	root:x:0:0:root:/root:/bin/bash
	bin:x:1:1:bin:/dev/null:/usr/bin/false
	daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
	messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
	systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
	systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
	systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
	systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
	systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
	systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
	systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
	uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
	systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
	nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
	EOF

	cat > /etc/group <<- "EOF"
	root:x:0:
	bin:x:1:daemon
	sys:x:2:
	kmem:x:3:
	tape:x:4:
	tty:x:5:
	daemon:x:6:
	floppy:x:7:
	disk:x:8:
	lp:x:9:
	dialout:x:10:
	audio:x:11:
	video:x:12:
	utmp:x:13:
	cdrom:x:15:
	adm:x:16:
	messagebus:x:18:
	systemd-journal:x:23:
	input:x:24:
	mail:x:34:
	kvm:x:61:
	systemd-journal-gateway:x:73:
	systemd-journal-remote:x:74:
	systemd-journal-upload:x:75:
	systemd-network:x:76:
	systemd-resolve:x:77:
	systemd-timesync:x:78:
	systemd-coredump:x:79:
	uuidd:x:80:
	systemd-oom:x:81:
	wheel:x:97:
	users:x:999:
	nogroup:x:65534:
	EOF

	localedef -i C -f UTF-8 C.UTF-8

	echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
	echo "tester:x:101:" >> /etc/group
	install -o tester -d /home/tester

	exec /usr/bin/bash --login
}

################################################################################################
################################################################################################

build_add_temp_tool_gettext() {

	cd /source
	tar -xJf gettext-0.22.5.tar.xz
	cd gettext-0.22.5
	./configure --disable-shared > /dev/null
	make > /dev/null
	cp gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
}