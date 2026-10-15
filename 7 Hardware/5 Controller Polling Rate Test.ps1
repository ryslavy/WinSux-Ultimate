        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # SCRIPT CHECK INTERNET
        if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Internet Connection Required`n" -ForegroundColor Red
        Pause
        exit
        }

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

# Import AppHelper if available
$helperPath = Join-Path (Split-Path -Parent $PSScriptRoot) "Core\AppHelper.ps1"
if (Test-Path $helperPath) { . $helperPath }

$pollingExe = "$env:SystemDrive\Program Files (x86)\Polling\Polling.exe"
if (-not (Test-Path $pollingExe)) {
    if (Get-Command Install-PollingNative -ErrorAction SilentlyContinue) {
        $pollingExe = Install-PollingNative
    } else {
        # Fallback to direct author's release
        Write-Host "Installing: Polling..."
        $targetDir = "$env:SystemDrive\Program Files (x86)\Polling"
        if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
        Invoke-WebRequest -Uri "https://github.com/cakama3a/Polling/releases/download/1.3.1.4/Polling.exe" -OutFile $pollingExe

        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Polling.lnk")
        $Shortcut.TargetPath = $pollingExe
        $Shortcut.WorkingDirectory = $targetDir
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Polling.lnk")
        $StartShortcut.TargetPath = $pollingExe
        $StartShortcut.WorkingDirectory = $targetDir
        $StartShortcut.Save()
    }
}

# open gamepadla
if (Test-Path $pollingExe) {
    Start-Process $pollingExe
}