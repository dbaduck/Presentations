# Load the IntegrationServices Assembly            
$assembly = "Microsoft.SqlServer.Management.IntegrationServices, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
Add-Type -AssemblyName $assembly
            
# Store the IntegrationServices Assembly namespace to avoid typing it every time            
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"            
            
Write-Host "Connecting to server ..."            
            
# Create a connection to the server            
$constr = "Data Source=localhost;Initial Catalog=master;Integrated Security=SSPI;"            
            
$con = New-Object -TypeName System.Data.SqlClient.SqlConnection -Args $constr            
            
# Create the Integration Services object            
$ssis = New-Object -TypeName "$ISNamespace.IntegrationServices" -Args $con            
            
$cat = $ssis.Catalogs["SSISDB"]

$folder = $cat.Folders["DogFoodCon2019"]
            
# Read the project file, and deploy it to the folder
$path = "D:\Development\DogFoodCon2019\DogFoodCon2019\DogFoodCon2019\bin\Development\*.ispac"
foreach ($item in (Get-ChildItem $path)) {
	Write-Host "Deploying project $($item.BaseName) ..."
	[byte[]]$projectFile = [System.IO.File]::ReadAllBytes($item.FullName)
	$folder.DeployProject("$($item.BaseName)", $projectFile)
}


