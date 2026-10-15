        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # FUNCTION RUN AS TRUSTED INSTALLER
        function Run-Trusted {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
                [string[]]$Command
            )
            process {
                $cmdList = @($Command | Where-Object { $_ -and $_.Trim() -ne "" })
                if ($cmdList.Count -eq 0) { return }

                try {
                    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue
                } catch {
                    taskkill /im trustedinstaller.exe /f >$null 2>&1
                }
                $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'" -ErrorAction SilentlyContinue
                $DefaultBinPath = if ($service -and $service.PathName) { $service.PathName } else { "$env:SystemRoot\servicing\TrustedInstaller.exe" }
                $trustedInstallerPath = "$env:SystemRoot\servicing\TrustedInstaller.exe"
                if ($DefaultBinPath -ne $trustedInstallerPath -and -not (Test-Path $DefaultBinPath)) {
                    $DefaultBinPath = $trustedInstallerPath
                }

                if ($cmdList.Count -eq 1 -and $cmdList[0].Length -lt 500 -and $cmdList[0] -notmatch "[\r\n]") {
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmdList[0])
                    $base64Command = [Convert]::ToBase64String($bytes)
                    sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -NoProfile -NonInteractive -EncodedCommand $base64Command" | Out-Null
                    sc.exe start TrustedInstaller | Out-Null
                } else {
                    $tempScript = "$env:SystemRoot\Temp\trusted_batch_$([Guid]::NewGuid().ToString('N')).ps1"
                    $scriptContent = $cmdList -join "`r`n"
                    [System.IO.File]::WriteAllText($tempScript, $scriptContent, [System.Text.Encoding]::UTF8)
                    sc.exe config TrustedInstaller binPath= "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$tempScript`"" | Out-Null
                    sc.exe start TrustedInstaller | Out-Null
                    if (Test-Path $tempScript) {
                        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
                    }
                }

                sc.exe config TrustedInstaller binpath= "`"$DefaultBinPath`"" | Out-Null
                try {
                    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue
                } catch {
                    taskkill /im trustedinstaller.exe /f >$null 2>&1
                }
            }
        }

        Write-Host "DEFENDER SETTINGS`n"
        ## windowsdefender:
		## windowsdefender://threatsettings
		## windowsdefender://ransomwareprotection
		## windowsdefender://settings
		## windowsdefender://smartapp
		## windowsdefender://smartscreenpua
		## windowsdefender://exploitprotection
		## windowsdefender://coreisolation

$windowssecuritysettings = @(
# virus & threat protection - manage settings
# real time protection - needs safe boot as trusted installer - windows turns this back on automatically
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection`" /v `"DisableRealtimeMonitoring`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# dev drive protection - needs safe boot as trusted installer
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection`" /v `"DisableAsyncScanOnOpen`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',

# cloud delivered protection - needs safe boot as trusted installer
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Spynet`" /v `"SpyNetReporting`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# automatic sample submission
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Spynet`" /v `"SubmitSamplesConsent`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# tamper protection - needs safe boot as trusted installer
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Features`" /v `"TamperProtection`" /t REG_DWORD /d `"4`" /f >nul 2>&1"',

# virus & threat protection - manage ransomware protection
# controlled folder access
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access`" /v `"EnableControlledFolderAccess`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# firewall & network protection - firewall notification settings - manage notifications
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications`" /v `"DisableEnhancedNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection`" /v `"NoActionNotificationDisabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection`" /v `"SummaryNotificationDisabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection`" /v `"FilesBlockedNotificationDisabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection`" /v `"DisableNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection`" /v `"DisableDynamiclockNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows Defender Security Center\Account protection`" /v `"DisableWindowsHelloNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Services\SharedAccess\Epoch`" /v `"Epoch`" /t REG_DWORD /d `"1231`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile`" /v `"DisableNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile`" /v `"DisableNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile`" /v `"DisableNotifications`" /t REG_DWORD /d `"1`" /f >nul 2>&1"',

# app & browser control - smart app control settings
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender`" /v `"VerifiedAndReputableTrustModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender`" /v `"SmartLockerMode`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender`" /v `"PUAProtection`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\AppID\Configuration\SMARTLOCKER`" /v `"START_PENDING`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\AppID\Configuration\SMARTLOCKER`" /v `"ENABLED`" /t REG_BINARY /d `"0000000000000000`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\CI\Policy`" /v `"VerifiedAndReputablePolicyState`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# app & browser control - reputation based protection settings
# check apps and files
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer`" /v `"SmartScreenEnabled`" /t REG_SZ /d `"Off`" /f >nul 2>&1"',

# smartscreen for microsoft edge - needs normal boot as admin
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\SmartScreenEnabled`" /ve /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\SmartScreenPuaEnabled`" /ve /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# phishing protection
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`" /v `"CaptureThreatWindow`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`" /v `"NotifyMalicious`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`" /v `"NotifyPasswordReuse`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`" /v `"NotifyUnsafeApp`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components`" /v `"ServiceEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# potentially unwanted app blocking
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender`" /v `"PUAProtection`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# smartscreen for microsoft store apps - needs normal boot as admin
'cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost`" /v `"EnableWebContentEvaluation`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# app & browser control - exploit protection settings
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\Session Manager\kernel`" /v `"MitigationOptions`" /t REG_BINARY /d `"222222000002000000020000000000000000000000000000`" /f >nul 2>&1"',

# device security - core isolation details
# memory integrity
'cmd /c "reg delete `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity`" /v `"ChangedInBootCycle`" /f >nul 2>&1"',
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity`" /v `"Enabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',
'cmd /c "reg delete `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity`" /v `"WasEnabledBy`" /f >nul 2>&1"',

# turn off vbs virtualization based security
# faceit anti cheat forces this on, even after uninstall
'cmd /c "bcdedit /deletevalue allowedinmemorysettings >nul 2>&1"',
'cmd /c "bcdedit /deletevalue isolatedcontext >nul 2>&1"',
'cmd /c "bcdedit /deletevalue hypervisorlaunchtype >nul 2>&1"',
'cmd /c "reg delete `"HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard`" /v `"EnableVirtualizationBasedSecurity`" /f >nul 2>&1"',

# local security authority protection
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa`" /v `"RunAsPPL`" /t REG_DWORD /d `"0`" /f >nul 2>&1"',

# microsoft vulnerable driver blocklist
'cmd /c "reg add `"HKEY_LOCAL_MACHINE\System\ControlSet001\Control\CI\Config`" /v `"VulnerableDriverBlocklistEnable`" /t REG_DWORD /d `"0`" /f >nul 2>&1"'
)

# run $windowssecuritysettings as trusted installer in a single batch
Run-Trusted $windowssecuritysettings

# run as admin fallback
$windowssecuritysettings | ForEach-Object { Invoke-Expression $_ }

# disable uac
cmd /c "reg add `"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" /v `"EnableLUA`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# remove safe mode boot
cmd /c "bcdedit /deletevalue {current} safeboot >nul 2>&1"

        Write-Host "DDU & RESTARTING`n" -ForegroundColor Red

# uninstall soundblaster realtek intel amd nvidia drivers & restart
$dduExe = "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe"
if (-not (Test-Path $dduExe)) {
    $altDdu = Get-ChildItem "$env:SystemRoot\Temp\ddu" -Filter "*Display Driver Uninstaller*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($altDdu) { $dduExe = $altDdu.FullName }
}
if (Test-Path $dduExe) {
    Start-Process $dduExe -ArgumentList "-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart" -Wait
} else {
    Write-Warning "DDU not found, restarting to normal mode..."
    shutdown -r -t 05
}