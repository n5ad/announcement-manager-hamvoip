<?php
/**
 * announcement.php - HamvoIP Version
 * MP3 to .ul conversion + cron install with scope + mode
 */
$TMP_DIR = '/mp3';
$CONVERT_SCRIPT = '/etc/asterisk/local/audio_convert.sh';
$PLAY_SCRIPT_LOCAL  = '/etc/asterisk/local/playaudio.sh';
$PLAY_SCRIPT_GLOBAL = '/etc/asterisk/local/playglobal.sh';
$SOUNDS_DIR = '/usr/local/share/asterisk/sounds/announcements';

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
$mode    = $_POST['mode'] ?? 'polite';   // polite or priority

if (!$mp3) die("No MP3 file specified.");

$src_mp3 = "$TMP_DIR/$mp3";
if (!file_exists($src_mp3)) die("MP3 file not found.");

if (!is_executable($CONVERT_SCRIPT)) die("Conversion script missing.");

exec(escapeshellcmd("$CONVERT_SCRIPT $src_mp3"), $out, $ret);
if ($ret !== 0) die("Conversion failed.");

$base_name = pathinfo($mp3, PATHINFO_FILENAME);
$ul_file = "$TMP_DIR/$base_name.ul";
if (!file_exists($ul_file)) die("Conversion failed - no .ul created.");

exec(escapeshellcmd("sudo cp $ul_file $SOUNDS_DIR/$base_name.ul"));
exec(escapeshellcmd("sudo chmod 644 $SOUNDS_DIR/$base_name.ul"));
exec(escapeshellcmd("sudo chown root:root $SOUNDS_DIR/$base_name.ul"));

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

    $tmp_cron = tempnam(sys_get_temp_dir(), 'cron');
    exec("sudo crontab -l > " . escapeshellarg($tmp_cron) . " 2>/dev/null");
    file_put_contents($tmp_cron, $desc_clean . "\n", FILE_APPEND);
    file_put_contents($tmp_cron, $cron_line . "\n", FILE_APPEND);
    exec("sudo crontab " . escapeshellarg($tmp_cron));
    unlink($tmp_cron);

    echo "Success! Cron installed.\nScope: $scope | Mode: $mode";
} else {
    echo "Conversion successful. No cron installed.";
}
echo "\nUL file: $SOUNDS_DIR/$base_name.ul";
?>
