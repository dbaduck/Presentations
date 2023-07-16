# Common Knowledge
<#
Verb-Dba  (most commands)
Verb-DbaXXX (for context based items)
Prefixes: 
Rg (Resource Governor), 
Db (Database), 
Ag (Availability Group), 
Pf (Perfmon), 
XE (Extended Events), 
Wsfc (Windows Server Failover Cluster), 
Pbm (Policy Based Management)
#>

# Parameters
<#
-SqlInstance (most always is an Array)
-Database (most always is an Array)
-SqlCredential (can be passed NULL object and still works with Windows Auth)
-EnableException (always off by default, you can enable to be able to get raw exception)
#>

# Data or Object
<#
.GetType()
| Get-Member
#>
Import-Module dbatools -RequiredVersion

# Prepare your environment
$servers = "SQLAG01", "SQLAG02"

$servers = Connect-DbaInstance -SqlInstance $servers -TrustServerCertificate

<#
$servers = Connect-DbaInstance -SqlInstance $servers -TrustServerCertificate
New in 2.0
-TrustServerCertificate
Get-DbatoolsConfig
Set-DbatoolsConfig -Name Import.EncryptionMessageCheck -Value $false -PassThru | Register-DbatoolsConfig
sql.connection.trustcert - $true
#>
$servers
$servers[0].gettype()
$servers[0] | Get-Member
# What type do we get back, Data or Object?
$db = New-DbaDatabase -SqlInstance $servers[0] -Database "FromProd1" -RecoveryModel Simple -Owner "sa"
$servers[0].Databases.Refresh()
$db.GetType()  # Object

# We get back an Object here too.
$db2 = Get-DbaDatabase -SqlInstance $servers[0] -Database "FromProd1"
$db2.GetType() # see the object type
$db2.Drop() # Because we got an object, we can actually manipulate it (drop it)

# Default View
# Is there more to the object?  Ensure that you know so that you can get the most out.
$db = New-DbaDatabase -SqlInstance $servers[0] -Database "FromProd1" -RecoveryModel Simple -Owner "sa"
$servers[0].databases["FromProd1"]  #no default view, so we see everything
$servers[0]  #default view exists and shows us some of the properties.
$db.Drop()

$servers.Name   # see you can see all of them by referencing just the property name
$servers[0].GetType()  # we see an SMO server.
$servers[0] | Get-Member -MemberType Methods

$db = New-DbaDatabase -SqlInstance $servers[0] -Database "FromProd1" -RecoveryModel Simple -Owner "sa"
$file = Get-DbaDbFile -SqlInstance $servers[0] -Database $db.Name
$file.GetType()
$file[0].gettype()
$file | get-member

<#
This is defined in the dbatools.Types in the xml folder of the module
<Type>
<Name>Microsoft.SqlServer.Management.Smo.Database</Name>

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
#>

$servers.Query("SELECT @@servername, name FROM sys.databases", "master")
$servers.Invoke("SELECT @@servername, name FROM sys.databases", "master")

# Surely there is more to this object than just these things
$servers[0].Databases["FromProd1"]

# Splatting
$ProdParam = @{
    SqlInstance = $prod
}

$splatInstance = @{SqlInstance=@("SQLAG01", "SQLAG02");"Database"="FromProd1" }

# Splatting
$splatInstance2 = @{
        SqlInstance = $prod
        Ben = "Bob"
}
    
Connect-DbaInstance @splatInstance2 #-SqlCredential

Connect-DbaInstance @ProdParam #-SqlCredential

# Predefine places combos
$servers = Get-DbaRegisteredServer -Group Production

# Profile & Transcripting
Start-Transcript -Path "c:\Demos\Transcripts\$(get-date -f 'yyyyMMdd_HHmmss').txt"

# Windows Failover Clustering
Get-DbaWsfcAvailableDisk
Get-DbaWsfcCluster -ComputerName $servers[0] # | Format-List *
Get-DbaWsfcDisk
Get-DbaWsfcNetwork -ComputerName $servers[0]
Get-DbaWsfcNetworkInterface
Get-DbaWsfcNode -Computer $servers[0]
Get-DbaWsfcResource -ComputerName $servers[0]
Get-DbaWsfcResourceType
Get-DbaWsfcRole -ComputerName $servers[0]
Get-DbaWsfcSharedVolume



