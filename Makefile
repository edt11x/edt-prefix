
#
# We need a new version of Make to handle this Makefile. Probably need to 
# compile Make by hand so this will work or package install from somewhere
# else.
#
# The machine needs at least 1Gbyte of RAM or binutils will not pass the tests.
#
# texinfo needs a newer version of gzip to pass its tests
# texinfo is used by many programs to install the info files
#
# gettext needs a new librt, librt comes from glibc, glibc needs a kernel greater than 2.6.19
# gettext should follow xz
# we need to compile gettext then libiconv then gettext again
#
# Good repositories:
# https://ftp.gnu.org/pub/gnu/
# ftp://ftp.kernel.org/pub/linux/
#

define LNBIN
	test -f /usr/bin/$1 || /usr/bin/sudo ln -s /usr/local/bin/$1 /usr/bin/.
endef

# call LNLIB libssp.a
define LNLIB
	test -f /lib/$1 || /usr/bin/sudo ln -s /usr/local/lib/$1 /lib/.
endef

define MKVRFYDIR
	mkdir -p --verbose $1
	cd $1; readlink -f . | grep $1
endef

define SOURCEDIR
	$(call MKVRFYDIR,$1)
	cd $1; find . -maxdepth 1 -type d -name $1\* -print -exec /bin/rm -rf {} \;
	cd $1; tar $2 $1*.tar* || tar $2 $1*.tgz
	cd $1; /bin/rm -f untar.dir
	cd $1; find . -maxdepth 1 -type d -name $1\* -print > untar.dir
	cd $1/`cat $1/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
endef

define SOURCEWGET
	$(call MKVRFYDIR,$1)
	cd $1; find . -maxdepth 1 -type d -name $1\* -print -exec /bin/rm -rf {} \;
	-cd $1; /bin/rm -f `basename $2`
	cd $1; wget --no-check-certificate $2
endef

define CPLIB
	cd /usr/local/lib; for FILE in $1; do if test -e /usr/local/lib/$$FILE ; then test -f /lib/$$FILE || test -L /lib/$$FILE || /usr/bin/sudo ln -s /usr/local/lib/$$FILE /lib/. ; fi ; done
endef

define RENEXE
	cd /usr/local/bin; for FILE in $1; do if test -e /usr/local/bin/$$FILE; then export n=0; while test -e /usr/local/bin/$$FILE.old.$$n ; do export n=$$((n+1)); done ; sudo mv $$FILE $$FILE.old.$$n ; fi ; done
endef

define PKGINSTALLTO
	cd $1/$2/; /usr/bin/sudo make install
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/packaged
	cd $1/$2/; /usr/bin/sudo make DESTDIR=/tmp/stage install
	/bin/mkdir -p packages
	cd $1/$2/; /usr/bin/sudo tar -C /tmp/stage -czf /tmp/packaged/$1.tar.gz .
	/bin/rm -f packages/$1.tar.gz
	/bin/cp /tmp/packaged/$1.tar.gz packages
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
	@echo "======= Build of $1 Successful ======="
endef

define PKGINSTALL
	$(call PKGINSTALLTO,$1,`cat $1/untar.dir`)
endef

define PKGINSTALLBUILD
	$(call PKGINSTALLTO,$1,$1-build)
endef

.PHONY: all
all: target_test check_sudo make gzip tar xz texinfo binutils coreutils grep findutils diffutils which \
     symlinks m4 ecj gmp mpfr mpc libelf flex gawk libtool sed \
     zlib bzip sqlite aftersqlite

.PHONY: target_test
target_test:
	/bin/echo $$LD_LIBRARY_PATH

.PHONY: aftersqlite
aftersqlite: gcc aftergcc

# db needs C++
# lzma needs C++
.PHONY: aftergcc
aftergcc: db lzma gdbm gettext libiconv gettext \
     Python afterpython

.PHONY: afterpython
afterpython: perl openssl \
     Archive-Zip Digest-SHA1 Scalar-MoreUtils URI HTML-Tagset HTML-Parser \
     Devel-Symdump Pod-Coverage Test-Pod Test-Pod-Coverage Net-SSLeay \
     IO-Socket-SSL \
     libwww-perl \
     bison libunistring libffi gc guile afterguile

.PHONY: afterguile
afterguile: autogen \
     tcl tclx expect dejagnu wget libgpg-error libgcrypt libassuan libksba \
     pth gnupg \
     bash expat apr apr-util \
     pcre pkg-config glib lua ruby ncurses vim aftervim

.PHONY: aftervim
aftervim: cppcheck libpcap \
    jnettop scrypt bcrypt \
    curl wipe srm util-linux-ng libxml2 afterlibxml2

.PHONY: afterlibxml2
afterlibxml2: fuse ntfs-3g check file \
    scons afterscons

.PHONY: afterscons
afterscons: serf protobuf mosh \
    llvm socat screen autossh inetutils \
    subversion autoconf automake swig gdb

# These will mess themselves up in the build process when they try to install, because
# the shared libraries are being used for the install
# Use the stock compiler to install them into /usr/local
oldcompiler: attr acl

.PHONY: foo
foo:
	$(call RENEXE,autossh)

.PHONY: check_sudo
check_sudo:
	/usr/bin/sudo echo sudo check

# Standard build with separate build directory
# make check is automatically built by automake
# so we will try that target first
.PHONY: gawk
.PHONY: gzip
.PHONY: m4
.PHONY: pth
.PHONY: sed
.PHONY: tar
.PHONY: texinfo
.PHONY: xz
texinfo gawk m4 sed gzip xz tar pth:
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

# Standard build in the source directory
.PHONY: scrypt
.PHONY: swig
.PHONY: zlib
scrypt swig zlib:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

# Post tar rule, we should have a good version of tar that automatically detects file type
.PHONY: apr
.PHONY: autoconf
.PHONY: automake
.PHONY: diffutils
.PHONY: findutils
.PHONY: grep
.PHONY: libffi
.PHONY: libgcrypt
.PHONY: libgpg-error
.PHONY: libassuan
.PHONY: libksba
.PHONY: which
apr autoconf automake diffutils findutils grep libffi libgcrypt libgpg-error libassuan libksba which:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory
.PHONY: jnettop libxml2 check file protobuf
jnettop libxml2 check file protobuf:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory, no make check || make test
# we should have a good version of tar that automatically detects file type
# gnupg does not have instructions for testing
.PHONY: curl gnupg mosh srm wipe autossh socat screen
curl gnupg srm wipe mosh autossh socat screen:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# autossh may be in use
	$(call RENEXE,autossh)
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No make check || make test
# bison fails the glibc version test, we have too old of a GLIBC
# lmza fails the glibc version test, we have too old of a GLIBC
# libunistring fails one test of 418, that appears to be because we are linking to an old librt in GLIBC
# libpcap does not appear to have any tests
# tcpdump fails on PPOE
.PHONY: autogen
.PHONY: bison
.PHONY: gettext
.PHONY: libpcap
.PHONY: libunistring
.PHONY: lzma
.PHONY: make
.PHONY: sqlite
.PHONY: tcpdump
make libpcap sqlite gettext lzma bison libunistring autogen tcpdump:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

# No configure and no make check || make test
.PHONY: bcrypt
.PHONY: bzip
.PHONY: symlinks
bcrypt bzip symlinks:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

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
Archive-Zip Digest-SHA1 Scalar-MoreUtils URI HTML-Tagset HTML-Parser IO-Socket-SSL Devel-Symdump Pod-Coverage Test-Pod Test-Pod-Coverage libwww-perl:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; perl Makefile.PL
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make check || make test
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
acl:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; INSTALL_USER=root INSTALL_GROUP=root ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install install-dev install-lib
	$(call CPLIB,lib$@*)
	@echo "======= Build of $@ Successful ======="

.PHONY: apr-util
apr-util:
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
attr:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; INSTALL_USER=root INSTALL_GROUP=root ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install install-dev install-lib
	/bin/rm /lib/libattr.la
	$(call CPLIB,lib$@*)
	@echo "======= Build of $@ Successful ======="

.PHONY: bash
bash:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --bindir=/usr/local/bin --htmldir=/usr/local/share/doc/bash-4.2 --without-bash-malloc
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

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
binutils:
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@; sed -i -e 's/@colophon/@@colophon/' -e 's/doc@cygnus.com/doc@@cygnus.com/' `cat untar.dir`/bfd/doc/bfd.texinfo
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; exec make check
	$(call PKGINSTALLBUILD,$@)

.PHONY: clisp
clisp:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --ignore-absence-of-libsigsegv
	cd $@/`cat $@/untar.dir`/src; make
	-cd $@/`cat $@/untar.dir`/src; make test || make check
	$(call PKGINSTALLTO,$@,`cat $@/untar.dir`/src)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: coreutils
coreutils:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --enable-install-program=hostname
	cd $@/$@-build/; make
	# Timeout test failed, I think it is the same forking pthread librt
	# problem I am getting in other tests
	# cd $@/$@-build/; make RUN_EXPENSIVE_TESTS=yes check
	$(call PKGINSTALLBUILD,$@)

.PHONY: cppcheck
cppcheck:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make HAVE_RULES=yes
	$(call PKGINSTALL,$@)

.PHONY: dejagnu
dejagnu:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; mkdir dejagnu
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; makeinfo --plaintext  -o doc/dejagnu.txt doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -dm755 /usr/local/share/doc/dejagnu-1.5.1
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -m644 doc/dejagnu.{html,txt} /usr/local/share/doc/dejagnu-1.5.1
	$(call PKGINSTALL,$@)

.PHONY: ecj
ecj:
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
	$(call LNLIB,libexpat.a)
	$(call LNLIB,libexpat.la)
	$(call LNLIB,libexpat.so)
	$(call LNLIB,libexpat.so.1)
	$(call LNLIB,libexpat.so.1.6.0)

.PHONY: expect
expect:
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

.PHONY: fuse
fuse:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# No test suite for fuse
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)


.PHONY: httpd
httpd:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --enable-mods-shared="all cgi" \
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
gc:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-gc-debug --enable-gc-assertions
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@.*)

.PHONY: gcc
gcc:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`; tar xf ../../mpfr/mpfr*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpfr-* mpfr
	cd $@/`cat $@/untar.dir`; tar xf ../../gmp/gmp*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf gmp-* gmp
	cd $@/`cat $@/untar.dir`; tar xf ../../mpc/mpc*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpc-* mpc
	cd $@/`cat $@/untar.dir`; cp ../../ecj/ecj*.jar ./ecj.jar
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    --prefix=/usr/local \
                    --enable-languages=c,c++,fortran,java,objc,obj-c++ \
		    --with-ecj-jar=/usr/local/share/java/ecj.jar
	cd $@/$@-build/; make
	-cd $@/$@-build/; C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib make check
	-ln -s /usr/local/bin/gcc /usr/local/bin/cc
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

