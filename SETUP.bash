# glibc warns that you should not include the current directory in LD_LIBRARY_PATH when
# building glibc
ulimit -s 16384
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib"