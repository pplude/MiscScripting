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
	set params = %*:"="
	echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
	
	"%TEMP%\getadmin.vbs"
	del "%TEMP%\getadmin.vbs"
	exit /B

REM Continue	
:gotAdmin
	pushd "%CD%"
	CD /D "%~dp0"
:-------------------------------------
