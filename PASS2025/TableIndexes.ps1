function Get-BmaTableInfo {
param(
	[string]$SqlInstance = "SAVPORTAL",
	[string]$Database = "HealthEquityProduction",
	[string]$TableName,
	[string]$Schema,
	[switch]$Indexes,
	[switch]$Table,
	[switch]$Space,
	[switch]$Stats,
	[switch]$All
)

	if(!$All.IsPresent) {
		if($Indexes.IsPresent -or $Table.IsPresent -or $Space.IsPresent -or $Stats.IsPresent) {
			# do nothing
		}
		else {
			$All = $true;
		}
	}

	$db = Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database

	$server = $db.Parent

	$tableFields = $server.GetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Table]);
	$columnFields = $server.GetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Column]);

	[void]$tableFields.Add("DataSpaceUsed")
	[void]$tableFields.Add("IndexSpaceUsed")
	[void]$tableFields.Add("RowCount")
	[void]$tableFields.Add("HasClusteredIndex")
	[void]$tableFields.Add("IsSystemObject")

	[void]$columnFields.Add("DataType");
	[void]$columnFields.Add("InPrimaryKey");

	$server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Table], $tableFields);
	$server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Column], $columnFields);

	$tableObj = $db.Tables["$TableName", "$Schema"]

	if($Space.IsPresent -or $All.IsPresent -or $Table.IsPresent) {
		$a = @{Expression={$_.Name};Label="Name"}, `
			@{Expression={$_.DataSpaceUsed};Label="Data Space"}, `
			@{Expression={$_.IndexSpaceUsed};Label="Index Space"}, `
			@{Expression={$_.RowCount};Label="Rows"}, `
			@{Expression={$_.Columns.Count};Label="Columns"}, `
			@{Expression={$_.HasClusteredIndex};Label="IsClustered"}
		$tableObj | Format-Table $a -AutoSize
	}

	$definitionLength = 0;

	$nonunicode = "varchar,char"
	$unicodeNarrow = "nvarchar,nchar"
	$unicodeWide = "ntext"
	$nvarcharCount = 0
	$nvarcharDefine = 0

	$columns = $tableObj.Columns

	foreach($col in $columns) {
		if($nonunicode.Contains($col.DataType.ToString())) {
			$definitionLength += $col.DataType.MaximumLength;
		}
		elseif($unicodeNarrow.Contains($col.DataType.ToString())) {
			$definitionLength += $col.DataType.MaximumLength * 2;
			$nvarcharDefine += $col.DataType.MaximumLength * 2;
			$nvarcharCount++;
		}
		elseif($unicodeWide.Contains($col.DataType.ToString())) {
			$definitionLength += $col.DataType.MaximumLength;
		}
		elseif($col.DataType.MaximumLength -eq -1) {
			$definitionLength += 16;
		}
		else {
			$definitionLength += $col.DataType.MaximumLength;
		}
	}

	$var = @{};
	$var.DefinitionSize = $definitionLength;
	$var.NVarcharCount = $nvarcharCount;
	$var.NVarcharDefined = $nvarcharDefine;

	#Write-Host "`nDefinition Size: $definitionLength";
	#Write-Host "NVarChar count: $nvarcharCount";
	#Write-Host "NVarChar defined: $nvarcharDefine";

	if($All.IsPresent -or $Table.IsPresent) {
	$b = @{Expression={$_.Name};Label="Name"}, `
		@{Expression={$_.DataType};Label="DataType"}, `
		@{Expression={$_.Nullable};Label="Nulls"}, `
		@{Expression={$_.Identity};Label="IsIdentity"}, `
		@{Expression={$_.InPrimaryKey};Label="In PK"}, `
		@{Expression={$_.Properties["Length"].Value};Label="Length"}

	$columns | Format-Table $b -AutoSize
	}

	$var | Format-Table *

	if($All.IsPresent -or $Indexes.IsPresent) {
		$tableObj.Indexes | Select-Object Name, IndexedColumns, IsUnique, IsClustered, Id, HasCompressedPartitions, FillFactor | Sort-Object Id | Format-Table -AutoSize
	}

	if($All.IsPresent -or $Stats.IsPresent) {
	$idxstats = @"
	SELECT 
		ix.NAME AS index_name,
		ius.user_seeks,
		ius.user_scans,
		ius.user_lookups,
		ius.user_updates,
		ius.last_user_update as last_upd,
		ix.index_id
	FROM sys.schemas s
	INNER JOIN sys.tables t on s.schema_id = t.schema_id
	INNER JOIN sys.indexes ix ON t.object_id = ix.object_id
	INNER JOIN sys.dm_db_index_usage_stats AS ius ON t.object_id = ius.object_id AND ix.index_id = ius.index_id
	WHERE t.name = '$($tableObj.Name)' AND s.name = '$($Schema)'
	ORDER BY ius.index_id
"@

	$results = $db.ExecuteWithResults($idxstats);
	$results.Tables[0] | Select-Object index_name, user_seeks, user_scans, user_lookups, user_updates, last_upd, index_id | Format-Table *;
	}

	if($All.IsPresent -or $Space.IsPresent) {
	$dataspace = @"
		-- Total # of pages, used_pages, and data_pages for a given heap/clustered index by page type
		SELECT  CASE WHEN GROUPING(i.object_id) = 1 THEN '--- TOTAL ---'
					ELSE OBJECT_NAME(i.object_id)
				END AS objectName ,
				CASE WHEN GROUPING(i.name) = 1 THEN '--- TOTAL ---'
					ELSE i.name
				END AS indexName ,
				CASE WHEN GROUPING(a.type_desc) = 1 THEN '--- TOTAL ---'
					ELSE a.type_desc
				END AS pageType ,
				SUM(a.total_pages) AS totalPages ,
				( SUM(a.total_pages) * 8192 ) / 1024 / 1024 AS totalSpaceMB ,
				i.index_id
		FROM    
			sys.schemas s
			INNER JOIN sys.tables t on s.schema_id = t.schema_id
			INNER JOIN sys.indexes i ON t.object_id = i.object_id
				JOIN sys.partitions p ON i.object_id = p.object_id
										AND i.index_id = p.index_id
				JOIN sys.allocation_units a ON p.partition_id = a.container_id
		WHERE   s.name = '$Schema' AND t.name = '$($tableObj.Name)'
		--AND i.index_id <= 1
				AND i.object_id > 100
		GROUP BY i.object_id ,
				i.name ,
				a.type_desc ,
				i.index_id 
		ORDER BY i.index_id
"@

	$dataresults = $db.ExecuteWithResults($dataspace);
	$dataresults.Tables[0] | Format-Table -AutoSize
	}

	if($All.IsPresent -or $Indexes.IsPresent) {
	Write-Host "`nIndexes Included Columns"
	Write-Host "`============================"


	$cols = @(); 
	$colindex = 0;

	$indexcol = $tb.Indexes 
	foreach($index in $indexcol) {
		$cols += "Index: $($index.Name)"; 
		$found = $false;
		$indexedcolumns = $index.IndexedColumns
		foreach($icol in $indexedcolumns) {
			if($icol.IsIncluded -eq $true) {
				if(!$found) {
					$cols[$colindex] += " Columns: ";
					$found = $true;
				}
				$cols[$colindex] += "$($icol.Name), "; 
			} 
		} 
		$colindex++;
	}
	$cols

	}

}