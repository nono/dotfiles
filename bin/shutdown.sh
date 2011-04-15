#!/bin/bash

gmessage "Are you sure you want to shut down your computer?" -center -title "Take action" -font "Sans bold 10" -default "Cancel" -buttons "_Cancel":1,"_Log out":2,"_Reboot":3,"_Shut down":4 >/dev/null 

case $? in
	1)
		echo "Exit";;
	2)
		killall openbox;;
	3)
		sudo shutdown -r now;;
	4)
		sudo shutdown -h now;;
esac
