# PIE ST 누적 저장소 - LAN 공유 서버 (인터넷 불필요)
# - 이 스크립트를 실행 중인 PC의 주소(LAN IP)를 다른 PC들이
#   PIE 설정 > 부품 ST 누적 저장소 > 서버 에 등록하면, 여러 PC가
#   분석한 부품별 표준시간(ST)을 이 PC를 통해 공유 누적할 수 있음.
# - GET  /api/st  -> 현재 누적된 {parts, partSt} JSON 반환
# - POST /api/st  -> 클라이언트가 보낸 {parts, partSt}를 서버가 보관 중인
#                    데이터와 병합(merge) 후 저장, 병합 결과를 반환

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = 8792
$StoreFile = Join-Path $RootDir 'st_store.json'

function Write-EmptyStore {
  '{"parts":[],"partSt":{},"tomb":{},"partTomb":{}}' | Out-File -FilePath $StoreFile -Encoding utf8 -NoNewline
}
if (-not (Test-Path $StoreFile)) { Write-EmptyStore }

# PSCustomObject/hashtable 어느 쪽이든 (키,값) 목록으로 변환
function Get-MapEntries($m) {
  $out = @()
  if ($null -eq $m) { return ,$out }
  if ($m -is [hashtable]) { foreach ($k in @($m.Keys)) { $out += ,@($k, $m[$k]) } }
  else { foreach ($p in $m.PSObject.Properties) { $out += ,@($p.Name, $p.Value) } }
  return ,$out  # 단일 원소여도 배열 형태 유지 (PowerShell 자동 풀림 방지)
}
# {키:시각ISO} 맵을 최신 시각 우선으로 병합 (클라이언트 _stampMerge와 동일 규칙)
function Merge-StampMap($a, $b) {
  $out = @{}
  foreach ($e in (Get-MapEntries $a)) { $out[$e[0]] = $e[1] }
  foreach ($e in (Get-MapEntries $b)) {
    $k = $e[0]; $v = $e[1]
    if (-not $out.ContainsKey($k)) { $out[$k] = $v }
    else {
      $ta = [datetime]::MinValue; $tb = [datetime]::MinValue
      try { $ta = [datetime]$out[$k] } catch {}
      try { $tb = [datetime]$v } catch {}
      if ($tb -gt $ta) { $out[$k] = $v }
    }
  }
  return $out
}

function Select-BetterEntry($a, $b) {
  if ($null -eq $a) { return $b }
  if ($null -eq $b) { return $a }
  $an = if ($a.n) { [double]$a.n } else { 0 }
  $bn = if ($b.n) { [double]$b.n } else { 0 }
  if ($an -ne $bn) { if ($an -gt $bn) { return $a } else { return $b } }
  $at = 0; $bt = 0
  try { $at = [datetime]$a.updatedAt } catch {}
  try { $bt = [datetime]$b.updatedAt } catch {}
  if ($at -ge $bt) { return $a } else { return $b }
}

