#!/data/data/com.termux/files/usr/bin/bash

APP_CLASS='code'
X11_DISPLAY=':0'

# Cleanup function to kill all child processes and pulseaudio when the script exits
cleanup() {
    echo "Cleaning up processes..."
    
    # Kill pulseaudio daemon cleanly (preferred method)
    pulseaudio -k || true
    
    # Force-kill any remaining pulseaudio processes (including subprocesses/modules)
    #pkill -f pulseaudio || true
    #pkill -9 -f pulseaudio || true  # extra safety with SIGKILL if needed
    
    # Kill all direct child processes of this script (backgrounded jobs like keep_max & termux-x11 &)
    pkill -P $$ || true
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

keep_max() {
    echo "Starting monitor for all $APP_CLASS windows..."

    while true; do
        # Find all window IDs for the class
        mapfile -t window_ids < <(DISPLAY="$X11_DISPLAY" xdotool search --class "$APP_CLASS" 2>/dev/null)

        if [ ${#window_ids[@]} -gt 0 ]; then
            echo "Found ${#window_ids[@]} window(s) for $APP_CLASS. Maximizing them..."

            for id in "${window_ids[@]}"; do
                echo "  Maxing window $id"
                DISPLAY="$X11_DISPLAY" xdotool windowsize "$id" 100% 100%
                DISPLAY="$X11_DISPLAY" xdotool windowmove "$id" 0 0
            done
        else
            echo "No $APP_CLASS windows found yet..."
        fi

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
  code --no-sandbox --disable-gpu --ozone-platform=x11 --user-data-dir /root/.vscode --verbose 
