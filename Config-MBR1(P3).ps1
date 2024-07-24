#VM's initial local admin:
[string]$userName = "tailwindtraders\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$DomainAdminCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#Store a password for DSRM
[string]$DSRMPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$SecureStringPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

Install-ADDSDomainController -DomainName "tailwindtraders.internal" -InstallDns:$true -Credential $DomainAdminCredObject -SafeModeAdministratorPassword $secStringPassword -Confirm -Force