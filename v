#!/bin/bash
cmd=$1
if [ -z "$cmd" ]; then
    exit
fi
case $cmd in
    "status" )
        state=`osascript -e "tell application \"iTunes\" to player state as string"`
        if [ "$status" != "stopped" ]; then
            artist=`osascript -e 'tell application "iTunes" to artist of current track as string'`
            track=`osascript -e 'tell application "iTunes" to name of current track as string'`
        fi
        echo "$state -- $artist -- $track"
        ;;
    "pause" | "play" | "prev" | "next" | "stop" | "quit" )
        osascript -e "tell application \"iTunes\" to $cmd"
        ;;
    * )
        osascript -e "set volume $cmd"
        ;;
esac
