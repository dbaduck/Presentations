$date = Get-Date -f "yyyyMMdd_HHmmss"
Start-Transcript -Path "$PWD\logs\Transcript_Gather_$date.txt"

Import-Module dbatools

$ReportServer = "localhost"
$ReportDatabase = "DEMO1"

# . c:\bin\Import-PsCredential.ps1

. "$PWD\GatherStats.ps1"

$server01 = @{}
$server01.ServerInstance = "localhost"
$server01.ReportSqlInstance = $ReportServer
$server01.ReportSqlDb = $ReportDatabase

# $server02 = @{}
# $server02.ServerInstance = "SERVER2"
# $server02.ReportSqlInstance = $ReportServer
# $server02.ReportSqlDb = $ReportDatabase


$servers = @($server01)

$iterationid = Get-BmaIterationId -ServerInstance $ReportServer -Database $ReportDatabase

foreach($server in $servers)
{
	$server.ServerInstance
	"Get-BmaIndexUsage"
	Get-BmaIndexUsage @server -IterationId $iterationid 
	"Get-BmaTableStatistics"
	Get-BmaTableStatistics @server -IterationId $iterationid 
}

stop-transcript
