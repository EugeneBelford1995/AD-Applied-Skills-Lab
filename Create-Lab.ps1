Function Create-SW
{
#Show how to enable Hyper-V & create a VMSwitch
New-VMSwitch -SwitchName "NATSwitch" -SwitchType Internal
New-NetIPAddress -IPAddress 10.10.10.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NATSwitch)"
New-NetNat -Name "NATNetwork" –InternalIPInterfaceAddressPrefix "10.10.10.0/24"
#Confirm: Get-NetIPAddress | Select-Object IPAddress, InterfaceAlias
}

Function Create-VM
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $VMName,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $IP
    )

#Creates the VM from a provided ISO & answer file, names it provided VMName
Set-Location "C:\VM_Stuff_Share\AD Class"
$isoFilePath = "..\ISOs\Windows Server 2022 (20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us).iso"
$answerFilePath = ".\2022_autounattend.xml"

New-Item -ItemType Directory -Path C:\Hyper-V_VMs\$VMName

$convertParams = @{
    SourcePath        = $isoFilePath
    SizeBytes         = 100GB
    Edition           = 'Windows Server 2022 Datacenter Evaluation (Desktop Experience)'
    VHDFormat         = 'VHDX'
    VHDPath           = "C:\Hyper-V_VMs\$VMName\$VMName.vhdx"
    DiskLayout        = 'UEFI'
    UnattendPath      = $answerFilePath
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
. '..\Convert-WindowsImage (from PS Gallery)\Convert-WindowsImage.ps1'

Convert-WindowsImage @convertParams

New-VM -Name $VMName -Path "C:\Hyper-V_VMs\$VMName" -MemoryStartupBytes 6GB -Generation 2
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 6GB -StartupBytes 6GB -MaximumBytes 8GB
Connect-VMNetworkAdapter -VMName $VMName -Name "Network Adapter" -SwitchName "NATSwitch"
$vm = Get-Vm -Name $VMName
$vm | Add-VMHardDiskDrive -Path "C:\Hyper-V_VMs\$VMName\$VMName.vhdx"
$bootOrder = ($vm | Get-VMFirmware).Bootorder
#$bootOrder = ($vm | Get-VMBios).StartupOrder
if ($bootOrder[0].BootType -ne 'Drive') {
    $vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
    #Set-VMBios $vm -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
}
Start-VM -Name $VMName
}#Close the Create-VM function

Create-SW
Write-Host "Creating VMSwitch, please standby ..."
Start-Sleep -Seconds 30

Create-VM -VMName Tailwind-DC1
Create-VM -VMName Tailwind-MBR1
Write-Host "Please wait, the VMs are booting up."
Start-Sleep -Seconds 180

#VM's initial local admin:
[string]$userName = "Changme\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$InitialCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#VM's local admin after re-naming the computer:
[string]$userName = "Tailwind-DC1\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$DC1LocalCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#VM's Domain Admin:
[string]$userName = "tailwindtraders\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$DomainAdminCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -VMName Tailwind-DC1 -FilePath '.\Config-DC1(P1).ps1' -Credential $InitialCredObject
Start-Sleep -Seconds 120
Invoke-Command -VMName Tailwind-DC1 -FilePath '.\Config-DC1(P2).ps1' -Credential $DC1LocalCredObject
Start-Sleep -Seconds 300
Invoke-Command -VMName Tailwind-DC1 -FilePath '.\Config-DC1(P3).ps1' -Credential $DomainAdminCredObject

#Make the second VM a DC, then move the one FSMO role
#VM's initial local admin:
[string]$userName = "Tailwind-DC1\Administrator"
[string]$userPassword = 'Pa55w.rdPa55w.rd'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$MBR1LocalCredObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -VMName Tailwind-MBR1 -FilePath '.\Config-MBR1(P1).ps1' -Credential $InitialCredObject
Start-Sleep -Seconds 120
Invoke-Command -VMName Tailwind-MBR1 -FilePath '.\Config-MBR1(P2).ps1' -Credential $MBR1LocalCredObject
Start-Sleep -Seconds 120
Invoke-Command -VMName Tailwind-MBR1 -FilePath '.\Config-MBR1(P3).ps1' -Credential $DomainAdminCredObject

Start-Sleep -Seconds 300
#move the RID Master role to Tailwind-MBR1
Invoke-Command -VMName Tailwind-DC1 {Move-ADDirectoryServerOperationMasterRole -Identity Tailwind-MBR1 -OperationMasterRole RIDMaster -Confirm} -Credential $DomainAdminCredObject

#Enable the AD Recycle Bin
Invoke-Command -VMName Tailwind-DC1 {Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target tailwindtraders.internal -Confirm} -Credential $DomainAdminCredObject
