
############################################################
# Script Name: Service Check MSSQL Stand Alone Instance    #
# Team Name:   SS Service Automation                       #
# Creation Date: 23rd Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would check the MSSQL Service   #
#              running or not.                             #
############################################################

##### Initialising Variables ###############################
$secpasswd = $null
$mycreds = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$APID = "301"
$CIServer = "${DBHost}"
$ActivityName = "Check MSSQL Service"
$Des = "This Activity would check MSSQL Service for Default and Named Service of MSSQL"
$LogAccountName = "Administrator@ssautomation.com"

############ Importing Log Module ##########################
Try{
Import-Module "Activity Logger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:1 ## StatusDesc:$_.Exception.Message"
Break}
############ Inserting Logs ################################
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Log Module Imported" | Out-Null
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "WorkFlow Variable Passed: DBUsername-${DBUsername},DBPassword-${DBPassword},DBHost-${DBHost},DBInstance-${DBInstance}" | Out-Null

##### Creating Connection with Encrypted password ##########
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)
$sess = New-PSSession -ComputerName "${DBHost}" -Credential $mycreds

Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Creating Session With Secure Password" | Out-Null

############ Starting Of Script Block ######################
$sc = {

############ Checking The MSSQL Service Name ###############
            $a = Get-Service Mssqlserver -ErrorAction SilentlyContinue 
            $sqlagent = Get-Service SQLServerAgent -ErrorAction SilentlyContinue
            if (!$a)
            {
                $serv = "Mssql"+'$'+"${DBInstance}"
                $Agnt = "sqlagent"+'$'+"${DBInstance}"
                $a = Get-Service $serv -ErrorAction SilentlyContinue                   
            }
                if ($a.Status -eq "Running")
                {
                '0'
                }
                else
                {
                '1'
                }
############ End Of Script Block ###########################
 }   

############ Sending Script Block To the Created Session ###    
Try{
Invoke-Command -Session $sess -ScriptBlock $sc
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "No Error" "Trying to send script block to remote machine" | Out-Null
}
catch{"StatusCode1 ## StatusDesc:$_.Exception.Message"
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "In Progress" "$LogAccountName" "$_.Exception.Message" "Now Removing Session" | out-null
}
############ Garbaging Session #############################
############ Success = 0 ###################################
############ Failure = 1 ###################################

Remove-PSSession $sess
Insert-ActivityLog "$LogServer" "$LogDB" "$APID" "$CIServer" "$ActivityName" "$Des" "Completed" "$LogAccountName" "No Error" "Session Removed" | Out-Null

############ End Of Script #################################
