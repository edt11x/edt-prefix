#
# edt-prefix
# ==========
# 
###################################################################################
###################################################################################
#
# My Linux Prefix Project
# 
# Main goals:
# 
# * I run into old, sometimes very old, versions of Linux at client sites. I
#   want to be able to use some modern tools. This is not uncommon in avionics
#   development, where tools are qualified and may live for more than a decade.
#
# * Build a set of tools that sit outside of the normal /bin, /sbin, /usr/bin,
#   /usr/sbin, etc.
# 
# * Build a set of tools that won't interfere with the pre-existing installed
#   tools
# 
# * Don't require additional users be added to the Linux box
#
# * Build a reasonable set of new tools on the old distribution
#
# * Give myself a platform and a methodology for building complex Linux source
#   packages.
# 
###################################################################################
###################################################################################
# 
# Things I should work on:
# * Alot of these packages fall into some pretty generic patterns,
#  - tar xf; configure; make; make check; /usr/bin/sudo make install
#  - or tar xf; make; make check; make install
#  - I need to build more generic templates to match these patterns
# * One major hurdle is not having a good pthreads library.
# * Need to work on the ability to handle building multiple versions of a
#   package. For example, I need to build GCC 4.7.3 since that will still
#   build with just a straight C compiler, then I need to build a more
#   recent version of GCC, like GCC 6 to build the rest of the packages.
#
###################################################################################
###################################################################################
#
# We need a new version of Make to handle this Makefile. Probably
# need to compile Make by hand so this will work or package install
# from somewhere else.
#
###################################################################################
###################################################################################
#
# Since we are building coreutils and other fundemental linux packages, we need
# this Makefile to use the original linux install of many basic utilities like
# rm, find, sudo, cp, etc.
#
###################################################################################
###################################################################################
#
# The machine needs at least 1Gbyte of RAM or binutils will not
# pass the tests.
#
###################################################################################
###################################################################################
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
# Lots of good concise info about building individual packages and their 
# dependancies can be found at Linux From Scratch.
#
# As far as special steps to install documentation, I am skipping those
# more and more. I find I look everything up on Google and Stackoverflow.
#
# In general, I try to build the packages without special options or
# patches, but often that is not realistic.
#
# Configuration Variables
#
GCC_LANGS=c,c++,fortran,java,objc,obj-c++

#
# Generate a unique file name for this run of make.
#
THIS_RUN := $(notdir $(shell mktemp -u))

#
# The current username
#
USERNAME := $(shell whoami)

#
# variable representations of comma, space, newline, backslash
#
comma := ,

space :=
space +=

#
# GNU Make does not like putting backslashes in defines or
# here documents. We have to jump through a couple hoops to
# make this happen.
#
# http://stackoverflow.com/questions/30099791/backslash-newline-in-a-make-variable

# variable containing a newline
# # there must be two blank lines between the define and endef
# # (http://stackoverflow.com/a/17055840/2064196)
define nl


endef

# variable containing a backslash
# https://www.netbsd.org/docs/pkgsrc/makefile.html#makefile.variables
# backslash !=           echo "\\"
# the version below avoids $(shell), as suggested by bobbogo's comment
backslash := \$(strip)

#
# Patches, Here Documents
#
###################################################################################
###################################################################################
###################################################################################
#
# Need this patch to compile GCC 4.7.3 with newer versions of GCC, where the C
# standard is post C89
#
# https://github.com/DragonFlyBSD/DPorts/issues/136
#
define GCC_4_7_3_PATCH
--- gcc/cp/cfns.h.orig	2015-02-13 08:27:46.000000000 +0200
+++ gcc/cp/cfns.h	2015-02-13 10:23:53.000000000 +0200
@@ -53,6 +53,9 @@
 static unsigned int hash (const char *, unsigned int);
 #ifdef __GNUC__
 __inline
+#ifdef __GNUC_STDC_INLINE__
+__attribute__ ((__gnu_inline__))
+#endif
 #endif
 const char * libc_name_p (const char *, unsigned int);
 /* maximum key range = 391, duplicates = 0 */
@@ -96,7 +99,7 @@
       400, 400, 400, 400, 400, 400, 400, 400, 400, 400,
       400, 400, 400, 400, 400, 400, 400
     };
-  register int hval = len;
+  register int hval = (int)len;
 
   switch (hval)
     {
endef
###################################################################################
###################################################################################
###################################################################################
define COMPILERRTPATCH
--- sanitizer_platform_limits_posix.cc.orig	2014-03-30 02:07:36.565541221 -0400
+++ sanitizer_platform_limits_posix.cc	2014-03-30 02:08:36.928098455 -0400
@@ -231,8 +231,8 @@
   int ptrace_setfpregs = PTRACE_SETFPREGS;
   int ptrace_getfpxregs = PTRACE_GETFPXREGS;
   int ptrace_setfpxregs = PTRACE_SETFPXREGS;
-  int ptrace_getsiginfo = PTRACE_GETSIGINFO;
-  int ptrace_setsiginfo = PTRACE_SETSIGINFO;
+  int ptrace_getsiginfo = -1;
+  int ptrace_setsiginfo = -1;
 #if defined(PTRACE_GETREGSET) && defined(PTRACE_SETREGSET)
   int ptrace_getregset = PTRACE_GETREGSET;
   int ptrace_setregset = PTRACE_SETREGSET;
endef

###################################################################################
###################################################################################
###################################################################################
define ICUPATCH
Submitted By: Pierre Labastie <pierre dot labastie at neuf dot fr>
Date: 2016-11-15
Initial Package Version: 58.1
Upstream Status: Applied
Origin: Upstream, rediffed so that patch -p1 works.
Description: Fix a regression in 58.1, which made mozilla applications
segfault. See ticket #8527

diff -Naur icu.old/source/common/ulist.c icu.new/source/common/ulist.c
--- icu.old/source/common/ulist.c	2016-06-15 20:58:17.000000000 +0200
+++ icu.new/source/common/ulist.c	2016-11-15 16:11:09.996596933 +0100
@@ -29,7 +29,6 @@
     UListNode *tail;
     
     int32_t size;
-    int32_t currentIndex;
 };
 
 static void ulist_addFirstItem(UList *list, UListNode *newItem);
@@ -51,7 +50,6 @@
     newList->head = NULL;
     newList->tail = NULL;
     newList->size = 0;
-    newList->currentIndex = -1;
     
     return newList;
 }
@@ -80,8 +78,9 @@
     } else {
         p->next->previous = p->previous;
     }
-    list->curr = NULL;
-    list->currentIndex = 0;
+    if (p == list->curr) {
+        list->curr = p->next;
+    }
     --list->size;
     if (p->forceDelete) {
         uprv_free(p->data);
@@ -150,7 +149,6 @@
         newItem->next = list->head;
         list->head->previous = newItem;
         list->head = newItem;
-        list->currentIndex++;
     }
     
     list->size++;
@@ -193,7 +191,6 @@
     
     curr = list->curr;
     list->curr = curr->next;
-    list->currentIndex++;
     
     return curr->data;
 }
@@ -209,7 +206,6 @@
 U_CAPI void U_EXPORT2 ulist_resetList(UList *list) {
     if (list != NULL) {
         list->curr = list->head;
-        list->currentIndex = 0;
     }
 }
 
@@ -272,4 +268,3 @@
 U_CAPI UList * U_EXPORT2 ulist_getListFromEnum(UEnumeration *en) {
     return (UList *)(en->context);
 }
-
diff -Naur icu.old/source/i18n/ucol_res.cpp icu.new/source/i18n/ucol_res.cpp
--- icu.old/source/i18n/ucol_res.cpp	2016-09-28 04:26:02.000000000 +0200
+++ icu.new/source/i18n/ucol_res.cpp	2016-11-15 16:11:10.000596933 +0100
@@ -680,6 +680,7 @@
         return NULL;
     }
     memcpy(en, &defaultKeywordValues, sizeof(UEnumeration));
+    ulist_resetList(sink.values);  // Initialize the iterator.
     en->context = sink.values;
     sink.values = NULL;  // Avoid deletion in the sink destructor.
     return en;
endef
###################################################################################
###################################################################################
###################################################################################
define LUASHAREDLIBPATCH
Submitted By:            Igor Å½ivkoviÄ‡ <contact@igor-zivkovic.from.hr>
Date:                    2013-06-19
Initial Package Version: 5.2.2
Upstream Status:         Rejected
Origin:                  Arch Linux packages repository
Description:             Adds the compilation of a shared library.

diff -Naur lua-5.3.0.orig/Makefile lua-5.3.0/Makefile
--- lua-5.3.0.orig/Makefile	2014-10-30 00:14:41.000000000 +0100
+++ lua-5.3.0/Makefile	2015-01-19 22:14:09.822290828 +0100
@@ -52,7 +52,7 @@
 all:	$$(PLAT)
 
 $$(PLATS) clean:
-	cd src && $$(MAKE) $$@
+	cd src && $$(MAKE) $$@ V=$$(V) R=$$(R)
 
 test:	dummy
 	src/lua -v
diff -Naur lua-5.3.0.orig/src/Makefile lua-5.3.0/src/Makefile
--- lua-5.3.0.orig/src/Makefile	2015-01-05 17:04:52.000000000 +0100
+++ lua-5.3.0/src/Makefile	2015-01-19 22:14:52.559378543 +0100
@@ -7,7 +7,7 @@
 PLAT= none
 
 CC= gcc -std=gnu99
-CFLAGS= -O2 -Wall -Wextra -DLUA_COMPAT_5_2 $$(SYSCFLAGS) $$(MYCFLAGS)
+CFLAGS= -fPIC -O2 -Wall -Wextra -DLUA_COMPAT_5_2 $$(SYSCFLAGS) $$(MYCFLAGS)
 LDFLAGS= $$(SYSLDFLAGS) $$(MYLDFLAGS)
 LIBS= -lm $$(SYSLIBS) $$(MYLIBS)
 
@@ -29,6 +29,7 @@
 PLATS= aix bsd c89 freebsd generic linux macosx mingw posix solaris
 
 LUA_A=	liblua.a
+LUA_SO= liblua.so
 CORE_O=	lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o ${backslash}${nl} \
 	lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ${backslash}${nl} \
 	ltm.o lundump.o lvm.o lzio.o
@@ -43,7 +44,7 @@
 LUAC_O=	luac.o
 
 ALL_O= $$(BASE_O) $$(LUA_O) $$(LUAC_O)
-ALL_T= $$(LUA_A) $$(LUA_T) $$(LUAC_T)
+ALL_T= $$(LUA_A) $$(LUA_T) $$(LUAC_T) $$(LUA_SO)
 ALL_A= $$(LUA_A)
 
 # Targets start here.
@@ -59,6 +60,12 @@
 	$$(AR) $$@ $$(BASE_O)
 	$$(RANLIB) $$@
 
+$$(LUA_SO): $$(CORE_O) $$(LIB_O)
+	$$(CC) -shared -ldl -Wl,-soname,$$(LUA_SO).$$(V) -o $$@.$$(R) $$? -lm $$(MYLDFLAGS)
+	ln -sf $$(LUA_SO).$$(R) $$(LUA_SO).$$(V)
+	ln -sf $$(LUA_SO).$$(R) $$(LUA_SO)
+
+
 $$(LUA_T): $$(LUA_O) $$(LUA_A)
 	$$(CC) -o $$@ $$(LDFLAGS) $$(LUA_O) $$(LUA_A) $$(LIBS)

endef

###################################################################################
###################################################################################
###################################################################################
define TCPWRAPPERSPATCH
Submitted By: Tushar Teredesai <tushar@linuxfromscratch.org>
Date: 2003-10-04
Initial Package Version: 7.6
Origin: http://archives.linuxfromscratch.org/mail-archives/blfs-dev/2003-January/001960.html
Description: The patch was created from the tcp_wrappers modified package by Mark Heerdink.
This patch provides the following improvements:
    * Install libwrap.so along with libwrap.a.
    * Create an install target for tcp_wrappers.
    * Compilation and security fixes.
    * Documentation fixes.
diff -Naur tcp_wrappers_7.6/Makefile tcp_wrappers_7.6.gimli/Makefile
--- tcp_wrappers_7.6/Makefile	1997-03-21 12:27:21.000000000 -0600
+++ tcp_wrappers_7.6.gimli/Makefile	2002-07-15 16:07:21.000000000 -0500
@@ -1,5 +1,10 @@
+GLIBC=$$(shell grep -s -c __GLIBC__ /usr/include/features.h)
+
 # @(#) Makefile 1.23 97/03/21 19:27:20
 
+# unset the HOSTNAME environment variable
+HOSTNAME =
+
 what:
 	@echo
 	@echo "Usage: edit the REAL_DAEMON_DIR definition in the Makefile then:"
@@ -19,7 +24,7 @@
 	@echo "	generic (most bsd-ish systems with sys5 compatibility)"
 	@echo "	386bsd aix alpha apollo bsdos convex-ultranet dell-gcc dgux dgux543"
 	@echo "	dynix epix esix freebsd hpux irix4 irix5 irix6 isc iunix"
-	@echo "	linux machten mips(untested) ncrsvr4 netbsd next osf power_unix_211"
+	@echo "	linux gnu machten mips(untested) ncrsvr4 netbsd next osf power_unix_211"
 	@echo "	ptx-2.x ptx-generic pyramid sco sco-nis sco-od2 sco-os5 sinix sunos4"
 	@echo "	sunos40 sunos5 sysv4 tandem ultrix unicos7 unicos8 unixware1 unixware2"
 	@echo "	uts215 uxp"
@@ -43,8 +48,8 @@
 # Ultrix 4.x SunOS 4.x ConvexOS 10.x Dynix/ptx
 #REAL_DAEMON_DIR=/usr/etc
 #
-# SysV.4 Solaris 2.x OSF AIX
-#REAL_DAEMON_DIR=/usr/sbin
+# SysV.4 Solaris 2.x OSF AIX Linux
+REAL_DAEMON_DIR=/usr/sbin
 #
 # BSD 4.4
 #REAL_DAEMON_DIR=/usr/libexec
@@ -141,10 +146,21 @@
 	LIBS= RANLIB=ranlib ARFLAGS=rv AUX_OBJ= NETGROUP= TLI= \\
 	EXTRA_CFLAGS=-DSYS_ERRLIST_DEFINED VSYSLOG= all
 
+ifneq ($$(GLIBC),0)
+MYLIB=-lnsl
+endif
+
 linux:
 	@make REAL_DAEMON_DIR=$$(REAL_DAEMON_DIR) STYLE=$$(STYLE) \\
-	LIBS= RANLIB=ranlib ARFLAGS=rv AUX_OBJ=setenv.o \\
-	NETGROUP= TLI= EXTRA_CFLAGS="-DBROKEN_SO_LINGER" all
+	LIBS=$$(MYLIB) RANLIB=ranlib ARFLAGS=rv AUX_OBJ=weak_symbols.o \\
+	NETGROUP=-DNETGROUP TLI= VSYSLOG= BUGS= all \\
+	EXTRA_CFLAGS="-DSYS_ERRLIST_DEFINED -DHAVE_WEAKSYMS -D_REENTRANT"
+
+gnu:
+	@make REAL_DAEMON_DIR=$$(REAL_DAEMON_DIR) STYLE=$$(STYLE) \\
+	LIBS=$$(MYLIB) RANLIB=ranlib ARFLAGS=rv AUX_OBJ=weak_symbols.o \\
+	NETGROUP=-DNETGROUP TLI= VSYSLOG= BUGS= all \\
+	EXTRA_CFLAGS="-DHAVE_STRERROR -DHAVE_WEAKSYMS -D_REENTRANT"
 
 # This is good for many SYSV+BSD hybrids with NIS, probably also for HP-UX 7.x.
 hpux hpux8 hpux9 hpux10:
@@ -391,7 +407,7 @@
 # the ones provided with this source distribution. The environ.c module
 # implements setenv(), getenv(), and putenv().
 
-AUX_OBJ= setenv.o
+#AUX_OBJ= setenv.o
 #AUX_OBJ= environ.o
 #AUX_OBJ= environ.o strcasecmp.o
 
@@ -454,7 +470,8 @@
 # host name aliases. Compile with -DSOLARIS_24_GETHOSTBYNAME_BUG to work
 # around this. The workaround does no harm on other Solaris versions.
 
-BUGS = -DGETPEERNAME_BUG -DBROKEN_FGETS -DLIBC_CALLS_STRTOK
+BUGS =
+#BUGS = -DGETPEERNAME_BUG -DBROKEN_FGETS -DLIBC_CALLS_STRTOK
 #BUGS = -DGETPEERNAME_BUG -DBROKEN_FGETS -DINET_ADDR_BUG
 #BUGS = -DGETPEERNAME_BUG -DBROKEN_FGETS -DSOLARIS_24_GETHOSTBYNAME_BUG
 
@@ -464,7 +481,7 @@
 # If your system supports NIS or YP-style netgroups, enable the following
 # macro definition. Netgroups are used only for host access control.
 #
-#NETGROUP= -DNETGROUP
+NETGROUP= -DNETGROUP
 
 ###############################################################
 # System dependencies: whether or not your system has vsyslog()
@@ -491,7 +508,7 @@
 # Uncomment the next definition to turn on the language extensions
 # (examples: allow, deny, banners, twist and spawn).
 # 
-#STYLE	= -DPROCESS_OPTIONS	# Enable language extensions.
+STYLE	= -DPROCESS_OPTIONS	# Enable language extensions.
 
 ################################################################
 # Optional: Changing the default disposition of logfile records
@@ -514,7 +531,7 @@
 #
 # The LOG_XXX names below are taken from the /usr/include/syslog.h file.
 
-FACILITY= LOG_MAIL	# LOG_MAIL is what most sendmail daemons use
+FACILITY= LOG_DAEMON	# LOG_MAIL is what most sendmail daemons use
 
 # The syslog priority at which successful connections are logged.
 
@@ -610,7 +627,7 @@
 # Paranoid mode implies hostname lookup. In order to disable hostname
 # lookups altogether, see the next section.
 
-PARANOID= -DPARANOID
+#PARANOID= -DPARANOID
 
 ########################################
 # Optional: turning off hostname lookups
@@ -623,7 +640,7 @@
 # In order to perform selective hostname lookups, disable paranoid
 # mode (see previous section) and comment out the following definition.
 
-HOSTNAME= -DALWAYS_HOSTNAME
+#HOSTNAME= -DALWAYS_HOSTNAME
 
 #############################################
 # Optional: Turning on host ADDRESS checking
@@ -649,28 +666,46 @@
 # source-routed traffic in the kernel. Examples: 4.4BSD derivatives,
 # Solaris 2.x, and Linux. See your system documentation for details.
 #
-# KILL_OPT= -DKILL_IP_OPTIONS
+KILL_OPT= -DKILL_IP_OPTIONS
 
 ## End configuration options
 ############################
 
 # Protection against weird shells or weird make programs.
 
+CC	= gcc
 SHELL	= /bin/sh
-.c.o:;	$$(CC) $$(CFLAGS) -c $$*.c
+.c.o:;	$$(CC) $$(CFLAGS) -o $$*.o -c $$*.c
+
+SOMAJOR = 0
+SOMINOR = 7.6
+
+LIB	= libwrap.a
+SHLIB	= shared/libwrap.so.$$(SOMAJOR).$$(SOMINOR)
+SHLIBSOMAJ= shared/libwrap.so.$$(SOMAJOR)
+SHLIBSO	= shared/libwrap.so
+SHLIBFLAGS = -Lshared -lwrap
 
-CFLAGS	= -O -DFACILITY=$$(FACILITY) $$(ACCESS) $$(PARANOID) $$(NETGROUP) \\
+shared/%.o: %.c
+	$$(CC) $$(CFLAGS) $$(SHCFLAGS) -c $$< -o $$@
+
+CFLAGS	= -O2 -DFACILITY=$$(FACILITY) $$(ACCESS) $$(PARANOID) $$(NETGROUP) \\
 	$$(BUGS) $$(SYSTYPE) $$(AUTH) $$(UMASK) \\
 	-DREAL_DAEMON_DIR=\\"$$(REAL_DAEMON_DIR)\\" $$(STYLE) $$(KILL_OPT) \\
 	-DSEVERITY=$$(SEVERITY) -DRFC931_TIMEOUT=$$(RFC931_TIMEOUT) \\
 	$$(UCHAR) $$(TABLES) $$(STRINGS) $$(TLI) $$(EXTRA_CFLAGS) $$(DOT) \\
 	$$(VSYSLOG) $$(HOSTNAME)
 
+SHLINKFLAGS = -shared -Xlinker -soname -Xlinker libwrap.so.$$(SOMAJOR) -lc $$(LIBS)
+SHCFLAGS = -fPIC -shared -D_REENTRANT
+
 LIB_OBJ= hosts_access.o options.o shell_cmd.o rfc931.o eval.o \\
 	hosts_ctl.o refuse.o percent_x.o clean_exit.o $$(AUX_OBJ) \\
 	$$(FROM_OBJ) fix_options.o socket.o tli.o workarounds.o \\
 	update.o misc.o diag.o percent_m.o myvsyslog.o
 
+SHLIB_OBJ= $$(addprefix shared/, $$(LIB_OBJ));
+
 FROM_OBJ= fromhost.o
 
 KIT	= README miscd.c tcpd.c fromhost.c hosts_access.c shell_cmd.c \\
@@ -684,46 +719,80 @@
 	refuse.c tcpdchk.8 setenv.c inetcf.c inetcf.h scaffold.c \\
 	scaffold.h tcpdmatch.8 README.NIS
 
-LIB	= libwrap.a
-
-all other: config-check tcpd tcpdmatch try-from safe_finger tcpdchk
+all other: config-check tcpd tcpdmatch try-from safe_finger tcpdchk $$(LIB)
 
 # Invalidate all object files when the compiler options (CFLAGS) have changed.
 
 config-check:
 	@set +e; test -n "$$(REAL_DAEMON_DIR)" || { make; exit 1; }
-	@set +e; echo $$(CFLAGS) >/tmp/cflags.$$$$$$$$ ; \\
-	if cmp cflags /tmp/cflags.$$$$$$$$ ; \\
-	then rm /tmp/cflags.$$$$$$$$ ; \\
-	else mv /tmp/cflags.$$$$$$$$ cflags ; \\
+	@set +e; echo $$(CFLAGS) >cflags.new ; \\
+	if cmp cflags cflags.new ; \\
+	then rm cflags.new ; \\
+	else mv cflags.new cflags ; \\
 	fi >/dev/null 2>/dev/null
+	@if [ ! -d shared ]; then mkdir shared; fi
 
 $$(LIB):	$$(LIB_OBJ)
 	rm -f $$(LIB)
 	$$(AR) $$(ARFLAGS) $$(LIB) $$(LIB_OBJ)
 	-$$(RANLIB) $$(LIB)
 
-tcpd:	tcpd.o $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ tcpd.o $$(LIB) $$(LIBS)
+$$(SHLIB): $$(SHLIB_OBJ)
+	rm -f $$(SHLIB)
+	$$(CC) -o $$(SHLIB) $$(SHLINKFLAGS) $$(SHLIB_OBJ)
+	ln -s $$(notdir $$(SHLIB)) $$(SHLIBSOMAJ)
+	ln -s $$(notdir $$(SHLIBSOMAJ)) $$(SHLIBSO)
+
+tcpd:	tcpd.o $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ tcpd.o $$(SHLIBFLAGS)
 
-miscd:	miscd.o $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ miscd.o $$(LIB) $$(LIBS)
+miscd:	miscd.o $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ miscd.o $$(SHLIBFLAGS)
 
-safe_finger: safe_finger.o $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ safe_finger.o $$(LIB) $$(LIBS)
+safe_finger: safe_finger.o $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ safe_finger.o $$(SHLIBFLAGS)
 
 TCPDMATCH_OBJ = tcpdmatch.o fakelog.o inetcf.o scaffold.o
 
-tcpdmatch: $$(TCPDMATCH_OBJ) $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ $$(TCPDMATCH_OBJ) $$(LIB) $$(LIBS)
+tcpdmatch: $$(TCPDMATCH_OBJ) $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ $$(TCPDMATCH_OBJ) $$(SHLIBFLAGS)
 
-try-from: try-from.o fakelog.o $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ try-from.o fakelog.o $$(LIB) $$(LIBS)
+try-from: try-from.o fakelog.o $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ try-from.o fakelog.o $$(SHLIBFLAGS)
 
 TCPDCHK_OBJ = tcpdchk.o fakelog.o inetcf.o scaffold.o
 
-tcpdchk: $$(TCPDCHK_OBJ) $$(LIB)
-	$$(CC) $$(CFLAGS) -o $$@ $$(TCPDCHK_OBJ) $$(LIB) $$(LIBS)
+tcpdchk: $$(TCPDCHK_OBJ) $$(SHLIB)
+	$$(CC) $$(CFLAGS) -o $$@ $$(TCPDCHK_OBJ) $$(SHLIBFLAGS)
+
+install: install-lib install-bin install-dev
+
+install-lib:
+	install -o root -g root -m 0755 $$(SHLIB) $${DESTDIR}/usr/lib/
+	ln -sf $$(notdir $$(SHLIB)) $${DESTDIR}/usr/lib/$$(notdir $$(SHLIBSOMAJ))
+	ln -sf $$(notdir $$(SHLIBSOMAJ)) $${DESTDIR}/usr/lib/$$(notdir $$(SHLIBSO))
+
+install-bin:
+	install -o root -g root -m 0755 tcpd $${DESTDIR}/usr/sbin/
+	install -o root -g root -m 0755 tcpdchk $${DESTDIR}/usr/sbin/
+	install -o root -g root -m 0755 tcpdmatch $${DESTDIR}/usr/sbin/
+	install -o root -g root -m 0755 try-from $${DESTDIR}/usr/sbin/
+	install -o root -g root -m 0755 safe_finger $${DESTDIR}/usr/sbin/
+	install -o root -g root -m 0644 tcpd.8 $${DESTDIR}/usr/share/man/man8/
+	install -o root -g root -m 0644 tcpdchk.8 $${DESTDIR}/usr/share/man/man8/
+	install -o root -g root -m 0644 try-from.8 $${DESTDIR}/usr/share/man/man8/
+	install -o root -g root -m 0644 tcpdmatch.8 $${DESTDIR}/usr/share/man/man8/
+	install -o root -g root -m 0644 safe_finger.8 $${DESTDIR}/usr/share/man/man8/
+	install -o root -g root -m 0644 hosts_access.5 $${DESTDIR}/usr/share/man/man5/
+	install -o root -g root -m 0644 hosts_options.5 $${DESTDIR}/usr/share/man/man5/
+
+install-dev:
+	install -o root -g root -m 0644 hosts_access.3 $${DESTDIR}/usr/share/man/man3/
+	install -o root -g root -m 0644 tcpd.h $${DESTDIR}/usr/include/
+	install -o root -g root -m 0644 $$(LIB) $${DESTDIR}/usr/lib/
+	ln -sf hosts_access.3 $${DESTDIR}/usr/share/man/man3/hosts_ctl.3
+	ln -sf hosts_access.3 $${DESTDIR}/usr/share/man/man3/request_init.3
+	ln -sf hosts_access.3 $${DESTDIR}/usr/share/man/man3/request_set.3
 
 shar:	$$(KIT)
 	@shar $$(KIT)
@@ -739,7 +808,8 @@
 
 clean:
 	rm -f tcpd miscd safe_finger tcpdmatch tcpdchk try-from *.[oa] core \\
-	cflags
+	cflags libwrap*.so*
+	rm -rf shared
 
 tidy:	clean
 	chmod -R a+r .
@@ -885,5 +955,6 @@
 update.o: mystdarg.h
 update.o: tcpd.h
 vfprintf.o: cflags
+weak_symbols.o: tcpd.h
 workarounds.o: cflags
 workarounds.o: tcpd.h
diff -Naur tcp_wrappers_7.6/fix_options.c tcp_wrappers_7.6.gimli/fix_options.c
--- tcp_wrappers_7.6/fix_options.c	1997-04-07 19:29:19.000000000 -0500
+++ tcp_wrappers_7.6.gimli/fix_options.c	2002-01-07 08:50:19.000000000 -0600
@@ -35,7 +35,12 @@
 #ifdef IP_OPTIONS
     unsigned char optbuf[BUFFER_SIZE / 3], *cp;
     char    lbuf[BUFFER_SIZE], *lp;
+#if !defined(__GLIBC__)
     int     optsize = sizeof(optbuf), ipproto;
+#else /* __GLIBC__ */
+    size_t  optsize = sizeof(optbuf);
+    int     ipproto;
+#endif /* __GLIBC__ */
     struct protoent *ip;
     int     fd = request->fd;
     unsigned int opt;
diff -Naur tcp_wrappers_7.6/hosts_access.3 tcp_wrappers_7.6.gimli/hosts_access.3
--- tcp_wrappers_7.6/hosts_access.3	1996-02-11 10:01:27.000000000 -0600
+++ tcp_wrappers_7.6.gimli/hosts_access.3	2002-01-07 08:50:19.000000000 -0600
@@ -3,7 +3,7 @@
 hosts_access, hosts_ctl, request_init, request_set \\- access control library
 .SH SYNOPSIS
 .nf
-#include "tcpd.h"
+#include <tcpd.h>
 
 extern int allow_severity;
 extern int deny_severity;
diff -Naur tcp_wrappers_7.6/hosts_access.5 tcp_wrappers_7.6.gimli/hosts_access.5
--- tcp_wrappers_7.6/hosts_access.5	1995-01-30 12:51:47.000000000 -0600
+++ tcp_wrappers_7.6.gimli/hosts_access.5	2002-01-07 08:50:19.000000000 -0600
@@ -8,9 +8,9 @@
 impatient reader is encouraged to skip to the EXAMPLES section for a
 quick introduction.
 .PP
-An extended version of the access control language is described in the
-\\fIhosts_options\\fR(5) document. The extensions are turned on at
-program build time by building with -DPROCESS_OPTIONS.
+The extended version of the access control language is described in the
+\\fIhosts_options\\fR(5) document. \\fBNote that this language supersedes
+the meaning of \\fIshell_command\\fB as documented below.\\fR
 .PP
 In the following text, \\fIdaemon\\fR is the the process name of a
 network daemon process, and \\fIclient\\fR is the name and/or address of
