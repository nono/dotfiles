# Run the system-wide support stuff
. $GLOBALAUTOSTART

# nm-applet --sm-disable &
xset -b
numlockx on
xmodmap ~/.xmodmaprc
xrdb -load ~/.Xdefaults
Esetroot -scale ~/Documents/Wallpapers/some_light_reading.jpg
setlayout 0 2 2 0

# Programs to launch at startup
sleep 2
x-www-browser &
thunderbird &
tilix --maximize -t gruik -s gruik -w Desktop &
tilix --maximize -t codaz -s codaz -w ~stack &
docker start cozy-stack-couch &

# Programs that will run after Openbox has started
(sleep 1 && fbpanel) &
