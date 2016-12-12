# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
# Install the needed features
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$result = Install-WindowsFeature NET-Framework-Core, SMTP-Server

if($result.Success)
{
    Write-Host 'Features installed'
    if ($result.RestartNeeded)
    {
        Write-Host 'We need to restart the computer...'
        #shutdown.exe -r -t 0
    }

}
else
{
    Write-Host 'Feature Install Failed'
}
Get-WindowsFeature

