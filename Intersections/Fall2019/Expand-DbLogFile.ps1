<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
	 Created on:   	5/15/2018 4:04 PM
	 Created by:   	bmiller
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module SqlServer

function Expand-DbLogFile
{
	param (
		$ServerInstance,
		$Database,
		[int]$FileId = 2,
		[int]$AmountToAddMB
	)
	
	begin
	{
		$smo = "Microsoft.SqlServer.Management.Smo"
		$server = New-Object -TypeName "$smo.Server" -ArgumentList $ServerInstance
		
	}
	
	process
	{
		if ($server.Databases[$Database] -eq $null)
		{
			Write-Error "Database $Database does not exist in $($server.Name)"
			return
		}
		$db = $server.Databases[$Database]
		$logfile = $db.LogFiles | Where Id -eq $FileId
		if ($logfile)
		{
			$AmountToAddMB *= 1KB
			$logfile.Size += $AmountToAddMB
			$logfile.Alter()
		}
		else
		{
			Write-Error "Did not find file id $FileId in database $Database"	
		}
	}
}
