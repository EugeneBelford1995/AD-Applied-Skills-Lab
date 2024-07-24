$Gateway = "10.10.10.1"
$NIC = (Get-NetAdapter).InterfaceAlias
$IP = "10.10.10.10"

#Disable IPv6
Disable-NetAdapterBinding -InterfaceAlias $NIC -ComponentID ms_tcpip6

#Disable NetBIOS
$regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $regkey | ForEach {Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 2 -Verbose}

#Set IPv4 address, gateway, & DNS servers
New-NetIPAddress -InterfaceAlias $NIC -AddressFamily IPv4 -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DNSClientServerAddress -InterfaceAlias $NIC -ServerAddresses ("1.1.1.1", "8.8.8.8")

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Rename-Computer -NewName "Tailwind-DC1" -PassThru -Restart -Force