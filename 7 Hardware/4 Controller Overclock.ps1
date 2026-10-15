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

$hidusbfExe = "$env:SystemDrive\Program Files (x86)\hidusbf\DRIVER\Setup.exe"
if (-not (Test-Path $hidusbfExe)) {
    if (Get-Command Install-HidusbfNative -ErrorAction SilentlyContinue) {
        $hidusbfExe = Install-HidusbfNative
    } else {
        # Fallback to direct LordOfMice repo
        Write-Host "Installing: hidusbf..."
        $targetDir = "$env:SystemDrive\Program Files (x86)\hidusbf"
        if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
        $tempZip = "$env:TEMP\hidusbf.zip"
        Invoke-WebRequest -Uri "https://github.com/LordOfMice/hidusbf/raw/master/hidusbf.zip" -OutFile $tempZip
        Expand-Archive -Path $tempZip -DestinationPath $targetDir -Force
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        
        $WshShell = New-Object -comObject WScript.Shell
        $Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
        $Shortcut = $WshShell.CreateShortcut("$Desktop\Setup.lnk")
        $Shortcut.TargetPath = "$targetDir\DRIVER\Setup.exe"
        $Shortcut.WorkingDirectory = "$targetDir\DRIVER"
        $Shortcut.Save()

        $StartShortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Setup.lnk")
        $StartShortcut.TargetPath = "$targetDir\DRIVER\Setup.exe"
        $StartShortcut.WorkingDirectory = "$targetDir\DRIVER"
        $StartShortcut.Save()

        Start-Process -FilePath "rundll32.exe" -ArgumentList "setupapi.dll,InstallHinfSection DefaultInstall 132 `"$targetDir\DRIVER\HIDUSBF_AS.INF`"" -Wait
    }
}