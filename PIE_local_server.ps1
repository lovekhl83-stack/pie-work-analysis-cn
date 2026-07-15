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

function Get-FreePort([int]$Preferred) {
  for ($p = $Preferred; $p -lt ($Preferred + 20); $p++) {
    $inUse = $false
    try {
      $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
      $listener.Start(); $listener.Stop()
    } catch { $inUse = $true }
    if (-not $inUse) { return $p }
  }
  return $Preferred
}

$Port = Get-FreePort -Preferred $Port
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