# AG Creation with AG Database
Add-DbaAgDatabase
Add-DbaAgListener
Add-DbaAgReplica
Disable-DbaAgHadr
Enable-DbaAgHadr
Get-DbaAgBackupHistory
Get-DbaAgDatabase
Get-DbaAgHadr
Get-DbaAgListener
Get-DbaAgReplica
Get-DbaAvailabilityGroup
Grant-DbaAgPermission
Invoke-DbaAgFailover
Join-DbaAvailabilityGroup
New-DbaAvailabilityGroup
Remove-DbaAgDatabase
Remove-DbaAgListener
Remove-DbaAgReplica
Remove-DbaAvailabilityGroup
Resume-DbaAgDbDataMovement
Revoke-DbaAgPermission
Set-DbaAgListener
Set-DbaAgReplica
Set-DbaAvailabilityGroup
Suspend-DbaAgDbDataMovement
Sync-DbaAvailabilityGroup
Test-DbaAvailabilityGroup
Enter-PsSession SQLAG01

$servers = "SQLAG01","SQLAG02" 
New-DbaDatabase -SqlInstance $servers[0] -Name "AGDatabase"

New-DbaAvailabilityGroup -Primary $servers[0] -Name DBATOOLSAG -ClusterType Wsfc -AutomatedBackupPreference Secondary -Confirm:$false

Get-DbaAvailabilityGroup -SqlInstance $servers[0] -AvailabilityGroup DBATOOLSAG | 
        Add-DbaAgReplica -SqlInstance $servers[1] -FailoverMode Manual -SeedingMode Manual