function Merge-PartStPayload($base, $incoming) {
  if (-not $incoming) { return $base }
  if (-not $base) { return $incoming }

  $mergedParts = New-Object System.Collections.ArrayList
  $nameToId = @{}
  foreach ($p in @($base.parts)) {
    if ($null -eq $p) { continue }
    [void]$mergedParts.Add($p)
    $nameToId[$p.name.ToString().ToLowerInvariant()] = $p.id
  }
  $incIdToMergedId = @{}
  foreach ($p in @($incoming.parts)) {
    if ($null -eq $p) { continue }
    $key = $p.name.ToString().ToLowerInvariant()
    if (-not $nameToId.ContainsKey($key)) {
      [void]$mergedParts.Add($p)
      $nameToId[$key] = $p.id
    }
    $incIdToMergedId[$p.id] = $nameToId[$key]
  }

  $merged = @{}
  if ($base.partSt) {
    foreach ($prop in $base.partSt.PSObject.Properties) {
      $tasks = @{}
      foreach ($tp in $prop.Value.PSObject.Properties) { $tasks[$tp.Name] = $tp.Value }
      $merged[$prop.Name] = $tasks
    }
  }
  if ($incoming.partSt) {
    foreach ($prop in $incoming.partSt.PSObject.Properties) {
      $incPid = $prop.Name
      $mergedPid = if ($incIdToMergedId.ContainsKey($incPid)) { $incIdToMergedId[$incPid] } else { $incPid }
      if (-not $merged.ContainsKey($mergedPid)) { $merged[$mergedPid] = @{} }
      foreach ($tp in $prop.Value.PSObject.Properties) {
        $taskName = $tp.Name
        $cur = $merged[$mergedPid][$taskName]
        $merged[$mergedPid][$taskName] = Select-BetterEntry $cur $tp.Value
      }
    }
  }

  # 삭제 표식(tombstone) 병합·적용 (결정 E, 2026-07-26) — 클라이언트 mergePartStPayload와 동일 규칙:
  # 표식 시각이 항목의 updatedAt 이상이면 삭제된 것으로 간주해 제거. 재생성 항목은 updatedAt이 더 최신이라 살아남는다.
  $tomb = @{}
  foreach ($e in (Get-MapEntries $(if ($base) { $base.tomb } else { $null }))) { $tomb[$e[0]] = Merge-StampMap $null $e[1] }
  foreach ($e in (Get-MapEntries $(if ($incoming) { $incoming.tomb } else { $null }))) {
    $tPid = if ($incIdToMergedId.ContainsKey($e[0])) { $incIdToMergedId[$e[0]] } else { $e[0] }
    $tomb[$tPid] = Merge-StampMap $tomb[$tPid] $e[1]
  }
  $partTomb = Merge-StampMap $(if ($base) { $base.partTomb } else { $null }) $(if ($incoming) { $incoming.partTomb } else { $null })
  foreach ($mPid in @($merged.Keys)) {
    if ($null -eq $merged[$mPid]) { $merged.Remove($mPid); continue }
    foreach ($task in @($merged[$mPid].Keys)) {
      $entry = $merged[$mPid][$task]
      $eT = [datetime]::MinValue
      try { $eT = [datetime]$entry.updatedAt } catch {}
      $tT = $null
      if ($tomb.ContainsKey($mPid) -and $tomb[$mPid].ContainsKey($task)) { try { $tT = [datetime]$tomb[$mPid][$task] } catch {} }
      if ($null -ne $tT -and $tT -ge $eT) { $merged[$mPid].Remove($task) }
    }
    if ($merged[$mPid].Count -eq 0) { $merged.Remove($mPid) }
  }
  $keptParts = New-Object System.Collections.ArrayList
  foreach ($p in $mergedParts) {
    $keyL = $p.name.ToString().ToLowerInvariant()
    $drop = $false
    if ($partTomb.ContainsKey($keyL)) {
      $tT2 = [datetime]::MinValue; $cT = [datetime]::MinValue
      try { $tT2 = [datetime]$partTomb[$keyL] } catch {}
      try { $cT = [datetime]$p.createdAt } catch {}
      if ($tT2 -ge $cT) { $drop = $true }
    }
    if (-not $drop) { [void]$keptParts.Add($p) }
  }
  return [PSCustomObject]@{ parts = $keptParts; partSt = $merged; tomb = $tomb; partTomb = $partTomb }
}

function Get-LanAddresses {
  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } |
    Select-Object -ExpandProperty IPAddress
}

function Start-StListener([string]$prefix) {
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add($prefix)
  $listener.Start()
  return $listener
}

