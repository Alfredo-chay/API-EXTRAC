param(
    [int]$Port = 8010
)

$ErrorActionPreference = "Stop"

$payload = [pscustomobject]@{
    text = "Juan Perez se reunio con Acme Corp el 3 de abril en Bogota para firmar contrato."
    domain = "legal"
}
$json = $payload | ConvertTo-Json -Compress

$proc = $null
try {
    $proc = Start-Process -FilePath "python" -ArgumentList @("-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "$Port") -PassThru -WindowStyle Hidden

    $baseUrl = "http://127.0.0.1:$Port"
    $ready = $false

    for ($i = 0; $i -lt 30; $i++) {
        try {
            Invoke-WebRequest -Uri "$baseUrl/docs" -UseBasicParsing | Out-Null
            $ready = $true
            break
        } catch {
            Start-Sleep -Milliseconds 300
        }
    }

    if (-not $ready) {
        throw "El servidor no inicio a tiempo en el puerto $Port."
    }

    $response = Invoke-RestMethod -Uri "$baseUrl/extract" -Method POST -ContentType "application/json" -Body $json
    $response | ConvertTo-Json -Depth 8
}
finally {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force
    }
}
