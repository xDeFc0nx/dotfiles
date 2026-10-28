#!/usr/bin/env bash
# Play an adhan reminder at full volume while every other audio stream is silenced,
# then restore exactly the streams that were unmuted before playback.
set -uo pipefail

audio="${1:?usage: play-adhan.sh <audio-file>}"
[ -r "$audio" ] || { printf 'play-adhan: cannot read %s\n' "$audio" >&2; exit 1; }

declare -A before=()
restore=()
while IFS=$'\t' read -r id mute; do
    [ -z "$id" ] && continue
    before["$id"]=1
    [ "$mute" = "false" ] && restore+=("$id")
done < <(pactl -f json list sink-inputs 2>/dev/null | jq -r '.[] | "\(.index)\t\(.mute)"')

cleanup() {
    for id in "${restore[@]:-}"; do
        [ -n "$id" ] && pactl set-sink-input-mute "$id" 0 2>/dev/null
    done
}
trap cleanup EXIT INT TERM

for id in "${restore[@]:-}"; do
    [ -n "$id" ] && pactl set-sink-input-mute "$id" 1 2>/dev/null
done

# keep-open=yes in the user's mpv.conf parks the player forever after playback, and a
# player that never releases the sink would leave every other stream muted.
pkill -f "mpv --no-video .*/quickshell/.*/assets/audio/" 2>/dev/null
timeout --signal=TERM 120 mpv --no-config --idle=no --keep-open=no --no-terminal \
    --no-video --really-quiet --volume=100 "$audio" &
player=$!

# WirePlumber restores remembered per-app mute state onto new streams, and mpv forces
# its own application.name, so the reminder is identified by "not in the snapshot" and
# force-unmuted — otherwise it plays silently.
for _ in $(seq 1 20); do
    while IFS= read -r id; do
        [ -z "$id" ] && continue
        if [ -z "${before[$id]:-}" ]; then
            pactl set-sink-input-mute "$id" 0 2>/dev/null
            owned=1
        fi
    done < <(pactl -f json list sink-inputs 2>/dev/null | jq -r '.[] | .index')
    [ "${owned:-}" = "1" ] && break
    sleep 0.2
done

wait "$player" 2>/dev/null
exit 0
