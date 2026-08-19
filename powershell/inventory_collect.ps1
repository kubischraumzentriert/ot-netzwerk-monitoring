param(
    [string]$ProjectRoot = '',
    [string]$OutputDir,
    [string]$RefreshArpCidr = '',
    [int]$RefreshArpTimeoutMilliseconds = 250,
    [int]$RefreshArpDelayMilliseconds = 20
)

$ErrorActionPreference = 'Stop'

# ipconfig/netsh/arp/netstat/route are legacy console tools that write their
# output in the system's OEM codepage (Control Panel > Region > "Language
# for non-Unicode programs"), not in PowerShell's default encoding. Without
# this, PowerShell decodes the captured bytes incorrectly and replaces
# non-ASCII characters (e.g. German umlauts) with U+FFFD before the text
# ever reaches Out-File -Encoding utf8 -- by then the original bytes are
# already lost. Reading the true OEM codepage from the registry keeps this
# correct for any locale, not just German.
try {
    $oemCodePage = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage').OEMCP
    [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding([int]$oemCodePage)
} catch {
    Write-Warning "Could not set console output encoding to the system OEM codepage: $($_.Exception.Message)"
}

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}

if (-not $OutputDir -or -not $OutputDir.Trim()) {
    $OutputDir = Join-Path $ProjectRoot 'data\raw\inventory'
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sessionDir = Join-Path $OutputDir $timestamp
New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null

$hostInfo = [ordered]@{
    collected_at = (Get-Date).ToString('o')
    computer_name = $env:COMPUTERNAME
    user_name = $env:USERNAME
    os_version = [System.Environment]::OSVersion.VersionString
    ps_version = $PSVersionTable.PSVersion.ToString()
}
$hostInfo.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ key = $_.Key; value = $_.Value }
} | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $sessionDir 'host_info.csv')

ipconfig /all | Out-File -FilePath (Join-Path $sessionDir 'ipconfig_all.txt') -Encoding utf8
netsh interface show interface | Out-File -FilePath (Join-Path $sessionDir 'netsh_interfaces.txt') -Encoding utf8

if ($RefreshArpCidr -and $RefreshArpCidr.Trim()) {
    $refreshScript = Join-Path $ScriptRootPath 'refresh_arp_cache.ps1'
    if (-not (Test-Path -LiteralPath $refreshScript)) {
        throw "ARP refresh script not found: $refreshScript"
    }
    & $refreshScript `
        -ProjectRoot $ProjectRoot `
        -NetworkCidr $RefreshArpCidr `
        -OutputDir (Join-Path $sessionDir 'arp_refresh') `
        -TimeoutMilliseconds $RefreshArpTimeoutMilliseconds `
        -DelayMilliseconds $RefreshArpDelayMilliseconds
}

arp -a | Out-File -FilePath (Join-Path $sessionDir 'arp_a.txt') -Encoding utf8
netstat -ano | Out-File -FilePath (Join-Path $sessionDir 'netstat_ano.txt') -Encoding utf8
route print | Out-File -FilePath (Join-Path $sessionDir 'route_print.txt') -Encoding utf8

Write-Host "Inventory written to $sessionDir"

