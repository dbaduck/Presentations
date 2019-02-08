
###################################################################
#  PowerShell Tips and Tricks
###################################################################

###################################################################
# CREATE DATABASE DEMODB
#  1..50 | % { Invoke-Sqlcmd -serverinstance localhost -database DEMODB -query "CREATE TABLE dbo.[Table$_] (id int not null, name [varchar](20) null)" }
###################################################################

####################################################
# Profile tips
####################################################
# Profile lives in Documents\WindowsPowerShell
# md is an alias for mkdir which is a command to make a directory
md (Split-Path $profile)
# or
New-Item -Path (Split-Path $profile) -ItemType Directory
New-Item -Path $profile -ItemType File

# Examples of what Split-Path can do
Split-Path $profile
Split-Path $profile -Leaf
Split-Path $profile -Qualifier
Split-Path $profile -NoQualifier

notepad $PROFILE

. $profile

####################################################
# Start of Profile
####################################################
$date = Get-Date -f "yyyyMMdd_HHmmss"
Start-Transcript -Path "$(Split-Path $profile)\Transcript_$date.txt"

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

Invoke-Expression "function $([char]4) { Exit-Me }"

########################################################
# Prompt
########################################################
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


####################################################
# Array vs. ArrayList
####################################################
<#
	[System.Collections.ArrayList]
	.NET type
	.Add(object) to add to the array list
	Memory Buffer

	Array (native to PowerShell)
	@( ) is a blank Array
	@(1,2,3)
	1,2,3
	$ary += $obj to add to the array
	Immutable – cannot be changed
#>

$ary = @()
$ary = @('1', '2', '3')
$ary = "1", "2", "3"

$ary2 = [System.Collections.ArrayList]@()
$ary2 = New-Object -TypeName System.Collections.ArrayList

# Slower
Measure-Command -Expression { 1 .. 10000 | ForEach-Object { $ary += $_ } }

# Super Fast
Measure-Command -Expression { 1 .. 10000 | ForEach-Object { $null = $ary2.Add($_) } }

####################################################
# Get Assemblies in your session
####################################################
<#
	Assemblies get loaded by PowerShell
	Assemblies can be loaded by Modules
	Assemblies can be loaded by You

	PowerShell is on top of .NET (Core or Full)
	Assemblies have functionality you don't have to write

	[AppDomain]::CurrentDomain.GetAssemblies()
#>
[Appdomain]::CurrentDomain.GetAssemblies() | select FullName | Sort FullName


####################################################
# Strings vs. Stringbuilder
####################################################
<#
	$obj = "String"
	$obj = "String" + " " + "Builder"
	$obj = "$obj Builder"
	Strings are Immutable – cannot be changed

	[System.Text.StringBuilder]

	$obj = new-object –typename System.Text.StringBuilder –Args 4096
	$obj.Append(" ") or $obj.AppendLine(" ")
	$obj.AppendFormat("{0} {1}", "one", "two")

	Returns an object
#>

$str1 = "This is a string"
$str2 = " and I added it to another"

$str3 = $str1 + " " + $str2
$str3 = "$str1 $str3"

$str3 = New-Object -TypeName System.Text.StringBuilder -Args 8192

$null = $str3.Append($str1)
$null = $str3.Append(" ")
$null = $str3.Append($str2)

$null = $str3.AppendFormat("{0} {1}", $str1, $str2)

$str3.ToString()

$bigstring = ""
Measure-Command -Expression { 1 .. 10000 | ForEach-Object { $bigstring += $_ } }

Measure-Command -Expression { 1..10000 | ForEach-Object { $null = $str3.Append($_) } }


####################################################
# 1 .. X iteration
# I want to do something X number of times.
####################################################
<#
	1..5 produces an array of 1 – 5 one at a time
	Can be used with Foreach()
	Increments by 1 so you can start at any number
	Can be done in reverse order
	5..1 and it will produce 5,4,3,2,1

	Useful and kind of like GO 5 except that it does not always have to go in reverse, and you can use the number in PowerShell

	1..5 | Foreach { $_ }
#>
1 .. 10

1 .. 10 | foreach { $_ }

1 .. 10 | foreach { $_ += $_; $_ }

