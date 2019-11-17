<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.163
	 Created on:   	10/4/2019 9:19 AM
	 Created by:   	BenMiller(DBAduck)
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


## Set a SMO Server object to the default instance on the local computer.  
CD SQLSERVER:\SQL\localhost\DEFAULT
$srv = get-item .

## Open a Common.ServerConnection to the same instance.  
$serverconnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($srv.ConnectionContext.SqlConnectionObject)
$serverconnection.Connect()
$dacstore = New-Object Microsoft.SqlServer.Management.Dac.DacStore($serverconnection)

## Load the DAC package file.  
$dacpacPath = "C:\MyDACs\MyApplication.dacpac"
$fileStream = [System.IO.File]::Open($dacpacPath, [System.IO.FileMode]::OpenOrCreate)
$dacType = [Microsoft.SqlServer.Management.Dac.DacType]::Load($fileStream)

## Subscribe to the DAC deployment events.  
$dacstore.add_DacActionStarted({ Write-Host `n`nStarting at $(get-date) :: $_.Description })
$dacstore.add_DacActionFinished({ Write-Host Completed at $(get-date) :: $_.Description })

## Deploy the DAC and create the database.  
$dacName = "MyApplication"
$evaluateTSPolicy = $true
$deployProperties = New-Object Microsoft.SqlServer.Management.Dac.DatabaseDeploymentProperties($serverconnection, $dacName)
$dacstore.Install($dacType, $deployProperties, $evaluateTSPolicy)
$fileStream.Close() 