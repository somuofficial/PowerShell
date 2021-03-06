############################################################
# Script Name: Capture Current Index Fragment MSSQL        #
# Team Name:   SS Service Automation                       #
# Creation Date: 18th Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would connect with MSSQL Server #
#              and execute SQL Query and fetch the result. #
# Inputs: DBDomain, DBUsername, DBPassword, DBHost,DB      #
############################################################

##### Creating Connection with Encrypted password ##########
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)
$sess = New-PSSession -ComputerName "${DBHost}" -Credential $mycreds

############ Starting Of Script Block ######################
$sc = {
      param($DB)
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      invoke-sqlcmd -serverinstance "${DBHost}" -query "use $DB; DECLARE @DBID INT 
        SELECT @DBID = DB_ID() 

        --- Identifying the High / Low Fragmentation of Table(s) in the active Database 
        SELECT OBJECT_NAME([OBJECT_ID]) 'TABLE NAME',
        INDEX_TYPE_DESC 'INDEX TYPE',IND.[NAME],
        AVG_FRAGMENTATION_IN_PERCENT '% FRAGMENTED' 
        FROM sys.dm_db_index_physical_stats(@DBID, NULL, NULL, NULL, NULL) JOIN sys.sysindexes IND 
        ON (IND.ID =[OBJECT_ID] AND IND.INDID = INDEX_ID) 
        WHERE AVG_FRAGMENTATION_IN_PERCENT = 0 
        AND DATABASE_ID = @DBID 
        AND IND.FIRST IS NOT NULL 
        AND IND.[NAME] IS NOT NULL 
        ORDER BY avg_fragmentation_in_percent DESC"

############ End Of Script Block ###########################
 }   

############ Sending Script Block To the Created Session ###    
try{
$out = Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList ${DB}  | Out-File ${flocation}
}
catch
{ "StatusCode:1 ## StatusDesc: $_.Exception.Message " }
############ Garbaging Session #############################
Remove-PSSession $sess

############ End Of Script #################################