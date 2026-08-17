param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$rscript = 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe'
$script = Join-Path $ProjectRoot 'R\run_benchmark_comparison.R'

if (-not (Test-Path -LiteralPath $rscript)) {
    throw "Rscript not found: $rscript"
}

if (-not (Test-Path -LiteralPath $script)) {
    throw "Benchmark comparison runner not found: $script"
}

Push-Location $ProjectRoot
try {
    & $rscript $script
}
finally {
    Pop-Location
}
