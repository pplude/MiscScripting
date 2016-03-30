#################################
##  NEW COMPUTER SETUP SCRIPT  ##
#################################


#############################
##  Setup the Environment  ##
#############################

# Load .NET assemblies
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

# Make sure the script can continue
Set-ExecutionPolicy Unrestricted -Force

# Check for Admin Permissions
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		[System.Windows.Forms.MessageBox]::Show("User is not running as administrator. `n `n Please run this script through an Administrative Powershell.", "ERROR") | Out-Null
		[Environment]::Exit(5)
	}

# Install new Powershell Modules
Install-PackageProvider -Name Chocolatey -Force

####################
## System Checks  ##
####################

# Os Version Check
$OSVer = (Get-WmiObject Win32_OperatingSystem | Select-Object Caption | ForEach-Object {$_.Caption} | Select-String "Microsoft Windows 10 Pro" -SimpleMatch -Quiet)
If ($OSVer -eq $false)
    {
        [System.Windows.Forms.MessageBox]::Show("Operating System not supported by this utility.","Error") | Out-Null
        [System.Environment]::Exit(1)
    }
    
# Check Package Provider
$ChocoCheck = (Get-PackageProvider | Select-Object Name | foreach {$_.Name} | Select-String "Chocolatey" -SimpleMatch -Quiet)
If ($ChocoCheck -eq $false)
    {
        [System.Windows.Forms.MessageBox]::Show("Package Source Installation requires that Powershell be restarted.","Error") | Out-Null
        [System.Environment]::Exit(1)
        
    }
    
############################
##  Get User Information  ##
############################

$NewHostname = Read-Host "Please enter the new hostname:"


########################
##  Install Software  ##
########################

Install-Package jre8,irfanview,classic-shell,googlechrome,firefox,adobereader


#####################################
##  Delete the Recovery Partition  ##
#####################################

$RecoveryPart = (Get-Partition | Where-Object Type -Match "Recovery")
$RecoverySize = $RecoveryPart.Size
Remove-Partition $RecoveryPart
$MainPart = (Get-Partition | Where-Object DriveLetter -Match "C")
Resize-Partition -DriveLetter "C" -Size ($MainPart.Size + $RecoverySize)


########################
##  ENABLE BITLOCKER  ##
########################

Enable-BitLocker -TpmProtector -MountPoint "C" 
$RecoveryKey = (Get-BitLockerVolume -MountPoint "C").KeyProtector | Select-Object RecoveryPassword | foreach {$_.RecoveryPassword}


###################
##  DISABLE UAC  ##
###################

New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name "ConsentPromptBehaviorAdmin" -PropertyType DWord -Value 0 -Force


#############################
##  SET NEW POWER OPTIONS  ##
#############################

# New DG Power Plan, needs some tweaking
$PowerPlan = "DG"
$guid = (Get-WmiObject Win32_PowerPlan -Namespace rootcimv2power -Filter "ElementName='$PowerPlan'").InstanceID.tostring()
$regex = [regex]"{(.*?)}$"
$NewPower = $regex.Match($guid).Groups[1].Value
powercfg.exe -S $NewPower
powercfg.exe -change -standby-timeout-ac 0
powercfg.exe -change -standby-timeout-dc 0
powercfg.exe -hibernate off


####################
##  DISABLE APPS  ##
####################

Get-AppXPackage Microsoft.WindowsStore -AllUsers | Remove-AppxPackage
Get-AppxPackage -AllUsers | Select-Object Name | Select-String -SimpleMatch "Lenovo", "Dell", "HP" | Remove-AppxPackage

####################
##  WIN 10 FIXES  ##
####################

# Disable Telemetry
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Name AllowTelemetry -PropertyType DWord -Value 0
Set-Service -Name dmwappushservice -StartupType Disabled
Stop-Service 

# Disable Advertisising ID
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name "AdvertisingInfo" -PropertyType DWord -Value 0

# Disable Smart Screen
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost -Name "EnableWebContentEvaluation" -PropertyType DWord -Value 0

# Disable Wi-Fi Sense
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi -Name "AllowAutoConnectToWiFiSenseHotspots" -PropertyType DWord -Value 0

########################
##  GET INFO TO TECH  ##
########################

 [System.Windows.Forms.MessageBox]::Show("Bitlocker recovery key is:`n $RecoveryKey `n `n Please reboot the computer.","Complete"
 [System.Environment]::Exit(1)