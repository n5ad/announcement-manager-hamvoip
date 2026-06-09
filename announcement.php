<?php
/**
 * announcement.php
 *
 * HamvoIP Supermon Announcement Manager
 *
 * Author: N5AD (James Carnathan)
 *
 * Created: June 2026
 * Updated: June 2026
 *
 *
 * Note: This file is included after successful login.
 */

$TMP_DIR = '/mp3';
$CONVERT_SCRIPT = '/etc/asterisk/local/audio_convert.sh';
$PLAY_SCRIPT_LOCAL  = '/etc/asterisk/local/playaudio.sh';
$PLAY_SCRIPT_GLOBAL = '/etc/asterisk/local/playglobal.sh';
$SOUNDS_DIR = '/usr/local/share/asterisk/sounds/announcements';

// Get POST data
$mp3     = basename($_POST['file'] ?? '');
$min     = $_POST['min'] ?? '';
$hour    = $_POST['hour'] ?? '';
$dom     = $_POST['dom'] ?? '';
$month   = $_POST['month'] ?? '';
$dow     = $_POST['dow'] ?? '';
$week    = $_POST['week'] ?? '*';
$use_nth = !empty($_POST['use_nth']) && $_POST['use_nth'] == 1;
$desc    = $_POST['desc'] ?? '';
$scope   = $_POST['scope'] ?? 'local';
$mode    = $_POST['mode'] ?? 'polite';

if (!$mp3) die("No MP3 file specified.");

$src_mp3 = "$TMP_DIR/$mp3";
if (!file_exists($src_mp3)) die("MP3 file not found: $mp3");

if (!is_executable($CONVERT_SCRIPT)) die("audio_convert.sh not found or not executable.");

$base_name = pathinfo($mp3, PATHINFO_FILENAME);
$ul_final  = "$SOUNDS_DIR/$base_name.ul";

// Run conversion directly to final location
$cmd = escapeshellcmd("sudo $CONVERT_SCRIPT " . escapeshellarg($src_mp3) . " " . escapeshellarg($ul_final));
exec($cmd, $output, $ret);

if ($ret !== 0) {
    die("Conversion failed: " . implode("\n", $output));
}

// Set permissions
exec("sudo chown root:root " . escapeshellarg($ul_final));
exec("sudo chmod 644 " . escapeshellarg($ul_final));

$play_script = ($scope === 'global') ? $PLAY_SCRIPT_GLOBAL : $PLAY_SCRIPT_LOCAL;

$scope_note = ($scope === 'global') ? " [GLOBAL]" : " [local]";
$mode_note  = " [$mode]";
$desc_clean = $desc ? "# Announcement: $desc$scope_note$mode_note" : "# Announcement$scope_note$mode_note";

if ($min !== '' && $hour !== '' && $dom !== '' && $month !== '' && $dow !== '') {
    $play_target = "$SOUNDS_DIR/$base_name";

    if ($use_nth && in_array($week, ['1','2','3','4','5'])) {
        $low = ((int)$week - 1) * 7 + 1;
        $high = ((int)$week === 5) ? 31 : $low + 6;
        $cond = "[ \$(date +\\%d) -ge $low ] && [ \$(date +\\%d) -le $high ]";
        $cron_line = "$min $hour * * $dow /bin/bash -c '$cond && $play_script $play_target'";
    } else {
        $cron_line = "$min $hour $dom $month $dow $play_script $play_target";
    }

    $tmp_cron = tempnam(sys_get_temp_dir(), 'cron_ann');
    exec("sudo crontab -l > " . escapeshellarg($tmp_cron) . " 2>/dev/null");

    file_put_contents($tmp_cron, $desc_clean . "\n", FILE_APPEND);
    file_put_contents($tmp_cron, $cron_line . "\n", FILE_APPEND);

    exec("sudo crontab " . escapeshellarg($tmp_cron));
    unlink($tmp_cron);

    echo "Success! Announcement installed.\nScope: $scope | Mode: $mode";
} else {
    echo "Conversion successful. No cron job created.";
}

echo "\nUL file: $ul_final";
?>
