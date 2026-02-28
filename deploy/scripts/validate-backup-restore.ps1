param(
    [Parameter(Mandatory = $true)]
    [string]$BackupRoot,

    [int]$MaxArtifactAgeHours = 26,

    [string[]]$RequiredScopes = @("database", "redis", "uploads"),

    [string]$RestoreEvidenceFile = ""
)

$utcNow = [DateTime]::UtcNow
$maxAge = [TimeSpan]::FromHours($MaxArtifactAgeHours)
$failures = New-Object System.Collections.Generic.List[string]
$details = @()
$resolvedBackupRoot = $BackupRoot

if (-not (Test-Path $BackupRoot)) {
    $failures.Add("Backup root path does not exist: $BackupRoot")
}
else {
    $resolvedBackupRoot = (Resolve-Path $BackupRoot).Path
}

foreach ($scope in $RequiredScopes) {
    if (-not (Test-Path $BackupRoot)) {
        continue
    }

    $scopePath = Join-Path $BackupRoot $scope
    if (-not (Test-Path $scopePath)) {
        $failures.Add("Missing backup scope directory: $scopePath")
        continue
    }

    $latest = Get-ChildItem -Path $scopePath -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if (-not $latest) {
        $failures.Add("No backup artifacts found in scope: $scope")
        continue
    }

    $age = $utcNow - $latest.LastWriteTimeUtc
    $isFresh = $age -le $maxAge
    if (-not $isFresh) {
        $failures.Add("Latest $scope backup is stale (${age.TotalHours}h old): $($latest.FullName)")
    }

    $details += [pscustomobject]@{
        scope = $scope
        latest_artifact = $latest.FullName
        latest_write_utc = $latest.LastWriteTimeUtc.ToString("o")
        age_hours = [Math]::Round($age.TotalHours, 2)
        within_age_target = $isFresh
    }
}

if ($RestoreEvidenceFile -ne "") {
    if (-not (Test-Path $RestoreEvidenceFile)) {
        $failures.Add("Restore evidence file not found: $RestoreEvidenceFile")
    }
    else {
        $restoreFile = Get-Item $RestoreEvidenceFile
        $restoreAge = $utcNow - $restoreFile.LastWriteTimeUtc
        $restoreFresh = $restoreAge -le $maxAge
        if (-not $restoreFresh) {
            $failures.Add("Restore evidence is stale (${restoreAge.TotalHours}h old): $RestoreEvidenceFile")
        }

        $details += [pscustomobject]@{
            scope = "restore-drill"
            latest_artifact = $restoreFile.FullName
            latest_write_utc = $restoreFile.LastWriteTimeUtc.ToString("o")
            age_hours = [Math]::Round($restoreAge.TotalHours, 2)
            within_age_target = $restoreFresh
        }
    }
}

$summary = [pscustomobject]@{
    generated_at_utc = $utcNow.ToString("o")
    backup_root = $resolvedBackupRoot
    max_artifact_age_hours = $MaxArtifactAgeHours
    required_scopes = $RequiredScopes
    checks = $details
    failures = $failures
    passed = ($failures.Count -eq 0)
}

$summary | ConvertTo-Json -Depth 8

if ($failures.Count -gt 0) {
    exit 1
}

exit 0
