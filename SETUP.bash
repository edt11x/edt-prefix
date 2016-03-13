# glibc warns that you should not include the current directory in LD_LIBRARY_PATH when
# building glibc
ulimit -s 16384
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/lib:/usr/lib:/usr/local/glibc/lib:/lib/x86_64-linux-gnu"
export PATH=$PATH:/usr/local/bin:/usr/local/qt5/bin
if [ -n "$STY" ]; then export PS1="$PS1"; export TERM=screen; fi
if [ -n "$TMUX" ]; then export PS1="(tmux) $PS1"; fi
