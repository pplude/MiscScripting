######################
##  CLENAUP SCRIPT  ##
######################

## Setup the environment
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

## Check to see if server
$WindowsCheck = (Get-WmiObject Win32_OperatingSystem | Select-Object Caption | foreach {$_.Caption} | Select-String -SimpleMatch -Quiet "Windows Server")

###############
##  FIX WMI  ##
###############
Stop-Service -Force ccmexec -ErrorAction SilentlyContinue
Stop-Service -Force winmgmt
$WMIBinaries=@("unsecapp.exe","wmiadap.exe","wmiapsrv.exe","wmiprvse.exe","scrcons.exe")
foreach ($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
	if(Test-Path -Path $sWMIPath){
		push-Location $sWMIPath
		foreach($sBin in $WMIBinaries){
			if(Test-Path -Path $sBin){
				$oCurrentBin=Get-Item -Path  $sBin
				Write-Host " Register $sBin"
				& $oCurrentBin.FullName /RegServer
			}
			else{
				# Warning only for System32
				if($sWMIPath -eq $ENV:SystemRoot+"\System32\wbem"){
					Write-Warning "File $sBin not found!"
				}
			}
		}
		Pop-Location
	}
}

Write-Host "Reset Repository"

WinMgmt.exe /resetrepository | Out-Null
WinMgmt.exe /salvagerepository | Out-Null

# Start the services again
Start-Service winmgmt
Start-Service ccmexec -ErrorAction SilentlyContinue

###############################
## PRE-RUN FREE SPACE CHECK  ##
###############################
$StartFree = (Get-Volume -DriveLetter C | Select SizeRemaining | foreach {$_.SizeRemaining})


###########################
##  TEMP FOLDER CLEANUP  ##
###########################

$TempFolders = @("C:\Windows\Temp\*","$env:TEMP","C:\Windows\Prefetch\*","C:\Users\Users\*\AppData\Local\Temp\*","C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*","C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*","C:\Users\*\My Documents\*.tmp")
$DriverFolders = @("C:\NVIDIA","C:\ATI","C:\AMD","C:\DELL","C:\Intel","C:\HP")
$NiniteFolders = @("C:\NetCare\Ninite\NiniteDownloads")
$UpdateBG = @("C:\Windows\*.log","C:\Windows\*.txt","C:\Windows\*.bmp","C:\Windows\*.tmp","C:\Windows\Web\Wallpaper\*.*","C:\Windows\Web\Wallpaper\Dell")
$FlashCache = @("C:\Users\Users\*\AppData\Roaming\Macromedia\Flash Player\#SharedObjects","C:\Users\Users\*\AppData\Roaming\Macromedia\Flash Player\macromedia.com\support\flashplayer\sys")


# Clean Internet Explorer
rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 4351

# Temp File Cleanup
Remove-Item -Path $TempFolders -Force -Recurse -ErrorAction SilentlyContinue

# Clean System Files
Remove-Item -Path $DriverFolders -Force -Recurse -ErrorAction SilentlyContinue

# Remove MSO Cache
Remove-Item "C:\MSOCache" -Force -Recurse -ErrorAction SilentlyContinue

# Remove Old Windows Installer (should be old)
Remove-Item "C:\Windows\i386" -Force -Recurse -ErrorAction SilentlyContinue

# Remove old Recycle-Bin areas
Remove-Item 'C:\$Recycle.Bin' -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\RECYCLER" -Force -Recurse -ErrorAction SilentlyContinue

#remove MUI Cache
reg.exe delete "HKCU\SOFTWARE\Classes\Local Settings\Muicache" /f
Remove-Item $UpdateBG -Force -Recurse -ErrorAction SilentlyContinue

# Remove Adobe Flash Caches
Remove-Item $FlashCache -Force -Recurse -ErrorAction SilentlyContinue

# Clear Windows Update Cache
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\$SafeMode\WUAUSERV" /ve /t reg_sz /d Service /f 
Stop-Service WUAUSERV 
Remove-Item C:\Windows\SoftwareDistribution\Download -Recurse -ErrorAction SilentlyContinue
Start-Service WUAUSERV 

# Purge oldest VSS copies
net start VSS
vssadmin.exe delete shadows /for=$env:SystemDrive /oldest /quiet

#Remove Ninite Cache
Remove-Item $NiniteFolders -Force -Recurse -ErrorAction SilentlyContinue

# Reduce System Restore Space
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v DiskPercent /t REG_DWORD /d 00000007 /f 
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore\Cfg" /v DiskPercent /t REG_DWORD /d 00000007 /f 

#######################
## REMOVE BLOATWARE  ##
#######################

$Packages=@("*Lenovo*","*Dell*","*HP*","*WindowsStore*","*Twitter*","*3dbuilder*","*windowsalarms*","*windowscommunicationpackage*","*mcafee*""*windowscamera*","*officehub*","*skype*","*getstarted*","*zune*","*groove*","*windowsmaps*","*solitaire*","*bing*","*people*","*windowsphone*")
Foreach ($Package in $Packages) { Get-AppxPackage $Package -AllUsers | Remove-AppxPackage}


##########################
##  REMOVE WINDOWS.OLD  ##
##########################

If (Test-Path C:\Windows.old)
    {
        New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -Name "StateFlags1221" -PropertyType DWord -Value 2 -Force | Out-Null
        Start-Process cleanmgr.exe /SAGERUN:1221 -WindowStyle Hidden
    }

####################
##  DISM REMOVAL  ##
####################

If ($WindowsCheck -eq $true)
    {
        Get-WindowsFeature | where-object{$_.Installed -eq 0 -and $_.InstallState -eq 'Available'} | uninstall-windowsfeature -remove
    }

dism /online /cleanup-image /SPSuperseded
dism /online /cleanup-image /StartComponentCleanup /ResetBase

##################
## DRIVE FIXES  ##
##################

WMIC.exe computersystem set AutomaticManagedPagefile=True
Optimize-Volume C


#############################
##  WRITE FINAL LOG ENTRY  ##
#############################

$EndFree = (Get-Volume -DriveLetter C | Select SizeRemaining | foreach {$_.SizeRemaining})
$TotalFreed = ($EndFree - $StartFree) / 1MB

Clear-Host
Write-Host "Total Space Freed:" $TotalFreed "MB"
