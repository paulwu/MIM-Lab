# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0

Import-Module GroupPolicy

Get-GPO -Name 'Default Domain Policy'

$gpo = Get-GPO -All | ? { $_.DisplayName -eq 'Default Domain Policy'}
$gpo







set-location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"  
set-location ZoneMap\Domains  
new-item BRAD-SERVER  
set-location BRAD-SERVER  
new-itemproperty . -Name http -Value 2 -Type DWORD  



Get-GPRegistryValue -Name "Default Domain Policy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" 
Get-GPRegistryValue -Name "Default Domain Policy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains" 

Get-GPRegistryValue -Key "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\" -Name "Default Domain Policy"

Get-GPRegistryValue -Key "HKEY_CURRENT_USER:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "Default Domain Policy"


$gpoName = "Trusted Site Policy"
$newGpo = New-GPO -Name $gpoName


#set the three registry keys in the Preferences section of the new GPO
Set-GPPrefRegistryValue -Name $gpoName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config' `
-Type DWord  -ValueName 'AnnounceFlags' -Value 5 | out-null


Set-GPPrefRegistryValue -Name $GPOName 
"HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

Set-GPPrefRegistryValue -Name $GPOName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' `
-Type String -ValueName 'NtpServer' -Value $TimeServer | out-null
 
Set-GPPrefRegistryValue -Name $GPOName -Action Update -Context Computer `
-Key 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' `
-Type String -ValueName 'Type' -Value 'NTP' | out-null
 
#link the new GPO to the Domain Controllers OU
New-GPLink -Name $GPOName `
-Target $TargetOU | out-null