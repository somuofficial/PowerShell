$secpasswd = ConvertTo-SecureString "Database@1234" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("sqlclusters\administrator", $secpasswd)
$sess = New-PSSession -ComputerName "node02" -Credential $mycreds
$sc = {
    param($DB)
    Import-Module sqlps 
    invoke-sqlcmd -query "use $DB; DECLARE @DBID INT 
SELECT @DBID = DB_ID() 

--- Identifying the High / Low Fragmentation of Table(s) in the active Database 
SELECT OBJECT_NAME([OBJECT_ID]) 'TABLE NAME',
INDEX_TYPE_DESC 'INDEX TYPE',IND.[NAME],
AVG_FRAGMENTATION_IN_PERCENT '% FRAGMENTED' 
FROM sys.dm_db_index_physical_stats(@DBID, NULL, NULL, NULL, NULL) JOIN sys.sysindexes IND 
ON (IND.ID =[OBJECT_ID] AND IND.INDID = INDEX_ID) 
WHERE AVG_FRAGMENTATION_IN_PERCENT = 0 
AND DATABASE_ID = @DBID 
AND IND.FIRST IS NOT NULL 
AND IND.[NAME] IS NOT NULL 
ORDER BY avg_fragmentation_in_percent DESC" -serverinstance "Node02"
    }   
    
Invoke-Command -Session $sess -ScriptBlock $sc -ArgumentList
Remove-PSSession $sess