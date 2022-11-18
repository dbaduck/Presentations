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
Import-Module dbatools

# Prepare your environment
#$dev = "SQLAG01", "dev-sql2\devsql2"
$prod = "SQLAG01", "SQLAG02"

$servers = Connect-DbaInstance -SqlInstance $prod

$servers
$servers[0].gettype()

# Default View
Is there more to the object?  Ensure that you know so that you can get the most out.
$servers[0].databases["FromProd1"]

$servers.Name
$servers[0].GetType()
$servers[0] | Get-Member -MemberType Methods

Connect-DbaInstance -SqlInstance $prod[0]

$file = get-dbadbfile -sqlinstance $prod[0] -database "FromProd1"
$file.GetType()
$file[0].gettype()
$file | get-member

$servers[0] | get-member
$servers[0].Query("SELECT name FROM sys.databases", "master")
$servers.Query("SELECT @@servername, name FROM sys.databases", "master")
$servers.Invoke("SELECT @@servername, name FROM sys.databases", "master")

$servers[0].Databases["FromProd1"]
# Surely there is more to this object than just these things

$ProdInstances = $prod
# Splatting
$ProdParam = @{
    SqlInstance = $ProdInstances
}

$splatInstance = @{SqlInstance=@("SQLAG01", "SQLAG02");"Database"="FromProd1" }

# Splatting
$splatInstance2 = @{
        SqlInstance = $ProdInstances
        Ben = "Bob"
}

    
Connect-DbaInstance @splatInstance2 #-SqlCredential

Connect-DbaInstance @ProdParam #-SqlCredential

function Get-FLower {
        [CmdLetBinding()]
        param (
                $Bob
        )

        $Bob
}

Get-Flower -Bob "Ben Miller"
Get-Flower "Ben Miller"

Get-Flower @splatInstance

# Predefine places combos

# Profile & Transcripting


# Windows Failover Clustering
Get-DbaWsfcAvailableDisk
Get-DbaWsfcCluster -ComputerName $prod[0] # | Format-List *
Get-DbaWsfcDisk
Get-DbaWsfcNetwork -ComputerName $prod[0]
Get-DbaWsfcNetworkInterface
Get-DbaWsfcNode -Computer $prod[0]
Get-DbaWsfcResource -ComputerName $prod[0]
Get-DbaWsfcResourceType
Get-DbaWsfcRole -ComputerName $prod[0]
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

$prod = "SQLAG01","SQLAG02" 
New-DbaDatabase -SqlInstance $prod[0] -Name "AGDatabase"

New-DbaAvailabilityGroup -Primary $prod[0] -Name DBATOOLSAG -ClusterType Wsfc -AutomatedBackupPreference Secondary -Confirm:$false

Get-DbaAvailabilityGroup -SqlInstance $prod[0] -AvailabilityGroup DBATOOLSAG | 
        Add-DbaAgReplica -SqlInstance $prod[1] -FailoverMode Manual -SeedingMode Manual

