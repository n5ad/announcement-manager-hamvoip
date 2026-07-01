#!/usr/bin/env bash
#
# setup-supermon-announcements-hamvoip.sh
# HamvoIP-only Announcement Manager Installer
# Clones from your dedicated repo
set -euo pipefail

REPO_URL="https://github.com/n5ad/announcement-manager-hamvoip.git" # <- Change to your new repo
TEMP_CLONE="/tmp/supermon-announcements-hamvoip"
TARGET_DIR="/srv/http/supermon/custom"
LINK_PHP="/srv/http/supermon/link.php"
MP3_DIR="/mp3"
LOCAL_DIR="/etc/asterisk/local"
ANNOUNCE_DIR="/usr/local/share/asterisk/sounds/announcements"
ALLMON_DIR="/srv/http/allmon/custom"

echo_step() { echo -e "\n\033[1;34m==>\033[0m $1"; }
warn() { echo -e "\033[1;33mWARNING:\033[0m $1" >&2; }
error() { echo -e "\033[1;31mERROR:\033[0m $1" >&2; exit 1; }
check_root() { [[ $EUID -eq 0 ]] || error "Run as root (sudo)."; }
check_root

echo_step "1. Installing required packages"
pacman -Sy --noconfirm git sox perl || error "pacman failed"

echo ""
echo "=== HamvoIP Announcement Manager Setup ==="
echo "Repo: $REPO_URL"
echo -n "Continue? (y/N) "
read -r answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo_step "2. Node number"
echo -n "Node number: "
read -r NODE_NUMBER
if [[ ! "$NODE_NUMBER" =~ ^[0-9]+$ ]]; then
    error "Invalid node number"
fi

echo_step "3. Cloning HamvoIP repo"
rm -rf "$TEMP_CLONE"
git clone --depth 1 "$REPO_URL" "$TEMP_CLONE" || error "Git clone failed"

