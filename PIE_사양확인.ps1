# PIE 실행 환경 점검 — 구형 윈도우(7/8.1)에서도 돌아가도록 PowerShell 2.0 문법만 쓴다.
#  · Get-CimInstance / Get-NetTCPConnection / [pscustomobject] 같은 신형 문법 금지
#  · 결과를 화면에 한글로 보여 주고, 바탕화면에 텍스트로도 남긴다

$ErrorActionPreference = 'SilentlyContinue'
$LinesOut = New-Object System.Collections.ArrayList

function Say($text, $color) {
  if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Host $text }
  [void]$LinesOut.Add($text)
}
function Row($name, $value, $verdict, $color) {
  $pad = $name
  while ($pad.Length -lt 20) { $pad = $pad + ' ' }
  $line = '  ' + $pad + $value
  if ($verdict) { $line = $line + '   ' + $verdict }
  Say $line $color
}

$OK = 'Green'; $WARN = 'Yellow'; $NG = 'Red'; $INFO = 'Gray'
$problems = 0
$warns = 0

Say ''
Say ' ============================================================'
Say '  PIE 실행 환경 점검'
Say ('  ' + (Get-Date).ToString('yyyy-MM-dd HH:mm') + '   컴퓨터: ' + $env:COMPUTERNAME)
Say ' ============================================================'
Say ''

# ── 1. 윈도우 ─────────────────────────────────────────────
Say ' [1] 윈도우' 'Cyan'
$os = Get-WmiObject Win32_OperatingSystem
$cs = Get-WmiObject Win32_ComputerSystem
$osVer = $os.Version
$bit = $os.OSArchitecture
if (-not $bit) { if ([IntPtr]::Size -eq 8) { $bit = '64비트' } else { $bit = '32비트' } }
$major = 0
try { $major = [int]($osVer.Split('.')[0]) } catch { }

if ($major -lt 6) {
  Row '버전' ($os.Caption + ' (' + $osVer + ')') '✗ 너무 오래됨 - 동작 불가' $NG; $problems++
} elseif ($osVer -like '6.1*') {
  Row '버전' ($os.Caption + ' (' + $osVer + ')') '△ 윈도우7 - 브라우저 확인 필수' $WARN; $warns++
} elseif ($osVer -like '6.2*' -or $osVer -like '6.3*') {
  Row '버전' ($os.Caption + ' (' + $osVer + ')') '△ 윈도우8 - 브라우저 확인 필수' $WARN; $warns++
} else {
  Row '버전' ($os.Caption + ' (' + $osVer + ')') '✓ 문제 없음' $OK
}
Row '비트' $bit '' $INFO
Say ''

# ── 2. PowerShell ─────────────────────────────────────────
Say ' [2] PowerShell (프로그램 실행에 사용)' 'Cyan'
$psv = $PSVersionTable.PSVersion.ToString()
if ($PSVersionTable.PSVersion.Major -ge 3) {
  Row '버전' $psv '✓ 문제 없음' $OK
} else {
  Row '버전' $psv '△ 2.0 - 3.0 이상 권장' $WARN; $warns++
}
$polBlocked = $false
foreach ($scope in @('MachinePolicy','UserPolicy')) {
  $p = Get-ExecutionPolicy -Scope $scope
  if ($p -and $p -ne 'Undefined' -and $p -ne 'Bypass' -and $p -ne 'Unrestricted') { $polBlocked = $true }
  Row ('정책(' + $scope + ')') $p '' $INFO
}
if ($polBlocked) {
  Row '판정' '회사 정책으로 차단됨' '✗ 전산팀 문의 필요' $NG; $problems++
} else {
  Row '판정' '차단 없음' '✓ 문제 없음' $OK
}
Say ''

