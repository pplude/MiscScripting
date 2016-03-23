#Check for Admin Rights
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		# Error Code goes here
		[Environment]::Exit(5)
	}