.PHONY: inetutils
inetutils:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local  \
	        --localstatedir=/usr/local/var   \
		--disable-logger       \
		--disable-syslogd      \
		--disable-whois        \
		--disable-servers
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make test || make check
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libiconv
libiconv:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call LNLIB,libiconv.la)
	$(call LNLIB,libiconv.so)
	$(call LNLIB,libiconv.so.2)
	$(call LNLIB,libiconv.so.2.5.1)

# No make check || make test
# libtool is going to fail Fortran checks, we need a new autoconf and automake, these depend on perl
.PHONY: libtool
libtool:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libltdl*)

.PHONY: lua
lua:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
	cd $@/`cat $@/untar.dir`/; make linux MYLIBS=-lncurses
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; sudo make INSTALL_TOP=/usr/local \
	    TO_LIB="liblua.a" \
	     INSTALL_DATA="cp -d" INSTALL_MAN=/usr/share/man/man1 install
	cd $@/`cat $@/untar.dir`/; sudo mkdir -pv /usr/local/share/doc/lua-5.2.3
	cd $@/`cat $@/untar.dir`/; sudo cp -v doc/*.{html,css,gif,png} /usr/local/share/doc/lua-5.2.3
	@echo "======= Build of $@ Successful ======="

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

.PHONY: gdb
gdb:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
# tests fail, including the test driver
	# cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: glib
glib:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-internal-glib --with-libiconv=gnu --with-pcre=system
	cd $@/`cat $@/untar.dir`/; CFLAGS=-I/usr/local/include LDFLAGS="-L/usr/local/lib -liconv -lz" make
	# Can not run check until desktop-file-utils are installed
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

# CFLAGS="-march=i686 -g -O2 -fno-stack-protector"
.PHONY: glibc
glibc:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	# cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --enable-kernel=2.6.32 --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include CFLAGS="-march=i686 -g -O2 -fno-stack-protector"
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include CFLAGS="-march=i686 -g -O2 -fno-stack-protector"
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: gmp
gmp:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

# guile is needed by autogen
.PHONY: guile
guile:
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

# If the install generates a unable to infer compiler target triple for gcc,
# the sudo needs a ./SETUP.bash before running it.
.PHONY: llvm
llvm:
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
mpc:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local --with-gmp=/usr/local --with-mpfr=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: mpfr
mpfr:
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

.PHONY: ntfs-3g
ntfs-3g:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# There is no test suite for ntfs-3g
	$(call PKGINSTALL,$@)

.PHONY: openssl
openssl:
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
pcre:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-unicode-properties \
	    --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 \
	    --enable-pcretest-libreadline
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: Python
Python:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python2.7 setup.py install

.PHONY: perl
perl:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sh Configure -de
	cd $@/`cat $@/untar.dir`/; make
	# Most of the tests succeed, except threading, socket, 3 tests out of 2255
	# cd $@/`cat $@/untar.dir`/; make check || make test
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

.PHONY: ruby
ruby:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make LDFLAGS="-L/usr/local/lib -lssp" install
	@echo "======= Build of $@ Successful ======="

.PHONY: serf
serf:
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
scons:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py install \
	    --prefix=/usr/local  --standard-lib --optimize=1 --install-data=/usr/share
	@echo "======= Build of $@ Successful ======="

.PHONY: subversion
subversion:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local  \
	        --with-apache-libexecdir
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make test || make check
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)
.PHONY: tcl
tcl:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/unix; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/unix; make
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

.PHONY: util-linux
util-linux:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-arch --enable-partx --enable-write
	# cd $@/`cat $@/untar.dir`/; make CFLAGS=-DO_CLOEXEC=0
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

.PHONY: util-linux-ng
util-linux-ng:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-arch --enable-partx --enable-write
	# cd $@/`cat $@/untar.dir`/; make CFLAGS=-DO_CLOEXEC=0
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libuuid*)

.PHONY: vim
vim:
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-perlinterp --enable-pythoninterp --enable-tclinterp --enable-rubyinterp
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-pythoninterp --enable-tclinterp --enable-rubyinterp --with-x --enable-gui
	cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C make
	cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C make test || LANG=C LC_ALL=C make check
	$(call PKGINSTALL,$@)

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
wget-all: wget-apr wget-apr-util wget-autossh wget-bcrypt \
    wget-binutils \
    wget-check wget-clisp wget-cppcheck wget-curl \
    wget-file wget-httpd wget-inetutils wget-gdbm wget-jnettop \
    wget-libpcap wget-libxml2 wget-lua wget-make \
    wget-openssl \
    wget-pcre wget-protobuf wget-mosh wget-ntfs-3g \
    wget-ncurses wget-scons wget-serf wget-socat \
    wget-scrypt wget-srm wget-subversion wget-util-linux \
    wget-util-linux-ng wget-which wget-wipe

.PHONY: wget-apr
wget-apr:
	$(call SOURCEWGET,"apr","http://archive.apache.org/dist/apr/apr-1.4.8.tar.bz2")

.PHONY: wget-apr-util
wget-apr-util:
	$(call SOURCEWGET,"apr-util","http://archive.apache.org/dist/apr/apr-util-1.5.3.tar.bz2")

.PHONY: wget-autoconf
wget-autoconf:
	$(call SOURCEWGET,"autoconf","http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz")

.PHONY: wget-automake
wget-automake:
	$(call SOURCEWGET,"automake","http://ftp.gnu.org/gnu/automake/automake-1.14.tar.xz")

.PHONY: wget-autossh
wget-autossh:
	$(call SOURCEWGET,"autossh","http://www.harding.motd.ca/autossh/autossh-1.4c.tgz")

.PHONY: wget-bcrypt
wget-bcrypt:
	$(call SOURCEWGET,"bcrypt","http://bcrypt.sourceforge.net/bcrypt-1.1.tar.gz")

.PHONY: wget-binutils
wget-binutils:
	# (call SOURCEWGET,"binutils","http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.gz")
	$(call SOURCEWGET,"binutils","http://ftp.gnu.org/gnu/binutils/binutils-2.23.2.tar.gz")

.PHONY: wget-cppcheck
wget-cppcheck:
	$(call SOURCEWGET,"cppcheck","http://downloads.sourceforge.net/project/cppcheck/cppcheck/1.65/cppcheck-1.65.tar.bz2")

.PHONY: wget-check
wget-check:
	$(call SOURCEWGET,"check","http://downloads.sourceforge.net/project/check/check/0.9.12/check-0.9.12.tar.gz")

.PHONY: wget-clang
wget-clang:
	$(call SOURCEWGET,"clang","http://llvm.org/releases/3.4/clang-3.4.src.tar.gz")

.PHONY: wget-clisp
wget-clisp:
	$(call SOURCEWGET,"clisp","http://ftp.gnu.org/pub/gnu/clisp/latest/clisp-2.49.tar.gz")

.PHONY: wget-compiler-rt
wget-compiler-rt:
	$(call SOURCEWGET,"compiler-rt","http://llvm.org/releases/3.4/compiler-rt-3.4.src.tar.gz")

.PHONY: wget-curl
wget-curl:
	$(call SOURCEWGET,"curl","http://curl.haxx.se/download/curl-7.33.0.tar.bz2")

.PHONY: wget-ecj
wget-ecj:
	$(call SOURCEWGET,"ecj","ftp://sourceware.org/pub/java/ecj-latest.jar")

.PHONY: wget-file
wget-file:
	$(call SOURCEWGET,"file","ftp://ftp.astron.com/pub/file/file-5.17.tar.gz")

.PHONY: wget-fuse
wget-fuse:
	$(call SOURCEWGET,"fuse","http://downloads.sourceforge.net/fuse/fuse-2.9.3.tar.gz")

.PHONY: wget-gdbm
wget-gdbm:
	$(call SOURCEWGET,"gdbm","ftp://ftp.gnu.org/gnu/gdbm/gdbm-1.10.tar.gz")

.PHONY: wget-httpd
wget-httpd:
	$(call SOURCEWGET,"httpd","http://archive.apache.org/dist/httpd/httpd-2.4.7.tar.bz2")

.PHONY: wget-inetutils
wget-inetutils:
	$(call SOURCEWGET,"inetutils","http://ftp.gnu.org/gnu/inetutils/inetutils-1.9.tar.gz")

.PHONY: wget-libpcap
wget-libpcap:
	$(call SOURCEWGET,"libpcap","http://www.tcpdump.org/release/libpcap-1.4.0.tar.gz")

.PHONY: wget-libxml2
wget-libxml2:
	$(call SOURCEWGET,"libxml2","http://xmlsoft.org/sources/libxml2-2.9.1.tar.gz")

.PHONY: wget-llvm
wget-llvm:
	$(call SOURCEWGET,"llvm","http://llvm.org/releases/3.4/llvm-3.4.src.tar.gz")

.PHONY: wget-lua
wget-lua:
	$(call SOURCEWGET,"lua","http://www.lua.org/ftp/lua-5.2.3.tar.gz")

.PHONY: wget-make
wget-make:
	$(call SOURCEWGET,"make","http://ftp.gnu.org/gnu/make/make-4.0.tar.gz")

.PHONY: wget-jnettop
wget-jnettop:
	$(call SOURCEWGET,"jnettop","http://jnettop.kubs.info/dist/jnettop-0.13.0.tar.gz")

.PHONY: wget-mosh
wget-mosh:
	$(call SOURCEWGET,"mosh","http://mosh.mit.edu/mosh-1.2.4.tar.gz")

.PHONY: wget-ncurses
wget-ncurses:
	$(call SOURCEWGET,"ncurses","http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz")

.PHONY: wget-ntfs-3g
wget-ntfs-3g:
	$(call SOURCEWGET,"ntfs-3g","http://tuxera.com/opensource/ntfs-3g_ntfsprogs-2013.1.13.tgz")

.PHONY: wget-openssl
wget-openssl:
	$(call SOURCEWGET,"openssl","http://www.openssl.org/source/openssl-1.0.1g.tar.gz")

.PHONY: wget-pcre
wget-pcre:
	$(call SOURCEWGET,"pcre","https://sourceforge.net/projects/pcre/files/pcre/8.34/pcre-8.34.tar.gz")

.PHONY: wget-protobuf
wget-protobuf:
	$(call SOURCEWGET,"protobuf", "https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2")

.PHONY: wget-scons
wget-scons:
	$(call SOURCEWGET, "scons", "http://downloads.sourceforge.net/scons/scons-2.3.0.tar.gz")

.PHONY: wget-screen
wget-screen:
	$(call SOURCEWGET,"screen","http://ftp.gnu.org/gnu/screen/screen-4.2.1.tar.gz")

.PHONY: wget-scrypt
wget-scrypt:
	$(call SOURCEWGET, "scrypt","http://www.tarsnap.com/scrypt/scrypt-1.1.6.tgz")

.PHONY: wget-serf
wget-serf:
	$(call SOURCEWGET, "serf", "http://serf.googlecode.com/svn/src_releases/serf-1.3.5.tar.bz2")

.PHONY: wget-subversion
wget-subversion:
	$(call SOURCEWGET,"subversion","http://www.apache.org/dist/subversion/subversion-1.8.9.tar.bz2")

.PHONY: wget-symlinks
wget-symlinks:
	$(call SOURCEWGET,"symlinks","http://pkgs.fedoraproject.org/repo/pkgs/symlinks/symlinks-1.4.tar.gz/c38ef760574c25c8a06fd2b5b141307d/symlinks-1.4.tar.gz")

.PHONY: wget-socat
wget-socat:
	$(call SOURCEWGET, "socat", "http://www.dest-unreach.org/socat/download/socat-1.7.2.2.tar.bz2")

.PHONY: wget-srm
wget-srm:
	$(call SOURCEWGET,"srm","http://sourceforge.net/projects/srm/files/srm/1.2.11/srm-1.2.11.tar.bz2")

.PHONY: wget-swig
wget-swig:
	# (call SOURCEWGET,"swig","http://downloads.sourceforge.net/swig/swig-2.0.11.tar.gz")
	$(call SOURCEWGET,"swig","http://prdownloads.sourceforge.net/swig/swig-3.0.0.tar.gz")

.PHONY: wget-tar
wget-tar:
	$(call SOURCEWGET,"tar","http://ftp.gnu.org/gnu/tar/tar-1.27.tar.gz")

.PHONY: wget-tcpdump
wget-tcpdump:
	$(call SOURCEWGET, "tcpdump","http://www.tcpdump.org/release/tcpdump-4.5.1.tar.gz")

.PHONY: wget-util-linux
wget-util-linux:
	$(call SOURCEWGET,"util-linux","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz")

.PHONY: wget-util-linux-ng
wget-util-linux-ng:
	$(call SOURCEWGET,"util-linux-ng","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.18/util-linux-ng-2.18.tar.xz")

.PHONY: wget-which
wget-which:
	$(call SOURCEWGET,"which","https://ftp.gnu.org/pub/gnu/which/which-2.20.tar.gz")

.PHONY: wget-wipe
wget-wipe:
	$(call SOURCEWGET,"wipe","http://sourceforge.net/projects/wipe/files/wipe/2.3.1/wipe-2.3.1.tar.bz2")
# 
# call SOURCEWGET,"wipe","http://lambda-diode.com/resources/wipe/wipe-0.22.tar.gz"

.PHONY: wget-xz
wget-xz:
	$(call SOURCEWGET,"xz","http://tukaani.org/xz/xz-5.0.5.tar.gz")

