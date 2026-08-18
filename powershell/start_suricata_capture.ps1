param(
    [string]$ProjectRoot = '',
    [string]$InterfaceName,
    [string]$ConfigPath,
    [string]$LogDir = '',
    [int]$DurationSeconds = 300,
    [string]$SuricataPath,
    [string]$RulesPath
)

$ErrorActionPreference = 'Stop'

$ScriptRootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ProjectRoot -or -not $ProjectRoot.Trim()) {
    $ProjectRoot = Split-Path -Parent $ScriptRootPath
}
if (-not $LogDir -or -not $LogDir.Trim()) {
    $LogDir = Join-Path $ProjectRoot 'data\raw\suricata'
}

. (Join-Path $ScriptRootPath 'resolve_tool_path.ps1')
$SuricataPath = Resolve-ProjectTool `
    -ProjectRoot $ProjectRoot `
    -ToolName 'suricata' `
    -ConfigKey 'suricata' `
    -ExplicitPath $SuricataPath `
    -CandidatePaths @(
        'C:\Program Files\Suricata\suricata.exe',
        'C:\Program Files (x86)\Suricata\suricata.exe'
    )

if (-not $InterfaceName -or -not $InterfaceName.Trim()) {
    throw "Please provide -InterfaceName."
}

if (-not $ConfigPath -or -not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Suricata config not found: $ConfigPath"
}

if ($RulesPath -and -not (Test-Path -LiteralPath $RulesPath)) {
    throw "Suricata rules file not found: $RulesPath"
}

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logPrefix = Join-Path $LogDir $stamp
$null = New-Item -ItemType Directory -Path $logPrefix -Force
$stdoutPath = Join-Path $LogDir "$stamp`_stdout.txt"
$stderrPath = Join-Path $LogDir "$stamp`_stderr.txt"

if ($RulesPath) {
    $argumentLine = "--pcap=`"$InterfaceName`" -c `"$ConfigPath`" -l `"$logPrefix`" -S `"$RulesPath`""
} else {
    $argumentLine = "--pcap=`"$InterfaceName`" -c `"$ConfigPath`" -l `"$logPrefix`""
}
$proc = Start-Process -FilePath $SuricataPath -ArgumentList $argumentLine -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

Start-Sleep -Seconds $DurationSeconds
if ($proc.HasExited) {
    Write-Host "Suricata exited early with code $($proc.ExitCode). Check $stderrPath for details."
}
if (-not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
}
