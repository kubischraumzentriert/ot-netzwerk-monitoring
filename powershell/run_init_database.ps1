param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RScriptPath = 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe'
)

$ErrorActionPreference = 'Stop'

$script = Join-Path $ProjectRoot 'R\run_init_database.R'

if (-not (Test-Path -LiteralPath $script)) {
    throw "Init script not found: $script"
}

if (-not (Test-Path -LiteralPath $RScriptPath)) {
    throw "Rscript not found: $RScriptPath"
}

if (-not $env:R_LIBS_USER -or -not (Test-Path -LiteralPath $env:R_LIBS_USER)) {
    $env:R_LIBS_USER = Join-Path $env:USERPROFILE 'AppData\Local\R\win-library\4.5'
}

Push-Location $ProjectRoot
try {
    & $RScriptPath $script
}
finally {
    Pop-Location
}
