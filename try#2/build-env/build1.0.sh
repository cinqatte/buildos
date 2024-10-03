#!/bin/bash


################################################################################################
################################################################################################

download_work_srcpkgs() {
	srcpkgs_url=(
		"https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz"
		"https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.xz"
		"https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz"
		"https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz"
		"https://ftp.gnu.org/gnu/bash/bash-5.2.21.tar.gz"
		"https://www.linuxfromscratch.org/patches/lfs/12.1/bash-5.2.21-upstream_fixes-1.patch"
		"https://github.com/gavinhoward/bc/releases/download/6.7.5/bc-6.7.5.tar.xz"
		"https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz"
		"https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
		"https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
		"https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz"
		"https://www.linuxfromscratch.org/patches/lfs/development/coreutils-9.5-i18n-2.patch"
		"https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz"
		"https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.1/e2fsprogs-1.47.1.tar.gz"
		"https://sourceware.org/ftp/elfutils/0.191/elfutils-0.191.tar.bz2"
		"https://prdownloads.sourceforge.net/expat/expat-2.6.2.tar.xz"
		"https://astron.com/pub/file/file-5.45.tar.gz"
		"https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
		"https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz"
		"https://ftp.gnu.org/gnu/gawk/gawk-5.3.0.tar.xz"
		"https://ftp.gnu.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.xz"
		"https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.xz"
		"https://ftp.gnu.org/gnu/glibc/glibc-2.39.tar.xz"
		"https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.39-fhs-1.patch"
		"https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.39-upstream_fix-2.patch"
		"https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
		"https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz"
		"https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz"
		"https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz"
		"https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz"
		"https://github.com/Mic92/iana-etc/releases/download/20240502/iana-etc-20240502.tar.gz"
		"https://ftp.gnu.org/gnu/inetutils/inetutils-2.5.tar.xz"
		"https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz"
		"https://mirrors.edge.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.9.0.tar.xz"
		"https://mirrors.edge.kernel.org/pub/linux/utils/kbd/kbd-2.6.4.tar.xz"
		"https://www.linuxfromscratch.org/patches/lfs/12.1/kbd-2.6.4-backspace-1.patch"
		"https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kmod/kmod-32.tar.xz"
		"https://ftp.gnu.org/gnu/less/less-643.tar.gz"
		"https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.70.tar.xz"
		"https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz"
		"https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.gz"
		"https://github.com/besser82/libxcrypt/releases/download/v4.4.36/libxcrypt-4.4.36.tar.xz"
		"https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.9.3.tar.xz"
		"https://github.com/lz4/lz4/releases/download/v1.9.4/lz4-1.9.4.tar.gz"
		"https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz"
		"https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
		"https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
		"https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz"
		"https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz"
		"https://github.com/ninja-build/ninja/archive/v1.12.1/ninja-1.12.1.tar.gz"
		"https://www.openssl.org/source/openssl-3.3.1.tar.gz"
		"https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"
		"https://www.cpan.org/src/5.0/perl-5.38.2.tar.xz"
		"https://distfiles.ariadne.space/pkgconf/pkgconf-2.2.0.tar.xz"
		"https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.4.tar.xz"
		"https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz"
		"https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tar.xz"
		"https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz"
		"https://www.linuxfromscratch.org/patches/lfs/12.1/readline-8.2-upstream_fixes-3.patch"
		"https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz"
		"https://github.com/shadow-maint/shadow/releases/download/4.15.1/shadow-4.15.1.tar.xz"
		"https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz"
		"https://downloads.sourceforge.net/tcl/tcl8.6.14-src.tar.gz"
		"https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.xz"
		"https://www.iana.org/time-zones/repository/releases/tzdata2024a.tar.gz"
		"https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.1.tar.xz"
		"https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz"
		"https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz"
		"https://zlib.net/fossils/zlib-1.3.1.tar.gz"
		"https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz"
	)

	for srcpkg_url in "${srcpkgs_url[@]}"; do
		wget $srcpkg_url --directory-prefix=$NTE_HOME/source
	done
}

################################################################################################
################################################################################################

build_cross_tool_binutils() {
	cd $NTE_HOME/source
	tar -xJf binutils-2.42.tar.xz
	cd binutils-2.42
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
}

