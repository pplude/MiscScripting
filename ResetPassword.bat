@echo off

REM THIS SECTION CHECKS FOR ADMIN RIGHTS AND CALLS UAC IF NEEDED
:-------------------------------------
REM Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM If error flag set, we do not have admin
IF '%ERRORLEVEL%' NEQ '0' (
	echo Requesting administrative privilages...
	goto UACPrompt
) ELSE ( GOTO gotAdmin )

REM Create a vbs that calls UAC
:UACPrompt
	echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
	set params = %*:"=""
	echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
	
	"%TEMP%\getadmin.vbs"
	del "%TEMP%\getadmin.vbs"
	exit /B

REM Continue	
:gotAdmin
	pushd "%CD%"
	CD /D "%~dp0"
:-------------------------------------

cls
echo "This utility will open a system-level command prompt at next boot"

REM Get the drive to perform the action on
set /p RemoteDrive = Please enter the system drive:

IF %RemoteDrive% = %SYSTEMDRIVE% (
	REM If the system drive, make changes directly
	reg.exe add HKLM\SYSTEM\Setup /v SetupType /t REG_DWORD /d 00000002 /f
	reg.exe add HKLM\SYSTEM\Setup /v CmdLine /t REG_SZ /d "cmd" /f
) ELSE (
	REM Loads the registry to memory and makes changes
	reg.exe load HKLM\TempHive "%RemoteDrive%\Windows\system32\config\system"
	reg.exe add HKLM\TempHive\Setup /v SetupType /t REG_DWORD /d 00000002 /f
	reg.exe add HKLM\TempHive\Setup /v CmdLine /t REG_SZ /d "cmd" /f
	reg.exe unload HKLM\TempHive
)
cls

echo "Complete, please reboot now"

REM At the next boot, a system level command prompt will open and the 
REM Technician user can use the command NET USER [username] [new_password]
