function Get-ToolConfigRows {
    param([string]$ProjectRoot)

    $configPaths = @(
        (Join-Path $ProjectRoot 'configs\tools.private.csv'),
        (Join-Path $ProjectRoot 'configs\tools.csv'),
        (Join-Path $ProjectRoot 'configs\tools.example.csv')
    )

    $rows = @()
    foreach ($path in $configPaths) {
        if (Test-Path -LiteralPath $path) {
            $rows += @(Import-Csv -LiteralPath $path)
        }
    }

    $rows
}

function Resolve-ExistingToolPath {
    param(
        [string]$Path,
        [string]$ProjectRoot
    )

    if (-not $Path -or -not $Path.Trim()) {
        return $null
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim())
    if (-not [System.IO.Path]::IsPathRooted($expanded)) {
        $expanded = Join-Path $ProjectRoot $expanded
    }

    if ($expanded -match '[\*\?]') {
        $matches = @(
            Get-ChildItem -Path $expanded -File -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending
        )
        if ($matches.Count -gt 0) {
            return $matches[0].FullName
        }
        return $null
    }

    if (Test-Path -LiteralPath $expanded -PathType Leaf) {
        return $expanded
    }

    $null
}

function Resolve-ProjectTool {
    param(
        [string]$ProjectRoot,
        [string]$ToolName,
        [string]$ConfigKey,
        [string]$ExplicitPath = '',
        [string[]]$CandidatePaths = @()
    )

    $attempted = New-Object System.Collections.Generic.List[string]

    $resolved = Resolve-ExistingToolPath -Path $ExplicitPath -ProjectRoot $ProjectRoot
    if ($resolved) {
        return $resolved
    }
    if ($ExplicitPath -and $ExplicitPath.Trim()) {
        $attempted.Add("parameter: $ExplicitPath")
    }

    $configRows = Get-ToolConfigRows -ProjectRoot $ProjectRoot
    $configured = @(
        $configRows |
            Where-Object { $_.tool -eq $ConfigKey -or $_.tool -eq $ToolName } |
            ForEach-Object { $_.path }
    )
    foreach ($path in $configured) {
        $resolved = Resolve-ExistingToolPath -Path $path -ProjectRoot $ProjectRoot
        if ($resolved) {
            return $resolved
        }
        if ($path -and $path.Trim()) {
            $attempted.Add("config: $path")
        }
    }

    $cmd = Get-Command $ToolName -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }
    $attempted.Add("PATH: $ToolName")

    foreach ($path in $CandidatePaths) {
        $resolved = Resolve-ExistingToolPath -Path $path -ProjectRoot $ProjectRoot
        if ($resolved) {
            return $resolved
        }
        if ($path -and $path.Trim()) {
            $attempted.Add("candidate: $path")
        }
    }

    $details = if ($attempted.Count) { " Tried: $($attempted -join '; ')." } else { "" }
    throw "$ToolName not found. Set the script parameter or configure configs/tools.private.csv.$details"
}
