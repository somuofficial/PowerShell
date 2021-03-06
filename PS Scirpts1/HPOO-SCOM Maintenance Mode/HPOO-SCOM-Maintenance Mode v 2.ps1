
############################################################
# Script Name: Start SCOM Maintenance Mode for node        #
# Team Name:   SS Service Automation                       #
# Creation Date: 15th Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script Start Maintenance mode for one  #
#              Node in SCOM.                               #
############################################################

##### Variable Initialization ##############################
$Ping = $null 
$secpasswd = $null
$mycreds = $null
$psout = $null
##### Encrypting password ##################################
$secpasswd = ConvertTo-SecureString ${SCOMPassword} -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${SCOMDomain}\${SCOMUsername}", $secpasswd)

##### Connectivity Test ####################################
$Ping = Test-Connection -ComputerName ${SCOMHost} -Quiet
if ($Ping -eq $True)
{

##### Creating Session #####################################
$sess = New-PSSession -ComputerName ${SCOMHost} -Credential $mycreds

##### Starting of Script Block #############################
$sc = {
       
            Import-Module OperationsManager -EA Stop
            $Instance = Get-ScomclassInstance -Name ${DBHost}.${DBDomain}
            $EndTime = ((Get-Date).AddMinutes(${Time}))
            Start-ScomMaintenanceMode -Instance $Instance -EndTime $EndTime -Reason ${Reason} -comment ${Comment} -EA Stop
            $Ex =  Get-SCOMClassInstance -Name $Instance | Select-Object -ExpandProperty "InMaintenanceMode"
                if($Ex -eq $True)
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
try{
Invoke-Command -Session $sess -ScriptBlock $sc -ErrorAction Stop 
}
catch{ "InMaintenanceMode:"+" ## "+ $_.Exception.Message }
############ Garbaging Session #############################
Remove-PSSession $sess
}

############ End Of Script #################################