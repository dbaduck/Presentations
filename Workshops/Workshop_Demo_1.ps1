# Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
[assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

dir C:\windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo

Set-ExecutionPolicy RemoteSigned # -Scope CurrentUser
Get-ExecutionPolicy
Import-Module dbatools

function Get-MyOsAssemblies
{
	[Appdomain]::CurrentDomain.GetAssemblies() | select FullName | Sort FullName
}

Get-MyOsAssemblies

$server = Connect-DbaInstance WIN19B -StatementTimeout 0 #-Credential (get-credential)
$server.ConnectionContext.StatementTimeout

$server = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server -ArgumentList WIN19B

$smo = "Microsoft.SqlServer.Management.Smo"

$server = New-Object -TypeName "$smo.Server" -ArgumentList WIN19B
$server.BackupDirectory
$server.ConnectionContext.StatementTimeout = 700


# $server = New-Object Microsoft.SqlServer.Management.SMO.Server ("WIN19B")

$cred = Get-Credential
$server.ConnectionContext.LoginSecure = $false
#$server.ConnectionContext.set_Login("sa")
$server.ConnectionContext.Login = $cred.UserName  #"sa"
$server.ConnectionContext.Password = "Password1"

$server.ConnectionContext.Disconnect()
$server.ConnectionContext.Login = $cred.UserName
$server.ConnectionContext.SecurePassword = $cred.Password


#$server.ConnectionContext.set_Password("Password1")

$server.ConnectionContext | Get-Member -MemberType Method
$server.ConnectionContext | gm

$server.ConnectionContext.Authentication
$server | gm
$server.NamedPipesEnabled
$server.TcpEnabled

$server.NumberOfLogFiles 
$server.NumberOfLogFiles = 15
$server.Alter()

$server.Information.Edition
$server.Information.EngineEdition

$server.Information.ErrorLogPath
$server.Information.HostPlatform

$server.Information.IsClustered
$server.Information.MasterDBPath
$server.Information.MasterDBPath.StartsWith("C:")
$server.Information.Version
$server.Information.VersionMajor -eq 14

$server.Configuration | gm
$server.Configuration.OptimizeAdhocWorkloads|gm
$server.Configuration.OptimizeAdhocWorkloads.ConfigValue = 0
$server.Alter()

$server.Configuration.Alter()

$server.Configuration.MaxServerMemory
$server.Configuration.MaxServerMemory.RunValue -eq $server.Configuration.MaxServerMemory.Maximum
$server.Configuration.OptimizeAdhocWorkloads
$server.Configuration.OptimizeAdhocWorkloads | gm
$server.Configuration.OptimizeAdhocWorkloads.ConfigValue = 1
$server.Configuration.Alter()

$server.Version

$server | Get-Member

$server.JobServer

$server.Logins

$server.Roles

$files = New-Object -TypeName System.Collections.Specialized.StringCollection
$files.Add('C:\SQLDATA\DEMODB.mdf')
$files.Add('C:\SQLDATA\DEMODB_log.ldf')

$server.AttachDatabase("DEMODB", @('C:\SQLDATA\DEMODB.mdf', 'C:\SQLDATA\DEMODB_log.ldf'))

$error[0].Exception
$error[0].Exception.InnerException
$error[0].Exception.InnerException.InnerException


$server.Databases.Refresh()


<#
Backing up databases
#>
#Backing up and restoring a Database from PowerShell  
  
#Connect to the local, default instance of SQL Server.  

$smo = "Microsoft.SqlServer.Management.Smo"

#Get a server object which corresponds to the default instance  
$srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server -ArgumentList WIN19B
$srv = New-Object -TypeName "$smo.Server" -ArgumentList WIN19B

$srv.ConnectionContext.LoginSecure = $false
$srv.ConnectionContext.Login = "sa"
$srv.ConnectionContext.Password = "Password1"

$srv.ConnectionContext.StatementTimeout = 0

$srv.Databases
#Reference the AdventureWorks database.  
$db = $srv.Databases["DEMODB"]  
$srv.Databases[0].Name
  
#Store the current recovery model in a variable.  
$recoverymod = $db.DatabaseOptions.RecoveryModel  
# or
$recoverymod = $db.RecoveryModel
  
#Create a Backup object  
$bk = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Backup  
$bk = New-Object -TypeName "$smo.Backup"  

#set to backup the database  
$bk.Action = [Microsoft.SqlServer.Management.SMO.BackupActionType]::Database
$bk.Action = "Database"

#Set back up properties  
$bk.BackupSetDescription = "Full backup of DEMODB"  
$bk.BackupSetName = "DEMODB Backup"  
$bk.Database = "DEMODB"  
  
#Declare a BackupDeviceItem by supplying the backup device file name in the constructor,   
#and the type of device is a file.  
$dt = [Microsoft.SqlServer.Management.SMO.DeviceType]::File 
$bdi = New-Object -TypeName Microsoft.SqlServer.Management.SMO.BackupDeviceItem `
-argumentlist "Test_FullBackup1", $dt  
  
#Add the device to the Backup object.  
$bk.Devices.Add($bdi)  
  
#Set the Incremental property to False to specify that this is a full database backup.  
$bk.Incremental = $false  
  
#Set the expiration date.  
$bk.ExpirationDate = get-date "10/05/2020"  
  
#Specify that the log must be truncated after the backup is complete.  
# $bk.LogTruncation = [Microsoft.SqlServer.Management.SMO.BackupTruncateLogType]::Truncate  
  
#Run SqlBackup to perform the full database backup on the instance of SQL Server.  
$bk.SqlBackup($srv)  

#Inform the user that the backup has been completed.  
"Full Backup complete."

$srv.ConnectionContext.SqlExecutionModes = "CaptureSql"
$srv.Configuration.MaxServerMemory.ConfigValue = 2048
$srv.Configuration.Alter()
$srv.ConnectionContext.CapturedSql

$srv.ConnectionContext.SqlExecutionModes = "ExecuteSql"

$db.RecoveryModel = "Simple"
$db.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately)

$bob = 1
$bill = "2"

$bob + $bill
$bill + $bob

$bob + "A"


