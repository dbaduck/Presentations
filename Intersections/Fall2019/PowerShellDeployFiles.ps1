<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.163
	 Created on:   	10/4/2019 9:13 AM
	 Created by:   	BenMiller(DBAduck)
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module SqlServer

$ServerInstance = "localhost"
$Database = "DogFoodConDB"

# Deploy Files
$DeployPath = "D:\Deploy"

$files = Get-ChildItem -Path $DeployPath -Filter *.sql -File | Sort-Object Name

foreach ($file in $files)
{
	Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $file.FullName -QueryTimeout 0
}

### Or Create a Function to allow you to deploy them a section at a time
function Invoke-DeployFiles
{
	param (
		$DeployPath,
		$Prefix
	)
	
	$files = Get-ChildItem -Path $DeployPath -Filter "$($Prefix)*.sql" -File | Sort-Object Name
	
	foreach ($file in $files)
	{
		Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $file.FullName -QueryTimeout 0
	}
	
}

Invoke-DeployFiles -DeployPath "D:\Deploy" -Prefix "01"
Invoke-DeployFiles -DeployPath "D:\Deploy" -Prefix "02"
Invoke-DeployFiles -DeployPath "D:\Deploy" -Prefix "03"
Invoke-DeployFiles -DeployPath "D:\Deploy" -Prefix "05"
Invoke-DeployFiles -DeployPath "D:\Deploy" -Prefix "99"
