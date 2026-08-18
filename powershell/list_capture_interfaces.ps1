param(
    [string]$ProjectRoot = '',
    [string]$TsharkPath
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
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

& $TsharkPath -D
