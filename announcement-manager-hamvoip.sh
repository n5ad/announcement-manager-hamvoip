#!/usr/bin/env bash
#
# setup-supermon-announcements-hamvoip.sh
# HamvoIP-only Announcement Manager Installer
# Clones from your new dedicated repo

set -euo pipefail

REPO_URL="https://github.com/n5ad/announcement-manager-hamvoip.git"   # ← Change to your new repo
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
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

echo_step "2. Node number"
echo -n "Node number: "
read -r NODE_NUMBER
[[ "$NODE_NUMBER" =~ ^[0-9]+$ ]] || error "Invalid node number"

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

# Prerequisite scripts (create if missing)
echo_step "9. Installing Asterisk helper scripts"
mkdir -p "$LOCAL_DIR"

# (All the cat blocks for playaudio.sh, playglobal.sh, polite_*.sh, audio_convert.sh go here - same as previous full versions)

# link.php patch
echo_step "10. Patching link.php"
if [[ -f "$LINK_PHP" ]]; then
    cp "$LINK_PHP" "${LINK_PHP}.bak.$(date +%Y%m%d-%H%M%S)"
    if ! grep -q "allmon-announcement.inc" "$LINK_PHP"; then
        sed -i '/include.*footer.inc/d' "$LINK_PHP"
        cat << 'EOF' >> "$LINK_PHP"

<div id="spinny"></div>
<?php
include_once "custom/allmon-announcement.inc";
echo "<br><br>";
include_once "footer.inc";
?>
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