Add-DbaAgDatabase -SqlInstance $servers[0] -AvailabilityGroup DBATOOLSAG -Database AGDatabase `
        -Secondary $servers[1] -SeedingMode Manual -SharedPath "\\DC01\SQLBACKUP"  -EnableException

# Did we succeed?
Get-DbaAvailabilityGroup -SqlInstance $servers[0]

Add-DbaAgListener -SqlInstance $servers[0] -AvailabilityGroup DBATOOLSAG -Name AGLISTEN -Port 1433 -IPAddress 192.168.85.233

Invoke-DbaAgFailover -SqlInstance $servers[1] -AvailabilityGroup DBATOOLSAG -Confirm:$false
Invoke-DbaAgFailover -SqlInstance $servers[0]-AvailabilityGroup DBATOOLSAG -Confirm:$false

Remove-DbaAvailabilityGroup -SqlInstance $servers[0] -AvailabilityGroup DBATOOLSAG -Confirm:$false

# Leaves behind EndPoints, let's remove them
Get-DbaEndpoint -SqlInstance $servers -Type DatabaseMirroring | Remove-DbaEndpoint -Confirm:$false

# Remove the database from both instances
Remove-DbaDatabase -SqlInstance $servers -Database "AGDatabase" -Confirm:$false

# DBAtools Config stuff

Get-DbatoolsConfig

set-dbatoolsconfig -fullname commands.get-dbaregserver.defaultcms -value AG01
Get-DbaToolsConfigValue -fullname commands.get-dbaregserver.defaultcms

Get-DbaToolsConfigValue -FullName import.sqlpscheck
Set-DbaToolsConfig -FullName import.sqlpscheck -Value $false

# Persist it across sessions on that computer
Set-DbatoolsConfig -Name Import.SqlpsCheck -Value $false -PassThru | Register-DbatoolsConfig

# Remove all registered config
Unregister-DbatoolsConfig 


# Test in another window.
# Import-Module sqlserver
Import-Module DBAtools

# Community tools installs
Install-DbaDarlingData -SqlInstance $servers -database master
Install-DbaFirstResponderKit  -SqlInstance $servers -database master
Install-DbaMaintenanceSolution -SqlInstance $servers -database master
Install-DbaMultiTooln -SqlInstance $servers -database master
Install-DbaSqlWatch -SqlInstance $servers -database master
Install-DbaWhoIsActive -SqlInstance $servers -database master

# Invoke-ing Community Tools
Install-DbaWhoIsActive -SqlInstance $servers -Database master
Invoke-DbaWhoisActive -SqlInstance $servers

Invoke-DbaDiagnosticQuery -SqlInstance $servers[0] -UseSelectionHelper

$var = Invoke-DbaDiagnosticQuery -SqlInstance $servers[0] -UseSelectionHelper 
$var | Export-DbaDiagnosticQuery -ConvertTo Excel -Path "C:\Demos"
$var.Result

#  Migration
Copy-DbaAgentAlert
Copy-DbaAgentJobCategory
Copy-DbaAgentJob -Source $servers[0] -Destination $servers[1]
Copy-DbaAgentOperator
Copy-DbaAgentProxy
Copy-DbaAgentServer
Copy-DbaAgentSchedule
Copy-DbaBackupDevice
Copy-DbaCredential
Copy-DbaCustomError
Copy-DbaDatabase
Copy-DbaDataCollector
Copy-DbaDbAssembly
Copy-DbaDbMail
Copy-DbaDbQueryStoreOption
Copy-DbaEndpoint
Copy-DbaInstanceAudit
Copy-DbaInstanceAuditSpecification
Copy-DbaInstanceTrigger
Copy-DbaLinkedServer
Copy-DbaLogin
Copy-DbaPolicyManagement
Copy-DbaRegServer
Copy-DbaResourceGovernor
Copy-DbaSpConfigure
Copy-DbaStartupProcedure
Copy-DbaSysDbUserObject
Copy-DbaXESession

Start-DbaMigration -Source $servers[0] -Destination $servers[1] -BackupRestore -SharedPath "\\DC01\SQLBACKUP" 

Copy-DbaAgentJob -Source $servers[0] -Destination $servers[1]
Copy-dbalogin -source $servers[0] -Destination $servers[1] -Login NewLogin -force
get-dbatoolslog -error 

# Backup and Restore

Backup-DbaDatabase
$model = Get-DbaDbRecoveryModel -Sqlinstance SQL01 -Database DBLARGE

Format-DbaBackupInformation
Get-DbaDbBackupHistory -sqlinstance $servers[0] -lastfull | Restore-DbaDatabase -sqlinstance sql01 -ReuseSourceFolderStructure -TrustDbBackupHistory -whatif
Get-DbaDbBackupHistory -sqlinstance $servers[0] -lastfull | Restore-DbaDatabase -sqlinstance sql01 -ReuseSourceFolderStructure -TrustDbBackupHistory  -OutputScriptOnly



Get-DbaBackupInformation

Get-DbaDbExtentDiff
Get-DbaDbRestoreHistory
Get-DbaLastBackup
Invoke-DbaAdvancedRestore
Measure-DbaBackupThroughput -sqlinstance ag01
Read-DbaBackupHeader
Remove-DbaBackup
Remove-DbaDbBackupRestoreHistory
Restore-DbaDatabase
Select-DbaBackupInformation
Test-DbaBackupInformation
Test-DbaDbRecoveryModel
Test-DbaLastBackup

get-childitem -path \\dc01\sqlbackup -filter *.trn | Where LastwriteTime -gt (Get-Date).AddHours(-12) | Restore-DbaDatabase
Get-ChildItem -path \\dc01\sqlbackup -filter *.trn | restore-dbadatabase -sqlinstance sql01 

# WhatIf
dir \\dc01\sqlbackup | Remove-Item -whatif

# Login Management
Add-DbaDbRoleMember
Add-DbaServerRoleMember -SqlInstance $servers -ServerRole "sysadmin" -Login "NewLogin" -Confirm:$false
Get-DbaDbOrphanUser -SqlInstance $servers -Database FromProd1
Get-DbaDbRole
Get-DbaDbRoleMember
Get-DbaDbUser
Get-DbaLogin
Get-DbaServerRole
Get-DbaServerRoleMember -SqlInstance $servers -ServerRole "sysadmin" | Select-Object SqlInstance, Role, Name
New-DbaDbRole
New-DbaDbUser -SqlInstance $servers[0] -Database "FromProd1" -Login "NewLogin" -Username "NewLogin"
$cred = Get-Credential
New-DbaLogin -SqlInstance $servers[0] -Login "NewLogin" -SecurePassword $cred.Password 
New-DbaLogin -SqlInstance $servers[0] -Login "NewLogin" -SecurePassword $cred.Password 
New-DbaServerRole
Remove-DbaDbOrphanUser
Remove-DbaDbRole
Remove-DbaDbRoleMember
Remove-DbaDbUser
Remove-DbaLogin
Remove-DbaServerRole
Remove-DbaServerRoleMember -SqlInstance $servers -ServerRole "sysadmin" -Login "NewLogin" -Confirm:$false
Rename-DbaLogin
Repair-DbaDbOrphanUser -sqlinstance $servers[0] -database FromProd1 
Copy-DbaLogin -Source $servers[0] -destination $servers[1] -login TestLogin
Set-DbaLogin
Sync-DbaLoginPermission
Test-DbaLoginPassword
Test-DbaWindowsLogin
Watch-DbaDbLogin


Invoke-Command -ComputerName $servers -ScriptBlock { Install-Module dbatools -confirm:$false -force }


# Databases
Get-DbaDatabase
Get-DbaDbAssembly
Get-DbaDbCertificate -SqlInstance $servers -ExcludeDatabase "model", "msdb", "tempdb" | Where-Object Name -notlike "#*"
Get-DbaDbCheckConstraint
Get-DbaDbCompatibility -Sqlinstance $servers | Where Database -notin @("master","model","msdb","tempdb") | Export-csv -path c:\demos\databases.csv -notypeinformation

$dbs = import-csv -path c:\demos\databases.csv

foreach($db in $dbs) {
        Set-DbaDbCompatibility -SqlInstance $db.ComputerName -Database $db.Database -Compatibility $db.Compatibility
}

$dbs | Write-DbaDbTableData -Sqlinstance $servers[0] -database DBA -schema dbo -table DatabaseSettings -AutoCreateTable
$rows = Invoke-dbaquery -sqlinstance sql01 -database DB01 -Query "SELECT * FROM dbo.DatabaseSettings" -As 

$rows 
Get-DbaDbFeatureUsage -SqlInstance $servers[0]
Get-DbaDbIdentity -SqlInstance $servers -Database FromProd1 -Table dbo.TestTable
Get-DbaDbMemoryUsage -SqlInstance $prod
Get-DbaDbMirrorMonitor
Get-DbaDbObjectTrigger
Get-DbaDbPageInfo
Get-DbaDbPartitionFunction
Get-DbaDbPartitionScheme
Get-DbaDbQueryStoreOption -SqlInstance $prod
Get-DbaDbSchema
Get-DbaDbSharePoint
Get-DbaDbSpace
Get-DbaDbState -SqlInstance $servers 
Get-DbaDbStoredProcedure
Get-DbaDbSynonym
Get-DbaDbTable
Get-DbaDbTrigger
Get-DbaDbUdf
Get-DbaDbUserDefinedTableType
Get-DbaDbView
Get-DbaHelpIndex
Get-DbaSuspectPage
Invoke-DbaDbClone
Invoke-DbaDbShrink
Invoke-DbaDbUpgrade
New-DbaDatabase
New-DbaDbSchema
New-DbaDbSynonym
Remove-DbaDatabase
Remove-DbaDatabaseSafely
Remove-DbaDbSchema
Remove-DbaDbSynonym
Remove-DbaDbTable
Remove-DbaDbUdf
Remove-DbaDbView
Rename-DbaDatabase
Set-DbaDbCompatibility
Set-DbaDbIdentity
Set-DbaDbOwner -SqlInstance $servers[0] -Database FromProd1 -TargetLogin "sa"
Set-DbaDbQueryStoreOption
Set-DbaDbRecoveryModel
Set-DbaDbSchema
Set-DbaDbState
Show-DbaDbList -SqlInstance $servers[0]
Test-DbaConnectionAuthScheme
Test-DbaDbCollation
Test-DbaDbCompatibility
Test-DbaDbOwner -sqlinstance $servers -database FromProd1
Test-DbaDbQueryStore -sqlinstance $servers -database FromProd1
Test-DbaOptimizeForAdHoc -sqlinstance $prod

Get-DbaDiskspace $prod
# Filesystem and Storage
Expand-DbaDbLogFile -SqlInstance $servers[0] -Database FromProd1 -TargetLogSize 1000 
Get-DbaDbFile`
Get-DbaDbFileGroup
Get-DbaDbFileGrowth
Get-DbaDbFileMapping
Get-DbaDbLogSpace -SqlInstance $servers[0] -Database "FromProd1"
Get-DbaDefaultPath
Get-DbaDiskSpace
Get-DbaFile
Move-DbaDbFile
New-DbaDbFileGroup
New-DbaDirectory
Remove-DbaDbFileGroup
Set-DbaDbFileGroup
Set-DbaDbFileGrowth
Set-DbaDefaultPath
Show-DbaInstanceFileSystem
Test-DbaDiskAlignment
Test-DbaDiskAllocation
Test-DbaPath