# Practical Use
1 .. 10 | foreach (expand a Log file )

####################################################
# .ForEach () usage
####################################################
<#
	Dynamic Properties and Methods

	$obj.Foreach( { code block; } )

	Iteration for each item in the collection in $obj

	* Bonus: You can add your own as well.

	<?xml version="1.0" encoding="utf-8" ?>
	<Types>
	    <!--Microsoft.SqlServer.Management.Smo.Database -->
	    <Type>
	        <Name>Microsoft.SqlServer.Management.Smo.Database</Name>
	        <Members>
	            <ScriptMethod>
	                <Name>Query</Name>
	                <Script>
	                    param (
	                        $Query,

	                        $AllTables = $false
	                    )

	                    if ($AllTables) { ($this.ExecuteWithResults($Query)).Tables }
	                    else { ($this.ExecuteWithResults($Query)).Tables[0] }
	                </Script>
	            </ScriptMethod>
	            <ScriptMethod>
	                <Name>Invoke</Name>
	                <Script>
	                    param (
	                        $Command
	                    )

	                    $this.ExecuteNonQuery($Command)
	                </Script>
	            </ScriptMethod>
	        </Members>
	    </Type>
	    
	    <!--Microsoft.SqlServer.Management.Smo.Server -->
	    <Type>
	        <Name>Microsoft.SqlServer.Management.Smo.Server</Name>
	        <Members>
	            <ScriptMethod>
	                <Name>Query</Name>
	                <Script>
	                    param (
	                        $Query,

	                        $Database = "master",

	                        $AllTables = $false
	                    )

	                    if ($AllTables) { ($this.Databases[$Database].ExecuteWithResults($Query)).Tables }
	                    else { ($this.Databases[$Database].ExecuteWithResults($Query)).Tables[0] }
	                </Script>
	            </ScriptMethod>
	            <ScriptMethod>
	                <Name>Invoke</Name>
	                <Script>
	                    param (
	                        $Command,

	                        $Database = "master"
	                    )

	                    $this.Databases[$Database].ExecuteNonQuery($Command)
	                </Script>
	            </ScriptMethod>
	        </Members>
	    </Type>
	</Types>

#>
(1..10).Foreach{ "Hello $_" }
(1..10).Foreach({ "Hello $_" })

Import-Module dbatools

$server = Connect-DbaInstance -SqlInstance "localhost" -Database master

$server.Query("select name from sys.databases")

####################################################
# Splatting (what is this?)
####################################################
<#
	Splatting is all about a Variable satisfying Parameters
	Variables look like this $obj

	Splatting uses @obj 

	Basically a Hash Table with multiple Keys/Values passed into a function/cmdlet

	Rules: You can splat with a variable that has as many or fewer parameter satisfying keys/values but NOT more.
#>
function get-mytestfunction
{
	param (
		$FirstName,
		$LastName,
		$FavoritePet
	)
	
	Write-Host "$FirstName $LastName $FavoritePet"
	
}
$splat = @{
	FirstName = "Ben"
	LastName  = "Miller"
	Bob = "Miller"
}

get-mytestfunction @splat

get-mytestfunction @splat -FavoritePet "Lily"


####################################################
# -eq vs. –ceq
####################################################
<#
	PowerShell is Case Insensitive
	Comparing values (mostly Strings) is the same
	Ben = ben

	Comparison Operators
	-eq -lt -gt etc.

	Case Sensitive Operators
	-ceq -clt -cgt etc.

	Great for password comparison and others that require Case Sensitivity

#>
"BEN" -cne "ben"
"BEN" -ceq "ben"
"BEN" -ceq "BEN"

####################################################
# Pipelining
####################################################
<#
	Using the Pipeline character | (pipe character)

	Objects are passed By Value not By Reference on the pipeline
	That means Copies are made of the object
	Keep the objects getting smaller on the left and getting smaller going to the right

	Powerful Tip to pass a set of objects over a pipe to a Cmdlet that handles a set of objects
#>
Import-Module SqlServer

# By Value
Get-SqlDatabase -ServerInstance localhost | Backup-SqlDatabase -CompressionOption On

# Let's get all the databases that are NOT system
Get-SqlDatabase -ServerInstance localhost | Where IsSystemObject -eq $false | Backup-SqlDatabase -CompressionOption On

