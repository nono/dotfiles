# Run the system-wide support stuff
. $GLOBALAUTOSTART

# nm-applet --sm-disable &
xset -b
numlockx on
xmodmap ~/.xmodmaprc
xrdb -load ~/.Xdefaults
Esetroot -scale ~/Documents/Wallpapers/vladstudio_frog_1600x1200.jpg
setlayout 0 2 2 0

# Programs to launch at startup
sleep 2
x-www-browser &
thunderbird &
urxvt -name irssi -title irssi &
urxvt -name gruik -title gruik &
urxvt -name codaz -title codaz &
urxvt -name codaz -title codaz &
urxvt -name codaz -title codaz &
urxvt -name nvim  -title nvim  &

# Programs that will run after Openbox has started
(sleep 1 && fbpanel) &
