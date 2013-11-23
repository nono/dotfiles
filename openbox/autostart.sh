# Run the system-wide support stuff
. $GLOBALAUTOSTART

# nm-applet --sm-disable &
xset -b
numlockx on
Esetroot -scale ~/Documents/Wallpapers/vladstudio_frog_1600x1200.jpg
setlayout 0 2 2 0
xmodmap ~/.xmodmaprc

# Programs to launch at startup
x-www-browser &
thunderbird &
urxvt -name irssi -title irssi -e irssi &
urxvt -name gruik -title gruik &
urxvt -name codaz -title codaz &

# Programs that will run after Openbox has started
(sleep 3 && fbpanel) &
