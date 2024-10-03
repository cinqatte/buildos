#!/bin/bash

build_m4() {
	cd $PI/sources/m4-1.4.19
	./configure \
		--prefix=/usr   \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_ncurses() {
	cd $PI/sources/ncurses-6.5
	sed -i s/mawk// configure
	mkdir -p build
	pushd build
		../configure > /dev/null
		make -C include > /dev/null
		make -C progs tic > /dev/null
	popd
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(./config.guess) \
		--mandir=/usr/share/man \
		--with-manpage-format=normal \
		--with-shared \
		--without-normal \
		--with-cxx-shared \
		--without-debug \
		--without-ada \
		--disable-stripping > /dev/null
	make > /dev/null && make DESTDIR=$PI TIC_PATH=$(pwd)/build/progs/tic install > /dev/null
	ln -s libncursesw.so $PI/usr/lib/libncurses.so
	sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $PI/usr/include/curses.h
}

build_bash() {
	cd $PI/sources/bash-5.2.21
	./configure \
		--prefix=/usr \
		--build=$(sh support/config.guess) \
		--host=$PI_TGT \
		--without-bash-malloc \
		bash_cv_strtold_broken=no > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
	ln -s bash $PI/bin/sh
}

build_coreutils() {
	cd $PI/sources/coreutils-9.5
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) \
		--enable-install-program=hostname \
		--enable-no-install-program=kill,uptime > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
	mv $PI/usr/bin/chroot $PI/usr/sbin
	mkdir -p $PI/usr/share/man/man8
	mv $PI/usr/share/man/man1/chroot.1 $PI/usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' $PI/usr/share/man/man8/chroot.8
}

build_diffutils() {
	cd $PI/sources/diffutils-3.10
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_file() {
	cd $PI/sources/file-5.45
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
		--host=$PI_TGT \
		--build=$(./config.guess) > /dev/null
	make FILE_COMPILE=$(pwd)/build/src/file > /dev/null && make DESTDIR=$PI install > /dev/null
	rm $PI/usr/lib/libmagic.la
}

build_findutils() {
	cd $PI/sources/findutils-4.10.0
	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_gawk() {
	cd $PI/sources/gawk-5.3.0
	sed -i 's/extras//' Makefile.in
	./configure \
		--prefix=/usr   \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_grep() {
	cd $PI/sources/grep-3.11
	./configure \
		--prefix=/usr   \
		--host=$PI_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_gzip() {
	cd $PI/sources/gzip-1.13
	./configure \
		--prefix=/usr   \
		--host=$PI_TGT > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_make() {
	cd $PI/sources/make-4.4.1
	./configure \
		--prefix=/usr \
		--without-guile \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_patch() {
	cd $PI/sources/patch-2.7.6
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_sed() {
	cd $PI/sources/sed-4.9
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_tar() {
	cd $PI/sources/tar-1.35
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
}

build_xz() {
	cd $PI/sources/xz-5.6.2
	./configure \
		--prefix=/usr \
		--host=$PI_TGT \
		--build=$(build-aux/config.guess) \
		--disable-static \
		--docdir=/usr/share/doc/xz-5.6.2 > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
	rm $PI/usr/lib/liblzma.la
}

build_binutils() {
	cd $PI/sources/binutils-2.42
	sed '6009s/$add_dir//' -i ltmain.sh
	mkdir build2 && cd build2
	../configure \
		--prefix=/usr \
		--build=$(../config.guess) \
		--host=$PI_TGT \
		--disable-nls \
		--enable-shared            \
		--enable-gprofng=no \
		--disable-werror \
		--enable-64-bit-bfd \
		--enable-default-hash-style=gnu > /dev/null
	make > /dev/null && make DESTDIR=$PI install > /dev/null
	rm $PI/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
}

build_gcc() {
	cd $PI/sources/gcc-14.1.0
	sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
	mkdir build3 && cd build3
	../configure \
		--build=$(../config.guess) \
		--host=$PI_TGT \
		--target=$PI_TGT \
		LDFLAGS_FOR_TARGET=-L$PWD/$PI_TGT/libgcc \
		--prefix=/usr \
		--with-build-sysroot=$PI \
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
	make > /dev/null && make DESTDIR=$PI install > /dev/null
	ln -s gcc $PI/usr/bin/cc
}

build_m4
build_ncurses
build_bash
build_coreutils
build_diffutils
build_file
build_findutils
build_gawk
build_grep
build_gzip
build_make
build_patch
build_sed
build_tar
build_xz
build_binutils
build_gcc
