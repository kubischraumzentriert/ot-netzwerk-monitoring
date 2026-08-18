param(
    [string]$ProjectRoot = '',
    [string]$InterfaceId,
    [string]$CaptureFilter = 'port 9000',
    [int]$DurationSeconds = 300,
    [string]$OutputDir = '',
    [string]$TsharkPath
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
if (-not $OutputDir -or -not $OutputDir.Trim()) {
    $OutputDir = Join-Path $ProjectRoot 'data\raw\pcap'
}

. (Join-Path $ScriptRootPath 'resolve_tool_path.ps1')
$TsharkPath = Resolve-ProjectTool `
    -ProjectRoot $ProjectRoot `
    -ToolName 'tshark' `
    -ConfigKey 'tshark' `
    -ExplicitPath $TsharkPath `
    -CandidatePaths @(
        "$env:USERPROFILE\Programme\WiresharkPortable64\App\Wireshark\tshark.exe",
        'C:\Program Files\Wireshark\tshark.exe',
        'C:\Program Files (x86)\Wireshark\tshark.exe'
    )

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
