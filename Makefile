
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
	cd $1; tar $2 $1*.tar* || tar $2 $1*.tgz || tar $2 $1*.tar || tar xf $1*.tar*
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
define MAKECERT
#!/usr/bin/perl -w

# Used to generate PEM encoded files from Mozilla certdata.txt.
# Run as ./make-cert.pl > certificate.crt
#
# Parts of this script courtesy of RedHat (mkcabundle.pl)
#
# This script modified for use with single file data (tempfile.cer) extracted
# from certdata.txt, taken from the latest version in the Mozilla NSS source.
# mozilla/security/nss/lib/ckfw/builtins/certdata.txt
#
# Authors: DJ Lucas
#          Bruce Dubbs
#
# Version 20120211

my $$certdata = './tempfile.cer';

open( IN, "cat $$certdata|" )
    || die "could not open $$certdata";

my $$incert = 0;

while ( <IN> )
{
    if ( /^CKA_VALUE MULTILINE_OCTAL/ )
    {
        $$incert = 1;
        open( OUT, "|openssl x509 -text -inform DER -fingerprint" )
            || die "could not pipe to openssl x509";
    }

    elsif ( /^END/ && $$incert )
    {
        close( OUT );
        $$incert = 0;
        print "\n\n";
    }

    elsif ($$incert)
    {
        my @bs = split( /\\/ );
        foreach my $$b (@bs)
        {
            chomp $$b;
            printf( OUT "%c", oct($$b) ) unless $$b eq '';
        }
    }
}
endef

define MAKECA
#!/bin/sh
# Begin make-ca.sh
# Script to populate OpenSSL's CApath from a bundle of PEM formatted CAs
#
# The file certdata.txt must exist in the local directory
# Version number is obtained from the version of the data.
#
# Authors: DJ Lucas
#          Bruce Dubbs
#
# Version 20120211

certdata="certdata.txt"

if [ ! -r $$certdata ]; then
  echo "$$certdata must be in the local directory"
  exit 1
fi

REVISION=$$(grep CVS_ID $$certdata | cut -f4 -d'$$')

if [ -z "$${REVISION}" ]; then
  echo "$$certfile has no 'Revision' in CVS_ID"
  exit 1
fi

VERSION=$$(echo $$REVISION | cut -f2 -d" ")

TEMPDIR=$$(mktemp -d)
TRUSTATTRIBUTES="CKA_TRUST_SERVER_AUTH"
BUNDLE="BLFS-ca-bundle-$${VERSION}.crt"
CONVERTSCRIPT="./make-cert.pl"
SSLDIR="/usr/local/etc/ssl"

mkdir "$${TEMPDIR}/certs"

# Get a list of starting lines for each cert
CERTBEGINLIST=$$(grep -n "^# Certificate" "$${certdata}" | cut -d ":" -f1)

# Get a list of ending lines for each cert
CERTENDLIST=`grep -n "^CKA_TRUST_STEP_UP_APPROVED" "$${certdata}" | cut -d ":" -f 1`

# Start a loop
for certbegin in $${CERTBEGINLIST}; do
  for certend in $${CERTENDLIST}; do
    if test "$${certend}" -gt "$${certbegin}"; then
      break
    fi
  done

  # Dump to a temp file with the name of the file as the beginning line number
  sed -n "$${certbegin},$${certend}p" "$${certdata}" > "$${TEMPDIR}/certs/$${certbegin}.tmp"
done

unset CERTBEGINLIST CERTDATA CERTENDLIST certbegin certend

