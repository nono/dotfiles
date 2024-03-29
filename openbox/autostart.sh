# Run the system-wide support stuff
. $GLOBALAUTOSTART

# nm-applet --sm-disable &
xset -b
numlockx on
xmodmap ~/.xmodmaprc
xrdb -load ~/.Xdefaults
Esetroot -scale ~/Documents/Wallpapers/Nord-wallpaper.png
setlayout 0 2 2 0

# Programs to launch at startup
sleep 2
firefox &

urxvt -name irssi  -title irssi  &
urxvt -name config -title config &
urxvt -name gruik  -title gruik  &
urxvt -name full   -title full   &

urxvt -name codaz1 -title codaz1 &
urxvt -name codaz2 -title codaz2 &
urxvt -name codaz3 -title codaz3 &
urxvt -name nvim   -title nvim   &

docker start cozy-stack-couch &
MailHog &

# Programs that will run after Openbox has started
(sleep 1 && fbpanel) &
