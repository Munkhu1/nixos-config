#!/usr/bin/env bash

echo "$(date): matugen called with $@" >> /tmp/matugen-wrapper.log

ARGS=("$@")
IMAGE=""

while [[ $# -gt 0 ]]; do
    if [[ "$1" == "image" ]]; then
        IMAGE=$(realpath "$2")
        break
    fi
    shift
done

if [[ -z "$IMAGE" ]]; then
    SESSION_FILE="$HOME/.local/state/DankMaterialShell/session.json"
    if [[ -f "$SESSION_FILE" ]]; then
        IMAGE=$(jq -r '.wallpaperPath' "$SESSION_FILE" 2>/dev/null)
        echo "Extracted image path from DMS session: $IMAGE" >> /tmp/matugen-wrapper.log
    fi
fi

if [[ -n "$IMAGE" && -f "$IMAGE" ]]; then
    echo "Applying image path to Pandora: $IMAGE" >> /tmp/matugen-wrapper.log

    sed -i -E 's|image "[^"]+"|image "'"$IMAGE"'"|' "$HOME/.config/pandora/pandora.kdl"

    ACTIVE_OUTPUT=$(niri msg outputs 2>/dev/null | grep -oE '\b(eDP|DP|HDMI-[A-Z]|Virtual|WL|VGA|DVI-[A-Z]|LVDS)-[0-9]+\b' | head -n 1)
    if [[ -n "$ACTIVE_OUTPUT" ]]; then
        sed -i -E 's|output "[^"]+"|output "'"$ACTIVE_OUTPUT"'"|' "$HOME/.config/pandora/pandora.kdl"
    fi

    pandora stop-daemon 2>/dev/null
    sleep 0.05
    rm -f /tmp/pandora*.sock /run/user/$(id -u)/pandora*.sock 2>/dev/null
    pandora > /tmp/pandora-crash.log 2>&1 & disown
fi

exec /etc/profiles/per-user/niri-dank/bin/matugen "${ARGS[@]}"
