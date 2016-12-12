# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$start_time = Get-Date
Write-Host $start_time '> Start Script.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Install Features: ADDS, Group Policy Management Console, Remote Admin Tools for AD
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Install Features: ADDS, Group Policy Management, Remote Server Administration Tools for AD'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Install-WindowsFeature AD-Domain-Services,GPMC,RSAT,RSAT-Role-Tools,RSAT-AD-Tools,RSAT-AD-PowerShell,RSAT-ADDS,RSAT-AD-AdminCenter,RSAT-ADDS-Tools

#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Set Static IP - this is required for a Domain Controller so it must be done before DC PROMO
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Setting Static IP. You may lose Remote Desktop connection as part of this process. Reconnect if necessary.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------

$IP = "10.1.0.10"
$MaskBits = 24 # This means subnet mask = 255.255.255.0
$Gateway = "10.1.0.1"
$Dns = "10.1.0.10"
$IPType = "IPv4"

$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}

 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $IP `
    -PrefixLength $MaskBits `
    -DefaultGateway $Gateway

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS



#------------------------------------------------------------------------------------------------------------------------------------------------------------
$stop_time = Get-Date
Write-Host $stop_time '> Done. You are ready for the next step.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$duration = New-TimeSpan -Start $start_time -End $stop_time
Write-Host 'Duration = ' $duration
#------------------------------------------------------------------------------------------------------------------------------------------------------------


