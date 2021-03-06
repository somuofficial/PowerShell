############################################################
# Script Name: Verify No Blocked Processes                 #
# Team Name:   SS Service Automation                       #
# Creation Date: 25th Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would connect with MSSQL Server #
#              and execute SQL Query and fetch the result. #
# Inputs: DBDomain, DBUsername, DBPassword, DBHost,DB      #
############################################################

##### Variable Initialization ##############################
$secpasswd = $null
$mycreds = $null
$out = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$APID = "304"
$CIServer = "${DBHost}"
$ActivityName = "Verify No Blocked Processes"
$Des = "This Activity would check for any process is in Blcoked state or not"
$LogAccountName = "Administrator@ssautomation.com"

############ Importing Log Module ##########################
Try{
Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:1 ## StatusDesc:$_.Exception.Message"
Break}

############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null

############ Encrypting password ###########################
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)

############ Establishing Connection #######################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "${DBHost}" -Credential $mycreds

############ Starting Of Script Block ######################
$sc = {
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      invoke-sqlcmd -serverinstance "${DBHost}" -query "declare @databaseName varchar(100)
set @databaseName = N'AdventureWorks2008R2'
select *  from sysprocesses where blocked <> 0 and db_name(dbid) = @databaseName;
"

############ End Of Script Block ###########################
 }   

############ Sending Script Block To the Created Session ###    
try{
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc 
    if($out -eq $null)
    {
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "No Error" "No Blcoked Process Exists" | Out-Null
    '0'
    }
    else
    {
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "Error" "Blcoked Process Exists" | Out-Null
    $out
    }
}
catch
{ "StatusCode:1 ## StatusDesc: $_.Exception.Message "
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
 }
############ Garbaging Session #############################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################