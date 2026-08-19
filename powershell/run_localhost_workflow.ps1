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

$serverScript = Join-Path $ScriptRootPath 'start_local_tcp_echo_server.ps1'
$inventoryScript = Join-Path $ScriptRootPath 'inventory_collect.ps1'
$runnerScript = Join-Path $ProjectRoot 'R\run_localhost_simulation.R'

if (-not (Test-Path -LiteralPath $serverScript)) { throw "Missing server script: $serverScript" }
if (-not (Test-Path -LiteralPath $inventoryScript)) { throw "Missing inventory script: $inventoryScript" }
if (-not (Test-Path -LiteralPath $runnerScript)) { throw "Missing R runner: $runnerScript" }
if (-not $env:R_LIBS_USER -or -not (Test-Path -LiteralPath $env:R_LIBS_USER)) {
    $env:R_LIBS_USER = Join-Path $env:USERPROFILE 'AppData\Local\R\win-library\4.5'
}
if (-not $env:TZ -or -not $env:TZ.Trim()) {
    $env:TZ = 'UTC'
}

if ($DbPath) {
    $env:NETWORK_ANALYSIS_DUCKDB_PATH = $DbPath
}

& (Join-Path $ScriptRootPath 'run_init_database.ps1') -ProjectRoot $ProjectRoot -RScriptPath $RScriptPath -DbPath $DbPath

$server = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $serverScript,
    '-BindAddress', '127.0.0.1',
    '-Port', '9000',
    '-DurationSeconds', '900',
    '-ResponseText', 'PONG'
)

try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $inventoryScript -ProjectRoot $ProjectRoot
    Push-Location $ProjectRoot
    try {
        & $RScriptPath $runnerScript
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
}
