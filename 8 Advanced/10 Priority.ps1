        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

		Write-Host "TEMPORARILY CHANGE PRIORITY FOR TESTING PER APP/GAME:`n"
        Write-Host "1. Priority: Already Running"
        Write-Host "2. Priority: Startup`n"
        while ($true) {
        $choice = Read-Host " "
        if ($choice -match '^[1-2]$') {
        switch ($choice) {
        1 {

Clear-Host

# show priority options
Write-Host "1. Real Time"
Write-Host "2. High"
Write-Host "3. Above Normal"
Write-Host "4. Normal"
Write-Host "5. Below Normal"
Write-Host "6. Idle`n"

# select priority
$priochoice = Read-Host -Prompt "Priority"

Clear-Host

# map choice to priority
switch ($priochoice) {
"1" {$prio = "RealTime"}
"2" {$prio = "High"}
"3" {$prio = "AboveNormal"}
"4" {$prio = "Normal"}
"5" {$prio = "BelowNormal"}
"6" {$prio = "Idle"}
default {
Write-Host "Invalid input..." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}

# copy game exe id
(Get-Process | Where-Object {$_.WorkingSet64 -gt 500MB} | Select-Object Name, Id) | Format-Table -AutoSize
$exeid = Read-Host -Prompt "ENTER GAME EXE ID"

Clear-Host

# set game exe priority
$processid = Get-Process -Id $exeid -ErrorAction SilentlyContinue
if ($processid) {
    try {
        $processid.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::$prio
        $currentprio = $processid.PriorityClass
        Write-Host "Process '$($processid.ProcessName)' (ID $exeid) priority set to: $currentprio`n" -ForegroundColor Green
    } catch {
        Write-Host "Could not set priority: $($_.Exception.Message)`n" -ForegroundColor Red
    }
} else {
    Write-Host "Process ID $exeid not found.`n" -ForegroundColor Red
}

Pause

exit

          }
        2 {

Clear-Host

# stop game launchers running
$stop = "Battle.net", "BsgLauncher", "EADesktop", "EpicGamesLauncher", "GalaxyClient", "RobloxPlayerBeta", "RiotClientServices", "Launcher", "steam", "upc"
$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }

Clear-Host

# show priority options
Write-Host "1. Real Time"
Write-Host "2. High"
Write-Host "3. Above Normal"
Write-Host "4. Normal"
Write-Host "5. Below Normal"
Write-Host "6. Low`n"

# select priority
$priochoice = Read-Host -Prompt "Priority"

Clear-Host

# map choice to priority
switch ($priochoice) {
"1" {$prio = "RealTime"}
"2" {$prio = "High"}
"3" {$prio = "AboveNormal"}
"4" {$prio = "Normal"}
"5" {$prio = "BelowNormal"}
"6" {$prio = "Idle"}
default {
Write-Host "Invalid input..." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}

# select game launcher lnk or exe
Write-Host "SELECT LAUNCHER/GAME/SHORTCUT/EXE:"
Add-Type -AssemblyName System.Windows.Forms
$Dialog = New-Object System.Windows.Forms.OpenFileDialog
$Dialog.Filter = "All Files (*.*)|*.*"
$Dialog.ShowDialog() | Out-Null
$gamelauncher = $Dialog.FileName
if ([string]::IsNullOrWhiteSpace($gamelauncher)) {
    Write-Host "No file selected." -ForegroundColor Yellow
    exit
}

Clear-Host

# set game exe priority and launch
cmd /c "start `"`" /$prio `"$gamelauncher`""

# convert directory to file name without exe
$processName = [System.IO.Path]::GetFileNameWithoutExtension($gamelauncher)

# give process a moment to launch then check
Start-Sleep -Seconds 1
$runningProc = Get-Process -Name $processName -ErrorAction SilentlyContinue | Select-Object -First 1
if ($runningProc) {
    Write-Host "EXE - $processName priority is: $($runningProc.PriorityClass)`n" -ForegroundColor Green
} else {
    Write-Host "Launched $processName with priority: $prio`n" -ForegroundColor Green
}

Pause

exit

          }
        } } else { Write-Host "Invalid input. Please select a valid option (1-2)." } }