echo_step "4. Copying files"
mkdir -p "$TARGET_DIR"
cp -v "$TEMP_CLONE"/* "$TARGET_DIR"/ 2>/dev/null || true

echo_step "5. Copying to Allmon custom dir"
mkdir -p "$ALLMON_DIR"
cp -v "$TARGET_DIR/allmon-announcement.inc" "$ALLMON_DIR/allmon-announcement.inc" 2>/dev/null || true
chown root:root "$ALLMON_DIR/allmon-announcement.inc" 2>/dev/null || true
chmod 644 "$ALLMON_DIR/allmon-announcement.inc" 2>/dev/null || true

# MP3 directory
echo_step "6. MP3 directory"
mkdir -p "$MP3_DIR"
usermod -aG http "${SUDO_USER:-$(whoami)}" 2>/dev/null || true
chown -R http:http "$MP3_DIR"
chmod -R 2775 "$MP3_DIR"

# Permissions
echo_step "7. Setting permissions"
chown -R http:http "$TARGET_DIR"
find "$TARGET_DIR" -type f -name "*.php" -exec chmod 644 {} \;
find "$TARGET_DIR" -type f -name "*.inc" -exec chmod 644 {} \;

# Announcements dir
echo_step "8. Announcements directory"
mkdir -p "$ANNOUNCE_DIR"
chown -R http:http "$ANNOUNCE_DIR"
chmod -R 2775 "$ANNOUNCE_DIR"

# STEP 9. Install prerequisite scripts in /etc/asterisk/local/ (if missing)

echo_step "9. Installing prerequisite scripts in $LOCAL_DIR"
mkdir -p "$LOCAL_DIR"
chown asterisk:asterisk "$LOCAL_DIR" 2>/dev/null || chown root:root "$LOCAL_DIR"
chmod 755 "$LOCAL_DIR"

# ----- playglobal.sh -----
GLOBAL_SCRIPT="$LOCAL_DIR/playglobal.sh"
if [[ ! -f "$GLOBAL_SCRIPT" ]]; then
    echo "Creating $GLOBAL_SCRIPT (missing)"
    cat > "$GLOBAL_SCRIPT" << 'EOF'
#!/bin/bash
#
# playglobal.sh - Play an audio file over an AllStarLink v3 node (Debian 12)
NODE="__NODE_NUMBER__"
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo or as root."
    exit 1
fi
if [ -z "$1" ]; then
    echo "Usage: $0 <audio_file_without_extension>"
    exit 1
fi
asterisk -rx "rpt playback ${NODE} $1"
EOF
    sed -i "s/__NODE_NUMBER__/$NODE_NUMBER/" "$GLOBAL_SCRIPT"
    chmod +x "$GLOBAL_SCRIPT"
    chown asterisk:asterisk "$GLOBAL_SCRIPT" 2>/dev/null || chown root:root "$GLOBAL_SCRIPT"
    chmod 755 "$GLOBAL_SCRIPT"
    echo "Created $GLOBAL_SCRIPT with node number: $NODE_NUMBER"
else
    echo "$GLOBAL_SCRIPT already exists - skipping"
fi

# ----- polite_global.sh -----
POLITE_GLOBAL_SCRIPT="$LOCAL_DIR/polite_global.sh"
if [[ ! -f "$POLITE_GLOBAL_SCRIPT" ]]; then
    echo "Creating $POLITE_GLOBAL_SCRIPT (missing)"
    cat > "$POLITE_GLOBAL_SCRIPT" << 'EOF'
#!/bin/bash
FILE=$1
NODE="__NODE_NUMBER__"
MAX_WAIT=300
CHECK_INTERVAL=1
TAIL_DELAY=2
is_busy() {
    RESULT=$(asterisk -rx "rpt show variables $NODE" 2>/dev/null | grep "RPT_RXKEYED" | awk -F= '{print $2}' | tr -d ' ')
    [ "$RESULT" = "1" ]
}
WAITED=0
while true; do
    if is_busy; then
        sleep $CHECK_INTERVAL
        WAITED=$((WAITED + CHECK_INTERVAL))
        if [ "$WAITED" -ge "$MAX_WAIT" ]; then
            break
        fi
    else
        sleep $TAIL_DELAY
        if is_busy; then
            continue
        fi
        break
    fi
done
asterisk -rx "rpt playback ${NODE} $FILE"
EOF
    sed -i "s/__NODE_NUMBER__/$NODE_NUMBER/" "$POLITE_GLOBAL_SCRIPT"
    chmod +x "$POLITE_GLOBAL_SCRIPT"
    chown asterisk:asterisk "$POLITE_GLOBAL_SCRIPT" 2>/dev/null || chown root:root "$POLITE_GLOBAL_SCRIPT"
    chmod 755 "$POLITE_GLOBAL_SCRIPT"
    echo "Created $POLITE_GLOBAL_SCRIPT"
else
    echo "$POLITE_GLOBAL_SCRIPT already exists - skipping"
fi

# ----- playaudio.sh -----
PLAY_SCRIPT="$LOCAL_DIR/playaudio.sh"
if [[ ! -f "$PLAY_SCRIPT" ]]; then
    echo "Creating $PLAY_SCRIPT (missing)"
    cat > "$PLAY_SCRIPT" << 'EOF'
#!/bin/bash
#
# playaudio.sh - Play an audio file over an AllStarLink v3 node (Debian 12)
NODE="__NODE_NUMBER__"
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo or as root."
    exit 1
fi
if [ -z "$1" ]; then
    echo "Usage: $0 <audio_file_without_extension>"
    exit 1
fi
asterisk -rx "rpt localplay ${NODE} $1"
EOF
    sed -i "s/__NODE_NUMBER__/$NODE_NUMBER/" "$PLAY_SCRIPT"
    chmod +x "$PLAY_SCRIPT"
    chown asterisk:asterisk "$PLAY_SCRIPT" 2>/dev/null || chown root:root "$PLAY_SCRIPT"
    chmod 755 "$PLAY_SCRIPT"
    echo "Created $PLAY_SCRIPT with node number: $NODE_NUMBER"
else
    echo "$PLAY_SCRIPT already exists - skipping"
fi

# ----- polite_play.sh -----
POLITE_PLAY_SCRIPT="$LOCAL_DIR/polite_play.sh"
if [[ ! -f "$POLITE_PLAY_SCRIPT" ]]; then
    echo "Creating $POLITE_PLAY_SCRIPT (missing)"
    cat > "$POLITE_PLAY_SCRIPT" << 'EOF'
#!/bin/bash
FILE=$1
NODE="__NODE_NUMBER__"
MAX_WAIT=300
CHECK_INTERVAL=1
TAIL_DELAY=2
is_busy() {
    RESULT=$(asterisk -rx "rpt show variables $NODE" 2>/dev/null | grep "RPT_RXKEYED" | awk -F= '{print $2}' | tr -d ' ')
    [ "$RESULT" = "1" ]
}
WAITED=0
while true; do
    if is_busy; then
        sleep $CHECK_INTERVAL
        WAITED=$((WAITED + CHECK_INTERVAL))
        if [ "$WAITED" -ge "$MAX_WAIT" ]; then
            break
        fi
    else
        sleep $TAIL_DELAY
        if is_busy; then
            continue
        fi
        break
    fi
done
asterisk -rx "rpt localplay ${NODE} $FILE"
EOF
    sed -i "s/__NODE_NUMBER__/$NODE_NUMBER/" "$POLITE_PLAY_SCRIPT"
    chmod +x "$POLITE_PLAY_SCRIPT"
    chown asterisk:asterisk "$POLITE_PLAY_SCRIPT" 2>/dev/null || chown root:root "$POLITE_PLAY_SCRIPT"
    chmod 755 "$POLITE_PLAY_SCRIPT"
    echo "Created $POLITE_PLAY_SCRIPT"
else
    echo "$POLITE_PLAY_SCRIPT already exists - skipping"
fi

# ----- audio_convert.sh -----
# (This one was already correct in the original script -- quoted heredoc,
# no install-time variables needed inside it.)
CONVERT_SCRIPT="$LOCAL_DIR/audio_convert.sh"
if [[ ! -f "$CONVERT_SCRIPT" ]]; then
    echo "Creating $CONVERT_SCRIPT (missing)"
    cat > "$CONVERT_SCRIPT" << 'EOF'
#!/bin/bash
#
# audio_convert.sh - Convert audio file to ulaw .ul
#
# Usage: audio_convert.sh input_file [output_file.ul]
#
# If output_file is not specified, it will be named the same as input_file but with .ul extension
# Requires sox (install with apt install sox libsox-fmt-mp3)
if [ $# -lt 1 ]; then
    echo "Usage: $0 [input_file] [output_file.ul]"
    exit 1
fi
INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}.ul}"
sox "$INPUT_FILE" -t raw -r 8000 -c 1 -e u-law "$OUTPUT_FILE"
if [ $? -eq 0 ]; then
    echo "Conversion successful!"
    echo "Output file: $OUTPUT_FILE"
else
    echo "Error: Conversion failed."
fi
EOF
    chmod +x "$CONVERT_SCRIPT"
    chown asterisk:asterisk "$CONVERT_SCRIPT" 2>/dev/null || chown root:root "$CONVERT_SCRIPT"
    chmod 755 "$CONVERT_SCRIPT"
    echo "Created $CONVERT_SCRIPT"
else
    echo "$CONVERT_SCRIPT already exists - skipping"
fi

chmod +x "$PLAY_SCRIPT" "$CONVERT_SCRIPT" 2>/dev/null || true
echo "Verified: Both scripts are executable."

# link.php patch
# NOTE: see caveat below the script -- this section needs your input.
echo_step "10. Patching link.php"
if [[ -f "$LINK_PHP" ]]; then
    cp "$LINK_PHP" "${LINK_PHP}.bak.$(date +%Y%m%d-%H%M%S)"
    if ! grep -q "announcement.inc" "$LINK_PHP"; then
        sed -i '/include.*footer.inc/d' "$LINK_PHP"
        cat << 'EOF' >> "$LINK_PHP"
<?php include "custom/announcement.inc"; ?>
<?php include_once "footer.inc"; ?>
EOF
    fi
    chown http:http "$LINK_PHP"
    chmod 644 "$LINK_PHP"
fi

# Sudoers
echo_step "11. Sudoers rule"
cat > /etc/sudoers.d/99-supermon-announcements << 'EOF'
http ALL=(root) NOPASSWD: /etc/asterisk/local/playaudio.sh
http ALL=(root) NOPASSWD: /usr/bin/crontab
http ALL=(root) NOPASSWD: /etc/asterisk/local/audio_convert.sh
http ALL=(ALL) NOPASSWD: /bin/cp, /bin/chown, /bin/chmod
http ALL=(ALL) NOPASSWD: /etc/asterisk/local/playglobal.sh
http ALL=(root) NOPASSWD: /etc/asterisk/local/polite_play.sh
http ALL=(root) NOPASSWD: /etc/asterisk/local/polite_global.sh
EOF
chmod 0440 /etc/sudoers.d/99-supermon-announcements

echo_step "✅ HamvoIP Announcement Manager Installed Successfully"
echo "73 — N5AD"
