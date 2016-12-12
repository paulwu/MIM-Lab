# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# DC PROMO for CORP.CONTOSO.COM
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Prepare to install AD DS Forest (DC PROMO). After this step, you will be asked to restart the computer.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "Win2012R2" `
-DomainName "CORP.CONTOSO.COM" `
-DomainNetbiosName "CORP" `
-ForestMode "Win2012R2" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
