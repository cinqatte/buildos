#!/bin/bash




################################################################################################
################################################################################################

set +h
umask 022

MAKEFLAGS=-j"$(nproc)"
export MAKEFLAGS

export LOM_OS_HOME="$HOME"/lom
export LOM_OS_TGT="x86_64-lom-linux-gnu"
export LC_ALL=POSIX
export PATH="$LOM_OS_HOME"/tools/bin:"$PATH"
export CONFIG_SITE="$LOM_OS_HOME"/usr/share/config.site

################################################################################################
################################################################################################

lom_cd_dir() {
	cd "$LOM_OS_HOME"/source/"$1" || exit 0
}

lom_mkdir_cd() {
	mkdir -p "$1" && cd "$1" || exit 0
}

################################################################################################
################################################################################################

lom_cd_dir m4-1.4.19
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--silent \
	--quiet \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir ncurses-6.5
sed -i s/mawk// configure
mkdir -p build
pushd build || exit 0
	../configure \
		--silent \
		--quiet
	make -C include
	make -C progs tic
popd || exit 0
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--build="$(./config.guess)" \
	--mandir=/usr/share/man \
	--with-manpage-format=normal \
	--with-shared \
	--without-normal \
	--with-cxx-shared \
	--without-debug \
	--without-ada \
	--disable-stripping \
	--enable-widec \
	--silent \
	--quiet
make > /dev/null && make DESTDIR="$LOM_OS_HOME" TIC_PATH="$(pwd)"/build/progs/tic install > /dev/null
ln -sv libncursesw.so "$LOM_OS_HOME"/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LOM_OS_HOME"/usr/include/curses.h

lom_cd_dir bash-5.2.21
./configure \
	--prefix=/usr \
	--build="$(sh support/config.guess)" \
	--host="$LOM_OS_TGT" \
	--without-bash-malloc \
	--silent \
	--quiet \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
ln -s bash "$LOM_OS_HOME"/bin/sh

lom_cd_dir coreutils-9.5
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--build="$(build-aux/config.guess)" \
	--enable-install-program=hostname \
	--enable-no-install-program=kill,uptime \
	--silent \
	--quiet
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
mv "$LOM_OS_HOME"/usr/bin/chroot "$LOM_OS_HOME"/usr/sbin
mkdir -p "$LOM_OS_HOME"/usr/share/man/man8
mv "$LOM_OS_HOME"/usr/share/man/man1/chroot.1 "$LOM_OS_HOME"/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' "$LOM_OS_HOME"/usr/share/man/man8/chroot.8

lom_cd_dir diffutils-3.10
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(./build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir file-5.45
mkdir -p build
pushd build || exit 0
	../configure \
		--silent \
		--quiet \
		--disable-bzlib \
		--disable-libseccomp \
		--disable-xzlib \
		--disable-zlib
	  make > /dev/null
popd || exit 0
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(./config.guess)"
make FILE_COMPILE="$(pwd)"/build/src/file > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
rm "$LOM_OS_HOME"/usr/lib/libmagic.la

lom_cd_dir findutils-4.10.0
./configure \
	--prefix=/usr \
	--quiet \
	--silent \
	--localstatedir=/var/lib/locate \
	--host="$LOM_OS_TGT" \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir grep-3.11
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(./build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir gzip-1.13
./configure \
	--prefix=/usr \
	--quiet \
	--silent \
	--host="$LOM_OS_TGT"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir make-4.4.1
./configure \
	--prefix=/usr \
	--without-guile \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir patch-2.7.6
./configure \
	--prefix=/usr \
	--quiet \
	--silent \
	--host="$LOM_OS_TGT" \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir sed-4.9
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(./build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir tar-1.35
./configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--quiet \
	--silent \
	--build="$(build-aux/config.guess)"
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null

lom_cd_dir xz-5.4.6
./configure \
	--prefix=/usr \
	--quiet \
	--silent \
	--host="$LOM_OS_TGT" \
	--build="$(build-aux/config.guess)" \
	--disable-static \
	--docdir=/usr/share/doc/xz-5.4.6
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
rm "$LOM_OS_HOME"/usr/lib/liblzma.la


lom_cd_dir binutils-2.42
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -p build && cd build || exit 0
../configure \
		--prefix=/usr \
		--build="$(../config.guess)" \
		--host="$LOM_OS_TGT" \
		--disable-nls \
		--enable-shared \
		--quiet \
		--silent \
		--disable-werror \
		--enable-64-bit-bfd \
		--disable-bootstrap \
		--enable-default-hash-style=gnu
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
rm "$LOM_OS_HOME"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

lom_cd_dir gcc-14.1.0
sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -p build && cd build || exit 0
../configure \
	--build="$(../config.guess)" \
	--host="$LOM_OS_TGT" \
	--target="$LOM_OS_TGT" \
	LDFLAGS_FOR_TARGET=-L"$PWD"/"$LOM_OS_TGT"/libgcc \
	--prefix=/usr \
	--with-build-sysroot="$LOM_OS_HOME" \
	--enable-default-pie \
	--enable-default-ssp \
	--disable-nls \
	--disable-multilib \
	--disable-libatomic \
	--quiet \
	--silent \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-libvtv \
	--disable-bootstrap \
	--enable-languages=c,c++
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
ln -s gcc "$LOM_OS_HOME"/usr/bin/cc
