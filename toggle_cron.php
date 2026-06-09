
<?php
/**
 * toggle_cron.php
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
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo "Method not allowed."; exit;
}

$raw_line = trim($_POST['raw_line'] ?? '');
$enable = (bool)($_POST['enable'] ?? false);

if (empty($raw_line)) { echo "Missing parameters."; exit; }

$output = [];
exec('sudo crontab -l 2>/dev/null', $output);

$new_crontab = [];
$found = false;

foreach ($output as $line) {
    $trimmed = trim($line);
    if ($trimmed === $raw_line || $trimmed === "# $raw_line") {
        $found = true;
        $new_line = $enable ? ltrim($trimmed, '# ') : "# $raw_line";
        $new_crontab[] = $new_line;
    } else {
        $new_crontab[] = $line;
    }
}

if (!$found) { echo "Cron line not found."; exit; }

$tempfile = tempnam(sys_get_temp_dir(), 'cron');
file_put_contents($tempfile, implode("\n", $new_crontab) . "\n");
exec("sudo crontab $tempfile", $out, $ret);
unlink($tempfile);

echo $enable ? "Cron job enabled." : "Cron job disabled.";
?>
