// delete_announcement.php for Hamvoip
// Modifie from Announcement Manager for ASL3 created by James N5AD June 2026


<?php
if (!isset($_POST['raw_line'])) {
    echo "Missing cron line";
    exit;
}

$raw = trim($_POST['raw_line']);
$output = [];
exec('sudo crontab -l', $output);

$new_lines = [];
$removed = false;
foreach ($output as $line) {
    if (trim($line) === $raw) {
        $removed = true;
        continue;
    }
    $new_lines[] = $line;
}

if (!$removed) {
    echo "Cron line not found";
    exit;
}

// Remove orphaned comment lines
$final_lines = [];
$i = 0;
while ($i < count($new_lines)) {
    $current = trim($new_lines[$i]);
    if (strpos($current, '# Announcement') === 0) {
        if ($i + 1 >= count($new_lines) || trim($new_lines[$i+1]) === '' || strpos(trim($new_lines[$i+1]), '#') === 0) {
            $i++;
            continue;
        }
    }
    $final_lines[] = $new_lines[$i];
    $i++;
}

$tempfile = tempnam(sys_get_temp_dir(), 'cron_clean_');
file_put_contents($tempfile, implode("\n", $final_lines) . "\n");
exec("sudo crontab $tempfile");
unlink($tempfile);

echo "Cron entry deleted successfully.";
?>
