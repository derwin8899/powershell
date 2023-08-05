<##################################################################
Script Name: process_finder.ps1
Description: Finds all instances of notepad.exe and users from list of computers
- Runs asynchonously using start-job and receive-job
- Example: .\process_finder.ps1
- Output is in gridview
Author: DJE 
Date Created: 11/18/2020
###################################################################>

cls
# Initialize final report
[array]$report = @()

# Commands that will be executed against each computer. Values captured will be put into a psobject
$cmd = {
  param([string]$compname)
  sleep 5
    
  # Initialize array that will hold the values obtained for each process found
  [array]$return = @()
    
  # Get the processes matching 'notepad.exe' and use GetOwner to grab user acct info. Put each finding in a psobject.
  $proc = Get-CimInstance Win32_Process -computername $compname | where commandline -match 'notepad.exe' 
  foreach ($line in $proc) {
    $procowner = Invoke-CimMethod -InputObject $line -MethodName GetOwner
    [pscustomobject]$obj = New-Object psobject
    $obj | Add-Member -Type NoteProperty -Name "computer" -Value $compname
    $obj | Add-Member -Type NoteProperty -Name "user" -Value $procowner.user
    $obj | Add-Member -Type NoteProperty -Name "process" -Value $line.processId.tostring()
    $obj | Add-Member -Type NoteProperty -Name "domain" -Value $procowner.domain
    $return += $obj
  }
  # Return the array containing object info.
  $return
}

# List of computers to query. Start-job if it's online.
[array]$complist = "dc41", "w42", "fake", "w43"

foreach ($comp in $complist) {
  $testcon = test-connection  -count 2 -ComputerName $comp
  if (!$testcon) {
    echo "$comp not found"
  }
  else {
    Start-Job -ScriptBlock $cmd -ArgumentList $comp
  }
}

# Wait until all jobs finish and then get all returned objects with receive-job.
get-job | wait-job
$returnedinfo = get-job | receive-job 

# Iternate throught the info returned putting each set of values into an object, then all objects into the final array.
foreach ($item in $returnedinfo) {
  [pscustomobject]$lineobj = New-Object psobject
  $lineobj | Add-Member -Type NoteProperty -Name "computer" -Value $item.computer
  $lineobj | Add-Member -Type NoteProperty -Name "user" -Value $item.user
  $lineobj | Add-Member -Type NoteProperty -Name "processID" -Value $item.process
  $lineobj | Add-Member -Type NoteProperty -Name "domain" -Value $item.domain
  $report += $lineobj
}

# Display the object in gridview.
$report | Out-GridView

