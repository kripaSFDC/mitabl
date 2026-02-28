param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,
    [int]$Days = 7
)

if (-not (Test-Path $LogPath)) {
    Write-Error "Log path not found: $LogPath"
    exit 2
}

$cutoff = (Get-Date).AddDays(-$Days)
$patterns = @(
    'salesforce',
    'Sales-Auth',
    'webto.salesforce.com',
    '/services/oauth2/token',
    '/services/data/v'
)

$files = Get-ChildItem -Path $LogPath -Recurse -File | Where-Object { $_.LastWriteTime -ge $cutoff }
if ($files.Count -eq 0) {
    Write-Warning "No log files found within the last $Days day(s) under $LogPath."
    exit 1
}

$matches = foreach ($file in $files) {
    Select-String -Path $file.FullName -Pattern $patterns -SimpleMatch
}

if ($matches) {
    Write-Host "Detected Salesforce traffic markers in the past $Days day(s):" -ForegroundColor Red
    $matches | Select-Object -First 200 | ForEach-Object {
        Write-Host "$($_.Path):$($_.LineNumber): $($_.Line)"
    }
    exit 1
}

Write-Host "No Salesforce traffic markers detected in logs from the past $Days day(s)." -ForegroundColor Green
exit 0
