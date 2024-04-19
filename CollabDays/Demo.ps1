<#
Principal of an Iteration Id

Each Data Gathering should have a definitive point in time to allow correlation
I add in the time of the Server Start so that I can tell when some
of the stats have been reset to 0

#>

function Get-BmaIterationId
{
	param (
		[string]$ServerInstance,
		$SqlCredential,
		[string]$Database = "DBA"
	)
	
	$query = "dbo.get_IterationId"
	
    Invoke-DbaQuery -SqlInstance $ServerInstance -Database $Database -Query $query -CommandType StoredProcedure `
        -SqlCredential $SqlCredential -As SingleValue
}


<#
Actually Getting the Data
#>

# Example 1:
Import-Module dbatools

# Importing dbatools will automatically load SMO which we will use
$smo = "Microsoft.SqlServer.Management.Smo"

<#
    Columns we are getting

    NOTE: Always have the iteration_id at the end of the table instead of the front
        Writing data to the table allows you to put columns before the iteration_id
ID
Name
Size
DataSpaceUsage
IndexSpaceUsage
LastBackupDate
RecoveryModel
PageVerify
CompatibilityLevel
IsReadCommittedSnapshotOn

CREATE TABLE dbo.stats_Database (
	ID int,
	Name nvarchar(128),
	Size bigint,
	DataSpaceUsage decimal(18,2),
	IndexSpaceUsage decimal(18,2),
	LastBackupDate datetime2(0),
	RecoveryModel varchar(15),
	PageVerify varchar(20),
	CompatibilityLevel varchar(10),
	IsReadCommittedSnapshotOn bit,
	IterationId int NOT NULL
)

#>

# $IterationId = Get-BmaIterationId -ServerInstance localhost -Database DBA
[System.Collections.ArrayList]$ary = @()

$IterationId = Get-BmaIterationId -ServerInstance localhost 

$server = Connect-DbaInstance -SqlInstance localhost -TrustServerCertificate

foreach ($db in ($server.Databases))
{
    # First technique
	$dbobj = "" | select ID, Name, Size, DataSpaceUsage, IndexSpaceUsage, LastBackupDate, RecoveryModel, PageVerify, CompatibilityLevel, IsReadCommittedSnapshotOn, IterationId
	
	$dbobj.ID = $db.ID
	$dbobj.Name = $db.Name
	$dbobj.Size = $db.Size
	$dbobj.DataSpaceUsage = $db.DataSpaceUsage
	$dbobj.IndexSpaceUsage = $db.IndexSpaceUsage
	$dbobj.LastBackupDAte = $db.LastBackupDate
	$dbobj.RecoveryModel = $db.RecoveryModel
	$dbobj.PageVerify = $db.PageVerify
	$dbobj.CompatibilityLevel = $db.CompatibilityLevel
	$dbobj.IsReadCommittedSnapshotOn = $db.IsReadCommittedSnapshotOn
	$dbobj.IterationId = $IterationId
	
	[void]$ary.Add($dbobj)
}
$dt = ConvertTo-DbaDataTable -InputObject $ary

Write-DbaDbTableData -SqlInstance localhost -Database DBA -Schema dbo -Table stats_Database -InputObject $dt


# Example 2:

# $IterationId = Get-BmaIterationId -ServerInstance localhost -Database DBA
[System.Collections.ArrayList]$ary = @()

$IterationId = Get-BmaIterationId -ServerInstance localhost 

$server = Connect-DbaInstance -SqlInstance localhost -TrustServerCertificate

foreach ($db in ($server.Databases))
{
	$dbobj = [PSCustomObject][ordered]@{
			ID = $db.ID
			Name = $db.Name
			Size = $db.Size
			DataSpaceUsage = $db.DataSpaceUsage
			IndexSpaceUsage = $db.IndexSpaceUsage
			LastBackupDate  = $db.LastBackupDate
			RecoveryModel   = $db.RecoveryModel
			PageVerify	  = $db.PageVerify
			CompatibilityLevel = $db.CompatibilityLevel
			IsReadCommittedSnapshotOn = $db.IsReadCommittedSnapshotOn
			IterationId			   = $IterationId
		}
	
	[void]$ary.Add($dbobj)
}

$dt = ConvertTo-DbaDataTable -InputObject $ary

Write-DbaDbTableData -SqlInstance localhost -Database DBA -Schema dbo -Table stats_Database -InputObject $dt


# Example 3: Only illustrate, we will run it differently for efficiency sake

$IterationId = Get-BmaIterationId -ServerInstance localhost 

$server = Connect-DbaInstance -SqlInstance localhost -TrustServerCertificate

$dt = New-Object -TypeName System.Data.DataTable -Args "DBStats"

$col1 = New-Object -TypeName System.Data.DataColumn -Args ID, ([Int])
$col2 = New-Object -TypeName System.Data.DataColumn -Args Name, ([String])
$col2.MaxLength = 256
$col3 = New-Object -TypeName System.Data.DataColumn -Args Size, ([Int64])
$col4 = New-Object -TypeName System.Data.DataColumn -Args DataSpaceUsage, ([decimal])
$col5 = New-Object -TypeName System.Data.DataColumn -Args IndexSpaceUsage, ([decimal])
$col6 = New-Object -TypeName System.Data.DataColumn -Args LastBackupDate, ([Datetime])
$col7 = New-Object -TypeName System.Data.DataColumn -Args RecoveryModel, ([string])
$col7.MaxLength = 15
$col8 = New-Object -TypeName System.Data.DataColumn -Args PageVerify, ([string])
$col8.MaxLength = 20
$col9 = New-Object -TypeName System.Data.DataColumn -Args CompatibilityLevel, ([string])
$col9.MaxLength = 10
$col10 = New-Object -TypeName System.Data.DataColumn -Args IsReadCommittedSnapshotOn, ([boolean])
$col11 = New-Object -TypeName System.Data.DataColumn -Args IterationId, ([Int])

$dt.Columns.Add($col1)
$dt.Columns.Add($col2)
$dt.Columns.Add($col3)
$dt.Columns.Add($col4)
$dt.Columns.Add($col5)
$dt.Columns.Add($col6)
$dt.Columns.Add($col7)
$dt.Columns.Add($col8)
$dt.Columns.Add($col9)
$dt.Columns.Add($col10)
$dt.Columns.Add($col11)

foreach ($db in ($server.Databases))
{
	$row = $dt.NewRow()
	
	$row.ID = $db.ID
	$row.Name = $db.Name
	$row.Size = $db.Size
	$row.DataSpaceUsage = $db.DataSpaceUsage
	$row.IndexSpaceUsage = $db.IndexSpaceUsage
	$row.LastBackupDate = $db.LastBackupDate
	$row.RecoveryModel = $db.RecoveryModel
	$row.PageVerify = $db.PageVerify
	$row.CompatibilityLevel = $db.CompatibilityLevel
	$row.IsReadCommittedSnapshotOn = $db.IsReadCommittedSnapshotOn
	$row.IterationId = 3
	
	$dt.Rows.Add($row)
}

Write-DbaDbTableData -SqlInstance localhost -Database DBA -Schema dbo -Table stats_Database -InputObject $dt


# Example 4: doing the DataTable thing a little bit better

$IterationId = Get-BmaIterationId -ServerInstance localhost 

$server = Connect-DbaInstance -SqlInstance localhost -TrustServerCertificate

$dt = Invoke-DbaQuery -SqlInstance $server -Database DBA -Query "SELECT * FROM dbo.stats_Database WHERE 1=0;" -As DataTable

foreach ($db in ($server.Databases))
{
	$row = $dt.NewRow()
	
	$row.ID = $db.ID
	$row.Name = $db.Name
	$row.Size = $db.Size
	$row.DataSpaceUsage = $db.DataSpaceUsage
	$row.IndexSpaceUsage = $db.IndexSpaceUsage
	$row.LastBackupDate = $db.LastBackupDate
	$row.RecoveryModel = $db.RecoveryModel
	$row.PageVerify = $db.PageVerify
	$row.CompatibilityLevel = $db.CompatibilityLevel
	$row.IsReadCommittedSnapshotOn = $db.IsReadCommittedSnapshotOn
	$row.IterationId = [Int32]$IterationId
	
	$dt.Rows.Add($row)
}

Write-DbaDbTableData -SqlInstance localhost -Database DBA -Schema dbo -Table stats_Database -InputObject $dt

