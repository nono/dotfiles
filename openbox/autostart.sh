# Run the system-wide support stuff
. $GLOBALAUTOSTART

# Make GTK apps look and behave how they were set up in the gnome config tools
gnome-settings-daemon &
# nm-applet --sm-disable &
xscreensaver -no-splash &> /dev/null &
xset -b
numlockx on
# xmodmap ~/config/xmodmaprc
# xmodmap -e "pointer = 1 2 3 6 7 4 5"
Esetroot -f ~/Documents/Wallpapers/vladstudio_frog_1600x1200.jpg &
# ~/.scripts/dlbg.sh commons
# ~/.scripts/random_wallpaper.rb
~/.scripts/setlayout 0 2 2 0

# Programs to launch at startup
firefox &
thunderbird &
liferea &
gajim &
exaile &
urxvt -name irssi -title irssi -e irssi &
urxvt -name gruik -title gruik &
urxvt -name codaz -title codaz &

# Programs that will run after Openbox has started
(sleep 2 && fbpanel) &

