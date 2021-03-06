#############################################################
# Script Name: BackupDB_MSSQL                         #
# Team Name:   SS Service Automation                        #
# Creation Date: 15th March 2016                            #
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
$ActivityName = "BackupDB_MSSQL"
$Des = "This Activity would take MSSQL DB Backup"
$LogAccountName = "Administrator@ssautomation.com"
 
Try{
    Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
    catch{"StatusCode:10StatusDesc:$_.Exception.Message"
    Break
}

############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null

############ Encrypting passwords ###########################
$secpasswd = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd)

############ Establishing Connections #######################
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "Node01" -Credential $mycreds

############ Starting Of Script Block ######################
$DB = "ReportServer"
$DBSourceHost = "Node02"
$DBSInstance = "Node02"
$Named = $fasle
$sc = {
      param($Named,$DB,$DBSourceHost,$DBSInstance)
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
         if($Named -eq $true)
         {
          $BkpDrive = (((((Invoke-Sqlcmd -Query "EXEC  master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory'" -ServerInstance $DBSourceHost\$DBSInstance) | Select-Object -ExpandProperty Data) -split '\\')[0]) -split ':')[0]
          $DriveSpaceAvl = (Get-PSDrive -Name $BkpDrive | Select-Object -ExpandProperty Free)/1MB
          $DBSize = ((((((Invoke-Sqlcmd -Query "EXEC sp_helpdb $DB;" -ServerInstance $DBSourceHost\$DBSInstance) | Select-Object -Property db_size) -split '=')[1] ) -split '}')[0]).tostring()
          $DBSize = $DBSize.Substring(0, $DBSize.indexof('M'))
          if ($DBSize -gt $DriveSpaceAvl)
          {
          'StatusCode:10StatusDesc: DriveSpace is Not Available'
          Break
          }
          Try{
                Backup-SqlDatabase -ServerInstance $DBSourceHost\$DBSInstance -Database $DB -erroraction Stop
          
                ############ Check Backup Size #############################
                  $BkpSize = invoke-sqlcmd "SELECT
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
                msdb.dbo.backupset.backup_finish_date  desc" -ServerInstance $DBSourceHost\$DBSInstance
        
                $BkpSize = ($BkpSize | Where-Object {$_.backup_type -eq "Database"}) | Sort-Object -Property backup_finish_date | Select-Object -Last 1
                ($BkpSize.backup_size)/1MB
            }
        catch { StatusCode10:StatusDesc:$_.Exception.Message }    
        }
          
        else
        {
          $BkpDrive = (((((Invoke-Sqlcmd -Query "EXEC  master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory'" -ServerInstance $DBSourceHost) | Select-Object -ExpandProperty Data) -split '\\')[0]) -split ':')[0]
          $DriveSpaceAvl = (Get-PSDrive -Name $BkpDrive | Select-Object -ExpandProperty Free)/1MB
          $DBSize = ((((((Invoke-Sqlcmd -Query "EXEC sp_helpdb $DB;" -ServerInstance $DBSourceHost) | Select-Object -Property db_size) -split '=')[1] ) -split '}')[0]).tostring()
          $DBSize = $DBSize.Substring(0, $DBSize.indexof('M'))
          if ($DBSize -gt $DriveSpaceAvl)
          {
            'StatusCode:10StatusDesc: DriveSpace is Not Available'
             Break
          }
          Try{
            Backup-SqlDatabase -ServerInstance $DBSourceHost -Database $DB -erroraction Stop
          
              ############ Check Backup Size #############################
              $BkpSize = invoke-sqlcmd "SELECT
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
            msdb.dbo.backupset.backup_finish_date  desc" -ServerInstance $DBSourceHost
        
            $BkpSize = ($BkpSize | Where-Object {$_.backup_type -eq "Database"}) | Sort-Object -Property backup_finish_date | Select-Object -Last 1
            ($BkpSize.backup_size)/1MB
        }
        catch { StatusCode10:StatusDesc:$_.Exception.Message }    
        }
      }
     ############### End Of Script Block ###########################
         

############ Sending Script Block To the Created Session ###    
try{
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList $Named,$DB,$DBSourceHost,$DBSInstance
}
catch
{ "StatusCode:10StatusDesc: $_.Exception.Message "
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
 }
############ Garbaging Session #############################
Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################


