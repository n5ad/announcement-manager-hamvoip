
<?php
/**
 * list_cron.php
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
header('Content-Type: application/json');
$cron = shell_exec('sudo crontab -l 2>/dev/null');
if (trim($cron) === '') { echo json_encode([]); exit; }

$lines = explode("\n", $cron);
$entries = [];
$last_comment = "";

foreach ($lines as $line) {
    $line = trim($line);
    if ($line === "") continue;

    if (strpos($line, '# Announcement:') === 0) {
        $last_comment = trim(substr($line, strlen('# Announcement:')));
        continue;
    }

    if (strpos($line, 'playaudio.sh') !== false || strpos($line, 'playglobal.sh') !== false) {
        $parts = preg_split('/\s+/', $line, -1, PREG_SPLIT_NO_EMPTY);
        $time = implode(" ", array_slice($parts, 0, 5));
        $command = implode(" ", array_slice($parts, 5));

        if (preg_match('/(playaudio\.sh|playglobal\.sh)\s+(.+)$/', $command, $m)) {
            $script = $m[1];
            $full_target = trim($m[2]);
            $file = basename($full_target);
            $file = preg_replace('/\.ul$/', '', $file);

            $scope = (strpos($script, 'playglobal.sh') !== false) ? 'global' : 'local';
            if (preg_match('/\[GLOBAL\]/i', $last_comment)) $scope = 'global';

            $entries[] = [
                "time" => $time,
                "file" => $file,
                "desc" => $last_comment,
                "scope" => $scope,
                "raw" => $line
            ];
            $last_comment = "";
        }
    }
}

echo json_encode($entries);
?>
