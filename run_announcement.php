<?php
// run_announcement.php - HamvoIP version
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo "Method not allowed."; exit;
}

$base = basename($_POST['file'] ?? '');
$source = $_POST['source'] ?? 'ul';

if ($source === 'mp3') {
    $play_path = "/mp3/" . pathinfo($base, PATHINFO_FILENAME);
    $echo_msg = "Playing '$base' (MP3/WAV) locally.";
} else {
    $play_path = "announcements/" . pathinfo($base, PATHINFO_FILENAME);
    $echo_msg = "Playing '$base' (.ul) locally.";
}

$play_script = "/etc/asterisk/local/playaudio.sh";

if (!is_executable($play_script)) {
    echo "playaudio.sh not executable.";
    exit;
}

$cmd = escapeshellcmd("sudo $play_script " . escapeshellarg($play_path));
exec($cmd . " 2>&1", $output, $retval);

if ($retval === 0) {
    echo $echo_msg;
} else {
    echo "Failed to play. Code: $retval";
}
?>
