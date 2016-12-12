# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Joins computer to CORP.CONTOSO.COM
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host 'Joins computer to CORP.CONTOSO.COM'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$DomainCred = Get-Credential

$result = Add-Computer -Credential $DomainCred -DomainName CORP.CONTOSO.COM -PassThru
#Add-Computer -Credential CORP\LabAdmin -DomainName CORP.CONTOSO.COM -PassThru


if($result.Success)
{
    Write-Host 'Domain Join Succeeded'
    if ($result.RestartNeeded)
    {
        Write-Host 'We need to restart the computer...'
        shutdown.exe -r -t 0
    }

}
else
{
    Write-Host 'Domain Join Failed'
}