<?php
// convert_mp3.php - HamvoIP version
// Converts MP3/WAV â†’ .ul and places it in the correct announcements directory

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); 
    echo "Method not allowed."; 
    exit;
}

$file = basename($_POST['file'] ?? '');
if (!$file) { 
    echo "No file specified."; 
    exit; 
}

$input     = "/mp3/" . $file;
$base_name = pathinfo($file, PATHINFO_FILENAME);
$ul_temp   = "/mp3/" . $base_name . ".ul";
$ul_final  = "/usr/local/share/asterisk/sounds/announcements/" . $base_name . ".ul";

$convert_script = "/etc/asterisk/local/audio_convert.sh";

if (!file_exists($input)) {
    echo "File not found: $file";
    exit;
}
if (!is_executable($convert_script)) {
    echo "audio_convert.sh not found or not executable.";
    exit;
}

// Step 1: Convert to .ul in /mp3/
$cmd = escapeshellcmd("sudo $convert_script " . escapeshellarg($input));
exec($cmd . " 2>&1", $output, $retval);

if ($retval !== 0) {
    echo "âŒ Conversion failed.\n" . implode("\n", $output);
    exit;
}

// Step 2: Move/Copy to the correct announcements directory
$cmd2 = escapeshellcmd("sudo cp " . escapeshellarg($ul_temp) . " " . escapeshellarg($ul_final));
exec($cmd2, $out2, $ret2);

if ($ret2 === 0) {
    // Optional: clean up the .ul from /mp3/
    @unlink($ul_temp);
    echo "âœ… Successfully converted and installed: $base_name.ul";
} else {
    echo "âŒ Failed to copy .ul to announcements directory.";
}
?>
