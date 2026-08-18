param(
    [string]$ProjectRoot = '',
    [string]$RScriptPath = '',
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs = @()
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

$ResolvedScriptPath = if ([System.IO.Path]::IsPathRooted($ScriptPath)) {
    $ScriptPath
} else {
    Join-Path $ProjectRoot $ScriptPath
}

if (-not (Test-Path -LiteralPath $ResolvedScriptPath -PathType Leaf)) {
    throw "R script not found: $ResolvedScriptPath"
}

Push-Location $ProjectRoot
try {
    & $RScriptPath $ResolvedScriptPath @ScriptArgs
}
finally {
    Pop-Location
}
