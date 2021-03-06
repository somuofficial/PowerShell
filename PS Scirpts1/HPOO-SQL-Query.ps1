$secpasswd = ConvertTo-SecureString ${DBPassword} -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBDomain}\${DBUsername}", $secpasswd)
$sess = New-PSSession -ComputerName ${DBHost} -Credential $mycreds   
$sc = { 
        Import-module SqlPs -DisableNameChecking | Out-Null
        Invoke-Sqlcmd -Query "select @@SPID as current_process,
    P.spid
,   right(convert(varchar, 
            dateadd(ms, datediff(ms, P.last_batch, getdate()), '1900-01-01'), 
            121), 12) as 'batch_duration'
,   P.program_name
,   P.hostname
,   P.loginame
from master.dbo.sysprocesses P
where P.spid > 50
and      P.status not in ('background', 'sleeping')
and      P.cmd not in ('AWAITING COMMAND'
                    ,'MIRROR HANDLER'
                    ,'LAZY WRITER'
                    ,'CHECKPOINT SLEEP'
                    ,'RA MANAGER')" -ServerInstance ${DBInstance}
      }
Invoke-Command -Session $sess -ScriptBlock $sc
Remove-PSSession $sess