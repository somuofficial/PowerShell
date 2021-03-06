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
$Des = "This Activity would check wheather MSSQL DB is offline"
$LogAccountName = "Administrator@ssautomation.com"

############ Importing Log Module ##########################
Try{
Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:10StatusDesc:$_.Exception.Message"
Break}
############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "WorkFlow Variable Passed: DBUsername-${DBUsername},DBPassword-${DBPassword},DBHost-${DBHost}" | Out-Null

    ##### Variables ############################################
    $DBS="onoffdb"
    $DBT="ReportServer"
    $DBSourceHost="Node01"
    $DBTargetHost="Node02"
    $DBSInstance = "SQL02"
    $DBTInstance = " "
    $SNamed = "True"
    $TNamed = "False"
    $DBSUsername = "sqlclusters\administrator"
    $DBTUsername = "sqlclusters\administrator"
    $DBSPassword = "Database@1234"
    $DBTPassword = "Database@1234"
    
    ##### Encrypting password ##################################
    $secpasswd = ConvertTo-SecureString $DBSPassword -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($DBSUsername, $secpasswd)

    $secpasswd1 = ConvertTo-SecureString $DBTPassword -AsPlainText -Force
    $mycreds1 = New-Object System.Management.Automation.PSCredential ($DBTUsername, $secpasswd1)

    ############ Establishing Connection #######################
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
    $sess = New-PSSession -ComputerName $DBSourceHost -Credential $mycreds
    $sess1 = New-PSSession -ComputerName $DBTargetHost -Credential $mycreds1

    $sc = { 
            param($Named,$DB,$DBHost,$DBInstance)
            Import-module SqlPs -Ea stop -WarningAction silentlycontinue | Out-Null
            if($Named -eq $True)
            {
                Invoke-Sqlcmd -Query "SELECT DATABASEPROPERTYEX('$DB', 'Status') as Status
                GO" -ServerInstance $DBHost\$DBInstance
            }
            else
            {
                Invoke-Sqlcmd -Query "SELECT DATABASEPROPERTYEX('$DB', 'Status') as Status
                GO" -ServerInstance $DBHost
            }
          }
    try{
    Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
    $out = Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList $SNamed,$DBS,$DBSourceHost,$DBSInstance 
    $out = $out | Select-Object -ExpandProperty Status
    $out1 = Invoke-Command -Session $sess1 -ScriptBlock $sc -ArgumentList $TNamed,$DBT,$DBTargetHost  
    $out1 = $out1 | Select-Object -ExpandProperty Status 
    if ($out -and $out1 -eq "ONLINE")
    {
    '0'
    }
    else
    {
    '1'
    }
    }
    catch{ "StatusCode:10StatusDesc: $_.Exception.Message" 
            Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "Error" "Issue:$_.Exception.Message" | Out-Null
    }
    Remove-PSSession $sess
    
    