# ── 3. 브라우저 (가장 중요) ───────────────────────────────
Say ' [3] 브라우저  <-- 가장 중요' 'Cyan'
function BrowserVersion($paths) {
  foreach ($p in $paths) {
    if ($p -and (Test-Path $p)) {
      $fi = Get-Item $p
      return $fi.VersionInfo.ProductVersion
    }
  }
  return ''
}
$pf = $env:ProgramFiles
$px = ${env:ProgramFiles(x86)}
$la = $env:LOCALAPPDATA
$chromeVer = BrowserVersion @(($pf + '\Google\Chrome\Application\chrome.exe'), ($px + '\Google\Chrome\Application\chrome.exe'), ($la + '\Google\Chrome\Application\chrome.exe'))
$edgeVer   = BrowserVersion @(($px + '\Microsoft\Edge\Application\msedge.exe'), ($pf + '\Microsoft\Edge\Application\msedge.exe'))

function MajorOf($ver) {
  if ($ver) { try { return [int]($ver.Split('.')[0]) } catch { return 0 } }
  return 0
}
$cm = MajorOf $chromeVer
$em = MajorOf $edgeVer
$best = $cm
if ($em -gt $best) { $best = $em }

if ($chromeVer) { Row 'Chrome' $chromeVer '' $INFO } else { Row 'Chrome' '설치 안 됨' '' $INFO }
if ($edgeVer)   { Row 'Edge'   $edgeVer   '' $INFO } else { Row 'Edge'   '설치 안 됨 (또는 구형 Edge)' '' $INFO }

if ($best -eq 0) {
  Row '판정' '최신 브라우저 없음' '✗ 동작 불가 - Chrome 설치 필요' $NG; $problems++
} elseif ($best -lt 80) {
  Row '판정' ('최고 버전 ' + $best) '✗ 너무 낮음 - 동작 불가' $NG; $problems++
} elseif ($best -lt 90) {
  Row '판정' ('최고 버전 ' + $best) '△ 일부 기능 제한 가능' $WARN; $warns++
} else {
  Row '판정' ('최고 버전 ' + $best) '✓ 문제 없음' $OK
}
$defBrowser = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice').ProgId
if (-not $defBrowser) { $defBrowser = '확인 불가' }
Row '기본 브라우저' $defBrowser '' $INFO
Say ''

# ── 4. 로컬 서버 ──────────────────────────────────────────
Say ' [4] 로컬 서버 (PIE 는 8791 포트를 씁니다)' 'Cyan'
$ns = netstat -ano 2>$null | Select-String ':8791 '
if ($ns) {
  Row '8791 포트' '이미 사용 중' '△ PIE 가 이미 켜져 있을 수 있음' $WARN
} else {
  Row '8791 포트' '비어 있음' '✓ 문제 없음' $OK
}
$bindOk = $false
$bindErr = ''
try {
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add('http://127.0.0.1:8799/')
  $listener.Start()
  $bindOk = $true
  $listener.Stop()
  $listener.Close()
} catch { $bindErr = $_.Exception.Message }
if ($bindOk) {
  Row '서버 열기' '성공' '✓ 관리자 권한 없이 가능' $OK
} else {
  Row '서버 열기' ('실패 - ' + $bindErr) '✗ 전산팀 문의 필요' $NG; $problems++
}
Say ''

# ── 5. 폴더 위치 (문서보안 드라이브 여부) ─────────────────
Say ' [5] 이 폴더의 위치' 'Cyan'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Row '폴더' $here '' $INFO
$drv = ''
try { $drv = Split-Path -Qualifier $here } catch { }
$dtype = ''
if ($drv) {
  $ld = Get-WmiObject Win32_LogicalDisk -Filter ("DeviceID='" + $drv + "'")
  if ($ld) {
    $dt = [int]$ld.DriveType
    if ($dt -eq 2) { $dtype = 'USB/이동식' }
    elseif ($dt -eq 3) { $dtype = '로컬 디스크' }
    elseif ($dt -eq 4) { $dtype = '네트워크 드라이브' }
    elseif ($dt -eq 5) { $dtype = 'CD/DVD' }
    else { $dtype = '기타' }
  }
}
if ($dtype -eq '로컬 디스크') {
  Row '드라이브' ($drv + ' ' + $dtype) '✓ 문제 없음' $OK
} elseif ($dtype) {
  Row '드라이브' ($drv + ' ' + $dtype) '✗ C: 또는 D: 로 옮기세요' $NG; $problems++
} else {
  Row '드라이브' '확인 불가' '△ 로컬 디스크 권장' $WARN; $warns++
}
Say ''

