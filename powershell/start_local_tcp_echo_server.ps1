param(
    [string]$BindAddress = '127.0.0.1',
    [int]$Port = 9000,
    [int]$DurationSeconds = 600,
    [string]$ResponseText = 'PONG'
)

$ErrorActionPreference = 'Stop'

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($BindAddress), $Port)
$listener.Start()
$end = (Get-Date).AddSeconds($DurationSeconds)

try {
    while ((Get-Date) -lt $end) {
        if (-not $listener.Pending()) {
            Start-Sleep -Milliseconds 100
            continue
        }

        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $buffer = New-Object byte[] 4096
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            $request = if ($bytesRead -gt 0) {
                [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
            } else {
                ''
            }
            $payload = [System.Text.Encoding]::UTF8.GetBytes("$ResponseText`n$request")
            $stream.Write($payload, 0, $payload.Length)
            $stream.Flush()
        }
        finally {
            $client.Close()
        }
    }
}
finally {
    $listener.Stop()
}

