param(
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

& $TsharkPath -D