build_cross_tool_gcc() {
	cd $NTE_HOME/source
	tar -xJf gcc-14.1.0.tar.xz
	cd gcc-14.1.0
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
	cd ../
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($NTE_TGT-gcc -print-libgcc-file-name)`/include/limits.h
}

build_cross_tool_linux_header() {
	cd $NTE_HOME/source
	tar -xJf linux-6.9.3.tar.xz
	cd linux-6.9.3
	make mrproper > /dev/null
	make headers > /dev/null
	find usr/include -type f ! -name '*.h' -delete > /dev/null
	cp -r usr/include $NTE_HOME/usr
}

build_cross_tool_glibc() {
	cd $NTE_HOME/source
	tar -xJf glibc-2.39.tar.xz
	cd glibc-2.39
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
}

build_cross_tool_libstdc() {
	cd $NTE_HOME/source
	cd gcc-14.1.0
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

build_cross_tool() {
	build_cross_tool_binutils
	build_cross_tool_gcc
	build_cross_tool_linux_header
	build_cross_tool_glibc
	build_cross_tool_libstdc
}

################################################################################################
################################################################################################

build_cross_temp_tool_m4() {
	cd $NTE_HOME/source
	tar -xJf m4-1.4.19.tar.xz
	cd m4-1.4.19
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_ncurses() {
	cd $NTE_HOME/source
	tar -xzf ncurses-6.5.tar.gz
	cd ncurses-6.5
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
}

build_cross_temp_tool_bash() {
	cd $NTE_HOME/source
	tar -xzf bash-5.2.21.tar.gz
	cd bash-5.2.21
	./configure \
		--prefix=/usr \
		--build=$(sh support/config.guess) \
		--host=$NTE_TGT \
		--without-bash-malloc \
		bash_cv_strtold_broken=no > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	ln -s bash $NTE_HOME/bin/sh
}

build_cross_temp_tool_coreutils() {
	cd $NTE_HOME/source
	tar -xJf coreutils-9.5.tar.xz
	cd coreutils-9.5
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
}

build_cross_temp_tool_diffutils() {
	cd $NTE_HOME/source
	tar -xJf diffutils-3.10.tar.xz
	cd diffutils-3.10
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_file() {
	cd $NTE_HOME/source
	tar -xzf file-5.45.tar.gz
	cd file-5.45
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
}

build_cross_temp_tool_findutils() {
	cd $NTE_HOME/source
	tar -xJf findutils-4.10.0.tar.xz
	cd findutils-4.10.0
	./configure \
		--prefix=/usr \
		--localstatedir=/var/lib/locate \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_gawk() {
	cd $NTE_HOME/source
	tar -xJf gawk-5.3.0.tar.xz
	cd gawk-5.3.0
	sed -i 's/extras//' Makefile.in
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_grep() {
	cd $NTE_HOME/source
	tar -xJf grep-3.11.tar.xz
	cd grep-3.11
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_gzip() {
	cd $NTE_HOME/source
	tar -xJf gzip-1.13.tar.xz
	cd gzip-1.13
	./configure \
		--prefix=/usr   \
		--host=$NTE_TGT > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_make() {
	cd $NTE_HOME/source
	tar -xzf make-4.4.1.tar.gz
	cd make-4.4.1
	./configure \
		--prefix=/usr \
		--without-guile \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_patch() {
	cd $NTE_HOME/source
	tar -xJf patch-2.7.6.tar.xz
	cd patch-2.7.6
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_sed() {
	cd $NTE_HOME/source
	tar -xJf sed-4.9.tar.xz
	cd sed-4.9
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(./build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_tar() {
	cd $NTE_HOME/source
	tar -xJf tar-1.35.tar.xz
	cd tar-1.35
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
}

build_cross_temp_tool_xz() {
	cd $NTE_HOME/source
	tar -xJf xz-5.6.2.tar.xz
	cd xz-5.6.2
	./configure \
		--prefix=/usr \
		--host=$NTE_TGT \
		--build=$(build-aux/config.guess) \
		--disable-static \
		--docdir=/usr/share/doc/xz-5.6.2 > /dev/null
	make > /dev/null && make DESTDIR=$NTE_HOME install > /dev/null
	rm $NTE_HOME/usr/lib/liblzma.la
}

build_cross_temp_tool_binutils() {
	cd $NTE_HOME/source
	cd binutils-2.42
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
}

build_cross_temp_tool_gcc() {
	cd $NTE_HOME/source
	cd gcc-14.1.0
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

build_cross_temp_tool() {
	build_cross_temp_tool_m4
	build_cross_temp_tool_ncurses
	build_cross_temp_tool_bash
	build_cross_temp_tool_coreutils
	build_cross_temp_tool_diffutils
	build_cross_temp_tool_file
	build_cross_temp_tool_findutils
	build_cross_temp_tool_gawk
	build_cross_temp_tool_grep
	build_cross_temp_tool_gzip
	build_cross_temp_tool_make
	build_cross_temp_tool_patch
	build_cross_temp_tool_sed
	build_cross_temp_tool_tar
	build_cross_temp_tool_xz
	build_cross_temp_tool_binutils
	build_cross_temp_tool_gcc
}

################################################################################################
################################################################################################


build_phase_one() {
	setup_host_dep
	setup_work_env
	setup_work_dir
	download_work_srcpkgs
	build_cross_tool
	build_cross_temp_tool
}

build_phase_one
