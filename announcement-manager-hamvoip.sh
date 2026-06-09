#!/usr/bin/env bash
#
# setup-supermon-announcements-hamvoip.sh
# COMPLETE HamvoIP Supermon Installer
# Modified from Announcement Manager created for ASL3 by James N5AD June 2026

set -euo pipefail

# CONFIG
REPO_URL="https://github.com/n5ad/announcement-manager-hamvoip.git"
TEMP_CLONE="/tmp/supermon-announcements-hamvoip"
TARGET_DIR="/srv/http/supermon/custom"
LINK_PHP="/srv/http/supermon/link.php"
MP3_DIR="/mp3"
LOCAL_DIR="/etc/asterisk/local"
ANNOUNCE_DIR="/usr/local/share/asterisk/sounds/announcements"

echo_step() { echo -e "\n\033[1;34m==>\033[0m $1"; }
warn() { echo -e "\033[1;33mWARNING:\033[0m $1" >&2; }
error() { echo -e "\033[1;31mERROR:\033[0m $1" >&2; exit 1; }
check_root() { [[ $EUID -eq 0 ]] || error "Run as root (sudo)."; }

check_root
echo_step "1. Installing required packages"
pacman -Sy --noconfirm git sox libmad libid3tag perl || error "pacman failed"

echo ""
echo "=== HamvoIP Supermon Announcement Manager Setup ==="
echo "Repo: $REPO_URL"
echo -n "Continue? (y/N) "
read -r answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo_step "2. Enter AllStar node number"
echo -n "Node number: "
read -r NODE_NUMBER
[[ "$NODE_NUMBER" =~ ^[0-9]+$ ]] || error "Invalid node number"

echo_step "3. Cloning HamvoIP repo"
rm -rf "$TEMP_CLONE"
git clone --depth 1 "$REPO_URL" "$TEMP_CLONE" || error "Git clone failed"

echo_step "3. Cloning HamvoIP repo"
rm -rf "$TEMP_CLONE"
git clone --depth 1 "$REPO_URL" "$TEMP_CLONE" || error "Git clone failed"

echo_step "4. Copying only .php and .inc files from repo"
mkdir -p "$TARGET_DIR"
find "$TEMP_CLONE" -maxdepth 1 -type f \( -name "*.php" -o -name "*.inc" \) -exec cp -v {} "$TARGET_DIR"/ \;

echo "Copied the following files:"
ls -1 "$TARGET_DIR"/*.php "$TARGET_DIR"/*.inc 2>/dev/null || echo "No files copied"

# MP3 directory
echo_step "5. Creating /mp3 directory"
mkdir -p "$MP3_DIR"
usermod -aG http "${SUDO_USER:-$(whoami)}" 2>/dev/null || true
chown -R http:http "$MP3_DIR"
chmod -R 2775 "$MP3_DIR"

# Permissions
echo_step "6. Setting permissions"
chown -R http:http "$TARGET_DIR"
find "$TARGET_DIR" -type f \( -name "*.php" -o -name "*.inc" \) -exec chmod 644 {} \;

# Announcements dir
echo_step "7. Creating Announcements directory"
mkdir -p "$ANNOUNCE_DIR"
chown -R http:http "$ANNOUNCE_DIR"
chmod -R 2775 "$ANNOUNCE_DIR"

# Prerequisite scripts
echo_step "8. Installing Asterisk helper scripts"
mkdir -p "$LOCAL_DIR"
chown asterisk:asterisk "$LOCAL_DIR" 2>/dev/null || true
chmod 755 "$LOCAL_DIR"

# playglobal.sh
cat > "$LOCAL_DIR/playglobal.sh" << EOF
#!/bin/bash
# modified for Hamvoip by N5AD James
# playglobal.sh  Play an audio file over an Hamvoip
NODE="$NODE_NUMBER"
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
chmod +x "$LOCAL_DIR/playglobal.sh"
chown asterisk:asterisk "$LOCAL_DIR/playglobal.sh" 2>/dev/null || true

# polite_global.sh
cat > "$LOCAL_DIR/polite_global.sh" << 'EOF'
#!/bin/bash

FILE=$1
NODE="$NODE_NUMBER"

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
chmod +x "$LOCAL_DIR/polite_global.sh"
chown asterisk:asterisk "$LOCAL_DIR/polite_global.sh" 2>/dev/null || true

# playaudio.sh
cat > "$LOCAL_DIR/playaudio.sh" << EOF
#!/bin/bash
# Modified for Hamvoip by N5AD James
# playaudio.sh  Play an audio file over Hamvoip
NODE="$NODE_NUMBER"
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
chmod +x "$LOCAL_DIR/playaudio.sh"
chown asterisk:asterisk "$LOCAL_DIR/playaudio.sh" 2>/dev/null || true

# polite_play.sh
cat > "$LOCAL_DIR/polite_play.sh" << 'EOF'
#!/bin/bash
FILE=$1
NODE="$NODE_NUMBER"
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
chmod +x "$LOCAL_DIR/polite_play.sh"
chown asterisk:asterisk "$LOCAL_DIR/polite_play.sh" 2>/dev/null || true

# audio_convert.sh (your original)
cat > "$LOCAL_DIR/audio_convert.sh" << 'EOF'
#!/bin/bash
INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}.ul}"
sox "$INPUT_FILE" -t raw -r 8000 -c 1 -e u-law "$OUTPUT_FILE"
if [ $? -eq 0 ]; then
    echo "Conversion successful! Output: $OUTPUT_FILE"
else
    echo "Error: Conversion failed."
fi
EOF
chmod +x "$LOCAL_DIR/audio_convert.sh"
chown asterisk:asterisk "$LOCAL_DIR/audio_convert.sh" 2>/dev/null || true

echo_step "9. Patching link.php for Announcement Manager"

if [[ -f "$LINK_PHP" ]]; then
    cp "$LINK_PHP" "${LINK_PHP}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Backup created: ${LINK_PHP}.bak.*"

    if grep -q "announcement.inc" "$LINK_PHP"; then
        echo "Announcement include already present - skipping patch"
    else
        echo "Applying clean patch..."

        # Remove any existing footer include at the end
        sed -i '/include.*footer.inc/d' "$LINK_PHP"

        # Remove any trailing ?> if it exists
        sed -i '${/^\s*?>\s*$/d}' "$LINK_PHP"

        # Append our include cleanly
        cat << 'EOF' >> "$LINK_PHP"

<div id="spinny"></div>
<?php
include_once "custom/announcement.inc";
echo "<br><br>";
include_once "footer.inc";
?>
EOF

        echo "link.php patched successfully"
    fi

    chown http:http "$LINK_PHP"
    chmod 644 "$LINK_PHP"
else
    warn "link.php not found at $LINK_PHP"
fi

# Sudoers
echo_step "10. Creating sudoers rule"
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

echo_step "✅ HamvoIP Supermon Announcement Manager Installed Successfully"
echo "73 — N5AD"
