#!/bin/bash

################################################################################################
################################################################################################

# shellcheck disable=SC2093
# shellcheck disable=SC2164

################################################################################################
################################################################################################

creating_directories() {
	mkdir -p /{boot,home,mnt,opt,srv}
	mkdir -p /etc/{opt,sysconfig}
	mkdir -p /lib/firmware
	mkdir -p /media/{floppy,cdrom}
	mkdir -p /usr/{,local/}{include,src}
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

creating_files() {
	ln -s /proc/self/mounts /etc/mtab

	cat > /etc/hosts <<- "EOF"
	127.0.0.1	localhost
	127.0.1.1	nte
	::1			localhost
	::1			ip6-localhost ip6-loopback
	fe00::0		ip6-localnet
	ff00::0		ip6-mcastprefix
	ff02::1		ip6-allnodes
	ff02::2		ip6-allrouters
	EOF

	cat > /etc/passwd <<- "EOF"
	root:x:0:0:root:/root:/bin/bash
	bin:x:1:1:bin:/dev/null:/usr/bin/false
	daemon:x:6:6::/dev/null:/usr/bin/false
	uuidd:x:80:80::/dev/null:/usr/bin/false
	nobody:x:65534:65534::/dev/null:/usr/bin/false
	EOF

	cat > /etc/group <<- "EOF"
	root:x:0:
	bin:x:1:daemon
	sys:x:2:
	kmem:x:3:
	tape:x:4:
	tty:x:5:
	daemon:x:6:
	disk:x:8:
	utmp:x:13:
	adm:x:16:
	input:x:24:
	kvm:x:61:
	uuidd:x:80:
	wheel:x:97:
	users:x:999:
	nogroup:x:65534:
	EOF

	cat > /etc/profile <<- "EOF"
	[[ $- != *i* ]] && return

	if [ -x /usr/bin/dircolors ]; then
		eval "$(dircolors -b)"
		alias ls='ls --color=auto'
		alias grep='grep --color=auto'
		alias fgrep='fgrep --color=auto'
		alias egrep='egrep --color=auto'
	fi

	alias ll='ls -alF'
	alias la='ls -A'
	alias l='ls -CF'

	PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

	if [ -f /etc/bashrc ]; then
		. /etc/bashrc
	fi
	EOF

	cat > /etc/resolv.conf <<- "EOF"
	nameserver 8.8.8.8
	nameserver 8.8.4.4
	EOF

	echo "nte" >> /etc/hostname

	exec /usr/bin/bash --login

	touch /var/log/{btmp,lastlog,faillog,wtmp}
	chgrp utmp /var/log/lastlog
	chmod 664  /var/log/lastlog
	chmod 600  /var/log/btmp
}

################################################################################################
################################################################################################

build_additional_temporary_tools() {
	# BUILD GETTEXT
	cd /source/gettext-0.22.5
	./configure \
		--disable-shared > /dev/null
	make > /dev/null
	cp gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

	# BUILD BISON
	cd /source/bison-3.8.2
	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/bison-3.8.2 > /dev/null
	make > /dev/null && make install > /dev/null


	# BUILD PERL
	cd /source/perl-5.38.2
	sh Configure -des \
		-D prefix=/usr \
		-D vendorprefix=/usr \
		-D useshrplib \
		-D privlib=/usr/lib/perl5/5.38/core_perl \
		-D archlib=/usr/lib/perl5/5.38/core_perl \
		-D sitelib=/usr/lib/perl5/5.38/site_perl \
		-D sitearch=/usr/lib/perl5/5.38/site_perl \
		-D vendorlib=/usr/lib/perl5/5.38/vendor_perl \
		-D vendorarch=/usr/lib/perl5/5.38/vendor_perl > /dev/null
	make > /dev/null && make install > /dev/null

	# BUILD PYTHON
	cd /source/Python-3.12.4
	./configure \
		--prefix=/usr \
		--enable-shared \
		--without-ensurepip > /dev/null
	make > /dev/null && make install > /dev/null

	# BUILD TEXINFO
	cd /source/texinfo-7.1
	./configure \
		--prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null

	# BUILD UTIL-LINUX
	cd /source/util-linux-2.40.2
	mkdir -p /var/lib/hwclock
	./configure \
		--libdir=/usr/lib \
		--runstatedir=/run \
		--disable-chfn-chsh \
		--disable-login \
		--disable-nologin \
		--disable-su \
		--disable-setpriv \
		--disable-runuser \
		--disable-pylibmount \
		--disable-static \
		--disable-liblastlog2 \
		--without-python \
		ADJTIME_PATH=/var/lib/hwclock/adjtime \
		--docdir=/usr/share/doc/util-linux-2.40.2 > /dev/null
	make > /dev/null && make install > /dev/null
}

clean_up() {
	rm -rf /usr/share/{info,man,doc}/*
	find /usr/{lib,libexec} -name \*.la -delete
	rm -rf /tools
}

install_system_software() {
	# BUILD MAN-PAGE
	cd /source/man-pages-6.9.1
	rm man3/crypt*
	make prefix=/usr install > /dev/null
	cd /source
	rm -rf /source/man-pages-6.9.1*

	# BUILD IANA-ETC
	cd /source/iana-etc-20240701
	cp services protocols /etc
	cd /source
	rm -rf /source/iana-etc-20240701*

	# BUILD GLIBC
	cd /source/glibc-2.39
	patch -Np1 -i ../glibc-2.39-fhs-1.patch
	patch -Np1 -i ../glibc-2.39-upstream_fix-2.patch
	mkdir -p build && cd build
	echo "rootsbindir=/usr/sbin" > configparms
	../configure \
		--prefix=/usr \
		--disable-werror \
		--enable-kernel=4.19 \
		--enable-stack-protector=strong \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib  > /dev/null
	make > /dev/null
	touch /etc/ld.so.conf
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
	make install > /dev/null
	sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
	localedef -i C -f UTF-8 C.UTF-8
	localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
	localedef -i de_DE -f ISO-8859-1 de_DE
	localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
	localedef -i de_DE -f UTF-8 de_DE.UTF-8
	localedef -i el_GR -f ISO-8859-7 el_GR
	localedef -i en_GB -f ISO-8859-1 en_GB
	localedef -i en_GB -f UTF-8 en_GB.UTF-8
	localedef -i en_HK -f ISO-8859-1 en_HK
	localedef -i en_PH -f ISO-8859-1 en_PH
	localedef -i en_US -f ISO-8859-1 en_US
	localedef -i en_US -f UTF-8 en_US.UTF-8
	localedef -i es_ES -f ISO-8859-15 es_ES@euro
	localedef -i es_MX -f ISO-8859-1 es_MX
	localedef -i fa_IR -f UTF-8 fa_IR
	localedef -i fr_FR -f ISO-8859-1 fr_FR
	localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
	localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
	localedef -i is_IS -f ISO-8859-1 is_IS
	localedef -i is_IS -f UTF-8 is_IS.UTF-8
	localedef -i it_IT -f ISO-8859-1 it_IT
	localedef -i it_IT -f ISO-8859-15 it_IT@euro
	localedef -i it_IT -f UTF-8 it_IT.UTF-8
	localedef -i ja_JP -f EUC-JP ja_JP
	localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
	localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
	localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
	localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
	localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
	localedef -i se_NO -f UTF-8 se_NO.UTF-8
	localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
	localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
	localedef -i zh_CN -f GB18030 zh_CN.GB18030
	localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
	localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
	make localedata/install-locales
	localedef -i C -f UTF-8 C.UTF-8
	localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
	cat > /etc/nsswitch.conf <<- "EOF"
	passwd: files systemd
	group: files systemd
	shadow: files systemd

	hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
	networks: files

	protocols: files
	services: files
	ethers: files
	rpc: files
	EOF
	tar -xf ../../tzdata2024a.tar.gz
	ZONEINFO=/usr/share/zoneinfo
	mkdir -p $ZONEINFO/{posix,right}
	for tz in etcetera southamerica northamerica europe africa antarctica  \
			  asia australasia backward; do
		zic -L /dev/null   -d $ZONEINFO       ${tz}
		zic -L /dev/null   -d $ZONEINFO/posix ${tz}
		zic -L leapseconds -d $ZONEINFO/right ${tz}
	done
	cp zone.tab zone1970.tab iso3166.tab $ZONEINFO
	zic -d $ZONEINFO -p Africa/Johannesburg
	unset ZONEINFO
	ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
	cat > /etc/ld.so.conf <<- "EOF"
	/usr/local/lib
	/opt/lib
	include /etc/ld.so.conf.d/*.conf
	EOF
	mkdir -p /etc/ld.so.conf.d
	cd /source
	rm -rf glibc-2.39*

	# BUILD ZLIB
	cd /source/zlib-1.3.1
	./configure \
		--prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	rm -f /usr/lib/libz.a
	cd /source
	rm -rf zlib-1.3.1*

	# BUILD BZIP2
	cd /source/bzip2-1.0.8
	patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
	sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
	sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
	make -f Makefile-libbz2_so > /dev/null && make clean > /dev/null
	make > /dev/null && make install PREFIX=/usr > /dev/null
	cp -a libbz2.so.* /usr/lib
	ln -s libbz2.so.1.0.8 /usr/lib/libbz2.so
	cp bzip2-shared /usr/bin/bzip2
	for i in /usr/bin/{bzcat,bunzip2}; do
		ln -sf bzip2 $i
	done
	rm -f /usr/lib/libbz2.a
	cd /source
	rm -rf bzip2-1.0.8*

	# BUILD XZ
	cd /source/xz-5.6.2
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/xz-5.6.2 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf xz-5.6.2*

	# BUILD LZ4
	cd /source/lz4-1.9.4
	make BUILD_STATIC=no > /dev/null
	make BUILD_STATIC=no PREFIX=/usr install > /dev/null
	cd /source
	rm -rf lz4-1.9.4*

	# BUILD ZSTD
	cd /source/zstd-1.5.6
	make prefix=/usr > /dev/null && make prefix=/usr install > /dev/null
	rm /usr/lib/libzstd.a
	cd /source/
	rm -rf zstd-1.5.6*

	# BUILD FILE
	cd /source/file-5.45
	./configure \
		--prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source/
	rm -rf file-5.45*

	# BUILD READLINE
	cd /source/readline-8.2
	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install
	sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
	patch -Np1 -i ../readline-8.2-upstream_fixes-3.patch
	./configure \
		--prefix=/usr    \
		--disable-static \
		--with-curses    \
		--docdir=/usr/share/doc/readline-8.2 > /dev/null
	make SHLIB_LIBS="-lncursesw" > /dev/null
	make SHLIB_LIBS="-lncursesw" install > /dev/null
	install -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2
	cd /source/
	rm -rf readline-8.2*

	# BUILD M4
	cd /source/m4-1.4.19
	./configure \
		--prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source/
	rm -rf m4-1.4.19*

	# BUILD BC
	cd /source/bc-6.7.6
	CC=gcc ./configure --prefix=/usr -G -O3 -r > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source/
	rm -rf bc-6.7.6*

	# BUILD FLEX
	cd /source/flex-2.6.4
	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/flex-2.6.4 \
		--disable-static > /dev/null
	make > /dev/null && make install > /dev/null
	ln -s flex /usr/bin/lex
	ln -s flex.1 /usr/share/man/man1/lex.1
	cd /source/
	rm -rf flex-2.6.4*

	# BUILD TCL
	cd /source/tcl8.6.14
	SRCDIR=$(pwd)
	cd unix
	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--disable-rpath > /dev/null
	make > /dev/null
	sed -e "s|$SRCDIR/unix|/usr/lib|" \
		-e "s|$SRCDIR|/usr/include|"  \
		-i tclConfig.sh
	sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.7|/usr/lib/tdbc1.1.7|" \
		-e "s|$SRCDIR/pkgs/tdbc1.1.7/generic|/usr/include|"    \
		-e "s|$SRCDIR/pkgs/tdbc1.1.7/library|/usr/lib/tcl8.6|" \
		-e "s|$SRCDIR/pkgs/tdbc1.1.7|/usr/include|"            \
		-i pkgs/tdbc1.1.7/tdbcConfig.sh
	sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.4|/usr/lib/itcl4.2.4|" \
		-e "s|$SRCDIR/pkgs/itcl4.2.4/generic|/usr/include|"    \
		-e "s|$SRCDIR/pkgs/itcl4.2.4|/usr/include|"            \
		-i pkgs/itcl4.2.4/itclConfig.sh
	unset SRCDIR
	make install > /dev/null
	chmod -v u+w /usr/lib/libtcl8.6.so
	make install-private-headers
	ln -sf tclsh8.6 /usr/bin/tclsh
	mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
	cd ../
	tar -xf ../tcl8.6.14-html.tar.gz --strip-components=1
	mkdir -p /usr/share/doc/tcl-8.6.14
	cp -r  ./html/* /usr/share/doc/tcl-8.6.14
	cd /source
	rm -rf tcl8.6.14*

	# BUILD PKGCONF
	cd /source/pkgconf-2.2.0
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/pkgconf-2.2.0 > /dev/null
	make > /dev/null && make install > /dev/null
	ln -s pkgconf /usr/bin/pkg-config
	ln -s pkgconf.1 /usr/share/man/man1/pkg-config.1
	cd /source
	rm -rf pkgconf-2.2.0*

	# BUILD BINUTILS
	cd /source/binutils-2.42
	mkdir -p build3 && cd build3
	../configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-gold \
		--enable-ld=default \
		--enable-plugins \
		--enable-shared \
		--disable-werror \
		--enable-64-bit-bfd \
		--with-system-zlib \
		--enable-default-hash-style=gnu > /dev/null
	make tooldir=/usr > /dev/null && make tooldir=/usr install > /dev/null
	rm -f /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
	cd /source
	rm -rf binutils-2.42*

	# BUILD GMP
	cd /source/gmp-6.3.0
	./configure \
		--prefix=/usr \
		--enable-cxx \
		--disable-static \
		--docdir=/usr/share/doc/gmp-6.3.0 > /dev/null
	make > /dev/null && make html > /dev/null
	make install > /dev/null && make install-html > /dev/null
	cd /source
	rm -rf gmp-6.3.0*

	# BUILD MPFR
	cd /source/mpfr-4.2.1
	./configure \
		--prefix=/usr \
		--disable-static     \
		--enable-thread-safe \
		--docdir=/usr/share/doc/mpfr-4.2.1 > /dev/null
	make > /dev/null && make html > /dev/null
	make install > /dev/null && make install-html > /dev/null
	cd /source
	rm -rf mpfr-4.2.1*

	# BUILD MPC
	cd /source/mpc-1.3.1
	./configure \
		--prefix=/usr \
		--disable-static     \
		--docdir=/usr/share/doc/mpc-1.3.1 > /dev/null
	make > /dev/null && make html > /dev/null
	make install > /dev/null && make install-html > /dev/null
	cd /source
	rm -rf mpc-1.3.1*

	# BUILD ATTR
	cd /source/attr-2.5.2
	./configure \
		--prefix=/usr \
		--disable-static  \
		--sysconfdir=/etc \
		--docdir=/usr/share/doc/attr-2.5.2 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf attr-2.5.2*

	# BUILD ACL
	cd /source/acl-2.3.2
	./configure \
		--prefix=/usr \
		--disable-static      \
		--docdir=/usr/share/doc/acl-2.3.2 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf acl-2.3.2*

	# BUILD LIBCAP
	cd /source/libcap-2.70
	sed -i '/install -m.*STA/d' libcap/Makefile
	make prefix=/usr lib=lib > /dev/null && make prefix=/usr lib=lib install > /dev/null
	cd /source
	rm -rf libcap-2.70*

	# BUILD LIBXCRYPT
	cd /source/libxcrypt-4.4.36
	./configure \
		--prefix=/usr \
		--enable-hashes=strong,glibc \
		--enable-obsolete-api=no \
		--disable-static \
		--disable-failure-tokens > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf libxcrypt-4.4.36*

	# BUILD SHADOW
	cd /source/shadow-4.16.0
	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
	sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
    touch /usr/bin/passwd
	./configure \
		--sysconfdir=/etc   \
		--disable-static    \
		--with-{b,yes}crypt \
		--without-libbsd    \
		--with-group-name-max-length=32 > /dev/null
	make > /dev/null && make exec_prefix=/usr install > /dev/null
	make -C man install-man > /dev/null
	pwconv
	grpconv
	mkdir -p /etc/default
	useradd -D --gid 999
	sed -i '/MAIL/s/yes/no/' /etc/default/useradd
	passwd root
	cd /source
	rm -rf shadow-4.16.0*

	# BUILD GCC
	cd /source/gcc-14.1.0
	mkdir -p build4 && cd build4
	../configure \
		--prefix=/usr \
		LD=ld \
		--enable-languages=c,c++ \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-host-pie \
		--disable-multilib \
		--disable-bootstrap \
		--disable-fixincludes \
		--with-system-zlib
	make > /dev/null && make install > /dev/null
	ln -sr /usr/bin/cpp /usr/lib
	ln -s gcc.1 /usr/share/man/man1/cc.1
	ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/14.1.0/liblto_plugin.so /usr/lib/bfd-plugins/
	mkdir -pv /usr/share/gdb/auto-load/usr/lib
	mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
	cd /source
	rm -rf gcc-14.1.0*

	cd /source/ncurses-6.5
	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--with-shared \
		--without-debug \
		--without-normal \
		--with-cxx-shared \
		--enable-pc-files \
		--with-pkg-config-libdir=/usr/lib/pkgconfig > /dev/null
	make > /dev/null && make DESTDIR=$PWD/dest install > /dev/null
	install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
	rm dest/usr/lib/libncursesw.so.6.5
	sed -e 's/^#if.*XOPEN.*$/#if 1/' \
		-i dest/usr/include/curses.h
	cp -a dest/* /
	for lib in ncurses form panel menu ; do
		ln -sf lib${lib}w.so /usr/lib/lib${lib}.so
		ln -sf ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
	done
	ln -sf libncursesw.so /usr/lib/libcurses.so
	cp -R doc -T /usr/share/doc/ncurses-6.5
	cd /source
	rm -rf ncurses-6.5*

	cd /source/sed-4.9
	./configure --prefix=/usr > /dev/null
	make > /dev/null
	make html > /dev/null
	make install
	install -d -m755 /usr/share/doc/sed-4.9
	install -m644 doc/sed.html /usr/share/doc/sed-4.9
	cd /source
	rm -rf sed-4.9*

	cd /source/psmisc-23.7
	./configure --prefix=/usr > /dev/null
	make > /dev/null
	make install > /dev/null
	cd /source
	rm -rf psmisc-23.7*

	cd /source/gettext-0.22.5
	./configure --prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/gettext-0.22.5 > /dev/null
	make > /dev/null
	make install > /dev/null
	chmod -v 0755 /usr/lib/preloadable_libintl.so
	cd /source
	rm -rf gettext-0.22.5*

	cd /source/bison-3.8.2
	./configure --prefix=/usr \
		--docdir=/usr/share/doc/bison-3.8.2 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf bison-3.8.2*

	cd /source/grep-3.11
	sed -i "s/echo/#echo/" src/egrep.sh
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf grep-3.11*

	cd /source/bash-5.2.21
	patch -Np1 -i ../bash-5.2.21-upstream_fixes-1.patch
	./configure --prefix=/usr \
		--without-bash-malloc \
		--with-installed-readline \
		bash_cv_strtold_broken=no \
		--docdir=/usr/share/doc/bash-5.2.21 > /dev/null
	make > /dev/null && make install > /dev/null
	exec /usr/bin/bash --login
	cd /source
	rm -rf bash-5.2.21*

	cd /source/libtool-2.4.7
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	rm -f /usr/lib/libltdl.a
	cd /source
	rm -rf libtool-2.4.7*

	cd /source/gdbm-1.24
	./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf gdbm-1.24*

	cd /source/gperf-3.1
	./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf gperf-3.1*

	cd /source/expat-2.6.2
	./configure --prefix=/usr --docdir=/usr/share/doc/expat-2.6.2 > /dev/null
	make > /dev/null && make install > /dev/null
	install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.2
	cd /source
	rm -rf expat-2.6.2*

	cd /source/inetutils-2.5
	sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
	./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers > /dev/null
	make > /dev/null && make install > /dev/null
	mv /usr/{,s}bin/ifconfig
	cd /source
	rm -rf inetutils-2.5*

	cd /source/less-661
	./configure --prefix=/usr --sysconfdir=/etc > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf less-661*

	cd /source/perl-5.38.2
	export BUILD_ZLIB=False
	export BUILD_BZIP2=0
	sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads > /dev/null
	make > /dev/null && make install > /dev/null
	unset BUILD_ZLIB BUILD_BZIP2
	cd /source
	rm -rf perl-5.38.2*

	cd /source/XML-Parser-2.47
	perl Makefile.PL
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf XML-Parser-2.47*

	cd /source/intltool-0.51.0
	sed -i 's:\\\${:\\\$\\{:' intltool-update.in
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
	cd /source
	rm -rf intltool-0.51.0*

	cd /source/autoconf-2.72
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf autoconf-2.72*

	cd /source/automake-1.17
	./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17 > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf automake-1.17*

	cd /source/openssl-3.3.1
	./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic > /dev/null
	make > /dev/null
	sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
	make MANSUFFIX=ssl install > /dev/null
	mv /usr/share/doc/openssl /usr/share/doc/openssl-3.3.1
	cp -fr doc/* /usr/share/doc/openssl-3.3.1
	cd /source
	rm -rf openssl-3.3.1*

	cd /source/kmod-32
	./configure --prefix=/usr \
            --sysconfdir=/etc \
            --with-openssl \
            --with-xz \
            --with-zstd \
            --with-zlib > /dev/null
	make > /dev/null && make install > /dev/null
	for target in depmod insmod modinfo modprobe rmmod; do
	  ln -sfv ../bin/kmod /usr/sbin/$target
	  rm -fv /usr/bin/$target
	done
	cd /source
	rm -rf kmod-32*

	cd /source/elfutils-0.191
	./configure --prefix=/usr \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy > /dev/null
	make > /dev/null && make -C libelf install > /dev/null
	install -vm644 config/libelf.pc /usr/lib/pkgconfig
	rm /usr/lib/libelf.a
	cd /source
	rm -rf elfutils-0.191*

	cd /source/libffi-3.4.6
	./configure --prefix=/usr \
            --disable-static \
            --with-gcc-arch=native > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf libffi-3.4.6*

	cd /source/Python-3.12.4
	./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations > /dev/null
	make > /dev/null && make install > /dev/null
	cat > /etc/pip.conf <<- EOF
	[global]
	root-user-action = ignore
	disable-pip-version-check = true
	EOF
	install -v -dm755 /usr/share/doc/python-3.12.4/html
	tar --no-same-owner \
		-xf ../python-3.12.4-docs-html.tar.bz2
	cp -R --no-preserve=mode python-3.12.4-docs-html/* \
		/usr/share/doc/python-3.12.4/html
	cd /source
	rm -rf Python-3.12.4* python*

	# pip3 install flit-core wheel setuptools meson markupsafe jinja2 pefile

	cd /source/ninja-1.12.1
	export NINJAJOBS=$(nproc)
	sed -i '/int Guess/a \
	  int   j = 0;\
	  char* jobs = getenv( "NINJAJOBS" );\
	  if ( jobs != NULL ) j = atoi( jobs );\
	  if ( j > 0 ) return j;\
	' src/ninja.cc
	python3 configure.py --bootstrap
	install -vm755 ninja /usr/bin/
	install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
	install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
	cd /source
	rm -rf ninja-1.12.1*

	cd /source/coreutils-9.5
	patch -Np1 -i ../coreutils-9.5-i18n-2.patch
	autoreconf -fiv
	FORCE_UNSAFE_CONFIGURE=1 ./configure \
				--prefix=/usr \
				--enable-no-install-program=kill,uptime > /dev/null
	make > /dev/null && make install > /dev/null
	mv -v /usr/bin/chroot /usr/sbin
	mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
	cd /source
	rm -rf coreutils-9.5*

	cd /source/diffutils-3.10
	./configure --prefix=/usr  > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf diffutils-3.10*

	cd /source/gawk-5.3.0
	sed -i 's/extras//' Makefile.in
	./configure --prefix=/usr  > /dev/null
	make > /dev/null
	rm -f /usr/bin/gawk-5.3.0
	make install > /dev/null
	cd /source
	rm -rf gawk-5.3.0*

	cd /source/findutils-4.10.0
	./configure --prefix=/usr --localstatedir=/var/lib/locate > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf findutils-4.10.0*

	cd /source/groff-1.23.0
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf groff-1.23.0*

	cd /source/grub-2.12
	unset {C,CPP,CXX,LD}FLAGS
	echo depends bli part_gpt > grub-core/extra_deps.lst
	./configure --prefix=/usr \
            --sysconfdir=/etc \
            --disable-efiemu \
            --disable-werror > /dev/null
	make > /dev/null && make install > /dev/null
	mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
	cd /source
	rm -rf grub-2.12*

	cd /source/gzip-1.13
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf gzip-1.13*

	cd /source/iproute2-6.9.0
	sed -i /ARPD/d Makefile
	rm -fv man/man8/arpd.8
	make NETNS_RUN_DIR=/run/netns > /dev/null
	make SBINDIR=/usr/sbin install > /dev/null
	mkdir -pv             /usr/share/doc/iproute2-6.9.0
	cp -v COPYING README* /usr/share/doc/iproute2-6.9.0
	cd /source
	rm -rf iproute2-6.9.0*

	cd /source/kbd-2.6.4
	patch -Np1 -i ../kbd-2.6.4-backspace-1.patch
	sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
	sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
	./configure --prefix=/usr --disable-vlock > /dev/null
	make > /dev/null && make install > /dev/null
	cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4
	cd /source
	rm -rf kbd-2.6.4*

	cd /source/libpipeline-1.5.7
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf libpipeline-1.5.7*

	cd /source/make-4.4.1
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf make-4.4.1*

	cd /source/patch-2.7.6
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf patch-2.7.6*

	cd /source/tar-1.35
	FORCE_UNSAFE_CONFIGURE=1  \
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	make -C doc install-html docdir=/usr/share/doc/tar-1.35
	cd /source
	rm -rf tar-1.35*

	cd /source/texinfo-7.1
	./configure --prefix=/usr > /dev/null
	make > /dev/null && make install > /dev/null
	make TEXMF=/usr/share/texmf install-tex > /dev/null
	pushd /usr/share/info
		rm -v dir
		for f in *; do
			install-info $f dir 2>/dev/null
		done
	popd
	cd /source
	rm -rf texinfo-7.1*

	cd /source/systemd-256.1
	sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
	mkdir -p build && cd build
	meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D default-dnssec=no    \
      -D firstboot=false      \
      -D install-tests=false  \
      -D rpmmacrosdir=no      \
      -D homed=disabled       \
      -D userdb=false         \
      -D man=disabled         \
      -D mode=release         \
      -D dev-kvm-mode=0660    \
      -D nobody-group=nogroup \
      -D sysupdate=disabled   \
      -D docdir=/usr/share/doc/systemd-256.1 > /dev/null
	ninja > /dev/null && ninja install > /dev/null
	tar -xf ../../systemd-man-pages-256.1.tar.xz \
    --no-same-owner --strip-components=1   \
    -C /usr/share/man
    systemd-machine-id-setup
    systemctl preset-all
	cd /source
	rm -rf systemd*

	cd /source/dbus-1.14.10
	./configure --prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--runstatedir=/run \
		--enable-user-session \
		--disable-static \
		--disable-doxygen-docs \
		--disable-xml-docs \
		--docdir=/usr/share/doc/dbus-1.14.10 \
		--with-system-socket=/run/dbus/system_bus_socket > /dev/null
	make > /dev/null && make install > /dev/null
	ln -sfv /etc/machine-id /var/lib/dbus
	cd /source
	rm -rf dbus-1.14.10*

	cd /source/man-db-2.12.1
	./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf man-db-2.12.1*

	cd /source/procps-ng-4.0.4
	./configure --prefix=/usr \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static \
            --disable-kill > /dev/null
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf procps-ng-4.0.4*

	cd /source/util-linux-2.40.2
	./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2  > /dev/null
	touch /etc/fstab
	make > /dev/null && make install > /dev/null
	cd /source
	rm -rf util-linux-2.40.2*

	cd /source/e2fsprogs-1.47.1
	mkdir -p build && cd build
	../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck  > /dev/null
	make > /dev/null && make install
	rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
	gunzip -v /usr/share/info/libext2fs.info.gz
	install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
	makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
	install -v -m644 doc/com_err.info /usr/share/info
	install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
	sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
	cd /source
	rm -rf e2fsprogs-1.47.1*


	cd /source/wget-1.24.5

	./configure --prefix=/usr \
            --sysconfdir=/etc  \
            --with-ssl=openssl > /dev/null
    make > /dev/null && make install > /dev/null
}

sysmbols_strip() {
	save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
				 libc.so.6
				 libthread_db.so.1
				 libquadmath.so.0.0.0
				 libstdc++.so.6.0.33
				 libitm.so.1.0.0
				 libatomic.so.1.2.0"

	cd /usr/lib

	for LIB in $save_usrlib; do
		objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
		cp $LIB /tmp/$LIB
		strip --strip-unneeded /tmp/$LIB
		objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
		install -vm755 /tmp/$LIB /usr/lib
		rm /tmp/$LIB
	done

	online_usrbin="bash find strip"
	online_usrlib="libbfd-2.42.so
				   libsframe.so.1.0.0
				   libhistory.so.8.2
				   libncursesw.so.6.5
				   libm.so.6
				   libreadline.so.8.2
				   libz.so.1.3.1
				   libzstd.so.1.5.6
				   $(cd /usr/lib; find libnss*.so* -type f)"

	for BIN in $online_usrbin; do
		cp /usr/bin/$BIN /tmp/$BIN
		strip --strip-unneeded /tmp/$BIN
		install -vm755 /tmp/$BIN /usr/bin
		rm /tmp/$BIN
	done

	for LIB in $online_usrlib; do
		cp /usr/lib/$LIB /tmp/$LIB
		strip --strip-unneeded /tmp/$LIB
		install -vm755 /tmp/$LIB /usr/lib
		rm /tmp/$LIB
	done

	for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
			 $(find /usr/lib -type f -name \*.a)                 \
			 $(find /usr/{bin,sbin,libexec} -type f); do
		case "$online_usrbin $online_usrlib $save_usrlib" in
			*$(basename $i)* )
				;;
			* ) strip --strip-unneeded $i
				;;
		esac
	done

	unset BIN LIB save_usrlib online_usrbin online_usrlib

	rm -rf /tmp/*
	find /usr/lib /usr/libexec -name \*.la -delete
	find /usr -depth -name $(uname -m)-nte-linux-gnu\* | xargs rm -rf
}