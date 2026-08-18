param(
    [string]$ProjectRoot = '',
    [string]$RScriptPath = '',
    [string]$DbPath = ''
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
. (Join-Path $ScriptRootPath 'resolve_tool_path.ps1')
$RScriptPath = Resolve-ProjectTool `
    -ProjectRoot $ProjectRoot `
    -ToolName 'Rscript' `
    -ConfigKey 'rscript' `
    -ExplicitPath $RScriptPath `
    -CandidatePaths @(
        "$env:USERPROFILE\Programme\R\R-*\bin\Rscript.exe",
        "$env:USERPROFILE\Programme\R\R-*\bin\x64\Rscript.exe",
        'C:\Program Files\R\R-*\bin\Rscript.exe',
        'C:\Program Files\R\R-*\bin\x64\Rscript.exe'
    )

$script = Join-Path $ProjectRoot 'R\run_init_database.R'

if (-not (Test-Path -LiteralPath $script)) {
    throw "Init script not found: $script"
}

if (-not $env:R_LIBS_USER -or -not (Test-Path -LiteralPath $env:R_LIBS_USER)) {
    $env:R_LIBS_USER = Join-Path $env:USERPROFILE 'AppData\Local\R\win-library\4.5'
}

if ($DbPath) {
    $env:NETWORK_ANALYSIS_DUCKDB_PATH = $DbPath
}

Push-Location $ProjectRoot
try {
    $args = @()
    if ($DbPath) {
        $args += "--db=$DbPath"
    }
    & $RScriptPath $script @args
}
finally {
    Pop-Location
}
