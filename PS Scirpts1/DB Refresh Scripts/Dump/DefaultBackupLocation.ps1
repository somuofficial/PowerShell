 
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

############ Establishing Connections #######################
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "Node02" -Credential $mycreds

############ Starting Of Script Block ######################
$sc = {
      param($DB)
      Import-Module SQLPS -ErrorAction Stop -WarningAction silentlycontinue
      invoke-sqlcmd "EXEC  master.dbo.xp_instance_regread  
      N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory'"
      ############ End Of Script Block ###########################
      }   

############ Sending Script Block To the Created Session ###    
try{
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
$out = Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList $DB
$BkpDrive = ((($out | Select-Object -ExpandProperty Data) -split '\\')[0] -split ':')[0] 
}
catch
{ "StatusCode:10StatusDesc: $_.Exception.Message "
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
 }
############ Garbaging Session #############################
#Write-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################


