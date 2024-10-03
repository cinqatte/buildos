





















cd /source/shadow-4.15.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:' \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
    -i etc/login.defs
touch /usr/bin/passwd
./configure \
	--sysconfdir=/etc   \
	--disable-static    \
	--with-{b,yes}crypt \
	--without-libbsd    \
	--with-group-name-max-length=32 > /dev/null
make > /dev/null
make exec_prefix=/usr install > /dev/null
make -C man install-man > /dev/null
pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
cd /source
rm -rf shadow-4.15.1*

cd /source/gcc-14.1.0
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -v build && cd build
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
	--with-system-zlib > /dev/null
make > /dev/null && make install > /dev/null
ln -sr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/14.1.0/liblto_plugin.so /usr/lib/bfd-plugins/
mkdir -p /usr/share/gdb/auto-load/usr/lib
mv /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /source/
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
install -m755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -a dest/* /
for lib in ncurses form panel menu ; do
	ln -sf lib${lib}w.so /usr/lib/lib${lib}.so
	ln - ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
ln -sf libncursesw.so /usr/lib/libcurses.so
cp -R doc -T /usr/share/doc/ncurses-6.5
cd /source/
rm -rf ncurses-6.5*

cd /source/sed-4.9
./configure --prefix=/usr > /dev/null
make > /dev/null && make html > /dev/null
make install > /dev/null
install -d -m755 /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
cd /source
rm -rf sed-4.9*

cd /source/psmisc-23.7
./configure --prefix=/usr > /dev/null
make > /dev/null && make install > /dev/null
cd /source
rm -rf psmisc-23.7*

cd /source/gettext-0.22.5
./configure \
	--prefix=/usr \
	--disable-static \
	--docdir=/usr/share/doc/gettext-0.22.5 > /dev/null
make > /dev/null && make install > /dev/null
chmod 0755 /usr/lib/preloadable_libintl.so
cd /source
rm -rf gettext-0.22.5*

cd /source/bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2 > /dev/null
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
./configure \
	--prefix=/usr \
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
cd /source/
rm -rf libtool-2.4.7*

cd /source/gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1 > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf gperf-3.1*

cd /source/expat-2.6.2
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.2 > /dev/null
make > /dev/null && make install > /dev/null
install -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.2
cd /source/
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
cd /source/
rm -rf inetutils-2.5*

cd /source/less-643
./configure --prefix=/usr --sysconfdir=/etc > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf less-643*

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
cd /source/
rm -rf perl-5.38.2*

cd /source/XML-Parser-2.47
perl Makefile.PL > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf XML-Parser-2.47*

cd /source/intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr > /dev/null
make > /dev/null && make install > /dev/null
install -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd /source/
rm -rf intltool-0.51.0*

cd /source/autoconf-2.72
./configure --prefix=/usr > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf autoconf-2.72*

cd /source/automake-1.16.5
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5 > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf automake-1.16.5*

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
cd /source/
rm -rf openssl-3.3.1*

cd /source/kmod-32
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib > /dev/null
make > /dev/null && make install > /dev/null
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sf ../bin/kmod /usr/sbin/$target
  rm -f /usr/bin/$target
done
cd /source/
rm -rf kmod-32*

# failed
cd /source/elfutils-0.191
./configure --prefix=/usr \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy > /dev/null
make > /dev/null && make -C libelf install > /dev/null
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd /source/
rm -rf elfutils-0.191*

cd /source/libffi-3.4.6
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native > /dev/null
make > /dev/null && make install > /dev/null
cd /source/
rm -rf libffi-3.4.6*

cd /source/Python-3.12.4
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations > /dev/null
make > /dev/null && make install > /dev/null
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
cd /source/
rm -rf Python-3.12.4*