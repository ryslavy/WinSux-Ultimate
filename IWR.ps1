# ==============================================================================
# WinSux & Ultimate - Dynamic Web Installer & Bootstrap (IWR.ps1)
# Fully Repository-Independent | Self-Detects Upstream Repo & Branch
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

# 1. Ensure Running As Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Cyan
    if ($PSCommandPath) {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    } else {
        $cmdToRun = if ($MyInvocation.Line) { $MyInvocation.Line } else { "irm https://raw.githubusercontent.com/ryslavy/WinSux-Ultimate/main/IWR.ps1 | iex" }
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -Command `"{0}`"" -f $cmdToRun) -Verb RunAs
    }
    exit
}

$Host.UI.RawUI.WindowTitle = "WinSux & Ultimate - Installer"
$progresspreference = 'silentlycontinue'

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "           WinSux & Ultimate - Automated Setup            " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 3. Detect Source Repository and Branch Dynamically
$detectedUser = ""
$detectedRepo = ""
$detectedBranch = "main"

# Try detecting from invocation line (e.g., irm https://raw.githubusercontent.com/User/Repo/main/IWR.ps1 | iex)
$invLine = $MyInvocation.Line
if ($invLine -match 'githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)') {
    $detectedUser = $matches[1]
    $detectedRepo = $matches[2]
    $detectedBranch = $matches[3]
} elseif ($invLine -match 'github\.com/([^/]+)/([^/]+)') {
    $detectedUser = $matches[1]
    $detectedRepo = $matches[2]
}

# Fallback: Environment variables or default
if (-not $detectedUser -and $env:WINSUX_REPO) {
    if ($env:WINSUX_REPO -match '([^/]+)/([^/]+)') {
        $detectedUser = $matches[1]
        $detectedRepo = $matches[2]
    }
}

# Check if running locally inside a cloned repository already
$localWorkspace = $PSScriptRoot
if ($localWorkspace -and (Test-Path (Join-Path $localWorkspace "WinSux\winsux.ps1"))) {
    Write-Host "Running from local repository: $localWorkspace" -ForegroundColor Green
    
    # Configure execution policy
    cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`" /v `"ExecutionPolicy`" /t REG_SZ /d `"Unrestricted`" /f >nul 2>&1"
    cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`" /v `"ExecutionPolicy`" /t REG_SZ /d `"Unrestricted`" /f >nul 2>&1"
    cmd /c "reg add `"HKCR\Applications\powershell.exe\shell\open\command`" /ve /t REG_SZ /d `"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -ExecutionPolicy unrestricted -File \`"`"%1\`"`"`" /f >nul 2>&1"
    
    Get-ChildItem -Path $localWorkspace -Recurse | Unblock-File -ErrorAction SilentlyContinue
    
    $startCmd = Join-Path $localWorkspace "Start.cmd"
    if (Test-Path $startCmd) {
        Start-Process $startCmd
    } else {
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$localWorkspace\Start.ps1`""
    }
    exit
}

# If remote invocation without user, prompt or use fallback
if (-not $detectedUser -or -not $detectedRepo) {
    Write-Host "Could not auto-detect repository from invocation line." -ForegroundColor Yellow
    $repoInput = Read-Host "Enter GitHub repository (format: 'Username/Repo' or press Enter to cancel)"
    if ($repoInput -match '([^/]+)/([^/]+)') {
        $detectedUser = $matches[1]
        $detectedRepo = $matches[2]
    } else {
        Write-Host "No repository specified. Exiting..." -ForegroundColor Red
        Pause
        exit
    }
}

Write-Host "Target Repository: $detectedUser/$detectedRepo ($detectedBranch)" -ForegroundColor Cyan

# 4. Download and Extract Repository Archive
$zipUrl = "https://github.com/$detectedUser/$detectedRepo/archive/refs/heads/$detectedBranch.zip"
$tempZip = "$env:SystemRoot\Temp\$detectedRepo-$detectedBranch.zip"
$tempDir = "$env:SystemRoot\Temp\$detectedRepo-extract"

Write-Host "Downloading repository package from GitHub..." -ForegroundColor Yellow
try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $wc.DownloadFile($zipUrl, $tempZip)
} catch {
    Write-Host "Failed to download $zipUrl. Error: $_" -ForegroundColor Red
    Pause
    exit
}

Write-Host "Extracting files..." -ForegroundColor Yellow
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

$extractedFolder = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
if (-not $extractedFolder) {
    Write-Host "Failed to locate extracted contents." -ForegroundColor Red
    Pause
    exit
}

# 5. Move to Desktop
$Desktop = (New-Object -ComObject Shell.Application).Namespace('shell:Desktop').Self.Path
$destination = Join-Path $Desktop $detectedRepo

if (Test-Path $destination) {
    Write-Host "Updating existing installation at $destination..." -ForegroundColor Yellow
    Remove-Item -Path $destination -Recurse -Force -ErrorAction SilentlyContinue
}

Move-Item -Path $extractedFolder.FullName -Destination $destination -Force
Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# 6. Configure Permissions and File Unblocking
Write-Host "Configuring PowerShell Execution Policy..." -ForegroundColor Yellow
cmd /c "reg add `"HKCR\Applications\powershell.exe\shell\open\command`" /ve /t REG_SZ /d `"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -ExecutionPolicy unrestricted -File \`"`"%1\`"`"`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`" /v `"ExecutionPolicy`" /t REG_SZ /d `"Unrestricted`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell`" /v `"ExecutionPolicy`" /t REG_SZ /d `"Unrestricted`" /f >nul 2>&1"

Write-Host "Unblocking downloaded files..." -ForegroundColor Yellow
Get-ChildItem -Path $destination -Recurse | Unblock-File -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Installation complete! Files deployed to: $destination" -ForegroundColor Green
Write-Host ""

# 7. Launch Suite
$startCmd = Join-Path $destination "Start.cmd"
if (Test-Path $startCmd) {
    Start-Process $startCmd
} else {
    Start-Process $destination
}

exit