$Prefix = "http://+:$Port/"
$Listener = $null
try {
  $Listener = Start-StListener $Prefix
} catch {
  Write-Host "LAN 주소로 서버를 열려면 최초 1회 관리자 권한이 필요합니다 (URL 등록)."
  Write-Host "관리자 권한으로 등록을 시도합니다 - 확인 창이 뜨면 '예'를 눌러주세요."
  try {
    Start-Process -Verb RunAs -Wait powershell -ArgumentList @(
      '-NoProfile','-Command',
      "netsh http add urlacl url=http://+:$Port/ user=Everyone"
    )
  } catch {
    Write-Host "[경고] 관리자 권한 등록이 취소되었거나 실패했습니다: $_"
  }
  try {
    $Listener = Start-StListener $Prefix
  } catch {
    Write-Host "[정보] LAN 공유 없이 이 PC 전용(로컬)으로만 서버를 실행합니다."
    $Prefix = "http://127.0.0.1:$Port/"
    $Listener = Start-StListener $Prefix
  }
}

Write-Host ""
Write-Host "PIE ST 누적 서버 실행 중 (포트 $Port)"
$lan = Get-LanAddresses
if ($lan) {
  Write-Host "다른 PC에서는 PIE 설정 > ST 누적 저장소 > 서버 에 아래 주소 중 하나를 입력하세요:"
  foreach ($ip in $lan) { Write-Host "  http://$ip`:$Port" }
} else {
  Write-Host "이 PC에서만 사용 가능합니다: http://127.0.0.1:$Port"
}
Write-Host "데이터 파일: $StoreFile"
Write-Host "이 창을 닫으면 서버가 종료됩니다."
Write-Host ""

try {
  while ($Listener.IsListening) {
    $context = $Listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $response.Headers.Add('Access-Control-Allow-Origin', '*')
    $response.Headers.Add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    $response.Headers.Add('Access-Control-Allow-Headers', 'Content-Type')
    try {
      if ($request.HttpMethod -eq 'OPTIONS') {
        $response.StatusCode = 204
      }
      elseif ($request.Url.AbsolutePath -ne '/api/st') {
        $response.StatusCode = 404
        $bytes = [Text.Encoding]::UTF8.GetBytes('404 Not Found')
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      elseif ($request.HttpMethod -eq 'GET') {
        $json = Get-Content -Path $StoreFile -Raw -Encoding UTF8
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $response.ContentType = 'application/json; charset=utf-8'
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      elseif ($request.HttpMethod -eq 'POST') {
        $reader = New-Object System.IO.StreamReader($request.InputStream, [Text.Encoding]::UTF8)
        $bodyText = $reader.ReadToEnd()
        $incoming = $bodyText | ConvertFrom-Json
        $current = $null
        $readFailed = $false
        try { $current = (Get-Content -Path $StoreFile -Raw -Encoding UTF8) | ConvertFrom-Json } catch { $readFailed = $true }
        if ($readFailed) {
          # 파손된 스토어는 조용히 덮어쓰지 않고 백업해 둔다 (누적 데이터 증발 방지)
          $bak = $StoreFile + '.corrupt_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.bak'
          try { Copy-Item -Path $StoreFile -Destination $bak -Force } catch {}
          Write-Host "[경고] st_store.json 판독 실패 - 기존 파일을 백업했습니다: $bak"
        }
        $mergedObj = Merge-PartStPayload $current $incoming
        $mergedJson = $mergedObj | ConvertTo-Json -Depth 20 -Compress
        # 원자적 쓰기: 임시 파일에 완성한 뒤 교체 (쓰기 중 크래시에도 원본 보존)
        $tmpFile = $StoreFile + '.tmp'
        $mergedJson | Out-File -FilePath $tmpFile -Encoding utf8 -NoNewline
        Move-Item -Path $tmpFile -Destination $StoreFile -Force
        $bytes = [Text.Encoding]::UTF8.GetBytes($mergedJson)
        $response.ContentType = 'application/json; charset=utf-8'
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      else {
        $response.StatusCode = 405
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
