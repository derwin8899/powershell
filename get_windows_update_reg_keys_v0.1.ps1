<####################################################################################### 
Script Name: get_windows_update_reg_keys.ps1
Description: For Windows patchng troubleshooting. 
- Takes list of servers and makes WMI call to check registry key values used for windows update.
- Includes WSUS or SCCM server, GPO options, day and time of update installs.
Author: DJE 
Date Created: 2/7/2018
Usage - Provide server names in $computer variable and run script: .\get_windows_update_reg_keys.ps1 
########################################################################################> 


$ErrorActionPreference = "silentlycontinue"

$report = @()

[string]$updateserver = 'WUServer'
[string]$targetgroup = 'TargetGroup'
[string]$updateoption = 'AUOptions'
[string]$auinstallday = 'ScheduledInstallDay'
[string]$auinstalltime = 'ScheduledInstallTime'

[array]$computers = "PHserver1", "PHserver2"
foreach ($computer in $computers) {
  echo "Testing $computer  ----------------------------------"

  # If server is not reachable update report object and quit
  $test_connect = test-connection -count 1 $computer
  If (!$test_connect) {
    echo "connection to $computer failed"
    [string]$connect_result = "Failed"
    $obj1 = new-object PSObject 
    $obj1 | add-member -membertype NoteProperty -name "Server" -Value $computer
    $obj1 | add-member -membertype NoteProperty -name "Connect" -Value $connect_result
    $report += $obj1
  }
  else {
    echo "connection to $computer is good. moving on..."
    [string]$connect_result = "OK"

    [string]$computer_os = (Get-WMIObject -ComputerName $computer win32_operatingsystem).caption
    
    $key1 = 'Software\Policies\Microsoft\Windows\windowsupdate'
    $reg1 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
    $regkey1 = $reg1.opensubkey($key1)
    $key2 = 'Software\Policies\Microsoft\Windows\windowsupdate\AU'
    $reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
    $regkey2 = $reg2.opensubkey($key2)
    $obj1 = new-object PSObject 
    $obj1 | add-member -membertype NoteProperty -name "Server" -Value $computer
    $obj1 | add-member -membertype NoteProperty -name "Connect" -Value $connect_result
    $obj1 | add-member -membertype NoteProperty -name "OS" -Value $computer_os
    $obj1 | add-member -membertype NoteProperty -name "UpateServer" -Value $regkey1.getvalue($updateserver)
    $obj1 | add-member -membertype NoteProperty -name "ADGroup" -Value $regkey1.getvalue($targetgroup)
    $obj1 | add-member -membertype NoteProperty -name "UpdateOption" -Value $regkey2.getvalue($updateoption)
    $obj1 | add-member -membertype NoteProperty -name "InstallDay" -Value $regkey2.getvalue($auinstallday)
    $obj1 | add-member -membertype NoteProperty -name "InstallTime" -Value $regkey2.getvalue($auinstalltime)
    $report += $obj1
  }
}

$report | Out-GridView


