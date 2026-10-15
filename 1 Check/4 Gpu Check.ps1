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

Write-Host "Preparing GPU-Z..." -ForegroundColor Cyan

$gpuzPaths = @(
    "$env:ProgramFiles (x86)\TechPowerUp\TechPowerUp GPU-Z\GPU-Z.exe",
    "$env:ProgramFiles\TechPowerUp\TechPowerUp GPU-Z\GPU-Z.exe",
    "$env:SystemDrive\Program Files (x86)\GPU-Z\GPU-Z.exe"
)
$gpuzExe = $gpuzPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $gpuzExe) {
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        Write-Host "Installing GPU-Z via WinGet..." -ForegroundColor DarkCyan
        & winget install --id TechPowerUp.GPU-Z --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        $gpuzExe = $gpuzPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
}

if (-not $gpuzExe) {
    $tempGpuz = "$env:SystemRoot\Temp\gpuz.exe"
    # TechPowerUp official direct download
    $headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
    try {
        Invoke-WebRequest -Uri "https://us1-dl.techpowerup.com/files/1-L364P31g6TzT92Nf_cFA/GPU-Z.2.60.0.exe" -OutFile $tempGpuz -Headers $headers -UseBasicParsing -ErrorAction SilentlyContinue
    } catch {}
    if (Test-Path $tempGpuz) {
        $gpuzExe = $tempGpuz
    }
}

if ($gpuzExe -and (Test-Path $gpuzExe)) {
    Start-Process $gpuzExe
} else {
    Write-Warning "Could not start GPU-Z. Please check your internet connection."
}

Clear-Host
Write-Host "GPU CHECK"
Write-Host "---------"
Write-Host "- Check Video Bus is at maximum"
Write-Host "- Check Resizable BAR is enabled"
Write-Host "- Verify monitor cable is connected to the GPU"
Write-Host "- Confirm GPU is in the top PCIe motherboard slot"
Write-Host "- Running multiple graphics cards is not recommended`n"

Pause