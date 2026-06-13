<?php
/**
 * convert_mp3.php
 *
 * HamvoIP Supermon Announcement Manager
 *
 * Author: N5AD (James Carnathan)
 *
 * Created: June 2026
 *
 *
 * Note: This file is included after successful login.
 */
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo "Method not allowed.";
    exit;
}

$file = basename($_POST['file'] ?? '');
if (empty($file)) {
    echo "Error: No file specified.";
    exit;
}

$input     = "/mp3/" . $file;
$base_name = pathinfo($file, PATHINFO_FILENAME);
$ul_final  = "/usr/local/share/asterisk/sounds/announcements/" . $base_name . ".ul";

$convert_script = "/etc/asterisk/local/audio_convert.sh";

if (!file_exists($input)) {
    echo "Error: File not found: $file";
    exit;
}

if (!is_executable($convert_script)) {
    echo "Error: audio_convert.sh not found.";
    exit;
}

// Run conversion
$cmd = escapeshellcmd("sudo $convert_script " . escapeshellarg($input) . " " . escapeshellarg($ul_final));
exec($cmd . " 2>&1", $output, $retval);

if ($retval === 0 || file_exists($ul_final)) {
    echo "Successfully converted and installed: $base_name.ul";
} else {
    echo " Conversion command failed.\n" . implode("\n", $output);
}
?>
