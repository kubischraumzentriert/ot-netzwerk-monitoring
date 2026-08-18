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

if (-not $TsharkPath -or -not $TsharkPath.Trim()) {
    $candidatePaths = @(
        'C:\Users\Andre\Programme\WiresharkPortable64\App\Wireshark\tshark.exe',
        'C:\Program Files\Wireshark\tshark.exe',
        'C:\Program Files (x86)\Wireshark\tshark.exe'
    )
    foreach ($candidate in $candidatePaths) {
        if (Test-Path -LiteralPath $candidate) {
            $TsharkPath = $candidate
            break
        }
    }
}

if (-not $TsharkPath -or -not (Test-Path -LiteralPath $TsharkPath)) {
    throw "tshark.exe not found. Set -TsharkPath or install Wireshark/tshark."
}

& $TsharkPath -D