@@ -40,7 +40,7 @@
 character. This permits you to break up long lines so that they are
 easier to edit.
 .IP \\(bu
-Blank lines or lines that begin with a `#\\' character are ignored.
+Blank lines or lines that begin with a `#' character are ignored.
 This permits you to insert comments and whitespace so that the tables
 are easier to read.
 .IP \\(bu
@@ -69,26 +69,33 @@
 .SH PATTERNS
 The access control language implements the following patterns:
 .IP \\(bu
-A string that begins with a `.\\' character. A host name is matched if
+A string that begins with a `.' character. A host name is matched if
 the last components of its name match the specified pattern.  For
-example, the pattern `.tue.nl\\' matches the host name
-`wzv.win.tue.nl\\'.
+example, the pattern `.tue.nl' matches the host name
+`wzv.win.tue.nl'.
 .IP \\(bu
-A string that ends with a `.\\' character. A host address is matched if
+A string that ends with a `.' character. A host address is matched if
 its first numeric fields match the given string.  For example, the
-pattern `131.155.\\' matches the address of (almost) every host on the
+pattern `131.155.' matches the address of (almost) every host on the
 Eind\\%hoven University network (131.155.x.x).
 .IP \\(bu
-A string that begins with an `@\\' character is treated as an NIS
+A string that begins with an `@' character is treated as an NIS
 (formerly YP) netgroup name. A host name is matched if it is a host
 member of the specified netgroup. Netgroup matches are not supported
 for daemon process names or for client user names.
 .IP \\(bu
-An expression of the form `n.n.n.n/m.m.m.m\\' is interpreted as a
-`net/mask\\' pair. A host address is matched if `net\\' is equal to the
-bitwise AND of the address and the `mask\\'. For example, the net/mask
-pattern `131.155.72.0/255.255.254.0\\' matches every address in the
-range `131.155.72.0\\' through `131.155.73.255\\'.
+An expression of the form `n.n.n.n/m.m.m.m' is interpreted as a
+`net/mask' pair. A host address is matched if `net' is equal to the
+bitwise AND of the address and the `mask'. For example, the net/mask
+pattern `131.155.72.0/255.255.254.0' matches every address in the
+range `131.155.72.0' through `131.155.73.255'.
+.IP \\(bu
+A string that begins with a `/' character is treated as a file
+name. A host name or address is matched if it matches any host name
+or address pattern listed in the named file. The file format is
+zero or more lines with zero or more host name or address patterns
+separated by whitespace.  A file name pattern can be used anywhere
+a host name or address pattern can be used.
 .SH WILDCARDS
 The access control language supports explicit wildcards:
 .IP ALL
@@ -115,19 +122,19 @@
 .ne 6
 .SH OPERATORS
 .IP EXCEPT
-Intended use is of the form: `list_1 EXCEPT list_2\\'; this construct
+Intended use is of the form: `list_1 EXCEPT list_2'; this construct
 matches anything that matches \\fIlist_1\\fR unless it matches
 \\fIlist_2\\fR.  The EXCEPT operator can be used in daemon_lists and in
 client_lists. The EXCEPT operator can be nested: if the control
-language would permit the use of parentheses, `a EXCEPT b EXCEPT c\\'
-would parse as `(a EXCEPT (b EXCEPT c))\\'.
+language would permit the use of parentheses, `a EXCEPT b EXCEPT c'
+would parse as `(a EXCEPT (b EXCEPT c))'.
 .br
 .ne 6
 .SH SHELL COMMANDS
 If the first-matched access control rule contains a shell command, that
 command is subjected to %<letter> substitutions (see next section).
 The result is executed by a \\fI/bin/sh\\fR child process with standard
-input, output and error connected to \\fI/dev/null\\fR.  Specify an `&\\'
+input, output and error connected to \\fI/dev/null\\fR.  Specify an `&'
 at the end of the command if you do not want to wait until it has
 completed.
 .PP
@@ -159,7 +166,7 @@
 .IP %u
 The client user name (or "unknown").
 .IP %%
-Expands to a single `%\\' character.
+Expands to a single `%' character.
 .PP
 Characters in % expansions that may confuse the shell are replaced by
 underscores.
@@ -243,9 +250,9 @@
 less trustworthy. It is possible for an intruder to spoof both the
 client connection and the IDENT lookup, although doing so is much
 harder than spoofing just a client connection. It may also be that
-the client\\'s IDENT server is lying.
+the client's IDENT server is lying.
 .PP
-Note: IDENT lookups don\\'t work with UDP services. 
+Note: IDENT lookups don't work with UDP services. 
 .SH EXAMPLES
 The language is flexible enough that different types of access control
 policy can be expressed with a minimum of fuss. Although the language
@@ -285,7 +292,7 @@
 .br
 ALL: .foobar.edu EXCEPT terminalserver.foobar.edu
 .PP
-The first rule permits access from hosts in the local domain (no `.\\'
+The first rule permits access from hosts in the local domain (no `.'
 in the host name) and from members of the \\fIsome_netgroup\\fP
 netgroup.  The second rule permits access from all hosts in the
 \\fIfoobar.edu\\fP domain (notice the leading dot), with the exception of
@@ -322,8 +329,8 @@
 /etc/hosts.deny:
 .in +3
 .nf
-in.tftpd: ALL: (/some/where/safe_finger -l @%h | \\\\
-	/usr/ucb/mail -s %d-%h root) &
+in.tftpd: ALL: (/usr/sbin/safe_finger -l @%h | \\\\
+	/usr/bin/mail -s %d-%h root) &
 .fi
 .PP
 The safe_finger command comes with the tcpd wrapper and should be
@@ -349,7 +356,7 @@
 capacity of an internal buffer; when an access control rule is not
 terminated by a newline character; when the result of %<letter>
 expansion would overflow an internal buffer; when a system call fails
-that shouldn\\'t.  All problems are reported via the syslog daemon.
+that shouldn't.  All problems are reported via the syslog daemon.
 .SH FILES
 .na
 .nf
diff -Naur tcp_wrappers_7.6/hosts_access.c tcp_wrappers_7.6.gimli/hosts_access.c
--- tcp_wrappers_7.6/hosts_access.c	1997-02-11 19:13:23.000000000 -0600
+++ tcp_wrappers_7.6.gimli/hosts_access.c	2002-01-07 08:50:19.000000000 -0600
@@ -240,6 +240,26 @@
     }
 }
 
+/* hostfile_match - look up host patterns from file */
+
+static int hostfile_match(path, host)
+char   *path;
+struct hosts_info *host;
+{
+    char    tok[BUFSIZ];
+    int     match = NO;
+    FILE   *fp;
+
+    if ((fp = fopen(path, "r")) != 0) {
+        while (fscanf(fp, "%s", tok) == 1 && !(match = host_match(tok, host)))
+            /* void */ ;
+        fclose(fp);
+    } else if (errno != ENOENT) {
+        tcpd_warn("open %s: %m", path);
+    }
+    return (match);
+}
+
 /* host_match - match host name and/or address against pattern */
 
 static int host_match(tok, host)
@@ -267,6 +287,8 @@
 	tcpd_warn("netgroup support is disabled");	/* not tcpd_jump() */
 	return (NO);
 #endif
+    } else if (tok[0] == '/') {                         /* /file hack */
+        return (hostfile_match(tok, host));
     } else if (STR_EQ(tok, "KNOWN")) {		/* check address and name */
 	char   *name = eval_hostname(host);
 	return (STR_NE(eval_hostaddr(host), unknown) && HOSTNAME_KNOWN(name));
diff -Naur tcp_wrappers_7.6/hosts_options.5 tcp_wrappers_7.6.gimli/hosts_options.5
--- tcp_wrappers_7.6/hosts_options.5	1994-12-28 10:42:29.000000000 -0600
+++ tcp_wrappers_7.6.gimli/hosts_options.5	2002-01-07 08:50:19.000000000 -0600
@@ -58,12 +58,12 @@
 Execute, in a child process, the specified shell command, after
 performing the %<letter> expansions described in the hosts_access(5)
 manual page.  The command is executed with stdin, stdout and stderr
-connected to the null device, so that it won\\'t mess up the
+connected to the null device, so that it won't mess up the
 conversation with the client host. Example:
 .sp
 .nf
 .ti +3
-spawn (/some/where/safe_finger -l @%h | /usr/ucb/mail root) &
+spawn (/usr/sbin/safe_finger -l @%h | /usr/bin/mail root) &
 .fi
 .sp
 executes, in a background child process, the shell command "safe_finger
diff -Naur tcp_wrappers_7.6/options.c tcp_wrappers_7.6.gimli/options.c
--- tcp_wrappers_7.6/options.c	1996-02-11 10:01:32.000000000 -0600
+++ tcp_wrappers_7.6.gimli/options.c	2002-01-07 08:50:19.000000000 -0600
@@ -473,6 +473,9 @@
 #ifdef LOG_CRON
     "cron", LOG_CRON,
 #endif
+#ifdef LOG_FTP
+    "ftp", LOG_FTP,
+#endif
 #ifdef LOG_LOCAL0
     "local0", LOG_LOCAL0,
 #endif
diff -Naur tcp_wrappers_7.6/percent_m.c tcp_wrappers_7.6.gimli/percent_m.c
--- tcp_wrappers_7.6/percent_m.c	1994-12-28 10:42:37.000000000 -0600
+++ tcp_wrappers_7.6.gimli/percent_m.c	2002-01-07 08:50:19.000000000 -0600
@@ -13,7 +13,7 @@
 #include <string.h>
 
 extern int errno;
-#ifndef SYS_ERRLIST_DEFINED
+#if !defined(SYS_ERRLIST_DEFINED) && !defined(HAVE_STRERROR)
 extern char *sys_errlist[];
 extern int sys_nerr;
 #endif
@@ -29,11 +29,15 @@
 
     while (*bp = *cp)
 	if (*cp == '%' && cp[1] == 'm') {
+#ifdef HAVE_STRERROR
+            strcpy(bp, strerror(errno));
+#else
 	    if (errno < sys_nerr && errno > 0) {
 		strcpy(bp, sys_errlist[errno]);
 	    } else {
 		sprintf(bp, "Unknown error %d", errno);
 	    }
+#endif
 	    bp += strlen(bp);
 	    cp += 2;
 	} else {
diff -Naur tcp_wrappers_7.6/rfc931.c tcp_wrappers_7.6.gimli/rfc931.c
--- tcp_wrappers_7.6/rfc931.c	1995-01-02 09:11:34.000000000 -0600
+++ tcp_wrappers_7.6.gimli/rfc931.c	2002-01-07 08:50:19.000000000 -0600
@@ -33,7 +33,7 @@
 
 int     rfc931_timeout = RFC931_TIMEOUT;/* Global so it can be changed */
 
-static jmp_buf timebuf;
+static sigjmp_buf timebuf;
 
 /* fsocket - open stdio stream on top of socket */
 
@@ -62,7 +62,7 @@
 static void timeout(sig)
 int     sig;
 {
-    longjmp(timebuf, sig);
+    siglongjmp(timebuf, sig);
 }
 
 /* rfc931 - return remote user name, given socket structures */
@@ -99,7 +99,7 @@
 	 * Set up a timer so we won't get stuck while waiting for the server.
 	 */
 
-	if (setjmp(timebuf) == 0) {
+	if (sigsetjmp(timebuf,1) == 0) {
 	    signal(SIGALRM, timeout);
 	    alarm(rfc931_timeout);
 
diff -Naur tcp_wrappers_7.6/safe_finger.8 tcp_wrappers_7.6.gimli/safe_finger.8
--- tcp_wrappers_7.6/safe_finger.8	1969-12-31 18:00:00.000000000 -0600
+++ tcp_wrappers_7.6.gimli/safe_finger.8	2002-01-07 08:50:19.000000000 -0600
@@ -0,0 +1,34 @@
+.TH SAFE_FINGER 8 "21th June 1997" Linux "Linux Programmer's Manual"
+.SH NAME
+safe_finger \\- finger client wrapper that protects against nasty stuff
+from finger servers
+.SH SYNOPSIS
+.B safe_finger [finger_options]
+.SH DESCRIPTION
+The
+.B safe_finger
+command protects against nasty stuff from finger servers. Use this
+program for automatic reverse finger probes from the
+.B tcp_wrapper
+.B (tcpd)
+, not the raw finger command. The
+.B safe_finger
+command makes sure that the finger client is not run with root
+privileges. It also runs the finger client with a defined PATH
+environment.
+.B safe_finger
+will also protect you from problems caused by the output of some
+finger servers. The problem: some programs may react to stuff in
+the first column. Other programs may get upset by thrash anywhere
+on a line. File systems may fill up as the finger server keeps
+sending data. Text editors may bomb out on extremely long lines.
+The finger server may take forever because it is somehow wedged.
+.B safe_finger
+takes care of all this badness.
+.SH SEE ALSO
+.BR hosts_access (5),
+.BR hosts_options (5),
+.BR tcpd (8)
+.SH AUTHOR
+Wietse Venema, Eindhoven University of Technology, The Netherlands.
+
diff -Naur tcp_wrappers_7.6/safe_finger.c tcp_wrappers_7.6.gimli/safe_finger.c
--- tcp_wrappers_7.6/safe_finger.c	1994-12-28 10:42:42.000000000 -0600
+++ tcp_wrappers_7.6.gimli/safe_finger.c	2002-01-07 08:50:19.000000000 -0600
@@ -26,21 +26,24 @@
 #include <stdio.h>
 #include <ctype.h>
 #include <pwd.h>
+#include <syslog.h>
 
 extern void exit();
 
 /* Local stuff */
 
-char    path[] = "PATH=/bin:/usr/bin:/usr/ucb:/usr/bsd:/etc:/usr/etc:/usr/sbin";
+char    path[] = "PATH=/bin:/usr/bin:/sbin:/usr/sbin";
 
 #define	TIME_LIMIT	60		/* Do not keep listinging forever */
 #define	INPUT_LENGTH	100000		/* Do not keep listinging forever */
 #define	LINE_LENGTH	128		/* Editors can choke on long lines */
 #define	FINGER_PROGRAM	"finger"	/* Most, if not all, UNIX systems */
 #define	UNPRIV_NAME	"nobody"	/* Preferred privilege level */
-#define	UNPRIV_UGID	32767		/* Default uid and gid */
+#define	UNPRIV_UGID	65534		/* Default uid and gid */
 
 int     finger_pid;
+int	allow_severity = SEVERITY;
+int	deny_severity = LOG_WARNING;
 
 void    cleanup(sig)
 int     sig;
diff -Naur tcp_wrappers_7.6/scaffold.c tcp_wrappers_7.6.gimli/scaffold.c
--- tcp_wrappers_7.6/scaffold.c	1997-03-21 12:27:24.000000000 -0600
+++ tcp_wrappers_7.6.gimli/scaffold.c	2002-01-07 08:50:19.000000000 -0600
@@ -180,10 +180,12 @@
 
 /* ARGSUSED */
 
-void    rfc931(request)
-struct request_info *request;
+void    rfc931(rmt_sin, our_sin, dest)
+struct sockaddr_in *rmt_sin;
+struct sockaddr_in *our_sin;
+char   *dest;
 {
-    strcpy(request->user, unknown);
+    strcpy(dest, unknown);
 }
 
 /* check_path - examine accessibility */
diff -Naur tcp_wrappers_7.6/socket.c tcp_wrappers_7.6.gimli/socket.c
--- tcp_wrappers_7.6/socket.c	1997-03-21 12:27:25.000000000 -0600
+++ tcp_wrappers_7.6.gimli/socket.c	2002-01-07 08:50:19.000000000 -0600
@@ -76,7 +76,11 @@
 {
     static struct sockaddr_in client;
     static struct sockaddr_in server;
+#if !defined (__GLIBC__)
     int     len;
+#else /* __GLIBC__ */
+    size_t  len;
+#endif /* __GLIBC__ */
     char    buf[BUFSIZ];
     int     fd = request->fd;
 
@@ -224,7 +228,11 @@
 {
     char    buf[BUFSIZ];
     struct sockaddr_in sin;
+#if !defined(__GLIBC__)
     int     size = sizeof(sin);
+#else /* __GLIBC__ */
+    size_t  size = sizeof(sin);
+#endif /* __GLIBC__ */
 
     /*
      * Eat up the not-yet received datagram. Some systems insist on a
diff -Naur tcp_wrappers_7.6/tcpd.8 tcp_wrappers_7.6.gimli/tcpd.8
--- tcp_wrappers_7.6/tcpd.8	1996-02-21 09:39:16.000000000 -0600
+++ tcp_wrappers_7.6.gimli/tcpd.8	2002-01-07 08:50:19.000000000 -0600
@@ -94,7 +94,7 @@
 .PP
 The example assumes that the network daemons live in /usr/etc. On some
 systems, network daemons live in /usr/sbin or in /usr/libexec, or have
-no `in.\\' prefix to their name.
+no `in.' prefix to their name.
 .SH EXAMPLE 2
 This example applies when \\fItcpd\\fR expects that the network daemons
 are left in their original place.
@@ -110,26 +110,26 @@
 becomes:
 .sp
 .ti +5
-finger  stream  tcp  nowait  nobody  /some/where/tcpd     in.fingerd
+finger  stream  tcp  nowait  nobody  /usr/sbin/tcpd       in.fingerd
 .sp
 .fi
 .PP
 The example assumes that the network daemons live in /usr/etc. On some
 systems, network daemons live in /usr/sbin or in /usr/libexec, the
-daemons have no `in.\\' prefix to their name, or there is no userid
+daemons have no `in.' prefix to their name, or there is no userid
 field in the inetd configuration file.
 .PP
 Similar changes will be needed for the other services that are to be
-covered by \\fItcpd\\fR.  Send a `kill -HUP\\' to the \\fIinetd\\fR(8)
+covered by \\fItcpd\\fR.  Send a `kill -HUP' to the \\fIinetd\\fR(8)
 process to make the changes effective. AIX users may also have to
-execute the `inetimp\\' command.
+execute the `inetimp' command.
 .SH EXAMPLE 3
 In the case of daemons that do not live in a common directory ("secret"
 or otherwise), edit the \\fIinetd\\fR configuration file so that it
 specifies an absolute path name for the process name field. For example:
 .nf
 .sp
-    ntalk  dgram  udp  wait  root  /some/where/tcpd  /usr/local/lib/ntalkd
+    ntalk  dgram  udp  wait  root  /usr/sbin/tcpd  /usr/sbin/in.ntalkd
 .sp
 .fi
 .PP
diff -Naur tcp_wrappers_7.6/tcpd.h tcp_wrappers_7.6.gimli/tcpd.h
--- tcp_wrappers_7.6/tcpd.h	1996-03-19 09:22:25.000000000 -0600
+++ tcp_wrappers_7.6.gimli/tcpd.h	2002-01-07 08:50:19.000000000 -0600
@@ -4,6 +4,25 @@
   * Author: Wietse Venema, Eindhoven University of Technology, The Netherlands.
   */
 
+#ifndef _TCPWRAPPERS_TCPD_H
+#define _TCPWRAPPERS_TCPD_H
+
+/* someone else may have defined this */
+#undef  __P
+
+/* use prototypes if we have an ANSI C compiler or are using C++ */
+#if defined(__STDC__) || defined(__cplusplus)
+#define __P(args)       args
+#else
+#define __P(args)       ()
+#endif
+
+/* Need definitions of struct sockaddr_in and FILE. */
+#include <netinet/in.h>
+#include <stdio.h>
+
+__BEGIN_DECLS
+
 /* Structure to describe one communications endpoint. */
 
 #define STRING_LENGTH	128		/* hosts, users, processes */
@@ -25,10 +44,10 @@
     char    pid[10];			/* access via eval_pid(request) */
     struct host_info client[1];		/* client endpoint info */
     struct host_info server[1];		/* server endpoint info */
-    void  (*sink) ();			/* datagram sink function or 0 */
-    void  (*hostname) ();		/* address to printable hostname */
-    void  (*hostaddr) ();		/* address to printable address */
-    void  (*cleanup) ();		/* cleanup function or 0 */
+    void  (*sink) __P((int));		/* datagram sink function or 0 */
+    void  (*hostname) __P((struct host_info *)); /* address to printable hostname */
+    void  (*hostaddr) __P((struct host_info *)); /* address to printable address */
+    void  (*cleanup) __P((struct request_info *)); /* cleanup function or 0 */
     struct netconfig *config;		/* netdir handle */
 };
 
@@ -61,25 +80,30 @@
 /* Global functions. */
 
 #if defined(TLI) || defined(PTX) || defined(TLI_SEQUENT)
-extern void fromhost();			/* get/validate client host info */
+extern void fromhost __P((struct request_info *));	/* get/validate client host info */
 #else
 #define fromhost sock_host		/* no TLI support needed */
 #endif
 
-extern int hosts_access();		/* access control */
-extern void shell_cmd();		/* execute shell command */
-extern char *percent_x();		/* do %<char> expansion */
-extern void rfc931();			/* client name from RFC 931 daemon */
-extern void clean_exit();		/* clean up and exit */
-extern void refuse();			/* clean up and exit */
-extern char *xgets();			/* fgets() on steroids */
-extern char *split_at();		/* strchr() and split */
-extern unsigned long dot_quad_addr();	/* restricted inet_addr() */
+extern void shell_cmd __P((char *));	/* execute shell command */
+extern char *percent_x __P((char *, int, char *, struct request_info *)); /* do %<char> expansion */
+extern void rfc931 __P((struct sockaddr_in *, struct sockaddr_in *, char *)); /* client name from RFC 931 daemon */
+extern void clean_exit __P((struct request_info *)); /* clean up and exit */
+extern void refuse __P((struct request_info *));	/* clean up and exit */
+extern char *xgets __P((char *, int, FILE *));	/* fgets() on steroids */
+extern char *split_at __P((char *, int));	/* strchr() and split */
+extern unsigned long dot_quad_addr __P((char *)); /* restricted inet_addr() */
 
 /* Global variables. */
 
+#ifdef HAVE_WEAKSYMS
+extern int allow_severity __attribute__ ((weak)); /* for connection logging */
+extern int deny_severity __attribute__ ((weak)); /* for connection logging */
+#else
 extern int allow_severity;		/* for connection logging */
 extern int deny_severity;		/* for connection logging */
+#endif
+
 extern char *hosts_allow_table;		/* for verification mode redirection */
 extern char *hosts_deny_table;		/* for verification mode redirection */
 extern int hosts_access_verbose;	/* for verbose matching mode */
@@ -92,9 +116,14 @@
   */
 
 #ifdef __STDC__
+extern int hosts_access(struct request_info *request);
+extern int hosts_ctl(char *daemon, char *client_name, char *client_addr, 
+                     char *client_user);
 extern struct request_info *request_init(struct request_info *,...);
 extern struct request_info *request_set(struct request_info *,...);
 #else
+extern int hosts_access();
+extern int hosts_ctl();
 extern struct request_info *request_init();	/* initialize request */
 extern struct request_info *request_set();	/* update request structure */
 #endif
@@ -117,27 +146,31 @@
   * host_info structures serve as caches for the lookup results.
   */
 
-extern char *eval_user();		/* client user */
-extern char *eval_hostname();		/* printable hostname */
-extern char *eval_hostaddr();		/* printable host address */
-extern char *eval_hostinfo();		/* host name or address */
-extern char *eval_client();		/* whatever is available */
-extern char *eval_server();		/* whatever is available */
+extern char *eval_user __P((struct request_info *));	/* client user */
+extern char *eval_hostname __P((struct host_info *));	/* printable hostname */
+extern char *eval_hostaddr __P((struct host_info *));	/* printable host address */
+extern char *eval_hostinfo __P((struct host_info *));	/* host name or address */
+extern char *eval_client __P((struct request_info *));	/* whatever is available */
+extern char *eval_server __P((struct request_info *));	/* whatever is available */
 #define eval_daemon(r)	((r)->daemon)	/* daemon process name */
 #define eval_pid(r)	((r)->pid)	/* process id */
 
 /* Socket-specific methods, including DNS hostname lookups. */
 
-extern void sock_host();		/* look up endpoint addresses */
-extern void sock_hostname();		/* translate address to hostname */
-extern void sock_hostaddr();		/* address to printable address */
+/* look up endpoint addresses */
+extern void sock_host __P((struct request_info *));
+/* translate address to hostname */
+extern void sock_hostname __P((struct host_info *));
+/* address to printable address */
+extern void sock_hostaddr __P((struct host_info *));
+
 #define sock_methods(r) \\
 	{ (r)->hostname = sock_hostname; (r)->hostaddr = sock_hostaddr; }
 
 /* The System V Transport-Level Interface (TLI) interface. */
 
 #if defined(TLI) || defined(PTX) || defined(TLI_SEQUENT)
-extern void tli_host();			/* look up endpoint addresses etc. */
+extern void tli_host __P((struct request_info *));	/* look up endpoint addresses etc. */
 #endif
 
  /*
@@ -178,7 +211,7 @@
   * behavior.
   */
 
-extern void process_options();		/* execute options */
+extern void process_options __P((char *, struct request_info *)); /* execute options */
 extern int dry_run;			/* verification flag */
 
 /* Bug workarounds. */
@@ -217,3 +250,7 @@
 #define strtok	my_strtok
 extern char *my_strtok();
 #endif
+
+__END_DECLS
+
+#endif /* tcpd.h */
diff -Naur tcp_wrappers_7.6/tcpdchk.c tcp_wrappers_7.6.gimli/tcpdchk.c
--- tcp_wrappers_7.6/tcpdchk.c	1997-02-11 19:13:25.000000000 -0600
+++ tcp_wrappers_7.6.gimli/tcpdchk.c	2002-01-07 08:50:19.000000000 -0600
@@ -350,6 +350,8 @@
 {
     if (pat[0] == '@') {
 	tcpd_warn("%s: daemon name begins with \\"@\\"", pat);
+    } else if (pat[0] == '/') {
+        tcpd_warn("%s: daemon name begins with \\"/\\"", pat);
     } else if (pat[0] == '.') {
 	tcpd_warn("%s: daemon name begins with dot", pat);
     } else if (pat[strlen(pat) - 1] == '.') {
@@ -382,6 +384,8 @@
 {
     if (pat[0] == '@') {			/* @netgroup */
 	tcpd_warn("%s: user name begins with \\"@\\"", pat);
+    } else if (pat[0] == '/') {
+        tcpd_warn("%s: user name begins with \\"/\\"", pat);
     } else if (pat[0] == '.') {
 	tcpd_warn("%s: user name begins with dot", pat);
     } else if (pat[strlen(pat) - 1] == '.') {
@@ -402,8 +406,13 @@
 static int check_host(pat)
 char   *pat;
 {
+    char    buf[BUFSIZ];
     char   *mask;
     int     addr_count = 1;
+    FILE   *fp;
+    struct tcpd_context saved_context;
+    char   *cp;
+    char   *wsp = " \\t\\r\\n";
 
     if (pat[0] == '@') {			/* @netgroup */
 #ifdef NO_NETGRENT
@@ -422,6 +431,21 @@
 	tcpd_warn("netgroup support disabled");
 #endif
 #endif
+    } else if (pat[0] == '/') {                 /* /path/name */
+        if ((fp = fopen(pat, "r")) != 0) {
+            saved_context = tcpd_context;
+            tcpd_context.file = pat;
+            tcpd_context.line = 0;
+            while (fgets(buf, sizeof(buf), fp)) {
+                tcpd_context.line++;
+                for (cp = strtok(buf, wsp); cp; cp = strtok((char *) 0, wsp))
+                    check_host(cp);
+            }
+            tcpd_context = saved_context;
+            fclose(fp);
+        } else if (errno != ENOENT) {
+            tcpd_warn("open %s: %m", pat);
+        }
     } else if (mask = split_at(pat, '/')) {	/* network/netmask */
 	if (dot_quad_addr(pat) == INADDR_NONE
 	    || dot_quad_addr(mask) == INADDR_NONE)
diff -Naur tcp_wrappers_7.6/try-from.8 tcp_wrappers_7.6.gimli/try-from.8
--- tcp_wrappers_7.6/try-from.8	1969-12-31 18:00:00.000000000 -0600
+++ tcp_wrappers_7.6.gimli/try-from.8	2002-01-07 08:50:19.000000000 -0600
@@ -0,0 +1,28 @@
+.TH TRY-FROM 8 "21th June 1997" Linux "Linux Programmer's Manual"
+.SH NAME
+try-from \\- test program for the tcp_wrapper
+.SH SYNOPSIS
+.B try-from
+.SH DESCRIPTION
+The
+.B try-from
+command can be called via a remote shell command to find out
+if the hostname and address are properly recognized
+by the
+.B tcp_wrapper
+library, if username lookup works, and (SysV only) if the TLI
+on top of IP heuristics work. Diagnostics are reported through
+.BR syslog (3)
+and redirected to stderr.
+
+Example:
+
+rsh host /some/where/try-from
+
+.SH SEE ALSO
+.BR hosts_access (5),
+.BR hosts_options (5),
+.BR tcpd (8)
+.SH AUTHOR
+Wietse Venema, Eindhoven University of Technology, The Netherlands.
+
diff -Naur tcp_wrappers_7.6/weak_symbols.c tcp_wrappers_7.6.gimli/weak_symbols.c
--- tcp_wrappers_7.6/weak_symbols.c	1969-12-31 18:00:00.000000000 -0600
+++ tcp_wrappers_7.6.gimli/weak_symbols.c	2002-01-07 08:50:19.000000000 -0600
@@ -0,0 +1,11 @@
+ /*
+  * @(#) weak_symbols.h 1.5 99/12/29 23:50
+  * 
+  * Author: Anthony Towns <ajt@debian.org>
+  */
+
+#ifdef HAVE_WEAKSYMS
+#include <syslog.h>
+int deny_severity = LOG_WARNING;
+int allow_severity = SEVERITY; 
+#endif
diff -Naur tcp_wrappers_7.6/workarounds.c tcp_wrappers_7.6.gimli/workarounds.c
--- tcp_wrappers_7.6/workarounds.c	1996-03-19 09:22:26.000000000 -0600
+++ tcp_wrappers_7.6.gimli/workarounds.c	2002-01-07 08:50:19.000000000 -0600
@@ -163,7 +163,11 @@
 int     fix_getpeername(sock, sa, len)
 int     sock;
 struct sockaddr *sa;
+#if !defined(__GLIBC__)
 int    *len;
+#else /* __GLIBC__ */
+size_t *len;
+#endif /* __GLIBC__ */
 {
     int     ret;
     struct sockaddr_in *sin = (struct sockaddr_in *) sa;
endef
###################################################################################
###################################################################################
###################################################################################
define PYGOBJECT_PATCH
Submitted By:            Andrew Benton <andy at benton dot eu dot com> (gobject-introspection) and Armin K. <krejzi at email dot com>, after thomas kaedin (git)
Date:                    2012-03-29 (gobject-introspection) and 2014-03-04 (git)
Initial Package Version: 2.28.6
Upstream Status:         not submitted (gobject-introspection) and committed (git)
Origin:                  Andrew Benton (gobject-introspection) and upstream (git)
Description:             Fixes compiling with recent versions of gobject-introspection; and upstream fixes

diff -Naur pygobject-2.28.6.orig/configure.ac pygobject-2.28.6/configure.ac
--- pygobject-2.28.6.orig/configure.ac	2011-06-13 13:33:56.000000000 -0300
+++ pygobject-2.28.6/configure.ac	2014-03-04 18:36:07.947079909 -0300
@@ -85,7 +85,7 @@
 AM_PROG_CC_STDC
 AM_PROG_CC_C_O
 
-# check that we have the minimum version of python necisary to build
+# check that we have the minimum version of python necessary to build
 JD_PATH_PYTHON(python_min_ver)
 
 # check if we are building for python 3
@@ -236,7 +236,7 @@
 AC_ARG_ENABLE(introspection,
   AC_HELP_STRING([--enable-introspection], [Use introspection information]),
   enable_introspection=$$enableval,
-  enable_introspection=yes)
+  enable_introspection=no)
 if test "$$enable_introspection" != no; then
     AC_DEFINE(ENABLE_INTROSPECTION,1,Use introspection information)
     PKG_CHECK_MODULES(GI,
@@ -262,6 +262,9 @@
 AC_SUBST(INTROSPECTION_SCANNER)
 AC_SUBST(INTROSPECTION_COMPILER)
 
+dnl Do not install codegen for Python 3.
+AM_CONDITIONAL(ENABLE_CODEGEN, test $$build_py3k = false)
+
 dnl add required cflags ...
 if test "x$$GCC" = "xyes"; then
   JH_ADD_CFLAG([-Wall])
@@ -281,8 +284,6 @@
   Makefile
   pygobject-2.0.pc
   pygobject-2.0-uninstalled.pc
-  codegen/Makefile
-  codegen/pygobject-codegen-2.0
   docs/Makefile
   docs/reference/entities.docbook
   docs/xsl/fixxref.py
@@ -295,6 +296,13 @@
   examples/Makefile
   tests/Makefile
   PKG-INFO)
+
+if test $$build_py3k = false; then
+  AC_CONFIG_FILES(
+    codegen/Makefile
+    codegen/pygobject-codegen-2.0)
+fi
+
 AC_OUTPUT
 
 echo
diff -Naur pygobject-2.28.6.orig/gi/module.py pygobject-2.28.6/gi/module.py
--- pygobject-2.28.6.orig/gi/module.py	2011-06-13 13:30:25.000000000 -0300
+++ pygobject-2.28.6/gi/module.py	2014-03-04 18:36:07.947079909 -0300
@@ -24,7 +24,11 @@
 
 import os
 import gobject
-import string
+try:
+    maketrans = ''.maketrans
+except AttributeError:
+    # fallback for Python 2
+    from string import maketrans
 
 import gi
 from .overrides import registry
@@ -124,7 +128,7 @@
                 # Don't use upper() here to avoid locale specific
                 # identifier conversion (e. g. in Turkish 'i'.upper() == 'i')
                 # see https://bugzilla.gnome.org/show_bug.cgi?id=649165
-                ascii_upper_trans = string.maketrans(
+                ascii_upper_trans = maketrans(
                         'abcdefgjhijklmnopqrstuvwxyz', 
                         'ABCDEFGJHIJKLMNOPQRSTUVWXYZ')
                 for value_info in info.get_values():
diff -Naur pygobject-2.28.6.orig/gi/overrides/Gtk.py pygobject-2.28.6/gi/overrides/Gtk.py
--- pygobject-2.28.6.orig/gi/overrides/Gtk.py	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/gi/overrides/Gtk.py	2014-03-04 18:36:07.949079863 -0300
@@ -35,6 +35,18 @@
 Gtk = modules['Gtk']._introspection_module
 __all__ = []
 
+if Gtk._version == '2.0':
+    import warnings
+    warn_msg = "You have imported the Gtk 2.0 module.  Because Gtk 2.0 $(backslash)$(nl)+was not designed for use with introspection some of the $(backslash)$(nl)+interfaces and API will fail.  As such this is not supported $(backslash)$(nl)+by the pygobject development team and we encourage you to $(backslash)$(nl)+port your app to Gtk 3 or greater. PyGTK is the recomended $(backslash)$(nl)+python module to use with Gtk 2.0"
+
+    warnings.warn(warn_msg, RuntimeWarning)
+
+
 class Widget(Gtk.Widget):
 
     def translate_coordinates(self, dest_widget, src_x, src_y):
@@ -401,16 +413,22 @@
     def __init__(self,
                  parent=None,
                  flags=0,
-                 type=Gtk.MessageType.INFO,
+                 message_type=Gtk.MessageType.INFO,
                  buttons=Gtk.ButtonsType.NONE,
                  message_format=None,
                  **kwds):
 
         if message_format != None:
             kwds['text'] = message_format
+
+        if 'type' in kwds:
+            import warnings
+            warnings.warn("The use of the keyword type as a parameter of the Gtk.MessageDialog constructor has been depricated. Please use message_type instead.", DeprecationWarning)
+            message_type = kwds['type']
+
         Gtk.MessageDialog.__init__(self,
                                    _buttons_property=buttons,
-                                   message_type=type,
+                                   message_type=message_type,
                                    **kwds)
         Dialog.__init__(self, parent=parent, flags=flags)
 
@@ -619,12 +637,18 @@
     def forward_search(self, string, flags, limit):
         success, match_start, match_end = super(TextIter, self).forward_search(string,
             flags, limit)
-        return (match_start, match_end,)
+        if success:
+            return (match_start, match_end)
+        else:
+            return None
 
     def backward_search(self, string, flags, limit):
         success, match_start, match_end = super(TextIter, self).backward_search(string,
             flags, limit)
-        return (match_start, match_end,)
+        if success:
+            return (match_start, match_end)
+        else:
+            return None
 
     def begins_tag(self, tag=None):
         return super(TextIter, self).begins_tag(tag)
diff -Naur pygobject-2.28.6.orig/gi/pygi-foreign-cairo.c pygobject-2.28.6/gi/pygi-foreign-cairo.c
--- pygobject-2.28.6.orig/gi/pygi-foreign-cairo.c	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/gi/pygi-foreign-cairo.c	2014-03-04 18:36:07.949079863 -0300
@@ -30,7 +30,7 @@
 #include <pycairo/py3cairo.h>
 #endif
 
-Pycairo_CAPI_t *Pycairo_CAPI;
+static Pycairo_CAPI_t *Pycairo_CAPI;
 
 #include "pygi-foreign.h"
 
@@ -114,10 +114,15 @@
     Py_RETURN_NONE;
 }
 
-static PyMethodDef _gi_cairo_functions[] = {};
+static PyMethodDef _gi_cairo_functions[] = {0,};
 PYGLIB_MODULE_START(_gi_cairo, "_gi_cairo")
 {
+#if PY_VERSION_HEX < 0x03000000
     Pycairo_IMPORT;
+#else
+    Pycairo_CAPI = (Pycairo_CAPI_t*) PyCObject_Import("cairo", "CAPI");
+#endif
+
     if (Pycairo_CAPI == NULL)
         return PYGLIB_MODULE_ERROR_RETURN;
 
diff -Naur pygobject-2.28.6.orig/gi/pygi-info.c pygobject-2.28.6/gi/pygi-info.c
--- pygobject-2.28.6.orig/gi/pygi-info.c	2011-06-13 13:30:25.000000000 -0300
+++ pygobject-2.28.6/gi/pygi-info.c	2014-03-04 18:35:32.473899924 -0300
@@ -162,9 +162,6 @@
         case GI_INFO_TYPE_CONSTANT:
             type = &PyGIConstantInfo_Type;
             break;
-        case GI_INFO_TYPE_ERROR_DOMAIN:
-            type = &PyGIErrorDomainInfo_Type;
-            break;
         case GI_INFO_TYPE_UNION:
             type = &PyGIUnionInfo_Type;
             break;
@@ -481,7 +478,6 @@
                 case GI_INFO_TYPE_INVALID:
                 case GI_INFO_TYPE_FUNCTION:
                 case GI_INFO_TYPE_CONSTANT:
-                case GI_INFO_TYPE_ERROR_DOMAIN:
                 case GI_INFO_TYPE_VALUE:
                 case GI_INFO_TYPE_SIGNAL:
                 case GI_INFO_TYPE_PROPERTY:
@@ -860,7 +856,6 @@
                     case GI_INFO_TYPE_INVALID:
                     case GI_INFO_TYPE_FUNCTION:
                     case GI_INFO_TYPE_CONSTANT:
-                    case GI_INFO_TYPE_ERROR_DOMAIN:
                     case GI_INFO_TYPE_VALUE:
                     case GI_INFO_TYPE_SIGNAL:
                     case GI_INFO_TYPE_PROPERTY:
diff -Naur pygobject-2.28.6.orig/gio/gio-types.defs pygobject-2.28.6/gio/gio-types.defs
--- pygobject-2.28.6.orig/gio/gio-types.defs	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/gio/gio-types.defs	2014-03-04 18:36:07.950079840 -0300
@@ -526,7 +526,7 @@
   )
 )
 
-(define-enum MountMountFlags
+(define-flags MountMountFlags
   (in-module "gio")
   (c-name "GMountMountFlags")
   (gtype-id "G_TYPE_MOUNT_MOUNT_FLAGS")
@@ -545,7 +545,7 @@
   )
 )
 
-(define-enum DriveStartFlags
+(define-flags DriveStartFlags
   (in-module "gio")
   (c-name "GDriveStartFlags")
   (gtype-id "G_TYPE_DRIVE_START_FLAGS")
@@ -770,7 +770,7 @@
   )
 )
 
-(define-enum SocketMsgFlags
+(define-flags SocketMsgFlags
   (in-module "gio")
   (c-name "GSocketMsgFlags")
   (gtype-id "G_TYPE_SOCKET_MSG_FLAGS")
diff -Naur pygobject-2.28.6.orig/gobject/gobjectmodule.c pygobject-2.28.6/gobject/gobjectmodule.c
--- pygobject-2.28.6.orig/gobject/gobjectmodule.c	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/gobject/gobjectmodule.c	2014-03-04 18:36:07.952079793 -0300
@@ -312,13 +312,6 @@
     pyglib_gil_state_release(state);
 }
 
-static void
-pyg_object_class_init(GObjectClass *class, PyObject *py_class)
-{
-    class->set_property = pyg_object_set_property;
-    class->get_property = pyg_object_get_property;
-}
-
 typedef struct _PyGSignalAccumulatorData {
     PyObject *callable;
     PyObject *user_data;
@@ -484,15 +477,14 @@
 }
 
 static PyObject *
-add_signals (GType instance_type, PyObject *signals)
+add_signals (GObjectClass *klass, PyObject *signals)
 {
     gboolean ret = TRUE;
-    GObjectClass *oclass;
     Py_ssize_t pos = 0;
     PyObject *key, *value, *overridden_signals = NULL;
+    GType instance_type = G_OBJECT_CLASS_TYPE (klass);
 
     overridden_signals = PyDict_New();
-    oclass = g_type_class_ref(instance_type);
     while (PyDict_Next(signals, &pos, &key, &value)) {
 	const gchar *signal_name;
         gchar *signal_name_canon, *c;
@@ -530,7 +522,6 @@
 	if (!ret)
 	    break;
     }
-    g_type_class_unref(oclass);
     if (ret)
         return overridden_signals;
     else {
@@ -800,14 +791,12 @@
 }
 
 static gboolean
-add_properties (GType instance_type, PyObject *properties)
+add_properties (GObjectClass *klass, PyObject *properties)
 {
     gboolean ret = TRUE;
-    GObjectClass *oclass;
     Py_ssize_t pos = 0;
     PyObject *key, *value;
 
-    oclass = g_type_class_ref(instance_type);
     while (PyDict_Next(properties, &pos, &key, &value)) {
 	const gchar *prop_name;
 	GType prop_type;
@@ -873,7 +862,7 @@
 	Py_DECREF(slice);
 
 	if (pspec) {
-	    g_object_class_install_property(oclass, 1, pspec);
+	    g_object_class_install_property(klass, 1, pspec);
 	} else {
             PyObject *type, *value, *traceback;
 	    ret = FALSE;
@@ -883,7 +872,7 @@
                 g_snprintf(msg, 256,
 			   "%s (while registering property '%s' for GType '%s')",
                PYGLIB_PyUnicode_AsString(value),
-			   prop_name, g_type_name(instance_type));
+			   prop_name, G_OBJECT_CLASS_NAME(klass));
                 Py_DECREF(value);
                 value = PYGLIB_PyUnicode_FromString(msg);
             }
@@ -892,11 +881,63 @@
 	}
     }
 
-    g_type_class_unref(oclass);
     return ret;
 }
 
 static void
+pyg_object_class_init(GObjectClass *class, PyObject *py_class)
+{
+    PyObject *gproperties, *gsignals, *overridden_signals;
+    PyObject *class_dict = ((PyTypeObject*) py_class)->tp_dict;
+
+    class->set_property = pyg_object_set_property;
+    class->get_property = pyg_object_get_property;
+
+    /* install signals */
+    /* we look this up in the instance dictionary, so we don't
+     * accidentally get a parent type's __gsignals__ attribute. */
+    gsignals = PyDict_GetItemString(class_dict, "__gsignals__");
+    if (gsignals) {
+	if (!PyDict_Check(gsignals)) {
+	    PyErr_SetString(PyExc_TypeError,
+			    "__gsignals__ attribute not a dict!");
+	    return;
+	}
+	if (!(overridden_signals = add_signals(class, gsignals))) {
+	    return;
+	}
+        if (PyDict_SetItemString(class_dict, "__gsignals__",
+				 overridden_signals)) {
+            return;
+        }
+        Py_DECREF(overridden_signals);
+
+        PyDict_DelItemString(class_dict, "__gsignals__");
+    } else {
+	PyErr_Clear();
+    }
+
+    /* install properties */
+    /* we look this up in the instance dictionary, so we don't
+     * accidentally get a parent type's __gproperties__ attribute. */
+    gproperties = PyDict_GetItemString(class_dict, "__gproperties__");
+    if (gproperties) {
+	if (!PyDict_Check(gproperties)) {
+	    PyErr_SetString(PyExc_TypeError,
+			    "__gproperties__ attribute not a dict!");
+	    return;
+	}
+	if (!add_properties(class, gproperties)) {
+	    return;
+	}
+	PyDict_DelItemString(class_dict, "__gproperties__");
+	/* Borrowed reference. Py_DECREF(gproperties); */
+    } else {
+	PyErr_Clear();
+    }
+}
+
+static void
 pyg_register_class_init(GType gtype, PyGClassInitFunc class_init)
 {
     GSList *list;
@@ -1068,7 +1109,7 @@
  */
 static void
 pyg_type_add_interfaces(PyTypeObject *class, GType instance_type,
-                        PyObject *bases, gboolean new_interfaces,
+                        PyObject *bases,
                         GType *parent_interfaces, guint n_parent_interfaces)
 {
     int i;
@@ -1082,7 +1123,6 @@
         guint k;
         PyObject *base = PyTuple_GET_ITEM(bases, i);
         GType itype;
-        gboolean is_new = TRUE;
         const GInterfaceInfo *iinfo;
         GInterfaceInfo iinfo_copy;
 
@@ -1099,16 +1139,6 @@
         if (!G_TYPE_IS_INTERFACE(itype))
             continue;
 
-        for (k = 0; k < n_parent_interfaces; ++k) {
-            if (parent_interfaces[k] == itype) {
-                is_new = FALSE;
-                break;
-            }
-        }
-
-        if ((new_interfaces && !is_new) || (!new_interfaces && is_new))
-            continue;
-
         iinfo = pyg_lookup_interface_info(itype);
         if (!iinfo) {
             gchar *error;
@@ -1129,7 +1159,7 @@
 int
 pyg_type_register(PyTypeObject *class, const char *type_name)
 {
-    PyObject *gtype, *gsignals, *gproperties, *overridden_signals;
+    PyObject *gtype;
     GType parent_type, instance_type;
     GType *parent_interfaces;
     guint n_parent_interfaces;
@@ -1216,88 +1246,22 @@
     }
 
     /*
-     * Note: Interfaces to be implemented are searched twice.  First
-     * we register interfaces that are already implemented by a parent
-     * type.  The second time, the remaining interfaces are
-     * registered, i.e. the ones that are not implemented by a parent
-     * type.  In between these two loops, properties and signals are
-     * registered.  It has to be done this way, in two steps,
-     * otherwise glib will complain.  If registering all interfaces
-     * always before properties, you get an error like:
-     *
-     *    ../gobject:121: Warning: Object class
-     *    test_interface+MyObject doesn't implement property
-     *    'some-property' from interface 'TestInterface'
-     *
-     * If, on the other hand, you register interfaces after
-     * registering the properties, you get something like:
-     *
-     *     ../gobject:121: Warning: cannot add interface type
-     *    `TestInterface' to type `test_interface+MyUnknown', since
-     *    type `test_interface+MyUnknown' already conforms to
-     *    interface
-     *
-     * This looks like a GLib quirk, but no bug has been filed
-     * upstream.  However we have a unit test for this particular
-     * problem, which can be found in test_interfaces.py, class
-     * TestInterfaceImpl.
+     * Note, all interfaces need to be registered before the first
+     * g_type_class_ref(), see bug #686149.
      *
      * See also comment above pyg_type_add_interfaces().
      */
-    pyg_type_add_interfaces(class, instance_type, class->tp_bases, FALSE,
+    pyg_type_add_interfaces(class, instance_type, class->tp_bases,
                             parent_interfaces, n_parent_interfaces);
 
-    /* we look this up in the instance dictionary, so we don't
-     * accidentally get a parent type's __gsignals__ attribute. */
-    gsignals = PyDict_GetItemString(class->tp_dict, "__gsignals__");
-    if (gsignals) {
-	if (!PyDict_Check(gsignals)) {
-	    PyErr_SetString(PyExc_TypeError,
-			    "__gsignals__ attribute not a dict!");
-            g_free(parent_interfaces);
-	    return -1;
-	}
-	if (!(overridden_signals = add_signals(instance_type, gsignals))) {
-            g_free(parent_interfaces);
-	    return -1;
-	}
-        if (PyDict_SetItemString(class->tp_dict, "__gsignals__",
-				 overridden_signals)) {
-            g_free(parent_interfaces);
-            return -1;
-        }
-        Py_DECREF(overridden_signals);
-    } else {
-	PyErr_Clear();
-    }
 
-    /* we look this up in the instance dictionary, so we don't
-     * accidentally get a parent type's __gsignals__ attribute. */
-    gproperties = PyDict_GetItemString(class->tp_dict, "__gproperties__");
-    if (gproperties) {
-	if (!PyDict_Check(gproperties)) {
-	    PyErr_SetString(PyExc_TypeError,
-			    "__gproperties__ attribute not a dict!");
-            g_free(parent_interfaces);
-	    return -1;
-	}
-	if (!add_properties(instance_type, gproperties)) {
-            g_free(parent_interfaces);
-	    return -1;
-	}
-	PyDict_DelItemString(class->tp_dict, "__gproperties__");
-	/* Borrowed reference. Py_DECREF(gproperties); */
-    } else {
-	PyErr_Clear();
+    gclass = g_type_class_ref(instance_type);
+    if (PyErr_Occurred() != NULL) {
+        g_type_class_unref(gclass);
+        g_free(parent_interfaces);
+        return -1;
     }
 
-    /* Register new interfaces, that are _not_ already defined by
-     * the parent type.  FIXME: See above.
-     */
-    pyg_type_add_interfaces(class, instance_type, class->tp_bases, TRUE,
-                            parent_interfaces, n_parent_interfaces);
-
-    gclass = g_type_class_ref(instance_type);
     if (pyg_run_class_init(instance_type, gclass, class)) {
         g_type_class_unref(gclass);
         g_free(parent_interfaces);
@@ -1306,9 +1270,8 @@
     g_type_class_unref(gclass);
     g_free(parent_interfaces);
 
-    if (gsignals)
-        PyDict_DelItemString(class->tp_dict, "__gsignals__");
-
+    if (PyErr_Occurred() != NULL)
+        return -1;
     return 0;
 }
 
diff -Naur pygobject-2.28.6.orig/gobject/propertyhelper.py pygobject-2.28.6/gobject/propertyhelper.py
--- pygobject-2.28.6.orig/gobject/propertyhelper.py	2011-06-13 13:30:25.000000000 -0300
+++ pygobject-2.28.6/gobject/propertyhelper.py	2014-03-04 18:36:07.953079770 -0300
@@ -188,14 +188,16 @@
             return TYPE_STRING
         elif type_ == object:
             return TYPE_PYOBJECT
-        elif isinstance(type_, type) and issubclass(type_, _gobject.GObject):
+        elif (isinstance(type_, type) and
+              issubclass(type_, (_gobject.GObject,
+                                 _gobject.GEnum))):
             return type_.__gtype__
         elif type_ in [TYPE_NONE, TYPE_INTERFACE, TYPE_CHAR, TYPE_UCHAR,
-                      TYPE_INT, TYPE_UINT, TYPE_BOOLEAN, TYPE_LONG,
-                      TYPE_ULONG, TYPE_INT64, TYPE_UINT64, TYPE_ENUM,
-                      TYPE_FLAGS, TYPE_FLOAT, TYPE_DOUBLE, TYPE_POINTER,
-                      TYPE_BOXED, TYPE_PARAM, TYPE_OBJECT, TYPE_STRING,
-                      TYPE_PYOBJECT]:
+                       TYPE_INT, TYPE_UINT, TYPE_BOOLEAN, TYPE_LONG,
+                       TYPE_ULONG, TYPE_INT64, TYPE_UINT64,
+                       TYPE_FLOAT, TYPE_DOUBLE, TYPE_POINTER,
+                       TYPE_BOXED, TYPE_PARAM, TYPE_OBJECT, TYPE_STRING,
+                       TYPE_PYOBJECT]:
             return type_
         else:
             raise TypeError("Unsupported type: %r" % (type_,))
@@ -224,6 +226,12 @@
         elif ptype == TYPE_PYOBJECT:
             if default is not None:
                 raise TypeError("object types does not have default values")
+        elif gobject.type_is_a(ptype, TYPE_ENUM):
+            if default is None:
+                raise TypeError("enum properties needs a default value")
+            elif not gobject.type_is_a(default, ptype):
+                raise TypeError("enum value %s must be an instance of %r" %
+                                (default, ptype))
 
     def _get_minimum(self):
         ptype = self.type
@@ -291,7 +299,8 @@
         if ptype in [TYPE_INT, TYPE_UINT, TYPE_LONG, TYPE_ULONG,
                      TYPE_INT64, TYPE_UINT64, TYPE_FLOAT, TYPE_DOUBLE]:
             args = self._get_minimum(), self._get_maximum(), self.default
-        elif ptype == TYPE_STRING or ptype == TYPE_BOOLEAN:
+        elif (ptype == TYPE_STRING or ptype == TYPE_BOOLEAN or
+              ptype.is_a(TYPE_ENUM)):
             args = (self.default,)
         elif ptype == TYPE_PYOBJECT:
             args = ()
diff -Naur pygobject-2.28.6.orig/gobject/pygobject.c pygobject-2.28.6/gobject/pygobject.c
--- pygobject-2.28.6.orig/gobject/pygobject.c	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/gobject/pygobject.c	2014-03-04 18:36:07.954079747 -0300
@@ -991,7 +991,9 @@
 PyObject *
 pygobject_new_sunk(GObject *obj)
 {
-    g_object_set_qdata (obj, pygobject_ref_sunk_key, GINT_TO_POINTER (1));
+    if (obj)
+       g_object_set_qdata (obj, pygobject_ref_sunk_key, GINT_TO_POINTER (1));
+       
     return pygobject_new_full(obj, TRUE, NULL);
 }
 
diff -Naur pygobject-2.28.6.orig/Makefile.am pygobject-2.28.6/Makefile.am
--- pygobject-2.28.6.orig/Makefile.am	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/Makefile.am	2014-03-04 18:36:07.954079747 -0300
@@ -1,7 +1,11 @@
 ACLOCAL_AMFLAGS = -I m4
 AUTOMAKE_OPTIONS = 1.7
 
-SUBDIRS = docs codegen glib gobject gio examples
+SUBDIRS = docs glib gobject gio examples
+
+if ENABLE_CODEGEN
+SUBDIRS += codegen
+endif
 
 if ENABLE_INTROSPECTION
 SUBDIRS += gi
diff -Naur pygobject-2.28.6.orig/tests/Makefile.am pygobject-2.28.6/tests/Makefile.am
--- pygobject-2.28.6.orig/tests/Makefile.am	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/tests/Makefile.am	2014-03-04 18:36:07.955079724 -0300
@@ -104,6 +104,7 @@
 	test-floating.h $(backslash)$(nl) 	test-thread.h $(backslash)$(nl) 	test-unknown.h $(backslash)$(nl)+	te_ST@nouppera $(backslash)$(nl) 	org.gnome.test.gschema.xml
 
 EXTRA_DIST += $$(TEST_FILES_STATIC) $$(TEST_FILES_GI) $$(TEST_FILES_GIO)
diff -Naur pygobject-2.28.6.orig/tests/test_gdbus.py pygobject-2.28.6/tests/test_gdbus.py
--- pygobject-2.28.6.orig/tests/test_gdbus.py	2011-06-13 13:33:49.000000000 -0300
+++ pygobject-2.28.6/tests/test_gdbus.py	2014-03-04 18:36:07.956079701 -0300
@@ -67,8 +67,10 @@
 
     def test_native_calls_async(self):
         def call_done(obj, result, user_data):
-            user_data['result'] = obj.call_finish(result)
-            user_data['main_loop'].quit()
+            try:
+                user_data['result'] = obj.call_finish(result)
+            finally:
+                user_data['main_loop'].quit()
 
         main_loop = gobject.MainLoop()
         data = {'main_loop': main_loop}
diff -Naur pygobject-2.28.6.orig/tests/test_properties.py pygobject-2.28.6/tests/test_properties.py
--- pygobject-2.28.6.orig/tests/test_properties.py	2011-06-13 13:30:25.000000000 -0300
+++ pygobject-2.28.6/tests/test_properties.py	2014-03-04 18:36:07.956079701 -0300
@@ -14,6 +14,8 @@
      G_MININT, G_MAXINT, G_MAXUINT, G_MINLONG, G_MAXLONG, $(backslash)$(nl) \
      G_MAXULONG
 
+from gi.repository import Gio
+
 if sys.version_info < (3, 0):
     TEST_UTF8 = "\xe2\x99\xa5"
     UNICODE_UTF8 = unicode(TEST_UTF8, 'UTF-8')
@@ -34,6 +36,9 @@
     uint64 = gobject.property(
         type=TYPE_UINT64, flags=PARAM_READWRITE|PARAM_CONSTRUCT)
 
+    enum = gobject.property(
+        type=Gio.SocketType, default=Gio.SocketType.STREAM)
+
 class TestProperties(unittest.TestCase):
     def testGetSet(self):
         obj = PropertyObject()
@@ -61,8 +66,9 @@
                 self.failUnless(pspec.name in ['normal',
                                                'construct',
                                                'construct-only',
-                                               'uint64'])
-            self.assertEqual(len(obj), 4)
+                                               'uint64',
+                                               'enum'])
+            self.assertEqual(len(obj), 5)
 
     def testNormal(self):
         obj = new(PropertyObject, normal="123")
@@ -127,6 +133,34 @@
             (etype, ex) = sys.exc_info()[2:]
             self.fail(str(ex))
 
+    def testEnum(self):
+        obj = new(PropertyObject)
+        self.assertEqual(obj.props.enum, Gio.SocketType.STREAM)
+        self.assertEqual(obj.enum, Gio.SocketType.STREAM)
+        obj.enum = Gio.SocketType.DATAGRAM
+        self.assertEqual(obj.props.enum, Gio.SocketType.DATAGRAM)
+        self.assertEqual(obj.enum, Gio.SocketType.DATAGRAM)
+        obj.props.enum = Gio.SocketType.STREAM
+        self.assertEqual(obj.props.enum, Gio.SocketType.STREAM)
+        self.assertEqual(obj.enum, Gio.SocketType.STREAM)
+        obj.props.enum = 2
+        self.assertEqual(obj.props.enum, Gio.SocketType.DATAGRAM)
+        self.assertEqual(obj.enum, Gio.SocketType.DATAGRAM)
+        obj.enum = 1
+        self.assertEqual(obj.props.enum, Gio.SocketType.STREAM)
+        self.assertEqual(obj.enum, Gio.SocketType.STREAM)
+
+        self.assertRaises(TypeError, setattr, obj, 'enum', 'foo')
+        self.assertRaises(TypeError, setattr, obj, 'enum', object())
+
+        self.assertRaises(TypeError, gobject.property, type=Gio.SocketType)
+        self.assertRaises(TypeError, gobject.property, type=Gio.SocketType,
+                          default=Gio.SocketProtocol.TCP)
+        self.assertRaises(TypeError, gobject.property, type=Gio.SocketType,
+                          default=object())
+        self.assertRaises(TypeError, gobject.property, type=Gio.SocketType,
+                          default=1)
+
     def testRange(self):
         # kiwi code
         def max(c):
@@ -270,8 +304,6 @@
         # self.assertRaises(TypeError, gobject.property, type=bool, default=0)
         self.assertRaises(TypeError, gobject.property, type=bool, default='ciao mamma')
         self.assertRaises(TypeError, gobject.property, type=bool)
-        self.assertRaises(TypeError, gobject.property, type=GEnum)
-        self.assertRaises(TypeError, gobject.property, type=GEnum, default=0)
         self.assertRaises(TypeError, gobject.property, type=object, default=0)
         self.assertRaises(TypeError, gobject.property, type=complex)
         self.assertRaises(TypeError, gobject.property, flags=-10)
endef

###################################################################################
###################################################################################
###################################################################################
define PERL5_PATCH
@@ -6788,6 +6788,26 @@
 #  define DOUBLE_VAX_ENDIAN
 #endif
 
+/* We have somehow managed not to define the denormal/subnormal
+ * detection.
+ *
+ * This may happen if the compiler doesn't expose the C99 math like
+ * the fpclassify() without some special switches.  Perl tries to
+ * stay C89, so for example -std=c99 is not an option.
+ *
+ * The Perl_isinf() and Perl_isnan() should have been defined even if
+ * the C99 isinf() and isnan() are unavailable, and the NV_MIN becomes
+ * from the C89 DBL_MIN or moral equivalent. */
+#if !defined(Perl_fp_class_denorm) && defined(Perl_isinf) && defined(Perl_isnan) && defined(NV_MIN)
+#  define Perl_fp_class_denorm(x) ((x) != 0.0 && !Perl_isinf(x) && !Perl_isnan(x) && PERL_ABS(x) < NV_MIN)
+#endif
+
+/* This is not a great fallback: subnormals tests will fail,
+ * but at least Perl will link and 99.999% of tests will work. */
+#if !defined(Perl_fp_class_denorm)
+#  define Perl_fp_class_denorm(x) FALSE
+#endif
+
 #ifdef DOUBLE_IS_IEEE_FORMAT
 /* All the basic IEEE formats have the implicit bit,
  * except for the x86 80-bit extended formats, which will undef this.
endef
###################################################################################
###################################################################################
###################################################################################
#
# Function Defines
#
define LNBIN
	test -f /usr/bin/$1 || /usr/bin/sudo ln -sf /usr/local/bin/$1 /usr/bin/.
endef

# call LNLIB libssp.a
define LNLIB
	test -f /lib/$1 || test -L /lib/$1 || /usr/bin/sudo ln -sf /usr/local/lib/$1 /lib/.
endef

define MKVRFYDIR
	echo mkdir -p --verbose $1
	mkdir -p --verbose $1
	cd $1; readlink -f . | grep $1
endef

define SOURCEBANNER
	@echo "======================================"
	@echo "=======    Start $1"
	@echo "======================================"
endef

# tcp_wrappers uses underscore in front of the version number
# Unfortunately, the make install for some of these packages corrupt the
# build directories with some amount of root owned files, so we need
# to use sudo to remove them
define SOURCEBASE
	$(call MKVRFYDIR,$1)
	cd $1; find . -maxdepth 1 -type d -name $1-\* -print -exec /usr/bin/sudo /bin/rm -rf {} \;
	cd $1; find . -maxdepth 1 -type d -name $1_\* -print -exec /usr/bin/sudo /bin/rm -rf {} \;
	cd $1; /usr/bin/sudo /bin/rm -rf *-build
endef

# 1 - name of the project
# 2 - expected partial name of the directory that was untarred, the untar name
define MAKEUNTARDIR
	-cd $1; /bin/rm -f untar.dir
	cd $1; find . -maxdepth 1 -type d -name $2\* -print | egrep -v '.-build' > untar.dir
	cd $1/`cat $1/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
endef

# 1 - name of the project
# 2 - tar options, xf or xfz
# 3 - expected partial name of the directory that was untarred, the untar name
define SOURCEDIR_W_UNTAR
	$(call SOURCEBANNER,$1)
	$(call SOURCEBASE,$1)
	echo ---###---
	cd $1; tar $2 $1*.tar* || tar $2 $1*.tgz || tar $2 $1*.tar || tar xf $1*.tar* || /usr/local/bin/tar xf $1*.tar* || unzip $1*.zip || unzip master.zip || tar xfz *.tar.gz || tar xfz *.tgz || ( mkdir $1; cd $1; tar xf ../master.tar.gz ) || test -d $1
	echo ---###---
	$(call MAKEUNTARDIR,$1,$3)
endef

# Old versions of tar may not handle all archives and may not dynamically detect
# how the archive is compressed. So we will try multiple ways and also see if
# we have a version in /usr/local/bin that can handle it.
# 1 - name of the project
# 2 - tar options, xf or xfz
define SOURCEDIR
	$(call SOURCEDIR_W_UNTAR,$1,$2,$1)
endef

define SOURCEFLATZIPDIR
	$(call SOURCEBANNER,$1)
	$(call SOURCEBASE,$1)
	echo ---###---
	cd $1; mkdir -p $1
	cd $1/$1; unzip -o ../$1*.zip
	echo ---###---
	$(call MAKEUNTARDIR,$1,$1)
endef

# cd $1; test ! -e $1-*.patch || /bin/mv $1-*.patch $$HOME/files/backups/oldpackages/.
define SOURCECLEAN
	$(call SOURCEBASE,$1)
	-cd $1; mkdir -p $$HOME/files/backups/oldpackages
	-cd $1; /usr/bin/sudo mkdir -p $$HOME/files/backups/oldpackages
	-cd $1; /usr/bin/sudo chown $(USERNAME) $$HOME/files/backups/oldpackages
	-cd $1; /bin/rm -rf `basename $1`
	-cd $1; /bin/rm -f `basename $2`
	-cd $1; test ! -e $1-*.tar || /bin/mv $1-*.tar $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tgz || /bin/mv $1-*.tgz $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tar.gz || /bin/mv $1-*.tar.gz $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tar.xz || /bin/mv $1-*.tar.xz $$HOME/files/backups/oldpackages/.
	-cd $1; test ! -e $1-*.tar.bz2 || /bin/mv $1-*.tar.bz2 $$HOME/files/backups/oldpackages/.
endef

define SOURCEWGET
	$(call SOURCECLEAN,$1,$2)
	echo wget --no-check-certificate $2
	cd $1; wget --no-check-certificate $2
endef

define SOURCEGIT
	$(call SOURCECLEAN,$1,$2)
	-cd $1; /bin/rm -rf `basename $2 .git`
	-cd $1; /bin/rm -rf master.zip
	cd $1; git clone $2
endef

define PATCHWGET
	$(call MKVRFYDIR,patches)
	-cd patches; /bin/rm -f `basename $1`
	cd patches; wget --no-check-certificate $1
endef

define CPLIB
	cd /usr/local/lib; for FILE in $1; do if test -e /usr/local/lib/$$FILE ; then test -f /lib/$$FILE || test -L /lib/$$FILE || /usr/bin/sudo ln -sf /usr/local/lib/$$FILE /lib/. ; fi ; done ; /usr/bin/sudo /bin/rm -f /lib/*.scm /lib/*.py ; /usr/bin/sudo /sbin/ldconfig
endef

define RENEXE
	cd /usr/local/bin; for FILE in $1; do if test -e /usr/local/bin/$$FILE; then export n=0; while test -e /usr/local/bin/$$FILE.old.$$n ; do export n=$$((n+1)); done ; /usr/bin/sudo mv $$FILE $$FILE.old.$$n ; fi ; done
endef

define PKGFROMSTAGE
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
	-cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/packaged
	/bin/mkdir -p packages
	cd $1/$2/; /usr/bin/sudo tar -C /tmp/$3 -czf /tmp/packaged/$1.tar.gz .
	-/bin/rm -f packages/$1.tar.gz
	/bin/cp /tmp/packaged/$1.tar.gz packages
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/packaged
endef

define PKGINSTALLTO
	@echo "======= Start of $1 Successful ======="
	cd $1/$2/; /usr/bin/sudo make install || /usr/bin/sudo make LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib" install
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/stage
	cd $1/$2/; /usr/bin/sudo make DESTDIR=/tmp/stage install || /usr/bin/sudo make LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib" DESTDIR=/tmp/stage install
	$(call PKGFROMSTAGE,$1,$2,stage)
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	@echo "======= Install of $1 Successful ======="
endef

# Some packages do not have configure and depend on the PREFIX
# and DESTDIR variables to determine where they should install
# Some Makefiles use prefix, some use PREFIX
# 1 - name of the project and base directory
# 2 - expected partial name of the directory that was untarred, the untar name
define PKGINSTALLTOPREFIX
	@echo "======= Start of $1 Successful ======="
	cd $1/$2/; /usr/bin/sudo make prefix=/usr/local PREFIX=/usr/local install || /usr/bin/sudo make LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib" PREFIX=/usr/local install
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
	cd $1/$2/; /usr/bin/sudo /bin/mkdir -p /tmp/stage
	cd $1/$2/; /usr/bin/sudo make prefix=/usr/local PREFIX=/usr/local DESTDIR=/tmp/stage install || /usr/bin/sudo make LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib" PREFIX=/usr/local DESTDIR=/tmp/stage install
	$(call PKGFROMSTAGE,$1,$2,stage)
	-cd $1/$2/; /usr/bin/sudo /bin/rm -rf /tmp/stage
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
ZHDR_DIR = /usr/local/include
ZLIB_VERSION = "1.2.8"
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
phase1: \
    target_test \
    target_dirs \
     nameservers \
     check_sudo \
     scripts \
     devices \
     make \
     zlib \
     gzip \
     tar \
     xz \
     perl \
     texinfo \
     binutils \
     coreutils \
     save_ld \
     findutils \
     diffutils \
     which \
     symlinks \
     m4 \
     ecj \
     gmp \
     mpfr \
     mpc \
     libelf \
     bison \
     flex \
     gawk \
     libtool \
     sed \
     bzip \
     sqlite \
     zip \
     unzip \
     autoconf \
     libunistring \
     libatomic_ops \
     gc \
     libffi \
     gettext \
     libiconv \
     gettext \
     pkg-config \
     guile \
     restore_ld \
     gcc

# db needs C++
# lzma needs C++
# lzip needs C++
#
# run ca-cert twice. The shell scripts are sloppy. They want to
# manipulate the previously installed certs
# Need the certs for Python Pip and git
#
# We may need to pull packages with git, so we need this as soon
# as we have a reasonable C compiler ready, but after we have
# the ca-certs installed.
#
# Watch to see if git hangs in the tests
#
.PHONY: aftergcc
aftergcc: \
    check_sudo \
    musl \
    ca-cert \
    ca-cert \
    pcre \
    pcre2 \
    grep \
    db \
    lzma \
    gdbm \
    gettext \
    libiconv \
    gettext \
    expat \
    aftergettext

# took out Net-SSLeay
#     Net-SSLeay IO-Socket-SSL 

.PHONY: aftergettext
aftergettext: \
    check_sudo \
    openssl \
    afteropenssl

.PHONY: afteropenssl
afteropenssl: \
    check_sudo \
    Python \
    afterpython

.PHONY: afterpython
afterpython: \
    check_sudo \
    Archive-Zip \
    Digest-SHA1 \
    Scalar-MoreUtils \
    Test-Needs \
    URI \
    HTML-Tagset \
    HTML-Parser \
    Devel-Symdump \
    Pod-Coverage \
    Test-Pod \
    Test-Pod-Coverage \
    XML-Parser \
    IO-HTML \
    LWP-MediaTypes \
    HTTP-Date \
    Encode-Locale \
    Try-Tiny \
    HTTP-Message \
    HTTP-Daemon \
    WWW-RobotRules \
    File-Listing \
    HTTP-Cookies \
    HTTP-Negotiate \
    Net-HTTP \
    afternethttp

.PHONY: afternethttp
afternethttp: \
    inc-latest \
    PAR-Dist \
    File-Path \
    PathTools \
    File-Remove \
    Test-Requires \
    Module-ScanDeps \
    YAML-Tiny \
    Module-Install \
    Module-Build \
    Module-Build-XSUtil \
    Test-Exception \
    Sub-Uplevel \
    Test-Fatal \
    Test-LeakTrace \
    Class-Loader \
    pari \
    Math-Pari \
    Sub-Name \
    Params-Util \
    Sub-Install \
    Data-OptList \
    Module-Runtime \
    Module-Implementation \
    Package-Stash-XS \
    Dist-CheckConflicts \
    Package-Stash \
    Class-Load \
    Class-Load-XS \
    Test-Warn \
    Test-Warnings \
    Package-DeprecationManager \
    File-pushd \
    Module-Runtime-Conflicts \
    Capture-Tiny \
    Module-Find \
    Class-Method-Modifiers \
    Sub-Exporter-Progressive \
    Role-Tiny \
    Devel-GlobalDestruction \
    Moo \
    Sub-Exporter \
    Test-Deep \
    Exporter-Tiny \
    Type-Tiny \
    Variable-Magic \
    B-Hooks-EndOfScope \
    namespace-clean \
    ExtUtils-Config \
    ExtUtils-Helpers \
    ExtUtils-InstallPaths \
    Module-Build-Tiny \
    Crypt-Random-Source \
    List-MoreUtils \
    Test-NoWarnings \
    Net-SSLeay \
    Test-Inter \
    Date-Manip \
    Sub-Identify \
    namespace-autoclean \
    Eval-Closure \
    MRO-Compat \
    Devel-StackTrace \
    Test-CleanNamespaces \
    CPAN-Meta-Check \
    Devel-OverloadInfo \
    Moose \
    Mouse \
    Any-Moose \
    MouseX-Types \
    Test-SharedFork \
    Math-Random-ISAAC \
    Math-Random-Secure \
    Specio \
    Test-Simple \
    Importer \
    Sub-Info \
    Term-Table \
    IPC-Run3 \
    Scope-Guard \
    Module-Pluggable \
    aftermodulepluggable

aftermodulepluggable: \
    Test2-Suite \
    Test2-Plugin-NoWarnings \
    Test-Without-Module \
    Class-Data-Inheritable \
    Exception-Class \
    Params-ValidationCompiler \
    Algorithm-Diff \
    Text-Diff \
    Test-Differences \
    Scalar-List-Utils \
    Class-Singleton \
    Class-Inspector \
    Class-Tiny \
    Path-Tiny \
    Test-utf8 \
    Test-File \
    File-Copy-Recursive \
    File-ShareDir-Install \
    File-ShareDir \
    Test-File-ShareDir \
    DateTime-Locale \
    DateTime-TimeZone \
    DateTime \
    JSON-MaybeXS \
    Test-RequiresInternet \
    libwww-perl \
    IO-Socket-SSL \
    LWP-Protocol-https \
    Log-Log4perl \
    IO-BufferedSelect \
    Mojolicious \
    Digest-HMAC \
    bison \
    afterbison

# lua needs ncurses and readline. readline needs ncurses
.PHONY: afterbison
afterbison: \
    check_sudo \
    autogen \
    automake \
    tcl \
    tclx \
    expect \
    dejagnu \
    wget \
    libgpg-error \
    libgcrypt \
    libassuan \
    libksba \
    ntbtls \
    npth \
    libcap \
    libxml2 \
    libxslt \
    libutempter \
    intltool \
    glib \
    ncurses \
    readline \
    pth \
    gnupg \
    bash \
    git \
    apr \
    apr-util \
    lua \
    afterlua

.PHONY: afterlua
afterlua: \
    check_sudo \
    ruby \
    vim \
    aftervim

# If curl finds an old version of valgrind, like /usr/bin/valgrind
# it will complain about a lot of illegal instructions and such.
# valgrind may pick up the old compiler library and there may be
# bugs like uninitialize variables, so it may complain on tests.
.PHONY: aftervim
aftervim: \
    check_sudo \
    cppcheck \
    libpcap \
    jnettop \
    scrypt \
    bcrypt \
    nettle \
    libtasn1 \
    libidn \
    p11-kit \
    gnutls \
    valgrind \
    curl \
    wipe \
    srm \
    util-linux-ng \
    afterlibxml2

.PHONY: afterlibxml2
afterlibxml2: \
    check_sudo \
    lzo \
    libarchive \
    libuv \
    cmake \
    fuse \
    ntfs-3g \
    check file \
    scons \
    afterscons

.PHONY: afterscons
afterscons: \
    check_sudo \
    six \
    serf \
    protobuf \
    mosh \
    llvm \
    afterllvm

.PHONY: afterllvm
afterllvm: \
    check_sudo \
    socat \
    screen \
    libevent \
    tmux \
    autossh \
    inetutils \
    swig \
    httpd \
    subversion \
    aftersubversion

.PHONY: aftersubversion
aftersubversion: \
    check_sudo \
    psmisc \
    tcp_wrappers \
    doxygen \
    icu \
    aftericu

# Need to do harfbuzz, then freetype, the harfbuzz again
.PHONY: aftericu
aftericu: \
    check_sudo \
    harfbuzz \
    libpng \
    freetype-nohb \
    harfbuzz \
    freetype \
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
    check_sudo \
    hashdeep \
    par2cmdline \
    iptraf-ng \
    hwloc \
    whois \
    patch \
    afterpatch

.PHONY: afterpatch
afterpatch: \
    vala \
    gobject-introspection \
    jpeg \
    lxsplit \
    crosextrafonts \
    crosextrafonts-carlito \
    pngnq \
    ack \
    mercurial \
    ImageMagick \
    jq \
    gnuplot \
    openvpn \
    password-store \
    slang \
    nano \
    random \
    maldetect \
    LMDB \
    fribidi \
    libass \
    fdk-aac \
    nasm \
    yasm \
    alsa-lib \
    libogg \
    flac \
    libvorbis \
    libsndfile \
    lame \
    libtheora \
    libvpx \
    opus \
    x264 \
    x265 \
    libmpeg2 \
    ffmpeg \
    dash \
    mutt \
    c-ares \
    lynis \
    ocaml \
    boost \
    global \
    xmlsec1 \
    oath-toolkit \
    octave \
    tcpdump \
    pixman \
    rng-tools \
    gpgme \
    libmnl \
    libnftnl \
    ufw \
    tenshi \
    afterlibsecret

# Problem children
#
# pygobject needs pycairo
# pycairo needs cairo
# cairo wants libpthreads
#
# When one of these fails, I should keep shuffling it to the bottom of the
# list, giving the other packages a chance to try.
#
.PHONY: afterlibsecret
afterlibsecret: \
    libsecret \
    nftables \
    busybox \
    tcc \
    cairo \
    py2cairo \
    pygobject \
    libdnet \
    daq \
    MoarVM \
    rakudo-star \
    snort \
    qt-everywhere-opensource-src \
    gcc-6.3 \
    e2fsprogs \
    netpbm \
    vera++ \
    gdb \
    go \
    libpthread \
    pango \
    glibc \
    pinentry \
    node \
    Net-DNS \
    truecrypt

# ==============================================================
# Versions
# ==============================================================
# Things to always check
# Perl - http://www.cpan.org/src/
# OpenSSL - https://www.openssl.org/source/
# Python - https://www.python.org/downloads/source/
# GnuPG - https://gnupg.org/download/
# Subversion - https://subversion.apache.org/download.cgi
# Screen - https://ftp.gnu.org/gnu/screen/
# Libgcrypt - https://www.gnupg.org/download/index.html#libgcrypt
# ==============================================================
#
# 2018-08-26
libnftnl-ver         = libnftnl/libnftnl-1.1.1.tar.bz2
# 2018-08-26
libmnl-ver           = libmnl/libmnl-1.0.4.tar.bz2
# 2018-08-26
nftables-ver         = nftables/nftables-0.9.0.tar.bz2
# 2018-08-25
ufw-ver              = ufw/ufw-0.35.tar.gz
# freetype-ver       = freetype/freetype-2.6.1.tar.bz2
# freetype-ver       = freetype/freetype-2.6.3.tar.bz2
# 2017-01-27
freetype-ver       = freetype/freetype-2.7.1.tar.bz2
# 2018-07-29
# freetype-ver       = freetype/freetype-2.9.1.tar.gz
# 2017-01-27
# harfbuzz-ver       = harfbuzz/harfbuzz-0.9.38.tar.bz2
# harfbuzz-ver       = harfbuzz/harfbuzz-1.4.2.tar.bz2
# 2018-07-29
harfbuzz-ver       = harfbuzz/harfbuzz-1.8.4.tar.bz2
# pango-ver          = pango/pango-1.36.8.tar.xz
# 2018-07-29
pango-ver          = pango/pango-1.42.2.tar.xz
# swig-ver           = swig/swig-3.0.0.tar.gz
# 2018-07-29
swig-ver           = swig/swig-3.0.12.tar.gz
# patch-ver          = patch/patch-2.7.tar.gz
# 2018-07-29
patch-ver          = patch/patch-2.7.6.tar.gz
# mosh-ver           = mosh/mosh-1.2.5.tar.gz
# 2018-07-29
mosh-ver           = mosh/mosh-1.3.2.tar.gz
#
sed-ver            = sed/sed-4.2.2.tar.gz
# 2018-07-15
# sed-ver            = sed/sed-4.5.tar.xz
# lzo-ver            = lzo/lzo-2.08.tar.gz
# 2018-07-15
lzo-ver            = lzo/lzo-2.10.tar.gz
# 2016-09-17
# xz-ver             = xz/xz-5.0.5.tar.gz
# xz-ver             = xz/xz-5.2.2.tar.gz
# 2017-12-10
# xz-ver             = xz/xz-5.2.3.tar.gz
# 2018-07-15
xz-ver             = xz/xz-5.2.4.tar.gz
# 2018-07-07
IO-BufferedSelect-ver = IO-BufferedSelect/IO-BufferedSelect-1.0.tar.gz
# 2018-07-07
tenshi-ver = tenshi/0.17.tar.gz
# 2017-07-22
# gnupg-ver          = gnupg/gnupg-2.0.29.tar.bz2
# gnupg-ver          = gnupg/gnupg-2.0.30.tar.bz2
# gnupg-ver          = gnupg/gnupg-2.1.21.tar.bz2
# 2018-03-23
# gnupg-ver          = gnupg/gnupg-2.2.5.tar.bz2
# 2018-07-04
gnupg-ver          = gnupg/gnupg-2.2.8.tar.bz2
# 2017-07-22
# libgpg-error-ver   = libgpg-error/libgpg-error-1.20.tar.bz2
# libgpg-error-ver   = libgpg-error/libgpg-error-1.24.tar.bz2
# libgpg-error-ver   = libgpg-error/libgpg-error-1.27.tar.bz2
# 2018-07-04
libgpg-error-ver   = libgpg-error/libgpg-error-1.31.tar.bz2
# 2017-07-22
# libgcrypt-ver      = libgcrypt/libgcrypt-1.6.4.tar.bz2
# libgcrypt-ver      = libgcrypt/libgcrypt-1.7.0.tar.bz2
# libgcrypt-ver      = libgcrypt/libgcrypt-1.7.3.tar.bz2
# libgcrypt-ver      = libgcrypt/libgcrypt-1.7.3.tar.bz2
# libgcrypt-ver      = libgcrypt/libgcrypt-1.8.0.tar.bz2
# 2017-12-02
# libgcrypt-ver      = libgcrypt/libgcrypt-1.8.1.tar.bz2
# 2017-12-15
# libgcrypt-ver      = libgcrypt/libgcrypt-1.8.2.tar.bz2
# 2018-07-04
libgcrypt-ver      = libgcrypt/libgcrypt-1.8.3.tar.bz2
# 2018-07-04
gpgme-ver = gpgme/gpgme-1.11.1.tar.bz2
# libunistring-ver   = libunistring/libunistring-0.9.6.tar.xz
# 2018-02-10
# libunistring-ver   = libunistring/libunistring-0.9.8.tar.xz
# 2018-02-28
# libunistring-ver   = libunistring/libunistring-0.9.9.tar.xz
# 2018-06-27
libunistring-ver   = libunistring/libunistring-0.9.10.tar.xz
# openssl-ver        = openssl/openssl-1.0.2e.tar.gz
# 2016-03-11
# openssl-ver        = openssl/openssl-1.0.2g.tar.gz
# 2016-05-06
#
# Need pthreads.
# 2016-08-26
# openssl-ver        = openssl/openssl-1.1.0.tar.gz
# New version of apr, apr-util
# openssl-ver        = openssl/openssl-1.0.2h.tar.gz
# 2017-05-20
# openssl-ver        = openssl/openssl-1.0.2k.tar.gz
# 2017-10-11
# openssl-ver        = openssl/openssl-1.0.2l.tar.gz
# 2017-11-05
# openssl-ver        = openssl/openssl-1.0.2m.tar.gz
# 2018-01-12
# openssl-ver        = openssl/openssl-1.0.2n.tar.gz
# 2018-06-24
openssl-ver        = openssl/openssl-1.0.2o.tar.gz
# 2016-08-26
# perl-ver           = perl/perl-5.22.1.tar.gz
# perl-ver           = perl/perl-5.24.0.tar.gz
# 2017-11-05
# perl-ver           = perl/perl-5.26.0.tar.gz
# 2017-12-02
# perl-ver           = perl/perl-5.26.1.tar.gz
# 2018-03-08
# perl-ver           = perl/perl-5.27.9.tar.gz
# 2018-03-17 moving back to the stable version
# perl-ver           = perl/perl-5.26.1.tar.gz
# 2018-06-24
perl-ver           = perl/perl-5.26.2.tar.gz
# 2018-03-18
# libsecret-ver      = libsecret/libsecret-0.18.5.tar.xz
# 2018-06-23
libsecret-ver      = libsecret/libsecret-0.18.6.tar.xz
# 2017-10-10
boost-ver          = boost/boost_1_63_0.tar.bz2
# 2018-06-23
# boost-ver          = boost/boost_1_67_0.tar.bz2
# 2016-05-15
# valgrind-ver      = valgrind/valgrind-3.11.0.tar.bz2
# 2016-12-29
# Hey, valgrind seems to be sort of working!
# valgrind-ver      = valgrind/valgrind-3.12.0.tar.bz2
# 2018-06-23
valgrind-ver      = valgrind/valgrind-3.13.0.tar.bz2
# 2017-01-27
# pcre-ver           = pcre/pcre-8.38.tar.bz2
# pcre-ver           = pcre/pcre-8.40.tar.bz2
# 2017-10-04
# pcre-ver           = pcre/pcre-8.41.tar.bz2
# 2018-06-23
pcre-ver           = pcre/pcre-8.42.tar.bz2
# bison-ver          = bison/bison-3.0.tar.gz
# 2018-03-29
# bison-ver          = bison/bison-3.0.4.tar.gz
# 2018-06-16
bison-ver          = bison/bison-3.0.5.tar.gz
# pkg-config-ver     = pkg-config/pkg-config-0.29.tar.gz
# 2018-04-01
pkg-config-ver     = pkg-config/pkg-config-0.29.2.tar.gz
# flex-ver           = flex/flex-2.5.39.tar.gz
# 2018-02-23
# flex-ver           = flex/flex-2.6.4.tar.gz
# Backing off to flex 2.6.3, 2.6.4 fights with newer versions of GCC
# So if we compile PHASE1 with a host with a modern GCC, we might
# have problems.
# A fix is probably coming soon.
# Resolved 2.6.4 with a fix from Linux from Scratch
# 2018-03-29
# flex-ver           = flex/flex-2.6.3.tar.gz
flex-ver           = flex/flex-2.6.4.tar.gz
# 2016-08-27
# diffutils-ver      = diffutils/diffutils-3.3.tar.xz
# diffutils-ver      = diffutils/diffutils-3.5.tar.xz
# 2018-03-28
diffutils-ver      = diffutils/diffutils-3.6.tar.xz
# scrypt-ver         = scrypt/scrypt-1.1.6.tgz
# 2018-03-28
scrypt-ver         = scrypt/scrypt-1.2.1.tgz
# dejagnu-ver        = dejagnu/dejagnu-1.5.3.tar.gz
# 2018-03-27
dejagnu-ver        = dejagnu/dejagnu-1.6.tar.gz
# 2016-01-17
# cppcheck-ver       = cppcheck/cppcheck-1.71.tar.bz2
# cppcheck-ver       = cppcheck/cppcheck-1.72.tar.bz2
# 2018-03-24
cppcheck-ver       = cppcheck/1.82.tar.gz
# p11-kit-ver        = p11-kit/p11-kit-0.23.2.tar.gz
# 2018-03-24
p11-kit-ver        = p11-kit/p11-kit-0.23.10.tar.gz
# libtasn1-ver       = libtasn1/libtasn1-4.3.tar.gz
# 2018-03-24
libtasn1-ver       = libtasn1/libtasn1-4.13.tar.gz
# libxml2-ver        = libxml2/libxml2-2.9.3.tar.gz
# 2018-01-27
# libxml2-ver        = libxml2/libxml2-2.9.7.tar.gz
# 2018-03-23
libxml2-ver        = libxml2/libxml2-2.9.8.tar.gz
# 2018-03-23
six-ver = six/six-1.11.0.tar.gz
# autogen-ver        = autogen/autogen-5.18.7.tar.xz
# 2018-03-21
autogen-ver        = autogen/autogen-5.18.12.tar.xz
# 2016-09-23
# XML-Parser-ver     = XML-Parser/XML-Parser-2.36.tar.gz
# 2018-03-18
XML-Parser-ver     = XML-Parser/XML-Parser-2.44.tar.gz
# 2018-03-18
intltool-ver       = intltool/intltool-0.51.0.tar.gz
# 2017-10-10
# automake-ver       = automake/automake-1.15.tar.xz
# automake-ver       = automake/automake-1.15.1.tar.xz
# 2018-03-18
automake-ver       = automake/automake-1.16.1.tar.xz
# IO-Socket-SSL-ver  = IO-Socket-SSL/IO-Socket-SSL-2.012.tar.gz
# 2018-03-18
IO-Socket-SSL-ver  = IO-Socket-SSL/IO-Socket-SSL-2.056.tar.gz
# libwww-perl-ver    = libwww-perl/libwww-perl-6.15.tar.gz
# 2018-03-18
libwww-perl-ver    = libwww-perl/libwww-perl-6.33.tar.gz
# 2018-03-18
Test-utf8-ver = Test-utf8/Test-utf8-1.01.tar.gz
# 2018-03-18
Test-File-ver = Test-File/Test-File-1.443.tar.gz
# 2017-03-05
# 2018-03-18
Exception-Class-ver = Exception-Class/Exception-Class-1.44.tar.gz
# 2018-03-18
Module-Pluggable-ver = Module-Pluggable/Module-Pluggable-5.2.tar.gz
# 2017-03-04
# Test2-Suite-ver = Test2-Suite/Test2-Suite-0.000067.tar.gz
# 2018-03-11
# Test2-Suite-ver = Test2-Suite/Test2-Suite-0.000108.tar.gz
# 2018-03-18
Test2-Suite-ver = Test2-Suite/Test2-Suite-0.000111.tar.gz
# 2018-03-18
IPC-Run3-ver = IPC-Run3/IPC-Run3-0.048.tar.gz
# 2017-03-05
# Test2-Plugin-NoWarnings-ver = Test2-Plugin-NoWarnings/Test2-Plugin-NoWarnings-0.05.tar.gz
# 2018-03-18
Test2-Plugin-NoWarnings-ver = Test2-Plugin-NoWarnings/Test2-Plugin-NoWarnings-0.06.tar.gz
# 2018-03-18
Test-SharedFork-ver = Test-SharedFork/Test-SharedFork-0.35.tar.gz
# 2016-06-04
Math-Random-Secure-ver = Math-Random-Secure/Math-Random-Secure-0.080001.tar.gz
# 2018-03-18
ExtUtils-InstallPaths-ver = ExtUtils-InstallPaths/ExtUtils-InstallPaths-0.011.tar.gz
# 2018-03-18
ExtUtils-Helpers-ver = ExtUtils-Helpers/ExtUtils-Helpers-0.026.tar.gz
# 2018-03-18
ExtUtils-Config-ver = ExtUtils-Config/ExtUtils-Config-0.008.tar.gz
# 2018-03-18
Module-Build-Tiny-ver = Module-Build-Tiny/Module-Build-Tiny-0.039.tar.gz
# 2016-06-04
# Mouse-ver         = Mouse/Mouse-v2.4.5.tar.gz
# 2018-03-18
Mouse-ver         = Mouse/Mouse-v2.5.2.tar.gz
# 2017-03-04
# Devel-StackTrace-ver = Devel-StackTrace/Devel-StackTrace-2.02.tar.gz
# 2018-03-18
Devel-StackTrace-ver = Devel-StackTrace/Devel-StackTrace-2.03.tar.gz
# 2017-03-10
# Devel-OverloadInfo-ver = Devel-OverloadInfo/Devel-OverloadInfo-0.004.tar.gz
# 2017-03-18
Devel-OverloadInfo-ver = Devel-OverloadInfo/Devel-OverloadInfo-0.005.tar.gz
# HTTP-Message-ver   = HTTP-Message/HTTP-Message-6.11.tar.gz
# 2018-03-17
HTTP-Message-ver   = HTTP-Message/HTTP-Message-6.15.tar.gz
# 2018-03-17
File-Path-ver = File-Path/File-Path-2.15.tar.gz
# 2018-03-17
PathTools-ver = PathTools/PathTools-3.74.tar.gz
# 2016-06-05
# List-MoreUtils-ver = List-MoreUtils/List-MoreUtils-0.413.tar.gz
# List-MoreUtils-ver = List-MoreUtils/List-MoreUtils-0.415.tar.gz
# 2018-03-12
List-MoreUtils-ver = List-MoreUtils/List-MoreUtils-0.428.tar.gz
# 2016-06-05
# Module-Runtime-ver = Module-Runtime/Module-Runtime-0.014.tar.gz
# 2018-03-12
Module-Runtime-ver = Module-Runtime/Module-Runtime-0.016.tar.gz
# 2016-06-04
pari-ver         = pari/pari-2.3.5.tar.gz
# 2018-03-12
# pari-ver         = pari/pari-2.9.4.tar.gz
# 2018-03-12
YAML-Tiny-ver = YAML-Tiny/YAML-Tiny-1.73.tar.gz
# 2018-03-12
Module-ScanDeps-ver = Module-ScanDeps/Module-ScanDeps-1.24.tar.gz
# 2018-03-12
File-Remove-ver = File-Remove/File-Remove-1.57.tar.gz
# 2018-03-12
Module-Install-ver = Module-Install/Module-Install-1.19.tar.gz
# 2016-06-04
# Module-Build-ver  = Module-Build/Module-Build-0.4218.tar.gz
# 2018-03-12
Module-Build-ver  = Module-Build/Module-Build-0.4224.tar.gz
# 2016-06-04
# PAR-Dist-ver      = PAR-Dist/PAR-Dist-0.11.tar.gz
# 2018-03-12
PAR-Dist-ver      = PAR-Dist/PAR-Dist-0.49.tar.gz
# 2016-06-05
# Variable-Magic-ver = Variable-Magic/Variable-Magic-0.59.tar.gz
# 2018-03-11
Variable-Magic-ver = Variable-Magic/Variable-Magic-0.62.tar.gz
# 2016-09-23
# URI-ver            = URI/URI-1.69.tar.gz
# URI-ver            = URI/URI-1.71.tar.gz
# 2018-03-11
URI-ver            = URI/URI-1.73.tar.gz
# 2016-06-04
# Try-Tiny-ver      = Try-Tiny/Try-Tiny-0.24.tar.gz
# 2018-03-11
Try-Tiny-ver      = Try-Tiny/Try-Tiny-0.30.tar.gz
# 2017-03-10
# Text-Diff-ver = Text-Diff/Text-Diff-1.44.tar.gz
# 2018-03-11
Text-Diff-ver = Text-Diff/Text-Diff-1.45.tar.gz
# 2017-03-05
# Test-Simple-ver = Test-Simple/Test-Simple-1.302075.tar.gz
# 2018-03-11
Test-Simple-ver = Test-Simple/Test-Simple-1.302133.tar.gz
# 2017-03-05
# Term-Table-ver = Term-Table/Term-Table-0.006.tar.gz
# 2018-03-11
Term-Table-ver = Term-Table/Term-Table-0.012.tar.gz
# 2017-03-04
# Specio-ver = Specio/Specio-0.31.tar.gz
# 2018-03-11
Specio-ver = Specio/Specio-0.42.tar.gz
# 2017-03-10
# Scalar-List-Utils-ver = Scalar-List-Utils/Scalar-List-Utils-1.47.tar.gz
# 2018-03-11
Scalar-List-Utils-ver = Scalar-List-Utils/Scalar-List-Utils-1.50.tar.gz
# 2017-03-04
# Params-ValidationCompiler-ver = Params-ValidationCompiler/Params-ValidationCompiler-0.13.tar.gz
# 2018-03-11
Params-ValidationCompiler-ver = Params-ValidationCompiler/Params-ValidationCompiler-0.27.tar.gz
# 2017-03-10
# Moose-ver = Moose/Moose-2.2004.tar.gz
# 2018-03-11
Moose-ver = Moose/Moose-2.2010.tar.gz
# 2017-03-10
# Mojolicious-ver = Mojolicious/Mojolicious-7.28.tar.gz
# 2018-03-11
Mojolicious-ver = Mojolicious/Mojolicious-7.70.tar.gz
# 2017-10-04
# File-Copy-Recursive-ver = File-Copy-Recursive/File-Copy-Recursive-0.38.tar.gz
# 2018-03-11
File-Copy-Recursive-ver = File-Copy-Recursive/File-Copy-Recursive-0.40.tar.gz
# Devel-Symdump-ver  = Devel-Symdump/Devel-Symdump-2.15.tar.gz
# 2018-03-11
Devel-Symdump-ver  = Devel-Symdump/Devel-Symdump-2.18.tar.gz
# 2017-03-04
# DateTime-ver       = DateTime/DateTime-1.42.tar.gz
# 2018-03-11
DateTime-ver       = DateTime/DateTime-1.46.tar.gz
# 2017-03-04
# DateTime-TimeZone-ver = DateTime-TimeZone/DateTime-TimeZone-2.10.tar.gz
# 2018-03-11
DateTime-TimeZone-ver = DateTime-TimeZone/DateTime-TimeZone-2.17.tar.gz
# 2017-03-04
# Date-Manip-ver     = Date-Manip/Date-Manip-6.58.tar.gz
# 2018-03-11
Date-Manip-ver     = Date-Manip/Date-Manip-6.70.tar.gz
# 2017-10-06
# rng-tools-ver      = rng-tools/rng-tools-5.tar.gz
# 2018-03-11
rng-tools-ver      = rng-tools/v6.1.tar.gz
# 2017-10-05
# pcre2-ver          = pcre2/pcre2-10.30.tar.bz2
# 2018-03-11
pcre2-ver          = pcre2/pcre2-10.31.tar.bz2
# libarchive-ver     = libarchive/libarchive-3.1.2.tar.gz
# 2018-03-09
libarchive-ver     = libarchive/libarchive-3.3.2.tar.gz
# libiconv-ver       = libiconv/libiconv-1.14.tar.gz
# 2018-02-10
libiconv-ver       = libiconv/libiconv-1.15.tar.gz
# pixman-ver         = pixman/pixman-0.32.6.tar.gz
# 2018-02-27
pixman-ver         = pixman/pixman-0.34.0.tar.gz
# unzip-ver          = unzip/unzip60.tar.gz
# changing to info-zip rather than sourceforge
# 2016-02-25
unzip-ver          = unzip/unzip60.tgz
# protobuf-ver       = protobuf/protobuf-2.5.0.tar.bz2
# not sure that I can tolerate protobuf proto3 yet
# 2018-02-24
protobuf-ver       = protobuf/protobuf-2.6.1.tar.gz
# nettle-ver         = nettle/nettle-3.1.1.tar.gz
# 2018-02-24
nettle-ver         = nettle/nettle-3.4.tar.gz
# 2017-02-18
# fribidi-ver        = fribidi/fribidi-0.19.7.tar.bz2
# 2018-02-24
fribidi-ver        = fribidi/v1.0.1.tar.gz
# symlinks-ver       = symlinks/symlinks-1.4.tar.gz
# 2018-02-24
symlinks-ver       = symlinks/v1.4.3.tar.gz
# tcl-ver            = tcl/tcl8.6.3-src.tar.gz
tcl-ver            = tcl/tcl8.6.8-src.tar.gz
# binutils-ver       = binutils/binutils-2.24.tar.gz
# 2017-10-07
# binutils-ver       = binutils/binutils-2.29.1.tar.gz
# 2018-02-17
binutils-ver       = binutils/binutils-2.30.tar.gz
# 2016-09-23, Checked, zlib is still 1.2.8 2013-04-28
# zlib-ver           = zlib/zlib-1.2.8.tar.gz
zlib-ver           = zlib/zlib-1.2.11.tar.gz
texinfo-ver        = texinfo/texinfo-5.2.tar.gz
# 2018-02-10
# texinfo-ver        = texinfo/texinfo-6.5.tar.xz
# unrar-ver          = unrar/unrarsrc-5.3.3.tar.gz
# 2018-02-10
unrar-ver          = unrar/unrarsrc-5.5.8.tar.gz
# 2016-09-23
# vim-ver            = vim/vim-7.4.tar.bz2
# vim-ver            = vim/v8.0.0008.tar.gz
# 2018-02-10
vim-ver            = vim/v8.0.1493.tar.gz
# 2018-02-03 
busybox-ver = busybox/busybox-1.28.0.tar.bz2
# 2018-02-03 
musl-ver = musl/musl-1.1.18.tar.gz
# libxslt-ver        = libxslt/libxslt-1.1.28.tar.gz
# 2018-01-27
libxslt-ver        = libxslt/libxslt-1.1.32.tar.gz
# 2018-01-27
xmlsec1-ver = xmlsec1/xmlsec1-1.2.25.tar.gz
# 2018-01-27
oath-toolkit-ver = oath-toolkit/oath-toolkit-2.6.2.tar.gz
# par2cmdline-ver    = par2cmdline/master.zip
# 2018-01-27
par2cmdline-ver    = par2cmdline/v0.8.0.tar.gz
# doxygen-ver        = doxygen/doxygen-1.8.9.1.src.tar.gz
# 2017-12-31
doxygen-ver        = doxygen/Release_1_8_14.tar.gz
# 2017-12-15
global-ver        = global/global-6.6.tar.gz
# screen-ver         = screen/screen-4.3.1.tar.gz
# 2017-12-15
screen-ver         = screen/screen-4.6.2.tar.gz
# 2016-08-20
# libassuan-ver      = libassuan/libassuan-2.3.0.tar.bz2
# libassuan-ver      = libassuan/libassuan-2.4.3.tar.bz2
# 2017-12-02
# libassuan-ver      = libassuan/libassuan-2.4.5.tar.bz2
# 2017-12-10
libassuan-ver      = libassuan/libassuan-2.5.1.tar.bz2
# 2016-08-20
# pinentry-ver       = pinentry/pinentry-0.9.5.tar.bz2
pinentry-ver       = pinentry/pinentry-0.9.7.tar.bz2
# 2017-12-10
# pinentry-ver       = pinentry/pinentry-1.1.0.tar.bz2
# 2016-05-19
# p7zip-ver          = p7zip/p7zip_9.38.1_src_all.tar.bz2
# p7zip-ver         = p7zip/p7zip_15.14.1_src_all.tar.bz2
# 2017-12-10
p7zip-ver         = p7zip/p7zip_16.02_src_all.tar.bz2
# 2016-01-10
# subversion-ver     = subversion/subversion-1.8.9.tar.bz2
# subversion-ver     = subversion/subversion-1.9.3.tar.bz2
# 2017-12-10
subversion-ver     = subversion/subversion-1.9.7.tar.bz2
# 2017-07-22
# ntbtls-ver         = ntbtls/ntbtls-0.1.1.tar.bz2
# 2017-12-02
ntbtls-ver         = ntbtls/ntbtls-0.1.2.tar.bz2
# 2017-12-02
MoarVM-ver = MoarVM/MoarVM-2017.09.1.tar.gz
# 2016-07-24
# rakudo-star-ver    = rakudo-star/rakudo-star-2016.07.tar.gz
# 2017-12-02
rakudo-star-ver    = rakudo-star/rakudo-star-2017.10.tar.gz
# 2017-10-19
gcc-7.2-ver          = gcc-7.2/gcc-7.2.0.tar.gz
# make-ver           = make/make-4.1.tar.gz
# 2017-10-11
make-ver           = make/make-4.2.1.tar.gz
# libtool-ver        = libtool/libtool-2.4.2.tar.gz
# 2017-10-11
libtool-ver        = libtool/libtool-2.4.6.tar.gz
# 2016-01-23
# Python-ver         = Python/Python-2.7.10.tar.xz
# Python-ver         = Python/Python-2.7.11.tar.xz
# 2017-01-27
# Python-ver         = Python/Python-2.7.13.tar.xz
# 2017-10-11
Python-ver         = Python/Python-2.7.14.tar.xz
# 2017-10-10
libuv-ver          = libuv/v1.15.0.tar.gz
# 2017-10-10
# 2016-02-27
cmake-ver          = cmake/cmake-3.4.3.tar.gz
# 2017-10-10
# cmake-ver          = cmake/cmake-3.9.4.tar.gz
# 2016-04-08
# git-ver            = git/git-2.2.1.tar.xz
# git-ver            = git/git-2.8.1.tar.xz
# 2017-10-06
git-ver            = git/git-2.14.2.tar.xz
# 2017-10-04
ocaml-ver          = ocaml/ocaml-4.05.0.tar.gz
# 2017-10-04
Path-Tiny-ver       = Path-Tiny-ver/Path-Tiny-0.104.tar.gz
# 2017-10-04
Scope-Guard-ver     = Scope-Guard-ver/Scope-Guard-0.21.tar.gz
# 2017-10-04
Class-Tiny-ver      = Class-Tiny/Class-Tiny-1.006.tar.gz
# 2017-10-04
Class-Inspector-ver = Class-Inspector/Class-Inspector-1.32.tar.gz
# 2017-10-04
File-ShareDir-ver   = File-ShareDir/File-ShareDir-1.104.tar.gz
# 2017-10-04
Test-File-ShareDir-ver = Test-File-ShareDir/Test-File-ShareDir-1.001002.tar.gz
# 2017-10-04
File-ShareDir-Install-ver = File-ShareDir-Install/File-ShareDir-Install-0.11.tar.gz
# 2017-10-03
lynis-ver          = lynis/lynis-2.5.5.tar.gz
# 2017-09-25
c-ares-ver         = c-ares/c-ares-1.12.0.tar.gz
# 2017-07-22
# tar-ver            = tar/tar-1.28.tar.gz
tar-ver            = tar/tar-1.29.tar.gz
# 2017-07-22
# npth-ver      = npth/npth-1.2.tar.bz2
npth-ver      = npth/npth-1.5.tar.bz2
# 2017-07-22
# libksba-ver        = libksba/libksba-1.3.3.tar.bz2
# libksba-ver        = libksba/libksba-1.3.4.tar.bz2
libksba-ver        = libksba/libksba-1.3.5.tar.bz2
# serf-ver           = serf/serf-1.3.5.tar.bz2
# 2017-05-20 serf is failing to build, trying a new version
# Nope, it fails due to certificates that are now expired
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=862027
serf-ver           = serf/serf-1.3.9.tar.bz2
# 2017-05-20 serf needs new scons
# scons-ver          = scons/scons-2.3.4.tar.gz
scons-ver          = scons/scons-2.5.1.tar.gz
# 2017-03-10
Digest-HMAC-ver = Digest-HMAC/Digest-HMAC-1.03.tar.gz
# 2017-03-10
Net-DNS-ver = Net-DNS/Net-DNS-1.08.tar.gz
# 2017-03-10
Log-Log4perl-ver = Log-Log4perl/Log-Log4perl-1.49.tar.gz
# 2017-03-10
Test-RequiresInternet-ver = Test-RequiresInternet/Test-RequiresInternet-0.05.tar.gz
# 2017-03-10
LWP-Protocol-https-ver = LWP-Protocol-https/LWP-Protocol-https-6.07.tar.gz
# 2017-03-10
JSON-MaybeXS-ver = JSON-MaybeXS/JSON-MaybeXS-1.003009.tar.gz
# 2017-03-10
Class-Singleton-ver = Class-Singleton/Class-Singleton-1.5.tar.gz
# 2017-03-10
Module-Runtime-Conflicts-ver = Module-Runtime-Conflicts/Module-Runtime-Conflicts-0.003.tar.gz
# 2017-03-10
File-pushd-ver = File-pushd/File-pushd-1.014.tar.gz
# 2017-03-10
Test-Deep-ver = Test-Deep/Test-Deep-1.126.tar.gz
# 2017-03-10
Test-CleanNamespaces-ver = Test-CleanNamespaces/Test-CleanNamespaces-0.22.tar.gz
# 2017-03-10
Class-Load-XS-ver = Class-Load-XS/Class-Load-XS-0.09.tar.gz
# 2017-03-10
Test-Warnings-ver = Test-Warnings/Test-Warnings-0.026.tar.gz
# 2017-03-10
Package-DeprecationManager-ver = Package-DeprecationManager/Package-DeprecationManager-0.17.tar.gz
# 2017-03-10
Sub-Name-ver = Sub-Name/Sub-Name-0.21.tar.gz
# 2017-03-10
Class-Load-ver = Class-Load/Class-Load-0.23.tar.gz
# 2017-03-10
MouseX-Types-ver = MouseX-Types/MouseX-Types-0.06.tar.gz
# 2017-03-10
Algorithm-Diff-ver = Algorithm-Diff/Algorithm-Diff-1.1903.tar.gz
# 2017-03-10
Test-Differences-ver = Test-Differences/Test-Differences-0.64.tar.gz
# 2017-03-10
CPAN-Meta-Check-ver = CPAN-Meta-Check/CPAN-Meta-Check-0.014.tar.gz
# 2017-03-05
DateTime-Locale-ver = DataTime-Locale/DateTime-Locale-1.16.tar.gz
# 2017-03-05
Class-Data-Inheritable-ver = Class-Data-Inheritable/Class-Data-Inheritable-0.08.tar.gz
# 2017-03-05
Test-Without-Module-ver = Test-Without-Module/Test-Without-Module-0.18.tar.gz
# 2017-03-05
Sub-Info-ver = Sub-Info/Sub-Info-0.002.tar.gz
# 2017-03-05
Importer-ver = Importer/Importer-0.024.tar.gz
# 2017-03-04
Test-Needs-ver = Test-Needs/Test-Needs-0.002001.tar.gz
# 2017-03-04
MRO-Compat-ver = MRO-Compat/MRO-Compat-0.12.tar.gz
# 2017-03-04
Eval-Closure-ver = Eval-Closure/Eval-Closure-0.14.tar.gz
# 2017-03-04
Sub-Identify-ver   = Sub-Identify/Sub-Identify-0.12.tar.gz
# 2017-03-04
namespace-autoclean-ver = namespace-autoclean/namespace-autoclean-0.28.tar.gz
# 2017-03-04
Test-Inter-ver     = Test-Inter/Test-Inter-1.06.tar.gz
# 2016-06-05
# Capture-Tiny-ver = Capture-Tiny/Capture-Tiny-0.42.tar.gz
# 2017-03-04
Capture-Tiny-ver   = Capture-Tiny/Capture-Tiny-0.46.tar.gz
# 2017-02-26
libmpeg2-ver       = libmpeg2/libmpeg2-0.5.1.tar.gz
# 2017-02-25
dash-ver           = dash/dash-0.5.9.1.tar.gz
# 2017-02-24
# libpthread-ver     = libpthread/master.zip
libpthread-ver     = libpthread/libpthread-glibc-2.23-hurd+libpthread-20161218.tar.gz
# 2017-02-19
ffmpeg-ver         = ffmpeg/ffmpeg-3.2.4.tar.xz
# 2017-02-18
x265-ver           = x265/x265_2.3.tar.gz
# 2017-02-18
x264-ver           = x264/x264-snapshot-20170212-2245-stable.tar.bz2
# 2017-02-18
opus-ver           = opus/opus-1.1.4.tar.gz
# 2017-02-18
libvpx-ver         = libvpx/libvpx-1.6.1.tar.bz2
# 2017-02-18
yasm-ver           = yasm/yasm-1.3.0.tar.gz
# 2017-02-18
libtheora-ver      = libtheora/libtheora-1.1.1.tar.xz
# 2017-02-18
# libpng-ver         = libpng/libpng-1.6.16.tar.xz
libpng-ver         = libpng/libpng-1.6.28.tar.xz
# 2017-02-18
lame-ver           = lame/lame-3.99.5.tar.gz
# 2017-02-18
octave-ver         = octave/octave-4.0.3.tar.xz
# 2017-02-18
libsndfile-ver     = libsndfile/libsndfile-1.0.27.tar.gz
# 2017-02-18
# sqlite-ver         = sqlite/sqlite-autoconf-3071502.tar.gz
sqlite-ver         = sqlite/sqlite-autoconf-3170000.tar.gz
# 2017-02-18
libvorbis-ver      = libvorbis/libvorbis-1.3.5.tar.xz
# 2017-02-18
flac-ver           = flac/flac-1.3.2.tar.xz
# 2017-02-18
libogg-ver         = libogg/libogg-1.3.2.tar.xz
# 2017-02-18
alsa-lib-ver       = alsa-lib/alsa-lib-1.1.3.tar.bz2
# 2017-02-18
nasm-ver           = nasm/nasm-2.12.02.tar.xz
# 2017-02-18
fdk-aac-ver        = fdk-aac/fdk-aac-0.1.5.tar.gz
# 2017-02-18
libass-ver         = libass/libass-0.13.6.tar.xz
# 2017-04-11
# m4-ver             = m4/m4-1.4.17.tar.gz
m4-ver             = m4/m4-1.4.18.tar.gz
# 2016-04-22
# gcc-5.3-ver        = gcc-5.3/gcc-5.3.0.tar.bz2
# 2017-01-27
gcc-6.3-ver          = gcc-6.3/gcc-6.3.0.tar.bz2
# 2017-01-27
# icu-ver            = icu/icu4c-54_1-src.tgz
icu-ver            = icu/icu4c-58_2-src.tgz
# 2017-01-27
# glib-ver           = glib/glib-2.44.1.tar.xz
glib-ver           = glib/glib-2.46.1.tar.xz
# needs libmount and openat
# glib-ver           = glib/glib-2.50.2.tar.xz
# 2016-04-18
# 2017-01-27
# fontconfig-ver     = fontconfig/fontconfig-2.11.1.tar.bz2
fontconfig-ver     = fontconfig/fontconfig-2.12.1.tar.bz2
# 2017-01-27
LMDB-ver           = LMDB/LMDB_0.9.19.tar.gz
# 2017-01-21
maldetect-ver       = maldetect/maldetect-current.tar.gz
# 2017-01-08
random-ver          = random/random.zip
# 2016-05-15
# gdb-ver            = gdb/gdb-7.9.tar.xz
# gdb-ver           = gdb/gdb-7.11.tar.xz
# 2016-12-29
gdb-ver           = gdb/gdb-7.12.tar.xz
# 2016-12-29
nano-ver           = nano/nano-2.6.3.tar.xz
# 2016-12-29
slang-ver          = slang/slang-2.3.1a.tar.bz2
# 2016-03-25
# curl-ver           = curl/curl-7.41.0.tar.bz2
# 2016-12-29
# curl-ver           = curl/curl-7.48.0.tar.bz2
# valgrind is not very happy
curl-ver           = curl/curl-7.52.1.tar.bz2
# 2016-10-16
password-store-ver = password-store/password-store-1.6.5.tar.xz
# 2016-09-24
# vala-ver           = vala/vala-0.28.1.tar.xz
vala-ver           = vala/vala-0.34.0.tar.xz
# 2016-09-23
# wget-ver           = wget/wget-1.16.3.tar.xz
wget-ver           = wget/wget-1.18.tar.xz
# 2016-09-23
# which-ver          = which/which-2.20.tar.gz
which-ver          = which/which-2.21.tar.gz
# 2016-09-23, Checked wipe is still 2.3.1 on Sourceforge, 2013-04-15
wipe-ver           = wipe/wipe-2.3.1.tar.bz2
# 2016-09-23, Checked WWW-RobotRules is still 6.02 in CPAN
WWW-RobotRules-ver = WWW-RobotRules/WWW-RobotRules-6.02.tar.gz
# 2016-09-23, Checked, Info-Zip is still 3.0 2008-09-24
zip-ver            = zip/zip30.tgz
# 2016-09-21
# db-ver             = db/db-6.1.26.tar
db-ver             = db/db-6.2.23.tar.gz
# 2016-09-09
# openvpn-ver        = openvpn/openvpn-2.3.8.tar.xz
openvpn-ver        = openvpn/openvpn-2.3.12.tar.xz
# 2016-05-15
# ImageMagick-ver   = ImageMagick/ImageMagick-7.0.1-3.tar.xz
# 2016-08-26
ImageMagick-ver   = ImageMagick/ImageMagick-7.0.2-9.tar.xz
# 2016-04-19
# gzip-ver           = gzip/gzip-1.6.tar.gz
# 2016-08-26
# gzip-ver           = gzip/gzip-1.7.tar.gz
gzip-ver           = gzip/gzip-1.8.tar.gz
# 2016-08-26
# gawk-ver           = gawk/gawk-4.1.1.tar.gz
gawk-ver           = gawk/gawk-4.1.4.tar.gz
# 2016-07-16
# gnutls-ver         = gnutls/gnutls-3.4.7.tar.xz
# gnutls-ver         = gnutls/gnutls-3.4.8.tar.xz
gnutls-ver         = gnutls/gnutls-3.4.14.tar.xz
# 2016-06-17
# Net-SSLeay-ver     = Net-SSLeay/Net-SSLeay-1.68.tar.gz
Net-SSLeay-ver     = Net-SSLeay/Net-SSLeay-1.74.tar.gz
# 2016-06-05
Test-Warn-ver         = Test-Warn/Test-Warn-0.30.tar.gz
# 2016-06-05
Test-NoWarnings-ver   = Test-NoWarnings/Test-NoWarnings-1.04.tar.gz
# 2016-06-05
Math-Random-ISAAC-ver = Math-Random-ISAAC/Math-Random-ISAAC-1.004.tar.gz
# 2016-06-05
Dist-CheckConflicts-ver = Dist-CheckConflicts/Dist-CheckConflicts-0.11.tar.gz
# 2016-06-05
Package-Stash-XS-ver = Package-Stash-XS/Package-Stash-XS-0.28.tar.gz
# 2016-06-05
Package-Stash-ver  = Package-Stash/Package-Stash-0.37.tar.gz
# 2016-06-05
Module-Implementation-ver = Module-Implementation/Module-Implementation-0.09.tar.gz
# 2016-06-05
B-Hooks-EndOfScope-ver = B-Hooks-EndOfScope/B-Hooks-EndOfScope-0.21.tar.gz
# 2016-06-05
namespace-clean-ver = namespace-clean/namespace-clean-0.27.tar.gz
# 2016-06-05
Exporter-Tiny-ver = Exporter-Tiny/Exporter-Tiny-0.042.tar.gz
# 2016-06-05
Type-Tiny-ver    = Type-Tiny/Type-Tiny-1.000005.tar.gz
# 2016-06-05
Sub-Install-ver  = Sub-Install/Sub-Install-0.928.tar.gz
# 2016-06-05
Params-Util-ver  = Params-Util/Params-Util-1.07.tar.gz
# 2016-06-05
Data-OptList-ver = Data-OptList/Data-OptList-0.110.tar.gz
# 2016-06-05
Sub-Exporter-ver = Sub-Exporter/Sub-Exporter-0.987.tar.gz
# 2016-06-05
Role-Tiny-ver    = Role-Tiny/Role-Tiny-2.000003.tar.gz
# 2016-06-05
Sub-Exporter-Progressive-ver = Sub-Exporter-Progressive/Sub-Exporter-Progressive-0.001011.tar.gz
# 2016-06-05
Devel-GlobalDestruction-ver = Devel-GlobalDestruction/Devel-GlobalDestruction-0.13.tar.gz
# 2016-06-05
Class-Method-Modifiers-ver = Class-Method-Modifiers/Class-Method-Modifiers-2.12.tar.gz
# 2016-06-05
Moo-ver          = Moo/Moo-2.001001.tar.gz
# 2016-06-05
Module-Find-ver  = Module-Find/Module-Find-0.13.tar.gz
# 2016-06-05
Crypt-Random-Source-ver = Crypt-Random-Source/Crypt-Random-Source-0.12.tar.gz
# 2016-06-04
Math-Pari-ver    = Math-Pari/Math-Pari-2.01080900.zip
# 2016-06-04
Class-Loader-ver = Class-Loader/Class-Loader-2.03.tar.gz
# 2016-06-04
Crypt-Random-ver = Crypt-Random/Crypt-Random-1.25.tar.gz
# 2016-06-04
Test-LeakTrace-ver = Test-LeakTrace/Test-LeakTrace-0.15.tar.gz
# 2016-06-04
Test-Requires-ver = Test-Requires/Test-Requires-0.10.tar.gz
# 2016-06-04
Test-Fatal-ver    = Test-Fatal/Test-Fatal-0.014.tar.gz
# 2016-06-04
Sub-Uplevel-ver   = Sub-Uplevel/Sub-Uplevel-0.25.tar.gz
# 2016-06-04
Test-Exception-ver = Test-Exception/Test-Exception-0.43.tar.gz
# 2016-06-04
Module-Build-XSUtil-ver = Module-Build-XSUtil/Module-Build-XSUtil-0.16.tar.gz
# 2016-06-04
inc-latest-ver    = inc-latest/inc-latest-0.500.tar.gz
# 2016-06-04
Any-Moose-ver     = Any-Moose/Any-Moose-0.26.tar.gz
# 2016-05-18
gnuplot-ver       = gnuplot/gnuplot-5.0.3.tar.gz
# 2016-05-17
# ruby-ver           = ruby/ruby-2.3.0.tar.xz
ruby-ver          = ruby/ruby-2.3.1.tar.xz
# 2016-05-15
jq-ver            = jq-1.5/jq-1.5.tar.gz
# 2016-05-06
util-linux-ver     = util-linux/util-linux-2.28.tar.gz
# 2016-04-20
mercurial-ver      = mercurial/mercurial-3.7.3.tar.gz
# 2016-04-19
# tmux-ver           = tmux/tmux-2.1.tar.gz
tmux-ver           = tmux/tmux-2.2.tar.gz
# 2016-04-19
ack-ver            = ack/ack-2.14-single-file
# 2016-04-18
pngnq-ver          = pngnq/pngnq-1.1.tar.gz
# 2016-04-18
crosextrafonts-carlito-ver = crosextrafonts-carlito/crosextrafonts-carlito-20130920.tar.gz
# 2016-04-18
crosextrafonts-ver = crosextrafonts/crosextrafonts-20130214.tar.gz
# 2016-04-08
# grep-ver           = grep/grep-2.21.tar.xz
grep-ver           = grep/grep-2.24.tar.xz
# 2016-04-08
lxsplit-ver        = lxsplit/lxsplit-0.2.4.tar.gz
# 2016-04-03
node-ver           = node/node-v4.4.2.tar.gz
# 2016-03-12
dbus-ver           = dbus/dbus-1.10.6.tar.gz
# 2016-03-12
qt-everywhere-opensource-src-ver            = qt-everywhere-opensource-src/qt-everywhere-opensource-src-5.5.1.tar.xz
# 2016-02-12
# autossh-ver        = autossh/autossh-1.4c.tgz
autossh-ver        = autossh/autossh-1.4e.tgz
# 2016-02-09
# socat-ver          = socat/socat-1.7.3.0.tar.gz
socat-ver          = socat/socat-1.7.3.1.tar.gz
# 2016-01-31
mutt-ver           = mutt/mutt-1.9.0.tar.gz
# 2016-01-31
libdnet-ver        = libdnet/libdnet-1.12.tar.gz
# 2016-01-31
snort-ver          = snort/snort-2.9.8.0.tar.gz
# 2016-01-31
daq-ver            = daq/daq-2.0.6.tar.gz
# 2016-01-40
Linux-PAM-ver      = Linux-PAM/Linux-PAM-1.2.1.tar.bz2
# 2016-01-29
libutempter-ver    = libutempter/libutempter-1.1.6.tar.bz2
# 2016-01-26
py2cairo-ver       = py2cairo/py2cairo-1.10.0.tar.bz2
# 2016-01-23
# Adding libidn
libidn-ver         = libidn/libidn-1.32.tar.gz
# 2016-01-21
# cairo-ver          = cairo/cairo-1.14.2.tar.xz
cairo-ver          = cairo/cairo-1.14.6.tar.xz
# 2016-01-17
vera++-ver         = vera++/vera++-1.3.0.tar.gz
# 2016-01-11
# whois-ver          = whois/whois_5.2.10.tar.xz
whois-ver          = whois/whois_5.2.11.tar.xz
# 2016-01-10
# hashdeep-ver        = hashdeep/master.zip
hashdeep-ver       = hashdeep/hashdeep-4.4.tar.gz
# 2016-01-10
# httpd-ver          = httpd/httpd-2.4.12.tar.bz2
httpd-ver          = httpd/httpd-2.4.18.tar.bz2
# 2016-01-09 Lua
lua-ver            = lua/lua-5.3.2.tar.gz
# attr was last updated 19-May-2013 14:16, checked 2018-03-28
attr-ver           = attr/attr-2.4.47.src.tar.gz
# acl was last updated 19-May-2013 06:10, checked 2018-03-28
acl-ver            = acl/acl-2.2.52.src.tar.gz
# bcrypte was last updated 2002-09-13, checked 2018-03-28
bcrypt-ver         = bcrypt/bcrypt-1.1.tar.gz
# The rest of these, I should check
apr-util-ver       = apr-util/apr-util-1.5.4.tar.bz2
apr-ver            = apr/apr-1.5.2.tar.bz2
Archive-Zip-ver    = Archive-Zip/Archive-Zip-1.51.tar.gz
autoconf-ver       = autoconf/autoconf-2.69.tar.xz
bash-ver           = bash/bash-4.3.30.tar.gz
bzip-ver           = bzip/bzip2-1.0.6.tar.gz
ca-cert-ver        = ca-cert/ca-cert-1.0
check-ver          = check/check-0.9.12.tar.gz
clang-ver          = clang/clang-3.4.src.tar.gz
clisp-ver          = clisp/clisp-2.49.tar.gz
compiler-rt-ver    = compiler-rt/compiler-rt-3.4.src.tar.gz
coreutils-ver      = coreutils/coreutils-8.22.tar.xz
Digest-SHA1-ver    = Digest-SHA1/Digest-SHA1-2.13.tar.gz
e2fsprogs-ver      = e2fsprogs/master.zip
ecj-ver            = ecj/ecj-latest.jar
Encode-Locale-ver  = Encode-Locale/Encode-Locale-1.05.tar.gz
expat-ver          = expat/expat-2.1.0.tar.gz
expect-ver         = expect/expect5.45.tar.gz
File-Listing-ver   = File-Listing/File-Listing-6.04.tar.gz
file-ver           = file/file-5.17.tar.gz
findutils-ver      = findutils/findutils-4.4.2.tar.gz
fuse-ver           = fuse/fuse-2.9.4.tar.gz
gcc-ver            = gcc/gcc-4.7.3.tar.bz2
gc-ver             = gc/gc-7.4.2.tar.gz
gdbm-ver           = gdbm/gdbm-1.10.tar.gz
gettext-ver        = gettext/gettext-0.19.7.tar.gz
glibc-ver          = glibc/glibc-2.21.tar.gz
gmp-ver            = gmp/gmp-5.1.2.tar.bz2
gobject-introspection-ver = gobject-introspection/gobject-introspection-1.46.0.tar.xz
go-ver             = go/go1.4.2.src.tar.gz
guile-ver          = guile/guile-2.0.11.tar.xz
HTML-Parser-ver    = HTML-Parser/HTML-Parser-3.71.tar.gz
HTML-Tagset-ver    = HTML-Tagset/HTML-Tagset-3.20.tar.gz
htop-ver           = htop/htop-1.0.1.tar.gz
HTTP-Cookies-ver   = HTTP-Cookies/HTTP-Cookies-6.01.tar.gz
HTTP-Daemon-ver    = HTTP-Daemon/HTTP-Daemon-6.01.tar.gz
HTTP-Date-ver      = HTTP-Date/HTTP-Date-6.02.tar.gz
HTTP-Negotiate-ver = HTTP-Negotiate/HTTP-Negotiate-6.01.tar.gz
hwloc-ver          = hwloc/hwloc-1.11.0.tar.gz
inetutils-ver      = inetutils/inetutils-1.9.tar.gz
IO-HTML-ver        = IO-HTML/IO-HTML-1.001.tar.gz
iptraf-ng-ver      = iptraf-ng/iptraf-ng-1.1.4.tar.gz
iwyu-ver           = include-what-you-use/include-what-you-use-3.4.src.tar.gz
jnettop-ver        = jnettop/jnettop-0.13.0.tar.gz
libatomic_ops-ver  = libatomic_ops/libatomic_ops-7.4.2.tar.gz
libcap-ver         = libcap/libcap-2.24.tar.xz
libelf-ver         = libelf/libelf-0.8.13.tar.gz
libevent-ver       = libevent/libevent-2.0.21-stable.tar.gz
libffi-ver         = libffi/libffi-3.2.1.tar.gz
jpeg-ver           = jpeg/jpegsrc.v9b.tar.gz
libpcap-ver        = libpcap/libpcap-1.4.0.tar.gz
libusb-ver         = libusb/libusb-1.0.19.tar.bz2
llvm-ver           = llvm/llvm-3.4.src.tar.gz
LWP-MediaTypes-ver = LWP-MediaTypes/LWP-MediaTypes-6.02.tar.gz
lzma-ver           = lzma/lzma-4.32.7.tar.gz
mpc-ver            = mpc/mpc-1.0.1.tar.gz
mpfr-ver           = mpfr/mpfr-3.1.2.tar.gz
multitail-ver      = multitail/multitail-6.4.2.tgz
ncurses-ver        = ncurses/ncurses-6.0.tar.gz
Net-HTTP-ver       = Net-HTTP/Net-HTTP-6.09.tar.gz
netpbm-ver         = netpbm/netpbm-10.35.95.tgz
ntfs-3g-ver        = ntfs-3g/ntfs-3g_ntfsprogs-2013.1.13.tgz
Pod-Coverage-ver   = Pod-Coverage/Pod-Coverage-0.23.tar.gz
popt-ver           = popt/popt-1.16.tar.gz
psmisc-ver         = psmisc/psmisc-22.21.tar.gz
pth-ver            = pth/pth-2.0.7.tar.gz
pygobject-ver      = pygobject/pygobject-2.28.6.tar.xz
readline-ver       = readline/readline-6.3.tar.gz
Scalar-MoreUtils-ver = Scalar-MoreUtils/Scalar-MoreUtils-0.02.tar.gz
sharutils-ver      = sharutils/sharutils-4.15.1.tar.xz
sparse-ver         = sparse/sparse-0.5.0.tar.gz
srm-ver            = srm/srm-1.2.15.tar.gz
tcc-ver            = tcc/tcc-0.9.26.tar.bz2
tclx-ver           = tclx/tclx8.4.1.tar.bz2
tcpdump-ver        = tcpdump/tcpdump-4.5.1.tar.gz
tcp_wrappers-patch-ver = tcp_wrappers/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch
tcp_wrappers-ver   = tcp_wrappers/tcp_wrappers_7.6.tar.gz
Test-Pod-Coverage-ver = Test-Pod-Coverage/Test-Pod-Coverage-1.10.tar.gz
Test-Pod-ver       = Test-Pod/Test-Pod-1.49.tar.gz
truecrypt-ver      = truecrypt/truecrypt-7.1a-linux-console-x86.tar.gz
util-linux-ng-ver  = util-linux-ng/util-linux-ng-2.18.tar.xz

# ==============================================================
# Individual Targets
# ==============================================================

.PHONY: target_test
target_test:
	/bin/echo $$LD_LIBRARY_PATH

.PHONY: target_dirs
target_dirs:
	/usr/bin/sudo mkdir -p /usr/local/bin
	/usr/bin/sudo mkdir -p /usr/local/etc
	/usr/bin/sudo mkdir -p /usr/local/lib
	/usr/bin/sudo mkdir -p /usr/local/lib/lib64
	/usr/bin/sudo mkdir -p /usr/local/lib64
	/usr/bin/sudo mkdir -p /usr/local/share/man
	/usr/bin/sudo mkdir -p /usr/local/share/man/man1
	/usr/bin/sudo mkdir -p /usr/local/share/man/man2
	/usr/bin/sudo mkdir -p /usr/local/share/man/man3
	/usr/bin/sudo mkdir -p /usr/local/share/man/man4
	/usr/bin/sudo mkdir -p /usr/local/share/man/man5
	/usr/bin/sudo mkdir -p /usr/local/share/man/man6
	/usr/bin/sudo mkdir -p /usr/local/share/man/man7
	/usr/bin/sudo mkdir -p /usr/local/share/man/man8
	/usr/bin/sudo mkdir -p /usr/local/share/man/mann
	/usr/bin/sudo mkdir -p /usr/local/share/man/web
	/usr/bin/sudo mkdir -p /usr/local/sbin
	# Create a link from /usr/local/usr back to /usr/local
	# This allows us to specify --sysroot=/usr/local and when
	# GCC appends usr/lib, which gives /usr/local/usr/lib, this
	# will resolve to /usr/local/lib. Same for GCC searching for
	# sysroot/usr/bin, this will give /usr/local/usr/bin which
	# will resolve to /usr/local/bin.
	#
	test -e /usr/local/src || /usr/bin/sudo ln -sf /usr/local /usr/local/usr
	test -e /usr/local/man || /usr/bin/sudo ln -sf /usr/local/share/man /usr/local/man

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
	echo -- $(word 2,$(subst -, ,$(basename $(basename $(notdir $(perl-ver))))))
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
	cd scripts/scripts-1.0; /usr/bin/sudo cp * /usr/local/bin/.

.PHONY: devices
devices:
	cd /dev; test -c /dev/random || /usr/bin/sudo /sbin/MAKEDEV random
	cd /dev; test -c /dev/urandom || /usr/bin/sudo /sbin/MAKEDEV urandom

.PHONY: nameservers
nameservers:
	egrep 8.8.8.8 /etc/resolv.conf || /usr/bin/sudo bash -c "echo nameserver 8.8.8.8 >> /etc/resolv.conf"
	egrep 8.8.4.4 /etc/resolv.conf || /usr/bin/sudo bash -c "echo nameserver 8.8.4.4 >> /etc/resolv.conf"

.PHONY: save_ld
save_ld:
ifneq ($(subst $(space),-,$(PHASE1_NOCHECK)),)
	@/bin/echo "Saving /usr/local/bin/ld"
	/bin/rm -rf /usr/local/bin/ld.$(THIS_RUN)
	-cd /usr/local/bin; test ! -e ld || /usr/bin/sudo /bin/mv ld ld.$(THIS_RUN)
else
	@/bin/echo ""
endif

.PHONE: restore_ld
restore_ld:
	@/bin/echo "Restoring /usr/local/bin/ld"
	-cd /usr/local/bin; test ! -e ld.$(THIS_RUN) || /usr/bin/sudo /bin/mv ld.$(THIS_RUN) ld

.PHONY: check_sudo
.PHONY: sudo
check_sudo sudo:
	/usr/bin/sudo echo sudo check

# Standard build with separate build directory
# make check is automatically built by automake
# so we will try that target first
#
# In several packages, there is a problem inherited
# from an old gnulib, where they are trying to warn
# of the definition of gets(). There are three ways
# to deal with it:
#
# * Update the pacakge that has a newer stdio.in.h inherited from gnulib
# * Surround the warning line with #if HAVE_RAW_DECL_GETS ... #endif
# * Just delete the line, which is what we do here.
#
#
.PHONY: gawk
.PHONY: tar
.PHONY: xz
gawk xz tar: $(xz-ver) $(gawk-ver) $(tar-ver)
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
.PHONY: scrypt
scrypt: $(scrypt-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, separate build directory
# We should have a good version of tar that
# automatically detects file type
.PHONY: apr
.PHONY: findutils
.PHONY: gdbm
.PHONY: gpgme
.PHONY: jpeg
.PHONY: libassuan
.PHONY: libgpg-error
.PHONY: libksba
.PHONY: libpng
.PHONY: ntbtls
.PHONY: npth
.PHONY: which
apr findutils gdbm gpgme jpeg libgpg-error libassuan libksba libpng ntbtls npth which: $(which-ver) $(libpng-ver) $(libgpg-error-ver) $(libassuan-ver) $(libksba-ver) $(apr-ver) $(gdbm-ver) $(findutils-ver) $(jpeg-ver) $(npth-ver) $(ntbtls-ver) $(gpgme-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, separate build directory
# No make check or make test
# We should have a good version of tar that
# automatically detects file type
#
# oath-toolkit does have a check, but you are supposed
# to run it after install, it needs a connection to the
# internet, and it detects _dl_map_object() leaking
# memory in my old ld-2.3.4.so. So I will go without
# it for now. Most tests do pass.
#
.PHONY: libvpx
.PHONY: oath-toolkit
libvpx oath-toolkit : \
    $(libvpx-ver) \
    $(oath-toolkit)
	$(call SOURCEDIR,$@,xf)
	-cd $@/`cat $@/untar.dir`/; sed -i -e 's/\boff_t\b/int/' third_party/libwebm/mkvmuxer/mkvwriter.cc
	-cd $@/`cat $@/untar.dir`/; sed -i -e 's/\boff_t\b/int/' third_party/libwebm/mkvparser/mkvreader.cc
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, separate build directory,
# broken copyright or fails tests
#
# We should have a good version of tar that automatically detects
# file type
# With test-update-copyright.sh failure that is in several packages
# patch hardcodes /bin/vi and fails tests because the installed vi
# is too old to handle the command line arguments that are passed.
# skip tests for texinfo needs a newer version of gzip to pass
# diffutils is failing one test where the date string doesn't insert
# the UTC hour offset, strftime is in glibc, which my goal is to
# avoid replacing on an existing system.
.PHONY: diffutils
.PHONY: grep
.PHONY: m4
.PHONY: patch
.PHONY: texinfo
diffutils grep m4 patch texinfo : \
    $(diffutils-ver) \
    $(grep-ver) \
    $(m4-ver) \
    $(patch-ver) \
    $(texinfo-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, separate build directory,
# skip PHASE1 tests
#
# We should have a good version of tar that
# automatically detects file type
#
# NOTE:
# For PHASE1, we will skip tests
#
# skip tests for autoconf, we may not have Fortran in PHASE1
# skip tests for libffi, we may not have a C++ compiler in PHASE1
# its tests, it may fail in tests phase1
.PHONY: libffi
libffi : \
    $(libffi-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --with-libiconv-prefix=/usr/local
	cd $@/$@-build/; make
	cd $@/$@-build/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, no separate build directory
# Try this one first!!!
.PHONY: alsa-lib
.PHONY: check
.PHONY: daq
.PHONY: file
.PHONY: flac
.PHONY: jnettop
.PHONY: lame
.PHONY: libarchive
.PHONY: libogg
.PHONY: libdnet
.PHONY: libmpeg2
.PHONY: libtasn1
.PHONY: libvorbis
.PHONY: libxml2
.PHONY: libxslt
.PHONY: nftables
.PHONY: octave
.PHONY: opus
.PHONY: popt
.PHONY: protobuf
.PHONY: sharutils
.PHONY: tcc
.PHONY: xmlsec1
.PHONY: yasm
jnettop libxml2 check file protobuf libtasn1 popt sharutils libxslt libidn daq libdnet alsa-lib libogg flac libvorbis octave lame yasm opus libmpeg2 xmlsec1 tcc libarchive nftables : \
    $(alsa-lib-ver) \
    $(check-ver) \
    $(daq-ver) \
    $(file-ver) \
    $(flac-ver) \
    $(jnettop-ver) \
    $(lame-ver) \
    $(libarchive-ver) \
    $(libdnet-ver) \
    $(libidn-ver) \
    $(libmpeg2-ver) \
    $(libogg-ver) \
    $(libtasn1-ver) \
    $(libvorbis-ver) \
    $(libxml2-ver) \
    $(libxslt-ver) \
    $(nftables-ver) \
    $(octave-ver) \
    $(opus-ver) \
    $(popt-ver) \
    $(protobuf-ver) \
    $(sharutils-ver) \
    $(tcc-ver) \
    $(xmlsec1-ver) \
    $(yasm-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, no separate build directory, but with autogen.sh
.PHONY: libuv
.PHONY: rng-tools
libuv rng-tools : $(libuv-ver) \
    $(rng-tools-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./autogen.sh
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --without-nistbeacon
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build using MUSL, post tar rule, no separate build directory
# We can not easily replace GLIBC, but we can use the MUSL libc, which
# will coexist and has thread support. I would like to try to recompile
# a bunch of this with MUSL support
.PHONY: pixman
pixman : \
    $(pixman-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CC=/usr/local/musl/bin/musl-gcc ./configure --prefix=/usr/local --enable-shared 
	cd $@/`cat $@/untar.dir`/; CC=/usr/local/musl/bin/musl-gcc make
	cd $@/`cat $@/untar.dir`/; CC=/usr/local/musl/bin/musl-gcc make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, no separate build directory,
# full automake
.PHONY: par2cmdline
par2cmdline : $(par2cmdline-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; aclocal
	cd $@/`cat $@/untar.dir`/; automake --add-missing
	cd $@/`cat $@/untar.dir`/; autoconf
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, no separate build directory,
# autoreconf to automate  autoconf, autoheader, aclocal automake libtoolize and autopoint
.PHONY: dash
dash : $(dash-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; autoreconf -i
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Standard build, post tar rule, no separate build directory
# no make check || make test, no test, no check
#
# we should have a good version of tar that automatically
# detects file type
.PHONY: c-ares
.PHONY: cairo
.PHONY: fdk-aac
.PHONY: htop
.PHONY: hwloc
.PHONY: iptraf-ng
.PHONY: libass
.PHONY: libmnl
.PHONY: libnftnl
.PHONY: libusb
.PHONY: mosh
.PHONY: nano
.PHONY: nasm
.PHONY: psmisc
.PHONY: socat
.PHONY: srm
.PHONY: tmux
.PHONY: wipe
.PHONY: x264
srm wipe mosh socat tmux psmisc libusb htop cairo iptraf-ng hwloc nano libass fdk-aac nasm x264 c-ares libmnl libnftnl : \
	$(cairo-ver) \
	$(fdk-aac-ver) \
	$(htop-ver) \
	$(hwloc-ver) \
	$(iptraf-ng-ver) \
	$(libass-ver) \
	$(libmnl-ver) \
	$(libnftnl-ver) \
	$(libusb-ver) \
	$(mosh-ver) \
	$(nano-ver) \
	$(nasm-ver) \
	$(psmisc-ver) \
	$(socat-ver) \
	$(srm-ver) \
	$(tmux-ver) \
	$(wipe-ver) \
	$(x264-ver) \
	$(c-ares-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No make check || make test, no test
# bison fails the glibc version test, we have too old of a GLIBC
# bison will also fail before flex is installed. bison and flex
# have circular dependancies
# gobject-introspection wants cairo installed for testing
# lmza fails the glibc version test, we have too old of a GLIBC
#  we are linking to an old librt in GLIBC
# libpcap does not appear to have any tests
# tcpdump fails on PPOE
# pango needs cairo to test
.PHONY: bison
.PHONY: gobject-introspection
.PHONY: libpcap
.PHONY: lzma
.PHONY: make
.PHONY: pango
.PHONY: sqlite
.PHONY: tcpdump
make libpcap sqlite lzma bison pango tcpdump gobject-introspection : \
    $(bison-ver) \
    $(make-ver) \
    $(libpcap-ver) \
    $(lzma-ver) \
    $(gobject-introspection-ver) \
    $(pango-ver) \
    $(sqlite-ver) \
    $(tcpdump-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No configure and no make check || make test
#
# unrar is going to install in /usr/bin
#
.PHONY: bcrypt
.PHONY: libcap
.PHONY: symlinks
.PHONY: multitail
.PHONY: unrar
.PHONY: lxsplit
.PHONY: password-store
.PHONY: tenshi
bcrypt libcap multitail symlinks unrar lxsplit password-store tenshi: $(bcrypt-ver) $(multitail-ver) $(symlinks-ver) $(unrar-ver) $(libcap-ver) $(lxsplit-ver) $(password-store-ver) $(tenshi-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Perl Rule using Make
.PHONY: Algorithm-Diff
.PHONY: Any-Moose
.PHONY: Archive-Zip
.PHONY: B-Hooks-EndOfScope
.PHONY: CPAN-Meta-Check
.PHONY: Capture-Tiny
.PHONY: Class-Data-Inheritable
.PHONY: Class-Inspector
.PHONY: Class-Load
.PHONY: Class-Load-XS
.PHONY: Class-Loader
.PHONY: Class-Method-Modifiers
.PHONY: Class-Singleton
.PHONY: Class-Tiny
.PHONY: Crypt-Random
.PHONY: Crypt-Random-Source
.PHONY: Data-OptList
.PHONY: DataTime-Locale
.PHONY: DateTime
.PHONY: DateTime-Locale
.PHONY: DateTime-TimeZone
.PHONY: Devel-GlobalDestruction
.PHONY: Devel-OverloadInfo
.PHONY: Devel-StackTrace
.PHONY: Devel-Symdump
.PHONY: Digest-HMAC
.PHONY: Digest-SHA1
.PHONY: Dist-CheckConflicts
.PHONY: Encode-Locale
.PHONY: Eval-Closure
.PHONY: Exception-Class
.PHONY: Exporter-Tiny
.PHONY: ExtUtils-Config
.PHONY: ExtUtils-Helpers
.PHONY: ExtUtils-InstallPaths
.PHONY: File-pushd
.PHONY: File-Copy-Recursive
.PHONY: File-Listing
.PHONY: File-Path
.PHONY: File-Remove
.PHONY: File-ShareDir
.PHONY: File-ShareDir-Install
.PHONY: HTML-Parser
.PHONY: HTML-Tagset
.PHONY: HTTP-Cookies
.PHONY: HTTP-Daemon
.PHONY: HTTP-Date
.PHONY: HTTP-Message
.PHONY: HTTP-Negotiate
.PHONY: IO-BufferedSelect
.PHONY: IO-HTML
.PHONY: Importer
.PHONY: IPC-Run3
.PHONY: JSON-MaybeXS
.PHONY: LWP-MediaTypes
.PHONY: LWP-Protocol-https
.PHONY: Log-Log4perl
.PHONY: MRO-Compat
.PHONY: Math-Random-ISAAC
.PHONY: Math-Random-Secure
.PHONY: Module-Build
.PHONY: Module-Build-XSUtil
.PHONY: Module-Find
.PHONY: Module-Implementation
.PHONY: Module-Install
.PHONY: Module-Pluggable
.PHONY: Module-Runtime
.PHONY: Module-Runtime-Conflicts
.PHONY: Module-ScanDeps
.PHONY: Mojolicious
.PHONY: Moo
.PHONY: Moose
.PHONY: Mouse
.PHONY: MouseX-Types
.PHONY: Net-DNS
.PHONY: Net-HTTP
.PHONY: PAR-Dist
.PHONY: Package-DeprecationManager
.PHONY: Package-Stash
.PHONY: Package-Stash-XS
.PHONY: Params-Util
.PHONY: Params-ValidationCompiler
.PHONY: Path-Tiny
.PHONY: PathTools
.PHONY: Pod-Coverage
.PHONY: Role-Tiny
.PHONY: Scalar-List-Utils
.PHONY: Scalar-MoreUtils
.PHONY: Scope-Guard
.PHONY: Specio
.PHONY: Sub-Exporter
.PHONY: Sub-Exporter-Progressive
.PHONY: Sub-Identify
.PHONY: Sub-Info
.PHONY: Sub-Install
.PHONY: Sub-Name
.PHONY: Sub-Uplevel
.PHONY: Term-Table
.PHONY: Test-CleanNamespaces
.PHONY: Test-Deep
.PHONY: Test-Differences
.PHONY: Test-Fatal
.PHONY: Test-File
.PHONY: Test-File-ShareDir
.PHONY: Test-Inter
.PHONY: Test-LeakTrace
.PHONY: Test-NoWarnings
.PHONY: Test-Pod
.PHONY: Test-Pod-Coverage
.PHONY: Test-Requires
.PHONY: Test-RequiresInternet
.PHONY: Test-Simple
.PHONY: Test-SharedFork
.PHONY: Test-utf8
.PHONY: Test-Warn
.PHONY: Test-Warnings
.PHONY: Tests-Warnings
.PHONY: Test-Without-Module
.PHONY: Test2-Plugin-NoWarnings
.PHONY: Test2-Suite
.PHONY: Text-Diff
.PHONY: Try-Tiny
.PHONY: URI
.PHONY: Variable-Magic
.PHONY: WWW-RobotRules
.PHONY: XML-Parser
.PHONY: YAML-Tiny
.PHONY: inc-latest
.PHONY: libwww-perl
.PHONY: namespace-autoclean
.PHONY: namespace-clean
Sub-Name Class-Load Class-Load-XS Test-Warnings Package-DeprecationManager Devel-OverloadInfo Test-Deep File-pushd Test-CleanNamespaces Module-Runtime-Conflicts Moose MouseX-Types Any-Moose Archive-Zip Capture-Tiny B-Hooks-EndOfScope Class-Loader Class-Method-Modifiers Crypt-Random Crypt-Random-Source Data-OptList Devel-GlobalDestruction Digest-SHA1 Dist-CheckConflicts Encode-Locale Exporter-Tiny ExtUtils-Config ExtUtils-Helpers ExtUtils-InstallPaths File-Listing Scalar-MoreUtils URI HTML-Tagset HTML-Parser HTTP-Daemon HTTP-Cookies HTTP-Date WWW-RobotRules HTTP-Message HTTP-Negotiate inc-latest IO-HTML IPC-Run3 LWP-MediaTypes Module-Find Module-Implementation Module-Runtime Math-Random-ISAAC Math-Random-Secure File-Path PathTools File-Remove YAML-Tiny Module-Pluggable Module-ScanDeps Module-Build Module-Install Moo Net-HTTP Devel-Symdump namespace-clean Package-Stash Package-Stash-XS PAR-Dist Params-Util Pod-Coverage Role-Tiny Sub-Exporter Sub-Exporter-Progressive Sub-Install Sub-Uplevel Test-Fatal Test-LeakTrace Test-NoWarnings Test-Pod Test-Pod-Coverage Test-Requires Test-SharedFork Test-Warn Try-Tiny Variable-Magic libwww-perl XML-Parser Test-Inter Sub-Identify namespace-autoclean Eval-Closure MRO-Compat Devel-StackTrace Specio Test-Simple Importer Sub-Info Term-Table Test-Without-Module Test2-Plugin-NoWarnings Test2-Suite Exception-Class Class-Data-Inheritable Params-ValidationCompiler Class-Inspector Class-Tiny Scope-Guard Path-Tiny File-Copy-Recursive File-ShareDir-Install File-ShareDir Test-File Test-File-ShareDir Test-utf8 DateTime-Locale Algorithm-Diff Text-Diff Test-Differences Scalar-List-Utils CPAN-Meta-Check Class-Singleton DateTime DateTime-TimeZone JSON-MaybeXS Test-RequiresInternet LWP-Protocol-https Log-Log4perl Mojolicious Digest-HMAC Net-DNS IO-BufferedSelect : \
    $(Algorithm-Diff-ver) \
    $(Any-Moose-ver) \
    $(Archive-Zip-ver) \
    $(B-Hooks-EndOfScope-ver) \
    $(CPAN-Meta-Check-ver) \
    $(Capture-Tiny-ver) \
    $(Class-Data-Inheritable-ver) \
    $(Class-Inspector-ver) \
    $(Class-Load-ver) \
    $(Class-Load-XS-ver) \
    $(Class-Loader-ver) \
    $(Class-Method-Modifiers-ver) \
    $(Class-Tiny-ver) \
    $(Crypt-Random-Source-ver) \
    $(Crypt-Random-ver) \
    $(Class-Singleton-ver) \
    $(Data-OptList-ver) \
    $(DateTime-Locale-ver) \
    $(DateTime-TimeZone-ver) \
    $(DateTime-ver) \
    $(Devel-GlobalDestruction-ver) \
    $(Devel-OverloadInfo-ver) \
    $(Devel-StackTrace-ver) \
    $(Devel-Symdump-ver) \
    $(Digest-HMAC-ver) \
    $(Digest-SHA1-ver) \
    $(Dist-CheckConflicts-ver) \
    $(Encode-Locale-ver) \
    $(Eval-Closure-ver) \
    $(Exception-Class-ver) \
    $(Exporter-Tiny-ver) \
    $(ExtUtils-Config-ver) \
    $(ExtUtils-Helpers-ver) \
    $(ExtUtils-InstallPaths-ver) \
    $(File-pushd-ver) \
    $(File-Copy-Recursive-ver) \
    $(File-Listing-ver) \
    $(File-Path-ver) \
    $(File-Remove-ver) \
    $(File-ShareDir-ver) \
    $(File-ShareDir-Install-ver) \
    $(HTML-Parser-ver) \
    $(HTML-Tagset-ver) \
    $(HTTP-Cookies-ver) \
    $(HTTP-Daemon-ver) \
    $(HTTP-Date-ver) \
    $(HTTP-Message-ver) \
    $(HTTP-Negotiate-ver) \
    $(IO-HTML-ver) \
    $(IO-BufferedSelect-ver) \
    $(Importer-ver) \
    $(IPC-Run3-ver) \
    $(JSON-MaybeXS-ver) \
    $(LWP-MediaTypes-ver) \
    $(LWP-Protocol-https-ver) \
    $(Log-Log4perl-ver) \
    $(MRO-Compat-ver) \
    $(Math-Random-ISAAC-ver) \
    $(Math-Random-Secure-ver) \
    $(Module-Build-ver) \
    $(Module-Find-ver) \
    $(Module-Implementation-ver) \
    $(Module-Install-ver) \
    $(Module-Pluggable-ver) \
    $(Module-Runtime-ver) \
    $(Module-Runtime-Conflicts-ver) \
    $(Module-ScanDeps-ver) \
    $(Mojolicious-ver) \
    $(Moo-ver) \
    $(Moose-ver) \
    $(MouseX-Types-ver) \
    $(Net-HTTP-ver) \
    $(Net-DNS-ver) \
    $(PAR-Dist-ver) \
    $(Package-DeprecationManager-ver) \
    $(Package-Stash-XS-ver) \
    $(Package-Stash-ver) \
    $(Params-Util-ver) \
    $(Params-ValidationCompiler-ver) \
    $(Path-Tiny-ver) \
    $(PathTools-ver) \
    $(Pod-Coverage-ver) \
    $(Role-Tiny-ver) \
    $(Scalar-List-Utils-ver) \
    $(Scalar-MoreUtils-ver) \
    $(Scope-Guard-ver) \
    $(Specio-ver) \
    $(Sub-Exporter-Progressive-ver) \
    $(Sub-Exporter-ver) \
    $(Sub-Identify-ver) \
    $(Sub-Info-ver) \
    $(Sub-Install-ver) \
    $(Sub-Name-ver) \
    $(Sub-Uplevel-ver) \
    $(Term-Table-ver) \
    $(Test-CleanNamespaces-ver) \
    $(Test-Deep-ver) \
    $(Test-Differences-ver) \
    $(Test-Fatal-ver) \
    $(Test-File-ver) \
    $(Test-File-ShareDir-ver) \
    $(Test-Inter-ver) \
    $(Test-LeakTrace-ver) \
    $(Test-NoWarnings-ver) \
    $(Test-Pod-Coverage-ver) \
    $(Test-Pod-ver) \
    $(Test-Requires-ver) \
    $(Test-RequiresInternet-ver) \
    $(Test-SharedFork-ver) \
    $(Test-Simple-ver) \
    $(Test-utf8-ver) \
    $(Test-Warn-ver) \
    $(Test-Warnings-ver) \
    $(Test-Without-Module-ver) \
    $(Test2-Plugin-NoWarnings-ver) \
    $(Test2-Suite-ver) \
    $(Text-Diff-ver) \
    $(Try-Tiny-ver) \
    $(URI-ver) \
    $(Variable-Magic-ver) \
    $(WWW-RobotRules-ver) \
    $(XML-Parser-ver) \
    $(YAML-Tiny-ver) \
    $(inc-latest-ver) \
    $(namespace-autoclean-ver) \
    $(namespace-clean-ver) \
    $(libwww-perl-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; perl Makefile.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include'
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make test || make check
	$(call PKGINSTALL,$@)

# IO-Socket-SSL wants to interactively ask for permission to test external network sites
# The tests for external network sites work, but the only way to avoid the interactive
# question is to disable the external network tests with an environment variable, so we
# will disable the external network tests to avoid a user interaction.
.PHONY: IO-Socket-SSL
IO-Socket-SSL: $(IO-Socket-SSL-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; NO_NETWORK_TESTING=1 perl Makefile.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include'
	cd $@/`cat $@/untar.dir`/; NO_NETWORK_TESTING=1 make
	cd $@/`cat $@/untar.dir`/; NO_NETWORK_TESTING=1 OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make test || make check
	$(call PKGINSTALL,$@)

# Perl has taken out the ability to automatically include . in the INC, include, path. This makes
# a lot of sense from a security perspective, but breaks packages that have not been updated.
.PHONY: XDate-Manip
XDate-Manip: $(XDate-Manip-ver)
	$(call SOURCEDIR,$@,xfz)
	echo "Adding PERLUSE_UNSAFE_INC=1 for now, too many packages have problems, especially in tests"
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 perl Makefile.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include'
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 make
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make test || make check
	$(call PKGINSTALL,$@)


# Standard build, post tar rule, no separate build directory, Perl Configure.pl rather than Makefile.PL
.PHONY: MoarVM
MoarVM: $(MoarVM-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/local/bin/perl Configure.pl
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)


# Perl Rule using Build, Build.PL rather than Makefile.PL
.PHONY: Module-Build-Tiny
.PHONY: Module-Build-XSUtil
.PHONY: Mouse
Module-Build-Tiny Module-Build-XSUtil Mouse :\
    $(Module-Build-Tiny-ver) \
    $(Module-Build-XSUtil-ver) \
    $(Mouse-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; perl Build.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include'
	cd $@/`cat $@/untar.dir`/; ./Build
	cd $@/`cat $@/untar.dir`/; OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib ./Build test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./Build install

# Perl Rule, no test
# Net-SSLeay seems to be failing because of thread problems
# PERL_MM_USE_DEFAULT=1 is the way to answer 'no' to 
# Makefile.PL for external tests question.
# Test-Exception needs Test-Exception installed to run its tests
# Type-Tiny tests need upgraded regular expression to avoid unescaped braces
# List-MoreUtils misunderstands the perl version of newer versions of perl
# Test-Needs misunderstands the perl version of newer versions of perl
# Date-Manip looks like it needs its tests to be upgraded
.PHONY: Date-Manip
.PHONY: List-MoreUtils
.PHONY: Net-SSLeay
.PHONY: Test-Exception
.PHONY: Test-Needs
.PHONY: Type-Tiny
Date-Manip List-MoreUtils Net-SSLeay Test-Exception Test-Needs Type-Tiny : \
    $(Date-Manip-ver) \
    $(List-MoreUtils-ver) \
    $(Net-SSLeay-ver) \
    $(Test-Exception-ver) \
    $(Test-Needs) \
    $(Type-Tiny-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; PERL_MM_USE_DEFAULT=1 perl Makefile.PL
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)

# Begin special cases

.PHONY: ack
ack: $(ack-ver)
	cd $@; cp $(notdir $(ack-ver)) ack
	cd $@; /usr/bin/sudo /usr/local/bin/install -m 755 -D ack /usr/local/bin

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

.PHONY: autoconf
autoconf: $(autoconf-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	# Perl regular expression brace change
	# messes up one test
	-cd $@/$@-build/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# --disable-shared is specified to avoid the version dependancies
#  of the share libguile and include files installed with guile
#  and the ones autogen expects
.PHONY: autogen
autogen : \
    $(autogen-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --disable-shared
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# many tests, a few fail, I have not sorted them out yet...
.PHONY: automake
automake: $(automake-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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

.PHONY: boost
boost: $(boost-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./bootstrap.sh --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; ./b2 stage
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./b2 install

.PHONY: bzip
bzip: $(bzip-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; make clean
	cd $@/`cat $@/untar.dir`/; make -f Makefile-libbz2_so
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av libbz2.so* /usr/local/lib
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av libbz2.so.1.0 /usr/local/lib/libbz2.so
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)
	cd $@/`cat $@/untar.dir`/; make clean
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install
	$(call PKGINSTALL,$@)
	$(call CPLIB,libbz*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ln -sf /usr/local/etc/ssl/ca-bundle.crt /usr/local/etc/ssl/certs/ca-certificates.crt

# cmake tests fail on not having GTK2
.PHONY: cmake
cmake: $(cmake-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed -i '1 i\
	set(CURSES_LIBRARY "/usr/local/lib/libncursesw.so")\
	set(CURSES_INCLUDE_PATH "/usr/local/include/ncursesw")' Modules/FindCurses.cmake
	cd $@/`cat $@/untar.dir`/; ./bootstrap --prefix=/usr/local --system-libs --no-system-jsoncpp --mandir=/usr/local/share/man --docdir=/usr/local/share/doc/cmake --no-system-jsoncpp
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; bin/ctest -j2 -O ../cmake-test.log
	$(call PKGINSTALL,$@)

.PHONY: crosextrafonts
.PHONY: crosextrafonts-carlito
crosextrafonts-carlito crosextrafonts: $(crosextrafonts-ver) $(crosextrafonts-carlito-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /usr/local/bin/install -d /usr/local/share/fonts/truetype
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /usr/local/bin/install -m 644 -D *.ttf /usr/local/share/fonts/truetype
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /usr/local/bin/fc-cache -f -v /usr/local/share/fonts

# curl needs valgrind to run its tests
# If it finds the system valgrind, that might not be compatible with
# the compiler we are using, so it may think theres all sorts of illegal
# instructions. Even if it does find the compiler we are using, it may
# find a system library with bugs and claim uninitialized variables and
# such, so we must ignore the tests.
.PHONY: curl
curl: $(curl-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Berkeley DB
.PHONY: db
db: $(db-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/build_unix; readlink -f . | grep `cat ../../untar.dir`
	cd $@/`cat $@/untar.dir`/build_unix; ../dist/configure --enable-compat185 --enable-dbm --enable-cxx
	cd $@/`cat $@/untar.dir`/build_unix; make
	cd $@/`cat $@/untar.dir`/build_unix; /usr/bin/sudo make install
	@echo "======= Build of $@ Successful ======="

# binutils check needs more memory
#
# First pass, testing binutils is precarious. You are trying to use
# ld and gas built for the new compiler environment on a possibly
# older or incompatible compiler. We will wait until we have the
# first pass compiler built before we test binutils.
.PHONY: binutils
binutils: $(binutils-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	# cd $@; sed -i -e 's/@colophon/@@colophon/' -e 's/doc@cygnus.com/doc@@cygnus.com/' `cat untar.dir`/bfd/doc/bfd.texinfo
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	-cd $@/$@-build/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALLBUILD,$@)

.PHONY: busybox
busybox : \
    $(busybox-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make defconfig
	cd $@/`cat $@/untar.dir`/; make
	# $(call PKGINSTALL,$@)
	# $(call CPLIB,libproto*)
	# $(call CPLIB,lib$@*)
	# $(call CPLIB,$@*)

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
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --enable-install-program=hostname --without-gmp
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

.PHONY: dbus
dbus : $(dbus-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" \
			./configure --prefix=/usr/local \
	                --sysconfdir=/usr/local/etc              \
			--localstatedir=/usr/local/var           \
			--disable-doxygen-docs         \
			--disable-xml-docs             \
			--disable-static               \
			--disable-systemd              \
			--without-systemdsystemunitdir \
			--with-console-auth-dir=/usr/local/var/run/console/ \
			--docdir=/usr/local/share/doc/dbus-1.10.6
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: dejagnu
dejagnu: $(dejagnu-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; mkdir dejagnu
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo mkdir -p /usr/local/share/doc/dejagnu
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; makeinfo --plaintext  -o doc/dejagnu.txt doc/dejagnu.texi
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -dm755 /usr/local/share/doc/dejagnu
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -v -m644 doc/dejagnu.{html,txt} /usr/local/share/doc/dejagnu
	$(call PKGINSTALL,$@)

.PHONY: doxygen
doxygen: $(doxygen-ver)
	$(call SOURCEDIR,$@,xf)
	# Need to add libiconv, normally in glibc, but in our environment it is separate
	# cd $@/`cat $@/untar.dir`/; sed -i -e 's/TMAKE_LIBS[ 	]*=.*/TMAKE_LIBS      = -liconv/' tmake/lib/linux-g++/tmake.conf
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	# cd $@/`cat $@/untar.dir`/; make
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; cmake -DICONV_INCLUDE_DIR=/usr/local/include -DICONV_LIBRARY=/usr/local/lib/libiconv.so -DCMAKE_REQUIRED_INCLUDES=/usr/local/include -G "Unix Makefiles" ../`cat ../untar.dir`/
	cd $@/$@-build/; make
	cd $@/$@-build/; make tests
	$(call PKGINSTALLBUILD,$@)
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
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install-libs
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: ecj
ecj: $(ecj-ver)
	cd $@; /usr/bin/sudo mkdir -pv /usr/local/share/java
	cd $@; /usr/bin/sudo cp -v *.jar /usr/local/share/java/ecj.jar

.PHONY: expat
expat: $(expat-ver)
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

.PHONY: ffmpeg
ffmpeg : \
    $(ffmpeg-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local \
            --enable-gpl         \
            --enable-version3    \
            --enable-nonfree     \
            --enable-shared      \
            --disable-debug      \
            --enable-libass      \
            --enable-libfdk-aac  \
            --enable-libfreetype \
            --enable-libmp3lame  \
            --enable-libopus     \
            --enable-libtheora   \
            --enable-libvorbis   \
            --enable-libvpx      \
            --enable-libx264     \
            --enable-libx265
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: flex
flex : \
    $(flex-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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
	-cd $@/`cat $@/untar.dir`/; sed -i  -e "/AUX.*.gxvalid/s@^# @@" -e "/AUX.*.otvalid/s@^# @@" modules.cfg
	-cd $@/`cat $@/untar.dir`/; sed -ri -e 's:.*(#.*SUBPIXEL.*) .*:\1:' include/config/ftoption.h
	-cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local $(HBOPT)
	cd $@/`cat $@/untar.dir`/; make
	# freetype does not have a test package
	$(call PKGINSTALL,$@)

.PHONY: freetype-nohb
freetype-nohb:
	make freetype HBOPT="--without-harfbuzz"

.PHONY: fribidi
fribidi : \
    $(fribidi-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./bootstrap
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: fuse
fuse: $(fuse-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	# No test suite for fuse
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)

.PHONY: gc
gc: $(gc-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ATOMIC_OPS_CFLAGS=-I/usr/local/include ATOMIC_OPS_LIBS=-L/usr/local/lib ./configure --prefix=/usr/local --enable-gc-debug --enable-gc-assertions --enable-threads=posix
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libcord.*)
	$(call CPLIB,lib$@.*)
	$(call CPLIB,lib$@cpp.*)

export GCC_4_7_3_PATCH
patches/gcc.patch:
	-mkdir -p patches
	echo "$$GCC_4_7_3_PATCH" >> $@

.PHONY: gcc
gcc: $(gcc-ver) patches/gcc.patch
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../mpfr/mpfr*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpfr-* mpfr
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../gmp/gmp*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf gmp-* gmp
	cd $@/`cat $@/untar.dir`; /usr/local/bin/tar xf ../../mpc/mpc*.tar*
	cd $@/`cat $@/untar.dir`; ln -sf mpc-* mpc
	cd $@/`cat $@/untar.dir`; cp ../../ecj/ecj*.jar ./ecj.jar
	cd $@/`cat $@/untar.dir`/gcc/cp; patch -p2 < ../../../../patches/gcc.patch
	# this will let us build glibc
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# May have to disable this to build the non-glibc packages
	# cd $@/`cat $@/untar.dir`; sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    --with-gmp=/usr/local \
		    --with-mpc=/usr/local \
		    --with-mpfr=/usr/local \
		    --enable-shared \
		    --disable-multilib \
		    --prefix=/usr/local \
                    --enable-languages=$(GCC_LANGS) \
		    --with-ecj-jar=/usr/local/share/java/ecj.jar
	cd $@/$@-build/; make
	-cd $@/$@-build/; C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib make check
	test -e /usr/local/bin/cc || /usr/bin/sudo ln -sf /usr/local/bin/gcc /usr/local/bin/cc
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,libssp*)
	$(call CPLIB,libstdc*)
	@echo "======= Build of $@ Successful ======="

.PHONY: gcc-6.3
gcc-6.3: $(gcc-6.3-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir -v $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    LDFLAGS="-L/usr/local/lib -lpth" \
		    --enable-shared \
		    --disable-bootstrap \
		    --disable-threads \
		    --disable-multilib \
		    --prefix=/usr/local \
                    --enable-languages=c,c++
	cd $@/$@-build/; make
	false
	-cd $@/$@-build/; C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib make check
	test -e /usr/local/bin/cc || /usr/bin/sudo ln -sf /usr/local/bin/gcc /usr/local/bin/cc
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,libssp*)
	$(call CPLIB,libstdc*)
	@echo "======= Build of $@ Successful ======="

.PHONY: gcc-7.2
gcc-7.2: $(gcc-7.2-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir -v $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
		    LDFLAGS="-L/usr/local/lib -lpth" \
		    --enable-shared \
		    --disable-bootstrap \
		    --enable-tls=no \
		    --disable-multilib \
		    --prefix=/usr/local \
                    --enable-languages=c,c++
	cd $@/$@-build/; make
	false
	-cd $@/$@-build/; C_INCLUDE_PATH=/usr/local/include LIBRARY_PATH=/usr/local/lib make check
	test -e /usr/local/bin/cc || /usr/bin/sudo ln -sf /usr/local/bin/gcc /usr/local/bin/cc
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,libssp*)
	$(call CPLIB,libstdc*)
	@echo "======= Build of $@ Successful ======="

# 
# Linux from scratch lets us know 9 tests will fail and do under some conditions
#
# We need to build gettext, then iconv, then gettext again
# The second time we build it, the tests will work, so
# we check for the presence of gettext in /usr/local/bin
# before we try to run the tests
#
.PHONY: gettext
gettext: $(gettext-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: global
global: $(global-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; bash reconf.sh
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: go
go: $(go-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/src; patch < ../../../patches/go.patch
	-cd $@; /usr/bin/sudo /bin/rm -rf /usr/local/go
	cd $@; /usr/bin/sudo cp -r go /usr/local/.
	cd /usr/local/go/src; /usr/bin/sudo ./all.bash

# 
# During testing, it does not like a really old ssh config file in /etc/ssh
.PHONY: gnupg
gnupg : \
    $(gnupg-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared \
	    --enable-symcryptrun --enable-maintainer-mode --enable-g13 LDFLAGS=-lrt
	cd $@/`cat $@/untar.dir`/; make
	- cd $@/`cat $@/untar.dir`/; make check || make test
	/usr/bin/sudo /bin/rm -f /usr/local/bin/gpg /usr/local/gpg2
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: gnuplot
gnuplot : \
    $(gnuplot-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local LDFLAGS="-L/usr/local/lib -liconv"
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

#
# Use the included libtasn1, so that we are not dependent on the
# external library
#
.PHONY: gnutls
gnutls: $(gnutls-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-default-trust-store-file=/usr/local/etc/ssl/ca-bundle.crt --with-included-libtasn1 --enable-local-libopts
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
		--disable-lua \
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

export ICUPATCH
patches/icu4c-58.2-fix_enumeration-1.patch:
	-mkdir -p patches
	echo "$$ICUPATCH" >> $@

.PHONY: icu
icu: $(icu-ver) patches/icu4c-58.2-fix_enumeration-1.patch
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`; patch -p1 -i ../../patches/icu4c-58.2-fix_enumeration-1.patch
	cd $@/`cat $@/untar.dir`/source; CC=gcc CXX=g++ ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/source; make
	cd $@/`cat $@/untar.dir`/source; make check || make test
	$(call PKGINSTALLTO,$@,`cat $@/untar.dir`/source)

.PHONY: inetutils
inetutils: $(inetutils-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local  \
	        --localstatedir=/usr/local/var   \
		--disable-logger       \
		--disable-syslogd      \
		--disable-whois        \
		--disable-servers      \
		--with-ncurses-include-dir=/usr/local/include/ncursesw
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Test case fails for a module that was not built and one for a syntax issue in a test
.PHONY: ImageMagick
ImageMagick : \
    $(ImageMagick-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local \
	    --sysconfdir=/usr/local/etc \
	    --enable-hdri \
	    --with-modules \
	    --with-perl \
	    --without-x
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: include-what-you-use
include-what-you-use: $(iwyu-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	# cd $@/$@-build/; cmake -G "Unix Makefiles" -DLLVM_PATH="../../llvm-3.4" ../include-what-you-use
	cd $@/$@-build/; cmake -G "Unix Makefiles" -DLLVM_PATH="/usr/local/lib" ../include-what-you-use
	cd $@/$@-build/; make
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: intltool
intltool: \
    $(intltool-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Tests fail because debug info for string functions are not found in glibc
.PHONY: jq
jq : \
    $(jq-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; autoreconf -i
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --disable-maintainer-mode
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
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
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libgcrypt
libgcrypt : $(libgcrypt-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --disable-aesni-support
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libiconv
libiconv: $(libiconv-ver)
	$(call SOURCEDIR,$@,xfz)
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' srclib/stdio.in.h
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libcharset.*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libpthread
libpthread: \
    $(libpthread-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; chmod a+rx ../`cat ../untar.dir`/configure
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libsecret
libsecret : \
    $(libsecret-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./autogen.sh --prefix=/usr/local --disable-manpages --disable-gtk-doc
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --disable-manpages --disable-gtk-doc
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# The test files for libsndfile have a hardcoded path to /usr/bin/python
# We edit it to /usr/bin/env python
.PHONY: libsndfile
libsndfile : \
    $(libsndfile-ver)
	$(call SOURCEDIR,$@,xf)
	-cd $@/`cat $@/untar.dir`/; sed -i -e 's/#!\/usr\/bin\/python/#!\/usr\/bin\/env python/' src/binheader_writef_check.py
	-cd $@/`cat $@/untar.dir`/; sed -i -e 's/#!\/usr\/bin\/python/#!\/usr\/bin\/env python/' src/create_symbols_file.py
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --disable-octave
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: libtheora
libtheora : \
    $(libtheora-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed -i 's/png_\(sizeof\)/\1/g' examples/png2theora.c
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No make check || make test
# libtool is going to fail Fortran checks, we need a new autoconf and automake, these depend on perl
.PHONY: libtool
libtool: $(libtool-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libltdl*)

export LUASHAREDLIBPATCH
patches/lua-5.3.2-shared_library-1.patch:
	-mkdir -p patches
	echo "$$LUASHAREDLIBPATCH" >> $@

# We need to use the internal libiconv. At some point a call libiconv, added an extra parameter
# If you link with a version with a mismatch in the parameter list, you end up with a segfault.
# Consequently we need to use the libiconv internal to the libunistring package.
.PHONY: libunistring
libunistring : \
    $(libunistring-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --without-libiconv-prefix
	cd $@/$@-build/; make
	cd $@/$@-build/; $(PHASE1_NOCHECK) make check || $(PHASE1_NOCHECK) make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No configure, no make check or test, does not have a good install
.PHONY: libutempter
libutempter : \
    $(libutempter-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av utempter.h /usr/local/include
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av libutempter.a /usr/local/lib
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av libutempter.so* /usr/local/lib
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -av utempter /usr/local/bin
	$(call CPLIB,libutempter*)
	$(call CPLIB,$@*)

# No configure, no make check or test, does not have a good install, just copy the directory
.PHONY: lynis
lynis : \
    $(lynis-ver)
	$(call SOURCEDIR,$@,xf)
	/usr/bin/sudo cp -av $@/`cat $@/untar.dir` /usr/local/.
	/usr/bin/sudo /bin/rm -f /usr/local/bin/lynis
	/usr/bin/sudo bash -c "echo 'cd /usr/local/lynis; ./lynis $$''*' > /usr/local/bin/lynis"
	/usr/bin/sudo chown -R 0:0 /usr/local/lynis/include/*
	/usr/bin/sudo chmod a+x /usr/local/bin/lynis

.PHONY: lua
lua: $(lua-ver) patches/lua-5.3.2-shared_library-1.patch
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; readlink -f . | grep `cat ../untar.dir`
	cd $@/`cat $@/untar.dir`/; patch -Np1 -i ../../patches/lua-5.3.2-shared_library-1.patch
	cd $@/`cat $@/untar.dir`/; make linux MYLIBS=-lncursesw
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make INSTALL_TOP=/usr/local TO_LIB="liblua.a" \
	     INSTALL_DATA="cp -d" INSTALL_MAN=/usr/share/man/man1 install
	cd $@/`cat $@/untar.dir`/src; /usr/bin/sudo cp -av liblua.so* /usr/local/lib
	@echo "======= Build of $@ Successful ======="

.PHONY: lzo
lzo: \
    $(lzo-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared=yes
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

#
# NetPBM packages itself in a a non-standard way into /tmp/netpbm, so
# we can not use our standard package installation script
#
export NETPBMCONFIG
.PHONY: netpbm
netpbm: $(netpbm-ver)
	/usr/bin/sudo /bin/rm -rf /tmp/netpbm
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; cp Makefile.config.in Makefile.config
	cd $@/`cat $@/untar.dir`/; echo "$$NETPBMCONFIG" >> Makefile.config
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make package
	$(call PKGFROMSTAGE,$@,`cat $@/untar.dir`,netpbm)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo mkdir -pv /usr/local/share/netpbm
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v /tmp/netpbm/bin/* /usr/local/bin/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v /tmp/netpbm/include/* /usr/local/include/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v /tmp/netpbm/link/* /usr/local/lib/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v /tmp/netpbm/man/* /usr/local/man/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v /tmp/netpbm/misc/* /usr/local/share/netpbm/.
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: node
node: $(node-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CC=clang CXX=clang++ CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" LDFLAGS="-L/usr/local/lib -lpth" ./configure --prefix=/usr/local --without-snapshot
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: ocaml
ocaml: \
	$(ocaml-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure -prefix /usr/local
	cd $@/`cat $@/untar.dir`/; make world
	$(call PKGINSTALL,$@)
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
	$(call CPLIB,libinproctrace.*)

# From the GIT Makefile
#
# Define SHELL_PATH to a POSIX shell if your /bin/sh is broken.
#
# Define SANE_TOOL_PATH to a colon-separated list of paths to prepend
# to PATH if your tools in /usr/bin are broken.
#
# git needs to come after bash, so we have a good, required, version of
# bash to build against.
# 
export GITCONFIG
.PHONY: git
git: $(git-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; chmod a+x configure
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" ./configure --prefix=/usr/local --with-gitconfig=/usr/local/etc/gitconfig --with-libpcre
	cd $@/`cat $@/untar.dir`/; PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make
	cd $@/`cat $@/untar.dir`/; TEST_NO_MALLOC_CHECK=1 PYTHON_PATH=/usr/local/bin/python SHELL_PATH=/usr/local/bin/bash SANE_TOOL_PATH="/usr/local/bin:/usr/local/sbin" make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /bin/rm -f /usr/local/etc/gitconfig
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo /bin/rm -f /tmp/gitconfig
	cd $@/`cat $@/untar.dir`/; echo "$$GITCONFIG" >> /tmp/gitconfig
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp /tmp/gitconfig /usr/local/etc/gitconfig
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
	$(call CPLIB,libgio*)

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
	cd $@/$@-build/; ../`cat ../untar.dir`/configure \
	    --prefix=/usr/local/glibc \
	    --disable-profile \
	    --libexecdir=/usr/local/lib/glibc \
	    --with-headers=/usr/local/include \
	    -without-selinux \
	    -enable-obsolete-rpc
	cd $@/$@-build/; make
	-cd $@/$@-build/; make check || make test
	-/usr/bin/sudo mkdir -p /usr/local/glibc/etc
	/usr/bin/sudo touch /usr/local/glibc/etc/ld.so.conf
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
	/usr/bin/sudo /bin/rm -rf /usr/local/include/libguile
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
libelf: $(libelf-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure --disable-shared --enable-static --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

# Tests aparently write to /etc/pam.d, which we are using
# Be carefull, installing this may create a system that
# cannot be logged into.
.PHONY: Linux-PAM
Linux-PAM: $(Linux-PAM-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --sysconfdir=/etc --libdir=/usr/local/lib
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	@echo "======= Build of $@ Successful ======="

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
# You need to be careful, not to directly headers_install without a
# INSTALL_HDR_PATH. This will delete directories in /usr/include
# and replace them.
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
	# need to put them in /usr/include without deleting everything
	# else
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make ARCH=x86 headers_install INSTALL_HDR_PATH=dest
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -rv dest/include/* /usr/include/.
	@echo "======= Build of $@ Successful ======="

export COMPILERRTPATCH
patches/compiler-rt.patch:
	-mkdir -p patches
	echo "$$COMPILERRTPATCH" >> $@

# If the install generates a unable to infer compiler target triple for gcc,
# the /usr/bin/sudo needs a ./SETUP.bash before running it.
.PHONY: llvm
llvm: $(llvm-ver) $(clang-ver) $(compiler-rt-ver) patches/compiler-rt.patch
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; tar -xf ../../clang/clang-3.4.src.tar.gz -C tools
	cd $@/`cat $@/untar.dir`/; tar -xf ../../compiler-rt/compiler-rt-3.4.src.tar.gz -C projects
	cd $@/`cat $@/untar.dir`/; mv tools/clang-3.4 tools/clang
	cd $@/`cat $@/untar.dir`/; mv projects/compiler-rt-3.4 projects/compiler-rt
	cd $@/`cat $@/untar.dir`/projects/compiler-rt/lib/sanitizer_common; patch < ../../../../../../patches/compiler-rt.patch
	cd $@/`cat $@/untar.dir`/; CC=gcc CXX=g++ \
	    CPPFLAGS="-I/usr/local/include -I/usr/include -I/usr/include/x86_64-linux-gnu" \
	    LDFLAGS="-L/usr/local/lib" ./configure --prefix=/usr/local \
	    --sysconfdir=/usr/local/etc --enable-libffi --enable-optimized --enable-shared \
	    --enable-targets=all \
	    --with-c-include-dirs="/usr/local/include:/usr/include:/usr/include/x86_64-linux-gnu" \
	    --with-gcc-toolchain=/usr/local
	    # --with-c-include-dirs="/usr/include/linux-2.6.32/include:/usr/include:/usr/local/include"
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: LMDB
LMDB: $(LMDB-ver)
	$(call SOURCEDIR_W_UNTAR,$@,xfz,lmdb-LMDB)
	cd $@/`cat $@/untar.dir`/libraries/liblmdb; make
	$(call PKGINSTALLTOPREFIX,$@,`cat $@/untar.dir`/libraries/liblmdb)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: Math-Pari
Math-Pari : \
    $(Math-Pari-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 perl Makefile.PL LIBS='-L/usr/local/lib -L/usr/lib -L/lib' INC='-I/usr/local/include -I/usr/include -I../../pari/pari-2.3.5/src' pari_tgz=../../pari/pari-2.3.5.tar.gz version23_ok=1
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 make
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 OPENSSL_DIR=/usr/local OPENSSL_PREFIX=/usr/local LD_LIBRARY_PATH=:/usr/local/lib:/usr/lib make test || make check
	$(call PKGINSTALL,$@)

.PHONY: maldetect
maldetect : \
    $(maldetect-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./install.sh

.PHONY: mercurial
mercurial: $(mercurial-ver)
	cd $@/`cat $@/untar.dir`/; make build
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make PREFIX=/usr/local install-bin

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

.PHONY: musl
musl : \
    $(musl-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: mutt
mutt : \
    $(mutt-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure --prefix=/usr/local \
		    --sysconfdir=/usr/local/etc \
		    --with-docdir=/usr/local/share/doc/mutt-1.9.0 \
		    --enable-pop      \
		    --enable-imap     \
		    --enable-hcache   \
		    --without-qdbm    \
		    --with-gdbm       \
		    --without-bdb     \
		    --without-tokyocabinet
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: ncurses
ncurses: $(ncurses-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; CPPFLAGS="-P" ../`cat ../untar.dir`/configure --prefix=/usr/local --with-shared --enable-widec
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	cd $@/$@-build/; for lib in ncurses form panel menu; do \
	    /usr/bin/sudo /bin/rm -vf /usr/local/lib/$${lib}.so ; \
	    /usr/bin/sudo /bin/rm -f /tmp/lib$${lib}.so ; \
	    echo "INPUT(-l$${lib}w)" > /tmp/lib$${lib}.so ; \
	    /usr/bin/sudo /bin/cp /tmp/lib$${lib}.so /usr/local/lib/lib$${lib}.so ; \
	done
	cd $@/$@-build/; for lib in curses ; do \
	    /usr/bin/sudo /bin/rm -vf /usr/local/lib/$${lib}.so ; \
	    /usr/bin/sudo /bin/rm -f /tmp/lib$${lib}.so ; \
	    echo "INPUT(-ln$${lib}w)" > /tmp/lib$${lib}.so ; \
	    /usr/bin/sudo /bin/cp /tmp/lib$${lib}.so /usr/local/lib/lib$${lib}.so ; \
	done
	$(call CPLIB,lib$@*)
	if test -d /usr/local/include/ncursesw ; then test -d /usr/include/ncursesw || test -L /usr/include/ncursesw || /usr/bin/sudo ln -sf /usr/local/include/ncursesw /usr/include/. ; fi 
	if test -d /usr/local/include/ncursesw ; then test -d /usr/include/ncurses || test -L /usr/include/ncurses || /usr/bin/sudo ln -sf f/usr/local/include/ncursesw /usr/include/ncurses ; fi 
	$(call CPLIB,libncurses*)

.PHONY: nettle
nettle: \
    $(nettle-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --libdir=/usr/local/lib
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install-here
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,libnettle*)
	$(call CPLIB,libhogweed*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo install -dv -m755 /usr/share/doc/openssl
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make cp -vfr doc/*     /usr/share/doc/openssl
	$(call LNLIB,libssl.a)
	$(call LNLIB,libssl.so)
	$(call LNLIB,libssl.so.1.0.0)
	$(call LNLIB,libcrypto.a)
	$(call LNLIB,libcrypto.so)
	$(call LNLIB,libcrypto.so.1.0.0)
	@echo "======= Build of $@ Successful ======="

.PHONY: openvpn
openvpn: $(openvpn-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; autoreconf -vi
	# cd $@/`cat $@/untar.dir`/; LIBPAM_LIBS="-L/lib/x86_64-linux-gnu -lpam"
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --disable-plugin-auth-pam
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No trust module, so that test fails
.PHONY: p11-kit
p11-kit : \
    $(p11-kit-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --without-trust-paths
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: pari
pari : \
    $(pari-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 ./Configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 make all
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 make gp
	cd $@/`cat $@/untar.dir`/; PERL_USE_UNSAFE_INC=1 make bench
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp misc/gprc.dft /etc/gprc
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ln -sf /usr/local/include/pari/* /usr/local/include/
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo mkdir -p /usr/local/include/gp
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo mkdir -p /usr/local/include/graph
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo mkdir -p /usr/local/include/language
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp src/gp/*.h /usr/local/include/gp/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp src/graph/*.h /usr/local/include/graph/.
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp src/language/*.h /usr/local/include/language/.
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: pcre
pcre: $(pcre-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-unicode-properties \
	    --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 \
	    --enable-jit
	    #--enable-pcretest-libreadline
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# The first time we build pcre2, we might not have a development readline. The only place this
# hurts us is in the pcre2test program. I am going to give up on the readline capability
# on the readline support in pcre2test.
# --enable-pcre2test-libreadline
#
.PHONY: pcre2
pcre2: $(pcre2-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-unicode \
	                --enable-pcre2-16 --enable-pcre2-32 --enable-pcre2grep-libz \
			--enable-pcre2grep-libbz2 \
			--enable-jit
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: pinentry
pinentry: $(pinentry-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --disable-pinentry-qt5 --enable-pinentry-qt=yes --enable-pinentry-gtk2=yes --enable-pinentry-gnome3=no
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

export PYGOBJECT_PATCH
patches/pygobject-2.28.6-fixes-1.patch:
	-mkdir -p patches
	echo "$$PYGOBJECT_PATCH" >> $@

.PHONY: pngnq
pngnq: $(pngnq-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/src; sed -i -e '/"png.h"/ i #include "zlib.h"' rwpng.c
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# pygobject does not have a working test suite
.PHONY: pygobject
pygobject : \
    $(pygobject-ver) \
    patches/pygobject-2.28.6-fixes-1.patch
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; patch -Np1 -i ../../patches/pygobject-2.28.6-fixes-1.patch
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
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

#
# We may be compiling on a machine without internet access, so
# the Python PIP installations, we do not check the return code.
#
.PHONY: Python
Python: $(Python-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo env LD_LIBRARY_PATH=/usr/local/lib python2.7 setup.py install
	-cd $@/`cat $@/untar.dir`/; wget https://bootstrap.pypa.io/get-pip.py
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo env LD_LIBRARY_PATH=/usr/local/lib python2.7 get-pip.py
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo env LD_LIBRARY_PATH=/usr/local/lib pip install -U setuptools
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo env LD_LIBRARY_PATH=/usr/local/lib pip install -U pip
	-cd $@/`cat $@/untar.dir`/; /usr/bin/sudo env LD_LIBRARY_PATH=/usr/local/lib pip install -U cppclean
	$(call CPLIB,libpython*)

.PHONY: py2cairo
py2cairo : \
    $(py2cairo-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./waf configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; ./waf build
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo ./waf install

export PERL5_PATCH
patches/perl5.patch:
	-mkdir -p patches
	echo "$$PERL5_PATCH" >> $@

.PHONY: perl
perl: $(perl-ver) patches/perl5.patch
	$(call SOURCEDIR,$@,xzf)
	# srand is not being called automatically, probably because of old glibc
	# cd $@/`cat $@/untar.dir`/; /bin/sed -i -e 's/^\(.*srand.*called.*automatically.*\)/@first_run  = mk_rand; \1/' t/op/srand.t
	# Test passes a option to cc that is not supported by all compilers
	cd $@/`cat $@/untar.dir`/; ./Configure -des -Dprefix=/usr/local \
	    -Dvendorprefix=/usr/local \
	    -Dman1dir=/usr/local/share/man/man1 \
	    -Dman3dir=/usr/local/share/man/man3 \
	    -Duseshrplib \
	    -Dusedevel
	cd $@/`cat $@/untar.dir`/; patch perl.h < ../../patches/perl5.patch
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; $(PHASE1_NOCHECK) make test
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libperl.so
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp libperl.so /usr/local/lib/.
	/usr/bin/sudo /bin/rm -f /usr/local/bin/perl
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install PERLNAME=perl
	$(call PKGINSTALL,$@)
	/usr/bin/sudo /bin/rm -f /usr/local/perl
	cd /usr/local/bin; /usr/bin/sudo ln -s "perl"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(perl-ver)))))) perl
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: pkg-config
pkg-config: $(pkg-config-ver)
	$(call SOURCEDIR,$@,xf)
	/usr/bin/sudo /bin/rm -f /usr/local/bin/i686-pc-linux-gnu-pkg-config
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

.PHONY: qt-everywhere-opensource-src
qt-everywhere-opensource-src : \
    $(qt-everywhere-opensource-src-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; ./configure -prefix /usr/local/qt5 \
	            -sysconfdir     /etc/xdg   \
		    -confirm-license           \
		    -opensource                \
		    -dbus-linked               \
		    -openssl-linked            \
		    -system-harfbuzz           \
		    -system-sqlite             \
		    -nomake examples           \
		    -no-rpath                  \
		    -optimized-qmake           \
		    -skip qtwebengine
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: random
random : \
    $(random-ver)
	$(call SOURCEFLATZIPDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo cp -a -v ./ent /usr/local/bin/.

.PHONY: rakudo-star
rakudo-star: $(rakudo-star-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/local/bin/perl Configure.pl --gen-moar --gen-nqp --backend=moar
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make rakudo-test
	cd $@/`cat $@/untar.dir`/; make rakudo-spectest
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# No test suite for readline
.PHONY: readline
readline: $(readline-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make SHLIB_LIBS=-lncursesw
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: ruby
ruby: $(ruby-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-shared
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make
	cd $@/`cat $@/untar.dir`/; LDFLAGS="-L/usr/local/lib -lssp" make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make LDFLAGS="-L/usr/local/lib -lssp" install
	@echo "======= Build of $@ Successful ======="

# I want to link screen as statically as possible, since
# we will likely be building libraries that screen depends on while
# running inside of screen.
.PHONY: screen
screen : $(screen-ver)
	$(call SOURCEDIR,$@,xf)
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/`cat $@/untar.dir`/; sed -i -e "/^# if defined(SVR4) && !defined(DGUX) && !defined(__hpux)/s/$$/  \&\& !defined(linux)/" os.h
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure --prefix=/usr/local LDFLAGS="-static"
	cd $@/`cat $@/untar.dir`/; make
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: sed
sed: $(sed-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	-cd $@/`cat $@/untar.dir`/; sed -i -e '/gets is a security/d' lib/stdio.in.h
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local --with-included-regex
	cd $@/$@-build/; make
	cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: serf
serf: $(serf-ver)
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libserf*
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; sed -i "/Append/s:RPATH=libdir,::"  SConstruct && \
	sed -i "/Default/s:lib_static,::"   SConstruct && \
	sed -i "/Alias/s:install_static,::" SConstruct && \
	scons PREFIX=/usr/local
	# The tests use certificates that have expired in 2017, generating
	# 14 failures.
	# Debian has fixed this with:
	# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=862027
	# I suspect an updated version of serf will fix this
	-cd $@/`cat $@/untar.dir`/; scons check
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo scons PREFIX=/usr/local install
	@echo "======= Build of $@ Successful ======="

.PHONY: scons
scons : $(scons-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py install \
	    --prefix=/usr/local  --standard-lib --optimize=1 --install-data=/usr/share
	@echo "======= Build of $@ Successful ======="

.PHONY: six
six : $(six-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py build
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py install \
	    --prefix=/usr/local --optimize=1 --install-data=/usr/share
	@echo "======= Build of $@ Successful ======="

# need to start working on a generic python build rule
.PHONY: ufw
ufw : $(ufw-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py build
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo python setup.py install \
	    --prefix=/usr/local
	@echo "======= Build of $@ Successful ======="

# slang does not like the parallel build
.PHONY: slang
slang: $(slang-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make -j1
	cd $@/`cat $@/untar.dir`/; make check || make test
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make install-all
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: snort
snort : \
    $(snort-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --enable-sourcefire
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

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
tclx: $(tclx-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; ../`cat ../untar.dir`/configure --prefix=/usr/local
	cd $@/$@-build/; make
	# Something fails, I do not expect to need tclX for anything
	# cd $@/$@-build/; make check || make test
	$(call PKGINSTALLBUILD,$@)

export TCPWRAPPERSPATCH
patches/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch:
	-mkdir -p patches
	echo "$$TCPWRAPPERSPATCH" >> $@

.PHONY: tcp_wrappers
tcp_wrappers: $(tcp_wrappers-ver) patches/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch
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

# From http://www.linuxfromscratch.org/lfs/view/development/chapter06/util-linux.html
# Warning Running the test suite as the root user can be harmful to your system.
.PHONY: util-linux
util-linux: $(util-linux-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" \
	    ./configure \
	    ADJTIME_PATH=/usr/local/var/lib/hwclock/adjtime   \
	    --prefix=/usr/local --enable-arch --disable-partx --enable-write \
	    --docdir=/usr/local/share/doc/util-linux-2.28 \
	    --disable-chfn-chsh  \
	    --disable-login      \
	    --enable-mount       \
	    --disable-nologin    \
	    --disable-su         \
	    --disable-setpriv    \
	    --disable-runuser    \
	    --enable-pylibmount  \
	    --disable-static     \
	    --without-systemd    \
	    --without-systemdsystemunitdir
	cd $@/`cat $@/untar.dir`/; make CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw"
	$(call PKGINSTALL,$@)
	$(call CPLIB,libuuid*)

# From https://en.wikipedia.org/wiki/Util-linux
# A fork, util-linux-ng—with ng meaning "next generation"—was created when
# development stalled,[3] but as of January 2011 has been renamed back to
# util-linux, and is the official version of the package.
.PHONY: util-linux-ng
util-linux-ng: $(util-linux-ng-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw" ./configure --prefix=/usr/local --enable-arch --enable-partx --enable-write
	cd $@/`cat $@/untar.dir`/; make CPPFLAGS="-I/usr/local/include -I/usr/local/include/ncursesw"
	$(call PKGINSTALL,$@)
	$(call CPLIB,libuuid*)

# The tests hardcode a path back to the original OS directories
.PHONY: vala
vala : \
    $(vala-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	-cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Tests fail if GDB-7.11 is not installed
.PHONY: valgrind
valgrind : \
    $(valgrind-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local \
	    --datadir=/usr/local/share/doc/valgrind
	cd $@/`cat $@/untar.dir`/; make
	#cd $@/`cat $@/untar.dir`/; make regtest
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: vera++
vera++ : \
    $(vera++-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@/`cat $@/untar.dir`/; cmake -G "Unix Makefiles" -DLLVM_PATH="/usr/local/lib" -DVERA_USE_SYSTEM_LUA=OFF
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libproto*)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

# Vim may need to be in a foreground window to support its tests
# unset DISPLAY to get the tests to pass
# unset GUI_TESTTARGET from trying to test the GUI component. I want to build both, but may be running
# on a headless server, so I don't want to fail the tests for the GUI component.
# The newer tests do things like grep the grub configuration file for specific strings. Well, we are
# old enough we do not have grub. So I will let it run the tests, but not score them.
.PHONY: vim
vim: $(vim-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-perlinterp --enable-pythoninterp --enable-tclinterp --enable-rubyinterp
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --with-features=huge --enable-pythoninterp --enable-tclinterp --enable-rubyinterp --with-x --enable-gui --with-tlib=ncursesw
	cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C make
	-cd $@/`cat $@/untar.dir`/; LANG=C LC_ALL=C GUI_TESTTARGET= make test || LANG=C LC_ALL=C make check
	$(call PKGINSTALL,$@)

.PHONY: wget
wget: $(wget-ver)
	$(call SOURCEDIR,$@,xf)
	# cd $@/`cat $@/untar.dir`/; patch -Np1 -i ../wget-1.14-texi2pod-1.patch
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local --sysconfdir=/usr/local/etc --with-ssl=openssl
	cd $@/`cat $@/untar.dir`/; make
	# Uses perl to do the tests and setup a server, there is something failing
	# Linux from scratch warsn HTTPS tests fail if openssl is used and
	# valgrind is enabled.
	# cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)

.PHONY: whois
whois: $(whois-ver)
	$(call SOURCEDIR,$@,xfz)
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local install-whois
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local install-mkpasswd
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local install-pos
	$(call PKGINSTALL,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: x265
x265: $(x265-ver)
	$(call SOURCEDIR,$@,xf)
	cd $@; mkdir $@-build
	cd $@/$@-build/; readlink -f . | grep $@-build
	cd $@/$@-build/; cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local ../x265_2.3/source
	cd $@/$@-build/; make
	$(call PKGINSTALLBUILD,$@)
	$(call CPLIB,lib$@*)
	$(call CPLIB,$@*)

.PHONY: zip
zip: $(zip-ver)
	$(call SOURCEDIR,$@,zip)
	cd $@/`cat $@/untar.dir`/; make -f unix/Makefile generic_gcc
	cd $@/`cat $@/untar.dir`/; /usr/bin/sudo make prefix=/usr/local MANDIR=/usr/local/man/man1 -f unix/Makefile install
	@echo "======= Build of $@ Successful ======="

.PHONY: zlib
zlib: $(zlib-ver)
	$(call SOURCEDIR,$@,xfz)
	/usr/bin/sudo /bin/rm -f /usr/local/lib/libz.a /usr/local/lib/libz.so /usr/local/lib/libz.so.1*
	cd $@/`cat $@/untar.dir`/; ./configure --prefix=/usr/local
	cd $@/`cat $@/untar.dir`/; make
	cd $@/`cat $@/untar.dir`/; make check || make test
	$(call PKGINSTALL,$@)
	$(call CPLIB,libz.*)

.PHONY: wget-all
wget-all: \
    $(Algorithm-Diff-ver) \
    $(Any-Moose-ver) \
    $(Archive-Zip-ver) \
    $(B-Hooks-EndOfScope-ver) \
    $(CPAN-Meta-Check-ver) \
    $(Capture-Tiny-ver) \
    $(Class-Data-Inheritable-ver) \
    $(Class-Inspector-ver) \
    $(Class-Load-ver) \
    $(Class-Load-XS-ver) \
    $(Class-Loader-ver) \
    $(Class-Method-Modifiers-ver) \
    $(Class-Singleton-ver) \
    $(Class-Tiny-ver) \
    $(Crypt-Random-Source-ver) \
    $(Crypt-Random-ver) \
    $(Data-OptList-ver) \
    $(Date-Manip-ver) \
    $(DateTime-Locale-ver) \
    $(DateTime-TimeZone-ver) \
    $(DateTime-ver) \
    $(Devel-GlobalDestruction-ver) \
    $(Devel-OverloadInfo-ver) \
    $(Devel-StackTrace-ver) \
    $(Devel-Symdump-ver) \
    $(Digest-HMAC-ver) \
    $(Digest-SHA1-ver) \
    $(Dist-CheckConflicts-ver) \
    $(Encode-Locale-ver) \
    $(Eval-Closure-ver) \
    $(Exception-Class-ver) \
    $(Exporter-Tiny-ver) \
    $(ExtUtils-Config-ver) \
    $(ExtUtils-Helpers-ver) \
    $(ExtUtils-InstallPaths-ver) \
    $(File-pushd-ver) \
    $(File-Copy-Recursive-ver) \
    $(File-Listing-ver) \
    $(File-Path-ver) \
    $(File-Remove-ver) \
    $(File-ShareDir-ver) \
    $(File-ShareDir-Install-ver) \
    $(HTML-Parser-ver) \
    $(HTML-Tagset-ver) \
    $(HTTP-Cookies-ver) \
    $(HTTP-Daemon-ver) \
    $(HTTP-Date-ver) \
    $(HTTP-Message-ver) \
    $(HTTP-Negotiate-ver) \
    $(IO-BufferedSelect-ver) \
    $(IO-HTML-ver) \
    $(IO-Socket-SSL-ver) \
    $(ImageMagick-ver) \
    $(Importer-ver) \
    $(IPC-Run3-ver) \
    $(JSON-MaybeXS-ver) \
    $(LMDB-ver) \
    $(LWP-MediaTypes-ver) \
    $(LWP-Protocol-https-ver) \
    $(Linux-PAM-ver) \
    $(List-MoreUtils-ver) \
    $(Log-Log4perl-ver) \
    $(MRO-Compat-ver) \
    $(Math-Pari-ver) \
    $(Math-Random-ISAAC-ver) \
    $(Math-Random-Secure-ver) \
    $(MoarVM-ver) \
    $(Module-Build-XSUtil-ver) \
    $(Module-Build-ver) \
    $(Module-Build-Tiny-ver) \
    $(Module-Find-ver) \
    $(Module-Implementation-ver) \
    $(Module-Install-ver) \
    $(Module-Pluggable-ver) \
    $(Module-Runtime-ver) \
    $(Module-Runtime-Conflicts-ver) \
    $(Module-ScanDeps-ver) \
    $(Mojolicious-ver) \
    $(Moo-ver) \
    $(Moose-ver) \
    $(Mouse-ver) \
    $(MouseX-Types-ver) \
    $(Net-HTTP-ver) \
    $(Net-DNS-ver) \
    $(Net-SSLeay-ver) \
    $(PAR-Dist-ver) \
    $(Package-DeprecationManager-ver) \
    $(Package-Stash-XS-ver) \
    $(Package-Stash-ver) \
    $(Params-Util-ver) \
    $(Params-ValidationCompiler-ver) \
    $(Path-Tiny-ver) \
    $(PathTools-ver) \
    $(Pod-Coverage-ver) \
    $(Python-ver) \
    $(Role-Tiny-ver) \
    $(Scalar-List-Utils-ver) \
    $(Scalar-MoreUtils-ver) \
    $(Scope-Guard-ver) \
    $(Specio-ver) \
    $(Sub-Exporter-Progressive-ver) \
    $(Sub-Exporter-ver) \
    $(Sub-Identify-ver) \
    $(Sub-Info-ver) \
    $(Sub-Install-ver) \
    $(Sub-Name-ver) \
    $(Sub-Uplevel-ver) \
    $(Term-Table-ver) \
    $(Test-CleanNamespaces-ver) \
    $(Test-Deep-ver) \
    $(Test-Exception-ver) \
    $(Test-Fatal-ver) \
    $(Test-File-ver) \
    $(Test-File-ShareDir-ver) \
    $(Test-Inter-ver) \
    $(Test-LeakTrace-ver) \
    $(Test-Needs-ver) \
    $(Test-NoWarnings-ver) \
    $(Test-Pod-Coverage-ver) \
    $(Test-Pod-ver) \
    $(Test-Requires-ver) \
    $(Test-RequiresInternet-ver) \
    $(Test-SharedFork-ver) \
    $(Test-Simple-ver) \
    $(Test-utf8-ver) \
    $(Test-Warn-ver) \
    $(Test-Warnings-ver) \
    $(Test-Without-Module-ver) \
    $(Test2-Plugin-NoWarnings-ver) \
    $(Test2-Suite-ver) \
    $(Text-Differences-ver) \
    $(Try-Tiny-ver) \
    $(Type-Tiny-ver) \
    $(URI-ver) \
    $(Variable-Magic-ver) \
    $(WWW-RobotRules-ver) \
    $(XML-Parser-ver) \
    $(YAML-Tiny-ver) \
    $(ack-ver) \
    $(acl-ver) \
    $(alsa-lib-ver) \
    $(apr-util-ver) \
    $(apr-ver) \
    $(attr-ver) \
    $(autoconf-ver) \
    $(autogen-ver) \
    $(automake-ver) \
    $(autossh-ver) \
    $(bash-ver) \
    $(boost-ver) \
    $(bcrypt-ver) \
    $(binutils-ver) \
    $(bison-ver) \
    $(busybox-ver) \
    $(bzip-ver) \
    $(c-ares-ver) \
    $(ca-cert-ver) \
    $(cairo-ver) \
    $(check-ver) \
    $(clang-ver) \
    $(clisp-ver) \
    $(cmake-ver) \
    $(compiler-rt-ver) \
    $(coreutils-ver) \
    $(cppcheck-ver) \
    $(crosextrafonts-carlito-ver) \
    $(crosextrafonts-ver) \
    $(curl-ver) \
    $(daq-ver) \
    $(dash-ver) \
    $(db-ver) \
    $(dbus-ver) \
    $(dejagnu-ver) \
    $(diffutils-ver) \
    $(doxygen-ver) \
    $(e2fsprogs-ver) \
    $(ecj-ver) \
    $(expat-ver) \
    $(expect-ver) \
    $(fdk-aac-ver) \
    $(ffmpeg-ver) \
    $(file-ver) \
    $(findutils-ver) \
    $(flac-ver) \
    $(flex-ver) \
    $(fontconfig-ver) \
    $(freetype-ver) \
    $(fribidi-ver) \
    $(fuse-ver) \
    $(gawk-ver) \
    $(gc-ver) \
    $(gcc-6.3-ver) \
    $(gcc-7.2-ver) \
    $(gcc-ver) \
    $(gdb-ver) \
    $(gdbm-ver) \
    $(gettext-ver) \
    $(git-ver) \
    $(glib-ver) \
    $(glibc-ver) \
    $(global-ver) \
    $(gmp-ver) \
    $(gntls-ver) \
    $(gnupg-ver) \
    $(gnuplot-ver) \
    $(go-ver) \
    $(gobject-introspection-ver) \
    $(gpgme-ver) \
    $(grep-ver) \
    $(guile-ver) \
    $(gzip-ver) \
    $(harfbuzz-ver) \
    $(hashdeep-ver) \
    $(htop-ver) \
    $(httpd-ver) \
    $(hwloc-ver) \
    $(icu-ver) \
    $(inc-latest-ver) \
    $(inetutils-ver) \
    $(intltool-ver) \
    $(iptraf-ng-ver) \
    $(iwyu-ver) \
    $(jnettop-ver) \
    $(jpeg-ver) \
    $(jq-ver) \
    $(lame-ver) \
    $(libarchive-ver) \
    $(libass-ver) \
    $(libassuan-ver) \
    $(libatomic_ops-ver) \
    $(libcap-ver) \
    $(libdnet-ver) \
    $(libelf-ver) \
    $(libevent-ver) \
    $(libffi-ver) \
    $(libgcrypt-ver) \
    $(libgpg-error-ver) \
    $(libiconv-ver) \
    $(libidn-ver) \
    $(libksba-ver) \
    $(libmnl-ver) \
    $(libmpeg2-ver) \
    $(libnftnl-ver) \
    $(libogg-ver) \
    $(libpcap-ver) \
    $(libpng-ver) \
    $(libpthread-ver) \
    $(libsecret-ver) \
    $(libsndfile-ver) \
    $(libtasn1-ver) \
    $(libtheora-ver) \
    $(libtool-ver) \
    $(libunistring-ver) \
    $(libusb-ver) \
    $(libuv-ver) \
    $(libutempter-ver) \
    $(libvorbis-ver) \
    $(libvpx-ver) \
    $(libwww-perl-ver) \
    $(libxml2-ver) \
    $(libxslt-ver) \
    $(lua-ver) \
    $(lxsplit-ver) \
    $(lynis-ver) \
    $(lzma-ver) \
    $(lzo-ver) \
    $(m4-ver) \
    $(make-ver) \
    $(maldetect-ver) \
    $(mercurial-ver) \
    $(mosh-ver) \
    $(mpc-ver) \
    $(mpfr-ver) \
    $(multitail-ver) \
    $(musl-ver) \
    $(mutt-ver) \
    $(namespace-autoclean-ver) \
    $(namespace-clean-ver) \
    $(nano-ver) \
    $(nasm-ver) \
    $(ncurses-ver) \
    $(netpbm-ver) \
    $(nettle-ver) \
    $(nftables-ver) \
    $(node-ver) \
    $(ntbtls-ver) \
    $(npth-ver) \
    $(ntfs-3g-ver) \
    $(oath-toolkit-ver) \
    $(ocaml-ver) \
    $(octave-ver) \
    $(openssl-ver) \
    $(openvpn-ver) \
    $(opus-ver) \
    $(p11-kit-ver) \
    $(p7zip-ver) \
    $(pango-ver) \
    $(par2cmdline-ver) \
    $(pari-ver) \
    $(password-store-ver) \
    $(patch-ver) \
    $(pcre-ver) \
    $(pcre2-ver) \
    $(perl-ver) \
    $(pinentry-ver) \
    $(pixman-ver) \
    $(pkg-config-ver) \
    $(pngnq-ver) \
    $(popt-ver) \
    $(protobuf-ver) \
    $(psmisc-ver) \
    $(pth-ver) \
    $(py2cairo-ver) \
    $(pygobject-ver) \
    $(qt-everywhere-opensource-src-ver) \
    $(rakudo-star-ver) \
    $(random-ver) \
    $(readline-ver) \
    $(rng-tools-ver) \
    $(ruby-ver) \
    $(scons-ver) \
    $(screen-ver) \
    $(scrypt-ver) \
    $(sed-ver) \
    $(serf-ver) \
    $(sharutils-ver) \
    $(six-ver) \
    $(slang-ver) \
    $(snort-ver) \
    $(socat-ver) \
    $(sparse-ver) \
    $(sqlite-ver) \
    $(srm-ver) \
    $(subversion-ver) \
    $(swig-ver) \
    $(symlinks-ver) \
    $(tar-ver) \
    $(tcc-ver) \
    $(tcl-ver) \
    $(tclx-ver) \
    $(tcp_wrappers-ver) \
    $(tcpdump-ver) \
    $(tenshi-ver) \
    $(texinfo-ver) \
    $(tmux-ver) \
    $(truecrypt-ver) \
    $(ufw-ver) \
    $(unrar-ver) \
    $(unzip-ver) \
    $(util-linux-ver) \
    $(vala-ver) \
    $(valgrind-ver) \
    $(vera++-ver) \
    $(vim-ver) \
    $(wget-ver) \
    $(which-ver) \
    $(whois-ver) \
    $(wipe-ver) \
    $(x264-ver) \
    $(xmlsec1-ver) \
    $(yasm-ver) \
    $(zip-ver) \
    $(zlib-ver) \
    $(util-linux-ng-ver)

$(ack-ver):
	$(call SOURCEWGET,"ack","http://beyondgrep.com/"$(notdir $(ack-ver)))

$(acl-ver):
	$(call SOURCEWGET,"acl","http://download.savannah.gnu.org/releases/"$(acl-ver))

$(alsa-lib-ver):
	$(call SOURCEWGET,"alsa-lib","ftp://ftp.alsa-project.org/pub/lib/"$(notdir $(alsa-lib-ver)))

$(Any-Moose-ver):
	$(call SOURCEWGET,"Any-Moose","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Any-Moose-ver)))

$(apr-ver):
	$(call SOURCEWGET,"apr","http://archive.apache.org/dist/apr/"$(notdir $(apr-ver)))

$(apr-util-ver):
	$(call SOURCEWGET,"apr-util","http://archive.apache.org/dist/apr/"$(notdir $(apr-util-ver)))

$(Archive-Zip-ver):
	$(call SOURCEWGET,"Archive-Zip","http://search.cpan.org/CPAN/authors/id/P/PH/PHRED/"$(notdir $(Archive-Zip-ver)))

$(Algorithm-Diff-ver):
	$(call SOURCEWGET,"Algorithm-Diff","http://search.cpan.org/CPAN/authors/id/T/TY/TYEMQ/"$(notdir $(Algorithm-Diff-ver)))

$(attr-ver):
	$(call SOURCEWGET,"attr","http://download.savannah.gnu.org/releases/attr/attr-2.4.47.src.tar.gz")

$(autoconf-ver):
	$(call SOURCEWGET,"autoconf","https://ftp.gnu.org/gnu/"$(autoconf-ver))

$(autogen-ver):
	$(call SOURCEWGET,"autogen","https://ftp.gnu.org/gnu/autogen/rel"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(autogen-ver))))))"/"$(notdir $(autogen-ver)))

$(automake-ver):
	$(call SOURCEWGET,"automake","https://ftp.gnu.org/gnu/"$(automake-ver))

$(autossh-ver):
	$(call SOURCEWGET,"autossh","http://www.harding.motd.ca/"$(autossh-ver))

$(B-Hooks-EndOfScope-ver):
	$(call SOURCEWGET,"B-Hooks-EndOfScope","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(B-Hooks-EndOfScope-ver)))

$(bash-ver):
	$(call SOURCEWGET,"bash","https://ftp.gnu.org/gnu/"$(bash-ver))

$(bcrypt-ver):
	$(call SOURCEWGET,"bcrypt","http://bcrypt.sourceforge.net/bcrypt-1.1.tar.gz")

$(binutils-ver):
	$(call SOURCEWGET,"binutils","https://ftp.gnu.org/gnu/"$(binutils-ver))

$(bison-ver):
	$(call SOURCEWGET,"bison","http://ftp.gnu.org/gnu/"$(bison-ver))

$(boost-ver):
	$(call SOURCEWGET,"boost","https://dl.bintray.com/boostorg/release/1.63.0/source/"$(notdir $(boost-ver)))

$(busybox-ver):
	$(call SOURCEWGET,"busybox","http://busybox.net/downloads/"$(notdir $(busybox-ver)))

$(bzip-ver):
	$(call SOURCEWGET,"bzip","http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz")

$(c-ares-ver):
	$(call SOURCEWGET,"c-ares","https://c-ares.haxx.se/download/"$(notdir $(c-ares-ver)))

$(ca-cert-ver):
	$(call SOURCEWGET,"ca-cert","http://anduin.linuxfromscratch.org/sources/other/certdata.txt")
	cd ca-cert; mkdir -p ca-cert-1.0
	cd ca-cert; mv certdata.txt ca-cert-1.0
	cd ca-cert; tar cfz ca-cert-1.0.tar.gz ./ca-cert-1.0

$(cairo-ver):
	$(call SOURCEWGET,"cairo","http://cairographics.org/releases/"$(notdir $(cairo-ver)))

$(Capture-Tiny-ver):
	$(call SOURCEWGET,"Capture-Tiny","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(Capture-Tiny-ver)))

$(check-ver):
	$(call SOURCEWGET,"check","http://downloads.sourceforge.net/project/check/check/0.9.12/check-0.9.12.tar.gz")

$(clang-ver):
	$(call SOURCEWGET,"clang","http://llvm.org/releases/3.4/clang-3.4.src.tar.gz")

$(Class-Data-Inheritable-ver):
	$(call SOURCEWGET,"Class-Data-Inheritable","http://search.cpan.org/CPAN/authors/id/T/TM/TMTM/"$(notdir $(Class-Data-Inheritable-ver)))

$(Class-Inspector-ver):
	$(call SOURCEWGET,"Class-Inspector","http://search.cpan.org/CPAN/authors/id/P/PL/PLICEASE/"$(notdir $(Class-Inspector-ver)))

$(Class-Load-ver):
	$(call SOURCEWGET,"Class-Load","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Class-Load-ver)))

$(Class-Load-XS-ver):
	$(call SOURCEWGET,"Class-Load-XS","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Class-Load-XS-ver)))

$(Class-Loader-ver):
	$(call SOURCEWGET,"Class-Loader","http://search.cpan.org/CPAN/authors/id/V/VI/VIPUL/"$(notdir $(Class-Loader-ver)))

$(Class-Method-Modifiers-ver):
	$(call SOURCEWGET,"Class-Method-Modifiers","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Class-Method-Modifiers-ver)))

$(Class-Singleton-ver):
	$(call SOURCEWGET,"Class-Singleton","http://search.cpan.org/CPAN/authors/id/S/SH/SHAY/"$(notdir $(Class-Singleton-ver)))

$(Class-Tiny-ver):
	$(call SOURCEWGET,"Class-Tiny","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(Class-Tiny-ver)))

$(clisp-ver):
	$(call SOURCEWGET,"clisp","https://ftp.gnu.org/pub/gnu/"$(clisp-ver))

$(cmake-ver):
	$(call SOURCEWGET,"cmake","http://www.cmake.org/files/v3.4/"$(notdir $(cmake-ver)))

$(compiler-rt-ver):
	$(call SOURCEWGET,"compiler-rt","http://llvm.org/releases/3.4/compiler-rt-3.4.src.tar.gz")

$(coreutils-ver):
	$(call SOURCEWGET,"coreutils","http://ftp.gnu.org/gnu/"$(coreutils-ver))

$(CPAN-Meta-Check-ver):
	$(call SOURCEWGET,"CPAN-Meta-Check","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(CPAN-Meta-Check-ver)))

$(cppcheck-ver):
	$(call SOURCEWGET,"cppcheck","https://github.com/danmar/cppcheck/archive/"$(notdir $(cppcheck-ver)))

$(crosextrafonts-ver):
	$(call SOURCEWGET,"crosextrafonts","http://commondatastorage.googleapis.com/chromeos-localmirror/distfiles/"$(notdir $(crosextrafonts-ver)))

$(crosextrafonts-carlito-ver):
	$(call SOURCEWGET,"crosextrafonts-carlito","http://commondatastorage.googleapis.com/chromeos-localmirror/distfiles/"$(notdir $(crosextrafonts-carlito-ver)))

$(Crypt-Random-ver):
	$(call SOURCEWGET,"Crypt-Random","http://search.cpan.org/CPAN/authors/id/V/VI/VIPUL/"$(notdir $(Crypt-Random-ver)))

$(Crypt-Random-Source-ver):
	$(call SOURCEWGET,"Crypt-Random-Source","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Crypt-Random-Source-ver)))

$(curl-ver):
	$(call SOURCEWGET,"curl","http://curl.haxx.se/download/"$(notdir $(curl-ver)))

$(daq-ver):
	$(call SOURCEWGET,"daq","https://www.snort.org/downloads/snort/"$(notdir $(daq-ver)))

$(dash-ver):
	$(call SOURCEWGET,"dash","https://git.kernel.org/pub/scm/utils/dash/dash.git/snapshot/"$(notdir $(dash-ver)))

$(Data-OptList-ver):
	$(call SOURCEWGET,"Data-OptList","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(Data-OptList-ver)))

$(Date-Manip-ver):
	$(call SOURCEWGET,"Date-Manip","http://search.cpan.org/CPAN/authors/id/S/SB/SBECK/"$(notdir $(Date-Manip-ver)))

$(DateTime-ver):
	$(call SOURCEWGET,"DateTime","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(DateTime-ver)))

$(DateTime-Locale-ver):
	$(call SOURCEWGET,"DateTime-Locale","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(DateTime-Locale-ver)))

$(DateTime-TimeZone-ver):
	$(call SOURCEWGET,"DateTime-TimeZone","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(DateTime-TimeZone-ver)))

$(db-ver):
	# (call SOURCEWGET,"db","http://download.oracle.com/otn/berkeley-"$(db-ver))
	$(call SOURCEWGET,"db","http://download.oracle.com/berkeley-"$(db-ver))

$(Devel-GlobalDestruction-ver):
	$(call SOURCEWGET,"Devel-GlobalDestruction","http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/"$(notdir $(Devel-GlobalDestruction-ver)))

$(Devel-OverloadInfo-ver):
	$(call SOURCEWGET,"Devel-OverloadInfo","http://search.cpan.org/CPAN/authors/id/I/IL/ILMARI/"$(notdir $(Devel-OverloadInfo-ver)))

$(Devel-StackTrace-ver):
	$(call SOURCEWGET,"Devel-StackTrace","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Devel-StackTrace-ver)))

$(Devel-Symdump-ver):
	$(call SOURCEWGET,"Devel-Symdump","http://search.cpan.org/CPAN/authors/id/A/AN/ANDK/"$(notdir $(Devel-Symdump-ver)))

$(dbus-ver):
	$(call SOURCEWGET,"dbus","http://dbus.freedesktop.org/releases/"$(dbus-ver))

$(dejagnu-ver):
	$(call SOURCEWGET,"dejagnu","http://ftp.gnu.org/pub/gnu/"$(dejagnu-ver))

$(diffutils-ver):
	$(call SOURCEWGET,"diffutils","http://ftp.gnu.org/gnu/"$(diffutils-ver))

$(Digest-HMAC-ver):
	$(call SOURCEWGET,"Digest-HMAC","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(Digest-HMAC-ver)))

$(Digest-SHA1-ver):
	$(call SOURCEWGET,"Digest-SHA1","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(Digest-SHA1-ver)))

$(Dist-CheckConflicts-ver):
	$(call SOURCEWGET,"Dist-CheckConflicts","http://search.cpan.org/CPAN/authors/id/D/DO/DOY/"$(notdir $(Dist-CheckConflicts-ver)))

$(doxygen-ver):
	$(call SOURCEWGET,"doxygen","https://github.com/doxygen/doxygen/archive/"$(notdir $(doxygen-ver)))

$(e2fsprogs-ver):
	$(call SOURCEGIT,"e2fsprogs","git://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git")

$(ecj-ver):
	$(call SOURCEWGET,"ecj","ftp://sourceware.org/pub/java/ecj-latest.jar")

$(Encode-Locale-ver):
	$(call SOURCEWGET,"Encode-Locale","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(Encode-Locale-ver)))

$(File-Listing-ver):
	$(call SOURCEWGET,"File-Listing","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(File-Listing-ver)))

$(Eval-Closure-ver):
	$(call SOURCEWGET,"Eval-Closure","http://search.cpan.org/CPAN/authors/id/D/DO/DOY/"$(notdir $(Eval-Closure-ver)))

$(Exception-Class-ver):
	$(call SOURCEWGET,"Exception-Class","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Exception-Class-ver)))

$(expat-ver):
	$(call SOURCEWGET,"expat","http://downloads.sourceforge.net/expat/expat-2.1.0.tar.gz")

$(expect-ver):
	$(call SOURCEWGET,"expect","http://prdownloads.sourceforge.net/"$(expect-ver))

$(Exporter-Tiny-ver):
	$(call SOURCEWGET,"Exporter-Tiny","http://search.cpan.org/CPAN/authors/id/T/TO/TOBYINK/"$(notdir $(Exporter-Tiny-ver)))

$(ExtUtils-Config-ver):
	$(call SOURCEWGET,"ExtUtils-Config","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(ExtUtils-Config-ver)))

$(ExtUtils-Helpers-ver):
	$(call SOURCEWGET,"ExtUtils-Helpers","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(ExtUtils-Helpers-ver)))

$(ExtUtils-InstallPaths-ver):
	$(call SOURCEWGET,"ExtUtils-InstallPaths","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(ExtUtils-InstallPaths-ver)))

$(fdk-aac-ver):
	$(call SOURCEWGET,"fdk-aac","http://downloads.sourceforge.net/opencore-amr/"$(notdir $(fdk-aac-ver)))

$(file-ver):
	$(call SOURCEWGET,"file","ftp://ftp.astron.com/pub/"$(file-ver))

$(File-pushd-ver):
	$(call SOURCEWGET,"File-pushd","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(File-pushd-ver)))

$(File-Copy-Recursive-ver):
	$(call SOURCEWGET,"File-Copy-Recursive","http://search.cpan.org/CPAN/authors/id/D/DM/DMUEY/"$(notdir $(File-Copy-Recursive-ver)))

$(File-Path-ver):
	$(call SOURCEWGET,"File-Path","http://search.cpan.org/CPAN/authors/id/J/JK/JKEENAN/"$(notdir $(File-Path-ver)))

$(File-Remove-ver):
	$(call SOURCEWGET,"File-Remove","http://search.cpan.org/CPAN/authors/id/S/SH/SHLOMIF/"$(notdir $(File-Remove-ver)))

$(File-ShareDir-ver):
	$(call SOURCEWGET,"File-ShareDir","http://search.cpan.org/CPAN/authors/id/R/RE/REHSACK/"$(notdir $(File-ShareDir-ver)))

$(File-ShareDir-Install-ver):
	$(call SOURCEWGET,"File-ShareDir-Install","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(File-ShareDir-Install-ver)))

$(findutils-ver):
	$(call SOURCEWGET,"findutils","https://ftp.gnu.org/pub/gnu/"$(findutils-ver))

$(flac-ver):
	$(call SOURCEWGET,"flac","http://downloads.xiph.org/releases/flac/"$(notdir $(flac-ver)))

$(flex-ver):
	$(call SOURCEWGET,"flex","https://github.com/westes/flex/releases/download/v"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(flex-ver))))))"/"$(notdir $(flex-ver)))

$(ffmpeg-ver):
	$(call SOURCEWGET,"ffmpeg","http://ffmpeg.org/releases/"$(notdir $(ffmpeg-ver)))

$(fontconfig-ver):
	$(call SOURCEWGET,"fontconfig","http://www.freedesktop.org/software/fontconfig/release/"$(notdir $(fontconfig-ver)))

$(freetype-ver):
	$(call SOURCEWGET,"freetype","https://download.savannah.gnu.org/releases/"$(freetype-ver))

$(fribidi-ver):
	$(call SOURCEWGET,"fribidi","https://github.com/fribidi/fribidi/archive/"$(notdir $(fribidi-ver)))

$(fuse-ver):
	$(call SOURCEWGET,"fuse","https://github.com/libfuse/libfuse/releases/download/fuse_2_9_4/"$(notdir $(fuse-ver)))

$(gawk-ver):
	$(call SOURCEWGET,"gawk","https://ftp.gnu.org/gnu/"$(gawk-ver))

$(gc-ver):
	$(call SOURCEWGET,"gc","http://www.hboehm.info/gc/gc_source/"$(notdir $(gc-ver)))

$(gcc-ver):
	$(call SOURCEWGET,"gcc","http://ftp.gnu.org/gnu/gcc/"$(basename $(basename $(notdir $(gcc-ver))))"/"$(notdir $(gcc-ver)))

$(gcc-6.3-ver):
	$(call SOURCEWGET,"gcc-6.3","http://www.netgull.com/gcc/releases/"$(basename $(basename $(notdir $(gcc-6.3-ver))))"/"$(notdir $(gcc-6.3-ver)))

$(gcc-7.2-ver):
	$(call SOURCEWGET,"gcc-7.2","http://www.netgull.com/gcc/releases/"$(basename $(basename $(notdir $(gcc-7.2-ver))))"/"$(notdir $(gcc-7.2-ver)))

$(gdb-ver):
	$(call SOURCEWGET,"gdb","https://ftp.gnu.org/gnu/"$(gdb-ver))

$(gdbm-ver):
	$(call SOURCEWGET,"gdbm","ftp://ftp.gnu.org/gnu/"$(gdbm-ver))

$(gettext-ver):
	$(call SOURCEWGET,"gettext","https://ftp.gnu.org/pub/gnu/"$(gettext-ver))

$(git-ver):
	$(call SOURCEWGET,"git","http://www.kernel.org/pub/software/scm/"$(git-ver))

$(glib-ver):
	$(call SOURCEWGET,"glib","http://ftp.gnome.org/pub/gnome/sources/glib/2.46/"$(notdir $(glib-ver)))

$(glibc-ver):
	$(call SOURCEWGET,"glibc","https://ftp.gnu.org/gnu/"$(glibc-ver))

$(global-ver):
	$(call SOURCEWGET,"global","http://tamacom.com/"$(global-ver))

$(gmp-ver):
	$(call SOURCEWGET,"gmp","http://ftp.gnu.org/gnu/"$(gmp-ver))

$(gnupg-ver):
	$(call SOURCEWGET,"gnupg","ftp://ftp.gnupg.org/gcrypt/"$(gnupg-ver))

$(gnuplot-ver):
	$(call SOURCEWGET,"gnuplot","https://downloads.sourceforge.net/gnuplot/5.0.3/"$(notdir $(gnuplot-ver)))

$(gnutls-ver):
	$(call SOURCEWGET,"gnutls","ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/"$(notdir $(gnutls-ver)))

$(go-ver):
	$(call SOURCEWGET,"go","https://storage.googleapis.com/golang/go1.4.2.src.tar.gz")

$(gobject-introspection-ver):
	$(call SOURCEWGET, "gobject-introspection", "http://ftp.gnome.org/pub/gnome/sources/gobject-introspection/1.46/"$(notdir $(gobject-introspection-ver)))

$(gpgme-ver):
	$(call SOURCEWGET,"gpgme","https://www.gnupg.org/ftp/gcrypt/"$(gpgme-ver))

$(grep-ver):
	$(call SOURCEWGET,"grep","https://ftp.gnu.org/gnu/"$(grep-ver))

$(guile-ver):
	$(call SOURCEWGET,"guile","https://ftp.gnu.org/pub/gnu/"$(guile-ver))

$(gzip-ver):
	$(call SOURCEWGET,"gzip","https://ftp.gnu.org/gnu/"$(gzip-ver))

$(harfbuzz-ver):
	$(call SOURCEWGET,"harfbuzz","https://www.freedesktop.org/software/harfbuzz/release/"$(notdir $(harfbuzz-ver)))

$(hashdeep-ver):
	$(call SOURCEWGET,"hashdeep","https://github.com/jessek/hashdeep/archive/v4.4.tar.gz")
	cd hashdeep; mv v4.4.tar.gz hashdeep-4.4.tar.gz

$(HTTP-Daemon-ver):
	$(call SOURCEWGET,"HTTP-Daemon","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(HTTP-Daemon-ver)))

$(HTTP-Cookies-ver):
	$(call SOURCEWGET,"HTTP-Cookies","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(HTTP-Cookies-ver)))

$(HTTP-Date-ver):
	$(call SOURCEWGET,"HTTP-Date","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(HTTP-Date-ver)))

$(HTTP-Message-ver):
	$(call SOURCEWGET,"HTTP-Message","http://search.cpan.org/CPAN/authors/id/O/OA/OALDERS/"$(notdir $(HTTP-Message-ver)))

$(HTTP-Negotiate-ver):
	$(call SOURCEWGET,"HTTP-Negotiate","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(HTTP-Negotiate-ver)))

$(HTML-Parser-ver):
	$(call SOURCEWGET,"HTML-Parser","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(HTML-Parser-ver)))

$(HTML-Tagset-ver):
	$(call SOURCEWGET,"HTML-Tagset","http://search.cpan.org/CPAN/authors/id/P/PE/PETDANCE/"$(notdir $(HTML-Tagset-ver)))

$(htop-ver):
	$(call SOURCEWGET,"htop","http://hisham.hm/htop/releases/1.0.1/htop-1.0.1.tar.gz")

$(httpd-ver):
	$(call SOURCEWGET,"httpd","http://archive.apache.org/dist/"$(httpd-ver))

$(hwloc-ver):
	$(call SOURCEWGET,"hwloc","http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.0.tar.gz")

$(icu-ver):
	$(call SOURCEWGET,"icu","http://download.icu-project.org/files/icu4c/58.2/"$(notdir $(icu-ver)))

$(ImageMagick-ver):
	$(call SOURCEWGET,"ImageMagick","https://www.imagemagick.org/download/releases/"$(notdir $(ImageMagick-ver)))

$(Importer-ver):
	$(call SOURCEWGET,"Importer","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Importer-ver)))

$(IO-HTML-ver):
	$(call SOURCEWGET,"IO-HTML","http://search.cpan.org/CPAN/authors/id/C/CJ/CJM/"$(notdir $(IO-HTML-ver)))

$(inc-latest-ver):
	$(call SOURCEWGET,"inc-latest","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(inc-latest-ver)))

$(inetutils-ver):
	$(call SOURCEWGET,"inetutils","https://ftp.gnu.org/gnu/"$(inetutils-ver))

$(intltool-ver):
	$(call SOURCEWGET,"intltool","https://launchpad.net/intltool/trunk/0.51.0/+download/"$(notdir $(intltool-ver)))

$(iptraf-ng-ver):
	$(call SOURCEWGET,"iptraf-ng","https://fedorahosted.org/releases/i/p/"$(iptraf-ng-ver))

$(iwyu-ver):
	$(call SOURCEWGET,"include-what-you-use","http://include-what-you-use.com/downloads/include-what-you-use-3.4.src.tar.gz")

$(IO-BufferedSelect-ver):
	$(call SOURCEWGET,"IO-BufferedSelect","https://cpan.metacpan.org/authors/id/A/AF/AFN/"$(notdir $(IO-BufferedSelect-ver)))

$(IO-Socket-SSL-ver):
	$(call SOURCEWGET,"IO-Socket-SSL","http://search.cpan.org/CPAN/authors/id/S/SU/SULLR/"$(notdir $(IO-Socket-SSL-ver)))

$(IPC-Run3-ver):
	$(call SOURCEWGET,"IPC-Run3","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(IPC-Run3-ver)))

$(JSON-MaybeXS-ver):
	$(call SOURCEWGET,"JSON-MaybeXS","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(JSON-MaybeXS-ver)))

$(jpeg-ver):
	$(call SOURCEWGET,"jpeg","http://www.ijg.org/files/"$(notdir $(jpeg-ver)))

$(jq-ver):
	$(call SOURCEWGET,"jq","https://github.com/stedolan/jq/releases/download/"$(jq-ver))

$(lame-ver):
	$(call SOURCEWGET,"lame","http://downloads.sourceforge.net/"$(lame-ver))

$(libarchive-ver):
	$(call SOURCEWGET,"libarchive","http://www.libarchive.org/downloads/"$(notdir $(libarchive-ver)))

$(libass-ver):
	$(call SOURCEWGET,"libass","https://github.com/libass/libass/releases/download/"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(libass-ver))))))"/"$(notdir $(libass-ver)))

$(libassuan-ver):
	$(call SOURCEWGET,"libassuan","ftp://ftp.gnupg.org/gcrypt/"$(libassuan-ver))

$(libatomic_ops-ver):
	$(call SOURCEWGET,"libatomic_ops","http://www.ivmaisoft.com/_bin/atomic_ops/libatomic_ops-7.4.2.tar.gz")

$(libcap-ver):
	$(call SOURCEWGET,"libcap","https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/"$(notdir $(libcap-ver)))

$(libdnet-ver):
	$(call SOURCEWGET,"libdnet","https://github.com/dugsong/libdnet/archive/"$(notdir $(libdnet-ver)))

$(libelf-ver):
	$(call SOURCEWGET,"libelf","http://www.mr511.de/software/libelf-0.8.13.tar.gz")

$(libevent-ver):
	$(call SOURCEWGET,"libevent","https://github.com/downloads/libevent/"$(libevent-ver))

$(libffi-ver):
	$(call SOURCEWGET,"libffi","ftp://sourceware.org/pub/"$(libffi-ver))

$(libgcrypt-ver):
	$(call SOURCEWGET,"libgcrypt","https://www.gnupg.org/ftp/gcrypt/"$(libgcrypt-ver))

$(libidn-ver):
	$(call SOURCEWGET,"libidn","http://ftp.gnu.org/gnu/"$(libidn-ver))

$(libksba-ver):
	$(call SOURCEWGET,"libksba","ftp://ftp.gnupg.org/gcrypt/"$(libksba-ver))

$(libiconv-ver):
	$(call SOURCEWGET,"libiconv","http://ftp.gnu.org/gnu/"$(libiconv-ver))

$(libgpg-error-ver):
	$(call SOURCEWGET,"libgpg-error","ftp://ftp.gnupg.org/gcrypt/"$(libgpg-error-ver))

$(libmnl-ver):
	$(call SOURCEWGET,"libmnl","https://netfilter.org/projects/libmnl/files/"$(notdir $(libmnl-ver)))

$(libmpeg2-ver):
	$(call SOURCEWGET,"libmpeg2","http://libmpeg2.sourceforge.net/files/"$(notdir $(libmpeg2-ver)))

$(libnftnl-ver):
	$(call SOURCEWGET,"libnftnl","https://netfilter.org/projects/libnftnl/files/"$(notdir $(libnftnl-ver)))

$(libogg-ver):
	$(call SOURCEWGET,"libogg","http://downloads.xiph.org/releases/ogg/"$(notdir $(libogg-ver)))

$(libpcap-ver):
	$(call SOURCEWGET,"libpcap","http://www.tcpdump.org/release/libpcap-1.4.0.tar.gz")

$(libpng-ver):
	$(call SOURCEWGET,"libpng","http://downloads.sourceforge.net/"$(libpng-ver))

$(libtheora-ver):
	$(call SOURCEWGET,"libtheora","http://downloads.xiph.org/releases/theora/"$(notdir $(libtheora-ver)))

$(libpthread-ver):
	$(call SOURCEWGET,"libpthread","http://git.savannah.gnu.org/cgit/hurd/libpthread.git/snapshot/"$(notdir $(libpthread-ver)))

$(libsecret-ver):
	$(call SOURCEWGET,"libsecret","http://ftp.gnome.org/pub/gnome/sources/libsecret/0.18/"$(notdir $(libsecret-ver)))

$(libsndfile-ver):
	$(call SOURCEWGET,"libsndfile","http://www.mega-nerd.com/libsndfile/files/"$(notdir $(libsndfile-ver)))

$(libtasn1-ver):
	$(call SOURCEWGET,"libtasn1","http://ftp.gnu.org/gnu/"$(libtasn1-ver))

$(libtool-ver):
	$(call SOURCEWGET,"libtool","http://ftpmirror.gnu.org/"$(libtool-ver))

$(libunistring-ver):
	$(call SOURCEWGET,"libunistring","https://ftp.gnu.org/gnu/"$(libunistring-ver))

$(libusb-ver):
	$(call SOURCEWGET,"libusb","http://downloads.sourceforge.net/libusb/libusb-1.0.19.tar.bz2")

$(libuv-ver):
	$(call SOURCEWGET,"libuv","https://github.com/libuv/libuv/archive/v1.15.0.tar.gz")

$(libvorbis-ver):
	$(call SOURCEWGET,"libvorbis","http://downloads.xiph.org/releases/vorbis/"$(notdir $(libvorbis-ver)))

$(libvpx-ver):
	$(call SOURCEWGET,"libvpx","http://storage.googleapis.com/downloads.webmproject.org/releases/webm/"$(notdir $(libvpx-ver)))

$(libwww-perl-ver):
	$(call SOURCEWGET,"libwww-perl","http://search.cpan.org/CPAN/authors/id/O/OA/OALDERS/"$(notdir $(libwww-perl-ver)))

$(libutempter-ver):
	$(call SOURCEWGET,"libutempter","http://slackware.cs.utah.edu/pub/slackware/slackware-current/source/a/utempter/"$(notdir $(libutempter-ver)))

$(libxml2-ver):
	$(call SOURCEWGET,"libxml2","http://xmlsoft.org/sources/"$(notdir $(libxml2-ver)))

$(libxslt-ver):
	$(call SOURCEWGET,"libxslt","http://xmlsoft.org/sources/"$(notdir $(libxslt-ver)))

$(Linux-PAM-ver):
	$(call SOURCEWGET,"Linux-PAM","http://linux-pam.org/library/"$(notdir $(Linux-PAM-ver)))

$(List-MoreUtils-ver):
	$(call SOURCEWGET,"List-MoreUtils","http://search.cpan.org/CPAN/authors/id/R/RE/REHSACK/"$(notdir $(List-MoreUtils-ver)))

$(llvm-ver):
	$(call SOURCEWGET,"llvm","http://llvm.org/releases/3.4/llvm-3.4.src.tar.gz")

$(LMDB-ver):
	$(call SOURCEWGET,"LMDB","https://github.com/LMDB/lmdb/archive/"$(notdir $(LMDB-ver)))

$(Log-Log4perl-ver):
	$(call SOURCEWGET,"Log-Log4perl","http://search.cpan.org/CPAN/authors/id/M/MS/MSCHILLI/"$(notdir $(Log-Log4perl-ver)))

$(lua-ver):
	$(call SOURCEWGET,"lua","http://www.lua.org/ftp/"$(notdir $(lua-ver)))

$(LWP-MediaTypes-ver):
	$(call SOURCEWGET,"LWP-MediaTypes","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(LWP-MediaTypes-ver)))

$(LWP-Protocol-https-ver):
	$(call SOURCEWGET,"LWP-Protocol-https","http://search.cpan.org/CPAN/authors/id/O/OA/OALDERS/"$(notdir $(LWP-Protocol-https-ver)))

$(lxsplit-ver):
	$(call SOURCEWGET,"lxsplit","http://downloads.sourceforge.net/"$(lxsplit-ver))

$(lynis-ver):
	$(call SOURCEWGET,"lynis","https://cisofy.com/files/"$(notdir $(lynis-ver)))

$(make-ver):
	$(call SOURCEWGET,"make","http://ftp.gnu.org/gnu/"$(make-ver))

$(maldetect-ver):
	$(call SOURCEWGET,"maldetect","http://www.rfxn.com/downloads/"$(notdir $(maldetect-ver)))

$(Math-Random-ISAAC-ver):
	$(call SOURCEWGET,"Math-Random-ISAAC","http://search.cpan.org/CPAN/authors/id/J/JA/JAWNSY/"$(notdir $(Math-Random-ISAAC-ver)))

$(Math-Random-Secure-ver):
	$(call SOURCEWGET,"Math-Random-Secure","http://search.cpan.org/CPAN/authors/id/F/FR/FREW/"$(notdir $(Math-Random-Secure-ver)))

# http://jnettop.kubs.info/dist/jnettop-0.13.0.tar.gz
$(jnettop-ver):
	$(call SOURCEWGET,"jnettop","http://downloads.sourceforge.net/project/jnettop/jnettop/0.13/"$(notdir $(jnettop-ver)))

$(lzma-ver):
	$(call SOURCEWGET,"lzma","http://tukaani.org/"$(lzma-ver))

$(lzo-ver):
	$(call SOURCEWGET,"lzo","http://www.oberhumer.com/opensource/lzo/download/"$(notdir $(lzo-ver)))

$(m4-ver):
	$(call SOURCEWGET,"m4","http://ftp.gnu.org/gnu/"$(m4-ver))

$(Math-Pari-ver):
	$(call SOURCEWGET,"Math-Pari","http://search.cpan.org/CPAN/authors/id/I/IL/ILYAZ/modules/"$(notdir $(Math-Pari-ver)))

$(mercurial-ver):
	$(call SOURCEWGET,"mercurial","https://www.mercurial-scm.org/release/"$(notdir $(mercurial-ver)))

$(Module-Build-ver):
	$(call SOURCEWGET,"Module-Build","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(Module-Build-ver)))

$(Module-Build-Tiny-ver):
	$(call SOURCEWGET,"Module-Build-Tiny","http://search.cpan.org/CPAN/authors/id/L/LE/LEONT/"$(notdir $(Module-Build-Tiny-ver)))

$(MoarVM-ver):
	$(call SOURCEWGET,"MoarVM","https://www.moarvm.org/releases/"$(notdir $(MoarVM-ver)))

$(Module-Build-XSUtil-ver):
	$(call SOURCEWGET,"Module-Build-XSUtil","http://search.cpan.org/CPAN/authors/id/H/HI/HIDEAKIO/"$(notdir $(Module-Build-XSUtil-ver)))

$(Module-Find-ver):
	$(call SOURCEWGET,"Module-Find","http://search.cpan.org/CPAN/authors/id/C/CR/CRENZ/"$(notdir $(Module-Find-ver)))

$(Module-Implementation-ver):
	$(call SOURCEWGET,"Module-Implementation","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Module-Implementation-ver)))

$(Module-Install-ver):
	$(call SOURCEWGET,"Module-Install","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Module-Install-ver)))

$(Module-Pluggable-ver):
	$(call SOURCEWGET,"Module-Pluggable","http://search.cpan.org/CPAN/authors/id/S/SI/SIMONW/"$(notdir $(Module-Pluggable-ver)))

$(Module-Runtime-ver):
	$(call SOURCEWGET,"Module-Runtime","http://search.cpan.org/CPAN/authors/id/Z/ZE/ZEFRAM/"$(notdir $(Module-Runtime-ver)))

$(Module-Runtime-Conflicts-ver):
	$(call SOURCEWGET,"Module-Runtime-Conflicts","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Module-Runtime-Conflicts-ver)))

$(Module-ScanDeps-ver):
	$(call SOURCEWGET,"Module-ScanDeps","http://search.cpan.org/CPAN/authors/id/R/RS/RSCHUPP/"$(notdir $(Module-ScanDeps-ver)))

$(Moo-ver):
	$(call SOURCEWGET,"Moo","http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/"$(notdir $(Moo-ver)))

$(Mojolicious-ver):
	$(call SOURCEWGET,"Mojolicious","http://search.cpan.org/CPAN/authors/id/S/SR/SRI/"$(notdir $(Mojolicious-ver)))

$(Moose-ver):
	$(call SOURCEWGET,"Moose","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Moose-ver)))

$(Mouse-ver):
	$(call SOURCEWGET,"Mouse","http://search.cpan.org/CPAN/authors/id/S/SK/SKAJI/"$(notdir $(Mouse-ver)))

$(MouseX-Types-ver):
	$(call SOURCEWGET,"MouseX-Types","http://search.cpan.org/CPAN/authors/id/G/GF/GFUJI/"$(notdir $(MouseX-Types-ver)))

$(mosh-ver):
	$(call SOURCEWGET,"mosh","https://mosh.org/"$(notdir $(mosh-ver)))

$(mpc-ver):
	$(call SOURCEWGET,"mpc","ftp://ftp.gnu.org/gnu/"$(mpc-ver))

$(mpfr-ver):
	$(call SOURCEWGET,"mpfr","http://ftp.gnu.org/gnu/"$(mpfr-ver))

$(MRO-Compat-ver):
	$(call SOURCEWGET,"MRO-Compat","http://search.cpan.org/CPAN/authors/id/B/BO/BOBTFISH/"$(notdir $(MRO-Compat-ver)))

$(multitail-ver):
	$(call SOURCEWGET,"multitail","http://www.vanheusden.com/"$(multitail-ver))

$(musl-ver):
	$(call SOURCEWGET,"musl","https://www.musl-libc.org/releases/"$(notdir $(musl-ver)))

$(mutt-ver):
	$(call SOURCEWGET,"mutt","ftp://ftp.mutt.org/pub/"$(mutt-ver))

$(namespace-autoclean-ver):
	$(call SOURCEWGET,"namespace-autoclean","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(namespace-autoclean-ver)))

$(namespace-clean-ver):
	$(call SOURCEWGET,"namespace-clean","http://search.cpan.org/CPAN/authors/id/R/RI/RIBASUSHI/"$(notdir $(namespace-clean-ver)))

$(nano-ver):
	$(call SOURCEWGET,"nano","https://www.nano-editor.org/dist/v2.6/"$(notdir $(nano-ver)))

$(nasm-ver):
	$(call SOURCEWGET,"nasm","http://www.nasm.us/pub/nasm/releasebuilds/"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(nasm-ver))))))"/"$(notdir $(nasm-ver)))

$(nettle-ver):
	$(call SOURCEWGET,"nettle","https://ftp.gnu.org/gnu/"$(nettle-ver))

$(ncurses-ver):
	$(call SOURCEWGET,"ncurses","http://ftp.gnu.org/gnu/"$(ncurses-ver))

$(Net-HTTP-ver):
	$(call SOURCEWGET,"Net-HTTP","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Net-HTTP-ver)))

$(Net-DNS-ver):
	$(call SOURCEWGET,"Net-DNS","http://search.cpan.org/CPAN/authors/id/N/NL/NLNETLABS/"$(notdir $(Net-DNS-ver)))

$(Net-SSLeay-ver):
	$(call SOURCEWGET,"Net-SSLeay","http://search.cpan.org/CPAN/authors/id/M/MI/MIKEM/"$(notdir $(Net-SSLeay-ver)))

$(netpbm-ver):
	$(call SOURCEWGET,"netpbm","http://downloads.sourceforge.net/project/netpbm/super_stable/10.35.95/netpbm-10.35.95.tgz")

$(nftables-ver):
	$(call SOURCEWGET,"nftables","https://netfilter.org/projects/nftables/files/"$(notdir $(nftables-ver)))

$(node-ver):
	$(call SOURCEWGET,"node","https://nodejs.org/dist/v4.4.2/"$(notdir $(node-ver)))

$(npth-ver):
	$(call SOURCEWGET,"npth","https://gnupg.org/ftp/gcrypt/"$(npth-ver))

$(ntbtls-ver):
	$(call SOURCEWGET,"ntbtls","https://www.gnupg.org/ftp/gcrypt/"$(ntbtls-ver))

$(ntfs-3g-ver):
	$(call SOURCEWGET,"ntfs-3g","http://tuxera.com/opensource/ntfs-3g_ntfsprogs-2013.1.13.tgz")

$(oath-toolkit-ver):
	$(call SOURCEWGET,"oath-toolkit","http://download.savannah.nongnu.org/releases/"$(oath-toolkit-ver))

$(ocaml-ver):
	$(call SOURCEWGET,"ocaml","http://caml.inria.fr/pub/distrib/ocaml-4.05/"$(notdir $(ocaml-ver)))

$(octave-ver):
	$(call SOURCEWGET,"octave","https://ftp.gnu.org/gnu/"$(octave-ver))

$(openssl-ver):
	$(call SOURCEWGET,"openssl","http://www.openssl.org/source/"$(notdir $(openssl-ver)))

$(openvpn-ver):
	$(call SOURCEWGET,"openvpn","https://swupdate.openvpn.org/community/releases/"$(notdir $(openvpn-ver)))

$(opus-ver):
	$(call SOURCEWGET,"opus","http://downloads.xiph.org/releases/"$(opus-ver))

$(p11-kit-ver):
	$(call SOURCEWGET,"p11-kit","https://github.com/p11-glue/p11-kit/releases/download/0.23.10/"$(notdir $(p11-kit-ver)))

$(Package-DeprecationManager-ver):
	$(call SOURCEWGET,"Package-DeprecationManager","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Package-DeprecationManager-ver)))

$(Package-Stash-ver):
	$(call SOURCEWGET,"Package-Stash","http://search.cpan.org/CPAN/authors/id/D/DO/DOY/"$(notdir $(Package-Stash-ver)))

$(Package-Stash-XS-ver):
	$(call SOURCEWGET,"Package-Stash-XS","http://search.cpan.org/CPAN/authors/id/D/DO/DOY/"$(notdir $(Package-Stash-XS-ver)))

$(pango-ver):
	$(call SOURCEWGET,"pango","http://ftp.gnome.org/pub/gnome/sources/pango/1.42/"$(notdir $(pango-ver)))

$(pari-ver):
	$(call SOURCEWGET,"pari","http://pari.math.u-bordeaux.fr/pub/pari/unix/OLD/2.3/"$(notdir $(pari-ver)))

$(PAR-Dist-ver):
	$(call SOURCEWGET,"PAR-Dist","http://search.cpan.org/CPAN/authors/id/R/RS/RSCHUPP/"$(notdir $(PAR-Dist-ver)))

$(Params-ValidationCompiler-ver):
	$(call SOURCEWGET,"Params-ValidationCompiler","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Params-ValidationCompiler-ver)))

$(Params-Util-ver):
	$(call SOURCEWGET,"Params-Util","http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/"$(notdir $(Params-Util-ver)))

$(par2cmdline-ver):
	$(call SOURCEWGET,"par2cmdline","https://github.com/Parchive/par2cmdline/archive/"$(notdir $(par2cmdline-ver)))

$(password-store-ver):
	$(call SOURCEWGET,"password-store","https://git.zx2c4.com/password-store/snapshot/"$(notdir $(password-store-ver)))

$(patch-ver):
	$(call SOURCEWGET,"patch","http://ftp.gnu.org/gnu/"$(patch-ver))

$(Path-Tiny-ver):
	$(call SOURCEWGET,"Path-Tiny","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(Path-Tiny-ver)))

$(PathTools-ver):
	$(call SOURCEWGET,"PathTools","http://search.cpan.org/CPAN/authors/id/X/XS/XSAWYERX/"$(notdir $(PathTools-ver)))

$(pcre-ver):
	$(call SOURCEWGET,"pcre","ftp://ftp.csx.cam.ac.uk/pub/software/programming/"$(pcre-ver))

$(pcre2-ver):
	$(call SOURCEWGET,"pcre2","ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/"$(notdir $(pcre2-ver)))

$(perl-ver):
	$(call SOURCEWGET,"perl","http://www.cpan.org/src/5.0/"$(notdir $(perl-ver)))

$(pinentry-ver):
	$(call SOURCEWGET,"pinentry","ftp://ftp.gnupg.org/gcrypt/"$(pinentry-ver))

$(pixman-ver):
	$(call SOURCEWGET,"pixman","http://cairographics.org/releases/"$(notdir $(pixman-ver)))

$(pkg-config-ver):
	$(call SOURCEWGET,"pkg-config","http://pkgconfig.freedesktop.org/releases/"$(notdir $(pkg-config-ver)))

$(pngnq-ver):
	$(call SOURCEWGET,"pngnq","http://downloads.sourceforge.net/pngnq/1.1/"$(notdir $(pngnq-ver)))

$(Pod-Coverage-ver):
	$(call SOURCEWGET,"Pod-Coverage","http://search.cpan.org/CPAN/authors/id/R/RC/RCLAMP/"$(notdir $(Pod-Coverage-ver)))

# Popt needed for cryptsetup
$(popt-ver):
	$(call SOURCEWGET,"popt","http://rpm5.org/files/popt/popt-1.16.tar.gz")

$(protobuf-ver):
	$(call SOURCEWGET,"protobuf", "https://github.com/google/protobuf/releases/download/v2.6.1/"$(notdir $(protobuf-ver)))

$(psmisc-ver):
	$(call SOURCEWGET, "psmisc", "http://downloads.sourceforge.net/psmisc/psmisc-22.21.tar.gz")

$(pth-ver):
	$(call SOURCEWGET, "pth", "https://ftp.gnu.org/gnu/pth/pth-2.0.7.tar.gz")

$(py2cairo-ver):
	$(call SOURCEWGET, "py2cairo", "http://cairographics.org/releases/"$(notdir $(py2cairo-ver)))

$(Python-ver):
	$(call SOURCEWGET, "Python", "https://www.python.org/ftp/python/"$(word 2,$(subst -, ,$(basename $(basename $(notdir $(Python-ver))))))"/"$(notdir $(Python-ver)))

$(pygobject-ver):
	$(call SOURCEWGET, "pygobject", "http://ftp.gnome.org/pub/gnome/sources/pygobject/2.28/"$(notdir $(pygobject-ver)))

$(p7zip-ver):
	$(call SOURCEWGET,"p7zip","http://downloads.sourceforge.net/project/p7zip/p7zip/16.02/"$(notdir $(p7zip-ver)))

$(qt-everywhere-opensource-src-ver):
	$(call SOURCEWGET,"qt-everywhere-opensource-src","http://download.qt.io/archive/qt/5.5/5.5.1/single/qt-everywhere-opensource-src-5.5.1.tar.xz")

$(random-ver):
	$(call SOURCEWGET,"random","http://www.fourmilab.ch/"$(random-ver))

$(rakudo-star-ver):
	$(call SOURCEWGET,"rakudo-star","http://rakudo.org/downloads/star/"$(notdir $(rakudo-star-ver)))

$(readline-ver):
	$(call SOURCEWGET,"readline","http://ftp.gnu.org/gnu/"$(readline-ver))

$(rng-tools-ver):
	$(call SOURCEWGET,"rng-tools","https://github.com/nhorman/rng-tools/archive/"$(notdir $(rng-tools-ver)))

$(Role-Tiny-ver):
	$(call SOURCEWGET,"Role-Tiny","http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/"$(notdir $(Role-Tiny-ver)))

$(ruby-ver):
	$(call SOURCEWGET,"ruby","http://cache.ruby-lang.org/pub/ruby/2.3/"$(notdir $(ruby-ver)))

$(Scalar-List-Utils-ver):
	$(call SOURCEWGET,"Scalar-List-Utils","http://search.cpan.org/CPAN/authors/id/P/PE/PEVANS/"$(notdir $(Scalar-List-Utils-ver)))

$(Scalar-MoreUtils-ver):
	$(call SOURCEWGET,"Scalar-MoreUtils","http://search.cpan.org/CPAN/authors/id/R/RK/RKRIMEN/"$(notdir $(Scalar-MoreUtils-ver)))

$(scons-ver):
	$(call SOURCEWGET, "scons", "http://prdownloads.sourceforge.net/scons/"$(notdir $(scons-ver)))

$(Scope-Guard-ver):
	$(call SOURCEWGET,"Scope-Guard","http://search.cpan.org/CPAN/authors/id/C/CH/CHOCOLATE/"$(notdir $(Scope-Guard-ver)))

$(screen-ver):
	$(call SOURCEWGET,"screen","https://ftp.gnu.org/gnu/"$(screen-ver))

$(scrypt-ver):
	$(call SOURCEWGET, "scrypt","http://www.tarsnap.com/"$(scrypt-ver))

$(sed-ver):
	$(call SOURCEWGET, "sed", "http://ftp.gnu.org/gnu/"$(sed-ver))

$(serf-ver):
	$(call SOURCEWGET, "serf", "https://archive.apache.org/dist/"$(serf-ver))

# sharutils needed for cryptsetup
$(sharutils-ver):
	$(call SOURCEWGET, "sharutils", "http://ftp.gnu.org/gnu/sharutils/sharutils-4.15.1.tar.xz")

$(six-ver):
	$(call SOURCEWGET, "six", "https://pypi.io/packages/source/s/"$(six-ver))

$(slang-ver):
	$(call SOURCEWGET,"slang","http://www.jedsoft.org/releases/"$(slang-ver))

$(Specio-ver):
	$(call SOURCEWGET,"Specio","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Specio-ver)))

$(Sub-Uplevel-ver):
	$(call SOURCEWGET,"Sub-Uplevel","http://search.cpan.org/CPAN/authors/id/D/DA/DAGOLDEN/"$(notdir $(Sub-Uplevel-ver)))

$(Sub-Exporter-ver):
	$(call SOURCEWGET,"Sub-Exporter","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(Sub-Exporter-ver)))

$(Sub-Exporter-Progressive-ver):
	$(call SOURCEWGET,"Sub-Exporter-Progressive","http://search.cpan.org/CPAN/authors/id/F/FR/FREW/"$(notdir $(Sub-Exporter-Progressive-ver)))

$(Sub-Info-ver):
	$(call SOURCEWGET,"Sub-Info","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Sub-Info-ver)))

$(Sub-Identify-ver):
	$(call SOURCEWGET,"Sub-Identify","http://search.cpan.org/CPAN/authors/id/R/RG/RGARCIA/"$(notdir $(Sub-Identify-ver)))

$(Sub-Install-ver):
	$(call SOURCEWGET,"Sub-Install","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(Sub-Install-ver)))

$(Sub-Name-ver):
	$(call SOURCEWGET,"Sub-Name","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Sub-Name-ver)))

$(subversion-ver):
	$(call SOURCEWGET,"subversion","http://www.us.apache.org/dist/"$(subversion-ver))

$(symlinks-ver):
	$(call SOURCEWGET,"symlinks","http://github.com/brandt/symlinks/archive/"$(notdir $(symlinks-ver)))

$(snort-ver):
	$(call SOURCEWGET, "snort", "https://www.snort.org/downloads/"$(snort-ver))

$(socat-ver):
	$(call SOURCEWGET, "socat", "http://www.dest-unreach.org/socat/download/"$(notdir $(socat-ver)))

$(sparse-ver):
	$(call SOURCEWGET,"sparse","http://www.kernel.org/pub/software/devel/sparse/dist/sparse-0.5.0.tar.gz")

$(sqlite-ver):
	$(call SOURCEWGET,"sqlite","http://sqlite.org/2017/"$(notdir $(sqlite-ver)))

$(srm-ver):
	$(call SOURCEWGET,"srm","http://sourceforge.net/projects/srm/files/1.2.15/"$(notdir $(srm-ver)))

$(swig-ver):
	# (call SOURCEWGET,"swig","http://prdownloads.sourceforge.net/swig/swig-3.0.0.tar.gz")
	$(call SOURCEWGET,"swig","http://prdownloads.sourceforge.net/"$(swig-ver))

$(tar-ver):
	$(call SOURCEWGET,"tar","https://ftp.gnu.org/gnu/"$(tar-ver))

$(tcc-ver):
	$(call SOURCEWGET,"tcc","http://download.savannah.gnu.org/releases/tinycc/"$(notdir $(tcc-ver)))

# http://www.tcl.tk/software/tcltk/download.html
$(tcl-ver):
	$(call SOURCEWGET,"tcl","http://prdownloads.sourceforge.net/"$(tcl-ver))

$(tclx-ver):
	$(call SOURCEWGET,"tclx","http://prdownloads.sourceforge.net/"$(tclx-ver))

$(tcp_wrappers-ver):
	$(call SOURCEWGET,"tcp_wrappers","ftp://ftp.porcupine.org/pub/security/tcp_wrappers_7.6.tar.gz")

$(tcp_wrappers-patch-ver):
	$(call PATCHWGET,"http://www.linuxfromscratch.org/patches/blfs/6.3/tcp_wrappers-7.6-shared_lib_plus_plus-1.patch")

$(tcpdump-ver):
	$(call SOURCEWGET,"tcpdump","http://www.tcpdump.org/release/tcpdump-4.5.1.tar.gz")

$(Term-Table-ver):
	$(call SOURCEWGET,"Term-Table","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Term-Table-ver)))

$(tenshi-ver):
	$(call SOURCEWGET,"tenshi","https://github.com/inversepath/tenshi/archive/0.17.tar.gz")

$(Test-Exception-ver):
	$(call SOURCEWGET,"Test-Exception","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Test-Exception-ver)))

$(Test-CleanNamespaces-ver):
	$(call SOURCEWGET,"Test-CleanNamespaces","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Test-CleanNamespaces-ver)))

$(Test-Deep-ver):
	$(call SOURCEWGET,"Test-Deep","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(Test-Deep-ver)))

$(Test-Differences-ver):
	$(call SOURCEWGET,"Test-Differences","http://search.cpan.org/CPAN/authors/id/D/DC/DCANTRELL/"$(notdir $(Test-Differences-ver)))

$(Test-Fatal-ver):
	$(call SOURCEWGET,"Test-Fatal","http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/"$(notdir $(Test-Fatal-ver)))

$(Test-File-ver):
	$(call SOURCEWGET,"Test-File","http://search.cpan.org/CPAN/authors/id/B/BD/BDFOY/"$(notdir $(Test-File-ver)))

$(Test-File-ShareDir-ver):
	$(call SOURCEWGET,"Test-File-ShareDir","http://search.cpan.org/CPAN/authors/id/K/KE/KENTNL/"$(notdir $(Test-File-ShareDir-ver)))

$(Test-Inter-ver):
	$(call SOURCEWGET,"Test-Inter","http://search.cpan.org/CPAN/authors/id/S/SB/SBECK/"$(notdir $(Test-Inter-ver)))

$(Test-LeakTrace-ver):
	$(call SOURCEWGET,"Test-LeakTrace","http://search.cpan.org/CPAN/authors/id/G/GF/GFUJI/"$(notdir $(Test-LeakTrace-ver)))

$(Test-Needs-ver):
	$(call SOURCEWGET,"Test-Needs","http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/"$(notdir $(Test-Needs-ver)))

$(Test-NoWarnings-ver):
	$(call SOURCEWGET,"Test-NoWarnings","http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/"$(notdir $(Test-NoWarnings-ver)))

$(Test-Warn-ver):
	$(call SOURCEWGET,"Test-Warn","http://search.cpan.org/CPAN/authors/id/C/CH/CHORNY/"$(notdir $(Test-Warn-ver)))

$(Test-Pod-ver):
	$(call SOURCEWGET,"Test-Pod","http://search.cpan.org/CPAN/authors/id/D/DW/DWHEELER/"$(notdir $(Test-Pod-ver)))

$(Test-Pod-Coverage-ver):
	$(call SOURCEWGET,"Test-Pod-Coverage","http://search.cpan.org/CPAN/authors/id/N/NE/NEILB/"$(notdir $(Test-Pod-Coverage-ver)))

$(Test-Requires-ver):
	$(call SOURCEWGET,"Test-Requires","http://search.cpan.org/CPAN/authors/id/T/TO/TOKUHIROM/"$(notdir $(Test-Requires-ver)))

$(Test-RequiresInternet-ver):
	$(call SOURCEWGET,"Test-RequiresInternet","http://search.cpan.org/CPAN/authors/id/M/MA/MALLEN/"$(notdir $(Test-RequiresInternet-ver)))

$(Test-Simple-ver):
	$(call SOURCEWGET,"Test-Simple","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Test-Simple-ver)))

$(Test-SharedFork-ver):
	$(call SOURCEWGET,"Test-SharedFork","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Test-SharedFork-ver)))

$(Test-utf8-ver):
	$(call SOURCEWGET,"Test-utf8","http://search.cpan.org/CPAN/authors/id/M/MA/MARKF/"$(notdir $(Test-utf8-ver)))

$(Test-Warnings-ver):
	$(call SOURCEWGET,"Test-Warnings","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Test-Warnings-ver)))

$(Test-Without-Module-ver):
	$(call SOURCEWGET,"Test-Without-Module","http://search.cpan.org/CPAN/authors/id/C/CO/CORION/"$(notdir $(Test-Without-Module-ver)))

$(Test2-Plugin-NoWarnings-ver):
	$(call SOURCEWGET,"Test2-Plugin-NoWarnings","http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/"$(notdir $(Test2-Plugin-NoWarnings-ver)))

$(Test2-Suite-ver):
	$(call SOURCEWGET,"Test2-Suite","http://search.cpan.org/CPAN/authors/id/E/EX/EXODIST/"$(notdir $(Test2-Suite-ver)))

$(Text-Diff-ver):
	$(call SOURCEWGET,"Text-Diff","http://search.cpan.org/CPAN/authors/id/N/NE/NEILB/"$(notdir $(Text-Diff-ver)))

$(texinfo-ver):
	$(call SOURCEWGET,"texinfo","https://ftp.gnu.org/gnu/texinfo/"$(notdir $(texinfo-ver)))

$(tmux-ver):
	$(call SOURCEWGET,"tmux","https://github.com/tmux/tmux/releases/download/2.2/"$(notdir $(tmux-ver)))

$(truecrypt-ver):
	$(call SOURCEWGET,"truecrypt","https://www.grc.com/misc/"$(truecrypt-ver))

$(Try-Tiny-ver):
	$(call SOURCEWGET,"Try-Tiny","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(Try-Tiny-ver)))

$(Type-Tiny-ver):
	$(call SOURCEWGET,"Type-Tiny","http://search.cpan.org/CPAN/authors/id/T/TO/TOBYINK/"$(notdir $(Type-Tiny-ver)))

$(ufw-ver):
	$(call SOURCEWGET,"ufw","https://launchpad.net/ufw/0.35/0.35/+download/"$(notdir $(ufw-ver)))

$(util-linux-ver):
	$(call SOURCEWGET,"util-linux-ng","https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.18/"$(not      dir $(util-linux-ng-ver)))

$(util-linux-ng-ver):
	$(call SOURCEWGET,"util-linux-ng","ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.18/util-linux-ng-2.18.tar.xz")

$(unrar-ver):
	$(call SOURCEWGET,"unrar","http://www.rarlab.com/rar/"$(notdir $(unrar-ver)))

$(unzip-ver):
	$(call SOURCEWGET,"unzip","ftp://ftp.info-zip.org/pub/infozip/src/"$(notdir $(unzip-ver)))

$(URI-ver):
	$(call SOURCEWGET,"URI","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(URI-ver)))

$(vala-ver):
	$(call SOURCEWGET,"vala","http://ftp.gnome.org/pub/gnome/sources/vala/0.34/"$(notdir $(vala-ver)))

$(valgrind-ver):
	$(call SOURCEWGET,"valgrind","http://sourceware.org/ftp/valgrind/"$(notdir $(valgrind-ver)))

$(Variable-Magic-ver):
	$(call SOURCEWGET,"Variable-Magic","http://search.cpan.org/CPAN/authors/id/V/VP/VPIT/"$(notdir $(Variable-Magic-ver)))

$(vera++-ver):
	$(call SOURCEWGET,"vera++","https://bitbucket.org/verateam/vera/downloads/"$(notdir $(vera++-ver)))

$(vim-ver):
	# (call SOURCEWGET,"vim","ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2")
	$(call SOURCEWGET,"vim","https://github.com/vim/vim/archive/"$(notdir $(vim-ver)))

$(wget-ver):
	$(call SOURCEWGET,"wget","http://ftp.gnu.org/gnu/"$(wget-ver))

$(which-ver):
	$(call SOURCEWGET,"which","https://ftp.gnu.org/pub/gnu/"$(which-ver))

$(whois-ver):
	$(call SOURCEWGET,"whois","http://ftp.debian.org/debian/pool/main/w/"$(whois-ver))

$(wipe-ver):
	$(call SOURCEWGET,"wipe","http://sourceforge.net/projects/wipe/files/wipe/2.3.1/wipe-2.3.1.tar.bz2")

$(WWW-RobotRules-ver):
	$(call SOURCEWGET,"WWW-RobotRules","http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/"$(notdir $(WWW-RobotRules-ver)))

$(xmlsec1-ver):
	$(call SOURCEWGET,"xmlsec1","http://www.aleksey.com/xmlsec/download/"$(notdir $(xmlsec1-ver)))

$(x264-ver):
	$(call SOURCEWGET,"x264","http://download.videolan.org/pub/videolan/x264/snapshots/"$(notdir $(x264-ver)))

$(x265-ver):
	$(call SOURCEWGET,"x265","https://bitbucket.org/multicoreware/x265/downloads/"$(notdir $(x265-ver)))

$(XML-Parser-ver):
	$(call SOURCEWGET,"XML-Parser","http://search.cpan.org/CPAN/authors/id/T/TO/TODDR/"$(notdir $(XML-Parser-ver)))

$(YAML-Tiny-ver):
	$(call SOURCEWGET,"YAML-Tiny","http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/"$(notdir $(YAML-Tiny-ver)))

$(yasm-ver):
	$(call SOURCEWGET,"yasm","http://www.tortall.net/projects/yasm/releases/"$(notdir $(yasm-ver)))

$(xz-ver):
	$(call SOURCEWGET,"xz","http://tukaani.org/"$(xz-ver))

$(zip-ver):
	$(call SOURCEWGET,"zip","ftp://ftp.info-zip.org/pub/infozip/src/"$(notdir $(zip-ver)))

$(zlib-ver):
	$(call SOURCEWGET,"zlib","https://www.zlib.net/"$(notdir $(zlib-ver)))

