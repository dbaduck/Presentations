<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	10/7/2018 12:23 PM
	 Created by:   	Ben Miller
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Gets the information that you see in the Shrink Files Dialog.

#>


function Get-DbaShrinkInfo
{
	[CmdletBinding()]
	param (
		$ServerInstance,
		$Database
	)
	
	$smo = "Microsoft.SqlServer.Management.Smo"
	
	$server = New-Object -TypeName "$smo.Server" -Args $ServerInstance
	
	$db = $server.Databases[$Database]
	if ($db)
	{
		$list = [System.Collections.ArrayList]@()
		
		foreach ($fg in $db.FileGroups)
		{
			foreach ($file in ($fg.Files | Sort Id))
			{
				$obj = "" | Select FileGroup, FileId, Name, FileName, SizeMB, UsedSpaceMB, FreeSpaceMB, FreePercent, GrowthType, GrowthMB
				$obj.FileGroup = $fg.Name
				$obj.FileId = $file.Id
				$obj.Name = $file.Name
				$obj.FileName = $file.FileName
				$obj.SizeMB = [math]::Round($file.Size/1KB, 2)
				$obj.UsedSpaceMB = [math]::Round($file.UsedSpace/1KB, 2)
				$obj.FreeSpaceMB = [math]::Round(($file.Size - $file.UsedSpace)/1KB, 2)
				$obj.FreePercent = [math]::Round((($file.Size - $file.UsedSpace) / $file.Size) * 100, 2)
				$obj.GrowthType = $file.GrowthType
				$obj.GrowthMB = $file.Growth/1KB
				$null = $list.Add($obj)
			}
		}
		
		foreach ($file in ($db.LogFiles | Sort Id))
		{
			$obj = "" | Select FileGroup, FileId, Name, FileName, SizeMB, UsedSpaceMB, FreeSpaceMB, FreePercent, GrowthType, GrowthMB
			$obj.FileGroup = "(none)"
			$obj.FileId = $file.Id
			$obj.Name = $file.Name
			$obj.FileName = $file.FileName
			$obj.SizeMB = [math]::Round($file.Size/1KB, 2)
			$obj.UsedSpaceMB = [math]::Round($file.UsedSpace/1KB, 2)
			$obj.FreeSpaceMB = [Math]::Round(($file.Size - $file.UsedSpace)/1KB, 2)
			$obj.FreePercent = [math]::Round((($file.Size - $file.UsedSpace) / $file.Size) * 100, 2)
			$obj.GrowthType = $file.GrowthType
			$obj.GrowthMB = $file.Growth/1KB
			$null = $list.Add($obj)
		}
		return $list.ToArray()
	}
	else
	{
		$obj = "" | Select FileGroup, FileId, Name, FileName, SizeMB, UsedSpaceMB, FreeSpaceMB, FreePercent, GrowthType, GrowthMB
		return @($obj)
	}
}
