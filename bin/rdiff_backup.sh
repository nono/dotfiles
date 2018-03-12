#!/bin/bash

SSH_AGENT_PID=`pgrep -U $USER ssh-agent`
for PID in $SSH_AGENT_PID; do
    FILE=`find /tmp -path "*ssh*" -type s -iname "agent.*" 2> /dev/null`
    export SSH_AGENT_PID="$PID" 
    export SSH_AUTH_SOCK="$FILE"
done

SRC=/home/nono
DST=backup::Backup/
LOG=/home/nono/save/log/$(date +%F).log

rdiff-backup \
	--verbosity 4 \
	--exclude "**/node_modules" \
	--exclude $SRC/cc \
	--exclude $SRC/dev \
	--exclude $SRC/Desktop \
	--exclude $SRC/Documents/af83 \
	--exclude $SRC/Documents/Audio \
	--exclude $SRC/Documents/Cozy \
	--exclude $SRC/Documents/Calibre \
	--exclude $SRC/Documents/Ebooks \
	--exclude $SRC/go \
	--exclude $SRC/lib \
	--exclude $SRC/save \
	--exclude $SRC/share \
	--exclude $SRC/tmp \
	--exclude $SRC/.adobe \
	--exclude $SRC/.bundle \
	--exclude $SRC/.cache \
	--exclude $SRC/.config/chromium \
	--exclude $SRC/.config/google-chrome \
	--exclude $SRC/.config/libreoffice \
	--exclude $SRC/.config/Popcorn-Time \
	--exclude $SRC/.config/spotify \
	--exclude $SRC/.config/yarn \
	--exclude $SRC/.cozy-stack-couch \
	--exclude $SRC/.davfs2 \
	--exclude $SRC/.docker \
	--exclude $SRC/.electron \
	--exclude $SRC/.electron-gyp \
	--exclude $SRC/.elm \
	--exclude $SRC/.gem \
	--exclude $SRC/.gnome2 \
	--exclude $SRC/.kde \
	--exclude $SRC/.local \
	--exclude $SRC/.macromedia \
	--exclude $SRC/.mozilla/firefox/5zq21lfg.default/Cache \
	--exclude $SRC/.node-gyp \
	--exclude $SRC/.npm \
	--exclude $SRC/.nv \
	--exclude $SRC/.nvm \
	--exclude $SRC/.Popcorn-Time \
	--exclude $SRC/.thumbnails \
	--exclude $SRC/.thunderbird \
	--exclude $SRC/.Xauthority \
	--exclude $SRC/.xsession-errors \
	--exclude $SRC/.xsession-errors.old \
	--exclude $SRC/.zoom \
	--print-statistics \
	$SRC $DST >> $LOG 2>&1

rdiff-backup --force --remove-older-than 3M $DST >> $LOG 2>&1
