param(
    [string]$ProjectRoot = '',
    [string]$TargetsConfig = '',
    [string]$RunConfig = '',
    [string]$OutputFile = '',
    [string]$RScriptPath = ''
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
if (-not $TargetsConfig -or -not $TargetsConfig.Trim()) {
    $privateTargets = Join-Path $ProjectRoot 'configs\webapp_targets.private.csv'
    $TargetsConfig = if (Test-Path -LiteralPath $privateTargets) { $privateTargets } else { Join-Path $ProjectRoot 'configs\webapp_targets.example.csv' }
}
if (-not $RunConfig -or -not $RunConfig.Trim()) {
    $privateRun = Join-Path $ProjectRoot 'configs\run.webapp.private.csv'
    $RunConfig = if (Test-Path -LiteralPath $privateRun) { $privateRun } else { Join-Path $ProjectRoot 'configs\run.webapp.example.csv' }
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

$script = Join-Path $ProjectRoot 'R\run_webapp_timing.R'
if (-not (Test-Path -LiteralPath $script)) {
    throw "Webapp timing script not found: $script"
}

Push-Location $ProjectRoot
try {
    $args = @(
        $script,
        "--targets=$TargetsConfig",
        "--run=$RunConfig"
    )
    if ($OutputFile -and $OutputFile.Trim()) {
        $args += "--out=$OutputFile"
    }
    & $RScriptPath @args
}
finally {
    Pop-Location
}
