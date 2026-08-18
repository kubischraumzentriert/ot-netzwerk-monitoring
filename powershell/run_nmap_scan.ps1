param(
    [string]$ProjectRoot = '',
    [string]$TargetsCsv = '',
    [string]$OutputDir = '',
    [string]$NmapPath,
    [string]$DefaultPorts = '9000'
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
if (-not $TargetsCsv -or -not $TargetsCsv.Trim()) {
    $TargetsCsv = if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'configs\targets.private.csv')) { Join-Path $ProjectRoot 'configs\targets.private.csv' } else { Join-Path $ProjectRoot 'configs\targets.csv' }
}
if (-not $OutputDir -or -not $OutputDir.Trim()) {
    $OutputDir = Join-Path $ProjectRoot 'data\raw\scans\nmap'
}

. (Join-Path $ScriptRootPath 'resolve_tool_path.ps1')
$NmapPath = Resolve-ProjectTool `
    -ProjectRoot $ProjectRoot `
    -ToolName 'nmap' `
    -ConfigKey 'nmap' `
    -ExplicitPath $NmapPath `
    -CandidatePaths @(
        'C:\Program Files\Nmap\nmap.exe',
        'C:\Program Files (x86)\Nmap\nmap.exe'
    )

if (-not (Test-Path -LiteralPath $TargetsCsv)) {
    throw "Targets CSV not found: $TargetsCsv"
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$targets = Import-Csv -LiteralPath $TargetsCsv

foreach ($target in $targets) {
    $label = if ($target.label) { $target.label } else { $target.host }
    $targetHost = $target.host
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
        $targetHost
    )

    Write-Host "Scanning $label ($targetHost) ports $ports"
    & $NmapPath @args
}
