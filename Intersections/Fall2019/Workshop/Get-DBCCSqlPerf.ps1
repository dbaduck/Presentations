
import-module sqlserver

function Get-DBCCSqlPerf {
	param (
		$ServerInstance,
		$DatabaseName
	)

	$query = "DBCC SQLPERF(LOGSPACE)"

	$results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -Query $query
	if ($DatabaseName)
	{
		$results | Where { $_."Database Name" -eq $DatabaseName }
	}
	else
	{
		$results
	}
}
