#!/bin/sh
# Usage: ./capture.sh <output.png> <fg-hex> <bg-hex> <appearance> [history]
# Example: ./capture.sh window-dark-1.png fbbf24 e74661 dark hide
#
# Set PIKA_APP to target a specific Pika.app rather than the system default:
#   PIKA_APP="/path/to/Pika.app" ./capture.sh ...
#
# Pika must be running (generate.ts launches it automatically when PIKA_APP is set).

OUTPUT="$1"
FG="$2"
BG="$3"
APPEARANCE="$4"
HISTORY="${5:-hide}"

# Send a pika:// URL — via a specific app if PIKA_APP is set, otherwise system default
pika_open() {
    if [ -n "$PIKA_APP" ]; then
        open -a "$PIKA_APP" "$1"
    else
        open "$1"
    fi
}

# Configure Pika state via URL triggers
pika_open "pika://appearance/$APPEARANCE"
sleep 0.3
pika_open "pika://set/foreground/$FG"
sleep 0.3
pika_open "pika://set/background/$BG"
sleep 0.3
pika_open "pika://history/$HISTORY"
sleep 0.3
pika_open "pika://window/resize/480/300"
sleep 0.5

# Look up the Pika window ID
WINDOW_ID=$(swift - <<'EOF'
import Quartz
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list {
    if (w["kCGWindowOwnerName"] as? String) == "Pika",
       let layer = w["kCGWindowLayer"] as? Int, layer == 3 {
        print(w["kCGWindowNumber"] as? Int ?? 0)
        break
    }
}
EOF
)

if [ -z "$WINDOW_ID" ]; then
    echo "Error: Pika window not found. Is Pika running?" >&2
    exit 1
fi

screencapture -l "$WINDOW_ID" "$OUTPUT"
echo "Captured → $OUTPUT"
