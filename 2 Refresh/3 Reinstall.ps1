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
        $hasNet = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
        if ($hasNet) {
            try { $hasNet = ([System.Net.Dns]::GetHostAddresses("github.com").Count -gt 0) } catch { $hasNet = $true }
        }
        if (!$hasNet -and !(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Internet Connection Required`n" -ForegroundColor Red
        Pause
        exit
        }

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

        Write-Host "1. Reinstall: W10 (Official Microsoft Media Creation Tool)"
        Write-Host "2. Reinstall: W11 (Official Microsoft Media Creation Tool)`n"
        while ($true) {
        $choice = Read-Host " "
        if ($choice -match '^[1-2]$') {
        switch ($choice) {
        1 {

Clear-Host
Write-Host "Downloading: Official Microsoft Windows 10 Media Creation Tool..." -ForegroundColor Cyan

$w10Tool = "$env:SystemRoot\Temp\MediaCreationToolW10.exe"
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?LinkId=691209" -OutFile $w10Tool -UseBasicParsing

if (Test-Path $w10Tool) {
    Start-Process $w10Tool
}

exit

          }
        2 {

Clear-Host
Write-Host "Downloading: Official Microsoft Windows 11 Media Creation Tool..." -ForegroundColor Cyan

$w11Tool = "$env:SystemRoot\Temp\MediaCreationToolW11.exe"
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2156295" -OutFile $w11Tool -UseBasicParsing

if (Test-Path $w11Tool) {
    Start-Process $w11Tool
}

exit

          }
        } } else { Write-Host "Invalid input. Please select a valid option (1-2)." } }