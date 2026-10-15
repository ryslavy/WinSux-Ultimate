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

        # Load Core AppHelper if available
        $helperLocations = @(
            (Join-Path $PSScriptRoot "..\Core\AppHelper.ps1"),
            (Join-Path $PSScriptRoot "Core\AppHelper.ps1"),
            (Join-Path (Get-Location).Path "Core\AppHelper.ps1")
        )
        foreach ($loc in $helperLocations) {
            if (Test-Path $loc) { . $loc; break }
        }

Write-Host "Installing: DirectX End-User Runtimes (June 2010)..." -ForegroundColor Cyan

if (Get-Command Install-DirectXNative -ErrorAction SilentlyContinue) {
    Install-DirectXNative
} else {
    # 7-Zip check/install
    if (-not (Test-Path "$env:SystemDrive\Program Files\7-Zip\7z.exe")) {
        $sevenZipExe = "$env:SystemRoot\Temp\7zip.exe"
        Invoke-WebRequest -Uri "https://www.7-zip.org/a/7z2409-x64.exe" -OutFile $sevenZipExe -UseBasicParsing
        Start-Process -Wait $sevenZipExe -ArgumentList "/S"
        Remove-Item $sevenZipExe -Force -ErrorAction SilentlyContinue
    }

    $dxExe = "$env:SystemRoot\Temp\directx.exe"
    $dxDir = "$env:SystemRoot\Temp\directx"
    $dxUrl = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"

    Invoke-WebRequest -Uri $dxUrl -OutFile $dxExe -UseBasicParsing
    & "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$dxExe" -o"$dxDir" -y | Out-Null
    Start-Process -Wait "$dxDir\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden

    Remove-Item $dxExe -Force -ErrorAction SilentlyContinue
    Remove-Item $dxDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "DirectX installation completed." -ForegroundColor Green