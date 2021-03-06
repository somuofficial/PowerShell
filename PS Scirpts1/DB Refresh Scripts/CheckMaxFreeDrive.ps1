############################################################
# Script Name: CheckMaxFreeDrive                           #
# Team Name:   SS Service Automation                       #
# Creation Date: 15th Mar 2016                             #
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
#Try{
#Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
#} 
#catch{"StatusCode:1 ## StatusDesc:$_.Exception.Message"
#Break}

############ Inserting Logs ################################
#Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Started" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null

############ Encrypting password ###########################
$secpasswd = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd)

############ Establishing Connection #######################
#Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Establishing Remote Session Connection" | Out-Null
$sess = New-PSSession -ComputerName "Node01" -Credential $mycreds

############ Starting Of Script Block ######################
$sc = { 
    $DriveInfo = Get-PSDrive | Where-Object {$_.free -Notlike $null} | Select-Object @{N="Drive";E={$_.Name}},@{N="Free(Gb)";E={[Math]::round($_.Free/1MB)}} | Sort-Object -Property "Free(Gb)" | Select-Object -Last 1 
    $DriveInfo.Drive
    $DriveInfo."Free(Gb)"  

############ End Of Script Block ###########################
 }   

############ Sending Script Block To the Created Session ###    
try{
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Transporting ScriptBlock to remote connection" | Out-Null
Invoke-Command -Session $sess -ScriptBlock $sc 
}
catch
{ "StatusCode:1 ## StatusDesc: $_.Exception.Message "
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "Error" "$_.Exception.Message" | Out-Null
}
############ Garbaging Session #############################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Closing Session Connection" | Out-Null
Remove-PSSession $sess

############ End Of Script #################################