// run_announcement.php for Hamvoip
// Modified from Announcement Manager for ASL3 created by James N5AD June 2026

<?php
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); 
    echo "Method not allowed."; 
    exit;
}

$base = basename($_POST['file'] ?? '');
$source = $_POST['source'] ?? 'ul';

if ($source === 'mp3') {
    $play_path = "/mp3/" . pathinfo($base, PATHINFO_FILENAME);
} else {
    // Use full path for .ul files
    $play_path = "/usr/local/share/asterisk/sounds/announcements/" . pathinfo($base, PATHINFO_FILENAME);
}

$play_script = "/etc/asterisk/local/playaudio.sh";

if (!is_executable($play_script)) {
    echo "playaudio.sh not executable.";
    exit;
}

$cmd = escapeshellcmd("sudo $play_script " . escapeshellarg($play_path));
exec($cmd . " 2>&1", $output, $retval);

if ($retval === 0) {
    echo "Local playback started for '$base'.";
} else {
    echo "Local play failed.\nCode: $retval\n" . implode("\n", $output);
}
?>
