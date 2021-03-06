
############################################################
# Script Name: Stop & Start MSSQL Stand Alone Instance     #
# Team Name:   SS Service Automation                       #
# Creation Date: 15th Feb 2016                             #
# Created By: Somnath Sarkar                               #
# Description: This Script would check the MSSQL Service   #
#              name and Stop the instance and start again. #
############################################################

##### Creating Connection with Encrypted password ##########
$secpasswd = ConvertTo-SecureString "${DBPassword}" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("${DBDomain}\${DBUsername}", $secpasswd)
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
                $sqlagent = Get-Service $Agnt                    
            }
                if ($a.Status -eq "Running")
                {
############ Stoping The MSSQL Service #####################
                            stop-service $a.Name -force 
                            $b = Get-Service $a.Name | Select-Object -ExpandProperty Status
                            if ($b -eq "Stopped")
                            {
############ Starting The MSSQL Service ####################
                                Start-Sleep -s 5
                                Start-Service $sqlagent.Name
                                $t = Get-Service $a.Name | Select-Object -ExpandProperty Status
                                    if ($t -eq "Running")
                                    {
                                    'Restarted'
                                    }
                                    else
                                    {
                                    'Not Started'
                                    }
                             }
                            else
                            {
                            'SQL Service did not Stop'
                            $b
                            }
            }
            else
            {
            'MSSQL Service Not Running '
            }
############ End Of Script Block ###########################
 }   

############ Sending Script Block To the Created Session ###    
Invoke-Command -Session $sess -ScriptBlock $sc

############ Garbaging Session #############################
Remove-PSSession $sess

############ End Of Script #################################
