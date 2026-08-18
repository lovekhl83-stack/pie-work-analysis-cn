# PIE USB 배포용 묶기
# - 실행에 꼭 필요한 파일만 골라 ZIP 하나로 만든다.
# - .git / BOM / 작업문서처럼 배포하면 안 되거나 필요 없는 것은 제외한다.
# - 프로그램이 실행 중이어도(파일 "사용 중") 공유 읽기로 복사하므로 막히지 않는다.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 담을 것 ──────────────────────────────────────────────────────────────
# 실행 필수
$Must = @(
  'PIE.html',
  'PIE(중국).bat',
  'PIE_local_server.ps1'
)
# 같이 넣으면 좋은 것 (없으면 조용히 건너뜀)
$Nice = @(
  'PIE_사양확인.bat',
  'PIE_사양확인.ps1',
  'README.md',
  'PIE_가이드.html',
  'PIE_가이드_한국어.pptx',
  'PIE_가이드_中文.pptx',
  'PIE_가이드_TiengViet.pptx',
  'PIE_ST_server.ps1',
  'PIE_ST_server_시작.bat',
  'PIE_setup.ps1',
  'PIE_설치.bat',
  'PIE_uninstall.ps1',
  'PIE_제거.bat'
)
# 폴더 통째로 (Pose 기능에 반드시 필요)
$Folders = @('mediapipe')

# ⚠ 절대 담지 않는 것 — BOM 은 회사 기밀, .git 은 수천 개 파일이라 USB 복사가 막히는 원인
$NeverFolders = @('.git', '.github', '.claude', 'BOM', 'node_modules')
$NeverFiles   = @('st_store.json', 'CLAUDE.md', 'WORKLOG.md', 'PROJECT_OVERVIEW.md',
                  'PROGRAM_BRIEF.md', 'tools_make_ppt.py', 'download.html',
                  'PIE_USB_묶기.ps1', 'PIE_USB_묶기.bat')

# ── 저장 위치: 바탕화면 (USB로 끌어다 놓기 쉽게) ──────────────────────────
$Stamp   = Get-Date -Format 'yyyyMMdd'
$ZipName = "PIE_배포_$Stamp.zip"
$Desktop = [Environment]::GetFolderPath('Desktop')
$ZipPath = Join-Path $Desktop $ZipName

Write-Host ''
Write-Host ' PIE USB 배포용 묶기' -ForegroundColor Cyan
Write-Host ' ─────────────────────────────────────────────'

# 사용 중이어도 읽히도록 공유 읽기로 연다
function Read-SharedBytes([string]$path) {
  $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  try {
    $buf = New-Object byte[] $fs.Length
    $off = 0
    while ($off -lt $buf.Length) {
      $n = $fs.Read($buf, $off, $buf.Length - $off)
      if ($n -le 0) { break }
      $off += $n
    }
    return $buf
  } finally { $fs.Dispose() }
}

# 담을 파일 목록 만들기
$Items = @()   # @{ Rel; Full }
foreach ($f in ($Must + $Nice)) {
  $p = Join-Path $Root $f
  if (Test-Path $p -PathType Leaf) { $Items += @{ Rel = $f; Full = $p } }
  elseif ($Must -contains $f) { Write-Host " [오류] 필수 파일이 없습니다: $f" -ForegroundColor Red; Read-Host ' Enter'; exit 1 }
}
foreach ($d in $Folders) {
  $dp = Join-Path $Root $d
  if (-not (Test-Path $dp -PathType Container)) { continue }
  Get-ChildItem $dp -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
    $top = ($rel -split '\\')[0]
    if ($NeverFolders -contains $top) { return }
    $Items += @{ Rel = $rel; Full = $_.FullName }
  }
}
$Items = $Items | Where-Object { $NeverFiles -notcontains $_.Rel }

# USB에서 바로 읽을 안내문 (압축 안에 같이 넣는다)
$Readme = @"
PIE (중국) — USB 배포본
=========================================

