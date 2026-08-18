[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BackupPath = '',
    [string]$BackupRoot = '',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

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

if (-not $BackupPath) {
    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        throw "Backup root not found: $BackupRoot"
    }

    $latest = Get-ChildItem -LiteralPath $BackupRoot -Directory |
        Where-Object { $_.Name -match '^\d{8}_\d{6}_Databackup$' } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw "No backup folder found in: $BackupRoot"
    }

    $BackupPath = $latest.FullName
} else {
    if (-not (Test-Path -LiteralPath $BackupPath)) {
        throw "Backup path not found: $BackupPath"
    }
}

$rawRoot = Join-Path $ProjectRoot 'data\raw'
$processedRoot = Join-Path $ProjectRoot 'data\processed'
$reportsRoot = Join-Path $ProjectRoot 'reports'

$restoreMap = @(
    @{ Source = (Join-Path $BackupPath 'data\raw'); Destination = $rawRoot },
    @{ Source = (Join-Path $BackupPath 'data\processed'); Destination = $processedRoot },
    @{ Source = (Join-Path $BackupPath 'reports'); Destination = $reportsRoot }
)

if ($WhatIf.IsPresent) {
    Write-Host "WhatIf: would restore $ProjectRoot from $BackupPath and replace data/raw, data/processed, reports."
    return
}

Remove-DirectoryContentsExcept -Path $rawRoot
Remove-DirectoryContentsExcept -Path $processedRoot
Remove-DirectoryContentsExcept -Path $reportsRoot

foreach ($entry in $restoreMap) {
    if (Test-Path -LiteralPath $entry.Source) {
        [void](Copy-DirectoryContents -Source $entry.Source -Destination $entry.Destination)
    }
}

Ensure-KeepFile -Path (Join-Path $rawRoot '.gitkeep')
Ensure-KeepFile -Path (Join-Path $processedRoot '.gitkeep')
Ensure-KeepFile -Path (Join-Path $reportsRoot '.gitkeep')

Write-Host "Restored backup from $BackupPath"
