$ADRoot = (Get-ADDomain).DistinguishedName
$FQDN = (Get-ADDomain).DNSRoot

#Store a password for users
[string]$DSRMPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$UserPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

$OUs = "Sydney,Melbourne,Brisbane" 
$OUs = $OUs.split(",")
ForEach($OU in $OUs)
{
New-ADOrganizationalUnit -Name "$OU" -Path "$ADRoot" -Description "OU for employees in $OU"
Start-Sleep -Seconds 10
$User = $OU + "Contractor"
New-ADUser -SamAccountName $User -Name $User -UserPrincipalName "$User@$FQDN" -AccountPassword $UserPassword -Path "ou=$OU,$ADRoot" -Enabled $true -Description "CTR for $OU" -PasswordNeverExpires $true
}

New-ADGroup "Sydney Administrators" -GroupScope Universal -Path "ou=sydney,$ADRoot"
Add-ADGroupMember -Identity "Sydney Administrators" -Members "SydneyContractor"
Add-ADGroupMember -Identity "Protected Users" -Members "SydneyContractor"
Set-ADUser -Identity "SydneyContractor" -City "Sydney" -AccountExpirationDate "1 Jan 2030"

Disable-ADAccount "MelbourneContractor"
Set-ADAccountPassword -Identity "BrisbaneContractor" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Pa66w.rdPa66w.rd" -Force)

New-ADComputer -Name Tailwind-MBR1 -SAMAccountName Tailwind-MBR1 -DisplayName Tailwind-MBR1 -Path "ou=domain controllers,$ADRoot"

#Create a new site
New-ADReplicationSite -Name "Sydney" -Description "Site for new facility in Sydney."
Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -SitesIncluded @{Add="Sydney"}

#Map the new site to a subnet
New-ADReplicationSubnet -Name "172.16.1.0/24" -Site "Sydney"

# --- Delegatin of rights on the Sydney OU ---

#Delegate "Sydney Administrators" reset password & force password change on the Sydney OU
#ExtendedRight 00299570-246d-11d0-a768-00aa006e0529
#WriteProperty 60b10d64-0f1b-465f-8cc0-bef2de541343 (CW6 Google pointed to this one, however use the 2 below as per Microsoft)
#WriteProperty bf967a0a-0de6-11d0-a285-00aa003049e2
#ReadProperty  bf967a0a-0de6-11d0-a285-00aa003049e2

Set-Location AD:
$victim = (Get-ADOrganizationalUnit "ou=Sydney,$ADRoot" -Properties *).DistinguishedName
$acl = Get-ACL $victim
$user = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup -Identity "Sydney Administrators").SID

#Allow specific password reset
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,"ExtendedRight","ALLOW",([GUID]("00299570-246d-11d0-a768-00aa006e0529")).guid,"Descendents",([GUID]("bf967aba-0de6-11d0-a285-00aa003049e2")).guid))

#Allow specific WriteProperty on the 'user must change password at next login' attribute
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,"WriteProperty","ALLOW",([GUID]("bf967a0a-0de6-11d0-a285-00aa003049e2")).guid,"Descendents",([GUID]("bf967aba-0de6-11d0-a285-00aa003049e2")).guid))
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user,"ReadProperty","ALLOW",([GUID]("bf967a0a-0de6-11d0-a285-00aa003049e2")).guid,"Descendents",([GUID]("bf967aba-0de6-11d0-a285-00aa003049e2")).guid))

#Apply above ACL rules
Set-ACL $victim $acl