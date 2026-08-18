param(
    [string]$ProjectRoot = '',
    [string]$TargetsConfig = '',
    [string]$RunConfig = '',
    [string]$RScriptPath = ''
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
if (-not $TargetsConfig -or -not $TargetsConfig.Trim()) {
    $TargetsConfig = if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'configs\targets.private.csv')) { Join-Path $ProjectRoot 'configs\targets.private.csv' } else { Join-Path $ProjectRoot 'configs\targets.csv' }
}
if (-not $RunConfig -or -not $RunConfig.Trim()) {
    $RunConfig = Join-Path $ProjectRoot 'configs\run.csv'
}

. (Join-Path $ScriptRootPath 'resolve_tool_path.ps1')
$rscript = Resolve-ProjectTool `
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

$script = Join-Path $ProjectRoot 'R\run_benchmark.R'

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