# Services
Get-DbaService -computername ag01
Get-DbaDbServiceBrokerService
Restart-DbaService
Start-DbaService
Stop-DbaService
Update-DbaServiceAccount


# Utilities
ConvertTo-DbaTimeline
Get-DbaBuild
Get-DbaDependency
Get-DbaInstanceInstallDate
Get-DbaLastGoodCheckDb
Get-DbaPowerPlan -computername ag01
Get-DbaProductKey
Get-DbaSchemaChangeHistory
Get-DbaUptime -sqlinstance ag01
Import-DbaCsv
Invoke-DbaBalanceDataFiles
Invoke-DbaDbDecryptObject
Invoke-DbaQuery
New-DbaSqlParameter
Join-DbaPath
Read-DbaTransactionLog
Repair-DbaInstanceName
Reset-DbaAdmin
Resolve-DbaPath
Select-DbaObject
Set-DbaMaxDop
Set-DbaPowerPlan -computername $servers[0] -PowerPlan 'High Performance'
Test-DbaBuild
Test-DbaInstanceName
Test-DbaMaxDop
Test-DbaPowerPlan
Update-DbaBuildReference4

# Connections

Connect-DbaInstance
Disconnect-DbaInstance
Get-DbaConnection
Test-DbaConnection

# Network
Get-DbaTcpPort -sqlinstance $rrod[0]
Set-DbaTcpPort

