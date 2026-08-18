[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BackupRoot = '',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Remove-DirectoryContentsExcept {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string[]]$KeepNames = @('.gitkeep')
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-ChildItem -LiteralPath $Path -Force | Where-Object {
        $KeepNames -notcontains $_.Name
    } | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return 0
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    $items = Get-ChildItem -LiteralPath $Source -Force
    foreach ($item in $items) {
        Copy-Item -LiteralPath $item.FullName -Destination $Destination -Recurse -Force
    }

    return $items.Count
}

function Ensure-KeepFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType File -Force -Path $Path | Out-Null
    }
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $BackupRoot) {
    $BackupRoot = Join-Path $ProjectRoot 'data\backups'
}

$rawRoot = Join-Path $ProjectRoot 'data\raw'
$processedRoot = Join-Path $ProjectRoot 'data\processed'
$reportsRoot = Join-Path $ProjectRoot 'reports'

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $BackupRoot ("{0}_Databackup" -f $timestamp)
$copyTargets = @(
    @{ Source = $rawRoot; Destination = (Join-Path $backupDir 'data\raw') },
    @{ Source = $processedRoot; Destination = (Join-Path $backupDir 'data\processed') },
    @{ Source = $reportsRoot; Destination = (Join-Path $backupDir 'reports') }
)

if ($WhatIf.IsPresent) {
    Write-Host "WhatIf: would archive $ProjectRoot to $backupDir and reset data/raw, data/processed, reports."
    return
}

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

foreach ($target in $copyTargets) {
    [void](Copy-DirectoryContents -Source $target.Source -Destination $target.Destination)
}

Remove-DirectoryContentsExcept -Path $rawRoot
Remove-DirectoryContentsExcept -Path $processedRoot
Remove-DirectoryContentsExcept -Path $reportsRoot

Ensure-KeepFile -Path (Join-Path $rawRoot '.gitkeep')
Ensure-KeepFile -Path (Join-Path $processedRoot '.gitkeep')
Ensure-KeepFile -Path (Join-Path $reportsRoot '.gitkeep')
Ensure-KeepFile -Path (Join-Path $ProjectRoot 'data\backups\.gitkeep')

@(
    "Backup created at: $backupDir"
    "Source root: $ProjectRoot"
    "Contains: data/raw, data/processed, reports"
) | Set-Content -LiteralPath (Join-Path $backupDir 'manifest.txt') -Encoding UTF8

Write-Host "Backup created at $backupDir"
