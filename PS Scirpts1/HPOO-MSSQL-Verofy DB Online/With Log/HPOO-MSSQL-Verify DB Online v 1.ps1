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
$out = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$APID = "302"
$CIServer = "${DBHost}"
$ActivityName = "Verify DB Online"
$Des = "This Activity would check wheather any MSSQL is offline"
$LogAccountName = "Administrator@ssautomation.com"

############ Importing Log Module ##########################
Try{
Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:1 ## StatusDesc:$_.Exception.Message"
Break}
############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "WorkFlow Variable Passed: DBUsername-${DBUsername},DBPassword-${DBPassword},DBHost-${DBHost}" | Out-Null

##### Encrypting password ##################################
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)
   

##### Connectivity Test ####################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Testing Connectivity with Remote Machine" | Out-Null
$Ping = Test-Connection -ComputerName "${DBHost}" -Quiet
if ($Ping -eq $True)
{
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Connectivity test with Remote Machine successful" | Out-Null

############ Establishing Connection #######################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "${DBHost}" -Credential $mycreds

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

" -ServerInstance "${DBInstance}"
      }
try{
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc
    if($out -eq $null)
    {
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "No Error" "All Databases are Online" | Out-Null
    '0'
    }
    else
    {
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "Error" "One or Multiple Databases are Offline" | Out-Null
    $out
    }
}
catch{ "StatusCode:1"+" ## StatusDesc:"+ $_.Exception.Message 
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "Error" "Issue:$_.Exception.Message" | Out-Null
}
Remove-PSSession $sess
}
else
{
"StatusCode:1 ## StatusDesc:Connectitvity error on Verify DB Online Node"
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "Connectivity test with Remote Machine failed" | Out-Null
}