# ── 6. 성능 ───────────────────────────────────────────────
Say ' [6] 성능 (영상 분석 속도에 영향)' 'Cyan'
$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
if ($cpu) { Row 'CPU' ($cpu.Name + '  (' + $cpu.NumberOfLogicalProcessors + '스레드)') '' $INFO }
$ramGB = 0
if ($cs) { $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1) }
if ($ramGB -lt 4) { Row '메모리' ($ramGB.ToString() + ' GB') '✗ 4GB 미만 - 매우 느림' $NG; $problems++ }
elseif ($ramGB -lt 8) { Row '메모리' ($ramGB.ToString() + ' GB') '△ 8GB 권장' $WARN; $warns++ }
else { Row '메모리' ($ramGB.ToString() + ' GB') '✓ 문제 없음' $OK }

$sys = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
if ($sys) {
  $freeGB = [math]::Round($sys.FreeSpace / 1GB, 1)
  if ($freeGB -lt 2) { Row 'C: 여유공간' ($freeGB.ToString() + ' GB') '✗ 부족' $NG; $problems++ }
  else { Row 'C: 여유공간' ($freeGB.ToString() + ' GB') '✓ 문제 없음' $OK }
}
$vc = Get-WmiObject Win32_VideoController | Select-Object -First 1
if ($vc -and $vc.CurrentHorizontalResolution) {
  $res = $vc.CurrentHorizontalResolution.ToString() + ' x ' + $vc.CurrentVerticalResolution.ToString()
  if ([int]$vc.CurrentHorizontalResolution -lt 1280) {
    Row '화면 해상도' $res '△ 좁음 - 1280 이상 권장' $WARN; $warns++
  } else {
    Row '화면 해상도' $res '✓ 문제 없음' $OK
  }
}
Say ''

# ── 종합 판정 ─────────────────────────────────────────────
Say ' ============================================================'
if ($problems -gt 0) {
  Say ('  판정 :  실행 불가 항목 ' + $problems + '건 · 주의 ' + $warns + '건') $NG
  Say '          위에서 [X] 표시된 항목을 먼저 해결해야 합니다.' $NG
} elseif ($warns -gt 0) {
  Say ('  판정 :  실행 가능 (주의 ' + $warns + '건)') $WARN
  Say '          [△] 항목은 확인해 보시면 좋습니다.' $WARN
} else {
  Say '  판정 :  모두 정상 - PIE 를 바로 쓰실 수 있습니다.' $OK
}
Say ' ============================================================'
Say ''

# ── 결과 파일로 저장 ──────────────────────────────────────
$desk = [Environment]::GetFolderPath('Desktop')
$outFile = Join-Path $desk ('PIE_사양확인_' + $env:COMPUTERNAME + '_' + (Get-Date).ToString('yyyyMMdd_HHmm') + '.txt')
$clean = @()
foreach ($l in $LinesOut) { $clean += $l }
$clean | Out-File -FilePath $outFile -Encoding UTF8
Write-Host ' 결과를 파일로 저장했습니다:' -ForegroundColor Cyan
Write-Host ('   ' + $outFile)
Write-Host ''
Write-Host ' 이 파일을 담당자에게 보내 주시면 됩니다.' -ForegroundColor Cyan
Write-Host ''
Read-Host ' Enter 키를 누르면 닫힙니다'
