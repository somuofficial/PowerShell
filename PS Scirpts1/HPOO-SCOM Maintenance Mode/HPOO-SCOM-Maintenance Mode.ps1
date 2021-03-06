$secpasswd = ConvertTo-SecureString "${SCOMPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${SCOMDomain}\${Username}", $secpasswd)
$sess = New-PSSession -ComputerName "${SCOMHost}" -Credential $mycreds
$sc = {
    Import-Module OperationsManager
    $Instance = Get-ScomclassInstance -Name ${SqlHost}.sqlclusters.net
    $Time = ((Get-Date).AddMinutes(${Time}))
    Start-ScomMaintenanceMode -Instance $Instance -EndTime $Time -Reason "${Reason}" -comment "${Comment}"
    $Ex =  Get-SCOMClassInstance -Name ${SqlHost}.sqlclusters.net | Select-Object -ExpandProperty InMaintenanceMode
        if($Ex -eq $True)
        {
        'MSSQL Server is in Maintenance Mode'
        }
        else
        {
        'There is some problem in taking server in Maintenance mode'
        }
    }   
    
Invoke-Command -Session $sess -ScriptBlock $sc
Remove-PSSession $sess