#VM's initial local admin:
[string]$userName = "tailwindtraders\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$DomainAdminCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Add-Computer -DomainName "tailwindtraders.internal" -Credential $DomainAdminCredObject -Restart -Force