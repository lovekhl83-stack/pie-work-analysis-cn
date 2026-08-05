# PIE 로컬 정적 서버 (인터넷 불필요)
# - PIE.html을 file:// 대신 http://127.0.0.1 로 열어서
#   MediaPipe(Pose) 등 fetch() 기반 로컬 자산 로딩이 브라우저 file:// 제한에 막히지 않도록 함.
# - Node/Python 등 별도 설치 없이 Windows 기본 PowerShell만으로 동작.

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = 8791

$MimeMap = @{
  '.html'   = 'text/html; charset=utf-8'
  '.htm'    = 'text/html; charset=utf-8'
  '.js'     = 'application/javascript; charset=utf-8'
  '.mjs'    = 'application/javascript; charset=utf-8'
  '.css'    = 'text/css; charset=utf-8'
  '.json'   = 'application/json; charset=utf-8'
  '.wasm'   = 'application/wasm'
  '.tflite' = 'application/octet-stream'
  '.data'   = 'application/octet-stream'
  '.binarypb' = 'application/octet-stream'
  '.png'    = 'image/png'
  '.jpg'    = 'image/jpeg'
  '.jpeg'   = 'image/jpeg'
  '.svg'    = 'image/svg+xml'
  '.ico'    = 'image/x-icon'
  '.pie'    = 'application/json'
}

function Test-PortFree([int]$p) {
  try {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
    $listener.Start(); $listener.Stop()
    return $true
  } catch { return $false }
}

function Get-FreePort([int]$Preferred) {
  for ($p = $Preferred; $p -lt ($Preferred + 20); $p++) {
    if (Test-PortFree $p) { return $p }
  }
  return $Preferred
}

# 8791을 이미 쓰고 있는 것이 우리 PIE 서버인지 확인한다.
# (구버전 서버에도 통하도록 /__pie 표식이 없으면 PIE.html 내용으로 판별)
function Test-PieServer([int]$p) {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$p/__pie" -UseBasicParsing -TimeoutSec 3
    if ($r.StatusCode -eq 200 -and "$($r.Content)".StartsWith('PIE')) { return $true }
  } catch {}
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$p/PIE.html" -UseBasicParsing -TimeoutSec 8
    if ($r.StatusCode -eq 200 -and "$($r.Content)" -like '*Powernet Industrial Engineering*') { return $true }
  } catch {}
  return $false
}

# ⚠ 브라우저는 데이터(부품 목록·표준시간·설정)를 "주소별"로 따로 저장한다.
#   포트가 바뀌면 저장해 둔 내용이 통째로 안 보인다. 그래서 8791을 최대한 고정한다.
if (-not (Test-PortFree $Port)) {
  if (Test-PieServer $Port) {
    Write-Host ""
    Write-Host " 이미 실행 중인 PIE 서버가 있어 그대로 사용합니다: http://127.0.0.1:$Port/"
    Write-Host " (저장된 부품·표준시간 데이터를 유지하려면 항상 같은 주소로 열어야 합니다)"
    Write-Host ""
    Start-Process ("http://127.0.0.1:$Port/PIE.html")
    exit 0
  }
  Write-Host ""
  Write-Host " [경고] $Port 포트를 다른 프로그램이 쓰고 있습니다."
  Write-Host "        다른 포트로 열면 저장해 둔 부품 목록과 표준시간이 보이지 않습니다."
  Write-Host "        그 프로그램을 종료한 뒤 PIE를 다시 실행하는 것을 권장합니다."
  Write-Host ""
  $Port = Get-FreePort -Preferred 8801   # ST 공유 서버(8792)와 겹치지 않는 대역
}

$Prefix = "http://127.0.0.1:$Port/"

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add($Prefix)
try {
  $Listener.Start()
} catch {
  Write-Host "[오류] 로컬 서버 시작 실패: $_"
  Read-Host "Enter 키를 누르면 종료합니다"
  exit 1
}

Write-Host "PIE 로컬 서버 실행 중: $Prefix"
Write-Host "이 창을 닫으면 서버가 종료됩니다."
Start-Process ($Prefix + "PIE.html")

try {
  while ($Listener.IsListening) {
    $context = $Listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    try {
      $relPath = [Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
      if ([string]::IsNullOrWhiteSpace($relPath)) { $relPath = 'PIE.html' }

      # 실행기가 "이 포트에 이미 PIE 서버가 떠 있는지" 싸게 확인하는 표식
      if ($relPath -eq '__pie') {
        $response.ContentType = 'text/plain; charset=utf-8'
        $bytes = [Text.Encoding]::UTF8.GetBytes("PIE local server")
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        continue   # 스트림 닫기는 아래 finally 가 처리한다
      }

      $filePath = Join-Path $RootDir $relPath

      $fullRoot = (Resolve-Path $RootDir).Path
      $fullFile = [System.IO.Path]::GetFullPath($filePath)
      if (-not $fullFile.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $filePath -PathType Leaf)) {
        $response.StatusCode = 404
        $bytes = [Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
        $mime = $MimeMap[$ext]
        if (-not $mime) { $mime = 'application/octet-stream' }
        $response.ContentType = $mime
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
    } catch {
      try {
        $response.StatusCode = 500
        $bytes = [Text.Encoding]::UTF8.GetBytes("500 Server Error: $_")
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      } catch {}
    } finally {
      $response.OutputStream.Close()
    }
  }
} finally {
  $Listener.Stop()
  $Listener.Close()
}
