param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$InterfaceName,
    [string]$ConfigPath,
    [string]$LogDir = (Join-Path $ProjectRoot 'data\raw\suricata'),
    [int]$DurationSeconds = 300,
    [string]$SuricataPath
)

$ErrorActionPreference = 'Stop'

if (-not $SuricataPath -or -not $SuricataPath.Trim()) {
    $cmd = Get-Command suricata -ErrorAction SilentlyContinue
    if ($cmd) {
        $SuricataPath = $cmd.Source
    }
}

if (-not $SuricataPath -or -not (Test-Path -LiteralPath $SuricataPath)) {
    throw "suricata.exe not found. Set -SuricataPath or install Suricata."
}

if (-not $InterfaceName -or -not $InterfaceName.Trim()) {
    throw "Please provide -InterfaceName."
}

if (-not $ConfigPath -or -not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Suricata config not found: $ConfigPath"
}

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logPrefix = Join-Path $LogDir $stamp

$proc = Start-Process -FilePath $SuricataPath -ArgumentList @(
    '-c', $ConfigPath,
    '-i', $InterfaceName,
    '-l', $logPrefix
) -PassThru -WindowStyle Hidden

Start-Sleep -Seconds $DurationSeconds
if (-not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
}

