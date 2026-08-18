param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$InterfaceName,
    [string]$ConfigPath,
    [string]$LogDir = (Join-Path $ProjectRoot 'data\raw\suricata'),
    [int]$DurationSeconds = 300,
    [string]$SuricataPath,
    [string]$RulesPath
)

$ErrorActionPreference = 'Stop'

if (-not $SuricataPath -or -not $SuricataPath.Trim()) {
    $cmd = Get-Command suricata -ErrorAction SilentlyContinue
    if ($cmd) {
        $SuricataPath = $cmd.Source
    }
}

if (-not $SuricataPath -or -not $SuricataPath.Trim()) {
    $candidatePaths = @(
        'C:\Program Files\Suricata\suricata.exe',
        'C:\Program Files (x86)\Suricata\suricata.exe'
    )
    foreach ($candidate in $candidatePaths) {
        if (Test-Path -LiteralPath $candidate) {
            $SuricataPath = $candidate
            break
        }
    }
}

if (-not $SuricataPath -or -not (Test-Path -LiteralPath $SuricataPath)) {
    throw "suricata.exe not found. Set -SuricataPath or install Suricata."
}

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
