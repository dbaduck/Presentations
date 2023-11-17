$demoserver = "localhost\s2019"
$dbademo = @{
    SqlInstance = "localhost\S2019"
}
$comtools = @{
    SqlInstance = "localhost\s2019"
    Database = "master"
}

# Verb-Noun
Get-ChildItem -Path c:\folder

# $var instead of @var int
# Datatypes are Inferred or explicitly cast
$unknown
$unknown = "This is a variable"
$unknown.GetType()
$unknown = 23
$unknown.GetType()
$unknown = 399393993999399399
$unknown.GetType()
[string]$unknown = 34
$unknown.GetType()

$unknown = $null
$unknown.GetType()
Get-Variable -Name unknown
Remove-Variable -Name unknown
Get-Variable -Name unknown

$var1 = "HELLO"
$VAR2 = "hello"
$var1 -eq $var2

# Case sensitive compare
$var1 -ceq $var2

# $Profile is the location of the startup code to run before continuing
# Global and User based
# [appdomain]::currentdomain.getassemblies() | Sort FullName | Select FullName
$PROFILE
4
$PSHOME
# Transcripting is the best tool in PowerShell for automation
Start-Transcript -Path "C:\demos\Adding PowerShell to your DBA toolbox.txt"

# using dynamic dates with String Replacements
'Single quotes are literal $var1'
"Double quotes are replaceable $var2"

# Let's try the transcript again. This time with a date in the name
# and remember that Transcripts are nestable. So Stop-Transcript for every one.
$tDate = Get-Date -Format "yyyyMMdd_HHmmss"
Start-Transcript -Path "c:\demos\Adding PowerShell to your DBA toolbox $tDate.txt"

# Single Line Comment
<#
Multi Line comment
This is a great feature
#>

# Are you ready to run scripts?
Get-ExecutionPolicy -List

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope ?  # (Process, LocalMachine, CurrentUser) -Force will not prompt you

# TLS 1.2 - This can go in your profile to ensure the protocol is selected for this session
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

# What OS are you running
Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption

# Let's get started.

# Azure Data Studio & VSCode (differences Run buttons)
# PowerShell extension, PowerShell Notebooks, Terminal
Start-Process "C:\Program Files\Azure Data Studio\azuredatastudio.exe"

# Modules - Try not to use auto import by command. Be specific
<#
SQLServer
dbatools
many more you can investigate
#>
Install-Module dbatools -SkipPublisherCheck -Force
Install-Module sqlserver -AllowClobber -Force
# you can also use Update-Module and have multiple modules (dbatools, sqlserver, dbachecks)

Import-Module dbatools
Import-Module sqlserver

# dbatools should be imported first if you need both
# otherwise, just import the ones you want
# sometimes the versions get out of date for SMO and that matters

# Open Terminal and show the assemblies
[appdomain]::currentdomain.getassemblies() | Sort-Object FullName | Select FullName
# OR
Get-MyAssemblies

# SQLServer Module and the Provider

# dbatools module (new one 2.+) has dbatools.library if you don't need the commands
# dbatools module  https://dbatools.io

# SSMS - Start PowerShell
# ensure that you have SQLServer module installed as SQLPS is deprecated and you don't want to use that.
Start-Process "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"

# Start-Process powershell -Verb Runas

# Agent Jobs - NOSQLPS
#NOSQLPS in the PowerShell job step and then you can load any module you want.
# errors can return code 0 so throw or return a different exit code

# Install-Dba Commands
Import-Module dbatools
Get-DbatoolsConfig
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register

# OR
$s = Connect-DbaInstance -SqlInstance $demoserver -TrustServerCertificate

Install-DbaWhoIsActive -SqlInstance $s -Database master
Install-DbaMaintenanceSolution -SqlInstance $demoserver -database DBA -InstallJobs -BackupLocation "D:\SQLBACKUP" -CleanupTime 200
Install-DbaFirstResponderKit @dbademo -Database master
Install-DbaDarlingData @comtools

# etc.
# Start-Process "https://dbatools.io/commands/#Community"

# just how cool is dbatools or sqlserver
Get-Command -Module dbatools -CommandType Function, Cmdlet | Measure-Object

$data = Invoke-DbaQuery @dbademo -Database master -Query "Select Name, database_id from sys.databases" -as DataTable
Write-DbaDbTableData -SqlInstance $demoserver -database DBA -Table sdatabases -Schema dbo -InputObject $data -AutoCreateTable

# dbatools has 2 types of command outputs
# data and smo type
Get-DbaDbFile -SqlInstance $demoserver -Database DBA
$file = Get-DbaDbFile -SqlInstance $demoserver -Database DBA
$file.GetType()

Get-DbaDatabase -SqlInstance localhost\s2019 -Database dba
$db = Get-DbaDatabase -SqlInstance localhost\s2019 -Database dba
$db.GetType()

# Sql Server Provider
Import-Module Sqlserver
Set-Location "SQLSERVER:\SQL\LOCALHOST\S2019"

Get-Item .
$server = Get-Item .

cd Databases\DBA
cd Tables
dir # Get-ChildItem

dir | Remove-Item
dir

cd C:\Demos
# Let's put the table back
$data = Invoke-DbaQuery @dbademo -Database master -Query "Select Name, database_id from sys.databases" -as DataTable
Write-DbaDbTableData -SqlInstance $demoserver -database DBA -Table sdatabases -Schema dbo -InputObject $data -AutoCreateTable

# Add Another one
$data = Invoke-DbaQuery @dbademo -Database master -Query "Select Name, database_id from sys.databases" -as DataTable
Write-DbaDbTableData -SqlInstance $demoserver -database DBA -Table sdatabases2 -Schema dbo -InputObject $data -AutoCreateTable

# go back to the provider
Cd "SQLSERVER:\SQL\LOCALHOST\S2019\Databases\DBA\Tables"
dir

dir | Foreach-Object { $_.Script() | Add-Content -Path "c:\demos\scripts\$($_.Name)_smo.sql" }

# SMO in action
dir
$table = dir | Select -last 1
$table.Drop()

# Much Much More

