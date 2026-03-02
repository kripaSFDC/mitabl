<?php

declare(strict_types=1);

if ($argc < 3) {
    fwrite(STDERR, "Usage: php scripts/check-coverage.php <clover.xml> <min-percent>\n");
    exit(2);
}

$cloverPath = $argv[1];
$minimumPercent = (float) $argv[2];

if (! is_file($cloverPath)) {
    fwrite(STDERR, "Coverage file not found: {$cloverPath}\n");
    exit(2);
}

libxml_use_internal_errors(true);
$xml = simplexml_load_file($cloverPath);
if ($xml === false) {
    fwrite(STDERR, "Failed to parse Clover XML: {$cloverPath}\n");
    exit(2);
}

$metrics = $xml->project->metrics ?? null;
if ($metrics === null) {
    fwrite(STDERR, "Invalid Clover XML: missing project metrics.\n");
    exit(2);
}

$statements = (int) ($metrics['statements'] ?? 0);
$coveredStatements = (int) ($metrics['coveredstatements'] ?? 0);

if ($statements <= 0) {
    fwrite(STDERR, "No statements found in coverage report.\n");
    exit(2);
}

$percent = ($coveredStatements / $statements) * 100;
$formatted = number_format($percent, 2);
$threshold = number_format($minimumPercent, 2);

fwrite(STDOUT, "Line coverage: {$formatted}% (threshold: {$threshold}%)\n");

if ($percent + 0.00001 < $minimumPercent) {
    fwrite(STDERR, "Coverage threshold not met.\n");
    exit(1);
}

fwrite(STDOUT, "Coverage threshold met.\n");
