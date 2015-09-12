
#
# We need a new version of Make to handle this Makefile. Probably
# need to compile Make by hand so this will work or package install
# from somewhere else.
#
# The machine needs at least 1Gbyte of RAM or binutils will not
# pass the tests.
#
# texinfo needs a newer version of gzip to pass its tests
# texinfo is used by many programs to install the info files
#
# gettext needs a new librt, librt comes from glibc, glibc needs a kernel
# greater than 2.6.19
# gettext should follow xz
# we need to compile gettext then libiconv then gettext again
#
# If something complains about not having Thread Local Storage or TLS,
# the old glibc does not include this, try linking with pth.
#
# GlibC will compile, but its a real hassle to use it.
# * Need to set LD_LIBRARY_PATH to include /usr/local/glibc/lib.
# * Need to link against /usr/local/glibc/lib rather than /lib
# * Need to execute it with the loader /usr/local/glibc/lib/ld-linux.so.2
#    exe
# *  eg /usr/local/glibc/lib/ld-linux.so.2 /usr/local/bin/which
#
# Good repositories:
# https://ftp.gnu.org/pub/gnu/
# ftp://ftp.kernel.org/pub/linux/
#
#
# Configuration Variables
#
GCC_LANGS=c,c++,fortran,java,objc,obj-c++

#
# Function Defines
#
define LNBIN
	test -f /usr/bin/$1 || /usr/bin/sudo ln -s /usr/local/bin/$1 /usr/bin/.
endef

# call LNLIB libssp.a
define LNLIB
	test -f /lib/$1 || test -L /lib/$1 || /usr/bin/sudo ln -s /usr/local/lib/$1 /lib/.
endef

define MKVRFYDIR
	mkdir -p --verbose $1
	cd $1; readlink -f . | grep $1
endef

define SOURCEBASE
	$(call MKVRFYDIR,$1)
	cd $1; find . -maxdepth 1 -type d -name $1-\* -print -exec /bin/rm -rf {} \;
endef

