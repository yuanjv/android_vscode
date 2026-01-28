#!/data/data/com.termux/files/usr/bin/bash

APP_CLASS='code'
WINDOW_TITLE_PATTERN=' - '
X11_DISPLAY=':0'
#DISPLAY="$X11_DISPLAY"

# Cleanup function to kill all child processes when the script exits
cleanup() {
    echo "Cleaning up processes..."
    pkill -P $$ || true
}

# Set up cleanup trap
trap cleanup EXIT INT TERM


# Function to find the main window ID
find_main_window() {
    DISPLAY="$X11_DISPLAY" xdotool search --class "$APP_CLASS" | while read -r id; do
        if DISPLAY="$X11_DISPLAY" xdotool getwindowname "$id" | grep -q "$WINDOW_TITLE_PATTERN"; then
            echo "$id"
            return 0
        fi
    done
    return 1
}

keep_max(){
    # Wait for and locate the main window
    echo "Waiting for main window..."
    while true; do
        sleep 1
        echo "keep looking for the main window"
        main_window_id=$(find_main_window)
        echo "$main_window_id"
        if [ -n "$main_window_id" ]; then
            echo "Main window found: $main_window_id"
            break
        fi
    done

    # Keep the window maximized
    echo "Maintaining main window size..."
    while true; do
        echo "Maxing..."
        DISPLAY="$X11_DISPLAY" xdotool windowsize "$main_window_id" 100% 100%
        DISPLAY="$X11_DISPLAY" xdotool windowmove "$main_window_id" 0 0
        sleep 1
    done
}

keep_max &

# Start Termux X11 server
XKB_CONFIG_ROOT=/data/data/com.termux/files/usr/share/xkeyboard-config-2 termux-x11 "$X11_DISPLAY" &

# Audio (optional but recommended)
pulseaudio --start --exit-idle-time=-1

# Launch VS Code inside proot
proot-distro login code --shared-tmp -- env \
  DISPLAY="$X11_DISPLAY" \
  XDG_RUNTIME_DIR=/tmp \
  PULSE_SERVER=127.0.0.1 \
  code --no-sandbox --disable-gpu --ozone-platform=x11 --user-data-dir /root/.vscode --verbose 1>/dev/null 2>/dev/null