# By PropertyName
function Get-MyComputerName
{
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		$ComputerName
	)
	
	Write-Host "You are on my computer named $ComputerName"
}

$obj = "" | select ComputerName
$obj.ComputerName = "BoboBob"

$obj | Get-MyComputerName


####################################################
# Object Creation tips
####################################################
<#
	You will typically need objects to store data in during automation

	1. $obj = New-Object –TypeName PSObject
	Add-Member
	2. $obj = "" | Select Name, ID, Description
	3. $obj = @{ Name = Value; ID=6; Description = "Desc" }

	The only one I would stay away from on custom objects is #1

#>
$obj = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -Args "localhost"

$smo = "Microsoft.SqlServer.Management.Smo"
$obj = New-Object -TypeName "$smo.Server" -Args "localhost"

$obj = "" | select Name, Id, HappyDay

$obj | Get-Member


###################################################################
#  SQL Server Tips and Tricks
###################################################################


####################################################
# SMO
####################################################
<#
	SMO is a great tool and totally accessible from PowerShell

	Knowing when to use it is the key
	If you need to manipulate the object (Table, Database, etc) use SMO
	If you need information you can use SMO
	It you need information from a set of objects, testing is needed

	Some objects can be easily pulled and manipulated using 
	Server.SetDefaultInitFields
#>
$smo = "Microsoft.SqlServer.Management.Smo"
$server = New-Object -TypeName "$smo.Server" -Args "localhost"

# tip for demos, set the statement timeout to 5 seconds
$server.ConnectionContext.StatementTimeout = 5
$server.ConnectionContext.Connect()

$databaseName = "DROPME"
$database = $server.Databases["master"]
$database = $server.Databases[$databaseName]
$database.PageVerify
# Tip, properties are in memory until you Alter() (meaning please send me to SQL)
$database.PageVerify = "CHECKSUM"
$database.Alter()

# Or you can just drop it
$database.Drop()

# Oops there are connections to the database
$server.KillAllProcesses($databaseName)
$database.Drop()

$server.Databases

####################################################
# SetDefaultInitFields
####################################################
<#
	Method is on the Server object
	Parameters are Object Type and String Collection of fields

	Types are like this
	[Microsoft.SqlServer.Management.Smo.Database]

	String collections are like this
	$coll = new-object –typename System.Collections.StringCollection
	$coll.Add("ID")

	$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database, $coll)
#>
$coll = new-object –typename System.Collections.StringCollection
$coll.Add("ID")

$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], $coll)

####################################################
# Refresh
####################################################
<#
	Objects are powerful in PowerShell
	Once properties are pulled from SQL, they are in memory
	Once in Memory they are not asked for again

	Use Refresh() on any object to signal to SMO to retrieve it again

	Normally needed when you are adding objects or if something is going to change like Disk Space or space used on the object

	When using Alter() the property is already refreshed because you set it
	Must be done on each object
	$collection.Foreach( { $_.Refresh() } )
#>
$smo = "Microsoft.SqlServer.Management.Smo"
$server = New-Object -TypeName "$smo.Server" -Args "localhost"

$server.Databases.Name

# Go rename a database
$server.Databases.Name

$server.Databases.Refresh()
$server.Databases.Name

$server.Databases.PageVerify
$server.Databases.Foreach({ $_.Refresh() })

$server.Databases.PageVerify


####################################################
# Test-Path in the SQL Provider
####################################################
<#
	SQLPS (deprecated) and SQL Server module load a Provider
	Providers represent a service in a Path-like Structure
	Providers manifest themselves as Drives (PSDrives)

	SQLSERVER: is the drive that gets loaded by the SqlServer module

	Path to a Database
	SQLSERVER:\sql\servername\instancename\Databases\master
	If you are using a Default Instance the instance name is DEFAULT

	Now you can test for the existence of a database called Ben
	Test-Path SQLSERVER:\sql\localhost\default\Databases\Ben
	If it exists, you will get back True, if not then False 

#>
Test-Path SQLSERVER:\SQL\localhost\default\databases\DEMODB

Test-Path SQLSERVER:\SQL\localhost\default\databases\DEMODB\Tables\dbo.Table1



