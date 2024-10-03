#!/bin/bash

################################################################################################
################################################################################################

# shellcheck disable=SC2155
# shellcheck disable=SC2164
# shellcheck disable=SC2086
# shellcheck disable=SC2046
# shellcheck disable=SC2006
# shellcheck disable=SC2016

################################################################################################
################################################################################################

setup_host_dependencies() {
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install -y bash bc binutils bison build-essential coreutils diffutils \
		findutils flex gawk gcc g++ gettext grep gzip m4 make nano patch \
		perl python3 sed tar texinfo tree xz-utils
	sudo apt-get autoremove -y

	sudo rm -f /bin/sh
	sudo ln -s /bin/bash /bin/sh
}

setup_host_work_environment() {
	set +h
	umask 022

	export NTE_HOME=$HOME/nte
	export NTE_TGT=x86_64-nte-linux-gnu
	export LC_ALL=POSIX
	export MAKEFLAGS=-j$(nproc)
	export PATH=$NTE_HOME/tools/bin:$PATH
	export CONFIG_SITE=$NTE_HOME/usr/share/config.site
	export WORKDIR=$(pwd)
}

setup_target_work_directories() {
	mkdir -p $NTE_HOME/{etc,var}
	mkdir -p $NTE_HOME/usr/{bin,lib,lib64,sbin}
	mkdir -p $NTE_HOME/{tools,source}

	for directory in bin lib lib64 sbin; do
		ln -fs usr/$directory $NTE_HOME/$directory
	done
}

setup_target_source_packages() {
	cd $NTE_HOME/source/
	wget --input-file=$WORKDIR/source_package_urls.txt --continue
	for source_package_archive in *.tar.xz *.tar.gz; do
		if [[ $source_package_archive == *.tar.xz ]]; then
			tar -xJvf $source_package_archive
		elif [[ $source_package_archive == *.tar.gz ]]; then
			tar -xzvf $source_package_archive
		fi
	done
}

################################################################################################
################################################################################################

