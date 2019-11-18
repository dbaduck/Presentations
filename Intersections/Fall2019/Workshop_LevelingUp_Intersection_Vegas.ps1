
############# Start up your Engines #########################
$host

# Ensure that you are on 5.1
Get-ExecutionPolicy -List
####### Set up your environment to be successful ############
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned # -force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Get-PSRepository

# Intrinsic Variables
# \Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1
$PROFILE  # In the PowerShell Integrated

# The above will be different from the regular PowerShell one that you will use for automations
# Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
$PROFILE   # in the PowerShell


$PSVersionTable
$PSVersionTable.CLRVersion.Major
$Host
$Host.Version

Get-Variable

Split-Path $profile

#####################################################################
# Profile
#####################################################################

$date = Get-Date -f "yyyyMMdd_HHmmss"
# If the path does not exist, it will be created for you, including directories
Start-Transcript -Path "$(Split-Path $profile)\Transcript_$date.txt"
Start-Transcript -Path "$(Split-Path $profile)\Transcript_$(Get-Date -f 'yyyyMMdd_HHmmss').txt"

Register-EngineEvent PowerShell.Exiting -Action { Stop-Transcript } -SupportEvent

if (Test-Path -path "$(Split-Path $profile)\History.clixml")
{
	$history = Import-Clixml -Path "$(Split-Path $profile)\History.clixml"
	$history | Add-History
}

function Exit-Me
{
	Stop-Transcript
	Get-History | Where ExecutionStatus -eq "Completed" | Export-Clixml -Path "$(split-path $profile)\History.clixml"
	Exit
}


function Get-MyOsAssemblies
{
	[AppDomain]::CurrentDomain.GetAssemblies() | Sort FullName | select FullName
}


Invoke-Expression "function $([char]4) { Exit-Me }"



########################################################
# Prompt
function prompt
{
	
	# Set Window Title
	$host.UI.RawUI.WindowTitle = "$ENV:USERNAME@$ENV:COMPUTERNAME - $(Get-Location)"
	
	$lastCommand = Get-History -Count 1
	$nextId = $lastCommand.Id + 1;
	$ElapsedTime = ($LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime).TotalSeconds
	
	# Set Prompt
	Write-Host (Get-Date -Format G) -NoNewline -ForegroundColor Red
	Write-Host " :: " -NoNewline -ForegroundColor DarkGray
	#Write-Host "$ENV:USERNAME@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
	Write-Host "[$($ElapsedTime) s]" -NoNewLine -ForegroundColor Yellow
	
	Write-Host " :: " -NoNewline -ForegroundColor DarkGray
	Write-Host $(get-location) -ForegroundColor Green
	
	# Check for Administrator elevation
	$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$prp = new-object System.Security.Principal.WindowsPrincipal($wid)
	$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	$IsAdmin = $prp.IsInRole($adm)
	if ($IsAdmin)
	{
		$host.UI.RawUI.WindowTitle += " - Administrator"
		Write-Host " [$nextId] #" -NoNewline -ForegroundColor Gray
		return " "
	}
	else
	{
		Write-Host " [$nextId] >" -NoNewline -ForegroundColor Gray
		return " "
	}
}
########################################################
# End Profile
########################################################





# SMO or Object based stuff

# PowerShell operates in a "First In Wins"
$a = 1
$b = "0"

$a + $b
$b + $a

$c = "a"
$a + $c

$smo = "Microsoft.SqlServer.Management.Smo"
$ServerInstance = "WIN2019A"

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SQlSErver.Smo")

Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=15.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

Install-Module sqlserver
Install-Module dbatools
Install-Module ImportExcel

Get-Module -ListAvailable dbatools
Get-MyOsAssemblies

Import-module SqlServer

# GAC_MSIL \ Microsoft.SqlServer.Smo is the assembly
# SSMS and other new tools are not putting the SMO libraries in the GAC
# Import-Module sqlserver

# Connect to SQL
$server = New-Object -TypeName "$smo.Server" -ArgumentList $ServerInstance
"$($smo)_Server"
# $server = New-Object -TypeName $smo + ".Server" -ArgumentList $ServerInstance

$server.Name

