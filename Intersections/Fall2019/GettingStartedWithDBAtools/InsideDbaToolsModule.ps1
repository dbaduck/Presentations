$filename = "$(Split-Path $profile)\Transcripts\Transcript_Demo_$(Get-Date -f 'yyyyMMdd_HHmmss')"
Start-Transcript -Path "$filename.txt"

$ServerInstance = "WIN2019A"
$Database = "DEMODB"

Import-Module dbatools

Get-Command -Module dbatools -CommandType Function | measure-object
Get-Command -Module dbatools -Verb Test
Get-Command -Module dbatools -Verb Get

# Connecting to the servers
$server1 = Connect-DbaInstance -SqlInstance $ServerInstance  # -ApplicationIntent, -FailoverPartner
$server1.ConnectionContext.StatementTimeout

$smo = "Microsoft.SqlServer.Management.Smo"
$server2 = New-Object -TypeName "$smo.Server" -ArgumentList $ServerInstance
$server2.ConnectionContext.StatementTimeout

$server3 = Connect-DbaInstance -SqlInstance $ServerInstance -StatementTimeout 0
$server3.ConnectionContext.StatementTimeout

$server1.GetType()
$server2.GetType()
$server3.GetType()

$db = Get-DbaDatabase -SqlInstance $ServerInstance -Database $Database
$db.Gettype()
$db.PageVerify
$db.PageVerify = "Checksum"

$db.RecoveryModel
$db.RecoveryModel = "Simple"
$db.Alter()

$db.Drop()
$db.Gettype()


# what is the status of my database?
$disk = Get-DbaDiskSpace -ComputerName $ServerInstance

$disk | Format-List *

$var = Get-DbaDbFile -sqlinstance $ServerInstance -Database DEMODB

# is there more information?
Get-DbaDiskSpace -ComputerName $ServerInstance | Format-List *

$value = Get-DbaDiskSpace -ComputerName $ServerInstance | Select-Object  SizeInGB
Get-DbaDiskSpace -ComputerName $ServerInstance | Select-Object -ExpandProperty  SizeInGB
$value = Get-DbaDiskSpace -ComputerName $ServerInstance | Select-Object -ExpandProperty  SizeInGB


# search the error log
Get-DbaErrorLog -SqlInstance $ServerInstance -LogNumber 0 -Text "BACKUP"

# Get the DBCC information on the database(s)
Get-DbaLastGoodCheckDb -SqlInstance $ServerInstance, WIN2019B -Database DEMODB, DEMODB2 

# Get all logins (returns SMO)
Get-DbaLogin -SqlInstance $ServerInstance | where name -eq 'sa' | Get-member

# Get specific login and see the type
Get-DbaLogin -SqlInstance $ServerInstance -Login 'sa'
(Get-DbaLogin -SqlInstance $ServerInstance -Login 'sa').GetType()


# Get me a server setting for Max Server Memory setting.
Get-DbaMaxMemory -SqlInstance $ServerInstance
Test-DbaMaxMemory -SqlInstance $ServerInstance
Set-DbaMaxMemory -SqlInstance $ServerInstance -Max 4096

# what is the status of my protocols on this server?
Get-DbaInstanceProtocol -ComputerName $ServerInstance

Get-DbaTcpPort -SqlInstance $ServerInstance
Set-DbaTcpPort -SqlInstance $ServerInstance -Port 56656

# Get the sp_configure like stuff
(Get-DbaSpConfigure -SqlInstance $ServerInstance).GetType()

Set-DbaSpConfigure

Export-DbaSpConfigure -SqlInstance $ServerInstance -FilePath 

# Back me up
Backup-DbaDatabase -SqlInstance $ServerInstance -Database DEMODB


Get-DbaDbBackupHistory -SqlInstance $ServerInstance -LastFull -database DEMODB
Get-DbaDbBackupHistory -SqlInstance $ServerInstance -LastFull -database DEMODB | Format-List *


# use dba backup history to restore the database.
Get-DbaDbBackupHistory -SqlInstance $ServerInstance -LastFull -database DEMODB |
	Restore-DbaDatabase -SqlInstance $ServerInstance -DatabaseName DEMODB3 -DestinationFilePrefix bbb `
					-TrustDbBackupHistory

# use dba backup history to restore the database, but only get the script
Get-DbaDbBackupHistory -SqlInstance $ServerInstance -LastFull -database DEMODB |
Restore-DbaDatabase -SqlInstance $ServerInstance -DatabaseName DEMODB4 -DestinationFilePrefix bbc `
					-MaxTransferSize 1048576 -TrustDbBackupHistory -OutputScriptOnly


# get me some data
$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database master `
	-Query "SELECT NULL as b, * FROM sys.master_files" -As DataTable

# put that data in a table.
Write-DbaDbTableData -SqlInstance $ServerInstance -Database "B" -Table master_files1 `
	-Schema dbo -InputObject $dt 

Write-DbaDbTableData -SqlInstance $ServerInstance -Database $Database -Table master_files2 `
					 -Schema dbo -InputObject $dt -AutoCreateTable

Stop-Transcript