# General
Add-DbaExtendedProperty
Get-DbaExtendedProperty
Set-DbaExtendedProperty
Remove-DbaExtendedProperty

Add-DbaExtendedProperty -SqlInstance $servers[0] -Database db1 -Name version -Value "1.0.0"

Get-DbaExtendedProperty -sqlinstance $servers[0] -database DB1 

Get-DbaExtendedProperty -sqlinstance $servers[0] -database DB1  | Remove-DbaExtendedProperty 

#Export

Export-DbaCredential
Export-DbaDacPackage
Export-DbaDbRole
Export-DbaDbTableData
Export-DbaInstance
Export-DbaLinkedServer *
Export-DbaLogin -sqlinstance sql01 -path c:\demos
Export-DbaRegServer -sqlinstance $servers[0] -path c:\demos
Export-DbaRepServerSetting
Export-DbaScript
Export-DbaServerRole
Export-DbaSpConfigure
Export-DbaSysDbUserObject
Export-DbaUser


# SQL Agent

Get-DbaAgentAlert
Get-DbaAgentAlertCategory
Get-DbaAgentJob
Get-DbaAgentJobCategory
Get-DbaAgentJobHistory
Get-DbaAgentJobOutputFile
Get-DbaAgentJobStep
Get-DbaAgentLog
Get-DbaAgentOperator
Get-DbaAgentProxy
Get-DbaAgentSchedule
Get-DbaAgentServer
Get-DbaRunningJob
New-DbaAgentAlertCategory
New-DbaAgentJob
New-DbaAgentJobCategory
New-DbaAgentJobStep
New-DbaAgentOperator
New-DbaAgentProxy
New-DbaAgentSchedule
Remove-DbaAgentAlert
Remove-DbaAgentAlertCategory
Remove-DbaAgentJob
Remove-DbaAgentJobCategory
Remove-DbaAgentJobStep
Remove-DbaAgentOperator
Remove-DbaAgentProxy
Remove-DbaAgentSchedule
Set-DbaAgentAlert
Set-DbaAgentJob
Set-DbaAgentJobCategory
Set-DbaAgentJobOutputFile
Set-DbaAgentJobOwner
Set-DbaAgentJobStep
Set-DbaAgentOperator
Set-DbaAgentSchedule
Set-DbaAgentServer
Start-DbaAgentJob
Stop-DbaAgentJob
Test-DbaAgentJobOwner
