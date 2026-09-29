#!/bin/sh
# Second press stops the recording
if pkill -INT wf-recorder; then
    notify-send "Recording saved"
    exit
fi

mkdir -p "$HOME/Videos"
region=$(slurp) || exit          # Esc cancels
wf-recorder -g "$region" -f "$HOME/Videos/rec-$(date +%F_%H-%M-%S).mp4"