"$(Split-Path $profile)\Transcript_$(Get-Date -f 'yyyyMMdd_HHmmss').txt"
"$(Split-Path $profile)\Transcript_$(Get-Date -f `"yyyyMMdd_HHmmss`").txt"
"$(Split-Path $profile)\Transcript_$(Get-Date -f ""yyyyMMdd_HHmmss"").txt"

$server | Get-Member

# Get a database name
# Smo puts databases in name order
# Indexing into collections
# 0 based index, and also accepts Name
$server.Databases["master"].Name
$server.Databases[0].Name

$server.Databases["master"]

$server.Databases.Name
$server.Databases.Count

$server.Databases["DEMODB"].Tables.Name
$server.Databases["DEMODB"].Tables["Table11","dbo"] | Get-Member

$server.Databases["DEMODB"].Tables["Table11","dbo"] | format-list *
$server.Databases["DEMODB"].Tables["Table11","dbo"] | Select Name, Schema, Size, RowCount



$server.Databases["DEMODB"].Schemas
$server.Databases.Name -contains "bob"

$server.Databases["demodb"].Schemas.Refresh()

$server.Databases["DEMODB"].Tables.Name -contains "a"

$server.Databases["DEMODB"].Tables.Script()

$server.Databases["DEMODB"].Tables | ForEach-Object { $_.Script() | Add-Content -Path "c:\temp\tables\$($_.Parent.Name)_$($_.Schema)_$($_.Name).txt" }

# Get a Configuration parameter
$server.Configuration.MaxServerMemory.ConfigValue
$server.Configuration.MaxServerMemory

# Change the value
$server.Configuration.MaxServerMemory.ConfigValue = 4096
$server.Configuration.MaxServerMemory

# Alter the configuration - RECONFIGURE
$server.Configuration.Alter()

# Alter the configuration with force - RECONFIGURE WITH OVERRIDE
$server.Configuration.Alter($true)

$server.Configuration | Get-Member
$server.Configuration.MaxServerMemory | Get-Member

# Let's Get the ErrorLog
$server.NumberOfLogFiles

$server.NumberOfLogFiles = 30
$server.NumberOfLogFiles

$server.Alter()


###################################
#  Database Stuff
###################################

# Database Recovery Model
$db = $server.Databases['DEMODB']

$db.RecoveryModel
$db.PageVerify

$db.RecoveryModel = "Simple"
$db.PageVerify = "Checksum"

$db.RecoveryModel = "Bob"

$db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full

$db.Alter()

### Termination Clause options
# Enum name [Microsoft.SqlServer.Management.Smo.TerminationClause]
#
# FailOnOpenTransactions
# RollbackTransactionsImmediately
#
# [Microsoft.SqlServer.Management.Smo.TerminationClause]::FailOnOpenTransactions
# [Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately

$rollback = [Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately
$db.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately)


$rollback = [Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately
$db.Alter("RollbackTransactionsImmediately")

# Reusable Code

# Example of code you won't want to type
[AppDomain]::CurrentDomain.GetAssemblies() | Sort FullName | select FullName


function Get-MyOsAssemblies
{
	[AppDomain]::CurrentDomain.GetAssemblies() | Sort FullName | select FullName
}


Get-MyOsAssemblies

##########################################################################


# Get Modules
# PowerShellGallery.com
Find-Module dbatools*

Install-Module dbatools
Save-Module dbatools -Path c:\temp
Update-Module dbatools


# Let's dive into some modules

Import-Module SqlServer

Get-Module

# Prepare
$ServerInstance = "WIN2019A"

$server = Get-SqlInstance -ServerInstance $ServerInstance # -Credential (Get-Credential)

$server.GetType()
$server.name

# SQL Server module 
# disabled by default
Add-SqlLogin -LoginName sabob -LoginType SqlLogin -ServerInstance $ServerInstance -LoginPSCredential (Get-Credential)

# with enable
$login = Add-SqlLogin -LoginType SqlLogin -ServerInstance $ServerInstance -LoginPSCredential (Get-Credential) # -Script
$login.GetType()

# cannot connect to sql without this
Add-SqlLogin -LoginType SqlLogin -ServerInstance $ServerInstance -LoginPSCredential (Get-Credential) -GrantConnectSql -Enable -Script
Add-SqlLogin -LoginType WindowsGroup -ServerInstance $ServerInstance -LoginName "DBADUCK\Administrator" -GrantConnectSql -Enable -Script

$var = Get-SqlLogin -ServerInstance $serverinstance -LoginName saben 
#$var.IsDisabled = $false
$var.DenyWindowsLogin = $false
$var.Alter()
$var.Enable()

$var | Get-Member -Name IsDisabled, DenyWindowsLogin

$var.GetType()
$var[0]
$var[1]

Get-SqlLogin -ServerInstance $serverinstance -LoginType SqlLogin | Where IsSystemObject -eq $false | 
	Where Name -notlike "##*" | Foreach { $_.DenyWindowsLogin = $false; $_.Alter() }

Get-SqlDatabase -ServerInstance $serverinstance  | foreach { $_.PageVerify = "Checksum"; $_.CompatibilityLevel = "150"; $_.Alter() }

$var 
$var | Get-Member
Get-Help Add-SqlLogin -ShowWindow


Get-PSDrive

#Sql Authentication
New-PsDrive -Name BEN -PSProvider SqlServer -Root "SQLSERVER:\sql\WIN2019A\default" -Credential (get-credential)
get-psdrive

cd sqlserver:\sql\win2019a\default\databases\DEMODB\Tables

Backup-SqlDatabase -Database DEMODB -BackupAction Database -CompressionOption On

Backup-SqlDatabase -ServerInstance $ServerInstance -Database DEMODB -BackupAction Database
cd \
$urn = $server.Urn
$server.Databases["DEMODB"].Urn
$urn = $server.Databases["DEMODB"].Urn
.Tables["TestSchema","dba"].Urn

cd (Convert-UrnToPath -Urn $server.Databases["DEMODB"].Urn)
$urn

invoke-sqlcmd -InputFile "CREATE DATABASE B" -Database master
test-path "BEN:\databases\B"
$path = Convert-UrnToPath -Urn $urn

cd $path

$obj = $server.GetSmoObject($urn)

# SQL Agent

Get-SqlAgent -ServerInstance $ServerInstance

Get-SqlAgentJob -ServerInstance $ServerInstance

Get-SqlAgentJobHistory -ServerInstance $ServerInstance -startrundate (get-date).addhours(-1)


Get-SqlBackupHistory -ServerInstance $ServerInstance -DatabaseName DEMODB | fl *

Get-SqlDatabase -ServerInstance $ServerInstance -Name DEMODB

$demodb = Get-SqlDatabase -ServerInstance $ServerInstance -Name DEMODB

# Now let's use the Pipeline
$server | Get-SqlDatabase -Name DEMODB

Get-SqlErrorLog -ServerInstance $ServerInstance -After (Get-Date).AddHours(-8) | where Text -Like "*process*"
Get-SqlErrorLog -ServerInstance $ServerInstance | where Text -Like "*login*"

Get-SqlErrorLog -ServerInstance $ServerInstance | where ArchiveNo -EQ 1


## 
## Welcome to Provider Context
##

CD $path
Get-SqlErrorLog -After (Get-Date).AddHours(-1)

Get-SqlLogin -LoginName sa

Invoke-Sqlcmd -Database master -Query "SELECT Name from sys.databases" -QueryTimeout 0

Invoke-Sqlcmd -Database master -Query "SELECT Name from sys.databases" -QueryTimeout 0 -SuppressProviderContextWarning

Invoke-Sqlcmd -Database master -Query "SELECT Name from sys.databases" -QueryTimeout 0 -IgnoreProviderContext

Read-SqlTableData -TableName "TestTable" -SchemaName "dbo"

CD sqlserver:\sql\win2019a\default\Databases\DEMODB

Read-SqlTableData -TableName "Table14" -SchemaName "dbo" -TopN 10  # -IgnoreProviderContext 

Read-SqlTableData -DatabaseName "DEMODB" -TableName "TestTable1" -SchemaName "dbo" -IgnoreProviderContext

Read-SqlTableData -ServerInstance $ServerInstance -DatabaseName "DEMODB" -TableName "TestTable1" -SchemaName "dbo" -IgnoreProviderContext

Read-SqlTableData -TableName "TestTable1" -SchemaName "dbo" -TopN 1 -


Get-SqlLogin -LoginName saben -ErrorAction SilentlyContinue | Remove-SqlLogin -Force 

Set-SqlErrorLog -MaxLogCount 99



# Put some data into SQL Server
$data = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "select name, database_id from sys.databases" -Database master -OutputAs DataTables

Write-SqlTableData -ServerInstance $ServerInstance -DatabaseName DEMODB -SchemaName dbo -TableName ImportOfDatabases1 -InputData $data -Force

cd sqlserver:\sql\win2019a\default\databases\DEMODB
cd Tables

dir | foreach { $_.Script() | Add-Content "c:\temp\scripts\$($_.Parent.Name)_$($_.Schema)_$($_.Name).sql" }

dir | Select -first 10 | foreach { $_.Drop() }
dir | foreach { $_.Drop() }

$var = dir
$var.Drop()

dir | Remove-Item

dir c:\temp\scripts\*.sql | foreach { invoke-sqlcmd -InputFile $_.FullName }

# DBAtools Module
# Restart Console New
$ServerInstance = "WIN2019A"

Import-Module dbatools

Add-DbaCmsRegServer

Add-DbaCmsRegServerGroup

$server = Connect-DbaInstance -SqlInstance $ServerInstance 

Copy-DbaLogin -Source $ServerInstance -Destination "win2019b" -ExcludeSystemLogins

Start-DbaMigration

get-command -module dbatools | Measure-Object

Copy-DbaSpConfigure -Source $ServerInstance -Destination "LIN2019A" # -ConfigName MaxServerMemory
Export-DbaSpConfigure -SqlInstance $ServerInstance -Path c:\temp\sp_configure_localhost.sql

Enable-DbaTraceFlag -SqlInstance $ServerInstance -TraceFlag 2371
Get-DbaTraceFlag -SqlInstance $ServerInstance

Disable-DbaTraceFlag -SqlInstance $ServerInstance -TraceFlag 3226
Get-DbaTraceFlag -SqlInstance $ServerInstance

Export-DbaLogin -SqlInstance $ServerInstance

Get-DbaDatabase -SqlInstance $ServerInstance -Database DEMODB,A
Get-DbaDatabase $ServerInstance DEMODB
Get-DbaDatabase -Sql
Get-DbaDbSpace -SqlInstance $ServerInstance -Database DEMODB

Function f {
	param (
			$Computername,
			$Component
	)

	$Computername
	$Component
}
f -compo "Ben"

$var = Get-DbaDbFile -SqlInstance $SErverInstance -Database DEMODB

Get-DbaDbVirtualLogFile -SqlInstance $ServerInstance -Database DEMODB

Get-DbaMaxMemory -SqlInstance $serverinstance

Get-DbaDefaultPath -SqlInstance $ServerInstance

Get-DbaDiskSpace -ComputerName "localhost"

Get-DbaErrorLog -SqlInstance $ServerInstance -LogNumber 1 -Text "Login"

Get-DbaLastBackup -SqlInstance $ServerInstance -Database DEMODB


Get-DbaMaxMemory -SqlInstance $ServerInstance

Test-DbaMaxMemory -SqlInstance $ServerInstance

Test-DbaMaxDop -SqlInstance $ServerInstance

Get-DbaServerProtocol -ComputerName "Localhost"

# Get the TCP Port from SQL Server
Get-DbaTcpPort -SqlInstance $ServerInstance
Set-DbaTcpPort -SqlInstance $ServerInstance -Port -IpAddress

Get-DbaAgentJobStep -SqlInstance $ServerInstance -Job "Waitfor Job"


Start-DbaAgentJob -SqlInstance $ServerInstance -Job "Waitfor Job"
Get-DbaRunningJob -SqlInstance $ServerInstance
Stop-DbaAgentJob -SqlInstance $ServerInstance -Job "Waitfor Job"

# Another way
$server | Get-DbaRunningJob
Get-DbaRunningJob -SqlInstance $serverinstance	
$server = Connect-DbaInstance -SqlInstance $serverinstance

Get-DbaAgentJob -SqlInstance $serverinstance | Get-DbaRunningJob

get-help Get-DbaRunningJob -ShowWindow


# Does not work in this build
Install-DbaFirstResponderKit

# Other comment
Install-DbaWhoIsActive -SqlInstance $ServerInstance -Database master

Start-DbaAgentJob -SqlInstance $ServerInstance -Job "Waitfor Job"
Invoke-DbaWhoIsActive -SqlInstance $ServerInstance

Invoke-DbaQuery -SqlInstance $ServerInstance -Query "select name from sys.databases" -Database master # -As (DataRow, DataSet, DataTable, PsObject, SingleValue)

New-DbaAgentJob
New-DbaAgentJobStep

Read-DbaBackupHeader -SqlInstance $ServerInstance -Path "C:\SQLBACKUP\demodb.bak"


Set-DbaDbOwner -ServerInstance $ServerInstance -Database DEMODB -TargetLogin "saben"
Set-DbaDbOwner -ServerInstance $ServerInstance -Database DEMODB -TargetLogin "sa"

Test-DbaDbOwner -SqlInstance $ServerInstance -Database DEMODB

Test-DbaDbRecoveryModel -SqlInstance $ServerInstance -Database DEMODB

Test-DbaConnection -SqlInstance $ServerInstance

Test-DbaPowerPlan -ComputerName localhost
Set-DbaPowerPlan -ComputerName localhost -PowerPlan "HighPerformance"

$csv = Import-Csv -Delimiter "," -Path "c:\temp\names.txt"

$dt = $csv | ConvertTo-DbaDataTable
Write-DbaDataTable -SqlInstance $ServerInstance -Database demodb -Table blah -Schema dbo -InputObject $csv -AutoCreateTable

Write-DbaDataTable -SqlInstance $ServerInstance -Database demodb -Table blah -Schema dbo -InputObject $dt -AutoCreateTable

############### Excel Module ###############

Install-Module ImportExcel

Import-Module ImportExcel

$exceldata = Invoke-DbaQuery -SqlInstance $ServerInstance -Query "select database_id, name from sys.databases order by name" -Database master -As DataTable


$exceldata | select Name, database_id | Export-Excel -Path c:\test\testexcel.xlsx -WorksheetName "bob" -Show

$data = Get-Service | Select Status, Name, DisplayName, StartType
$data | Export-Excel c:\temp\test_export.xlsx -AutoSize

$Text1 = New-ConditionalText Stop
$data | Export-Excel c:\temp\test_stop.xlsx -AutoSize -ConditionalText $Text1

$Text2 = New-ConditionalText runn Blue Cyan
$data | Export-Excel c:\temp\test_runn.xlsx -AutoSize -ConditionalText $Text1, $Text2

$Text3 = New-ConditionalText svc Wheat Green
$data | Export-Excel c:\temp\test_svc.xlsx -AutoSize -ConditionalText $Text1, $Text2, $Text3

$data = Get-Process | Where Company | Select Company, Name, PM, Handles, *mem*
$cfmt = New-ConditionalFormattingIconSet -Range "C:C" -ConditionalFormat ThreeIconSet -IconType Arrows
$data | Export-Excel c:\temp\test_process.xlsx -AutoSize -ConditionalFormat $cfmt

$ctext = New-ConditionalText Microsoft Wheat Green
$data | Export-Excel c:\temp\test_fmttext.xlsx -AutoSize -ConditionalFormat $cfmt -ConditionalText $ctext

get-command -module importexcel | Measure-Object



$splat = @{SqlInstance="win2019a"; Database = "DEMODB"}
$rbhdefault = @{
	SqlInstance = "win2019a"
	Database = "DEMODB"
	LastFull = $true
}

$splat2 = @{
	SqlInstance = "win2019b"
	Database = "DEMODB"
}

Get-DbaDbBackupHistory @rbhdefault
$rbhdefault.Database = "A"
Get-DbaDbBackupHistory @rbhdefault

| Restore-DbaDatabase -SqlInstance win2019b -TrustDbBackupHistory

function abc {
	param (
		$SqlInstance,
		$Database
	)

}
abc @splat
