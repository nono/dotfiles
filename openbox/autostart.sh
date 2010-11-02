# Run the system-wide support stuff
. $GLOBALAUTOSTART

# Make GTK apps look and behave how they were set up in the gnome config tools
# gnome-settings-daemon &
# nm-applet --sm-disable &
xset -b
numlockx on
# alsactl restore
# xmodmap ~/config/xmodmaprc
# xmodmap -e "pointer = 1 2 3 6 7 4 5"
Esetroot -f ~/Documents/Wallpapers/vladstudio_frog_1600x1200.jpg
~/.scripts/setlayout 0 2 2 0

# Programs to launch at startup
gtk-redshift -l 48.8:2.3 -t 6500:5700 &
firefox-4.0 &
thunderbird &
liferea &
#gajim &
#gwibber-service &
urxvt -name irssi -title irssi -e irssi &
urxvt -name gruik -title gruik &
urxvt -name codaz -title codaz &

# Programs that will run after Openbox has started
(sleep 3 && fbpanel) &