■ 설치 방법 (복사해서 붙여넣기만 하면 됩니다)
  1) 이 ZIP 파일을 PC의 "진짜 로컬 디스크"(예: D:\PIE 또는 바탕화면)에 풀어 주세요.
     ※ USB에서 바로 실행하지 마세요.
     ※ 문서중앙화·클라우드 드라이브(Cloudium, OneDrive, 네트워크 드라이브)에
        두지 마세요. 그런 드라이브는 실행 파일을 막습니다. (아래 참고)
  2) 폴더 안의  PIE(중국).bat  을 더블클릭합니다.
  3) 검은 창이 뜨고 브라우저가 자동으로 열립니다.
     검은 창은 프로그램 본체입니다 — 끄면 종료됩니다.

■ "[.bat]와 같은 실행 파일의 동작은 지원하지 않습니다" 라는 오류가 뜨면
  회사 보안 프로그램(Cloudium 등)이 그 드라이브에서 실행 파일을 막은 것입니다.
  프로그램 문제가 아니라 "폴더를 둔 위치" 문제입니다.

  1순위) 폴더를 C: 또는 D: 로컬 디스크(예: D:\PIE)로 옮긴 뒤 다시 실행
  2순위) 그래도 막히면 .bat 없이 실행하는 방법:
         PIE_local_server.ps1 을 마우스 오른쪽 클릭 → "PowerShell에서 실행"
  3순위) 그래도 안 되면 PIE.html 을 그냥 더블클릭
         (대부분 기능은 되지만 자세 비교(Pose) 기능은 동작하지 않습니다)

■ 프로그램이 안 켜지거나 화면이 이상하면 — 먼저 이것부터
  PIE_사양확인.bat  을 더블클릭하세요.
  이 PC가 PIE 를 돌릴 수 있는지 한글로 알려 주고,
  결과를 바탕화면에 텍스트 파일로 저장합니다. 그 파일을 담당자에게 보내 주세요.

■ 라이선스 키
  처음 실행하면 키를 넣으라는 화면이 나옵니다.
  키는 이 압축본에 들어 있지 않습니다. 담당자에게 따로 받으세요.

■ 사용 설명서
  PIE_가이드.html          (브라우저로 열기 · 한국어/中文/Tiếng Việt 전환)
  PIE_가이드_한국어.pptx    (파워포인트)
  PIE_가이드_中文.pptx
  PIE_가이드_TiengViet.pptx

■ 주의
  · 폴더 안의 파일을 빼거나 옮기지 마세요. mediapipe 폴더가 없으면
    자세 비교(Pose) 기능이 동작하지 않습니다.
  · 인터넷 연결이 필요 없습니다.
  · Chrome 또는 Edge 브라우저가 필요합니다.

문의: lovekhl83@gmail.com
"@

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
$zipStream = [System.IO.File]::Open($ZipPath, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  $total = 0
  foreach ($it in $Items) {
    $entry = $zip.CreateEntry($it.Rel, [System.IO.Compression.CompressionLevel]::Optimal)
    $bytes = Read-SharedBytes $it.Full
    $es = $entry.Open()
    try { $es.Write($bytes, 0, $bytes.Length) } finally { $es.Dispose() }
    $total += $bytes.Length
    "{0,-46} {1,8:N0} KB" -f $it.Rel, ($bytes.Length / 1KB) | Write-Host
  }
  # 안내문 추가
  $entry = $zip.CreateEntry('사용법_먼저읽기.txt', [System.IO.Compression.CompressionLevel]::Optimal)
  $es = $entry.Open()
  try {
    $enc = New-Object System.Text.UTF8Encoding($true)   # 메모장에서 안 깨지도록 BOM 포함
    $b = $enc.GetBytes($Readme)
    $es.Write($b, 0, $b.Length)
  } finally { $es.Dispose() }
} finally {
  $zip.Dispose(); $zipStream.Dispose()
}

$zipSize = (Get-Item $ZipPath).Length
Write-Host ' ─────────────────────────────────────────────'
Write-Host (" 파일 {0}개 · 원본 {1:N1} MB → 압축 {2:N1} MB" -f ($Items.Count + 1), ($total/1MB), ($zipSize/1MB)) -ForegroundColor Green
Write-Host ''
Write-Host " 만들어진 파일:" -ForegroundColor Cyan
Write-Host "   $ZipPath"
Write-Host ''
Write-Host ' 이 ZIP 하나만 USB로 끌어다 놓으면 됩니다.' -ForegroundColor Yellow
Write-Host ' (BOM 폴더·작업 문서·.git 은 담기지 않았습니다)'
Write-Host ''
Read-Host ' Enter 키를 누르면 닫힙니다'
