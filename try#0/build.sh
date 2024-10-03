





setup_build_dependency() {
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y bash binutils bison coreutils diffutils findutils \
        gawk gcc g++ grep gzip m4 make patch perl python3 sed tar texinfo xz-utils \
        bzip2 zip unzip rar unrar bc build-essential tree libdebuginfod-dev \
        gettext
    sudo apt autoremove -y
    
    sudo rm -f /bin/sh
    sudo ln -s /bin/bash /bin/sh
}

setup_build_environment() {
    export OK_HOME=$HOME/ok
    export OK_TARGET=x86_64-ok-linux-gnu
    export MAKEFLAGS=-j$(nproc)
    export LC_ALL=POSIX
    export PATH=$OK_HOME/tools/bin:$PATH
    export CONFIG_SITE=$OK_HOME/usr/share/config.site
}

setup_build_directory() {
    mkdir -p $OK_HOME/{etc,var}
    mkdir -p $OK_HOME/usr/{bin,lib,sbin}
    mkdir -p $OK_HOME/{sources,tools}
    mkdir -p $OK_HOME/lib64
    for directory in bin lib sbin; do
        ln -s usr/$directory $OK_HOME/$directory
    done
}

setup_build() {
    setup_build_dependency
    setup_build_environment
    setup_build_directory
}

build_cross_toolchain_binutils() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.xz
    tar xJf binutils-2.43.tar.xz
    cd binutils-2.43
    
    mkdir -p build
    cd build
    
    ../configure \
        --prefix=$OK_HOME/tools \
        --with-sysroot=$OK_HOME \
        --target=$OK_TARGET \
        --disable-nls \
        --enable-gprofng=no \
        --disable-werror \
        --enable-new-dtags \
        --enable-default-hash-style=gnu > /dev/null
    
    make > /dev/null
    make install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf binutils-2.43
}

