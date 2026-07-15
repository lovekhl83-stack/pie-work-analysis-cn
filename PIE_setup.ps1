Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 스크립트 실행 위치 (PIE.html이 있는 폴더)
$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# PIE.html 존재 확인
if (-not (Test-Path (Join-Path $SrcDir 'PIE.html'))) {
    [System.Windows.Forms.MessageBox]::Show(
        "PIE.html 파일을 찾을 수 없습니다.`n`nPIE_설치.bat와 PIE.html이 같은 폴더에 있어야 합니다.`n`n현재 폴더: $SrcDir",
        "오류", "OK", "Error") | Out-Null
    exit 1
}

#region 폼 생성
# 폰트 안전 폴백 (중국/베트남 Windows 대응)
$SafeFont = if ((New-Object System.Drawing.FontFamily("맑은 고딕", $null)).IsStyleAvailable([System.Drawing.FontStyle]::Regular)) { "맑은 고딕" } elseif ((New-Object System.Drawing.FontFamily("Microsoft YaHei", $null)).IsStyleAvailable([System.Drawing.FontStyle]::Regular)) { "Microsoft YaHei" } else { "Arial" }
$form = New-Object System.Windows.Forms.Form
$form.Text = "PIE 설치 / Install / Cài đặt"
$form.Size = New-Object System.Drawing.Size(520, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)

# 제목
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "PIE - Powernet Industrial Engineering"
$lblTitle.Font = New-Object System.Drawing.Font("맑은 고딕", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(96, 165, 250)
$lblTitle.Location = New-Object System.Drawing.Point(20, 18)
$lblTitle.Size = New-Object System.Drawing.Size(470, 30)
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "설치 프로그램 v1.0  |  安装程序  |  Trình cài đặt"
$lblSub.Font = New-Object System.Drawing.Font($SafeFont, 9)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblSub.Location = New-Object System.Drawing.Point(22, 50)
$lblSub.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($lblSub)

# 구분선
$sep = New-Object System.Windows.Forms.Label
$sep.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$sep.Location = New-Object System.Drawing.Point(20, 76)
$sep.Size = New-Object System.Drawing.Size(470, 2)
$form.Controls.Add($sep)

# 설치 위치 레이블
$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "설치 위치 / 安装路径 / Đường dẫn:"
$lblPath.Font = New-Object System.Drawing.Font($SafeFont, 9)
$lblPath.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$lblPath.Location = New-Object System.Drawing.Point(20, 98)
$lblPath.Size = New-Object System.Drawing.Size(80, 22)
$form.Controls.Add($lblPath)

# 설치 경로 텍스트박스
$DefaultInstall = Join-Path $env:LOCALAPPDATA "PIE_WorkAnalysis"
$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Text = $DefaultInstall
$txtPath.Font = New-Object System.Drawing.Font($SafeFont, 9)
$txtPath.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$txtPath.ForeColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
$txtPath.Location = New-Object System.Drawing.Point(20, 122)
$txtPath.Size = New-Object System.Drawing.Size(370, 24)
$txtPath.BorderStyle = "FixedSingle"
$form.Controls.Add($txtPath)

# 찾아보기 버튼
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "찾아보기 / Browse"
$btnBrowse.Font = New-Object System.Drawing.Font($SafeFont, 9)
$btnBrowse.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$btnBrowse.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$btnBrowse.Location = New-Object System.Drawing.Point(400, 121)
$btnBrowse.Size = New-Object System.Drawing.Size(88, 26)
$form.Controls.Add($btnBrowse)

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "설치 폴더를 선택하세요"
    $dlg.SelectedPath = $txtPath.Text
    if ($dlg.ShowDialog() -eq "OK") {
        $txtPath.Text = Join-Path $dlg.SelectedPath "PIE_WorkAnalysis"
    }
})

# 옵션 체크박스
$chkDesktop = New-Object System.Windows.Forms.CheckBox
$chkDesktop.Text = "바탕화면 바로가기 / 桌面快捷方式 / Lối tắt màn hình"
$chkDesktop.Font = New-Object System.Drawing.Font($SafeFont, 9)
$chkDesktop.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
$chkDesktop.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$chkDesktop.Location = New-Object System.Drawing.Point(20, 162)
$chkDesktop.Size = New-Object System.Drawing.Size(220, 22)
$chkDesktop.Checked = $true
$form.Controls.Add($chkDesktop)

$chkStartMenu = New-Object System.Windows.Forms.CheckBox
$chkStartMenu.Text = "시작 메뉴 / 开始菜单 / Menu bắt đầu"
$chkStartMenu.Font = New-Object System.Drawing.Font($SafeFont, 9)
$chkStartMenu.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
$chkStartMenu.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$chkStartMenu.Location = New-Object System.Drawing.Point(250, 162)
$chkStartMenu.Size = New-Object System.Drawing.Size(200, 22)
$chkStartMenu.Checked = $true
$form.Controls.Add($chkStartMenu)

# 진행 상태 레이블
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = ""
$lblStatus.Font = New-Object System.Drawing.Font($SafeFont, 9)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(74, 222, 128)
$lblStatus.Location = New-Object System.Drawing.Point(20, 270)
$lblStatus.Size = New-Object System.Drawing.Size(470, 22)
$form.Controls.Add($lblStatus)

# 진행 바
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 296)
$progress.Size = New-Object System.Drawing.Size(470, 14)
$progress.Style = "Continuous"
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$form.Controls.Add($progress)

# 하단 구분선
$sep2 = New-Object System.Windows.Forms.Label
$sep2.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$sep2.Location = New-Object System.Drawing.Point(20, 320)
$sep2.Size = New-Object System.Drawing.Size(470, 2)
$form.Controls.Add($sep2)

