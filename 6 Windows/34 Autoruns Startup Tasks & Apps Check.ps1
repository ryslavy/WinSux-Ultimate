        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

        # FUNCTION RUN AS TRUSTED INSTALLER
        function Run-Trusted {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
                [string[]]$Command
            )
            process {
                $cmdList = @($Command | Where-Object { $_ -and $_.Trim() -ne "" })
                if ($cmdList.Count -eq 0) { return }

                try {
                    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue
                } catch {
                    taskkill /im trustedinstaller.exe /f >$null 2>&1
                }
                $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'" -ErrorAction SilentlyContinue
                $DefaultBinPath = if ($service -and $service.PathName) { $service.PathName } else { "$env:SystemRoot\servicing\TrustedInstaller.exe" }
                $trustedInstallerPath = "$env:SystemRoot\servicing\TrustedInstaller.exe"
                if ($DefaultBinPath -ne $trustedInstallerPath -and -not (Test-Path $DefaultBinPath)) {
                    $DefaultBinPath = $trustedInstallerPath
                }

                if ($cmdList.Count -eq 1 -and $cmdList[0].Length -lt 500 -and $cmdList[0] -notmatch "[\r\n]") {
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmdList[0])
                    $base64Command = [Convert]::ToBase64String($bytes)
                    sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -NoProfile -NonInteractive -EncodedCommand $base64Command" | Out-Null
                    sc.exe start TrustedInstaller | Out-Null
                } else {
                    $tempScript = "$env:SystemRoot\Temp\trusted_batch_$([Guid]::NewGuid().ToString('N')).ps1"
                    $scriptContent = $cmdList -join "`r`n"
                    [System.IO.File]::WriteAllText($tempScript, $scriptContent, [System.Text.Encoding]::UTF8)
                    sc.exe config TrustedInstaller binPath= "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$tempScript`"" | Out-Null
                    sc.exe start TrustedInstaller | Out-Null
                    if (Test-Path $tempScript) {
                        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
                    }
                }

                sc.exe config TrustedInstaller binpath= "`"$DefaultBinPath`"" | Out-Null
                try {
                    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue
                } catch {
                    taskkill /im trustedinstaller.exe /f >$null 2>&1
                }
            }
        }

Write-Host "Downloading: Autoruns..."

# create a restore point
try {
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`" /v `"SystemRestorePointCreationFrequency`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue | Out-Null
Checkpoint-Computer -Description "beforeautoruns" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue | Out-Null
cmd /c "reg delete `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`" /v `"SystemRestorePointCreationFrequency`" /f >nul 2>&1"
} catch { }

# remove 3rd party startup apps
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunNotification`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunNotification`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
Remove-Item -Recurse -Force "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Recurse -Force "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

# remove 3rd party scheduled tasks
$treePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree"
$nonMsTasks = Get-ChildItem $treePath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -ne "Microsoft" }
if ($nonMsTasks) {
    $delCmds = @($nonMsTasks | ForEach-Object { "Remove-Item '$($_.PSPath)' -Recurse -Force -ErrorAction SilentlyContinue" })
    Run-Trusted $delCmds
}

$tasksPath = "$env:SystemRoot\System32\Tasks"
Get-ChildItem $tasksPath | Where-Object { $_.Name -ne "Microsoft" } | ForEach-Object {
Remove-Item $_.FullName -Recurse -Force
}

# new folder
New-Item -Path "$env:SystemDrive\Program Files (x86)\Autoruns" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# download autoruns
Invoke-WebRequest -Uri "https://live.sysinternals.com/Autoruns.exe" -OutFile "$env:SystemDrive\Program Files (x86)\Autoruns\Autoruns.exe" -UseBasicParsing

# create desktop shortcut
$WshShell = New-Object -comObject WScript.Shell
$Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
$Shortcut = $WshShell.CreateShortcut("$Desktop\Autoruns.lnk")
$Shortcut.TargetPath = "$env:SystemDrive\Program Files (x86)\Autoruns\Autoruns.exe"
$Shortcut.WorkingDirectory = "$env:SystemDrive\Program Files (x86)\Autoruns"
$Shortcut.Save()

# create start menu shortcut
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Autoruns.lnk")
$Shortcut.TargetPath = "$env:SystemDrive\Program Files (x86)\Autoruns\Autoruns.exe"
$Shortcut.WorkingDirectory = "$env:SystemDrive\Program Files (x86)\Autoruns"
$Shortcut.Save()

# open autoruns
Start-Process "$env:SystemDrive\Program Files (x86)\Autoruns\Autoruns.exe"