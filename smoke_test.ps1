param(
    [int]$Port = 8010
)

$ErrorActionPreference = "Stop"

# Test Case 1: Texto claro (needs_clarification = false)
$test_case_1 = [pscustomobject]@{
    name = "Caso A: Texto Claro"
    text = "La Universidad organizará una reunión el 10 de abril de 2026 en el auditorio principal. María López coordinará el evento y se solicitará confirmar asistencia antes del 5 de abril."
    domain = "universidad"
}

# Test Case 2: Texto ambiguo (needs_clarification = true)
$test_case_2 = [pscustomobject]@{
    name = "Caso B: Texto Ambiguo"
    text = "Hay una reunión la próxima semana para revisar el proyecto. Necesitamos decidir el lugar y quién presentará."
    domain = "universidad"
}

$proc = $null
try {
    Write-Host "🚀 Iniciando servidor FastAPI en puerto $Port..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "python" -ArgumentList @("-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "$Port") -PassThru -WindowStyle Hidden

    $baseUrl = "http://127.0.0.1:$Port"
    $ready = $false

    Write-Host "⏳ Esperando que el servidor inicie..." -ForegroundColor Yellow
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

    Write-Host "✅ Servidor listo. Ejecutando pruebas..." -ForegroundColor Green
    Write-Host ""

    # Test Case 1
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host $test_case_1.name -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    
    $payload1 = $test_case_1 | Select-Object -Property text, domain | ConvertTo-Json -Compress
    Write-Host "Request:" -ForegroundColor Yellow
    Write-Host $payload1 | ConvertFrom-Json | ConvertTo-Json -Depth 2
    Write-Host ""
    
    $response1 = Invoke-RestMethod -Uri "$baseUrl/extract" -Method POST -ContentType "application/json" -Body $payload1
    Write-Host "Response:" -ForegroundColor Yellow
    $response1 | ConvertTo-Json -Depth 8
    
    $check1 = if ($response1.needs_clarification -eq $false) {
        Write-Host "✅ CORRECTO: needs_clarification = false" -ForegroundColor Green
    } else {
        Write-Host "❌ ERROR: Se esperaba needs_clarification = false" -ForegroundColor Red
    }
    Write-Host ""

    # Test Case 2
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host $test_case_2.name -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    
    $payload2 = $test_case_2 | Select-Object -Property text, domain | ConvertTo-Json -Compress
    Write-Host "Request:" -ForegroundColor Yellow
    Write-Host $payload2 | ConvertFrom-Json | ConvertTo-Json -Depth 2
    Write-Host ""
    
    $response2 = Invoke-RestMethod -Uri "$baseUrl/extract" -Method POST -ContentType "application/json" -Body $payload2
    Write-Host "Response:" -ForegroundColor Yellow
    $response2 | ConvertTo-Json -Depth 8
    
    if ($response2.needs_clarification -eq $true) {
        Write-Host "✅ CORRECTO: needs_clarification = true" -ForegroundColor Green
        if ($response2.clarifying_questions.Count -ge 2) {
            Write-Host "✅ CORRECTO: Al menos 2 preguntas clarificadoras" -ForegroundColor Green
        } else {
            Write-Host "❌ ERROR: Se esperaban al menos 2 preguntas clarificadoras" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ ERROR: Se esperaba needs_clarification = true" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "✨ Pruebas completadas" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
}
finally {
    if ($proc -and -not $proc.HasExited) {
        Write-Host "🛑 Deteniendo servidor..." -ForegroundColor Yellow
        Stop-Process -Id $proc.Id -Force
    }
}
