param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$TargetsCsv = (Join-Path $ProjectRoot 'configs\targets.csv'),
    [string]$OutputDir = (Join-Path $ProjectRoot 'data\raw\scans\nmap'),
    [string]$NmapPath,
    [string]$DefaultPorts = '9000'
)

$ErrorActionPreference = 'Stop'

if (-not $NmapPath -or -not $NmapPath.Trim()) {
    $cmd = Get-Command nmap -ErrorAction SilentlyContinue
    if ($cmd) {
        $NmapPath = $cmd.Source
    } else {
        $candidate = 'C:\Program Files (x86)\Nmap\nmap.exe'
        if (Test-Path -LiteralPath $candidate) {
            $NmapPath = $candidate
        }
    }
}

if (-not $NmapPath -or -not (Test-Path -LiteralPath $NmapPath)) {
    throw "nmap.exe not found. Set -NmapPath or install Nmap."
}

if (-not (Test-Path -LiteralPath $TargetsCsv)) {
    throw "Targets CSV not found: $TargetsCsv"
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$targets = Import-Csv -LiteralPath $TargetsCsv

foreach ($target in $targets) {
    $label = if ($target.label) { $target.label } else { $target.host }
    $host = $target.host
    $ports = if ($target.ports) { $target.ports } else { $DefaultPorts }
    $safeLabel = ($label -replace '[^A-Za-z0-9_-]', '_')
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $base = Join-Path $OutputDir "$stamp`_$safeLabel"

    $args = @(
        '-Pn',
        '-n',
        '-sT',
        '-T2',
        '--max-retries', '2',
        '--host-timeout', '45s',
        '-p', $ports,
        '-oA', $base,
        $host
    )

    Write-Host "Scanning $label ($host) ports $ports"
    & $NmapPath @args
}

