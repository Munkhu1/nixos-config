#!/usr/bin/env bash

echo "$(date): matugen called with $@" >> /tmp/matugen-wrapper.log

ARGS=("$@")
IMAGE=""

# 1. First, check if "image <path>" is in the arguments (for manual terminal use)
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "image" ]]; then
        IMAGE=$(realpath "$2")
        break
    fi
    shift
done

# 2. If no image was passed in arguments (like when using the DMS picker), ask swww!
if [[ -z "$IMAGE" ]] && command -v swww &>/dev/null; then
    # swww query outputs something like: "Output DP-1: image: /home/user/...jpg"
    IMAGE=$(swww query 2>/dev/null | awk -F 'image: ' '{print $2}' | head -n 1)
    echo "Extracted image path from swww: $IMAGE" >> /tmp/matugen-wrapper.log
fi

if [[ -n "$IMAGE" ]]; then
    echo "Applying image path to Pandora: $IMAGE" >> /tmp/matugen-wrapper.log

    # Update Image Path
    sed -i -E 's|image "[^"]+"|image "'"$IMAGE"'"|' ~/.config/pandora/pandora.kdl

    # Ensure Monitor Output is correct
    ACTIVE_OUTPUT=$(niri msg outputs 2>/dev/null | grep -oE '\b(eDP|DP|HDMI-[A-Z]|Virtual|WL|VGA|DVI-[A-Z]|LVDS)-[0-9]+\b' | head -n 1)
    if [[ -n "$ACTIVE_OUTPUT" ]]; then
        sed -i -E 's|output "[^"]+"|output "'"$ACTIVE_OUTPUT"'"|' ~/.config/pandora/pandora.kdl
    fi

    # Restart Pandora smoothly
    pandora stop-daemon 2>/dev/null
    sleep 0.05
    rm -f /tmp/pandora*.sock /run/user/$(id -u)/pandora*.sock 2>/dev/null
    pandora > /tmp/pandora-crash.log 2>&1 & disown

    # Hide swww so it doesn't render over Pandora
    swww kill 2>/dev/null
fi

# Finally, let Matugen do its normal color generation
exec /etc/profiles/per-user/niri-dank/bin/matugen "${ARGS[@]}"
