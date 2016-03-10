################################################################################################
#                                                                                              #
#                          Activity LOGGER - SCRIPT MODULE DESCRIPTION                         #
#                                                                                              #
################################################################################################
#                                                                                              #
#     This script is for creating a powershell module for writting activity log into DB        #
#                                                                                              #
################################################################################################
#                                                                                              #
#      AUTHOR:  SAMIT MANNA                                                                    #
#      VERSION: 1.0                                                                            #
#      LAST MODIFIED DATE: 13-AUG-2014                                                         #
#      MODIFIED BY: PARDHU                                                                     #
#                                                                                              #
#                                                                                              #
################################################################################################
function Write-ActivityLog($Server, $DataBase, $ProcessID, $ServerName, $ComponentName, $Description, $Status, $AccountName, $Error, $Message)
{

    $TableName = "RbookLog"
    $ConnString = "Server = $Server ; Database = $DataBase ; Integrated Security = true"
    try
    {
        $Connection = New-Object System.Data.SqlClient.SqlConnection
        $Connection.ConnectionString = $ConnString
        $Connection.Open()
        $Query = "Update $DataBase.dbo.$TableName set [Status] = '$Status',[Error] = '$Error',[Message] = '$Message' WHERE [ProcessID] = '$ProcessID' and [ComponentName] = '$ComponentName'"
        $Command = $Connection.CreateCommand()
        $Command.CommandText = $Query
        $Result = $Command.ExecuteNonQuery()
        $Connection.Close()
        if($Result -eq 1)
        {
            return "Log Inserted Into Database"
        }
        else
        {
            return "Unable to Insert Log Into Database"
        }
    } 
    catch
    {
        return ("Unable to Insert Log Into Database: ", $_.Exception.Message)
    }
}

function Insert-ActivityLog($Server, $DataBase, $ProcessID, $ServerName, $ComponentName, $Description, $Status, $AccountName)
{

    $TableName = "RbookLog"
    $ConnString = "Server = $Server ; Database = $DataBase ; Integrated Security = true"
    try
    {
        $Connection = New-Object System.Data.SqlClient.SqlConnection
        $Connection.ConnectionString = $ConnString
        $Connection.Open()
        $Query = "insert into $DataBase.dbo.$TableName(ProcessID, ServerName, ComponentName, Description, Status, AccountName, Error, Message, DateTime) 
                    values('$ProcessID', '$ServerName', '$ComponentName', '$Description', '$Status', '$AccountName', '$Error', '$Message',getdate());"
        $Command = $Connection.CreateCommand()
        $Command.CommandText = $Query
        $Result = $Command.ExecuteNonQuery()
        $Connection.Close()
        if($Result -eq 1)
        {
            return "Log Inserted Into Database"
        }
        else
        {
            return "Unable to Insert Log Into Database"
        }
    } 
    catch
    {
        return ("Unable to Insert Log Into Database: ", $_.Exception.Message)
    }
}

########### Exporting all funtions as powershell cmdlet ####################

Export-ModuleMember -Function * -Alias *

###################### End of the Script ##################################