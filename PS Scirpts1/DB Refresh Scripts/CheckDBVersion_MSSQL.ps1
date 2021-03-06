#############################################################
# Script Name: Verify No Blocked Processes                  #
# Team Name:   SS Service Automation                        #
# Creation Date: 25th Feb 2016                              #
# Created By: Somnath Sarkar                                #
# Description: This Script would connect with MSSQL Servers #
#              and get MSSQL Server Versions.               #
# Inputs: DBDomain, DBUsername, DBPassword, DBHost,DB       #
#############################################################

##### Variable Initialization ##############################
$secpasswd = $null
$mycreds = $null
$out = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$APID = "411"
$CIServer = "${DBSourceHost},${DBTargetHost}"
$ActivityName = "Check Database Versions"
$Des = "This Activity would check Database Server versions on both machines"
$LogAccountName = "Administrator@ssautomation.com"

############ Importing Log Module ##########################
#Try{
#Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
#} 
#catch{"StatusCode:10StatusDesc:$_.Exception.Message"
#Break}

############ Inserting Logs ################################
#Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null

############ Encrypting passwords ###########################
$secpasswd = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd)

$secpasswd1 = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds1 = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd1)

############ Establishing Connections #######################
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "Node01" -Credential $mycreds

#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess1 = New-PSSession -ComputerName "Node02" -Credential $mycreds1

############ Starting Of Script Block ######################
$sc = {
      param($Named,$DBHost,$DBInstance)
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      if ($Named -eq $True)
      {
         Invoke-sqlcmd "Select @@Version" -ServerInstance $DBHost\$DBInstance  
      }
      else
      {
         Invoke-sqlcmd "Select @@Version" -ServerInstance $DBHost  
      }
      ############ End Of Script Block ###########################
      }   

############ Sending Script Block To the Created Session ###    
try{
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList "True","Node01","Sql02"
$out1 = Invoke-Command -Session $sess1 -ScriptBlock $sc -ArgumentList "False","Node02",$null    

   $splt = $out | Select-Object -ExpandProperty column1
   $splt1 = $out1 | Select-Object -ExpandProperty column1
   $SVersion = ($Splt.Substring(0, $Splt.IndexOf('-')) -split ' ')[3]
   $TVersion = ($splt1.Substring(0, $splt1.Indexof('-')) -split ' ')[3]
   if ($SVersion -le $TVersion)
   {
   '0'
   }
   else
   {
   '1'
   }
   
   }
catch
{ "StatusCode:10StatusDesc: $_.Exception.Message "
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
 }
############ Garbaging Session #############################
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess,$sess1

############ End Of Script #################################