####################################################
# SQL Authentication and the Provider
####################################################
<#
	By Default, SQLSERVER: drive uses Windows Authentication
	Because it is drive representation, you can use a Credential

	Get-PSDrive to see which drives are present
	New-PSDrive to create a new drive

	SQL Provider recognizes the -Credential parameter for SQL Auth

	When you see SQLSERVER:\sql\path……+sa
	The + indicates that you are using SQL authentication
	Need the Root at least to the Instance level to use SQL Authentication but you can go further, even with Windows Authentication
#>
Get-PSDrive

$credential = Get-Credential -UserName sa

New-PSDrive -Name BEN -PSProvider SqlServer -Root SQLSERVER:\SQL\localhost\DEFAULT -Credential $credential

Set-Location BEN:

# Cheat like Microsoft
function BEN:
{
	Set-Location BEN:
}

BEN:

# Notice the drive path
Get-PSDrive

####################################################
# Invoke-SqlCmd
####################################################
<#
	Using TSQL in PowerShell can be useful

	$query = "select * from sys.databases"

	Use Invoke-SqlCmd to get the data
	ServerInstance servername
	Database databasename
	Query $query
	Special clauses in the SqlServer module now
	-OutputAs
	Values (DataRows (default), DataTable, DataSet)
	Use QueryTimeout 0 if you intend it to take longer than 10 minutes

#>
$rows = Invoke-Sqlcmd -ServerInstance localhost -Database master -Query "select name from sys.databases order by name ASC"
$tables = Invoke-Sqlcmd -ServerInstance localhost -Database master -Query "select name from sys.databases order by name ASC" -OutputAs DataTables

$rows.GetType()
$tables.GetType()


####################################################
# Write-SqlTableData
####################################################
<#
	This one is in the SqlServer module (NOT SQLPS)
	One like this is in the DBAtools module as well (Write-DbaDataTable)

	Basically you can write data to a table in SQL from an object
	-Force can be used to create the table
	Strings become nvarchar(max) so not amazingly useful

	Super fast, uses SqlBulkCopy to get the data in
	Automaps by position of the column, not by column name
#>
$databases = Invoke-Sqlcmd -ServerInstance localhost -Database master -Query "SELECT name, database_id from sys.databases order by name asc"
Write-SqlTableData -ServerInstance localhost -DatabaseName DBA -SchemaName dbo -TableName DatabaseNames -InputData $databases -Force

Read-SqlTableData -ServerInstance localhost -DatabaseName DBA -TableName DatabaseNames -SchemaName dbo -OutputAs DataTable |
	Write-SqlTableData -ServerInstance localhost -DatabaseName DBA -TableName DBNames -SchemaName dbo -Force

####################################################
# Using SQL Provider Context
####################################################
<#
	Commands in the SqlServer module understand context
	Inside SQLSERVER:\sql\server\instance\Databases you can use a command that understands where you are.

	Invoke-SqlCmd will use the context of the server you are in

	Backup-SqlDatabase will also use context and will also use settings in the instance
#>
SQLSERVER:
cd \sql\localhost\default\databases

Backup-SqlDatabase -Database DEMODB


####################################################
# Extra stuff
####################################################
# SQL Server Provider fun

SQLSERVER:
Set-Location \sql\localhost\default\Databases\DEMODB\Tables

$date = Get-Date -f "yyyyMMdd_HHmmss"

# dir is alias for Get-ChildItem or gci is another alias
# foreach is an alias for Foreach-Object
dir | foreach { $_.Script() | Add-Content -Path "C:\Demos\Scripts\$($_.Parent.Name)_$($_.Schema)_$($_.Name)_$date.sql"}

foreach($table in (dir .)) {
	$table.Script() | Add-Content -Path "C:\Demos\Scripts\$($_.Parent.Name)_$($_.Schema)_$($_.Name)_$date.sql"
}

# Showing System Objects
cd ..\..
# Let's look at the variables
dir Variable:\

# This variable was set when SQLSERVER module was loaded
$SqlServerIncludeSystemObjects = $true

# now look at the directory
dir

# Let's set it back
$SqlServerIncludeSystemObjects = $false

# We can all be Jedi and use the Force switch
dir -Force



