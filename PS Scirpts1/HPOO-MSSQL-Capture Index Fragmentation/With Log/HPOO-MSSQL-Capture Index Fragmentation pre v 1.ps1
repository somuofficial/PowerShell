############################################################
# Script Name: Capture Current Index Fragment MSSQL        #
# Team Name:   SS Service Automation                       #
# Creation Date: 18th Feb 2016                             #
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
$APID = "303"
$CIServer = "${DBHost}"
$ActivityName = "Capture Current Index Fragment MSSQL"
$Des = "This Activity would Capture fragmentation details Pre rebuild reorganise"
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
$secpasswd = ConvertTo-SecureString ${DBPassword} -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)

############ Establishing Connection #######################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName ${DBHost} -Credential $mycreds

############ Starting Of Script Block ######################
$sc = {
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      invoke-sqlcmd -serverinstance ${DBHost} -query "use ${DB}; DECLARE @DBID INT 
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
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc | Out-File ${flocation}
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Saving Index Fragmentation Details in ${flocation}" | Out-Null
}
catch
{ "StatusCode:1 ## StatusDesc: $_.Exception.Message " 
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
}
############ Garbaging Session #############################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################