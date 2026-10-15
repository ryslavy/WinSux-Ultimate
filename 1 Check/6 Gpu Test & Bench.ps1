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
        if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue) -and
            !(Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Internet Connection Required`n" -ForegroundColor Red
        Pause
        exit
        }

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

Write-Host "Preparing FurMark..." -ForegroundColor Cyan

$furmarkExe = "$env:ProgramFiles\Geeks3D\FurMark2\FurMark.exe"
if (-not (Test-Path $furmarkExe)) {
    $furmarkExe = "$env:ProgramFiles (x86)\Geeks3D\FurMark2\FurMark.exe"
}

if (-not (Test-Path $furmarkExe)) {
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        Write-Host "Installing FurMark via WinGet..." -ForegroundColor DarkCyan
        & winget install --id Geeks3D.FurMark --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
    }
}

if (-not (Test-Path $furmarkExe)) {
    $tempZip = "$env:SystemRoot\Temp\furmark.zip"
    $tempDir = "$env:SystemRoot\Temp\furmark"
    # Geeks3D official direct link
    try {
        Invoke-WebRequest -Uri "https://geeks3d.com/dl/get/752" -OutFile $tempZip -UseBasicParsing -ErrorAction SilentlyContinue
        Expand-Archive $tempZip -DestinationPath $tempDir -Force -ErrorAction SilentlyContinue
        $found = Get-ChildItem $tempDir -Filter "*FurMark*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $furmarkExe = $found.FullName }
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    } catch {}
}

if ($furmarkExe -and (Test-Path $furmarkExe)) {
    Start-Process $furmarkExe
} else {
    Write-Warning "Could not start FurMark. Opening official website..."
    Start-Process "https://geeks3d.com/furmark/"
}

Clear-Host
Write-Host "GPU TEST"
Write-Host "--------"
Write-Host "Run GPU stress test`n"
Write-Host "TROUBLESHOOTING"
Write-Host "---------------"
Write-Host "Basic troubleshooting items to monitor"
Write-Host "- Temps"
Write-Host "- Framerate"
Write-Host "- Artifacts"
Write-Host "- Freezing"
Write-Host "- Driver crashes"
Write-Host "- Shutdowns"
Write-Host "- Blue screens`n"
Write-Host "GPU BENCH"
Write-Host "---------"
Write-Host "Run a GPU benchmark"
Write-Host "- Compare results"
Write-Host "- Confirm GPU is performing optimally`n"

Pause