Add-DbaAgDatabase -SqlInstance $prod[0] -AvailabilityGroup DBATOOLSAG -Database AGDatabase `
        -Secondary $prod[1] -SeedingMode Manual -SharedPath "\\DC01\SQLBACKUP"  -EnableException



# Did we succeed?
Get-DbaAvailabilityGroup -SqlInstance $prod[0]

Add-DbaAgListener -SqlInstance $prod[0] -AvailabilityGroup DBATOOLSAG -Name AGLISTEN -Port 1433 -IPAddress 192.168.85.233

Invoke-DbaAgFailover -SqlInstance $prod[1] -AvailabilityGroup DBATOOLSAG -Confirm:$false
Invoke-DbaAgFailover -SqlInstance $prod[0]-AvailabilityGroup DBATOOLSAG -Confirm:$false

Remove-DbaAvailabilityGroup -SqlInstance $prod[0] -AvailabilityGroup DBATOOLSAG -Confirm:$false

# Leaves behind EndPoints, let's remove them
Get-DbaEndpoint -SqlInstance $prod -Type DatabaseMirroring | Remove-DbaEndpoint -Confirm:$false

Remove-DbaDatabase -SqlInstance $prod -Database "AGDatabase" -Confirm:$false

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
Import-Module sqlserver
Import-Module DBAtools



# Community tools installs
Install-DbaDarlingData -SqlInstance $prod -database master
Install-DbaFirstResponderKit  -SqlInstance $prod -database master
Install-DbaMaintenanceSolution -SqlInstance $prod -database master
Install-DbaMultiTooln -SqlInstance $prod -database master
Install-DbaSqlWatch -SqlInstance $prod -database master
Install-DbaWhoIsActive -SqlInstance $prod -database master

# Invoke-ing Community Tools
Install-DbaWhoIsActive -SqlInstance $prod -Database master
Invoke-DbaWhoisActive -SqlInstance $prod

Install-DbaWhoIsActive -SqlInstance $dev -Database master
Invoke-DbaWhoisActive -SqlInstance $dev

Invoke-DbaDiagnosticQuery -SqlInstance $prod[0] -UseSelectionHelper

$var = Invoke-DbaDiagnosticQuery -SqlInstance $prod[0] -UseSelectionHelper 
$var | Export-DbaDiagnosticQuery -ConvertTo Excel -Path "C:\Demos"
$var.Result

#  Migration
Copy-DbaAgentAlert
Copy-DbaAgentJobCategory
Copy-DbaAgentJob
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

Start-DbaMigration -Source $prod[0] -Destination $prod[1] -BackupRestore -SharedPath "\\SQL01\SQLBACKUP2" 

copy-dbaagentjob -source $prod[0] -destination $prod[1] -force

get-dbatoolslog -error 

# Backup and Restore

Backup-DbaDatabase
$model = Get-DbaDbRecoveryModel -Sqlinstance SQL01 -Database DBLARGE

Format-DbaBackupInformation
Get-DbaDbBackupHistory -sqlinstance $prod[0] -lastfull | Restore-DbaDatabase -sqlinstance sql01 -ReuseSourceFolderStructure -TrustDbBackupHistory -whatif
Get-DbaDbBackupHistory -sqlinstance $prod[0] -lastfull | Restore-DbaDatabase -sqlinstance sql01 -ReuseSourceFolderStructure -TrustDbBackupHistory  -OutputScriptOnly



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

get-childitem -path \\sql01\sqlbackup -filter *.trn | Where LastwriteTime -gt (Get-Date).AddHours(-12) | Restore-DbaDatabase
Get-ChildItem -path \\sql01\sqlbackup -filter *.trn | restore-dbadatabase -sqlinstance sql01 

# WhatIf
dir \\sql01\sqlbackup2 | Remove-Item -whatif

# Login Management
Add-DbaDbRoleMember
Add-DbaServerRoleMember
Get-DbaDbOrphanUser -sqlinstance sql02 # -Database DBLARGE
Get-DbaDbRole
Get-DbaDbRoleMember
Get-DbaDbUser
Get-DbaLogin
Get-DbaServerRole
Get-DbaServerRoleMember
New-DbaDbRole
New-DbaDbUser
New-DbaLogin
New-DbaServerRole
Remove-DbaDbOrphanUser
Remove-DbaDbRole
Remove-DbaDbRoleMember
Remove-DbaDbUser
Remove-DbaLogin
Remove-DbaServerRole
Remove-DbaServerRoleMember
Rename-DbaLogin
Repair-DbaDbOrphanUser -sqlinstance $prod[1] -database DBLARGE
Copy-DbaLogin -Source $prod[0] -destination $prod[1] -login TestLogin
Set-DbaLogin
Sync-DbaLoginPermission
Test-DbaLoginPassword
Test-DbaWindowsLogin
Watch-DbaDbLogin


Invoke-Command -ComputerName $prod -ScriptBlock { Install-Module dbatools -confirm:$false -force }


# Databases
Get-DbaDatabase
Get-DbaDbAssembly
Get-DbaDbCertificate
Get-DbaDbCheckConstraint
Get-DbaDbCompatibility -Sqlinstance $prod | Where Database -notin @("master","model","msdb","tempdb") | Export-csv -path c:\demos\databases.csv -notypeinformation

$dbs = import-csv -path c:\demos\databases.csv

foreach($db in $dbs) {
        Set-DbaDbCompatibility -SqlInstance $db.ComputerName -Database $db.Database -Compatibility $db.Compatibility
}

$dbs | Write-DbaDbTableData -Sqlinstance $prod[0] -database DBA -schema dbo -table DatabaseSettings -AutoCreateTable
$rows = Invoke-dbaquery -sqlinstance sql01 -database DB01 -Query "SELECT * FROM dbo.DatabaseSettings" -As DataTable

$rows 
Get-DbaDbFeatureUsage
Get-DbaDbIdentity
Get-DbaDbMemoryUsage
Get-DbaDbMirrorMonitor
Get-DbaDbObjectTrigger
Get-DbaDbPageInfo
Get-DbaDbPartitionFunction
Get-DbaDbPartitionScheme
Get-DbaDbQueryStoreOption
Get-DbaDbSchema
Get-DbaDbSharePoint
Get-DbaDbSpace
Get-DbaDbState
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
Set-DbaDbOwner
Set-DbaDbQueryStoreOption
Set-DbaDbRecoveryModel
Set-DbaDbSchema
Set-DbaDbState
Show-DbaDbList
Test-DbaConnectionAuthScheme
Test-DbaDbCollation
Test-DbaDbCompatibility
Test-DbaDbOwner -sqlinstance sql01 -database db01
Test-DbaDbQueryStore -sqlinstance sql01 -database db01
Test-DbaOptimizeForAdHoc -sqlinstance sql01


$Name = "Ben Miller"

"My name is $servers"
'My name is $Name'
$dbs
"My name is $($dbs.Database -join ',')"
$var = @"
This is my string
and I love it $($dbs.Database -join ',')
"@

$var
Get-DbaDiskspace
# Filesystem and Storage
Expand-DbaDbLogFile
Get-DbaDbFile`
Get-DbaDbFileGroup
Get-DbaDbFileGrowth
Get-DbaDbFileMapping
Get-DbaDbLogSpace
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
Set-DbaPowerPlan -computername $prod[0] -PowerPlan 'High Performance'
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

Add-DbaExtendedProperty -SqlInstance $prod[0] -Database db1 -Name version -Value "1.0.0"

Get-DbaExtendedProperty -sqlinstance $prod[0] -database DB1 

Get-DbaExtendedProperty -sqlinstance $prod[0] -database DB1  | Remove-DbaExtendedProperty 

#Export

Export-DbaCredential
Export-DbaDacPackage
Export-DbaDbRole
Export-DbaDbTableData
Export-DbaInstance
Export-DbaLinkedServer *
Export-DbaLogin -sqlinstance sql01 -path c:\demos
Export-DbaRegServer -sqlinstance $prod[0] -path c:\demos
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

