param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$TargetsConfig = (Join-Path $ProjectRoot 'configs\targets.csv'),
    [string]$RunConfig = (Join-Path $ProjectRoot 'configs\run.csv')
)

$rscript = 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe'
$script = Join-Path $ProjectRoot 'R\run_benchmark.R'

if (-not (Test-Path -LiteralPath $rscript)) {
    throw "Rscript not found: $rscript"
}

if (-not (Test-Path -LiteralPath $script)) {
    throw "Benchmark script not found: $script"
}

Push-Location $ProjectRoot
try {
    & $rscript $script "--targets=$TargetsConfig" "--run=$RunConfig"
}
finally {
    Pop-Location
}
