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

Write-Host "Preparing CPU-Z..." -ForegroundColor Cyan

$cpuzPath = "$env:ProgramFiles\CPUID\CPU-Z\cpuz.exe"
if (-not (Test-Path $cpuzPath)) {
    # Check if winget is available
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        Write-Host "Installing CPU-Z via WinGet..." -ForegroundColor DarkCyan
        & winget install --id CPUID.CPU-Z --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
    }
}

if (-not (Test-Path $cpuzPath)) {
    $tempCpuz = "$env:SystemRoot\Temp\cpuz.exe"
    Invoke-WebRequest -Uri "https://download.cpuid.com/cpu-z/cpu-z_2.11-en.exe" -OutFile $tempCpuz -UseBasicParsing
    Start-Process -Wait $tempCpuz -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -WindowStyle Hidden
    Remove-Item $tempCpuz -Force -ErrorAction SilentlyContinue
}

if (Test-Path $cpuzPath) {
    Start-Process $cpuzPath
} else {
    Write-Warning "Could not start CPU-Z. Please check your internet connection."
}

Clear-Host
Write-Host "RAM CHECK"
Write-Host "---------"
Write-Host "- Check RAM profile is enabled"
Write-Host "- Verify RAM is in the correct slots"
Write-Host "- Confirm there is no mismatch in RAM modules"
Write-Host "- At least two RAM sticks (dual channel) is ideal`n"

Pause