# Old versions of tar may not handle all archives and may not dynamically detect
# how the archive is compressed. So we will try multiple ways and also see if
# we have a version in /usr/local/bin that can handle it.
define SOURCEDIR
	@echo "======================================"
	@echo "=======    Start $1"
	@echo "======================================"
	$(call SOURCEBASE,$1)
	echo ---###---
	cd $1; tar $2 $1*.tar* || tar $2 $1*.tgz || tar $2 $1*.tar || tar xf $1*.tar* || /usr/local/bin/tar xf $1*.tar* || unzip $1*.zip || unzip master.zip || ( mkdir $1; cd $1; tar xf ../master.tar.gz ) || test -d $1
	echo ---###---
	cd $1; /bin/rm -f untar.dir
	cd $1; find . -maxdepth 1 -type d -name $1\* -print > untar.dir
	cd $1/`cat $1/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
endef

define SOURCECLEAN
	$(call SOURCEBASE,$1)
	-cd $1; mkdir -p $$HOME/files/backups/oldpackages
	-cd $1; /bin/rm -f `basename $2`
	-cd $1; test ! -e $1-*.tar.gz || /bin/mv $1-*.tar.gz $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tgz || /bin/mv $1-*.t.gz $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tar.bz2 || /bin/mv $1-*.tar.bz2 $$HOME/files/backups/oldpackages/.
endef

define SOURCEWGET
	$(call SOURCECLEAN,$1,$2)
	cd $1; wget --no-check-certificate $2
endef

define SOURCEGIT
	$(call SOURCECLEAN,$1,$2)
	-cd $1; /bin/rm -rf `basename $2 .git`
	cd $1; git clone $2
endef

define PATCHWGET
	$(call MKVRFYDIR,patches)
	-cd patches; /bin/rm -f `basename $1`
	cd patches; wget --no-check-certificate $1
endef

define CPLIB
	cd /usr/local/lib; for FILE in $1; do if test -e /usr/local/lib/$$FILE ; then test -f /lib/$$FILE || test -L /lib/$$FILE || /usr/bin/sudo ln -s /usr/local/lib/$$FILE /lib/. ; fi ; done ; sudo /bin/rm -f /lib/*.scm /lib/*.py ; sudo /sbin/ldconfig
endef

define RENEXE
	cd /usr/local/bin; for FILE in $1; do if test -e /usr/local/bin/$$FILE; then export n=0; while test -e /usr/local/bin/$$FILE.old.$$n ; do export n=$$((n+1)); done ; sudo mv $$FILE $$FILE.old.$$n ; fi ; done
endef

define PKGFROMSTAGE
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/packaged
	/bin/mkdir -p packages
	cd $1/$2/; /usr/bin/sudo tar -C /tmp/$3 -czf /tmp/packaged/$1.tar.gz .
	/bin/rm -f packages/$1.tar.gz
	/bin/cp /tmp/packaged/$1.tar.gz packages
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
endef

define PKGINSTALLTO
	@echo "======= Start of $1 Successful ======="
	cd $1/$2/; /usr/bin/sudo make install
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/stage
	cd $1/$2/; /usr/bin/sudo make DESTDIR=/tmp/stage install
	$(call PKGFROMSTAGE,$1,$2,stage)
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	@echo "======= Install of $1 Successful ======="
endef

# Some packages do not have configure and depend on the PREFIX
# and DESTDIR variables to determine where they should install
define PKGINSTALLTOPREFIX
	@echo "======= Start of $1 Successful ======="
	cd $1/$2/; /usr/bin/sudo make PREFIX=/usr/local install
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/stage
	cd $1/$2/; /usr/bin/sudo make PREFIX=/usr/local DESTDIR=/tmp/stage install
	$(call PKGFROMSTAGE,$1,$2,stage)
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	@echo "======= Install of $1 Successful ======="
endef

define PKGINSTALL
	$(call PKGINSTALLTO,$1,`cat $1/untar.dir`)
endef

define PKGINSTALLPREFIX
	$(call PKGINSTALLTOPREFIX,$1,`cat $1/untar.dir`)
endef

define PKGINSTALLBUILD
	$(call PKGINSTALLTO,$1,$1-build)
endef

define PKGCHECKFROM
	@echo "=======    Start check of $1   ======="
	cd $1/$2/; make check || make test
	@echo "======= Check of $1 Successful ======="
endef

define PKGCHECK
	$(call PKGCHECKFROM,$1,`cat $1/untar.dir`)
endef

define PKGCHECKBUILD
	$(call PKGCHECKFROM,$1,$1-build)
endef

#
# NetPBM really wants to be configured interactively so we just
# define the answers in a HERE document and handle Makefile.config.in
# and Makefile.config by copying the answers into Makefile.config.
# The build instructions ask you to please not automate running configure.
#
define NETPBMCONFIG
####Lines above were copied from Makefile.config.in by 'configure'.
####Lines below were added by 'configure' based on the GNU platform.
DEFAULT_TARGET = nonmerge
NETPBMLIBTYPE=unixstatic
NETPBMLIBSUFFIX=a
STATICLIB_TOO=n
CFLAGS = -O3 -ffast-math  -pedantic -fno-common -Wall -Wno-uninitialized -Wmissing-declarations -Wimplicit -Wwrite-strings -Wmissing-prototypes -Wundef
CFLAGS_MERGE = -Wno-missing-declarations -Wno-missing-prototypes
LDRELOC = ld --reloc
LINKER_CAN_DO_EXPLICIT_LIBRARY=Y
LINKERISCOMPILER = Y
CFLAGS_SHLIB += -fPIC
TIFFLIB = libtiff.so
JPEGLIB = libjpeg.so
ZLIB = libz.so
X11LIB = /usr/X11R6/lib/libX11.so
NETPBM_DOCURL = http://netpbm.sourceforge.net/doc/
endef

#
# Here documents for CA certs
# 
define GITCONFIG
[http]
    sslCAinfo=/usr/local/etc/ssl/ca-bundle.crt
endef

.PHONY: all
all: phase1 aftergcc

# PHASE1, we want to build enough so we can get a modernish C/C++
# compiler.  Then go back and build everything that we have built
# with the new compiler before moving on to the rest of the
# packages. We know there are problems with compiling some of the
# newer packages with old versions of GCC, so we try to do just what
# we need to get a version of GCC built before we can redo what we
# have done to get GCC working and do the rest of the packages.
.PHONY: phase1
phase1: target_test target_dirs \
     nameservers \
     check_sudo scripts devices make zlib \
     gzip tar xz perl texinfo binutils \
     coreutils findutils diffutils which \
     symlinks m4 ecj gmp mpfr mpc libelf \
     flex gawk libtool sed \
     bzip sqlite zip unzip \
     autoconf \
     libunistring \
     libatomic_ops gc \
     libffi guile gcc

# db needs C++
# lzma needs C++
.PHONY: aftergcc
aftergcc: pcre grep db lzma gdbm gettext libiconv gettext \
     Python afterpython

# run ca-cert twice. The shell scripts are sloppy. They want to
# manipulate the previously installed certs

# took out Net-SSLeay
#     Net-SSLeay IO-Socket-SSL 

.PHONY: afterpython
afterpython: ca-cert ca-cert openssl \
     Archive-Zip Digest-SHA1 Scalar-MoreUtils \
     URI HTML-Tagset HTML-Parser \
     Devel-Symdump Pod-Coverage Test-Pod Test-Pod-Coverage \
     libwww-perl \
     bison afterbison

# lua needs ncurses
.PHONY: afterbison
afterbison: autogen tcl tclx \
     expect dejagnu wget libgpg-error libgcrypt libassuan libksba \
     pth gnupg \
     bash expat apr apr-util \
     pkg-config glib ncurses lua ruby vim aftervim

.PHONY: aftervim
aftervim: cppcheck libpcap \
    jnettop scrypt bcrypt \
    nettle libtasn1 \
    gnutls \
    curl wipe srm util-linux-ng libxml2 afterlibxml2

.PHONY: afterlibxml2
afterlibxml2: libarchive lzo \
    cmake \
    fuse ntfs-3g check file \
    scons afterscons

.PHONY: afterscons
afterscons: serf protobuf mosh \
    llvm socat screen libevent tmux autossh inetutils \
    swig httpd subversion git \
    psmisc tcp_wrappers doxygen icu aftericu

# Need to do harfbuzz, then freetype, the harfbuzz again
.PHONY: aftericu
aftericu: harfbuzz libpng freetype-nohb harfbuzz freetype \
    afterfreetype

.PHONY: afterfreetype
afterfreetype: \
    check_sudo \
    fontconfig \
    htop \
    multitail \
    p7zip \
    include-what-you-use \
    popt \
    sharutils \
    aftersharutils

.PHONY: aftersharutils
aftersharutils: \
    hashdeep \
    gdb \
    par2cmdline \
    iptraf-ng \
    hwloc \
    e2fsprogs \
    go \
    pixman \
    cairo \
    glibc \
    automake truecrypt

# ==============================================================
# Versions
# ==============================================================
acl-ver            = acl/acl-2.2.52.src.tar.gz
apr-util-ver       = apr-util/apr-util-1.5.3.tar.bz2
apr-ver            = apr/apr-1.4.8.tar.bz2
attr-ver           = attr/attr-2.4.47.src.tar.gz
autoconf-ver       = autoconf/autoconf-2.69.tar.xz
automake-ver       = automake/automake-1.14.tar.xz
autossh-ver        = autossh/autossh-1.4c.tgz
bash-ver           = bash/bash-4.3.tar.gz
bcrypt-ver         = bcrypt/bcrypt-1.1.tar.gz
binutils-ver       = binutils/binutils-2.24.tar.gz
ca-cert-ver        = ca-cert/ca-cert-1.0
cairo-ver          = cairo/cairo-1.14.2.tar.xz
check-ver          = check/check-0.9.12.tar.gz
clang-ver          = clang/clang-3.4.src.tar.gz
clisp-ver          = clisp/clisp-2.49.tar.gz
cmake-ver          = cmake/cmake-3.1.2.tar.gz
compiler-rt-ver    = compiler-rt/compiler-rt-3.4.src.tar.gz
coreutils-ver      = coreutils/coreutils-8.22.tar.xz
cppcheck-ver       = cppcheck/cppcheck-1.65.tar.bz2
curl-ver           = curl/curl-7.41.0.tar.bz2
dejagnu-ver        = dejagnu/dejagnu-1.5.2.tar.gz
Devel-Symdump      = Devel-Symdump/Devel-Symdump-2.14.tar.gz
diffutils-ver      = diffutils/diffutils-3.3.tar.xz
doxygen-ver        = doxygen/doxygen-1.8.9.1.src.tar.gz
e2fsprogs-ver      = e2fsprogs/master.zip
ecj-ver            = ecj/ecj-latest.jar
expect-ver         = expect/expect5.45.tar.gz
file-ver           = file/file-5.17.tar.gz
findutils-ver      = findutils/findutils-4.4.2.tar.gz
fontconfig-ver     = fontconfig/fontconfig-2.11.1.tar.bz2
freetype-ver       = freetype/freetype-2.5.5.tar.bz2
fuse-ver           = fuse/fuse-2.9.3.tar.gz
gawk-ver           = gawk/gawk-4.1.1.tar.gz
gc-ver             = gc/gc-7.4.2.tar.gz
gcc-ver            = gcc/gcc-4.7.3.tar.bz2
gdb-ver            = gdb/gdb-7.9.tar.xz
gdbm-ver           = gdbm/gdbm-1.10.tar.gz
gettext-ver        = gettext/gettext-0.19.4.tar.gz
git-ver            = git/git-2.2.1.tar.xz
glib-ver           = glib/glib-2.42.1.tar.xz
glibc-ver          = glibc/glibc-2.21.tar.gz
gmp-ver            = gmp/gmp-4.3.2.tar.bz2
go-ver             = go/go1.4.2.src.tar.gz
gnupg-ver          = gnupg/gnupg-2.0.26.tar.bz2
gnutls-ver         = gnutls/gnutls-3.3.13.tar.xz
grep-ver           = grep/grep-2.15.tar.xz
guile-ver          = guile/guile-2.0.11.tar.xz
gzip-ver           = gzip/gzip-1.6.tar.gz
harfbuzz-ver       = harfbuzz/harfbuzz-0.9.38.tar.bz2
hashdeep-ver       = hashdeep/master.zip
htop-ver           = htop/htop-1.0.1.tar.gz
httpd-ver          = httpd/httpd-2.4.12.tar.bz2
hwloc-ver          = hwloc/hwloc-1.11.0.tar.gz
icu-ver            = icu/icu4c-54_1-src.tgz
inetutils-ver      = inetutils/inetutils-1.9.tar.gz
IO-Socket-SSL-ver  = IO-Socket-SSL/IO-Socket-SSL-2.012.tar.gz
iptraf-ng-ver      = iptraf-ng/iptraf-ng-1.1.4.tar.gz
iwyu-ver           = include-what-you-use/include-what-you-use-3.4.src.tar.gz
jnettop-ver        = jnettop/jnettop-0.13.0.tar.gz
libarchive-ver     = libarchive/libarchive-3.1.2.tar.gz
libassuan-ver      = libassuan/libassuan-2.2.0.tar.bz2
libatomic_ops-ver  = libatomic_ops/libatomic_ops-7.4.2.tar.gz
libevent-ver       = libevent/libevent-2.0.21-stable.tar.gz
libffi-ver         = libffi/libffi-3.2.1.tar.gz
libgcrypt-ver      = libgcrypt/libgcrypt-1.6.2.tar.bz2
libgpg-error-ver   = libgpg-error/libgpg-error-1.18.tar.bz2
libiconv-ver       = libiconv/libiconv-1.14.tar.gz
libksba-ver        = libksba/libksba-1.3.2.tar.bz2
libpcap-ver        = libpcap/libpcap-1.4.0.tar.gz
libpng-ver         = libpng/libpng-1.6.16.tar.xz
libtasn1-ver       = libtasn1/libtasn1-4.2.tar.gz
libunistring-ver   = libunistring/libunistring-0.9.5.tar.xz
libusb-ver         = libusb/libusb-1.0.19.tar.bz2
llvm-ver           = llvm/llvm-3.4.src.tar.gz
lua-ver            = lua/lua-5.3.0.tar.gz
lzo-ver            = lzo/lzo-2.08.tar.gz
make-ver           = make/make-4.1.tar.gz
m4-ver             = m4/m4-1.4.17.tar.gz
mosh-ver           = mosh/mosh-1.2.4.tar.gz
mpc-ver            = mpc/mpc-0.8.1.tar.gz
mpfr-ver           = mpfr/mpfr-2.4.2.tar.gz
multitail-ver      = multitail/multitail-6.4.1.tgz
netpbm-ver         = netpbm/netpbm-10.35.95.tgz
nettle-ver         = nettle/nettle-2.7.1.tar.gz
ntfs-3g-ver        = ntfs-3g/ntfs-3g_ntfsprogs-2013.1.13.tgz
openssl-ver        = openssl/openssl-1.0.2.tar.gz
par2cmdline-ver    = par2cmdline/master.zip
pcre-ver           = pcre/pcre-8.36.tar.bz2
perl-ver           = perl/perl-5.22.0.tar.gz
pixman-ver         = pixman/pixman-0.32.6.tar.gz
popt-ver           = popt/popt-1.16.tar.gz
protobuf-ver       = protobuf/protobuf-2.5.0.tar.bz2
psmisc-ver         = psmisc/psmisc-22.21.tar.gz
pth-ver            = pth/pth-2.0.7.tar.gz
Python-ver         = Python/Python-2.7.9.tar.xz
p7zip-ver          = p7zip/p7zip_9.38.1_src_all.tar.bz2
scons-ver          = scons/scons-2.3.4.tar.gz
screen-ver         = screen/screen-4.2.1.tar.gz
scrypt-ver         = scrypt/scrypt-1.1.6.tgz
sed-ver            = sed/sed-4.2.2.tar.gz
serf-ver           = serf/serf-1.3.5.tar.bz2
sharutils-ver      = sharutils/sharutils-4.15.1.tar.xz
socat-ver          = socat/socat-1.7.2.2.tar.bz2
sparse-ver         = sparse/sparse-0.5.0.tar.gz
srm-ver            = srm/srm-1.2.13.tar.gz
subversion-ver     = subversion/subversion-1.8.9.tar.bz2
swig-ver           = swig/swig-3.0.0.tar.gz
symlinks-ver       = symlinks/symlinks-1.4.tar.gz
tar-ver            = tar/tar-1.28.tar.gz
tcl-ver            = tcl/tcl8.6.3-src.tar.gz
tcp_wrappers-ver   = tcp_wrappers/tcp_wrappers_7.6.tar.gz
tcpdump-ver        = tcpdump/tcpdump-4.5.1.tar.gz
texinfo-ver        = texinfo/texinfo-5.2.tar.gz
tmux-ver           = tmux/tmux-1.9a.tar.gz
truecrypt-ver      = truecrypt/truecrypt-7.1a-linux-console-x86.tar.gz
unzip-ver          = unzip/unzip60.tar.gz
util-linux-ver     = util-linux/util-linux-2.24.tar.gz
util-linux-ng-ver  = util-linux-ng/util-linux-ng-2.18.tar.xz
vim-ver            = vim/vim-7.4.tar.bz2
which-ver          = which/which-2.20.tar.gz
wipe-ver           = wipe/wipe-2.3.1.tar.bz2
xz-ver             = xz/xz-5.0.5.tar.gz
zip-ver            = zip/zip30.tar.gz
zlib-ver           = zlib/zlib-1.2.8.tar.gz

# ==============================================================
# Individual Targets
# ==============================================================

.PHONY: target_test
target_test:
	/bin/echo $$LD_LIBRARY_PATH

.PHONY: target_dirs
target_dirs:
	sudo mkdir -p /usr/local/bin
	sudo mkdir -p /usr/local/etc
	sudo mkdir -p /usr/local/lib
	sudo mkdir -p /usr/local/lib64
	sudo mkdir -p /usr/local/share/man
	sudo mkdir -p /usr/local/share/man/man1
	sudo mkdir -p /usr/local/share/man/man2
	sudo mkdir -p /usr/local/share/man/man3
	sudo mkdir -p /usr/local/share/man/man4
	sudo mkdir -p /usr/local/share/man/man5
	sudo mkdir -p /usr/local/share/man/man6
	sudo mkdir -p /usr/local/share/man/man7
	sudo mkdir -p /usr/local/share/man/man8
	sudo mkdir -p /usr/local/share/man/mann
	sudo mkdir -p /usr/local/share/man/web
	sudo mkdir -p /usr/local/sbin
	test -e /usr/local/man || sudo ln -s /usr/local/share/man /usr/local/man

# These will mess themselves up in the build process when they try to install, because
# the shared libraries are being used for the install
# Use the stock compiler to install them into /usr/local
oldcompiler: check_sudo nameservers attr acl

.PHONY: foo
foo:
	echo -- $(PHASE1_NOCHECK)
	echo -- $(GCC_LANGS)
	echo -- $(shell perl -e '$$b = "$(grep-ver)"; $$b =~ s/-\d+\.\d.*//; print $$b')
	echo -- $(shell perl -e 'print map{s/-\d+\.\d.*//;$$_}($$a="$(grep-ver)")')
	true

.PHONY: bundle-scripts
bundle-scripts:
	mkdir -p scripts
	cd scripts; mkdir -p scripts-1.0
	cd scripts; tar cfz scripts-1.0.tar.gz ./scripts-1.0

.PHONY: scripts
scripts:
	mkdir -p scripts
	cd scripts; tar xfz scripts-1.0.tar.gz
	cd scripts/scripts-1.0; chmod a+x *
	cd scripts/scripts-1.0; sudo cp * /usr/local/bin/.

.PHONY: devices
devices:
	cd /dev; test -c /dev/random || sudo /sbin/MAKEDEV random
	cd /dev; test -c /dev/urandom || sudo /sbin/MAKEDEV urandom

.PHONY: nameservers
nameservers:
	egrep 8.8.8.8 /etc/resolv.conf || sudo bash -c "echo nameserver 8.8.8.8 >> /etc/resolv.conf"
	egrep 8.8.4.4 /etc/resolv.conf || sudo bash -c "echo nameserver 8.8.4.4 >> /etc/resolv.conf"

.PHONY: check_sudo
.PHONY: sudo
check_sudo sudo:
	/usr/bin/sudo echo sudo check

# Standard build with separate build directory
# make check is automatically built by automake
# so we will try that target first
.PHONY: gawk
.PHONY: m4
.PHONY: sed
.PHONY: tar
.PHONY: xz
gawk m4 sed xz tar: $(xz-ver) $(gawk-ver) $(m4-ver) $(sed-ver) $(tar-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build in the source directory
#
# We need to build gettext, then iconv, then gettext again
# The second time we build it, the tests will work, so
# we check for the presence of gettext in /usr/local/bin
# before we try to run the tests
#
.PHONY: scrypt gettext
gettext scrypt: $(gettext-ver) $(scrypt-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, we should have a good version of tar that automatically detects file type
.PHONY: apr
.PHONY: automake
.PHONY: findutils
.PHONY: gdbm
.PHONY: grep
.PHONY: libassuan
.PHONY: libgcrypt
.PHONY: libgpg-error
.PHONY: libksba
.PHONY: libpng
.PHONY: which
apr automake findutils gdbm grep libgcrypt libgpg-error libassuan libksba libpng which: $(which-ver) $(libpng-ver) $(libgpg-error-ver) $(libassuan-ver) $(libgcrypt-ver) $(libksba-ver) $(grep-ver) $(apr-ver) $(automake-ver) $(gdbm-ver) $(findutils-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, we should have a good version of tar that
# automatically detects file type
# For phase1, we will skip tests
# skip tests for autoconf, we may not have Fortran in PHASE1
# skip tests for libffi, we may not have a C++ compiler in PHASE1
# skip tests for texinfo needs a newer version of gzip to pass
# its tests, it may fail in tests phase1
.PHONY: autoconf
.PHONY: libffi
.PHONY: texinfo
autoconf libffi texinfo: $(autoconf-ver) $(libffi-ver) $(texinfo-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory
.PHONY: jnettop libxml2 check file protobuf libarchive libunistring lzo gnupg nettle popt sharutils pixman
jnettop libxml2 check file protobuf libarchive libtasn1 libunistring lzo gnupg nettle popt sharutils pixman: $(gnupg-ver) $(nettle-ver) $(libtasn1-ver) $(libunistring-ver) $(libarchive-ver) $(lzo-ver) $(check-ver) $(file-ver) $(protobuf-ver) $(popt-ver) $(sharutils-ver) $(pixman-ver) $(jnettop-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local LDFLAGS="-lpthreads"
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory, full automake build
.PHONY: par2cmdline
par2cmdline: $(par2cmdline-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; aclocal
	cd $@/`cat $@/untar.dir`/; automake --add-missing
	cd $@/`cat $@/untar.dir`/; autoconf
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory, no make check || make test, no test, no check
# we should have a good version of tar that automatically detects file type
.PHONY: mosh srm wipe socat screen tmux psmisc libusb htop cairo iptraf-ng hwloc
srm wipe mosh socat screen tmux psmisc libusb htop cairo iptraf-ng hwloc: $(srm-ver) $(libusb-ver) $(htop-ver) $(mosh-ver) $(socat-ver) $(screen-ver) $(tmux-ver) $(psmisc-ver) $(wipe-ver) $(cairo-ver) $(iptraf-ng-ver) $(hwloc-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No make check || make test, no test
# bison fails the glibc version test, we have too old of a GLIBC
# lmza fails the glibc version test, we have too old of a GLIBC
# libunistring fails one test of 418, that appears to be because we are linking to an old librt in GLIBC
# libpcap does not appear to have any tests
# tcpdump fails on PPOE
.PHONY: autogen
.PHONY: bison
.PHONY: libpcap
.PHONY: lzma
.PHONY: make
.PHONY: sqlite
.PHONY: tcpdump
make libpcap sqlite lzma bison autogen tcpdump: $(make-ver) $(libpcap-ver) $(tcpdump-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No configure and no make check || make test
.PHONY: bcrypt
.PHONY: bzip
.PHONY: symlinks
.PHONY: multitail
bcrypt bzip multitail symlinks: $(bcrypt-ver) $(multitail-ver) $(symlinks-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Perl Rule
.PHONY: Archive-Zip
.PHONY: Devel-Symdump
.PHONY: Digest-SHA1
.PHONY: HTML-Parser
.PHONY: HTML-Tagset
.PHONY: IO-Socket-SSL
.PHONY: Pod-Coverage
.PHONY: Scalar-MoreUtils
.PHONY: Test-Pod
.PHONY: Test-Pod-Coverage
.PHONY: URI
.PHONY: libwww-perl
Archive-Zip Digest-SHA1 Scalar-MoreUtils URI HTML-Tagset HTML-Parser IO-Socket-SSL Devel-Symdump Pod-Coverage Test-Pod Test-Pod-Coverage libwww-perl: $(Devel-Symdump-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; perl Makefile.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include'
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make test || make check
	$(call PKGINSTALL,$@)

# Perl Rule, no test
# Net-SSLeay seems to be failing because of thread problems
# PERL_MM_USE_DEFAULT=1 is the way to answer 'no' to 
# Makefile.PL for external tests question.
.PHONY: Net-SSLeay
Net-SSLeay:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; PERL_MM_USE_DEFAULT=1 perl Makefile.PL
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

# Begin special cases

.PHONY: acl
acl: $(acl-ver)
	# remove the old shared library, in case its in use
	# this will keep things from crashing, the running
	# process will keep the unlinked file open
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libacl.so \
	    /usr/local/lib/libacl.so.1 /usr/local/lib/libacl.so.1.1.0
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; INSTALL_USER=root INSTALL_GROUP=root ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install install-dev install-lib
	$(call CPLIB,lib$@*)
	@echo "======= Build of $@ Successful ======="

.PHONY: apr-util
apr-util: $(apr-util-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local \
	    --with-apr=/usr/local --with-gdbm=/usr/local --with-openssl=/usr/local \
	    --with-crypto
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call LNBIN,apr-1-config)
	$(call LNBIN,apu-1-config)
	$(call CPLIB,lib$@*)

# Need to do attr with the old tools or it gets messed up trying to replace itself
.PHONY: attr
attr: $(attr-ver)
	# remove the old shared library, in case its in use
	# this will keep things from crashing, the running
	# process will keep the unlinked file open
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libattr.so \
	    /usr/local/lib/libattr.so.1 /usr/local/lib/libattr.so.1.1.0
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; INSTALL_USER=root INSTALL_GROUP=root ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install install-dev install-lib
	/usr/bin/sudo /bin/rm -f /lib/libattr.la
	$(call CPLIB,lib$@*)
	@echo "======= Build of $@ Successful ======="

.PHONY: autossh
autossh: $(autossh-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# autossh may be in use
	$(call RENEXE,autossh)
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: bash
bash: $(bash-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --bindir=/usr/local/bin --htmldir=/usr/local/share/doc/bash --without-bash-malloc
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: ca-cert
ca-cert: $(ca-cert-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /bin/rm -f make-cert.pl
	cd $@/`cat $@/untar.dir`/; cp ../../scripts/scripts-1.0/make-cert.pl .
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./make-cert.pl
	cd $@/`cat $@/untar.dir`/; cp ../../scripts/scripts-1.0/make-ca.sh .
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./make-ca.sh
	cd $@/`cat $@/untar.dir`/; cp ../../scripts/scripts-1.0/remove-expired-certs.sh .
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./remove-expired-certs.sh
	cd $@/`cat $@/untar.dir`/; ./make-ca.sh
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./remove-expired-certs.sh
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -d /usr/local/etc/ssl/certs
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -v certs/*.pem /usr/local/etc/ssl/certs
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo c_rehash
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install BLFS-ca-bundle*.crt /usr/local/etc/ssl/ca-bundle.crt
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /bin/rm -f /usr/local/etc/ssl/certs/ca-certificates.crt
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ln -s /usr/local/etc/ssl/ca-bundle.crt /usr/local/etc/ssl/certs/ca-certificates.crt

# cmake tests fail on not having GTK2
.PHONY: cmake
cmake: $(cmake-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./bootstrap --prefix=/usr/local --system-libs --mandir=/usr/local/share/man --docdir=/usr/local/share/doc/cmake-3.1.2
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; bin/ctest -j2 -O ../cmake-3.1.2-test.log
	$(call PKGINSTALL,$@)

.PHONY: curl
curl: $(curl-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Berkeley DB
.PHONY: db
db:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/build_unix; readlink -f . | grep `cat ../../untar.dir`
	cd $@/`cat $@/untar.dir`/build_unix; ../dist/configure --enable-compat185 --enable-dbm --enable-cxx
	cd $@/`cat $@/untar.dir`/build_unix; make
	cd $@/`cat $@/untar.dir`/build_unix; sudo make install
	@echo "======= Build of $@ Successful ======="

# binutils check needs more memory
.PHONY: binutils
binutils: $(binutils-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	# cd $@; sed -i -e 's/@colophon/@@colophon/' -e 's/doc@cygnus.com/doc@@cygnus.com/' `cat untar.dir`/bfd/doc/bfd.texinfo
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; exec make check
	$(call PKGINSTALLBUILD,$@)

.PHONY: clisp
clisp: $(clisp-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --ignore-absence-of-libsigsegv
	cd $@/`cat $@/untar.dir`/src; make
	-cd $@/`cat $@/untar.dir`/src; make check || make test
	$(call PKGINSTALLTO,$@,`cat $@/untar.dir`/src)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: coreutils
coreutils: $(coreutils-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --enable-install-program=hostname
	cd $@/$@-build/; make
	# Timeout test failed, I think it is the same forking pthread librt
	# problem I am getting in other tests
	@echo "======= One test will fail ======="
	-cd $@/$@-build/; make RUN_EXPENSIVE_TESTS=yes check
	@echo "======= One test will fail ======="
	$(call PKGINSTALLBUILD,$@)

.PHONY: cppcheck
cppcheck: $(cppcheck-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make HAVE_RULES=yes
	$(call PKGINSTALL,$@)

.PHONY: dejagnu
dejagnu: $(dejagnu-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; mkdir dejagnu
	-cd $@/`cat $@/untar.dir`/; sudo mkdir -p /usr/local/share/doc/dejagnu
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; makeinfo --plaintext  -o doc/dejagnu.txt doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -dm755 /usr/local/share/doc/dejagnu
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -m644 doc/dejagnu.{html,txt} /usr/local/share/doc/dejagnu
	$(call PKGINSTALL,$@)

.PHONY: diffutils
diffutils: $(diffutils-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	# next release should fix the test-copyright problem
	# they did not code the perl regular expression correctly
	-cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: doxygen
doxygen: $(doxygen-ver)
	$(call SOURCEDIR,$@,xf)
	# Need to add libiconv, normally in glibc, but in our environment it is separate
	cd $@/`cat $@/untar.dir`/; sed -i -e 's/TMAKE_LIBS[ 	]*=.*/TMAKE_LIBS      = -liconv/' tmake/lib/linux-g++/tmake.conf
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)


.PHONY: e2fsprogs
e2fsprogs: $(e2fsprogs-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/misc; patch < ../../../patches/e2fsprogs.Makefile.in.patch
	cd $@/`cat $@/untar.dir`/misc; patch < ../../../patches/e2fsprogs.e4defrag.c.patch
	cd $@/`cat $@/untar.dir`/misc; patch < ../../../patches/e2fsprogs.e4crypt.c.patch
	cd $@/`cat $@/untar.dir`/tests/m_hugefile; patch < ../../../../patches/e2fsprogs.script.patch
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check
	cd $@/`cat $@/untar.dir`/; sudo make install-libs
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: ecj
ecj: $(ecj-ver)
	cd $@; sudo mkdir -pv /usr/local/share/java
	cd $@; sudo cp -v *.jar /usr/local/share/java/ecj.jar

.PHONY: expat
expat:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: expect
expect: $(expect-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-tcl=/usr/local/lib --with-tclinclude=/usr/local/include
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: flex
flex:
	$(call SOURCEDIR,$@,xfj)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# fails because of the old Glibc
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: fontconfig
fontconfig: $(fontconfig-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --sysconfdir=/usr/local/etc --localstatedir=/usr/local/var --disable-docs --docdir=/usr/local/share/doc/fontconfig 
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: freetype
freetype: $(freetype-ver)
	$(call SOURCEDIR,$@,xfj)
	cd $@/`cat $@/untar.dir`/; sed -i  -e "/AUX.*.gxvalid/s@^# @@" -e "/AUX.*.otvalid/s@^# @@" modules.cfg
	cd $@/`cat $@/untar.dir`/; sed -ri -e 's:.*(#.*SUBPIXEL.*) .*:\1:' include/config/ftoption.h
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local $(HBOPT)
	cd $@/`cat $@/untar.dir`/; make
	# freetype does not have a test package
	$(call PKGINSTALL,$@)

.PHONY: freetype-nohb
freetype-nohb:
	make freetype HBOPT="--without-harfbuzz"

.PHONY: fuse
fuse: $(fuse-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# No test suite for fuse
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)

.PHONY: harfbuzz
harfbuzz: $(harfbuzz-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-gobject
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)

.PHONY: httpd
httpd: $(httpd-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed 's/ldump_writer, &b/&, NULL/' -i modules/lua/mod_lua.c
	cd $@/`cat $@/untar.dir`/; sed '/dir.*CFG_PREFIX/s@^@#@' -i support/apxs.in
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local \
	        --enable-mods-shared="all cgi" \
		--enable-mpms-shared=all --with-apr=/usr/local/bin/apr-1-config \
		--with-apr-util=/usr/local/bin/apu-1-config --enable-suexec=shared \
		--with-suexec-bin=/usr/lib/httpd/suexec \
		--with-suexec-docroot=/srv/www --with-suexec-caller=apache \
		--with-suexec-userdir=public_html \
		--with-suexec-logfile=/usr/local/var/log/httpd/suexec.log \
		--with-suexec-uidmin=100
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

.PHONY: gc
gc: $(gc-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ATOMIC_OPS_CFLAGS=-I/usr/local/include ATOMIC_OPS_LIBS=-L/usr/local/lib ./configure --prefix=/usr/local --enable-gc-debug --enable-gc-assertions --enable-threads=posix
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@.*)

.PHONY: gcc
gcc: $(gcc-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../mpfr/mpfr*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpfr-* mpfr
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../gmp/gmp*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf gmp-* gmp
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../mpc/mpc*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpc-* mpc
	cd $@/`cat $@/untar.dir`; cp ../../ecj/ecj*.jar ./ecj.jar
	# this will let us build glibc
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# May have to disable this to build the non-glibc packages
	# cd $@/`cat $@/untar.dir`; sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    --prefix=/usr/local \
                    --enable-languages=$(GCC_LANGS) \
		    --with-ecj-jar=/usr/local/share/java/ecj.jar
	cd $@/$@-build/; make
	-cd $@/$@-build/; C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib make check
	test -e /usr/local/bin/cc || /usr/bin/sudo ln -s /usr/local/bin/gcc /usr/local/bin/cc
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,libssp*)
	$(call CPLIB,libstdc*)
	@echo "======= Build of $@ Successful ======="

.PHONY: gcc48
gcc48:
	$(call SOURCEDIR,$@,xf)
	# use this for gcc 4.8 cd $@/`cat $@/untar.dir`/gcc; patch < ../../../patches/gcc.Makefile.in.patch
	cd $@/`cat $@/untar.dir`/gcc; patch < ../../../patches/gcc.Makefile.in.patch
	cd $@/`cat $@/untar.dir`; tar xf ../../mpfr/mpfr*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpfr-* mpfr
	cd $@/`cat $@/untar.dir`; tar xf ../../gmp/gmp*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf gmp-* gmp
	cd $@/`cat $@/untar.dir`; tar xf ../../mpc/mpc*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpc-* mpc
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local \
                    --enable-languages=c,c++,fortran,java,objc,obj-c++ 
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: go
go: $(go-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/src; patch < ../../../patches/go.patch
	-cd $@; sudo /bin/rm -rf /usr/local/go
	cd $@; sudo cp -r go /usr/local/.
	cd /usr/local/go/src; sudo ./all.bash

.PHONY: gnutls
gnutls: $(gnutls-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-default-trust-store-file=/usr/local/etc/ssl/ca-bundle.crt
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# May not have gzip functionality in tar when we try to build gzip
.PHONY: gzip
gzip: $(gzip-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: hashdeep
hashdeep: $(hashdeep-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sh ./bootstrap.sh
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: icu
icu: $(icu-ver)
	$(call SOURCEDIR,$@,xf)
	# XXX XXX XXX XXX 
	cd $@/`cat $@/untar.dir`/source; CC=gcc CXX=g++ ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/source; make
	cd $@/`cat $@/untar.dir`/source; make check || make test
	$(call PKGINSTALLTO,$@,`cat $@/untar.dir`/source)

.PHONY: inetutils
inetutils: $(inetutils-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local  \
	        --localstatedir=/usr/local/var   \
		--disable-logger       \
		--disable-syslogd      \
		--disable-whois        \
		--disable-servers
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: include-what-you-use
include-what-you-use: $(iwyu-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; cmake -G "Unix Makefiles" -DLLVM_PATH=../../llvm-3.4 ../include-what-you-use
	cd $@/$@-build/; make
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libatomic_ops
libatomic_ops: $(libatomic_ops-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; autoreconf -fi
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; LD_LIBRARY_PATH=../src/.libs make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libevent
libevent: $(libevent-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local LDFLAGS="-lpthreads"
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libiconv
libiconv: $(libiconv-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libcharset.*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No make check || make test
# libtool is going to fail Fortran checks, we need a new autoconf and automake, these depend on perl
.PHONY: libtool
libtool:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libltdl*)

.PHONY: lua
lua: $(lua-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
	cd $@/`cat $@/untar.dir`/; make linux MYLIBS=-lncursesw
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; sudo make INSTALL_TOP=/usr/local TO_LIB="liblua.a" \
	     INSTALL_DATA="cp -d" INSTALL_MAN=/usr/share/man/man1 install
	cd $@/`cat $@/untar.dir`/; sudo mkdir -pv /usr/local/share/doc/lua
	cd $@/`cat $@/untar.dir`/; sudo cp -v doc/*.{html,css,gif,png} /usr/local/share/doc/lua
	@echo "======= Build of $@ Successful ======="

#
# NetPBM packages itself in a a non-standard way into /tmp/netpbm, so
# we can not use our standard package installation script
#
export NETPBMCONFIG
.PHONY: netpbm
netpbm: $(netpbm-ver)
	sudo /bin/rm -rf /tmp/netpbm
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; cp Makefile.config.in Makefile.config
	cd $@/`cat $@/untar.dir`/; echo "$$NETPBMCONFIG" >> Makefile.config
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make package
	$(call PKGFROMSTAGE,$@,`cat $@/untar.dir`,netpbm)
	cd $@/`cat $@/untar.dir`/; sudo mkdir -pv /usr/local/share/netpbm
	cd $@/`cat $@/untar.dir`/; sudo cp -a -v /tmp/netpbm/bin/* /usr/local/bin/.
	cd $@/`cat $@/untar.dir`/; sudo cp -a -v /tmp/netpbm/include/* /usr/local/include/.
	cd $@/`cat $@/untar.dir`/; sudo cp -a -v /tmp/netpbm/link/* /usr/local/lib/.
	cd $@/`cat $@/untar.dir`/; sudo cp -a -v /tmp/netpbm/man/* /usr/local/man/.
	cd $@/`cat $@/untar.dir`/; sudo cp -a -v /tmp/netpbm/misc/* /usr/local/share/netpbm/.
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: origgcc
origgcc:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/gcc; patch < ../../../patches/gcc.Makefile.in.patch
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --libdir=/usr/local/lib \
                    --libexecdir=/usr/local/lib --with-system-zlib --with-gmp=/usr/local \
                    --with-mpfr=/usr/local --with-mpc=/usr/local --enable-shared \
                    --enable-threads=posix --enable-__cxa_atexit --disable-multilib \
                    --enable-clocale=gnu --enable-lto \
                    --enable-languages=c,c++,fortran,java,objc,obj-c++ 
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

# tests fail, including the test driver
#
# Linux from Scratch reports:
# To test the results, issue: make -k check. There are many problems
# with the test suite. Depends on installed compilers, there are
# differences if run locally or remotely, a large number of timeouts
# (there is a variable that can be set to increase time for timeout,
# but changing it, apparently the total number of tests is not
# conserved), there are failures associated with system readline
# 6.x, between others. Unexpected failures are of the order of 0.5%.
#
.PHONY: gdb
gdb: $(gdb-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	# cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

# From the GIT Makefile
#
# Define SHELL_PATH to a POSIX shell if your /bin/sh is broken.
#
# Define SANE_TOOL_PATH to a colon-separated list of paths to prepend
# to PATH if your tools in /usr/bin are broken.
# 
export GITCONFIG
.PHONY: git
git: $(git-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" ./configure --prefix=/usr/local --with-gitconfig=/usr/local/etc/gitconfig --with-libpcre
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make test
	cd $@/`cat $@/untar.dir`/; sudo /bin/rm -f /usr/local/etc/gitconfig
	cd $@/`cat $@/untar.dir`/; sudo /bin/rm -f /tmp/gitconfig
	cd $@/`cat $@/untar.dir`/; echo "$$GITCONFIG" >> /tmp/gitconfig
	cd $@/`cat $@/untar.dir`/; sudo cp /tmp/gitconfig /usr/local/etc/gitconfig
	$(call PKGINSTALL,$@)
	$(call CPLIB,libz.*)

.PHONY: glib
glib: $(glib-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-internal-glib --with-libiconv=gnu --with-pcre=system
	cd $@/`cat $@/untar.dir`/; CFLAGS=-I/usr/local/include LDFLAGS="-L/usr/local/lib -liconv -lz" make
	# Can not run check until desktop-file-utils are installed
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

# CFLAGS="-march=i686 -g -O2 -fno-stack-protector"
.PHONY: glibc
glibc: $(glibc-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/`cat $@/untar.dir`/; sed -e '/ia32/s/^/1:/' -e '/SSE2/s/^1://' -i sysdeps/i386/i686/multiarch/mempcpy_chk.S
	cd $@/`cat $@/untar.dir`/; sed -e '/tst-audit2-ENV/i CFLAGS-tst-audit2.c += -fno-builtin' -i elf/Makefile
	# cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --enable-kernel=2.6.32 --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include CFLAGS="-march=i686 -g -O2 -fno-stack-protector"
	# cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include -without-selinux -enable-obsolete-rpc CFLAGS="-fno-stack-protector -march=i686 -O2"
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include -without-selinux -enable-obsolete-rpc
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	-sudo mkdir -p /usr/local/glibc/etc
	sudo touch /usr/local/glibc/etc/ld.so.conf
	$(call PKGINSTALLBUILD,$@)

.PHONY: gmp
gmp: $(gmp-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# guile is needed by autogen
.PHONY: guile
guile: $(guile-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig ../`cat ../untar.dir`/configure --prefix=/usr/local --enable-error-on-warning=no --with-libgmp-prefix=/usr/local
	cd $@/$@-build/; make
	# 3 out of 38860 tests failed
	# cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)

.PHONY: libelf
libelf:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: linux-2.6.32.61
linux-2.6.32.61:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 menuconfig
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 dep
	cd $@/`cat $@/untar.dir`/; make ARCH=x86
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 modules
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 modules_install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/include/linux-2.6.32
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/local
	@echo "======= Build of $@ Successful ======="

.PHONY: linux-3.13.6
linux-3.13.6:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 menuconfig
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 dep
	cd $@/`cat $@/untar.dir`/; make ARCH=x86
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 modules
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 modules_install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/include/linux-3.13.6
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/local
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install
	@echo "======= Build of $@ Successful ======="

# De-configure the 64 bit kernel
# Disable Token Ring
# Enable RealTek 8196 under Networking Devices
# Enable FUSE support under File Systems
# Enable FUSE file system
# Enable ext4 encryption
#
.PHONY: linux-4.1.tar.xz
linux-4.1.tar.xz:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 menuconfig
	cd $@/`cat $@/untar.dir`/; make ARCH=x86
	cd $@/`cat $@/untar.dir`/; make ARCH=x86 modules
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 modules_install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/include/linux-3.13.6
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=/usr/local
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install
	@echo "======= Build of $@ Successful ======="

# If the install generates a unable to infer compiler target triple for gcc,
# the sudo needs a ./SETUP.bash before running it.
.PHONY: llvm
llvm: $(llvm-ver) $(clang-ver) $(compiler-rt-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; tar -xf ../../clang/clang-3.4.src.tar.gz -C tools
	cd $@/`cat $@/untar.dir`/; tar -xf ../../compiler-rt/compiler-rt-3.4.src.tar.gz -C projects
	cd $@/`cat $@/untar.dir`/; mv tools/clang-3.4 tools/clang
	cd $@/`cat $@/untar.dir`/; mv projects/compiler-rt-3.4 projects/compiler-rt
	cd $@/`cat $@/untar.dir`/projects/compiler-rt/lib/sanitizer_common; patch < ../../../../../../patches/compiler-rt.patch
	cd $@/`cat $@/untar.dir`/; CC=gcc CXX=g++ ./configure --prefix=/usr/local \
	    --sysconfdir=/usr/local/etc --enable-libffi --enable-optimized --enable-shared \
	    --enable-targets=all \
	    --with-c-include-dirs="/usr/local/include:/usr/include" --with-gcc-toolchain=/usr/local
	    # --with-c-include-dirs="/usr/include/linux-2.6.32/include:/usr/include:/usr/local/include"
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: mpc
mpc: $(mpc-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local --with-gmp=/usr/local --with-mpfr=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: mpfr
mpfr: $(mpfr-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local --with-gmp=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: ncurses
ncurses:
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --with-shared --enable-widec
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	if test -d /usr/local/include/ncursesw ; then test -d /usr/include/ncursesw || test -L /usr/include/ncursesw || /usr/bin/sudo ln -s /usr/local/include/ncursesw /usr/include/. ; fi 
	if test -d /usr/local/include/ncursesw ; then test -d /usr/include/ncurses || test -L /usr/include/ncurses || /usr/bin/sudo ln -s /usr/local/include/ncursesw /usr/include/ncurses ; fi 

.PHONY: ntfs-3g
ntfs-3g: $(ntfs-3g-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# There is no test suite for ntfs-3g
	$(call PKGINSTALL,$@)

.PHONY: openssl
openssl: $(openssl-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./config --prefix=/usr/local --openssldir=/usr/local/etc/ssl --libdir=lib shared zlib-dynamic
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make MANDIR=/usr/share/man MANSUFFIX=ssl install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -dv -m755 /usr/share/doc/openssl-1.0.1e
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make cp -vfr doc/*     /usr/share/doc/openssl-1.0.1e
	$(call LNLIB,libssl.a)
	$(call LNLIB,libssl.so)
	$(call LNLIB,libssl.so.1.0.0)
	$(call LNLIB,libcrypto.a)
	$(call LNLIB,libcrypto.so)
	$(call LNLIB,libcrypto.so.1.0.0)
	@echo "======= Build of $@ Successful ======="

.PHONY: pcre
pcre: $(pcre-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-unicode-properties \
	    --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 \
	    --enable-pcretest-libreadline
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: pth
pth: $(pth-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	# cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --enable-pthread
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,libpthread*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: Python
Python: $(Python-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python2.7 setup.py install
	cd $@/`cat $@/untar.dir`/; wget https://bootstrap.pypa.io/get-pip.py
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python2.7 get-pip.py
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo pip install -U setuptools
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo pip install -U pip
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo pip install -U cppclean

.PHONY: perl
perl: $(perl-ver)
	$(call SOURCEDIR,$@,xzf)
	# srand is not being called automatically, probably because of old glibc
	# cd $@/`cat $@/untar.dir`/; /bin/sed -i -e 's/^\(.*srand.*called.*automatically.*\)/@first_run  = mk_rand; \1/' t/op/srand.t
	cd $@/`cat $@/untar.dir`/; ./Configure -des -Dprefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; $(PHASE1_NOCHECK) make test
	$(call PKGINSTALL,$@)

.PHONY: pkg-config
pkg-config:
	$(call SOURCEDIR,$@,xf)
	sudo /bin/rm -f /usr/local/bin/i686-pc-linux-gnu-pkg-config
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/GNU libiconv not in use but included iconv.h/d' ./glib/glib/gconvert.c
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/prctl (PR_SET_NAME, name, 0, 0, 0, 0);/d' ./glib/glib/gthread-posix.c
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-internal-glib --with-libiconv=gnu
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -liconv" make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: p7zip
p7zip: $(p7zip-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; cp makefile.linux_x86_asm_gcc_4.X makefile.linux
	cd $@/`cat $@/untar.dir`/; make all3
	cd $@/`cat $@/untar.dir`/; make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./install.sh

.PHONY: ruby
ruby:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make LDFLAGS="-L/usr/local/lib -lssp" install
	@echo "======= Build of $@ Successful ======="

.PHONY: serf
serf: $(serf-ver)
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libserf*
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed -i "/Append/s:RPATH=libdir,::"  SConstruct && \
	sed -i "/Default/s:lib_static,::"   SConstruct && \
	sed -i "/Alias/s:install_static,::" SConstruct && \
	scons PREFIX=/usr/local
	cd $@/`cat $@/untar.dir`/; scons check
	cd $@/`cat $@/untar.dir`/; sudo scons PREFIX=/usr/local install
	@echo "======= Build of $@ Successful ======="

.PHONY: scons
scons: $(scons-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py install \
	    --prefix=/usr/local  --standard-lib --optimize=1 --install-data=/usr/share
	@echo "======= Build of $@ Successful ======="

.PHONY: sparse
sparse: $(sparse-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALLPREFIX,$@)

.PHONY: subversion
subversion: $(subversion-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./autogen.sh
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local  \
	    --with-apxs=/usr/local/bin/apxs \
	    --with-ssl --without-apache
	    #--with-apache \
	    #--with-apache-libexecdir=$(/usr/local/bin/apxs -q libexecdir)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: swig
swig: $(swig-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure
	cd $@/`cat $@/untar.dir`/; make
	# java can not find a class it is looking for in
	# the test cases
	-$(call PKGCHECK,$@)
	$(call PKGINSTALL,$@)

.PHONY: tcl
tcl: $(tcl-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/unix; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/unix; make
	cd $@/`cat $@/untar.dir`/unix; make test
	cd $@/`cat $@/untar.dir`/unix; /usr/bin/sudo make install
	cd $@/`cat $@/untar.dir`/unix; /usr/bin/sudo make install-private-headers
	cd $@/`cat $@/untar.dir`/unix; /usr/bin/sudo /bin/rm -f /usr/local/bin/tclsh
	cd $@/`cat $@/untar.dir`/unix; /usr/bin/sudo ln -v -sf /usr/local/bin/tclsh8.6 /usr/local/bin/tclsh

.PHONY: tclx
tclx:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	# Something fails, I do not expect to need tclX for anything
	# cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: tcp_wrappers
tcp_wrappers: $(tcp_wrappers-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; patch -Np1 -i ../../patches/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch
	cd $@/`cat $@/untar.dir`/; sed -i -e "s,^extern char \*malloc();,/* & */," scaffold.c
	cd $@/`cat $@/untar.dir`/; make REAL_DAEMON_DIR=/usr/local/sbin STYLE=-DPROCESS_OPTIONS linux
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install

.PHONY: truecrypt
truecrypt: $(truecrypt-ver)
	$(call SOURCEDIR,$@,xf)

.PHONY: unzip
unzip: $(unzip-ver)
	$(call SOURCEDIR,$@,zip)
	cd $@/`cat $@/untar.dir`/; sed -i -e 's/CFLAGS="-O -Wall/& -DNO_LCHMOD/' unix/Makefile
	cd $@/`cat $@/untar.dir`/; make -f unix/Makefile linux_noasm
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local MANDIR=/usr/local/man/man1 -f unix/Makefile install
	@echo "======= Build of $@ Successful ======="

.PHONY: util-linux
util-linux: $(util-linux-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-arch --enable-partx --enable-write
	# cd $@/`cat $@/untar.dir`/; make CFLAGS=-DO_CLOEXEC=0
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

.PHONY: util-linux-ng
util-linux-ng: $(util-linux-ng-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-arch --enable-partx --enable-write
	# cd $@/`cat $@/untar.dir`/; make CFLAGS=-DO_CLOEXEC=0
	cd $@/`cat $@/untar.dir`/; make CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw"
	$(call PKGINSTALL,$@)
	$(call CPLIB,libuuid*)

.PHONY: vim
vim: $(vim-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-perlinterp --enable-pythoninterp --enable-tclinterp --enable-rubyinterp
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-pythoninterp --enable-tclinterp --enable-rubyinterp --with-x --enable-gui
	cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C make
	cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C make test || LANG=C LC_ALL=C make check
	$(call PKGINSTALL,$@)

.PHONY: zip
zip: $(zip-ver)
	$(call SOURCEDIR,$@,zip)
	cd $@/`cat $@/untar.dir`/; make -f unix/Makefile generic_gcc
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local MANDIR=/usr/local/man/man1 -f unix/Makefile install
	@echo "======= Build of $@ Successful ======="

.PHONY: zlib
zlib: $(zlib-ver)
	$(call SOURCEDIR,$@,xfz)
	sudo /bin/rm -f /usr/local/lib/libz.a /usr/local/lib/libz.so /usr/local/lib/libz.so.1*
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libz.*)

.PHONY: wget
wget:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; patch -Np1 -i ../wget-1.14-texi2pod-1.patch
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --sysconfdir=/usr/local/etc --with-ssl=openssl
	cd $@/`cat $@/untar.dir`/; make
	# Uses perl to do the tests and setup a server, there is something failing
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: wget-all
wget-all: \
    $(acl-ver) \
    $(apr-ver) \
    $(apr-util-ver) \
    $(attr-ver) \
    $(autoconf-ver) \
    $(automake-ver) \
    $(autossh-ver) \
    $(bash-ver) \
    $(binutils-ver) \
    $(bcrypt-ver) \
    $(ca-cert-ver) \
    $(cairo-ver) \
    $(check-ver) \
    $(clang-ver) \
    $(clisp-ver) \
    $(cmake-ver) \
    $(compiler-rt-ver) \
    $(coreutils-ver) \
    $(cppcheck-ver) \
    $(curl-ver) \
    $(dejagnu-ver) \
    $(Devel-Symdump-ver) \
    $(diffutils-ver) \
    $(doxygen-ver) \
    $(e2fsprogs-ver) \
    $(ecj-ver) \
    $(expect-ver) \
    $(file-ver) \
    $(findutils-ver) \
    $(fontconfig-ver) \
    $(freetype-ver) \
    $(fuse-ver) \
    $(gawk-ver) \
    $(gc-ver) \
    $(gcc-ver) \
    $(gdb-ver) \
    $(gdbm-ver) \
    $(gettext-ver) \
    $(git-ver) \
    $(glib-ver) \
    $(glibc-ver) \
    $(gmp-ver) \
    $(go-ver) \
    $(gntls-ver) \
    $(gnupg-ver) \
    $(grep-ver) \
    $(guile-ver) \
    $(gzip-ver) \
    $(harfbuzz-ver) \
    $(hashdeep-ver) \
    $(htop-ver) \
    $(httpd-ver) \
    $(hwloc-ver) \
    $(icu-ver) \
    $(inetutils-ver) \
    $(iptraf-ng-ver) \
    $(IO-Socket-SSL-ver) \
    $(iwyu-ver) \
    $(jnettop-ver) \
    $(libarchive-ver) \
    $(libassuan-ver) \
    $(libatomic_ops-ver) \
    $(libevent-ver) \
    $(libffi-ver) \
    $(libgcrypt-ver) \
    $(libgpg-error-ver) \
    $(libiconv-ver) \
    $(libksba-ver) \
    $(libpcap-ver) \
    $(libpng-ver) \
    $(libtasn1-ver) \
    $(libunistring-ver) \
    $(libusb-ver) \
    $(lua-ver) \
    $(lzo-ver) \
    $(m4-ver) \
    $(make-ver) \
    $(mosh-ver) \
    $(mpc-ver) \
    $(mpfr-ver) \
    $(multitail-ver) \
    $(netpbm-ver) \
    $(nettle-ver) \
    $(ntfs-3g-ver) \
    $(openssl-ver) \
    $(par2cmdline-ver) \
    $(pcre-ver) \
    $(perl-ver) \
    $(pixman-ver) \
    $(popt-ver) \
    $(protobuf-ver) \
    $(psmisc-ver) \
    $(pth-ver) \
    $(Python-ver) \
    $(p7zip-ver) \
    $(scons-ver) \
    $(screen-ver) \
    $(scrypt-ver) \
    $(sed-ver) \
    $(serf-ver) \
    $(sharutils-ver) \
    $(symlinks-ver) \
    $(socat-ver) \
    $(sparse-ver) \
    $(srm-ver) \
    $(subversion-ver) \
    $(swig-ver) \
    $(symlinks-ver) \
    $(tcp_wrappers-ver) \
    $(tar-ver) \
    $(tcl-ver) \
    $(tcpdump-ver) \
    $(texinfo-ver) \
    $(tmux-ver) \
    $(truecrypt-ver) \
    $(unzip-ver) \
    $(vim-ver) \
    $(which-ver) \
    $(wipe-ver) \
    $(zip-ver) \
    $(zlib-ver) \
    wget-libxml2 \
    wget-NetSSLeay \
    wget-ncurses \
    wget-tcp_wrappers-patch \
    $(util-linux-ver) \
    $(util-linux-ng-ver)

$(acl-ver):
	$(call SOURCEWGET,"acl","http://download.savannah.gnu.org/releases/"$(acl-ver))

$(apr-ver):
	$(call SOURCEWGET,"apr","http://archive.apache.org/dist/apr/apr-1.4.8.tar.bz2")

$(apr-util-ver):
	$(call SOURCEWGET,"apr-util","http://archive.apache.org/dist/apr/apr-util-1.5.3.tar.bz2")

$(attr-ver):
	$(call SOURCEWGET,"attr","http://download.savannah.gnu.org/releases/attr/attr-2.4.47.src.tar.gz")

$(autoconf-ver):
	$(call SOURCEWGET,"autoconf","https://ftp.gnu.org/gnu/"$(autoconf-ver))

$(automake-ver):
	$(call SOURCEWGET,"automake","https://ftp.gnu.org/gnu/"$(automake-ver))

$(autossh-ver):
	$(call SOURCEWGET,"autossh","http://www.harding.motd.ca/"$(autossh-ver))

$(bash-ver):
	$(call SOURCEWGET,"bash","https://ftp.gnu.org/gnu/"$(bash-ver))

$(bcrypt-ver):
	$(call SOURCEWGET,"bcrypt","http://bcrypt.sourceforge.net/bcrypt-1.1.tar.gz")

$(binutils-ver):
	$(call SOURCEWGET,"binutils","https://ftp.gnu.org/gnu/"$(binutils-ver))

$(ca-cert-ver):
	$(call SOURCEWGET,"ca-cert","http://anduin.linuxfromscratch.org/sources/other/certdata.txt")
	cd ca-cert; mkdir -p ca-cert-1.0
	cd ca-cert; mv certdata.txt ca-cert-1.0
	cd ca-cert; tar cfz ca-cert-1.0.tar.gz ./ca-cert-1.0

$(cairo-ver):
	$(call SOURCEWGET,"cairo","http://cairographics.org/releases/cairo-1.14.2.tar.xz")

$(check-ver):
	$(call SOURCEWGET,"check","http://downloads.sourceforge.net/project/check/check/0.9.12/check-0.9.12.tar.gz")

$(clang-ver):
	$(call SOURCEWGET,"clang","http://llvm.org/releases/3.4/clang-3.4.src.tar.gz")

$(clisp-ver):
	$(call SOURCEWGET,"clisp","https://ftp.gnu.org/pub/gnu/"$(clisp-ver))

$(cmake-ver):
	$(call SOURCEWGET,"cmake","http://www.cmake.org/files/v3.1/cmake-3.1.2.tar.gz")

$(compiler-rt-ver):
	$(call SOURCEWGET,"compiler-rt","http://llvm.org/releases/3.4/compiler-rt-3.4.src.tar.gz")

$(coreutils-ver):
	$(call SOURCEWGET,"coreutils","https://ftp.gnu.org/gnu/"$(corutils-ver))

$(cppcheck-ver):
	$(call SOURCEWGET,"cppcheck","http://downloads.sourceforge.net/project/cppcheck/cppcheck/1.65/cppcheck-1.65.tar.bz2")

$(curl-ver):
	$(call SOURCEWGET,"curl","http://curl.haxx.se/download/curl-7.41.0.tar.bz2")

$(Devel-Symdump-ver):
	$(call SOURCEWGET,"Devel-Symdump","http://search.cpan.org/CPAN/authors/id/A/AN/ANDK/Devel-Symdump-2.14.tar.gz")

$(dejagnu-ver):
	$(call SOURCEWGET,"dejagnu","https://ftp.gnu.org/pub/gnu/"$(dejagnu-ver))


$(diffutils-ver):
	$(call SOURCEWGET,"diffutils","http://ftp.gnu.org/gnu/"$(diffutils-ver))

$(doxygen-ver):
	$(call SOURCEWGET,"doxygen","http://ftp.stack.nl/pub/"$(doxygen-ver))

$(e2fsprogs-ver):
	$(call SOURCEGIT,"e2fsprogs","git://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git")

$(ecj-ver):
	$(call SOURCEWGET,"ecj","ftp://sourceware.org/pub/java/ecj-latest.jar")

$(expect-ver):
	$(call SOURCEWGET,"expect","http://prdownloads.sourceforge.net/"$(expect-ver))

$(file-ver):
	$(call SOURCEWGET,"file","ftp://ftp.astron.com/pub/"$(file-ver))

$(findutils-ver):
	$(call SOURCEWGET,"findutils","https://ftp.gnu.org/pub/gnu/"$(findutils-ver))

$(fontconfig-ver):
	$(call SOURCEWGET,"fontconfig","http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.1.tar.bz2")

$(freetype-ver):
	$(call SOURCEWGET,"freetype","http://downloads.sourceforge.net/"$(freetype-ver))

$(fuse-ver):
	$(call SOURCEWGET,"fuse","http://downloads.sourceforge.net/"$(fuse-ver))

$(gawk-ver):
	$(call SOURCEWGET,"gawk","https://ftp.gnu.org/gnu/"$(gawk-ver))

$(gc-ver):
	$(call SOURCEWGET,"gc","http://www.hboehm.info/gc/gc_source/gc-7.4.2.tar.gz")

$(gcc-ver):
	$(call SOURCEWGET,"gcc","https://ftp.gnu.org/gnu/"$(gcc-ver))

$(gdb-ver):
	$(call SOURCEWGET,"gdb","https://ftp.gnu.org/gnu/"$(gdb-ver))

$(gdbm-ver):
	$(call SOURCEWGET,"gdbm","ftp://ftp.gnu.org/gnu/"$(gdbm-ver))

$(gettext-ver):
	$(call SOURCEWGET,"gettext","https://ftp.gnu.org/pub/gnu/"$(gettext-ver))

$(git-ver):
	$(call SOURCEWGET,"git","http://www.kernel.org/pub/software/scm/"$(git-ver))

$(glib-ver):
	$(call SOURCEWGET,"glib","http://ftp.gnome.org/pub/gnome/sources/glib/2.42/glib-2.42.1.tar.xz")

$(glibc-ver):
	$(call SOURCEWGET,"glibc","https://ftp.gnu.org/gnu/"$(glibc-ver))

$(gmp-ver):
	$(call SOURCEWGET,"gmp","ftp://gcc.gnu.org/pub/gcc/infrastructure/gmp-4.3.2.tar.bz2")

$(gnupg-ver):
	$(call SOURCEWGET,"gnupg","ftp://ftp.gnupg.org/gcrypt/"$(gnupg-ver))

$(gnutls-ver):
	$(call SOURCEWGET,"gnutls","ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.13.tar.xz")

$(go-ver):
	$(call SOURCEWGET,"go","https://storage.googleapis.com/golang/go1.4.2.src.tar.gz")

$(grep-ver):
	$(call SOURCEWGET,"grep","https://ftp.gnu.org/gnu/"$(grep-ver))

$(guile-ver):
	$(call SOURCEWGET,"guile","https://ftp.gnu.org/pub/gnu/"$(guile-ver))

$(gzip-ver):
	$(call SOURCEWGET,"gzip","https://ftp.gnu.org/gnu/"$(gzip-ver))

$(harfbuzz-ver):
	$(call SOURCEWGET,"harfbuzz","http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-0.9.38.tar.bz2")

$(hashdeep-ver):
	$(call SOURCEGIT,"hashdeep","https://github.com/jessek/hashdeep.git")

$(htop-ver):
	$(call SOURCEWGET,"htop","http://hisham.hm/htop/releases/1.0.1/htop-1.0.1.tar.gz")

$(httpd-ver):
	$(call SOURCEWGET,"httpd","http://archive.apache.org/dist/"$(httpd-ver))

$(hwloc-ver):
	$(call SOURCEWGET,"hwloc","http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.0.tar.gz")

$(icu-ver):
	$(call SOURCEWGET,"icu","http://download.icu-project.org/files/icu4c/54.1/icu4c-54_1-src.tgz")

$(inetutils-ver):
	$(call SOURCEWGET,"inetutils","https://ftp.gnu.org/gnu/"$(inetutils-ver))

$(iptraf-ng-ver):
	$(call SOURCEWGET,"iptraf-ng","https://fedorahosted.org/releases/i/p/"$(iptraf-ng-ver))

$(iwyu-ver):
	$(call SOURCEWGET,"include-what-you-use","http://include-what-you-use.com/downloads/include-what-you-use-3.4.src.tar.gz")

$(IO-Socket-SSL-ver):
	$(call SOURCEWGET,"IO-Socket-SSL","http://search.cpan.org/CPAN/authors/id/S/SU/SULLR/IO-Socket-SSL-2.012.tar.gz")

$(libarchive-ver):
	$(call SOURCEWGET,"libarchive","http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz")

$(libassuan-ver):
	$(call SOURCEWGET,"libassuan","ftp://ftp.gnupg.org/gcrypt/"$(libassuan-ver))

$(libatomic_ops-ver):
	$(call SOURCEWGET,"libatomic_ops","http://www.ivmaisoft.com/_bin/atomic_ops/libatomic_ops-7.4.2.tar.gz")

$(libevent-ver):
	$(call SOURCEWGET,"libevent","https://github.com/downloads/libevent/"$(libevent-ver))

$(libffi-ver):
	$(call SOURCEWGET,"libffi","ftp://sourceware.org/pub/"$(libffi-ver))

$(libgcrypt-ver):
	$(call SOURCEWGET,"libgcrypt","ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.6.2.tar.bz2")

$(libksba-ver):
	$(call SOURCEWGET,"libksba","ftp://ftp.gnupg.org/gcrypt/"$(libksba-ver))

$(libiconv-ver):
	$(call SOURCEWGET,"libiconv","https://ftp.gnu.org/pub/gnu/$(libiconv-ver))

$(libpcap-ver):
	$(call SOURCEWGET,"libpcap","http://www.tcpdump.org/release/libpcap-1.4.0.tar.gz")

$(libgpg-error-ver):
	$(call SOURCEWGET,"libgpg-error","ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.18.tar.bz2")

$(libpng-ver):
	$(call SOURCEWGET,"libpng","http://downloads.sourceforge.net/libpng/libpng-1.6.16.tar.xz")

$(libtasn1-ver):
	$(call SOURCEWGET,"libtasn1","https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.2.tar.gz")

$(libunistring-ver):
	$(call SOURCEWGET,"libunistring","https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.5.tar.xz")

$(libusb-ver):
	$(call SOURCEWGET,"libusb","http://downloads.sourceforge.net/libusb/libusb-1.0.19.tar.bz2")

.PHONY: wget-libxml2
wget-libxml2:
	$(call SOURCEWGET,"libxml2","http://xmlsoft.org/sources/libxml2-2.9.1.tar.gz")

$(llvm-ver):
	$(call SOURCEWGET,"llvm","http://llvm.org/releases/3.4/llvm-3.4.src.tar.gz")

$(lua-ver):
	$(call SOURCEWGET,"lua","http://www.lua.org/ftp/lua-5.3.0.tar.gz")

$(make-ver):
	$(call SOURCEWGET,"make","https://ftp.gnu.org/gnu/make/make-4.1.tar.gz")

$(jnettop-ver):
	$(call SOURCEWGET,"jnettop","http://jnettop.kubs.info/dist/jnettop-0.13.0.tar.gz")

$(lzo-ver):
	$(call SOURCEWGET,"lzo","http://www.oberhumer.com/opensource/lzo/download/lzo-2.08.tar.gz")

$(m4-ver):
	$(call SOURCEWGET,"m4","http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.gz")

$(mpc-ver):
	$(call SOURCEWGET,"mpc","ftp://ftp.gnupg.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz")

$(mpfr-ver):
	$(call SOURCEWGET,"mpfr","ftp://ftp.gnupg.org/pub/gcc/infrastructure/mpfr-2.4.2.tar.gz")

$(mosh-ver):
	$(call SOURCEWGET,"mosh","http://mosh.mit.edu/mosh-1.2.4.tar.gz")

$(multitail-ver):
	$(call SOURCEWGET,"multitail","http://www.vanheusden.com/multitail/multitail-6.4.1.tgz")

$(nettle-ver):
	$(call SOURCEWGET,"nettle","https://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz")

.PHONY: wget-ncurses
wget-ncurses:
	$(call SOURCEWGET,"ncurses","https://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz")

.PHONY: wget-Net-SSLeay
wget-Net-SSLeay:
	$(call SOURCEWGET,"Net-SSLeay","http://search.cpan.org/CPAN/authors/id/M/MI/MIKEM/Net-SSLeay-1.68.tar.gz")

$(netpbm-ver):
	$(call SOURCEWGET,"netpbm","http://downloads.sourceforge.net/project/netpbm/super_stable/10.35.95/netpbm-10.35.95.tgz")

$(ntfs-3g-ver):
	$(call SOURCEWGET,"ntfs-3g","http://tuxera.com/opensource/ntfs-3g_ntfsprogs-2013.1.13.tgz")

$(openssl-ver):
	$(call SOURCEWGET,"openssl","http://www.openssl.org/source/openssl-1.0.2.tar.gz")

$(par2cmdline-ver):
	$(call SOURCEWGET,"par2cmdline","https://github.com/Parchive/par2cmdline/archive/master.zip")

$(pcre-ver):
	$(call SOURCEWGET,"pcre","ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.36.tar.bz2")

$(perl-ver):
	$(call SOURCEWGET,"perl","http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz")

$(pixman-ver):
	$(call SOURCEWGET,"pixman","http://cairographics.org/releases/pixman-0.32.6.tar.gz")

# Popt needed for cryptsetup
$(popt-ver):
	$(call SOURCEWGET,"popt","http://rpm5.org/files/popt/popt-1.16.tar.gz")

$(protobuf-ver):
	$(call SOURCEWGET,"protobuf", "https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2")

$(psmisc-ver):
	$(call SOURCEWGET, "psmisc", "http://downloads.sourceforge.net/psmisc/psmisc-22.21.tar.gz")

$(pth-ver):
	$(call SOURCEWGET, "pth", "https://ftp.gnu.org/gnu/pth/pth-2.0.7.tar.gz")

$(Python-ver):
	$(call SOURCEWGET, "Python", "https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tar.xz")

$(p7zip-ver):
	$(call SOURCEWGET,"p7zip","http://downloads.sourceforge.net/project/p7zip/p7zip/9.38.1/p7zip_9.38.1_src_all.tar.bz2")

$(scons-ver):
	$(call SOURCEWGET, "scons", "http://prdownloads.sourceforge.net/scons/scons-2.3.4.tar.gz")

$(screen-ver):
	$(call SOURCEWGET,"screen","https://ftp.gnu.org/gnu/screen/screen-4.2.1.tar.gz")

$(scrypt-ver):
	$(call SOURCEWGET, "scrypt","http://www.tarsnap.com/"$(scrypt-ver))

$(sed-ver):
	$(call SOURCEWGET, "sed", "http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.gz")

$(serf-ver):
	$(call SOURCEWGET, "serf", "http://serf.googlecode.com/svn/src_releases/serf-1.3.5.tar.bz2")

# sharutils needed for cryptsetup
$(sharutils-ver):
	$(call SOURCEWGET, "sharutils", "http://ftp.gnu.org/gnu/sharutils/sharutils-4.15.1.tar.xz")

$(subversion-ver):
	$(call SOURCEWGET,"subversion","http://www.apache.org/dist/subversion/subversion-1.8.9.tar.bz2")

$(symlinks-ver):
	$(call SOURCEWGET,"symlinks","http://pkgs.fedoraproject.org/repo/pkgs/symlinks/symlinks-1.4.tar.gz/c38ef760574c25c8a06fd2b5b141307d/symlinks-1.4.tar.gz")

$(socat-ver):
	$(call SOURCEWGET, "socat", "http://www.dest-unreach.org/socat/download/socat-1.7.2.2.tar.bz2")

$(sparse-ver):
	$(call SOURCEWGET,"sparse","http://www.kernel.org/pub/software/devel/sparse/dist/sparse-0.5.0.tar.gz")

$(srm-ver):
	$(call SOURCEWGET,"srm","http://sourceforge.net/projects/srm/files/1.2.13/srm-1.2.13.tar.gz")

$(swig-ver):
	# (call SOURCEWGET,"swig","http://downloads.sourceforge.net/swig/swig-2.0.11.tar.gz")
	$(call SOURCEWGET,"swig","http://prdownloads.sourceforge.net/swig/swig-3.0.0.tar.gz")

$(tar-ver):
	$(call SOURCEWGET,"tar","https://ftp.gnu.org/gnu/tar/tar-1.28.tar.gz")

# http://www.tcl.tk/software/tcltk/download.html
$(tcl-ver):
	$(call SOURCEWGET,"tcl","http://prdownloads.sourceforge.net/"$(tcl-ver))

$(tcp_wrappers-ver):
	$(call SOURCEWGET,"tcp_wrappers","ftp://ftp.porcupine.org/pub/security/tcp_wrappers_7.6.tar.gz")

.PHONY: wget-tcp_wrappers-patch
wget-tcp_wrappers-patch:
	$(call PATCHWGET,"http://www.linuxfromscratch.org/patches/blfs/6.3/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch")

$(tcpdump-ver):
	$(call SOURCEWGET,"tcpdump","http://www.tcpdump.org/release/tcpdump-4.5.1.tar.gz")

$(texinfo-ver):
	$(call SOURCEWGET,"texinfo","https://ftp.gnu.org/gnu/texinfo/texinfo-5.2.tar.gz")

$(tmux-ver):
	$(call SOURCEWGET,"tmux","http://downloads.sourceforge.net/tmux/tmux-1.9a.tar.gz")

$(truecrypt-ver):
	$(call SOURCEWGET,"truecrypt","https://www.grc.com/misc/"$(truecrypt-ver))

$(util-linux-ver):
	$(call SOURCEWGET,"util-linux","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz")

$(util-linux-ng-ver):
	$(call SOURCEWGET,"util-linux-ng","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.18/util-linux-ng-2.18.tar.xz")

$(unzip-ver):
	$(call SOURCEWGET,"unzip","http://downloads.sourceforge.net/infozip/unzip60.tar.gz")

$(vim-ver):
	$(call SOURCEWGET,"vim","ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2")

$(which-ver):
	$(call SOURCEWGET,"which","https://ftp.gnu.org/pub/gnu/"$(which-ver))

$(wipe-ver):
	$(call SOURCEWGET,"wipe","http://sourceforge.net/projects/wipe/files/wipe/2.3.1/wipe-2.3.1.tar.bz2")

$(xz-ver):
	$(call SOURCEWGET,"xz","http://tukaani.org/"$(xz-ver))

$(zip-ver):
	$(call SOURCEWGET,"zip","http://downloads.sourceforge.net/infozip/zip30.tar.gz")

$(zlib-ver):
	$(call SOURCEWGET,"zlib","http://zlib.net/zlib-1.2.8.tar.gz")

