####################################################
# Start of Profile
####################################################
$date = Get-Date -f "yyyyMMdd_HHmmss"
Start-Transcript -Path "$(Split-Path $profile)\Transcript_$date.txt"

Register-EngineEvent PowerShell.Exiting -Action { Stop-Transcript } -SupportEvent

if (Test-Path -path "$(Split-Path $profile)\History.clixml")
{
	$history = Import-Clixml -Path "$(Split-Path $profile)\History.clixml"
	$history | Add-History
}

function Exit-Me
{
	Stop-Transcript
	Get-History | Where-Object ExecutionStatus -eq "Completed" | Export-Clixml -Path "$(split-path $profile)\History.clixml"
	Exit
}

function Get-MyOsAssemblies
{
	[Appdomain]::CurrentDomain.GetAssemblies() | select-Object FullName | Sort-Object FullName
}

Invoke-Expression "function $([char]4) { Exit-Me }"

########################################################
# Prompt
########################################################
function prompt
{
	
	# Set Window Title
	$host.UI.RawUI.WindowTitle = "$ENV:USERNAME@$ENV:COMPUTERNAME - $(Get-Location)"
	
	$lastCommand = Get-History -Count 1
	$nextId = $lastCommand.Id + 1;
	$ElapsedTime = ($LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime).TotalSeconds
	
	# Set Prompt
	Write-Host (Get-Date -Format G) -NoNewline -ForegroundColor Red
	Write-Host " :: " -NoNewline -ForegroundColor DarkGray
	#Write-Host "$ENV:USERNAME@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
	Write-Host "[$($ElapsedTime) s]" -NoNewLine -ForegroundColor Yellow
	
	Write-Host " :: " -NoNewline -ForegroundColor DarkGray
	Write-Host $(get-location) -ForegroundColor Green
	
	# Check for Administrator elevation
	$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$prp = new-object System.Security.Principal.WindowsPrincipal($wid)
	$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	$IsAdmin = $prp.IsInRole($adm)
	if ($IsAdmin)
	{
		$host.UI.RawUI.WindowTitle += " - Administrator"
		Write-Host " [$nextId] #" -NoNewline -ForegroundColor Gray
		return " "
	}
	else
	{
		Write-Host " [$nextId] >" -NoNewline -ForegroundColor Gray
		return " "
	}
}
########################################################
# End Profile
########################################################
