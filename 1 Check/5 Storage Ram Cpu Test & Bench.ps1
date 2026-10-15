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

Write-Host "Preparing OCCT..." -ForegroundColor Cyan

$occtExe = "$env:SystemRoot\Temp\occt.exe"
if (-not (Test-Path $occtExe)) {
    # Try official direct download from OCBASE
    $headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
    try {
        Invoke-WebRequest -Uri "https://www.ocbase.com/download/edition:OCCT" -OutFile $occtExe -Headers $headers -UseBasicParsing -ErrorAction SilentlyContinue
    } catch {}
}

if (Test-Path $occtExe) {
    Start-Process $occtExe
} else {
    Write-Warning "Could not download OCCT. Opening official download page..."
    Start-Process "https://www.ocbase.com/"
}

Clear-Host
Write-Host "STORAGE RAM CPU TEST"
Write-Host "--------------------"
Write-Host "Run a STORAGE, RAM & CPU stress test"
Write-Host "Check temps, test errors, WHEA errors & storage errors"
Write-Host "Errors should not be ignored as they can lead to"
Write-Host "- Stutters and hitches"
Write-Host "- Corrupted Windows"
Write-Host "- Poor performance"
Write-Host "- Corrupted files"
Write-Host "- Black screens"
Write-Host "- Boot failure"
Write-Host "- Blue screens"
Write-Host "- Input lag"
Write-Host "- Shutdowns`n"
Write-Host "TROUBLESHOOTING"
Write-Host "---------------"
Write-Host "Basic troubleshooting for errors, crashes, issues or boot failure"
Write-Host "- RAM overheating? Typically over 55deg. (fix case flow/ram fan)"
Write-Host "- Unlucky CPU memory controller? (lower RAM speed)"
Write-Host "- CPU overheating? (repaste/retighten/RMA cooler)"
Write-Host "- Overclock? (turn it off/dial it down)"
Write-Host "- CPU cooler over tightened? (loosen)"
Write-Host "- RAM in wrong slots? (check manual)"
Write-Host "- BIOS bugged out? (clear CMOS)"
Write-Host "- Incompatible RAM? (check QVL)"
Write-Host "- BIOS out of date? (update)"
Write-Host "- Mismatched RAM? (replace)"
Write-Host "- Faulty motherboard? (RMA)"
Write-Host "- Faulty RAM stick? (RMA)"
Write-Host "- Bent CPU pin? (RMA)"
Write-Host "- Faulty CPU? (RMA)`n"

Pause