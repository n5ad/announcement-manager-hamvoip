// list_mp3.php for Hamvoip
// Modified from Announcement Manager for ASL3 created by James N5AD June 2026

<?php
/** list_mp3.php - HamvoIP version */
$files = [];
$mp3_files = glob("/mp3/*.mp3");
foreach ($mp3_files as $f) $files[] = basename($f);

$wav_files = glob("/mp3/*.wav");
foreach ($wav_files as $f) $files[] = basename($f);

sort($files);
$files = array_unique($files);

header('Content-Type: application/json');
echo json_encode($files);
?>
