Import-Module dbatools

$ary = @()
Measure-Command { 1..10000 | % { $ary += $_ }}

$ary2 = [System.Collections.ArrayList]@()
Measure-Command { 1..10000 | % { $null = $ary2.Add($_) }}


# This is a method of objects
[Collections.ArrayList]$ary = @()
$ary = [Collections.ArrayList]@()
$ary = New-Object -TypeName System.Collections.ArrayList

$server = Connect-DbaInstance -SqlInstance localhost
$server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], "ID, CompatibilityLevel")

foreach($db in ($server.Databases)) {
    $dbobj = "" | Select-Object ID, Name, CompatibilityLevel, IterationId
    
    $dbobj.ID = $db.Id
    $dbobj.Name = $db.Name
    $dbobj.CompatibilityLevel = $db.CompatibilityLevel
    $dbobj.IterationId = 1

    [void]$ary.Add($dbobj)
}
$dt = ConvertTo-DbaDataTable -InputObject $ary
Write-DbaDbTableData -SqlInstance localhost -Database DEMO1 -Table stats_Database -Schema dbo -InputObject $dt 

$ary.Clear()

# This is an Ordered Hash Table
foreach($db in ($server.Databases)) {
    $dbobj = New-Object PsObject -Property ([ordered]@{
        ID = $db.ID
        Name = $db.Name
        CompatibilityLevel = $db.CompatibilityLevel
        IterationId = 2
    })

    [void]$ary.Add($dbobj)

}
$dt = ConvertTo-DbaDataTable -InputObject $ary
Write-DbaDbTableData -SqlInstance localhost -Database DEMO1 -Table stats_Database -Schema dbo -InputObject $dt 
$dt
<#
    Now let's use a datatable manually created
#>
$dt = New-Object -TypeName System.Data.DataTable -ArgumentList "DBStats"

$col1 = New-Object -TypeName System.Data.DataColumn -ArgumentList ID, ([Int])
$col2 = New-Object -TypeName System.Data.DataColumn -ArgumentList Name, ([String])
$col2.MaxLength = 256
$col3 = New-Object -TypeName System.Data.DataColumn -ArgumentList CompatibilityLevel, ([String])
$col3.MaxLength = 10
$col4 = New-Object -TypeName System.Data.DataColumn -ArgumentList IterationId, ([Int])

<# Add columns to the table #>

$dt.Columns.Add($col1)
$dt.Columns.Add($col2)
$dt.Columns.Add($col3)
$dt.Columns.Add($col4)

<# Iterate through the databases #>
foreach($db in $server.Databases) {
    $row = $dt.NewRow()

    $row.ID = $db.ID
    $row.Name = $db.Name
    $row.CompatibilityLevel = $db.CompatibilityLevel
    $row.IterationId = 3

    $dt.Rows.Add($row)
}
Write-DbaDbTableDAta -SqlInstance localhost -Database DEMO1 -Table stats_Database -Schema dbo -InputObject $dt


