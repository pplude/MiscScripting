# Load the .NET 3.5 Assemblies needed
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null


#Check for Admin Rights
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		[System.Windows.Forms.MessageBox]::Show("User is not running as administrator. `n `n Please run this application as an Administrator.", "ERROR") | Out-Null
		[Environment]::Exit(5)
	}
# Hide Powershell Window
$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

# Do the work
$NetAdapter = (Get-WMIObject -Class Win32_NetworkAdapter -Filter 'AdapterType="Ethernet 802.3"')
foreach ($Adapter in $NetAdapter)
{
    $Adapter.Disable()
    $Adapter.Enable()
}

& ipconfig /release
& ipconfig /renew
& ipconfig /flushdns
& ipconfig /registerdns

[System.Windows.Forms.MessageBox]::Show("Process Completed Successfully.`n `n It may take up to 1 minute for network connection to be restored","Complete")
[Environment]::Exit(0)