#!/bin/bash

################################################################################################
################################################################################################

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y bash bc binutils bison build-essential coreutils diffutils \
	findutils flex gawk gcc g++ gettext grep gzip m4 make nano patch \
	perl python3 sed tar texinfo tree xz-utils zstd zip unzip
sudo apt-get autoremove -y


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

mkdir -p "$LOM_OS_HOME"/{boot,dev,etc,home,media,mnt,opt,run,srv,var/log}
mkdir -p "$LOM_OS_HOME"/usr/{bin,lib,lib64,sbin,include,local}
mkdir -p "$LOM_OS_HOME"/{tools,source}

install -d -m 0555 "$LOM_OS_HOME"/proc/
install -d -m 0700 "$LOM_OS_HOME"/root/
install -d -m 0555 "$LOM_OS_HOME"/sys/
install -d -m 1777 "$LOM_OS_HOME"/tmp/ "$LOM_OS_HOME"/var/tmp/

ln -s usr/bin "$LOM_OS_HOME"/bin
ln -s usr/lib "$LOM_OS_HOME"/lib
ln -s usr/lib64 "$LOM_OS_HOME"/lib64
ln -s usr/bin "$LOM_OS_HOME"/sbin

################################################################################################
################################################################################################

SOURCE_PACKAGES=(
	"https://ftp.gnu.org/gnu/glibc/glibc-2.39.tar.xz"
	"https://ftp.gnu.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.xz"
	"https://zlib.net/fossils/zlib-1.3.1.tar.gz"
	"https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.1.tar.xz"
	"https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz"
	"https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz"
	"https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz"
	"https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
	"https://ftp.gnu.org/gnu/gawk/gawk-5.3.0.tar.xz"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/bzip2-1.0.8-install_docs-1.patch"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/kbd-2.6.4-backspace-1.patch"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/glibc-2.39-fhs-1.patch"
	"https://libisl.sourceforge.io/isl-0.26.tar.xz"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/readline-8.2-upstream_fixes-3.patch"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/coreutils-9.4-i18n-1.patch"
	"https://www.linuxfromscratch.org/patches/lfs/12.1/bash-5.2.21-upstream_fixes-1.patch"
	"https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
	"https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz"
	"https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
	"https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz"
	"https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz"
	"https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz"
	"https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
	"https://ftp.gnu.org/gnu/bash/bash-5.2.21.tar.gz"
	"https://github.com/gavinhoward/bc/releases/download/6.7.5/bc-6.7.5.tar.xz"
	"https://cdn.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.47.1/e2fsprogs-1.47.1.tar.xz"
	"https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz"
	"https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.9.3.tar.xz"
	"https://www.cpan.org/src/5.0/perl-5.38.2.tar.gz"
	"https://github.com/besser82/libxcrypt/releases/download/v4.4.36/libxcrypt-4.4.36.tar.xz"
	"https://www.python.org/ftp/python/3.12.3/Python-3.12.3.tar.xz"
	"https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
	"https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz"
	"https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz"
)

for source_url in "${SOURCE_PACKAGES[@]}"; do
	wget "$source_url" --continue --no-verbose --quiet --directory-prefix="$LOM_OS_HOME"/source
done

cd "$LOM_OS_HOME"/source || exit 0
for source_package in *.tar.xz *.tar.gz; do
	if [[ "$source_package" == *.tar.xz ]]; then
		tar -xJf "$source_package"
	elif [[ "$source_package" == *.tar.gz ]]; then
		tar -xzf "$source_package"
	fi
done

################################################################################################
################################################################################################

cd "$LOM_OS_HOME"/source/binutils-2.42 || exit 0
mkdir -p build && cd build || exit 0
../configure \
	--prefix="$LOM_OS_HOME"/tools \
	--with-sysroot="$LOM_OS_HOME" \
	--target="$LOM_OS_TGT"   \
	--disable-nls \
	--enable-gprofng=no \
	--disable-werror \
	--silent \
	--quiet \
	--enable-default-hash-style=gnu
make > /dev/null && make install > /dev/null

cd "$LOM_OS_HOME"/source/gcc-14.1.0 || exit 0
tar xJf ../mpfr-4.2.1.tar.xz && mv mpfr-4.2.1 mpfr
tar xJf ../gmp-6.3.0.tar.xz && mv gmp-6.3.0 gmp
tar xzf ../mpc-1.3.1.tar.gz && mv mpc-1.3.1 mpc
tar xJf ../isl-0.26.tar.xz && mv isl-0.26 isl
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -p build && cd build || exit 0
../configure \
	--target="$LOM_OS_TGT" \
	--prefix="$LOM_OS_HOME"/tools \
	--with-glibc-version=2.39 \
	--with-sysroot="$LOM_OS_HOME" \
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
	--silent \
	--quiet \
	--enable-languages=c,c++
make > /dev/null && make install > /dev/null
cd ../ && cat gcc/limitx.h gcc/glimits.h gcc/limity.h > "$(dirname "$("$LOM_OS_TGT"-gcc -print-libgcc-file-name)")"/include/limits.h || exit 0

cd "$LOM_OS_HOME"/source/linux-6.9.3 || exit 0
make mrproper > /dev/null && make headers > /dev/null
find usr/include -type f ! -name '*.h' -delete
cp -r usr/include "$LOM_OS_HOME"/usr

cd "$LOM_OS_HOME"/source/glibc-2.39 || exit 0
ln -sf ../lib/ld-linux-x86-64.so.2 "$LOM_OS_HOME"/lib64
ln -sf ../lib/ld-linux-x86-64.so.2 "$LOM_OS_HOME"/lib64/ld-lsb-x86-64.so.3
patch -Np1 -i ../glibc-2.39-fhs-1.patch
mkdir -p build && cd build || exit 0
echo "rootsbindir=/usr/sbin" > configparms
../configure \
	--prefix=/usr \
	--host="$LOM_OS_TGT" \
	--build="$(../scripts/config.guess)" \
	--enable-kernel=4.19 \
	--with-headers="$LOM_OS_HOME"/usr/include \
	--disable-nscd \
	--silent \
	--quiet \
	libc_cv_slibdir=/usr/lib
make > /dev/null && make DESTDIR="$LOM_OS_HOME" install > /dev/null
sed '/RTLDLIST=/s@/usr@@g' -i "$LOM_OS_HOME"/usr/bin/ldd

cd "$LOM_OS_HOME"/source/gcc-14.1.0 || exit 0
mkdir -p build2 && cd build2 || exit 0
../libstdc++-v3/configure \
	--host="$LOM_OS_TGT" \
	--build="$(../config.guess)" \
	--prefix=/usr \
	--disable-multilib \
	--disable-nls \
	--disable-libstdcxx-pch \
	--silent \
	--quiet \
	--with-gxx-include-dir=/usr/"$LOM_OS_TGT"/include/c++/gcc-14.1.0
make > /dev/null
make DESTDIR="$LOM_OS_HOME" install > /dev/null
rm "$LOM_OS_HOME"/usr/lib/lib{stdc++{,exp,fs},supc++}.la