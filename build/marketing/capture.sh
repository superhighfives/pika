#!/bin/sh
# Usage: ./capture.sh <output.png> <fg-hex> <bg-hex> <appearance> [history] [window]
# Example: ./capture.sh window-dark-1.png fbbf24 e74661 dark hide main
#          ./capture.sh window-about.png 0a31bc 432f9b light hide about
#
# Set PIKA_APP to target a specific Pika.app rather than the system default:
#   PIKA_APP="/path/to/Pika.app" ./capture.sh ...
#
# Pika must be running (generate.ts launches it automatically when PIKA_APP is set).
#
# Windows:
#   main        — the primary Pika colour picker window (default)
#   about       — the About window (pika://window/about)
#   help        — the Help window (pika://window/help)
#   preferences — the Preferences window (pika://window/preferences)
#   splash      — the first-run/splash window (pika://window/splash)
#
# Secondary windows are detected by z-order: the URL trigger calls makeKeyAndOrderFront,
# so the target window is always the frontmost Pika window above the main window level.

OUTPUT="$1"
FG="$2"
BG="$3"
APPEARANCE="$4"
HISTORY="${5:-hide}"
WINDOW="${6:-main}"

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

# Only resize the main window — secondary windows have fixed sizes
if [ "$WINDOW" = "main" ]; then
    pika_open "pika://window/resize/480/300"
    sleep 0.5
fi

# Open the requested secondary window
if [ "$WINDOW" != "main" ]; then
    pika_open "pika://window/$WINDOW"
    sleep 0.8
fi

# Look up the window ID
if [ "$WINDOW" = "main" ]; then
    # Main window: floating level (3)
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
else
    # Secondary windows: the URL trigger calls makeKeyAndOrderFront, so the target window
    # is the frontmost Pika window above the main window level (z-order, first in list).
    WINDOW_ID=$(swift - <<'EOF'
import Quartz
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list {
    if (w["kCGWindowOwnerName"] as? String) == "Pika",
       let layer = w["kCGWindowLayer"] as? Int, layer > 3 {
        print(w["kCGWindowNumber"] as? Int ?? 0)
        break
    }
}
EOF
)
fi

if [ -z "$WINDOW_ID" ]; then
    echo "Error: Pika window '$WINDOW' not found. Is Pika running?" >&2
    exit 1
fi

screencapture -l "$WINDOW_ID" "$OUTPUT"
echo "Captured → $OUTPUT"
