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

function Expand-DbDataFile
{
	param (
		$ServerInstance,
		$Database,
		[int]$FileId,
		[string]$FileName,
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
		$dbfile = foreach ($filegroup in $db.FileGroups)
		{
			foreach ($file in $filegroup.Files)
			{
				if($fileId) {
					if ($file.Id -eq $fileId)
					{
						$file
						break
					}
				}
				elseif($fileName) {
					if($file.FileName -eq $FileName) {
						$file
						break
					}
				}
				else {
					break
				}
			}	
		}
		if ($dbfile)
		{
			$AmountToAddMB *= 1KB
			$dbfile.Size += $AmountToAddMB
			$dbfile.Alter()
		}
		else
		{
			Write-Error "Did not find file id $FileId in database $Database"	
		}
	}
}
