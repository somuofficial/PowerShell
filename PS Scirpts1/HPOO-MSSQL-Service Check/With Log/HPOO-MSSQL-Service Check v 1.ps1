
############################################################
# Script Name: Service Check MSSQL Stand Alone Instance    #
# Team Name:   SS Service Automation                       #
# Creation Date: 23rd Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would check the MSSQL Service   #
#              running or not.                             #
############################################################

############ Importing Log Module ##########################
Try{
Import-Module "Activity Log1ger" -ErrorAction Stop -WarningAction Silentlycontinue
} 
catch{"StatusCode:1 ## StatusDesc:$_.Exception.Message"
Break}
Insert
##### Initialising Variables ###############################
$secpasswd = $null
$mycreds = $null
$sess = $null
$LogServer = "Exchange.ssautomation.com"
$LogDB = "GCONG"
$PID = "303"
$CIServer = "${DBHost}"
$ActivityName = "Check MSSQL Service"
$Des = "This Activity would check MSSQL Service for Default and Named Service of MSSQL"
$Status = $null
$LogAccountName = "Administrator@ssautomation.com"
$err = $null
$Msg = $null

##### Creating Connection with Encrypted password ##########
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBUsername}", $secpasswd)
$sess = New-PSSession -ComputerName "${DBHost}" -Credential $mycreds

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
}
catch{"StatusCode1 ## StatusDesc:$_.Exception.Message"}
############ Garbaging Session #############################
############ Success = 0 ###################################
############ Failure = 1 ###################################

Remove-PSSession $sess

############ End Of Script #################################
