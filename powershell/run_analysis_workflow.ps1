param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

& (Join-Path $PSScriptRoot 'run_nmap_scan.ps1') -ProjectRoot $ProjectRoot

