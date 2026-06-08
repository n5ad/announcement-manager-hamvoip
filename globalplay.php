<?php
// globalplay.php - HamvoIP version
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo "Method not allowed."; exit;
}

$base = basename($_POST['file'] ?? '');
$play_path = "/mp3/" . pathinfo($base, PATHINFO_FILENAME);
$play_script = "/etc/asterisk/local/playglobal.sh";

if (!is_executable($play_script)) {
    echo "playglobal.sh not executable.";
    exit;
}

$cmd = escapeshellcmd("sudo $play_script " . escapeshellarg($play_path));
exec($cmd . " 2>&1", $output, $retval);

if ($retval === 0) {
    echo "Global playback started for '$base'.";
} else {
    echo "Global play failed. Code: $retval";
}
?>
