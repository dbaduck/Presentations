<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.144
	 Created on:   	11/20/2017 11:33 PM
	 Created by:   	bmiller
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Import-Module SqlServer

function Rename-Indexes
{
	[CmdletBinding()]
	param (
		$ServerInstance,
		$Database,
		$Table,
		$Schema = "dbo"
	)
	
	begin
	{
		$smo = "Microsoft.SqlServer.Management.Smo"
	}
	process
	{
		$server = New-Object -TypeName "$smo.Server" -Args $ServerInstance
		
		$db = $server.Databases["$Database"]
		if ($db -eq $null)
		{
			Write-Error "Database $Database does not exist on $ServerInstance"
			return
		}
		if(!$db.IsAccessible) {
			return
		}
		$list = [System.Collections.ArrayList]@()
		
		if ($Table)
		{
			$tables = $db.Tables["$Table", "$Schema"]
		}
		else
		{
			$tables = $db.Tables
		}
		foreach ($table in $tables)
		{
			if (!$table.IsSystemObject)
			{
				$names = $table.Indexes.Name
				Write-Verbose "Table: $($table.Name)"
				
				foreach ($index in $table.Indexes)
				{
					Write-Verbose "Current Name: $($index.Name)"
					$keys = $index.IndexedColumns | where IsIncluded -EQ $false
					$incl = $index.IndexedColumns | where IsIncluded -EQ $true | Sort Name
					
					$keysList = $keys | select -ExpandProperty Name
					$inclList = $incl | select -ExpandProperty Name
					
					if ($index.IndexKeyType -eq "DriPrimaryKey")
					{
						Write-Verbose "Primary Key"
						if ($index.IsClustered)
						{
							$newname = "PK"
						}
						else
						{
							$newname = "PKNC"
						}
					}
					elseif ($index.IndexKeyType -eq "DriUniqueKey" -or $index.IsUnique)
					{
						$newname = "UQ"
					}
					else
					{
						$newname = "IX"
					}
					# $index.IndexKeyType
					
					$keysfinal = $keys -Join "__"
					$inclfinal = $inclList -join "__"
					if (!$inclfinal)
					{
						$newname = "$($newname)_$($table.Schema)_$($table.Name)__$($keysfinal)".Replace("[", "").Replace("]", "")
					}
					else
					{
						$newname = "$($newname)_$($table.Schema)_$($table.Name)__$($keysfinal)__INCL__$($inclfinal)".Replace("[", "").Replace("]", "")
					}
					if (($index.Name -ne $newname -and $names -contains $newname) -or ($index.Name -eq $newname))
					{
						#Write-Warning "$newname already exists!"
					}
					else
					{
						Write-Verbose "New Index Name: $newname"
						$obj = "" | select IndexUrn, NewName
						$obj.IndexUrn = $index.Urn.Value
						$obj.NewName = $newname
						[void]$list.Add($obj)
						#$index.Rename($newname)
					}
				}
			}
			
		}
		foreach ($item in $list)
		{
			$indexToRename = $server.GetSmoObject($item.IndexUrn)
			if ($indexToRename)
			{
				$indexToRename.Rename($item.NewName)
			}
		}
	}
}
