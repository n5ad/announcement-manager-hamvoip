
<?php
/**
 * list_ul.php
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
$SOUNDS_DIR = '/usr/local/share/asterisk/sounds/announcements';
$files = glob("$SOUNDS_DIR/*.ul");
$out = [];
foreach ($files as $f) $out[] = basename($f);

header('Content-Type: application/json');
echo json_encode($out);
?>
