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

Write-Host "Installing: Visual C++ Redistributables (2005 - 2022) from Microsoft..." -ForegroundColor Cyan

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

Write-Host "Visual C++ Redistributables installation completed." -ForegroundColor Green