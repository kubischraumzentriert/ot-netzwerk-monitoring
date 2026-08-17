param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RScriptPath = 'C:\Program Files\R\R-4.5.3\bin\Rscript.exe'
)

$ErrorActionPreference = 'Stop'

$serverScript = Join-Path $PSScriptRoot 'start_local_tcp_echo_server.ps1'
$inventoryScript = Join-Path $PSScriptRoot 'inventory_collect.ps1'
$runnerScript = Join-Path $ProjectRoot 'R\run_localhost_simulation.R'

if (-not (Test-Path -LiteralPath $serverScript)) { throw "Missing server script: $serverScript" }
if (-not (Test-Path -LiteralPath $inventoryScript)) { throw "Missing inventory script: $inventoryScript" }
if (-not (Test-Path -LiteralPath $runnerScript)) { throw "Missing R runner: $runnerScript" }
if (-not (Test-Path -LiteralPath $RScriptPath)) { throw "Missing Rscript: $RScriptPath" }

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
