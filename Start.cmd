@echo off
setlocal EnableDelayedExpansion

:: Elevate to Administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto uacprompt
) else ( goto gotadmin )

:uacprompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:gotadmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

:: Set Execution Policy and Run Start.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Start.ps1'"

exit /B
