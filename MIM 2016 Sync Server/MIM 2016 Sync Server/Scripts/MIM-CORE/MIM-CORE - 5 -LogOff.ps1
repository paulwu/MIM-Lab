# Created by Paul Wu (moi@paulwu.net)
# v.1.0.0
#------------------------------------------------------------------------------------------------------------------------------------------------------------
$currentUserName = "labadmin"

$users = quser /server:MIM-CORE
foreach ($user in $users)
{
    $qresult = [string]$user
    if ($qresult.Contains($currentUserName))
    {
        $list = $qresult.Split(" ")
        $fields = New-Object System.Collections.ArrayList
        foreach ($item in $list)
        {
            if ($item.Length -gt 0)
            {
                $fields.Add($item)
                Write-Host 'added ' $item
            }
        }
        $sesionId = $fields[2]
        Write-Host 'session id ' + $sesionId 
        break;
    }
    else
    {
        Write-Host 'line skipped'
    }
}
#$sesionId



logoff /Server:MIM-CORE $sesionId /v
