# ==============================================================================
# WinSux - One-Click Automated Windows Optimizer
# Repository-Independent | Native Software Management
# ==============================================================================

# SCRIPT RUN AS ADMIN
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "WinSux - Automated Windows Optimizer (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

# Load Core AppHelper if available
$helperLocations = @(
    (Join-Path $PSScriptRoot "..\Core\AppHelper.ps1"),
    (Join-Path $PSScriptRoot "Core\AppHelper.ps1"),
    (Join-Path (Get-Location).Path "Core\AppHelper.ps1"),
    (Join-Path "$env:SystemRoot\Temp" "AppHelper.ps1")
)
foreach ($loc in $helperLocations) {
    if (Test-Path $loc) {
        . $loc
        break
    }
}

# SCRIPT CHECK INTERNET
$hasNet = $false
if (Get-Command Test-InternetConnection -ErrorAction SilentlyContinue) {
    $hasNet = Test-InternetConnection
} else {
    $hasNet = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
}
if (-not $hasNet) {
    Write-Host "Internet Connection Required`n" -ForegroundColor Red
    Pause
    exit
}

# SCRIPT SILENT
$progresspreference = 'silentlycontinue'

Write-Host "Preparing WinSux workspace files..." -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Prepare WinSux local files (Local-First resolution)
# ------------------------------------------------------------------------------
$filesToCopy = @("reg.reg", "settimerresolutionservice.cs", "start2.txt", "stepone.ps1", "steptwo.ps1")
$searchDirs = @($PSScriptRoot, (Join-Path $PSScriptRoot "WinSux"), (Get-Location).Path)

foreach ($f in $filesToCopy) {
    $found = $false
    foreach ($d in $searchDirs) {
        if ($d -and (Test-Path (Join-Path $d $f))) {
            Copy-Item -Path (Join-Path $d $f) -Destination "$env:SystemRoot\Temp\$f" -Force -ErrorAction SilentlyContinue
            $found = $true
            break
        }
    }
    # If not found locally, and repo base url is set, download from repo base
    if (-not $found -and $Global:RepoBaseUrl) {
        $downloadUrl = "$($Global:RepoBaseUrl.TrimEnd('/'))/WinSux/$f"
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile "$env:SystemRoot\Temp\$f" -UseBasicParsing -ErrorAction SilentlyContinue
        } catch {}
    }
}

