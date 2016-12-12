# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Configure MIM Portal Step #1
#------------------------------------------------------------------------------------------------------------------------------------------------------------

cd "F:\PowerShell Scripts\"
Import-Module .\MIMTools.psm1
New-MIMPortalQuickStart -AppPoolAccountName "corp\srvMIMSPPool" -CentralAdminUrl http://mim-core.corp.contoso.com -DatabaseServer "MIM-CORE" -FarmAccountName "corp\srvMIMSPFarm" -HostHeader "idweb.corp.contoso.com" -OwnerAccountName corp\LabAdmin -OwnerEmail "labadmin@corp.contoso.com" -PortalUrl "http://idweb.corp.contoso.com" –Verbose


