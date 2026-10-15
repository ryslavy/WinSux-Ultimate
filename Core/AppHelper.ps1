# ==============================================================================
# WinSux & Ultimate - Native Application & Helper Module
# Repository-Independent | Native Package Management | Official Sources
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

# ------------------------------------------------------------------------------
# 1. Elevation & Environment
# ------------------------------------------------------------------------------
function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        exit
    }
}

function Test-InternetConnection {
    [CmdletBinding()]
    param([int]$TimeoutSeconds = 5)
    $targets = @("1.1.1.1", "8.8.8.8", "microsoft.com")
    foreach ($target in $targets) {
        if (Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

function Test-HasWinget {
    $wingetCmd = Get-Command "winget" -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        try {
            $ver = & winget --version 2>$null
            if ($ver) { return $true }
        } catch {}
    }
    return $false
}

# ------------------------------------------------------------------------------
# 2. File Download & Extraction Helpers
# ------------------------------------------------------------------------------
function Download-FileWithRetry {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$OutFile,
        [int]$MaxRetries = 3
    )

    $parentDir = Split-Path -Parent $OutFile
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $client = New-Object System.Net.WebClient
    $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Host "Downloading: $(Split-Path -Leaf $OutFile) (Attempt $attempt)..." -ForegroundColor Cyan
            $client.DownloadFile($Url, $OutFile)
            if (Test-Path $OutFile -and (Get-Item $OutFile).Length -gt 0) {
                return $true
            }
        } catch {
            Write-Warning "Download attempt $attempt failed: $_"
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Extract-ArchiveNative {
    param(
        [Parameter(Mandatory=$true)][string]$ZipPath,
        [Parameter(Mandatory=$true)][string]$DestinationPath
    )

    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $sevenZip = "$env:SystemDrive\Program Files\7-Zip\7z.exe"
    if (Test-Path $sevenZip) {
        & $sevenZip x $ZipPath "-o$DestinationPath" -y | Out-Null
        return
    }

    Expand-Archive -Path $ZipPath -DestinationPath $DestinationPath -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# 3. Native App Installer
# ------------------------------------------------------------------------------
function Install-NativeApp {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$WingetId,
        [string]$WingetSource,
        [string]$DirectUrl,
        [string]$Arguments = "/S",
        [string]$CheckPath,
        [string]$DestinationDir,
        [switch]$IsZip,
        [scriptblock]$PostInstall
    )

    Write-Host "Installing: $Name..." -ForegroundColor Yellow

    if ($CheckPath -and (Test-Path $CheckPath)) {
        Write-Host "$Name is already installed." -ForegroundColor Green
        if ($PostInstall) { & $PostInstall }
        return $true
    }

    $installed = $false

    # Try Winget first if WingetId is supplied and winget is available
    if ($WingetId -and (Test-HasWinget)) {
        try {
            Write-Host "Attempting native installation via WinGet ($WingetId)..." -ForegroundColor DarkCyan
            $wingetArgs = "install --id $WingetId --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
            if ($WingetSource) {
                $wingetArgs += " --source $WingetSource"
            }
            $proc = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -eq 0 -or ($CheckPath -and (Test-Path $CheckPath))) {
                Write-Host "$Name installed successfully via WinGet." -ForegroundColor Green
                $installed = $true
            }
        } catch {
            Write-Warning "WinGet installation failed: $_"
        }
    }

    # Fallback to direct official download
    if (-not $installed -and $DirectUrl) {
        $tempFile = Join-Path "$env:SystemRoot\Temp" (Split-Path -Leaf $DirectUrl)
        # Handle query string in URL if present
        if ($tempFile -match '\?.*$') {
            $tempFile = $tempFile.Split('?')[0]
        }
        if (-not ($tempFile -match '\.(exe|msi|zip|appx)$')) {
            $tempFile += ".exe"
        }

        $dlSuccess = Download-FileWithRetry -Url $DirectUrl -OutFile $tempFile
        if ($dlSuccess) {
            if ($IsZip) {
                $targetDir = if ($DestinationDir) { $DestinationDir } else { "$env:SystemRoot\Temp\$($Name.Replace(' ', ''))" }
                Extract-ArchiveNative -ZipPath $tempFile -DestinationPath $targetDir
                $installed = $true
            } elseif ($tempFile -like "*.msi") {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" /qn /norestart" -Wait -WindowStyle Hidden
                $installed = $true
            } elseif ($tempFile -like "*.appx") {
                Add-AppxPackage -Path $tempFile -ErrorAction SilentlyContinue | Out-Null
                $installed = $true
            } else {
                Start-Process -FilePath $tempFile -ArgumentList $Arguments -Wait -WindowStyle Hidden
                $installed = $true
            }
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    if ($PostInstall) {
        & $PostInstall
    }

    return $installed
}

# ------------------------------------------------------------------------------
# 4. Standard Runtimes & Core Tools
# ------------------------------------------------------------------------------
function Install-7ZipNative {
    if (Test-Path "$env:SystemDrive\Program Files\7-Zip\7z.exe") {
        return $true
    }

    Install-NativeApp -Name "7-Zip" `
        -WingetId "7zip.7zip" `
        -DirectUrl "https://www.7-zip.org/a/7z2409-x64.exe" `
        -Arguments "/S" `
        -CheckPath "$env:SystemDrive\Program Files\7-Zip\7z.exe" `
        -PostInstall {
            cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"
            cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
            Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
}

function Install-VCRedistAllNative {
    Write-Host "Installing all Visual C++ Redistributables (2005 - 2022)..." -ForegroundColor Yellow

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
        Write-Host "Installing: $($pkg.Name)..."
        if (Download-FileWithRetry -Url $pkg.Url -OutFile $outFile) {
            Start-Process -FilePath $outFile -ArgumentList $pkg.Args -Wait -WindowStyle Hidden
            Remove-Item $outFile -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Install-DirectXNative {
    Write-Host "Installing: DirectX End-User Runtimes (June 2010)..." -ForegroundColor Yellow
    Install-7ZipNative

    $directxExe = "$env:SystemRoot\Temp\directx.exe"
    $directxDir = "$env:SystemRoot\Temp\directx"

    $url = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    if (Download-FileWithRetry -Url $url -OutFile $directxExe) {
        Extract-ArchiveNative -ZipPath $directxExe -DestinationPath $directxDir
        if (Test-Path "$directxDir\DXSETUP.exe") {
            Start-Process -Wait "$directxDir\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden
        }
        Remove-Item $directxExe -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $directxDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Install-DDUNative {
    param([string]$Destination = "$env:SystemRoot\Temp\ddu")

    Write-Host "Preparing Display Driver Uninstaller (DDU)..." -ForegroundColor Yellow
    Install-7ZipNative

    $dduExe = "$env:SystemRoot\Temp\ddu.exe"
    $url = "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.5.3_setup.exe"
    if (-not (Download-FileWithRetry -Url $url -OutFile $dduExe)) {
        # Fallback to direct mirror
        $url = "https://www.wagnardsoft.com/DDU/download/DDU%20v18.1.5.3.exe"
        Download-FileWithRetry -Url $url -OutFile $dduExe
    }

    if (Test-Path $dduExe) {
        Extract-ArchiveNative -ZipPath $dduExe -DestinationPath $Destination
        Remove-Item $dduExe -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $dduSettingsDir = Join-Path $Destination "Settings"
    if (-not (Test-Path $dduSettingsDir)) {
        New-Item -Path $dduSettingsDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

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
    $settingsPath = Join-Path $dduSettingsDir "Settings.xml"
    Set-Content -Path $settingsPath -Value $DduConfig -Force
    Set-ItemProperty -Path $settingsPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
}

function Install-NvidiaProfileInspectorNative {
    $targetDir = "$env:SystemDrive\Program Files (x86)\Nvidia Profile Inspector"
    $targetExe = "$targetDir\Nvidia Profile Inspector.exe"

    if (Test-Path $targetExe) {
        return $targetExe
    }

    Write-Host "Installing: Nvidia Profile Inspector..." -ForegroundColor Yellow
    Install-7ZipNative

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $zipPath = "$env:SystemRoot\Temp\nvidiaProfileInspector.zip"
    $url = "https://github.com/Orbmu2k/nvidiaProfileInspector/releases/download/v3.0.2.3/nvidiaProfileInspector.zip"
    
    if (Download-FileWithRetry -Url $url -OutFile $zipPath) {
        Extract-ArchiveNative -ZipPath $zipPath -DestinationPath $targetDir
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue | Out-Null

        # Rename main exe if named nvidiaProfileInspector.exe
        $extractedExe = "$targetDir\nvidiaProfileInspector.exe"
        if (Test-Path $extractedExe -and -not (Test-Path $targetExe)) {
            Copy-Item -Path $extractedExe -Destination $targetExe -Force -ErrorAction SilentlyContinue
        }

        # Create Shortcuts
        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Nvidia Profile Inspector.lnk")
        $Shortcut.TargetPath = $targetExe
        $Shortcut.WorkingDirectory = $targetDir
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Nvidia Profile Inspector.lnk")
        $StartShortcut.TargetPath = $targetExe
        $StartShortcut.WorkingDirectory = $targetDir
        $StartShortcut.Save()
    }

    return $targetExe
}

function Install-HeliumNative {
    if (Test-Path "$env:ProgramFiles\Helium\Helium.exe") {
        return $true
    }

    Write-Host "Installing: Helium Browser..." -ForegroundColor Yellow
    Install-NativeApp -Name "Helium" `
        -WingetId "ImputNet.Helium" `
        -DirectUrl "https://github.com/imputnet/helium-windows/releases/download/0.19.2.1/helium_0.19.2.1_x64-installer.exe" `
        -Arguments "/S" `
        -CheckPath "$env:ProgramFiles\Helium\Helium.exe" `
        -PostInstall {
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
}

function Install-AutorunsNative {
    $targetDir = "$env:SystemDrive\Program Files (x86)\Autoruns"
    $targetExe = "$targetDir\Autoruns.exe"
    if (Test-Path $targetExe) {
        return $targetExe
    }

    Write-Host "Installing: Sysinternals Autoruns..." -ForegroundColor Yellow
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $url = "https://live.sysinternals.com/Autoruns.exe"
    Download-FileWithRetry -Url $url -OutFile $targetExe

    $WshShell = New-Object -comObject WScript.Shell
    $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
    $Shortcut = $WshShell.CreateShortcut("$Desktop\Autoruns.lnk")
    $Shortcut.TargetPath = $targetExe
    $Shortcut.WorkingDirectory = $targetDir
    $Shortcut.Save()

    $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Autoruns.lnk")
    $StartShortcut.TargetPath = $targetExe
    $StartShortcut.WorkingDirectory = $targetDir
    $StartShortcut.Save()

    return $targetExe
}

function Install-MouseMovementRecorderNative {
    $targetDir = "$env:SystemDrive\Program Files (x86)\Mouse Movement Recorder"
    $targetExe = "$targetDir\Mouse Movement Recorder.exe"
    if (Test-Path $targetExe) {
        return $targetExe
    }

    Write-Host "Installing: Mouse Movement Recorder (MarkC)..." -ForegroundColor Yellow
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $tempZip = "$env:TEMP\MarkC_MouseFix.zip"
    $tempExtract = "$env:TEMP\MarkC_Extract"
    $url = "https://archive.org/download/markc-mousefix-v29/MarkC_Windows_10%2B8.x%2B7_MouseFix.zip"

    if (Download-FileWithRetry -Url $url -OutFile $tempZip) {
        Extract-ArchiveNative -ZipPath $tempZip -DestinationPath $tempExtract
        $innerZip = Get-ChildItem -Path $tempExtract -Filter "MouseMovementRecorder*.zip" -Recurse | Select-Object -First 1
        if ($innerZip) {
            $innerExtract = "$tempExtract\inner"
            Extract-ArchiveNative -ZipPath $innerZip.FullName -DestinationPath $innerExtract
            $mmrExe = Get-ChildItem -Path $innerExtract -Filter "MouseMovementRecorder.exe" -Recurse | Select-Object -First 1
            if ($mmrExe) {
                Copy-Item -Path $mmrExe.FullName -Destination $targetExe -Force
            }
        }
        Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $targetExe) {
        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Mouse Movement Recorder.lnk")
        $Shortcut.TargetPath = $targetExe
        $Shortcut.WorkingDirectory = $targetDir
        $Shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,248"
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Mouse Movement Recorder.lnk")
        $StartShortcut.TargetPath = $targetExe
        $StartShortcut.WorkingDirectory = $targetDir
        $StartShortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,248"
        $StartShortcut.Save()
    }

    return $targetExe
}

function Install-HidusbfNative {
    $targetDir = "$env:SystemDrive\Program Files (x86)\hidusbf"
    $targetExe = "$targetDir\DRIVER\Setup.exe"
    if (Test-Path $targetExe) {
        return $targetExe
    }

    Write-Host "Installing: hidusbf (LordOfMice)..." -ForegroundColor Yellow
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $tempZip = "$env:TEMP\hidusbf.zip"
    $url = "https://github.com/LordOfMice/hidusbf/raw/master/hidusbf.zip"

    if (Download-FileWithRetry -Url $url -OutFile $tempZip) {
        Extract-ArchiveNative -ZipPath $tempZip -DestinationPath $targetDir
        # If files were placed inside an inner subfolder, flatten them into $targetDir
        $innerSub = Get-ChildItem -Path $targetDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "DRIVER") } | Select-Object -First 1
        if ($innerSub) {
            Get-ChildItem -Path $innerSub.FullName | Move-Item -Destination $targetDir -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $innerSub.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $targetExe) {
        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Setup.lnk")
        $Shortcut.TargetPath = $targetExe
        $Shortcut.WorkingDirectory = "$targetDir\DRIVER"
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Setup.lnk")
        $StartShortcut.TargetPath = $targetExe
        $StartShortcut.WorkingDirectory = "$targetDir\DRIVER"
        $StartShortcut.Save()

        $infPath = "$targetDir\DRIVER\HIDUSBF_AS.INF"
        if (Test-Path $infPath) {
            Start-Process -FilePath "rundll32.exe" -ArgumentList "setupapi.dll,InstallHinfSection DefaultInstall 132 `"$infPath`"" -Wait
        }
    }

    return $targetExe
}

function Install-PollingNative {
    $targetDir = "$env:SystemDrive\Program Files (x86)\Polling"
    $targetExe = "$targetDir\Polling.exe"
    if (Test-Path $targetExe) {
        return $targetExe
    }

    Write-Host "Installing: Gamepadla Polling..." -ForegroundColor Yellow
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $url = "https://github.com/cakama3a/Polling/releases/download/1.3.1.4/Polling.exe"
    Download-FileWithRetry -Url $url -OutFile $targetExe

    if (Test-Path $targetExe) {
        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Polling.lnk")
        $Shortcut.TargetPath = $targetExe
        $Shortcut.WorkingDirectory = $targetDir
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Polling.lnk")
        $StartShortcut.TargetPath = $targetExe
        $StartShortcut.WorkingDirectory = $targetDir
        $StartShortcut.Save()
    }

    return $targetExe
}


# ------------------------------------------------------------------------------
# 5. Repo Independence - Local & Remote File Resolver
# ------------------------------------------------------------------------------
function Resolve-WorkspaceFile {
    param(
        [Parameter(Mandatory=$true)][string]$RelativePath,
        [string]$TargetLocation = "$env:SystemRoot\Temp"
    )

    # 1. Search locally relative to caller script or current directory
    $possibleBases = @(
        $PSScriptRoot,
        (Split-Path -Parent $PSScriptRoot),
        (Get-Location).Path,
        (Join-Path (Get-Location).Path "WinSux")
    )

    foreach ($base in $possibleBases) {
        if ($base) {
            $candidate = Join-Path $base $RelativePath
            if (Test-Path $candidate) {
                $dest = Join-Path $TargetLocation (Split-Path -Leaf $RelativePath)
                if ((Resolve-Path $candidate).Path -ne (Resolve-Path $dest -ErrorAction SilentlyContinue).Path) {
                    Copy-Item -Path $candidate -Destination $dest -Force -ErrorAction SilentlyContinue
                }
                return $dest
            }
        }
    }

    # 2. If not found locally and user defined a repo base
    if ($Global:RepoBaseUrl) {
        $url = "$($Global:RepoBaseUrl.TrimEnd('/'))/$RelativePath"
        $dest = Join-Path $TargetLocation (Split-Path -Leaf $RelativePath)
        Download-FileWithRetry -Url $url -OutFile $dest
        return $dest
    }

    return $null
}
