
<#
Why PowerShell? I am a DBA.

Consider the click. Simple, yet single use and certainly not reusable.
Consider managing multiple SQL Servers. If you have one server and one database and the checks cash, keep that gig.

It is really easy to get started.  It is really easy to quit.

With a little practice and a lot of help from Modules, you will get everything out of it.
Reusability, if you write scripts, documentation, etc.

You just cannot afford to convince yourself that it is not worth it. You will look back and regret it.

Below are commands that will keep you in the game.
#>
Update-Help -SourcePath
Save-Help
Get-Help
Get-Command *sql*
Get-Command -Module dbatools -Name *sql*
Get-Command -Verb get -Module dbatools
Get-Module
Get-Module -ListAvailable dbatools

Get-Member
https://github.com/dbaduck


<#
Environment
#>
dir Variable:
$var1 = "Ben"
$var1.Gettype()
$var1 = 1
get-member -InputObject $var1

$var1 | Get-Member
$host
$pshome

Get-ExecutionPolicy

Set-ExecutionPolicy  
<#
    # -ExecutionPolicy (AllSigned, ByPass, RemoteSigned, Restricted, Undefined, Unrestricted)
        Most common: AllSigned, RemoteSigned, Restricted
    # -Scope (CurrentUser, LocalMachine, MachinePolicy, Process, UserPolicy)
        Most common: CurrentUser, LocalMachine
    # -Force (basically do not prompt me for the change, just do it)
        Most commonly used by Jedi's.
#>
$profile

<#
Editors
    # Azure Data Studio with PowerShell Extension
    # VS Code with PowerShell Extension
    # ISE (deprecated, but useful)
    # Visual Studio
    # Other Free Editors
    # Other Paid Editors

Modules
    # dbatools.io
    # SqlServer - Requires 5.1 PS
    # PoshRSJob - Parallelism
    # ImportExcel - dump data into Excel with formatting too.

C:\Program Files\WindowsPowerShell\Modules
C:\Users\username\Documents\WindowsPowerShell\Modules
C:\Program Files\PowerShell\Modules

#>
Install-Module dbatools -Scope CurrentUser
Install-Module SqlServer -AllowClobber  # AllowClobber simply says that you allow PowerShell to 
                                    # still install the module even if there are commands of the same name
Install-Module ImportExcel, PoshRsJob  # installing multiple modules at the same time.

<#
PowerShell Profile
#>
$profile
<#
Does not exist on install because the WindowsPowerShell folder does not exist in the Users Documents folder.
#>

New-Item -Path $profile -ItemType File -force

<#
Creates a new 0 byte file that you can now edit.
#>
notepad $profile
<#
Where are all the profiles that can be on a machine

c:\Users\username\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
c:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1
c:\Windows\SysWOW64\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1

All of the above except with ISE in them or other pieces in them for things like VSCode, ADS

What goes in them?

Demo Profile in folder.
#>
notepad $profile

<#

Why use a profile? Think of it like priming the pump. You can pre set up the environment.
Imagine, a list of servers, a variable that holds some critical database names that are frequent.

Perhaps a bunch of queries, in variables to use at various times.
Perhaps some functions that you use all the time.

If you only want to manage 1 then you can have a centralized place and put a .ps1 file
and then dot source it into each one of your profile files one time and then just
edit the one file ever after.

Here is how it works.

Inside the profile files, you would put the 
. "c:\profile\$(split-path $profile -leaf)"

Now remember that all these profiles fire and the first one to fire is your personal one.
$profile

So you will only want to load 1 of them, so don't overmanage, keep it simple.
To edit the global one for your type of PowerShell (x86, x64)
notepad "$pshome\$(split-path $profile -leaf)"
#>

<#
Concepts in PowerShell - Good to know

Pipeline
The pipeline is at the core of PowerShell and as a DBA we get to take advantage of it.

Think of it like doing a query and then taking the results and passing them to another procedure or query
    and do this again until the last pipeline is done and the result of that is returned.

    Things to think about. If you did a query with 1M rows in it and passed it to the next procedure
    you would be sending a copy, not the actual results, so now you have 2M rows in the buffer
    Keep it smaller as much as you can for fast pipelines.
    Consider what you are going to do in the pipeline before you just go use it.
    Functions need to be written to accept pipeline input.

    Get-Service -Name mssqlserver | Stop-Service
    Get-Service -Name mssqlserver | Start-Service


Functions
    These are not a lot different from what we are used to in Stored Procedures or Functions.
    These are key to PowerShell reusability - Create the function and reuse it just like in TSQL.
    Parameters are specified with - instead of @
    Parameters in PowerShell should always be specified (character significance as well)
        -Computer is the same as -ComputerName unless there is a parameter that starts with Computer 2 times
            ComputerName, ComputerSerial, means you would have to use -ComputerN or -ComputerS to be significant

    Get-Service -N mssql*
    Get-Service -Name mssql*

#>
function New-BenMiller {
    param(
        [boolean]$IsAwesome,
        [string]$Name
    )

    $returnstring = "The New Ben Miller is $Name"
    if($IsAwesome) {
        $returnstring = "$returnstring and he is Awesome"
    }
    else {
        $returnstring = "$returnstring and he is OK"
    }
    return $returnstring
    # $returnstring
    # Write-Output $returnstring
}

New-BenMiller -IsAwesome $true -Name "DBADuck"
New-BenMiller -IsAwesome $false -Name "BobOBob"

<#
Select, Where, Comparisons
    First Select is really Select-Object it gives you the ability to select properties out of the big list of them
    Where is really Where-Object and it gives you the same ability as WHERE does in TSQL
        whittle down the results by criteria
    Comparisons are really about Equal, NotEqual, GreaterThan, LessThan, GreaterThanOrEqual, LessThanOrEqual
        -eq -ne -lt -le -gt -ge -notin -contains -in -match -like -notlike
        Everything in PowerShell is case insensitive, so if you need a case sensitive comparison use these
        -ceq -cne -clt -cle -cgt

        Get-Help about_Comparison_Operators
#>
Get-Service | Select-Object Name
Get-Service | Select-Object -ExpandProperty Name
Get-Service | Where-Object Status -eq "Running" | Select-Object -First 3
    
<#
Foreach
    Foreach is really Foreach-Object
    This is the iteration operator that lets you take a collection of items and do something to each one
    RBAR in PowerShell, but very useful
#>
Get-Service -Name M* | Foreach-Object { $_.Name }
Foreach($service in (Get-Service M*)) {
    $service.Name
}

Get-Service -Name M* | Foreach { $_.Name }
$services = Get-Service M*
Foreach($service in $services) {
    $service.Name
}


<#
Notice that we have been speaking of these items above first by their Alias and not their full command?

Aliases are a great thing. There is one caution
    Be friendly to those that come after you, and use Full Parameter Names and Full Command Names in script
    On the command line, create your own Aliases and use them, use the built in ones


Remoting - PSSession
    Enable-PsRemoting - this is done on older systems where PsRemoting is not enabled by default
        
    Enter-PSSession
    New-PsSession
    Remove-PsSession

    If you are in a PSSession with Enter-PsSession, you exit out of it to get out.
    When you are in a PSSession with Enter-PsSession it is as if you were on that machine

    You can copy between Sessions if you establish more than one.

    Invoke-Command will create an implicit session

#>
Invoke-Command -ComputerName sqldemo, sqldemo2 -ScriptBlock { Get-Service mssql* }

Enter-Pssession -ComputerName sqldemo2
Enter-Pssession sqldemo2

New-Alias -Name bbb -Value Get-Service


Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Website
# https://dbaduck.com


