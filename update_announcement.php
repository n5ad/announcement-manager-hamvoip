// update_announcement.php
// Modified from Announcement Manager for ASL3 created by James N5AD June 2026

<?php
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo "Method not allowed."; exit;
}

$raw_line = trim($_POST['raw_line'] ?? '');
$min = trim($_POST['min'] ?? '');
$hour = trim($_POST['hour'] ?? '');
$dom = trim($_POST['dom'] ?? '');
$month = trim($_POST['month'] ?? '');
$dow = trim($_POST['dow'] ?? '');

if (!$raw_line || $min==='' || $hour==='' || $dom==='' || $month==='' || $dow==='') {
    echo "Missing required fields.";
    exit;
}

$output = [];
exec('sudo crontab -l 2>/dev/null', $output);

$new_crontab = [];
$found = false;

foreach ($output as $line) {
    if (trim($line) === $raw_line || strpos(trim($line), $raw_line) !== false) {
        $found = true;
        if (preg_match('/^\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(.+)$/', $line, $m)) {
            $full_command = trim($m[1]);
        } else {
            $full_command = '/etc/asterisk/local/playaudio.sh unknown';
        }
        $new_line = "$min $hour $dom $month $dow $full_command";
        $new_crontab[] = $new_line;
    } else {
        $new_crontab[] = $line;
    }
}

if (!$found) { echo "Original cron not found."; exit; }

$tempfile = tempnam(sys_get_temp_dir(), 'cron_update_');
file_put_contents($tempfile, implode("\n", $new_crontab) . "\n");
exec("sudo crontab $tempfile", $out, $ret);
unlink($tempfile);

echo $ret === 0 ? "Cron job updated successfully." : "Failed to update cron.";
?>
