# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$start_time = Get-Date
Write-Host $start_time '> Start Script.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create the necessary service accounts accounts, groups, ACL, SPN, and DNS entries
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Create the necessary service accounts accounts, groups, ACL, SPN, and DNS entries'
#------------------------------------------------------------------------------------------------------------------------------------------------------------

Import-Module dnsserver
#Create DNS host record for the MIM Portal
Add-DnsServerResourceRecordA -Name idweb -ZoneName corp.contoso.com -IPv4Address 10.1.0.11
#End

#Create OUs,Service Accounts, and Groups in Corp Active Directory forest
$RootOUNames = "People","Groups","Service Accounts"
$RootOUNames|%{New-ADOrganizationalUnit -Name $_}
New-ADOrganizationalUnit -Name Disabled -Path (Get-ADOrganizationalUnit -Filter {Name -eq 'People'}|% distinguishedname)

$AccountNames = "srvMIMSPFarm","srvMIMSPPool","srvMIMSync","srvMIMMA","srvMIMService","srvMIMADMA", "srvSQL","srvADFS"

#$AccountNames = "srvSQL", "srvADFS"
$Password = "P@ssw0rd"
$AccountNames|%{New-ADUser -Name $_ -SamAccountName $_ -PasswordNeverExpires $true -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -force) -DisplayName $_ -Enabled $true -Path "OU=Service Accounts,DC=corp,DC=contoso,DC=com"}

$GroupNames = "MIMSyncAdmins","MIMSyncOperators","MIMSyncJoiners","MIMSyncBrowse","MIMSyncPasswordSet"
$GroupNames|%{New-ADGroup -Name $_ -DisplayName $_ -Description $_ -SamAccountName $_ -GroupCategory Security -GroupScope Global -Path "OU=Groups,DC=corp,DC=contoso,DC=com"}
#End

#Grant permissions to the MIM AD Management Ageent service account

dsacls "DC=corp,DC=contoso,DC=com" /G "srvMIMADMA@corp.contoso.com:CA;Replicating Directory Changes"
dsacls "OU=People,DC=corp,DC=contoso,DC=com" /I:T /G "srvMIMADMA@corp.contoso.com:GA"
dsacls "OU=Groups,DC=corp,DC=contoso,DC=com" /I:T /G "srvMIMADMA@corp.contoso.com:GA"
#End

#Define the Account Lockout Policy
Set-ADDefaultDomainPasswordPolicy -Identity corp.contoso.com -MinPasswordAge 0 -LockoutThreshold 3
#End

#Setup Kerberos for the MIM Portal
setspn -s HTTP/idweb.corp.contoso.com CORP\srvMIMSPPool
setspn -s FIMService/idweb.corp.contoso.com CORP\srvMIMService
Set-ADUser srvMIMSPPool -Add @{"msDS-AllowedToDelegateTo"="FIMService/idweb","FIMService/idweb.corp.contoso.com"}
#End


#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Add the CORP\LabAdmin account to the CORP\MIMSyncAdmins group:
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Add-ADGroupMember MIMSyncAdmins -Members LabAdmin


#------------------------------------------------------------------------------------------------------------------------------------------------------------
$stop_time = Get-Date
Write-Host $stop_time '> Done. You are ready for the next step.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$duration = New-TimeSpan -Start $start_time -End $stop_time
Write-Host 'Duration = ' $duration
#------------------------------------------------------------------------------------------------------------------------------------------------------------


