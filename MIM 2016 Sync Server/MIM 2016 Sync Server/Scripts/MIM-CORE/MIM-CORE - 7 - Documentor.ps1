# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
mkdir 'C:\MCS FIM Documenter\Data\MIM2016.OOBInstall\ServiceConfig'
mkdir 'C:\MCS FIM Documenter\Data\MIM2016.OOBInstall\SyncConfig'



cd "C:\MCS FIM Documenter"

$systemName="MIM2016.OOBInstall";export-fimpolicyforDoc -systemname $systemname -verbose;export-fimschemafordoc -systemname $systemname -verbose

