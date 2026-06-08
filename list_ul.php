<?php
/** list_ul.php - HamvoIP version */
$SOUNDS_DIR = '/usr/local/share/asterisk/sounds/announcements';
$files = glob("$SOUNDS_DIR/*.ul");
$out = [];
foreach ($files as $f) $out[] = basename($f);

header('Content-Type: application/json');
echo json_encode($out);
?>
