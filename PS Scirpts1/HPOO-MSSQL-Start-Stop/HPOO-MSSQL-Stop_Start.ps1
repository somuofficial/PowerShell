$secpasswd = ConvertTo-SecureString "${Password}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\${Username}", $secpasswd)
$sess = New-PSSession -ComputerName "${Host}" -Credential $mycreds
$sc = {
    $a = Get-Service Mssqlserver | Select-Object -ExpandProperty Status
    if ($a -eq "Running")
    {
        stop-service Mssqlserver -force 
        $b = Get-Service Mssqlserver | Select-Object -ExpandProperty Status
        if ($b -eq "Stopped")
        {
            Start-Sleep -s 5
            Start-Service Sqlserveragent
            $t = Get-Service MssqlServer | Select-Object -ExpandProperty Status
                if ($t -eq "Running")
                {
                'Restarted'
                }
                else
                {
                'Not Started'
                }
         }
        else
        {
        'SQL Service did not Stop'
        $b
        }
    }
    else
    {
    'MSSQL Service Not Running '
    }
 }   
    
Invoke-Command -Session $sess -ScriptBlock $sc
Remove-PSSession $sess