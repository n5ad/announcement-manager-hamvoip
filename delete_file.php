
<?php
/**
 * delete_file.php
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
// delete_file.php - HamvoIP version
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo "Method not allowed.";
    exit;
}

$type = $_POST['type'] ?? '';
$filename = basename($_POST['file'] ?? '');

if ($type === 'mp3') {
    $file_path = "/mp3/" . $filename;
} elseif ($type === 'ul') {
    $file_path = "/usr/local/share/asterisk/sounds/announcements/" . $filename;
} else {
    echo "Invalid type.";
    exit;
}

if (!file_exists($file_path)) {
    echo "File not found.";
    exit;
}

if (unlink($file_path)) {
    echo "Deleted $filename successfully.";
} else {
    echo "Failed to delete $filename.";
}
?>
