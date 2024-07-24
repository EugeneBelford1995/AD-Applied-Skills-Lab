#Store a password for DSRM
[string]$DSRMPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$SecureStringPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

#Create New Forest, add Domain Controller
$DomainName = "tailwindtraders.internal"
$NetBIOSName = "tailwindtraders"
Install-ADDSForest -CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName $DomainName `
-DomainNetbiosName $NetBIOSName `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true `
-SafeModeAdministratorPassword $SecureStringPassword