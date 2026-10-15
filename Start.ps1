# ==============================================================================
# WinSux & Ultimate - Unified Master Interactive Console
# ==============================================================================

# Ensure Admin
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "WinSux & Ultimate Suite (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"

$rootPath = $PSScriptRoot
if (-not $rootPath) { $rootPath = (Get-Location).Path }

# Unblock files upon launch
Get-ChildItem -Path $rootPath -Recurse | Unblock-File -ErrorAction SilentlyContinue

function Show-CategoryMenu {
    param(
        [string]$CategoryDir,
        [string]$CategoryTitle
    )

    $targetPath = Join-Path $rootPath $CategoryDir
    if (-not (Test-Path $targetPath)) {
        Write-Host "Category folder not found: $targetPath" -ForegroundColor Red
        Pause
        return
    }

    while ($true) {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "   $CategoryTitle" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host ""

        $scripts = Get-ChildItem -Path $targetPath -Filter "*.ps1" | Sort-Object {
            if ($_.BaseName -match '^(\d+)') { [int]$matches[1] } else { 999 }
        }

        if ($scripts.Count -eq 0) {
            Write-Host "No scripts found in this category." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "0. Back to Main Menu"
            Pause
            return
        }

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $num = $i + 1
            Write-Host "  [$num] $($scripts[$i].BaseName)" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "  [0] Back to Main Menu" -ForegroundColor DarkGray
        Write-Host ""

        $choice = Read-Host "Select a script to run (0-$($scripts.Count))"
        if ($choice -eq "0" -or $choice -eq "") {
            return
        }

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $scripts.Count) {
            $selectedScript = $scripts[[int]$choice - 1].FullName
            Clear-Host
            Write-Host "Executing: $(Split-Path -Leaf $selectedScript)...`n" -ForegroundColor Green
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $selectedScript
            Write-Host ""
            Write-Host "Script execution completed." -ForegroundColor Cyan
            Pause
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

while ($true) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "             WINSUX & ULTIMATE UNIFIED SUITE              " -ForegroundColor Yellow
    Write-Host "       Native Software Management | Repo Independent      " -ForegroundColor DarkCyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [--- AUTOMATED PIPELINE (WINSUX) ---]" -ForegroundColor Yellow
    Write-Host "  [W] Run WinSux Automated 1-Click Pipeline" -ForegroundColor White
    Write-Host "  [S1] Run WinSux Step 1 (Driver clean, apps, preparation)" -ForegroundColor Gray
    Write-Host "  [S2] Run WinSux Step 2 (Post-reboot registry & optimizations)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [--- MODULAR CATEGORIES (ULTIMATE) ---]" -ForegroundColor Yellow
    Write-Host "  [1]  1 Check       - Hardware diagnostic, RAM, GPU, CPU bench" -ForegroundColor White
    Write-Host "  [2]  2 Refresh     - Windows Refresh, Reinstall, Restore Point" -ForegroundColor White
    Write-Host "  [3]  3 Setup       - Windows Initial Setup & Configuration" -ForegroundColor White
    Write-Host "  [4]  4 Installers  - 27+ Native Apps, Afterburner, Chromium" -ForegroundColor White
    Write-Host "  [5]  5 Graphics    - DDU, Nvidia drivers, C++, DirectX 9-12" -ForegroundColor White
    Write-Host "  [6]  6 Windows     - Bloatware, Telemetry, Privacy, Services" -ForegroundColor White
    Write-Host "  [7]  7 Hardware    - Mouse/Controller polling, Scaling, Monitor" -ForegroundColor White
    Write-Host "  [8]  8 Advanced    - ReBar, Defender, Priority, Kernels, Tweaks" -ForegroundColor White
    Write-Host ""
    Write-Host "  [--- TOOLS & SETTINGS ---]" -ForegroundColor Yellow
    Write-Host "  [A]  Allow / Block PowerShell Scripts" -ForegroundColor DarkYellow
    Write-Host "  [O]  Open Workspace Directory in Explorer" -ForegroundColor DarkYellow
    Write-Host "  [0]  Exit" -ForegroundColor DarkGray
    Write-Host ""

    $mainChoice = (Read-Host "Enter your choice").Trim()

    switch ($mainChoice.ToUpper()) {
        "W" {
            $wsPath = Join-Path $rootPath "WinSux\winsux.ps1"
            if (Test-Path $wsPath) {
                Clear-Host
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wsPath
            } else {
                Write-Host "WinSux script not found at $wsPath" -ForegroundColor Red
                Pause
            }
        }
        "S1" {
            $s1Path = Join-Path $rootPath "WinSux\stepone.ps1"
            if (Test-Path $s1Path) {
                Clear-Host
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $s1Path
            } else {
                Write-Host "StepOne script not found at $s1Path" -ForegroundColor Red
                Pause
            }
        }
        "S2" {
            $s2Path = Join-Path $rootPath "WinSux\steptwo.ps1"
            if (Test-Path $s2Path) {
                Clear-Host
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $s2Path
            } else {
                Write-Host "StepTwo script not found at $s2Path" -ForegroundColor Red
                Pause
            }
        }
        "1" { Show-CategoryMenu "1 Check" "1 Check - System Diagnostic & Benchmarks" }
        "2" { Show-CategoryMenu "2 Refresh" "2 Refresh - Windows Refresh & Reinstall" }
        "3" { Show-CategoryMenu "3 Setup" "3 Setup - Windows Initial Setup & Config" }
        "4" { Show-CategoryMenu "4 Installers" "4 Installers - Native Application Deployment" }
        "5" { Show-CategoryMenu "5 Graphics" "5 Graphics - GPU Drivers, Runtimes & Settings" }
        "6" { Show-CategoryMenu "6 Windows" "6 Windows - Debloat, Telemetry, Privacy & UI" }
        "7" { Show-CategoryMenu "7 Hardware" "7 Hardware - Mouse, Controller, Monitor & Scaling" }
        "8" { Show-CategoryMenu "8 Advanced" "8 Advanced - Kernel Tweaks, Defender, Services & ReBar" }
        "A" {
            $allowCmd = Join-Path $rootPath "AllowScripts.cmd"
            if (Test-Path $allowCmd) {
                Start-Process "cmd.exe" -ArgumentList "/c `"$allowCmd`"" -Wait
            }
        }
        "O" {
            Start-Process "explorer.exe" -ArgumentList "`"$rootPath`""
        }
        "0" {
            exit
        }
        Default {
            # Check if user typed numeric category directly
            if ($mainChoice -match '^[1-8]$') {
                $dirs = @{
                    "1" = "1 Check"; "2" = "2 Refresh"; "3" = "3 Setup";
                    "4" = "4 Installers"; "5" = "5 Graphics"; "6" = "6 Windows";
                    "7" = "7 Hardware"; "8" = "8 Advanced"
                }
                Show-CategoryMenu $dirs[$mainChoice] "$($dirs[$mainChoice])"
            }
        }
    }
}