build_cross_toolchain() {
	# BUILD BINUTILS
	cd $NTE_HOME/source/binutils-2.42
	mkdir -p build && cd build
	../configure \
		--prefix=$NTE_HOME/tools \
		--with-sysroot=$NTE_HOME \
		--target=$NTE_TGT \
		--disable-nls \
		--enable-gprofng=no \
		--disable-werror \
		--enable-default-hash-style=gnu > /dev/null
	make > /dev/null && make install > /dev/null

	# BUILD GCC
	cd $NTE_HOME/source/gcc-14.1.0
	tar -xJf ../mpfr-4.2.1.tar.xz && mv mpfr-4.2.1 mpfr
	tar -xJf ../gmp-6.3.0.tar.xz && mv gmp-6.3.0 gmp
	tar -xzf ../mpc-1.3.1.tar.gz && mv mpc-1.3.1 mpc
	sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
	mkdir -p build && cd build
	../configure \
		--target=$NTE_TGT \
		--prefix=$NTE_HOME/tools \
		--with-glibc-version=2.39 \
		--with-sysroot=$NTE_HOME \
		--with-newlib \
		--without-headers \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-threads \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--enable-languages=c,c++ > /dev/null
	make > /dev/null && make install > /dev/null
	cd ../ && cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($NTE_TGT-gcc -print-libgcc-file-name)`/include/limits.h

	# BUILD LINUX HEADERS
	cd $NTE_HOME/source/linux-6.9.9
	make mrproper > /dev/null
	make headers > /dev/null
	find usr/include -type f ! -name '*.h' -delete > /dev/null
	cp -r usr/include $NTE_HOME/usr

	# BUILD GLIBC
	cd $NTE_HOME/source/glibc-2.39
	ln -sf ../lib/ld-linux-x86-64.so.2 $NTE_HOME/lib64
	ln -sf ../lib/ld-linux-x86-64.so.2 $NTE_HOME/lib64/ld-lsb-x86-64.so.3
	patch -Np1 -i ../glibc-2.39-fhs-1.patch
	mkdir -p build && cd build
	echo "rootsbindir=/usr/sbin" > configparms
	../configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(../scripts/config.guess) \
		--enable-kernel=4.19 \
		--with-headers=$NTE_HOME/usr/include \
		--disable-nscd \
		libc_cv_slibdir=/usr/lib > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	sed '/RTLDLIST=/s@/usr@@g' -i $NTE_HOME/usr/bin/ldd

	# BUILD LIBSTDC++
	cd $NTE_HOME/source/gcc-14.1.0
	mkdir -p build2 && cd build2
	../libstdc++-v3/configure \
		--host=$NTE_TGT \
		--build=$(../config.guess) \
		--prefix=/usr \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=/tools/$NTE_TGT/include/c++/14.1.0 > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	rm $NTE_HOME/usr/lib/lib{stdc++{,exp,fs},supc++}.la
}

build_cross_temporary_tools() {
	# BUILD M4
	cd $NTE_HOME/source/m4-1.4.19
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD NCURSES
	cd $NTE_HOME/source/ncurses-6.5
	sed -i s/mawk// configure
	mkdir -p build
	pushd build
		../configure > /dev/null
		make -C include > /dev/null
		make -C progs tic > /dev/null
	popd
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./config.guess) \
		--mandir=/usr/share/man \
		--with-manpage-format=normal \
		--with-shared \
		--without-normal \
		--with-cxx-shared \
		--without-debug \
		--without-ada \
		--disable-stripping > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME TIC_PATH=$(pwd)/build/progs/tic install > /dev/null
	ln -s libncursesw.so $NTE_HOME/usr/lib/libncurses.so
	sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $NTE_HOME/usr/include/curses.h

	# BUILD BASH
	cd $NTE_HOME/source/bash-5.2.21
	./configure \
		--prefix=/usr \
		--build=$(sh support/config.guess) \
		--host=$NTE_TGT \
		--without-bash-malloc \
		bash_cv_strtold_broken=no > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	ln -s bash $NTE_HOME/bin/sh

	# BUILD COREUTILS
	cd $NTE_HOME/source/coreutils-9.5
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) \
		--enable-install-program=hostname \
		--enable-no-install-program=kill,uptime > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	mv $NTE_HOME/usr/bin/chroot $NTE_HOME/usr/sbin
	mkdir -p $NTE_HOME/usr/share/man/man8
	mv $NTE_HOME/usr/share/man/man1/chroot.1 $NTE_HOME/usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' $NTE_HOME/usr/share/man/man8/chroot.8

	# BUILD DIFFUTILS
	cd $NTE_HOME/source/diffutils-3.10
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD FILE
	cd $NTE_HOME/source/file-5.45
	mkdir -p build
	pushd build
		../configure \
			--disable-bzlib \
			--disable-libseccomp \
			--disable-xzlib \
			--disable-zlib > /dev/null
		make > /dev/null
	popd
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./config.guess) > /dev/null
	make FILE_COMPILE=$(pwd)/build/src/file > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	rm $NTE_HOME/usr/lib/libmagic.la

	# BUILD FINDUTILS
	cd $NTE_HOME/source/findutils-4.10.0
	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD GAWK
	cd $NTE_HOME/source/gawk-5.3.0
	sed -i 's/extras//' Makefile.in
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD GREP
	cd $NTE_HOME/source/grep-3.11
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD GZIP
	cd $NTE_HOME/source/gzip-1.13
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD MAKE
	cd $NTE_HOME/source/make-4.4.1
	./configure \
		--prefix=/usr \
		--without-guile \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD PATCH
	cd $NTE_HOME/source/patch-2.7.6
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD SED
	cd $NTE_HOME/source/sed-4.9
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD TAR
	cd $NTE_HOME/source/tar-1.35
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null

	# BUILD XZ
	cd $NTE_HOME/source/xz-5.6.2
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) \
		--disable-static \
		--docdir=/usr/share/doc/xz-5.6.2 > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	rm $NTE_HOME/usr/lib/liblzma.la

	# BUILD BINUTILS
	cd $NTE_HOME/source/binutils-2.42
	sed '6009s/$add_dir//' -i ltmain.sh
	mkdir -p build2 && cd build2
	../configure \
		--prefix=/usr \
		--build=$(../config.guess) \
		--host=$NTE_TGT \
		--disable-nls \
		--enable-shared            \
		--enable-gprofng=no \
		--disable-werror \
		--enable-64-bit-bfd \
		--enable-default-hash-style=gnu > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	rm $NTE_HOME/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

	# BUILD GCC
	cd $NTE_HOME/source/gcc-14.1.0
	sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
	mkdir -p build3 && cd build3
	../configure \
		--build=$(../config.guess) \
		--host=$NTE_TGT \
		--target=$NTE_TGT \
		LDFLAGS_FOR_TARGET=-L$PWD/$NTE_TGT/libgcc \
		--prefix=/usr \
		--with-build-sysroot=$NTE_HOME \
		--enable-default-pie \
		--enable-default-ssp \
		--disable-nls \
		--disable-multilib \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libvtv \
		--enable-languages=c,c++ > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	ln -s gcc $NTE_HOME/usr/bin/cc
}

################################################################################################
################################################################################################

chroot_preparation() {
	# CHANGE OWNERSHIP
	sudo chown -R root:root $NTE_HOME/{usr,lib,lib64,var,etc,bin,sbin,tools}

	# PREPARE VIRTUAL FS
	mkdir -p $NTE_HOME/{dev,proc,sys,run}

	# Dedicated Mounts
	sudo mount -t devtmpfs devtmpfs $NTE_HOME/dev
	sudo mount -t devpts devpts -o gid=5,mode=0620 $NTE_HOME/dev/pts
	sudo mount -t proc proc $NTE_HOME/proc
	sudo mount -t sysfs sysfs $NTE_HOME/sys
	sudo mount -t tmpfs tmpfs $NTE_HOME/run

	if [ -h $NTE_HOME/dev/shm ]; then
		sudo install -d -m 1777 $NTE_HOME/dev/shm
	else
		sudo mount -t tmpfs -o nosuid,nodev tmpfs $NTE_HOME/dev/shm
	fi

	# ENTER
	sudo chroot "$NTE_HOME" /usr/bin/env -i \
		HOME=/root \
		TERM="$TERM" \
		PS1='\u:\w\$ ' \
		PATH=/usr/bin:/usr/sbin \
		MAKEFLAGS="-j$(nproc)" \
		/bin/bash --login

	# CLEAN UP (IMPORTANT!)
	sudo umount $NTE_HOME/{dev,proc,sys,run,dev/shm}
}

################################################################################################
################################################################################################

setup_host_dependencies
setup_host_work_environment
setup_target_work_directories
setup_target_source_packages
build_cross_toolchain
build_cross_temporary_tools
chroot_preparation


export DEBIE=/home/bu/WorkSpace/Projects/Programming/lo/debian

sudo mount -t devtmpfs devtmpfs $DEBIE/dev
sudo mount -t devpts devpts -o gid=5,mode=0620 $DEBIE/dev/pts
sudo mount -t proc proc $DEBIE/proc
sudo mount -t sysfs sysfs $DEBIE/sys
sudo mount -t tmpfs tmpfs $DEBIE/run

if [ -h $DEBIE/dev/shm ]; then
	sudo install -d -m 1777 $DEBIE/dev/shm
else
	sudo mount -t tmpfs -o nosuid,nodev tmpfs $DEBIE/dev/shm
fi

# ENTER
sudo chroot "$DEBIE" /usr/bin/env -i \
	HOME=/root \
	TERM="$TERM" \
	PS1='\u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin \
	MAKEFLAGS="-j$(nproc)" \
	/bin/bash --login


sudo umount $DEBIE/{dev,proc,sys,run,dev/shm}
