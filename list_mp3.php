
<?php
/**
 * list_mp3.php
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
