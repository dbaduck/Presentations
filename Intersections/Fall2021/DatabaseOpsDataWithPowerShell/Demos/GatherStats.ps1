
function Get-BmaIterationId
{
	param (
		[string]$ServerInstance,
		[PSCredential]$SqlCredential,
		[string]$Database
	)
	
	$query = "INSERT INTO stat.Iterations (gather_date) OUTPUT inserted.iteration_id VALUES (GETDATE())"
	
	return (Invoke-DbaQuery -SqlInstance $ServerInstance -Database $Database -Query $query -As SingleValue -SqlCredential $SqlCredential)
}

function Get-BmaTableStatistics
{
	param (
		[string]$ServerInstance,
		[PSCredential]$SqlCredential,
		[int]$IterationId,
		[string[]]$Database,
		[string]$ReportSqlInstance,
		[string]$ReportSqlDb,
		[PSCredential]$ReportSqlCredential
	)
	
	# Scheduled Per Day
	# Run per Database
	
	$query = @"
WITH ColumnCounts
AS (
    SELECT 
        t.object_id,
        COUNT(*) as column_count
    FROM sys.schemas as s
    inner join sys.tables as t on s.schema_id = t.schema_id
    INNER JOIN sys.columns as c on t.object_id = c.object_id
    GROUP BY t.object_id
),
IndexCounts
AS (
    SELECT 
        t.object_id,
        COUNT(*) as index_count
    FROM sys.tables as t 
    INNER JOIN sys.indexes as ix on t.object_id = ix.object_id
    GROUP BY t.object_id
),
PrimaryKeys
AS (
    SELECT 
        t.object_id,
        c.name as [primary_key_name],
        c.is_system_named,
        c.unique_index_id,
        STUFF((SELECT ',' + col.name
            FROM sys.index_columns as cl
            INNER JOIN sys.columns as col on cl.object_id = col.object_id and cl.column_id = col.column_id
            WHERE 
                cl.object_id = c.parent_object_id 
                and cl.index_id = c.unique_index_id
            ORDER BY cl.key_ordinal
            FOR XML PATH('')),1,1,'') as key_columns
    FROM sys.tables as t 
    LEFT JOIN sys.key_constraints as c ON t.object_id = c.parent_object_id and c.type = 'PK'
),
TableLengths
AS (
    select 
        t.object_id, 
        --CASE WHEN c.system_type_id IN (127, 56, 52, 48, 36, 173, 61, 175, 62, 98, 32, 106, 104, 239, 35, 34, 40, 41, 42, 58, 59, 60, 99, 108, 240, 189, 122) THEN c.max_length
        --     WHEN c.system_type_id IN (231, 165, 167, 240, 241) AND st.max_length > 0 THEN c.max_length ELSE 16 END 
        SUM(CASE WHEN c.max_length > 0 THEN c.max_length
            ELSE 16 
        END) as table_length
    from sys.tables as t
    INNER JOIN sys.columns as c ON t.object_id = c.object_id 
    inner join sys.types as st on c.system_type_id = st.system_type_id
            and st.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
    GROUP BY t.object_id
)
SELECT
    @@SERVERNAME as [server_name],
    DB_NAME() as [database_name],
    s.name as [schema_name],
    t.name as [table_name],
    ic.index_count,
    dau.data_space_mb,
    dau.index_space_mb,
    dau.rows as [row_count],
    c.column_count as [column_count],
    CAST(ix.index_id as bit) as [is_clustered],
    tl.table_length as [definition_length],
    (SELECT COUNT(*) 
        FROM sys.indexes as iix 
        INNER JOIN sys.index_columns ixc ON iix.object_id = ixc.object_id and iix.index_id = ixc.index_id 
        INNER JOIN sys.columns as ccc ON ixc.object_id = ccc.object_id AND ccc.column_id = ixc.column_id
        WHERE iix.index_id = 1
            AND iix.object_id = ix.object_id 
            AND iix.index_id = ix.index_id
    ) as [clustered_column_count],
    pk.key_columns as [primary_key_columns],
    CAST(CASE WHEN pk.unique_index_id = 1 THEN 1 ELSE 0 END as bit) as [is_pk_clustered],
    pk.primary_key_name as [primary_key_name],
    pk.is_system_named as is_pk_system_named,
	CONVERT(BIT, CASE WHEN ix.index_id = 0 THEN 1 ELSE 0 END) AS is_heap,
	$IterationId AS [iterationid]
--INTO stat.TableStatistics
FROM sys.schemas as s
INNER JOIN sys.tables t (nolock) on s.schema_id = t.schema_id
INNER JOIN ColumnCounts as c ON t.object_id = c.object_id
INNER JOIN sys.indexes as ix (nolock) on t.object_id = ix.object_id
INNER JOIN IndexCounts as ic on t.object_id = ic.object_id
INNER JOIN TableLengths as tl ON t.object_id = tl.object_id
LEFT JOIN PrimaryKeys as pk ON pk.object_id = t.object_id
CROSS APPLY (
        SELECT
            ix.object_id,
            p.[rows],
            SUM(CASE WHEN p.index_id IN (0,1) THEN au.total_pages ELSE 0 END)/128 as data_space_mb,
            SUM(CASE WHEN p.index_id > 1 THEN au.total_pages ELSE 0 END)/128 as index_space_mb
        FROM sys.tables as it (nolock)
        INNER JOIN sys.indexes as ix (nolock) ON it.object_id = ix.object_id
        INNER JOIN sys.partitions as p (nolock) ON ix.object_id = p.object_id and ix.index_id = p.index_id
        INNER JOIN sys.allocation_units as au (nolock) ON p.partition_id = au.container_id 
        WHERE p.object_id = ix.object_id and p.index_id = ix.index_id and ix.object_id = t.object_id
            and it.is_ms_shipped = 0
        GROUP BY ix.object_id, p.[rows]
    ) as dau
WHERE ix.index_id IN (0,1)
    AND t.is_ms_shipped = 0
OPTION (RECOMPILE)
"@
	if($SqlCredential) {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance -SqlCredential $SqlCredential
	}
	else {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance 
	}
	
	if($null -eq $Database) {
		$Database = $s.Databases | Where-Object IsAccessible -eq $true | Where-Object { $_.Name -NotIn @("master", "model", "msdb", "tempdb") } | Select-Object -ExpandProperty Name
	}
	
	foreach ($db in $Database)
	{
		
		try
		{
			if($SqlCredential) {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable -SqlCredential $SqlCredential -QueryTimeout 120
			}
			else {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable -QueryTimeout 120
			}

			Write-DbaDbTableData -SqlInstance $ReportSqlInstance -Database $ReportSqlDb -Schema stat -Table TableStatistics -InputObject $dt -BulkCopyTimeOut 0
		}
		catch
		{
			Write-Host "Error occurred in $($ServerInstance) - $($db) - TableStatistics"
		}
		
	}	
}

