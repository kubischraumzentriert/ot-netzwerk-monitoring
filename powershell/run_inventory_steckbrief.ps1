param(
    [string]$ProjectRoot = '',
    [string]$SessionDir = "",
    [string]$OutputFile = "",
    [string]$RScriptPath = ''
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
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
$script = Join-Path $ProjectRoot 'R\run_inventory_steckbrief.R'

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
