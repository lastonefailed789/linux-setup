#!/usr/bin/env bash
# niri-display-cycle.sh
# Cycles: Extended -> Primary only -> Secondary only -> Extended -> ...
set -euo pipefail
PRIMARY="eDP-1"
SECONDARY="HDMI-A-1"

# --- Connection check via the kernel DRM subsystem directly ---
# niri's own `outputs` list can lag behind reality on disconnect
# (known compositor behavior — connect events are always caught via
# hotplug + EDID read, but disconnect isn't always picked up promptly).
# Reading /sys/class/drm/*-$SECONDARY/status is authoritative and instant.
secondary_status="disconnected"
for f in /sys/class/drm/card*-"$SECONDARY"/status; do
    [[ -f "$f" ]] || continue
    secondary_status=$(cat "$f")
    break
done

if [[ "$secondary_status" != "connected" ]]; then
    # No second monitor physically present — force primary on and stop,
    # regardless of what niri's cached output list says.
    niri msg output "$PRIMARY" on
    MODE="Primary screen only (secondary not connected)"
    if command -v notify-send &> /dev/null; then
        notify-send "Display Mode" "$MODE"
    fi
    echo "$MODE"
    exit 0
fi

OUTPUTS_JSON=$(niri msg --json outputs)
primary_on=$(echo "$OUTPUTS_JSON" | jq -r --arg p "$PRIMARY" '.[$p].logical != null')
secondary_on=$(echo "$OUTPUTS_JSON" | jq -r --arg s "$SECONDARY" '.[$s].logical != null')

if [[ "$primary_on" == "true" && "$secondary_on" == "true" ]]; then
    niri msg output "$PRIMARY" on
    niri msg output "$SECONDARY" off
    MODE="Primary screen only"
elif [[ "$primary_on" == "true" && "$secondary_on" == "false" ]]; then
    niri msg output "$SECONDARY" on
    niri msg output "$PRIMARY" off
    MODE="Secondary screen only"
else
    niri msg output "$PRIMARY" on
    niri msg output "$SECONDARY" on
    MODE="Extended (both screens)"
fi

if command -v notify-send &> /dev/null; then
    notify-send "Display Mode" "$MODE"
fi
echo "$MODE"
