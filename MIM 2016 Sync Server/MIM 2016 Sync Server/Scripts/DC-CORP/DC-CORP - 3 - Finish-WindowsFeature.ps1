# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Install Features: ADDS, Group Policy Management Console, Remote Admin Tools for AD
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Install Features: Admin Tools for DNS, AD CS, and AD FS'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Install-WindowsFeature RSAT-DNS-Server,AD-Certificate,ADCS-Cert-Authority,ADFS-Federation, RSAT-ADCS, RSAT-ADCS-Mgmt -restart

$result = Install-WindowsFeature RSAT-ADCS, RSAT-ADCS-Mgmt

if($result.Success)
{
    Write-Host 'Install Windows Feature Succeeded'
    if ($result.RestartNeeded)
    {
        Write-Host 'We need to restart the computer...'
        shutdown.exe -r -t 0
    }

}
else
{
    Write-Host 'Install Windows Feature Failed'

}

#Get-WindowsFeature

