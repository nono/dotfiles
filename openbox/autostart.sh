# Run the system-wide support stuff
. $GLOBALAUTOSTART

# nm-applet --sm-disable &
xset -b
numlockx on
Esetroot -scale /usr/share/xfce4/backdrops/xubuntu-wallpaper.png
setlayout 0 2 2 0
xmodmap ~/.xmodmaprc
xrdb -load ~/.Xdefaults

# Programs to launch at startup
sleep 4
x-www-browser &
thunderbird &
urxvt -name irssi -title irssi -e irssi &
urxvt -name gruik -title gruik &
urxvt -name codaz -title codaz &

# Programs that will run after Openbox has started
(sleep 1 && fbpanel) &
