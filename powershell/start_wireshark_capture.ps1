param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$InterfaceId,
    [string]$CaptureFilter = 'port 9000',
    [int]$DurationSeconds = 300,
    [string]$OutputDir = (Join-Path $ProjectRoot 'data\raw\pcap'),
    [string]$TsharkPath
)

$ErrorActionPreference = 'Stop'

if (-not $TsharkPath -or -not $TsharkPath.Trim()) {
    $cmd = Get-Command tshark -ErrorAction SilentlyContinue
    if ($cmd) {
        $TsharkPath = $cmd.Source
    }
}

if (-not $TsharkPath -or -not (Test-Path -LiteralPath $TsharkPath)) {
    throw "tshark.exe not found. Set -TsharkPath or install Wireshark/tshark."
}

if (-not $InterfaceId -or -not $InterfaceId.Trim()) {
    throw "Please provide -InterfaceId. Use list_capture_interfaces.ps1 first."
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outFile = Join-Path $OutputDir "$stamp`_port9000.pcapng"

$args = @(
    '-i', $InterfaceId,
    '-f', $CaptureFilter,
    '-a', "duration:$DurationSeconds",
    '-w', $outFile
)

Write-Host "Capturing to $outFile"
& $TsharkPath @args

