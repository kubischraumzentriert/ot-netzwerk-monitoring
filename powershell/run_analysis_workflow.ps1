param(
    [string]$ProjectRoot = '',
    [string]$NmapPath = ''
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}

& (Join-Path $ScriptRootPath 'run_nmap_scan.ps1') -ProjectRoot $ProjectRoot -NmapPath $NmapPath

