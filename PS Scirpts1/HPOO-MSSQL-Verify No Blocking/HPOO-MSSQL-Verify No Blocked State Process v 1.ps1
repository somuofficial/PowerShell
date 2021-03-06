############################################################
# Script Name: Verify Blocked Stated Process MSSQL         #
# Team Name:   SS Service Automation                       #
# Creation Date: 18th Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would connect with MSSQL Server #
#              and execute SQL Query and fetch the result  #
#              to check that if any process is in blocked  #
#              State.                                      #
# Inputs: DBDomain, DBUsername, DBPassword, DBHost         #
############################################################

##### Creating Connection with Encrypted password ##########
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)
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
$out = Invoke-Command -Session $sess -ScriptBlock $sc 
    if($out -eq $null)
    {
    '0'
    }
    else
    {
    $out
    }
}
catch
{ "StatusCode:1 ## StatusDesc: $_.Exception.Message " }
############ Garbaging Session #############################
Remove-PSSession $sess

############ End Of Script #################################