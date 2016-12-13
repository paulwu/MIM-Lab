# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Make sure .Net 3.5 with SP1 is installed
# mount the SQL install ISO image as drive E:
#------------------------------------------------------------------------------------------------------------------------------------------------------------
CD E:\
.\setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SQL,SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="CORP\srvSQL" /SQLSVCPASSWORD="P@ssw0rd" /AGTSVCSTARTUPTYPE=Automatic /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /SQLSYSADMINACCOUNTS="CORP\Labadmin"


