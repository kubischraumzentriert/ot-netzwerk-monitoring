param(
    [Parameter(Mandatory = $true)]
    [string]$NetworkCidr,
    [string]$ProjectRoot = '',
    [string]$OutputDir,
    [int]$TimeoutMilliseconds = 250,
    [int]$DelayMilliseconds = 20,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}

function Get-IPv4HostsFrom24 {
    param([string]$Cidr)

    if ($Cidr -notmatch '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/24$') {
        throw "Only IPv4 /24 CIDR ranges are supported, for example 192.0.2.0/24."
    }

    $octets = @(
        [int]$Matches[1],
        [int]$Matches[2],
        [int]$Matches[3],
        [int]$Matches[4]
    )

    if (($octets | Where-Object { $_ -lt 0 -or $_ -gt 255 }).Count -gt 0) {
        throw "Invalid IPv4 range: $Cidr"
    }

    $prefix = "$($octets[0]).$($octets[1]).$($octets[2])"
    1..254 | ForEach-Object { "$prefix.$_" }
}

function Convert-ArpTextToRows {
    param([string[]]$Lines)

    $currentInterface = ''
    foreach ($line in $Lines) {
        if ($line -match '^\s*Interface:\s+(.+?)\s+---\s+(.+?)\s*$') {
            $currentInterface = $Matches[1]
            continue
        }

        if ($line -match '^\s*(?<ip>(?:\d{1,3}\.){3}\d{1,3})\s+(?<mac>[0-9A-Fa-f]{2}(?:-[0-9A-Fa-f]{2}){5})\s+(?<type>\S+)\s*$') {
            [pscustomobject]@{
                interface = $currentInterface
                ip        = $Matches.ip
                mac       = $Matches.mac.ToLowerInvariant()
                type      = $Matches.type
            }
        }
    }
}

if ($TimeoutMilliseconds -lt 100) {
    throw "TimeoutMilliseconds must be at least 100."
}

if ($DelayMilliseconds -lt 0) {
    throw "DelayMilliseconds must not be negative."
}

$targets = @(Get-IPv4HostsFrom24 -Cidr $NetworkCidr)

if (-not $OutputDir -or -not $OutputDir.Trim()) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $OutputDir = Join-Path $ProjectRoot "data\raw\inventory\arp_refresh\$stamp"
}

if ($WhatIf) {
    Write-Host "Would ping $($targets.Count) hosts in $NetworkCidr."
    Write-Host "Would write ARP refresh output to $OutputDir."
    return
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

arp -a | Out-File -FilePath (Join-Path $OutputDir 'arp_before.txt') -Encoding utf8

$rows = foreach ($target in $targets) {
    $startedAt = Get-Date
    $pingOutput = & ping.exe -n 1 -w $TimeoutMilliseconds $target 2>&1
    $elapsedMs = [math]::Round(((Get-Date) - $startedAt).TotalMilliseconds, 1)
    $text = ($pingOutput -join "`n")
    $success = ($LASTEXITCODE -eq 0) -and ($text -match 'TTL=')

    [pscustomobject]@{
        ts         = (Get-Date).ToString('o')
        target     = $target
        success    = [bool]$success
        elapsed_ms = $elapsedMs
        detail     = $text
    }

    if ($DelayMilliseconds -gt 0) {
        Start-Sleep -Milliseconds $DelayMilliseconds
    }
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutputDir 'ping_sweep.csv')

$arpAfter = @(arp -a)
$arpAfter | Out-File -FilePath (Join-Path $OutputDir 'arp_after.txt') -Encoding utf8

$arpRows = @(Convert-ArpTextToRows -Lines $arpAfter)
if ($arpRows.Count -gt 0) {
    $arpRows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutputDir 'arp_after.csv')
} else {
    '"interface","ip","mac","type"' | Out-File -FilePath (Join-Path $OutputDir 'arp_after.csv') -Encoding utf8
}

Write-Host "ARP refresh written to $OutputDir"