mkdir -p certs
rm -f certs/*      # Make sure the directory is clean

for tempfile in $${TEMPDIR}/certs/*.tmp; do
  # Make sure that the cert is trusted...
  grep "CKA_TRUST_SERVER_AUTH" "$${tempfile}" | egrep "TRUST_UNKNOWN|NOT_TRUSTED" > /dev/null

  if test "$${?}" = "0"; then
    # Throw a meaningful error and remove the file
    cp "$${tempfile}" tempfile.cer
    perl $${CONVERTSCRIPT} > tempfile.crt
    keyhash=$$(openssl x509 -noout -in tempfile.crt -hash)
    echo "Certificate $${keyhash} is not trusted!  Removing..."
    rm -f tempfile.cer tempfile.crt "$${tempfile}"
    continue
  fi

  # If execution made it to here in the loop, the temp cert is trusted
  # Find the cert data and generate a cert file for it

  cp "$${tempfile}" tempfile.cer
  perl $${CONVERTSCRIPT} > tempfile.crt
  keyhash=$$(openssl x509 -noout -in tempfile.crt -hash)
  mv tempfile.crt "certs/$${keyhash}.pem"
  rm -f tempfile.cer "$${tempfile}"
  echo "Created $${keyhash}.pem"
done

# Remove blacklisted files
# MD5 Collision Proof of Concept CA
if test -f certs/8f111d69.pem; then
  echo "Certificate 8f111d69 is not trusted!  Removing..."
  rm -f certs/8f111d69.pem
fi

# Finally, generate the bundle and clean up.
cat certs/*.pem >  $${BUNDLE}
rm -r "$${TEMPDIR}"
endef

define REMOVECA
#!/bin/sh
# Begin /usr/bin/remove-expired-certs.sh
#
# Version 20120211

# Make sure the date is parsed correctly on all systems
mydate()
{
  local y=$$( echo $$1 | cut -d" " -f4 )
  local M=$$( echo $$1 | cut -d" " -f1 )
  local d=$$( echo $$1 | cut -d" " -f2 )
  local m

  if [ $${d} -lt 10 ]; then d="0$${d}"; fi

  case $$M in
    Jan) m="01";;
    Feb) m="02";;
    Mar) m="03";;
    Apr) m="04";;
    May) m="05";;
    Jun) m="06";;
    Jul) m="07";;
    Aug) m="08";;
    Sep) m="09";;
    Oct) m="10";;
    Nov) m="11";;
    Dec) m="12";;
  esac

  certdate="$${y}$${m}$${d}"
}

OPENSSL=/usr/bin/openssl
SSLDIR=/usr/local/etc/ssl/certs

if [ $$# -gt 0 ]; then
  SSLDIR="$$1"
fi

certs=$$( find $${SSLDIR} -type f -name "*.pem" -o -name "*.crt" )
today=$$( date +%Y%m%d )

for cert in $$certs; do
  notafter=$$( $$OPENSSL x509 -enddate -in "$${cert}" -noout )
  date=$$( echo $${notafter} |  sed 's/^notAfter=//' )
  mydate "$$date"

  if [ $${certdate} -lt $${today} ]; then
     echo "$${cert} expired on $${certdate}! Removing..."
     rm -f "$${cert}"
  fi
done
endef

.PHONY: all
all: target_test target_dirs \
     check_sudo make gzip tar xz perl texinfo binutils \
     coreutils grep findutils diffutils which \
     symlinks m4 ecj gmp mpfr mpc libelf flex gawk libtool sed \
     zlib bzip sqlite zip unzip aftersqlite

.PHONY: target_test
target_test:
	/bin/echo $$LD_LIBRARY_PATH

.PHONY: target_dirs
target_dirs:
	sudo mkdir -p /usr/local/bin
	sudo mkdir -p /usr/local/etc
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

.PHONY: aftersqlite
aftersqlite: guile gcc aftergcc

# db needs C++
# lzma needs C++
.PHONY: aftergcc
aftergcc: db lzma gdbm gettext libiconv gettext \
     Python afterpython

# run ca-cert twice. The shell scripts are sloppy. They want to manipulate
# the previously installed certs

.PHONY: afterpython
afterpython: ca-cert ca-cert openssl \
     Archive-Zip Digest-SHA1 Scalar-MoreUtils URI HTML-Tagset HTML-Parser \
     Devel-Symdump Pod-Coverage Test-Pod Test-Pod-Coverage Net-SSLeay \
     IO-Socket-SSL \
     libwww-perl \
     bison libunistring libffi gc afterguile

.PHONY: afterguile
afterguile: autogen tcl tclx \
     expect dejagnu wget libgpg-error libgcrypt libassuan libksba \
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
    llvm socat screen libevent tmux autossh inetutils \
    swig httpd subversion git autoconf glibc \
    automake truecrypt gdb

# These will mess themselves up in the build process when they try to install, because
# the shared libraries are being used for the install
# Use the stock compiler to install them into /usr/local
oldcompiler: check_sudo attr acl

.PHONY: foo
foo:
	$(call RENEXE,autossh)

.PHONY: check_sudo
.PHONY: sudo
check_sudo sudo:
	/usr/bin/sudo echo sudo check

# Standard build with separate build directory
# make check is automatically built by automake
# so we will try that target first
.PHONY: gawk
.PHONY: m4
.PHONY: pth
.PHONY: sed
.PHONY: tar
.PHONY: texinfo
.PHONY: xz
texinfo gawk m4 sed xz tar pth:
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

# Standard build in the source directory
#
# We need to build gettext, then iconv, then gettext again
# The second time we build it, the tests will work, so
# we check for the presence of gettext in /usr/local/bin
# before we try to run the tests
#
.PHONY: scrypt gettext
gettext scrypt:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; test ! -e /usr/local/bin/gettext || make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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
.PHONY: jnettop libevent libxml2 check file protobuf curl
curl jnettop libevent libxml2 check file protobuf:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Post tar rule, no build directory, no make check || make test, no test
# we should have a good version of tar that automatically detects file type
# gnupg does not have instructions for testing
.PHONY: gnupg mosh srm wipe autossh socat screen tmux
gnupg srm wipe mosh autossh socat screen tmux:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# autossh may be in use
	$(call RENEXE,autossh)
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
.PHONY: libunistring
.PHONY: lzma
.PHONY: make
.PHONY: sqlite
.PHONY: tcpdump
make libpcap sqlite lzma bison libunistring autogen tcpdump:
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
	/usr/bin/sudo /bin/rm -f /lib/libattr.la
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

export MAKECERT
export MAKECA
export REMOVECA
.PHONY: ca-cert
ca-cert:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /bin/rm -f make-cert.pl
	cd $@/`cat $@/untar.dir`/; echo "$$MAKECERT" >> make-cert.pl
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./make-cert.pl
	cd $@/`cat $@/untar.dir`/; echo "$$MAKECA" >> make-ca.sh
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./make-ca.sh
	cd $@/`cat $@/untar.dir`/; echo "$$REMOVECA" >> remove-expired-certs.sh
	cd $@/`cat $@/untar.dir`/; /bin/chmod +x ./remove-expired-certs.sh
	cd $@/`cat $@/untar.dir`/; ./make-ca.sh
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./remove-expired-certs.sh
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -d /usr/local/etc/ssl/certs
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -v certs/*.pem /usr/local/etc/ssl/certs
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo c_rehash
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install BLFS-ca-bundle*.crt /usr/local/etc/ssl/ca-bundle.crt
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /bin/rm -f /usr/local/etc/ssl/certs/ca-certificates.crt
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ln -s /usr/local/etc/ssl/ca-bundle.crt /usr/local/etc/ssl/certs/ca-certificates.crt

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
	-cd $@/`cat $@/untar.dir`/src; make check || make test
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
	@echo "======= One test will fail ======="
	-cd $@/$@-build/; make RUN_EXPENSIVE_TESTS=yes check
	@echo "======= One test will fail ======="
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
	# this will let us build glibc
	# cd $@/`cat $@/untar.dir`; sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    --prefix=/usr/local \
                    --enable-languages=c,c++,fortran,java,objc,obj-c++ \
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

# May not have gzip functionality in tar when we try to build gzip
.PHONY: gzip
gzip:
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
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
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libiconv
libiconv:
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

#
# NetPBM packages itself in a a non-standard way into /tmp/netpbm, so
# we can not use our standard package installation script
#
export NETPBMCONFIG
.PHONY: netpbm
netpbm:
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
	$(call LNLIB,libnetpbm.a)

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

# From the GIT Makefile
#
# Define SHELL_PATH to a POSIX shell if your /bin/sh is broken.
#
# Define SANE_TOOL_PATH to a colon-separated list of paths to prepend
# to PATH if your tools in /usr/bin are broken.
# 
.PHONY: git
git:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" ./configure --prefix=/usr/local --with-gitconfig=/usr/local/etc/gitconfig --with-libpcre
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libz.*)

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
	cd $@/$@-build/; CFLAGS="-fno-stack-protector -O2" ../`cat ../untar.dir`/configure --prefix=/usr/local/glibc --disable-profile --libexecdir=/usr/local/lib/glibc --with-headers=/usr/local/include -without-selinux CFLAGS="-fno-stack-protector -march=i686 -O2"
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	-sudo mkdir -p /usr/local/glibc/etc
	sudo touch /usr/local/glibc/etc/ld.so.conf
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
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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

.PHONY: sparse
sparse:
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALLPREFIX,$@)

.PHONY: subversion
subversion:
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
swig:
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure
	cd $@/`cat $@/untar.dir`/; make
	# java can not find a class it is looking for in
	# the test cases
	-$(call PKGCHECK,$@)
	$(call PKGINSTALL,$@)


.PHONY: tcl
tcl:
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

.PHONY: truecrypt
truecrypt:
	$(call SOURCEDIR,$@,xf)

.PHONY: unzip
unzip:
	$(call SOURCEDIR,$@,zip)
	cd $@/`cat $@/untar.dir`/; sed -i -e 's/CFLAGS="-O -Wall/& -DNO_LCHMOD/' unix/Makefile
	cd $@/`cat $@/untar.dir`/; make -f unix/Makefile linux_noasm
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local MANDIR=/usr/local/man/man1 -f unix/Makefile install
	@echo "======= Build of $@ Successful ======="

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

.PHONY: zip
zip:
	$(call SOURCEDIR,$@,zip)
	cd $@/`cat $@/untar.dir`/; make -f unix/Makefile generic_gcc
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local MANDIR=/usr/local/man/man1 -f unix/Makefile install
	@echo "======= Build of $@ Successful ======="

.PHONY: zlib
zlib:
	$(call SOURCEDIR,$@,xfz)
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
wget-all: wget-apr wget-apr-util wget-autossh \
    wget-bash wget-bcrypt \
    wget-binutils \
    wget-ca-cert \
    wget-check wget-clisp wget-coreutils \
    wget-cppcheck wget-curl \
    wget-file wget-gettext wget-git \
    wget-gzip wget-glibc wget-httpd wget-inetutils \
    wget-gdbm wget-jnettop \
    wget-libevent \
    wget-libiconv \
    wget-libpcap wget-libxml2 wget-lua wget-make \
    wget-netpbm \
    wget-openssl \
    wget-pcre wget-protobuf wget-mosh wget-ntfs-3g \
    wget-ncurses wget-scons wget-serf \
    wget-scrypt wget-socat wget-sparse \
    wget-srm wget-subversion wget-tar \
    wget-tcl \
    wget-texinfo wget-tmux \
    wget-truecrypt wget-unzip wget-util-linux \
    wget-util-linux-ng wget-vim \
    wget-which wget-wipe \
    wget-xz wget-zip \
    wget-zlib

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

.PHONY: wget-bash
wget-bash:
	$(call SOURCEWGET,"bash","https://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz")

.PHONY: wget-bcrypt
wget-bcrypt:
	$(call SOURCEWGET,"bcrypt","http://bcrypt.sourceforge.net/bcrypt-1.1.tar.gz")

.PHONY: wget-binutils
wget-binutils:
	# (call SOURCEWGET,"binutils","http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.gz")
	$(call SOURCEWGET,"binutils","http://ftp.gnu.org/gnu/binutils/binutils-2.23.2.tar.gz")

.PHONY: wget-ca-cert
wget-ca-cert:
	$(call SOURCEWGET,"ca-cert","http://anduin.linuxfromscratch.org/sources/other/certdata.txt")
	cd ca-cert; mkdir -p ca-cert-1.0
	cd ca-cert; mv certdata.txt ca-cert-1.0
	cd ca-cert; tar cfJ ca-cert-1.0.tar.gz ./ca-cert-1.0

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

.PHONY: wget-coreutils
wget-coreutils:
	$(call SOURCEWGET,"coreutils","http://ftp.gnu.org/gnu/coreutils/coreutils-8.22.tar.xz")

.PHONY: wget-curl
wget-curl:
	$(call SOURCEWGET,"curl","http://curl.haxx.se/download/curl-7.40.0.tar.bz2")

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

.PHONY: wget-gettext
wget-gettext:
	$(call SOURCEWGET,"gettext","http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.1.tar.gz")

.PHONY: wget-git
wget-git:
	$(call SOURCEWGET,"git","http://www.kernel.org/pub/software/scm/git/git-2.2.1.tar.xz")

.PHONY: wget-glibc
wget-glibc:
	$(call SOURCEWGET,"glibc","http://ftp.gnu.org/gnu/glibc/glibc-2.19.tar.gz")

.PHONY: wget-gzip
wget-gzip:
	$(call SOURCEWGET,"gzip","http://ftp.gnu.org/gnu/gzip/gzip-1.2.4.tar")

.PHONY: wget-httpd
wget-httpd:
	$(call SOURCEWGET,"httpd","http://archive.apache.org/dist/httpd/httpd-2.4.7.tar.bz2")

.PHONY: wget-inetutils
wget-inetutils:
	$(call SOURCEWGET,"inetutils","http://ftp.gnu.org/gnu/inetutils/inetutils-1.9.tar.gz")

.PHONY: wget-libevent
wget-libevent:
	$(call SOURCEWGET,"libevent","https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz")

.PHONY: wget-libiconv
wget-libiconv:
	$(call SOURCEWGET,"libiconv","http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz")

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

.PHONY: wget-netpbm
wget-netpbm:
	$(call SOURCEWGET,"netpbm","http://downloads.sourceforge.net/project/netpbm/super_stable/10.35.95/netpbm-10.35.95.tgz")

.PHONY: wget-ntfs-3g
wget-ntfs-3g:
	$(call SOURCEWGET,"ntfs-3g","http://tuxera.com/opensource/ntfs-3g_ntfsprogs-2013.1.13.tgz")

.PHONY: wget-openssl
wget-openssl:
	$(call SOURCEWGET,"openssl","http://www.openssl.org/source/openssl-1.0.2.tar.gz")

.PHONY: wget-pcre
wget-pcre:
	$(call SOURCEWGET,"pcre","https://sourceforge.net/projects/pcre/files/pcre/8.35/pcre-8.35.tar.gz")

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

.PHONY: wget-sparse
wget-sparse:
	$(call SOURCEWGET,"sparse","http://www.kernel.org/pub/software/devel/sparse/dist/sparse-0.5.0.tar.gz")

.PHONY: wget-srm
wget-srm:
	$(call SOURCEWGET,"srm","http://sourceforge.net/projects/srm/files/1.2.13/srm-1.2.13.tar.gz")

.PHONY: wget-swig
wget-swig:
	# (call SOURCEWGET,"swig","http://downloads.sourceforge.net/swig/swig-2.0.11.tar.gz")
	$(call SOURCEWGET,"swig","http://prdownloads.sourceforge.net/swig/swig-3.0.0.tar.gz")

# http://www.tcl.tk/software/tcltk/download.html
.PHONY: wget-tcl
wget-tcl:
	$(call SOURCEWGET,"tcl","http://prdownloads.sourceforge.net/tcl/tcl8.6.3-src.tar.gz")

.PHONY: wget-tar
wget-tar:
	$(call SOURCEWGET,"tar","http://ftp.gnu.org/gnu/tar/tar-1.27.tar.gz")

.PHONY: wget-tcpdump
wget-tcpdump:
	$(call SOURCEWGET,"tcpdump","http://www.tcpdump.org/release/tcpdump-4.5.1.tar.gz")

.PHONY: wget-texinfo
wget-texinfo:
	$(call SOURCEWGET,"texinfo","http://ftp.gnu.org/gnu/texinfo/texinfo-5.2.tar.gz")

.PHONY: wget-tmux
wget-tmux:
	$(call SOURCEWGET,"tmux","http://downloads.sourceforge.net/tmux/tmux-1.9a.tar.gz")

.PHONY: wget-truecrypt
wget-truecrypt:
	$(call SOURCEWGET,"truecrypt","http://truecrypt.org/download/truecrypt-7.1a-linux-console-x86.tar.gz")

.PHONY: wget-util-linux
wget-util-linux:
	$(call SOURCEWGET,"util-linux","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz")

.PHONY: wget-util-linux-ng
wget-util-linux-ng:
	$(call SOURCEWGET,"util-linux-ng","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.18/util-linux-ng-2.18.tar.xz")

.PHONY: wget-unzip
wget-unzip:
	$(call SOURCEWGET,"unzip","http://downloads.sourceforge.net/infozip/unzip60.tar.gz")

.PHONY: wget-vim
wget-vim:
	$(call SOURCEWGET,"vim","ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2")

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

.PHONY: wget-zip
wget-zip:
	$(call SOURCEWGET,"zip","http://downloads.sourceforge.net/infozip/zip30.tar.gz")

.PHONY: wget-zlib
wget-zlib:
	$(call SOURCEWGET,"zlib","http://zlib.net/zlib-1.2.8.tar.gz")


