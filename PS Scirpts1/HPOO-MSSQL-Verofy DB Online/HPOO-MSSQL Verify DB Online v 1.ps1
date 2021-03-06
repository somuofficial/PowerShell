############################################################
# Script Name: Verify MSSQL Database Online                #
# Team Name:   SS Service Automation                       #
# Creation Date: 23rd Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script checks that the MSSQL database  #
#              is online or not.                           #
############################################################
##### Variable Initialization ##############################
$Ping = $null 
$secpasswd = $null
$mycreds = $null
##### Encrypting password ##################################
$secpasswd = ConvertTo-SecureString ${DBPassword} -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential (${DBUsername}, $secpasswd)
$sess = New-PSSession -ComputerName ${DBHost} -Credential $mycreds   

##### Connectivity Test ####################################
$Ping = Test-Connection -ComputerName ${DBHost} -Quiet
if ($Ping -eq $True)
{
##### Creating Session #####################################
$sc = { 
        Import-module SqlPs -DisableNameChecking | Out-Null
        Invoke-Sqlcmd -Query "-- DB status---

SELECT name,DATABASEPROPERTYEX(name, 'status') as status , 
                                                                       DATABASEPROPERTYEX(name, 'UserAccess') as useraccess ,DATABASEPROPERTYEX(name, 'Updateability') as Updateability 
                        ,DATABASEPROPERTYEX(name, 'IsInStandBy') as IsInStandBy 
                        from master..sysdatabases 
                        where databaseproperty(name, 'IsReadOnly') = 1 or databaseproperty(name, 'IsInStandBy') = 1 
                        or databaseproperty(name, 'IsInRecovery') = 1 or databaseproperty(name, 'IsInLoad') = 1 
                        or databaseproperty(name, 'IsSuspect') = 1 or databaseproperty(name, 'IsSingleUser') = 1 
                        or databaseproperty(name, 'IsOffline') = 1 or databaseproperty(name, 'IsNotRecovered') = 1 
                        or databaseproperty(name, 'IsDboOnly') = 1 or databaseproperty(name, 'IsEmergencyMode') = 1 or cast(DATABASEPROPERTYEX(name,'status')as varchar) not like 'ONLINE'

" -ServerInstance ${DBInstance}
      }
try{
Invoke-Command -Session $sess -ScriptBlock $sc
}
catch{ "StatusCode:1"+" ## StatusDesc:"+ $_.Exception.Message }
Remove-PSSession $sess
}
else
{
"StatusCode:1 ## StatusDesc:Connectitvity error on Verify DB Online Node"
}