<?php
// globalplay.php - Fixed for HamvoIP (full path)
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); 
    echo "Method not allowed."; 
    exit;
}

$base = basename($_POST['file'] ?? '');
$filename = pathinfo($base, PATHINFO_FILENAME);

// Use full path to announcements directory (matches your cron)
$play_path = "/usr/local/share/asterisk/sounds/announcements/" . $filename;

$play_script = "/etc/asterisk/local/playglobal.sh";

if (!is_executable($play_script)) {
    echo "playglobal.sh not found or not executable.";
    exit;
}

$cmd = escapeshellcmd("sudo $play_script " . escapeshellarg($play_path));
exec($cmd . " 2>&1", $output, $retval);

if ($retval === 0) {
    echo "Global playback started for '$filename'.";
} else {
    echo "Global play failed.\nCode: $retval\n" . implode("\n", $output);
}
?>
