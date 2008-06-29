# autologin tty2
[ -z "$DISPLAY" ] && [ $(tty) = /dev/tty2 ] && startx