build_cross_toolchain_gcc() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
    tar xJf gcc-14.2.0.tar.xz
    cd gcc-14.2.0
    
    wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz
    wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
    wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
    
    tar xJf mpfr-4.2.1.tar.xz && mv mpfr-4.2.1 mpfr
    tar xJf gmp-6.3.0.tar.xz && mv gmp-6.3.0 gmp
    tar xzf mpc-1.3.1.tar.gz && mv mpc-1.3.1 mpc
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    mkdir -p build
    cd build
    
    ../configure \
        --target=$OK_TARGET \
        --prefix=$OK_HOME/tools \
        --with-glibc-version=2.40 \
        --with-sysroot=$OK_HOME \
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
    
    make > /dev/null
    make install > /dev/null
    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($OK_TARGET-gcc -print-libgcc-file-name)`/include/limits.h
    
    cd $OK_HOME/sources
    rm -rf gcc-14.2.0
}

build_cross_toolchain_linux_header() {
    cd $OK_HOME/sources
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.4.tar.xz
    tar xJf linux-6.10.4.tar.xz
    cd linux-6.10.4
    
    make mrproper > /dev/null
    make headers > /dev/null
    find usr/include -type f ! -name '*.h' -delete
    cp -r usr/include $OK_HOME/usr
    
    cd $OK_HOME/sources
    rm -rf linux-6.10.4
}

build_cross_toolchain_glibc() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/glibc/glibc-2.40.tar.xz
    tar xJf glibc-2.40.tar.xz
    cd glibc-2.40
    
    ln -sf ../lib/ld-linux-x86-64.so.2 $OK_HOME/lib64
    ln -sf ../lib/ld-linux-x86-64.so.2 $OK_HOME/lib64/ld-lsb-x86-64.so.3
    
    wget https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.40-fhs-1.patch
    patch -Np1 -i glibc-2.40-fhs-1.patch
    mkdir -p build
    cd build
    
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(../scripts/config.guess) \
        --enable-kernel=4.19 \
        --with-headers=$OK_HOME/usr/include \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    sed '/RTLDLIST=/s@/usr@@g' -i $OK_HOME/usr/bin/ldd
    
    echo 'int main(){}' | $OK_TARGET-gcc -xc -
    readelf -l a.out | grep ld-linux
    
    cd $OK_HOME/sources
    rm -rf glibc-2.40
}

build_cross_toolchain_libstdcpp() {
    cd $OK_HOME/sources
    tar xJf gcc-14.2.0.tar.xz
    cd gcc-14.2.0
    
    mkdir -p build
    cd build
    
    ../libstdc++-v3/configure \
        --host=$OK_TARGET \
        --build=$(../config.guess) \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --disable-libstdcxx-pch \
        --with-gxx-include-dir=/tools/$OK_TARGET/include/c++/14.2.0 > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    rm $OK_HOME/usr/lib/lib{stdc++{,exp,fs},supc++}.la
    
    cd $OK_HOME/sources
    rm -rf gcc-14.2.0
}

build_cross_toolchain_packages() {
    build_cross_toolchain_binutils
    build_cross_toolchain_gcc
    build_cross_toolchain_linux_header
    build_cross_toolchain_glibc
    build_cross_toolchain_libstdcpp
}

build_temporary_tool_m4() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
    tar xJf m4-1.4.19.tar.xz
    cd m4-1.4.19
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(build-aux/config.guess) > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf m4-1.4.19
}

build_temporary_tool_ncurses() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz
    tar xzf ncurses-6.5.tar.gz
    cd ncurses-6.5

    sed -i s/mawk// configure
    mkdir build
    pushd build
        ../configure > /dev/null
        make -C include > /dev/null
        make -C progs tic > /dev/null
    popd
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(./config.guess) \
        --mandir=/usr/share/man \
        --with-manpage-format=normal \
        --with-shared \
        --without-normal \
        --with-cxx-shared \
        --without-debug \
        --without-ada \
        --disable-stripping > /dev/null
        
    make > /dev/null
    make DESTDIR=$OK_HOME TIC_PATH=$(pwd)/build/progs/tic install > /dev/null
    ln -s libncursesw.so $OK_HOME/usr/lib/libncurses.so
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $OK_HOME/usr/include/curses.h
    
    cd $OK_HOME/sources
    rm -rf ncurses-6.5
}

build_temporary_tool_bash() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/bash/bash-5.2.32.tar.gz
    tar xzf bash-5.2.32.tar.gz
    cd bash-5.2.32
    
    ./configure \
        --prefix=/usr \
        --build=$(sh support/config.guess) \
        --host=$OK_TARGET \
        --without-bash-malloc \
        bash_cv_strtold_broken=no > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    ln -sf bash $OK_HOME/bin/sh
    
    cd $OK_HOME/sources
    rm -rf bash-5.2.32
}

build_temporary_tool_coreutils() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz
    tar xJf coreutils-9.5.tar.xz
    cd coreutils-9.5
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(build-aux/config.guess) \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    mv $OK_HOME/usr/bin/chroot $OK_HOME/usr/sbin
    mkdir -p $OK_HOME/usr/share/man/man8
    mv $OK_HOME/usr/share/man/man1/chroot.1 $OK_HOME/usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/' $OK_HOME/usr/share/man/man8/chroot.8
    
    cd $OK_HOME/sources
    rm -rf coreutils-9.5
}

build_temporary_tool_diffutils() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz
    tar xJf diffutils-3.10.tar.xz
    cd diffutils-3.10
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(./build-aux/config.guess) > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf diffutils-3.10
}

build_temporary_tool_file() {
    cd $OK_HOME/sources
    wget https://astron.com/pub/file/file-5.45.tar.gz
    tar xzf file-5.45.tar.gz
    cd file-5.45
    
    mkdir build
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
        --host=$OK_TARGET \
        --build=$(./config.guess) > /dev/null
    
    make FILE_COMPILE=$(pwd)/build/src/file > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    rm $OK_HOME/usr/lib/libmagic.la
    
    cd $OK_HOME/sources
    rm -rf file-5.45
}

build_temporary_tool_findutils() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz
    tar xJf findutils-4.10.0.tar.xz
    cd findutils-4.10.0
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --localstatedir=/var/lib/locate \
        --build=$(build-aux/config.guess) > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf findutils-4.10.0
}

build_temporary_tool_gawk() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/gawk/gawk-5.3.0.tar.xz
    tar xJf gawk-5.3.0.tar.xz
    cd gawk-5.3.0
    
    sed -i 's/extras//' Makefile.in
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(build-aux/config.guess) > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf gawk-5.3.0
}

build_temporary_tool_grep() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz
    tar xJf grep-3.11.tar.xz
    cd grep-3.11
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(build-aux/config.guess) > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf grep-3.11
}

build_temporary_tool_gzip() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz
    tar xJf gzip-1.13.tar.xz
    cd gzip-1.13
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf gzip-1.13
}

build_temporary_tool_make() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
    tar xzf make-4.4.1.tar.gz
    cd make-4.4.1
    
    ./configure \
        --prefix=/usr \
        --without-guile \
        --build=$(build-aux/config.guess) \
        --host=$OK_TARGET > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf make-4.4.1
}

build_temporary_tool_patch() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
    tar xJf patch-2.7.6.tar.xz
    cd patch-2.7.6
    
    ./configure \
        --prefix=/usr \
        --build=$(build-aux/config.guess) \
        --host=$OK_TARGET > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf patch-2.7.6
}

build_temporary_tool_sed() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
    tar xJf sed-4.9.tar.xz
    cd sed-4.9
    
    ./configure \
        --prefix=/usr \
        --build=$(build-aux/config.guess) \
        --host=$OK_TARGET > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf sed-4.9
}

build_temporary_tool_tar() {
    cd $OK_HOME/sources
    wget https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz
    tar xJf tar-1.35.tar.xz
    cd tar-1.35
    
    ./configure \
        --prefix=/usr \
        --build=$(build-aux/config.guess) \
        --host=$OK_TARGET > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    
    cd $OK_HOME/sources
    rm -rf tar-1.35
}

build_temporary_tool_xz() {
    cd $OK_HOME/sources
    wget https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
    tar xJf xz-5.6.2.tar.xz
    cd xz-5.6.2
    
    ./configure \
        --prefix=/usr \
        --host=$OK_TARGET \
        --build=$(build-aux/config.guess) \
        --disable-static \
        --docdir=/usr/share/doc/xz-5.6.2 > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    rm $OK_HOME/usr/lib/liblzma.la
    
    cd $OK_HOME/sources
    rm -rf xz-5.6.2
}

build_temporary_tool_binutils() {
    cd $OK_HOME/sources
    tar xJf binutils-2.43.tar.xz
    cd binutils-2.43
    
    sed '6009s/$add_dir//' -i ltmain.sh
    mkdir -p build
    cd build
    
    ../configure \
        --prefix=/usr \
        --build=$(../config.guess) \
        --host=$OK_TARGET \
        --disable-nls \
        --enable-shared \
        --enable-gprofng=no \
        --disable-werror \
        --enable-64-bit-bfd \
        --enable-new-dtags \
        --enable-default-hash-style=gnu > /dev/null
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    rm $OK_HOME/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
    
    cd $OK_HOME/sources
    rm -rf binutils-2.43
}

build_temporary_tool_gcc() {
    cd $OK_HOME/sources
    tar xJf gcc-14.2.0.tar.xz
    cd gcc-14.2.0
    
    wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz
    wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
    wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
    
    tar xJf mpfr-4.2.1.tar.xz && mv mpfr-4.2.1 mpfr
    tar xJf gmp-6.3.0.tar.xz && mv gmp-6.3.0 gmp
    tar xzf mpc-1.3.1.tar.gz && mv mpc-1.3.1 mpc
    
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
    mkdir -p build
    cd build
    
    ../configure \
        --build=$(../config.guess) \
        --host=$OK_TARGET \
        --target=$OK_TARGET \
        LDFLAGS_FOR_TARGET=-L$PWD/$OK_TARGET/libgcc \
        --prefix=/usr \
        --with-build-sysroot=$OK_HOME \
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
    
    make > /dev/null
    make DESTDIR=$OK_HOME install > /dev/null
    ln -s gcc $OK_HOME/usr/bin/cc
    
    cd $OK_HOME/sources
    rm -rf gcc-14.2.0
}

build_temporary_tool_packages() {
    build_temporary_tool_m4
    build_temporary_tool_ncurses
    build_temporary_tool_bash
    build_temporary_tool_coreutils
    build_temporary_tool_diffutils
    build_temporary_tool_file
    build_temporary_tool_findutils
    build_temporary_tool_gawk
    build_temporary_tool_grep
    build_temporary_tool_gzip
    build_temporary_tool_make
    build_temporary_tool_patch
    build_temporary_tool_sed
    build_temporary_tool_tar
    build_temporary_tool_xz
    build_temporary_tool_binutils
    build_temporary_tool_gcc
}

setup_build
build_cross_toolchain_packages
build_temporary_tool_packages


pacman install gcc glibc libstdc++ g++ m4 ncurses bash coreutils diffutils file findutils gawk grep gzip make patch sed tar xz binutils gettext perl python texinfo util-linux