# ------------------------------------------------------------------------------
# 2. 7-Zip Native Installation
# ------------------------------------------------------------------------------
Write-Host "7-Zip..." -ForegroundColor Cyan
if (Get-Command Install-7ZipNative -ErrorAction SilentlyContinue) {
    Install-7ZipNative
} else {
    if (-not (Test-Path "$env:SystemDrive\Program Files\7-Zip\7z.exe")) {
        $sevenZipUrl = "https://www.7-zip.org/a/7z2409-x64.exe"
        Invoke-WebRequest -Uri $sevenZipUrl -OutFile "$env:SystemRoot\Temp\7zip.exe" -UseBasicParsing
        Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"
        Remove-Item "$env:SystemRoot\Temp\7zip.exe" -Force -ErrorAction SilentlyContinue
    }
    cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"
    cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
    Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

# ------------------------------------------------------------------------------
# 3. Microsoft Visual C++ Redistributables (Official Microsoft CDNs)
# ------------------------------------------------------------------------------
Write-Host "Visual C++ Redistributables (2005 - 2022)..." -ForegroundColor Cyan
if (Get-Command Install-VCRedistAllNative -ErrorAction SilentlyContinue) {
    Install-VCRedistAllNative
} else {
    $vcPackages = @(
        @{ Name = "vcredist2005_x86"; Url = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"; Args = "/Q /C:`"msiexec /i vcredist.msi /qn /norestart`"" },
        @{ Name = "vcredist2005_x64"; Url = "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE"; Args = "/Q /C:`"msiexec /i vcredist.msi /qn /norestart`"" },
        @{ Name = "vcredist2008_x86"; Url = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"; Args = "/q" },
        @{ Name = "vcredist2008_x64"; Url = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"; Args = "/q" },
        @{ Name = "vcredist2010_x86"; Url = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2010_x64"; Url = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2012_x86"; Url = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2012_x64"; Url = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2013_x86"; Url = "https://aka.ms/highdpimfc2013x86enu"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2013_x64"; Url = "https://aka.ms/highdpimfc2013x64enu"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2015_2022_x86"; Url = "https://aka.ms/vc14/vc_redist.x86.exe"; Args = "/quiet /norestart" },
        @{ Name = "vcredist2015_2022_x64"; Url = "https://aka.ms/vc14/vc_redist.x64.exe"; Args = "/quiet /norestart" }
    )
    foreach ($pkg in $vcPackages) {
        $outFile = "$env:SystemRoot\Temp\$($pkg.Name).exe"
        try {
            Invoke-WebRequest -Uri $pkg.Url -OutFile $outFile -UseBasicParsing -ErrorAction SilentlyContinue
            Start-Process -FilePath $outFile -ArgumentList $pkg.Args -Wait -WindowStyle Hidden
            Remove-Item $outFile -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

# ------------------------------------------------------------------------------
# 4. Display Driver Uninstaller (DDU Native)
# ------------------------------------------------------------------------------
Write-Host "Display Driver Uninstaller (DDU)..." -ForegroundColor Cyan
if (Get-Command Install-DDUNative -ErrorAction SilentlyContinue) {
    Install-DDUNative -Destination "$env:SystemRoot\Temp\ddu"
} else {
    $dduSetup = "$env:SystemRoot\Temp\ddu.exe"
    $dduUrl = "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.5.3_setup.exe"
    try {
        Invoke-WebRequest -Uri $dduUrl -OutFile $dduSetup -UseBasicParsing
    } catch {
        Invoke-WebRequest -Uri "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.5.3.exe" -OutFile $dduSetup -UseBasicParsing
    }
    & "$env:SystemDrive\Program Files\7-Zip\7z.exe" x $dduSetup -o"$env:SystemRoot\Temp\ddu" -y | Out-Null
    Remove-Item $dduSetup -Force -ErrorAction SilentlyContinue

    $DduConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.5.3">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<RemoveMonitors>True</RemoveMonitors>
		<RemoveCrimsonCache>True</RemoveCrimsonCache>
		<RemoveAMDDirs>True</RemoveAMDDirs>
		<RemoveAudioBus>True</RemoveAudioBus>
		<RemoveAMDKMPFD>True</RemoveAMDKMPFD>
		<RemoveNvidiaDirs>True</RemoveNvidiaDirs>
		<RemovePhysX>True</RemovePhysX>
		<Remove3DTVPlay>True</Remove3DTVPlay>
		<RemoveGFE>True</RemoveGFE>
		<RemoveNVBROADCAST>True</RemoveNVBROADCAST>
		<RemoveNVCP>True</RemoveNVCP>
		<RemoveINTELCP>True</RemoveINTELCP>
		<RemoveINTELIGS>True</RemoveINTELIGS>
		<RemoveOneAPI>True</RemoveOneAPI>
		<RemoveEnduranceGaming>True</RemoveEnduranceGaming>
		<RemoveIntelNpu>True</RemoveIntelNpu>
		<RemoveAMDCP>True</RemoveAMDCP>
		<UseRoamingConfig>False</UseRoamingConfig>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>False</SaveLogs>
		<RemoveVulkan>True</RemoveVulkan>
		<ShowOffer>False</ShowOffer>
		<EnableSafeModeDialog>False</EnableSafeModeDialog>
		<PreventWinUpdate>True</PreventWinUpdate>
		<UsedBCD>False</UsedBCD>
		<KeepNVCPopt>False</KeepNVCPopt>
		<RememberLastChoice>False</RememberLastChoice>
		<LastSelectedGPUIndex>0</LastSelectedGPUIndex>
		<LastSelectedTypeIndex>0</LastSelectedTypeIndex>
	</Settings>
</DisplayDriverUninstaller>
'@
    $settingsFolder = "$env:SystemRoot\Temp\ddu\Settings"
    if (-not (Test-Path $settingsFolder)) { New-Item -Path $settingsFolder -ItemType Directory -Force | Out-Null }
    Set-Content -Path "$settingsFolder\Settings.xml" -Value $DduConfig -Force
    Set-ItemProperty -Path "$settingsFolder\Settings.xml" -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
}

# Prevent downloads of drivers from Windows Update
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`" /v `"SearchOrderConfig`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# ------------------------------------------------------------------------------
# 5. Helium Browser Native Installation
# ------------------------------------------------------------------------------
Write-Host "Helium Browser..." -ForegroundColor Cyan
if (Get-Command Install-HeliumNative -ErrorAction SilentlyContinue) {
    Install-HeliumNative
} else {
    $heliumUrl = "https://github.com/imputnet/helium-windows/releases/download/0.19.2.1/helium_0.19.2.1_x64-installer.exe"
    $heliumOut = "$env:SystemRoot\Temp\helium.exe"
    try {
        Invoke-WebRequest -Uri $heliumUrl -OutFile $heliumOut -UseBasicParsing
        Start-Process -Wait $heliumOut -ArgumentList "/S" -WindowStyle Hidden
        Remove-Item $heliumOut -Force -ErrorAction SilentlyContinue
    } catch {}

    cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"HardwareAccelerationModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
    cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"BackgroundModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
    cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"HighEfficiencyModeEnabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

    $basePath = "HKLM:\Software\Microsoft\Active Setup\Installed Components"
    Get-ChildItem $basePath -ErrorAction SilentlyContinue | ForEach-Object {
        $val = (Get-ItemProperty $_.PsPath)."(default)"
        if ($val -like "*Helium*") {
            Remove-Item $_.PsPath -Force -ErrorAction SilentlyContinue
        }
    }

    Get-Service | Where-Object { $_.Name -match 'Helium' } | ForEach-Object {
        cmd /c "sc stop `"$($_.Name)`" >nul 2>&1"
        cmd /c "sc delete `"$($_.Name)`" >nul 2>&1"
    }

    Get-ScheduledTask | Where-Object { $_.TaskName -like '*Helium*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Helium.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
}

# ------------------------------------------------------------------------------
# 6. DirectX End-User Runtimes Native Installation (Microsoft Official)
# ------------------------------------------------------------------------------
Write-Host "DirectX End-User Runtimes..." -ForegroundColor Cyan
if (Get-Command Install-DirectXNative -ErrorAction SilentlyContinue) {
    Install-DirectXNative
} else {
    $dxUrl = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    $dxOut = "$env:SystemRoot\Temp\directx.exe"
    $dxDir = "$env:SystemRoot\Temp\directx"
    try {
        Invoke-WebRequest -Uri $dxUrl -OutFile $dxOut -UseBasicParsing
        & "$env:SystemDrive\Program Files\7-Zip\7z.exe" x $dxOut -o"$dxDir" -y | Out-Null
        Start-Process -Wait "$dxDir\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden
        Remove-Item $dxOut -Force -ErrorAction SilentlyContinue
        Remove-Item $dxDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------------------------
# 7. Remove Preinstalled UWP Bloatware
# ------------------------------------------------------------------------------
Write-Host "Removing UWP Bloatware..." -ForegroundColor Cyan
Get-AppXPackage -AllUsers | Where-Object {
    $_.Name -notlike '*CBS*' -and
    $_.Name -notlike '*Microsoft.AV1VideoExtension*' -and
    $_.Name -notlike '*Microsoft.AVCEncoderVideoExtension*' -and
    $_.Name -notlike '*Microsoft.HEIFImageExtension*' -and
    $_.Name -notlike '*Microsoft.HEVCVideoExtension*' -and
    $_.Name -notlike '*Microsoft.MPEG2VideoExtension*' -and
    $_.Name -notlike '*Microsoft.Paint*' -and
    $_.Name -notlike '*Microsoft.RawImageExtension*' -and
    $_.Name -notlike '*Microsoft.SecHealthUI*' -and
    $_.Name -notlike '*Microsoft.VP9VideoExtensions*' -and
    $_.Name -notlike '*Microsoft.WebMediaExtensions*' -and
    $_.Name -notlike '*Microsoft.WebpImageExtension*' -and
    $_.Name -notlike '*Microsoft.Windows.Photos*' -and
    $_.Name -notlike '*Microsoft.Windows.ShellExperienceHost*' -and
    $_.Name -notlike '*Microsoft.Windows.StartMenuExperienceHost*' -and
    $_.Name -notlike '*Microsoft.WindowsNotepad*' -and
    $_.Name -notlike '*Microsoft.WindowsStore*' -and
    $_.Name -notlike '*NVIDIACorp.NVIDIAControlPanel*' -and
    $_.Name -notlike '*windows.immersivecontrolpanel*'
} | Remove-AppxPackage -ErrorAction SilentlyContinue

# Allow password sign-in
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`" /v `"DevicePasswordLessBuildVersion`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# Disable open terminal by default
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationConsole`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationTerminal`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"

# ------------------------------------------------------------------------------
# 8. Configure Safe Boot & RunOnce Automation
# ------------------------------------------------------------------------------
# Install RunOnce stepone ps1 file to run in safe boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*!stepone`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\stepone.ps1`" /f >nul 2>&1"

# Install RunOnce steptwo ps1 file to run in normal boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"!steptwo`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\steptwo.ps1`" /f >nul 2>&1"

# Turn on safe boot
cmd /c "bcdedit /set {current} safeboot minimal >nul 2>&1"

Write-Host "`nPreparation Complete! Rebooting to Safe Mode in 5 seconds..." -ForegroundColor Red
Start-Sleep -Seconds 5
shutdown -r -t 00