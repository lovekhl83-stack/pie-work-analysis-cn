Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PIE_WorkAnalysis'
$installDir = $null
if (Test-Path $regPath) {
    $installDir = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).InstallLocation
}
if (-not $installDir) { $installDir = Join-Path $env:LOCALAPPDATA 'PIE_WorkAnalysis' }

$nl = [Environment]::NewLine
$msg = 'PIE를 제거하시겠습니까?' + $nl + 'Uninstall PIE?' + $nl + $nl +
        '제거 항목:' + $nl +
        '  - 설치 폴더: ' + $installDir + $nl +
        '  - 바탕화면 바로가기' + $nl +
        '  - 시작 메뉴' + $nl + $nl +
        '사용자 데이터(LocalStorage)는 삭제되지 않습니다.'

$result = [System.Windows.Forms.MessageBox]::Show($msg, 'PIE 제거',
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($result -ne 'Yes') { exit 0 }

$desk = [Environment]::GetFolderPath('Desktop')
foreach ($name in @('PIE 작업분석.lnk', 'PIE 작업분析.lnk')) {
    $p = Join-Path $desk $name
    if (Test-Path $p) { $null = Remove-Item $p -Force -ErrorAction SilentlyContinue }
}

$smDir = Join-Path ([Environment]::GetFolderPath('Programs')) 'PIE'
if (Test-Path $smDir) { $null = Remove-Item $smDir -Recurse -Force -ErrorAction SilentlyContinue }

if (Test-Path $regPath) { $null = Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue }

if (Test-Path $installDir) { $null = Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue }

$done = 'PIE가 성공적으로 제거되었습니다.' + $nl + $nl + '사용해 주셔서 감사합니다.'
[System.Windows.Forms.MessageBox]::Show($done, '제거 완료',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null