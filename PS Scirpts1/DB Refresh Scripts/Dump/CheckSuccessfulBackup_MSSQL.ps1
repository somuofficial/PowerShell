#############################################################
# Script Name: CheckSuccesfulBackup                         #
# Team Name:   SS Service Automation                        #
# Creation Date: 14th March 2016                            #
# Created By: Somnath Sarkar                                #
# Description: This Script would connect with MSSQL Server  #
#              and Fetch the details about last Full        #
#              successful Backup                            #
# Inputs: DBDomain, DBUsername, DBPassword, DBHost,DB       #
#############################################################

##### Variable Initialization ###############################
$secpasswd = $null
$mycreds = $null
$out = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$APID = "411"
$CIServer = "${DBSourceHost}"
$ActivityName = "CheckSuccessfulBackup"
$Des = "This Activity would check last successful backup information in source database"
$LogAccountName = "Administrator@ssautomation.com"
$DB = "ReportServer"

############ Importing Log Module ##########################
Try{
Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:10StatusDesc:$_.Exception.Message"
Break}

############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null

############ Encrypting passwords ###########################
$secpasswd = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd)

############ Establishing Connections #######################
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "Node02" -Credential $mycreds

############ Starting Of Script Block ######################
$sc = {
      param($DB)
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      invoke-sqlcmd "SELECT
    CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
    msdb.dbo.backupset.database_name,
    msdb.dbo.backupset.backup_finish_date,  
    CASE msdb..backupset.type  
       WHEN 'D' THEN 'Database'  
       WHEN 'L' THEN 'Log'  
    END AS backup_type,  
    msdb.dbo.backupset.backup_size,  
    msdb.dbo.backupmediafamily.logical_device_name,  
    msdb.dbo.backupmediafamily.physical_device_name   
    FROM   msdb.dbo.backupmediafamily  
    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
    WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 2)  
    and  msdb.dbo.backupset.database_name = '$DB' 
    ORDER BY  
    msdb.dbo.backupset.database_name, 
    msdb.dbo.backupset.backup_finish_date  desc"

      ############ End Of Script Block ###########################
      }   

############ Sending Script Block To the Created Session ###    
try{
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList $DB
$out = ($out | Where-Object {$_.backup_type -eq "Database"}) | Sort-Object -Property backup_finish_date | Select-Object -Last 1
#$out | Select-Object -ExpandProperty physical_device_name
}
catch
{ "StatusCode:10StatusDesc: $_.Exception.Message "
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
 }
############ Garbaging Session #############################
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################