function Get-BmaIndexUsage
{
	param (
		[string]$ServerInstance,
		[PSCredential]$SqlCredential,
		[int]$IterationId,
		[string[]]$Database,
		[string]$ReportSqlInstance,
		[string]$ReportSqlDb,
		[PSCredential]$ReportSqlCredential
	)
	
	# Scheduled Per Day
	# Run per Database
	
	$query = @"
SELECT * INTO #ius FROM sys.dm_db_index_usage_stats WHERE database_id = db_id();

select 
	@@servername as [server_name],
	db_name() as [database_name],
	db_id() as [database_id],
	t.object_id,
 	s.name as [schema_name],
	t.name as [table_name],
	ix.name as [index_name],
	ix.index_id,
	ius.user_seeks,
	ius.user_scans,
	ius.user_lookups,
	ius.user_updates,
	ius.last_user_seek,
	ius.last_user_scan,
	$IterationId AS [iterationid]
--INTO stat.IndexUsage
from sys.tables t 
inner join sys.indexes ix on t.object_id = ix.object_id
inner join sys.schemas s on t.schema_id = s.schema_id
left join #ius ius on ius.object_id = ix.object_id and ius.index_id = ix.index_id and ius.database_id = DB_ID()
WHERE t.is_ms_shipped = 0
ORDER BY [schema_name], [table_name], [index_id]
OPTION (RECOMPILE);

DROP TABLE #ius;
"@
	if($SqlCredential) {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance -SqlCredential $SqlCredential
	}
	else {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance 
	}	
	if($null -eq $Database) {
		$Database = $s.Databases | Where-Object IsAccessible -eq $true | Where-Object { $_.Name -NotIn @("master", "model", "msdb", "tempdb") } | Select-Object -ExpandProperty Name
	}
	
	foreach ($db in $Database)
	{
		try
		{
			if($SqlCredential) {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable -SqlCredential $SqlCredential -QueryTimeout 120
			}
			else {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable -QueryTimeout 120
			}
			Write-DbaDbTableData -SqlInstance $ReportSqlInstance -Database $ReportSqlDb -Schema stat -Table IndexUsage -InputObject $dt -BulkCopyTimeout 0
			
		}
		catch
		{
			Write-Host "Error occurred in $($s.Name) - $($db) - IndexUsage"
		}
		
	}
}


