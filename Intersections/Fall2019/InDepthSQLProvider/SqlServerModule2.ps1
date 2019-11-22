$ServerInstance = "WIN2019A"

# Getting modules loaded and which versions exist on the PSGallery
Get-Module
Find-Module SqlServer

# Getting the SQLServer Module to other places
Save-Module -Name sqlserver -Path C:\temp\modules
Install-Module SqlServer -AllowClobber
Update-Module SqlServer

# Then xcopy deployment to other places
# This can be used on any module (that I know of) in PSGallery

# Providers
Get-PSDrive

# Notice that there are many other than C: D:, etc.
# Notice the Provider name

Import-Module SqlServer

# Now look at the Get-PSDrive
Get-PSDdrive

# Authentication with Providers
# SQL Server is by default Windows Authentication
# but.... It can use SQL Server Authentication
$cred = Get-Credential

New-PSDrive -Name BEN -PSProvider SqlServer -Root "SQLSERVER:\SQL\WIN2019A\DEFAULT"
New-PSDrive -Name SQLAUTH -PSProvider SqlServer -Root "SQLSERVER:\SQL\WIN2019A\DEFAULT" -Credential $cred

# Look at the difference
Get-PSDrive

# The key to the New-PSDrive is the level at which you get to in the Root.
# You need to be at least at the Instance level or there is no auth mechanism
# But you can go further
New-PSDrive -Name WDB -PSProvider SqlServer -Root "SQLSERVER:\SQL\$ServerInstance\DEFAULT\Databases"

Get-PSDrive

cd WDB:
dir

# navigation of Paths to begin
SQLSERVER:
dir

# Path structure
# sqlserver:\sql\machine\instance\databases\dbname\Tables\schema.tablename ...
# Means that you can use it against other servers as well.

# SQLRegistration
cd SQLRegistration
dir
# This is not as dynamic as you would like, you need to reload the provider
# You can do a New-Item for this particular thing
New-Item -ItemType Registration -Name WIN2019A -Value "Data Source=WIN2019A;Integrated Security=true"
# New-Item -ItemType Registration -Name WIN2019A -Value "Data Source=WIN2019A;Integrated Security=SSPI"

# Get-Childitem (or dir)
# cd (Set-Location)
cd SQLSERVER:\SQL\WIN2019A\DEFAULT
dir
cd Databases
dir
# what is missing?
# Viewing System Objects (variable, -force)
# Notice the View
# psformattypes is in play. These can be loaded during importing of a module
# SQLServer module has these for the SMO objects
dir -force

# How do I get 1 database
Get-Item .
Get-Item A

# SMO objects from the Provider
$db = Get-Item .
$db.Pageverify
$db.PageVerify = "NONE"
$db.Alter()

# Object Path
$db = Get-Item .
$db.PSPath

$db.Urn
Convert-UrnToPath -Urn $db.Urn
cd (Convert-UrnToPath -Urn $db.Urn)

# Provider Context
Backup-SqlDatabase -Database A

# Pipelines
dir | Backup-SqlDatabase -CompressionOption on

# Save off all the scripts
cd sqlserver:\sql\win2019a\default\Databases\A
dir Tables | Foreach-Object { $_.Script() | Add-Content "c:\temp\tables\$($_.Parent.Name)_$($_.Schema)_$($_.Name).sql" }

# Using PowerShell commands Remove-Item
cd sqlserver:\sql\win2019a\default\Databases\A
dir Tables | Remove-Item -whatif
dir Tables | Remove-Item 

# Put them back and use Provider Context
cd sqlserver:\sql\win2019a\default\Databases\A
dir c:\temp\tables\*.sql | foreach-object { Invoke-Sqlcmd -InputFile $_.FullName }

# Urns
# Get an item in SMO and convert the URN to a path
cd SQLSERVER:\SQL\WIN2019A\default\databases\A\Tables\dbo.Table1
$table = Get-Item .
Convert-UrnToPath -urn $table.Urn


