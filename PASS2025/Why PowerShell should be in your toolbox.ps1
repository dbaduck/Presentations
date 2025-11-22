# Why PowerShell should be in your DBA toolbox


# Modules
# SMO
# Multiple Databases, Multiple Servers
$servername = "SQL02"

Import-Module dbatools

1..10 | ForEach-Object {
    New-DbaDatabase -SqlInstance $serverName -Name "NEW$_" -ErrorAction SilentlyContinue
}

1..10 | ForEach-Object {
    Get-DbaDatabase -SqlInstance $serverName -Database "NEW$_" | Remove-DbaDatabase -Confirm:$false
}


# Scripting
$options = New-DbaScriptingOption 
$options
$options.IncludeIfNotExists = $true
$options | gm

$table = Get-DbaDbTable -SqlInstance $servername -Database DEMO1 -Table "CPU"
$table.Script($options)
foreach($index in $table.Indexes) {
    $index.Script($options) | Add-Content -Path "c:\Demos\indexes\index_table_$($table.Name)_$($index.Name).sql"
}   

# Create things
New-DbaAvailabilityGroup -Name "AG1" -Primary SQL01 -Secondary SQL02 `
        -Database PreconDatabase -SharedPath "\\sql01\sqlbackup" -FailoverMode Manual -Dhcp -Confirm:$false

$query = @"
    SELECT name, database_id, create_date, is_accelerated_database_recovery_on
    FROM sys.databases
    WHERE database_id > 4
"@

$data = Invoke-DbaQuery -SqlInstance SQL01 -Query $query -as DataTable
Write-DbaDbTableData -SqlInstance SQL02 -Database DEMO1 -Table DBAQueryResults -InputObject $data -AutoCreateTable

$data = Get-DbaDiskSpace -ComputerName sql01
Write-DbaDbTableData -SqlInstance SQL02 -Database DEMO1 -Table dba_diskspace -InputObject $data -AutoCreateTable

# dba functions
# expand log file
Expand-DbaDbLogFile -SqlInstance SQL02 -Database DEMO1 -TargetLogSize 8000 -IncrementSize 500

# expand data file
$db = Get-DbaDatabase -SqlInstance SQL01 -Database DEMO1

# change  filegrowth
Set-DbaDbFileGrowth -SqlInstance sql01 -Database DEMO1 -GrowthType MB -Growth 512 -FileType Data
Set-DbaDbFileGrowth -SqlInstance sql01 -Database DEMO1 -GrowthType MB -Growth 512 -FileType Log

# tables and indexes
.\TableIndexes.ps1
Get-BmaTableInfo -SqlInstance SQL01 -Database StackOverflow2013 -Table Posts -All