function Get-BmaFileSizes
{
	param (
		[string]$ServerInstance,
		[PSCredential]$SqlCredential,
		[int]$IterationId,
		[string[]]$Database,
		[string]$ReportSqlInstance,
		[string]$ReportSqlDb,
		[PSCredential]$ReportSqlCredential
	)
	
	# Scheduled Per Hour
	# Run per Database
	
	$query = @"
-- Attributed to Glenn Berry DMV Diagnostic Queries - https://glennsqlperformance.com/resources/
-- Individual File Sizes and space available for current database  (Query 51) (File Sizes and Space)
SELECT 
    @@SERVERNAME as [server_name],
    DB_NAME() as [database_name],
    f.name AS [file_name], 
    f.physical_name AS [physical_name], 
    CAST((f.size/128.0) AS DECIMAL(15,2)) AS [total_size_mb],
    CAST(f.size/128.0 - CAST(FILEPROPERTY(f.name, 'SpaceUsed') AS int)/128.0 AS DECIMAL(15,2)) AS [available_space_in_mb], 
    f.[file_id], 
    fg.name AS [filegroup_name],
    f.is_percent_growth, 
    f.growth, 
    fg.is_default, 
    fg.is_read_only, 
    -1 AS is_autogrow_all_files,
	$IterationId AS [iterationid]
--INTO stat.FileSizes
FROM sys.database_files AS f WITH (NOLOCK) 
LEFT OUTER JOIN sys.filegroups AS fg WITH (NOLOCK) ON f.data_space_id = fg.data_space_id
ORDER BY [file_id]
OPTION (RECOMPILE);
"@

	if($SqlCredential) {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance -SqlCredential $SqlCredential
	}
	else {
		$s = Connect-DbaInstance -SqlInstance $ServerInstance
	}
	
	if($null -eq $Database) {
		$Database = $s.Databases | Where-Object IsAccessible -eq $true | Where-Object { $_.Name -NotIn @("master", "model", "msdb", "tempdb") } | Select-Object -ExpandProperty Name
	}
	foreach ($db in $Database)
	{
		try
		{
			if($SqlCredential) {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable -SqlCredential $SqlCredential
				Write-DbaDbTableData -SqlInstance $ReportSqlInstance -Database $ReportSqlDb -Schema stat -Table FileSizes -InputObject $dt -BulkCopyTimeout 0
			}
			else {
				$dt = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $db -Query $query -As DataTable
				Write-DbaDbTableData -SqlInstance $ReportSqlInstance -Database $ReportSqlDb -Schema stat -Table FileSizes -InputObject $dt -BulkCopyTimeout 0
			}

		}
		catch
		{
			Write-Host "Error occurred in $($db) - FileSizes"
		}
	}
	
}


