#! /bin/sh
# usage: dlbg.sh [default|commons|enwiki|dewiki-bdk] [scale|tile|center|seamless]
 
POTD="$HOME/Documents/Wallpapers/potd-1600x1200.jpg"
DEFAULT="$HOME/Documents/Wallpapers/aloof-1600x1200.jpg"
wiki="${1:-default}"
type="${2:-scale}"
 
 
if [ "$wiki" = "default" ] ; then
    Esetroot -$type "$DEFAULT" &
else
    [ -f "$POTD" ] && rm -f "$POTD"
    echo "http://tools.wikimedia.de/~daniel/potd/potd.php/$wiki/1600x1200" -O "$POTD"
    wget "http://tools.wikimedia.de/~daniel/potd/potd.php/$wiki/1600x1200" -O "$POTD"
    Esetroot -$type "$POTD" &
fi
