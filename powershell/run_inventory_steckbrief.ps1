param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$SessionDir = "",
    [string]$OutputFile = ""
)

$ErrorActionPreference = 'Stop'

$rscript = 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe'
$script = Join-Path $ProjectRoot 'R\run_inventory_steckbrief.R'

if (-not (Test-Path -LiteralPath $rscript)) {
    throw "Rscript not found: $rscript"
}

if (-not (Test-Path -LiteralPath $script)) {
    throw "Inventory steckbrief runner not found: $script"
}

$args = @($script)
if ($SessionDir) { $args += "--session=$SessionDir" }
if ($OutputFile) { $args += "--out=$OutputFile" }

Push-Location $ProjectRoot
try {
    & $rscript @args
}
finally {
    Pop-Location
}
