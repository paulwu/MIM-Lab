# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
Import-Module ServerManager
$DomainCred = Get-Credential
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$start_time = Get-Date
Write-Host $start_time '> Start Script.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------


$result = Install-AdcsCertificationAuthority -CACommonName CORP-DC-CORP-CA -CADistinguishedNameSuffix "DC=CORP,DC=CONTOSO,DC=COM" -CAType EnterpriseRootCA -Credential $DomainCred -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" -DatabaseDirectory C:\Windows\system32\CertLog -HashAlgorithmName SHA256 -KeyLength 2048 -LogDirectory C:\Windows\system32\CertLog -ValidityPeriod Years -ValidityPeriodUnits 20 -Force -OverwriteExistingKey

if ($result.ErrorId -eq 0)
{
    Write-Host 'AD CS Configured'

    # Define CRL Publication Intervals 
    certutil -setreg CA\CRLPeriodUnits 12
    certutil -setreg CA\CRLPeriod "Months"
    
    # Define CRL Overlap
    certutil -setreg CA\CRLOverlapUnits 1
    certutil -setreg CA\CRLOverlapPeriod "Months"

    # Define Delta CRL (disabled)
    certutil -setreg CA\CRLDeltaPeriodUnits 0
    certutil -setreg CA\CRLDeltaPeriod "Days"


    #certutil -getreg CA\CRLPublicationURLs 

    certutil -setreg CA\CRLPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl\n15:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10"

    #certutil -getreg CA\CACertPublicationURLs 
    certutil -setreg CA\CACertPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n3:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11"


    # Enable all auditing events for the Root CA
    #certutil -getreg CA\AuditFilter
    certutil -setreg CA\AuditFilter 127

    # Set Validity Period for Issued Certificates
    certutil -setreg CA\ValidityPeriodUnits 10
    certutil -setreg CA\ValidityPeriod "Years"

    # Enable all auditing events, if not set, not everything will be enabled
    # Needed also to ensure event 4872 gets generated for new CRLs
    #auditpol /list
    auditpol /get /subcategory:"Certification Services" 
    auditpol /set /subcategory:"Certification Services" /success:enable /failure:enable

    # Restart Certificate Services
    net stop certsvc
    net start certsvc


}
else
{
    Write-Host 'AD CS Configuration Failed'

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$stop_time = Get-Date
Write-Host $stop_time '> Done. You are ready for the next step.'
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$duration = New-TimeSpan -Start $start_time -End $stop_time
Write-Host 'Duration = ' $duration
#------------------------------------------------------------------------------------------------------------------------------------------------------------




#Uninstall-AdcsCertificationAuthority -Force