# 설치 버튼
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "설치 / Install / Cài đặt"
$btnInstall.Font = New-Object System.Drawing.Font($SafeFont, 10, [System.Drawing.FontStyle]::Bold)
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnInstall.ForeColor = [System.Drawing.Color]::White
$btnInstall.FlatStyle = "Flat"
$btnInstall.FlatAppearance.BorderSize = 0
$btnInstall.Location = New-Object System.Drawing.Point(20, 336)
$btnInstall.Size = New-Object System.Drawing.Size(220, 36)
$form.Controls.Add($btnInstall)

# 취소 버튼
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "취소 / Cancel / Hủy"
$btnCancel.Font = New-Object System.Drawing.Font($SafeFont, 10)
$btnCancel.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$btnCancel.FlatStyle = "Flat"
$btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$btnCancel.Location = New-Object System.Drawing.Point(270, 336)
$btnCancel.Size = New-Object System.Drawing.Size(220, 36)
$form.Controls.Add($btnCancel)

$btnCancel.Add_Click({ $form.Close() })

# 설치 버튼 동작
$btnInstall.Add_Click({
    $InstallPath = $txtPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($InstallPath)) {
        [System.Windows.Forms.MessageBox]::Show("설치 경로를 입력하세요.", "알림", "OK", "Warning") | Out-Null
        return
    }

    $btnInstall.Enabled = $false
    $btnCancel.Enabled = $false
    $btnBrowse.Enabled = $false

    try {
        # 1. 폴더 생성
        $lblStatus.Text = "[1/5] 설치 폴더 생성 중..."
        $form.Refresh()
        if (-not (Test-Path $InstallPath)) { New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null }
        $progress.Value = 20

        # 2. 파일 복사
        $lblStatus.Text = "[2/5] PIE.html 복사 중..."
        $form.Refresh()
        Copy-Item (Join-Path $SrcDir 'PIE.html') (Join-Path $InstallPath 'PIE.html') -Force
        $progress.Value = 40

        # 3. 제거 프로그램 복사
        $lblStatus.Text = "[3/5] 제거 프로그램 복사 중..."
        $form.Refresh()
        $uninstSrc = Join-Path $SrcDir 'PIE_제거.bat'
        if (Test-Path $uninstSrc) {
            Copy-Item $uninstSrc (Join-Path $InstallPath 'PIE_제거.bat') -Force
        }
        $progress.Value = 60

        # 4. 바탕화면 바로가기
        if ($chkDesktop.Checked) {
            $lblStatus.Text = "[4/5] 바탕화면 바로가기 생성 중..."
            $form.Refresh()
            $ws = New-Object -ComObject WScript.Shell
            $lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'PIE 작업분석.lnk'
            $lnk = $ws.CreateShortcut($lnkPath)
            $lnk.TargetPath = Join-Path $InstallPath 'PIE.html'
            $lnk.Description = 'PIE - Powernet Industrial Engineering'
            $lnk.Save()
        }
        $progress.Value = 75

        # 5. 시작 메뉴
        if ($chkStartMenu.Checked) {
            $lblStatus.Text = "[5/5] 시작 메뉴 등록 중..."
            $form.Refresh()
            $smDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\PIE'
            if (-not (Test-Path $smDir)) { New-Item -ItemType Directory -Path $smDir -Force | Out-Null }
            $ws2 = New-Object -ComObject WScript.Shell
            $lnk2 = $ws2.CreateShortcut("$smDir\PIE 작업분석.lnk")
            $lnk2.TargetPath = Join-Path $InstallPath 'PIE.html'
            $lnk2.Save()
            # 제거 바로가기
            $uninstLnk = $ws2.CreateShortcut("$smDir\PIE 제거.lnk")
            $uninstLnk.TargetPath = Join-Path $InstallPath 'PIE_제거.bat'
            $uninstLnk.Save()
        }
        $progress.Value = 90

        # 6. 레지스트리 등록
        $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PIE_WorkAnalysis'
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name 'DisplayName'     -Value 'PIE - Powernet Industrial Engineering'
        Set-ItemProperty -Path $regPath -Name 'DisplayVersion'  -Value '1.0'
        Set-ItemProperty -Path $regPath -Name 'Publisher'       -Value 'Powernet'
        Set-ItemProperty -Path $regPath -Name 'InstallLocation' -Value $InstallPath
        Set-ItemProperty -Path $regPath -Name 'UninstallString' -Value (Join-Path $InstallPath 'PIE_제거.bat')
        Set-ItemProperty -Path $regPath -Name 'NoModify'        -Value 1 -Type DWord
        Set-ItemProperty -Path $regPath -Name 'NoRepair'        -Value 1 -Type DWord
        $progress.Value = 100

        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(74, 222, 128)
        $lblStatus.Text = "설치 완료!"

        $result = [System.Windows.Forms.MessageBox]::Show(
            "PIE 설치가 완료되었습니다. / Installation complete! / Cài đặt hoàn tất!`n`n설치 위치 / Install path: $InstallPath`n`n지금 PIE를 실행하시겠습니까? / Launch PIE now?",
            "설치 완료 / Install Complete", "YesNo", "Information")
        if ($result -eq "Yes") {
            Start-Process (Join-Path $InstallPath 'PIE.html')
        }
        $form.Close()
    }
    catch {
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(248, 113, 113)
        $lblStatus.Text = "오류: $_"
        [System.Windows.Forms.MessageBox]::Show("설치 중 오류가 발생했습니다.`n`n$_", "오류", "OK", "Error") | Out-Null
        $btnInstall.Enabled = $true
        $btnCancel.Enabled = $true
        $btnBrowse.Enabled = $true
    }
})

#endregion

[void]$form.ShowDialog()