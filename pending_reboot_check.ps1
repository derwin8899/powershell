<##################################################################
Script Name: pending_reboot_check.ps1
Description: Takes list of computers and checks registry keys flagged for reboot.
- Used for windows update pre-check list.
- Example: .\pending_reboot_check.ps1 -inputfile C:\temp\serverlist.txt
- Output file provided as csv: "pending_reboot_check_<date>.csv"
Author: DJE 
Date Created: 8/20/2018
###################################################################>

# Parameter for input file
param($inputfile)

# validate input file exists
If (!$inputfile) {
  echo "Error - An input file with IPs or hostnames must be specified. Example: .\pending_reboot_check.ps1 -inputfile C:\temp\serverlist.txt"
  break
}
else {}

$ErrorActionPreference = 'silentlycontinue'

# Test connectivity to server
function test_connect($tci) {
  if (!(test-connection -count 1 $tci)) {
    return $false
  }
  else { return $true }
}

# Check wmi and reg keys for possible pending reboot values
function check_pending($cpi) {

  invoke-command -computer $cpi -ScriptBlock {
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { 
      return $true 
    }
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { 
      return $true 
    }
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { 
      return $true 
    }
    try { 
      $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
      $status = $util.DetermineIfRebootPending()
      if (($status -ne $null) -and $status.RebootPending) {
        return $true
      }
    }
    catch { }
    return $false
  }
}

# Setup counter, get input file contents, and initiate report object. 
$x = 1
$file1 = get-content $inputfile
$countlines = ($file1).Count
[array]$report = @() 

# Loop through list of servers, pass to function and put results into report object. 
foreach ($serv in $file1) {
  echo "--------------------------------------------------"
  echo "Checking $serv Item $x of $countlines"
  [function]$connect_result = test_connect($serv)
  $pending_reboot = check_pending($serv)
  $obj1 = New-Object psobject
  $obj1 | Add-Member -Type NoteProperty -name 'Server' -Value $serv
  $obj1 | Add-Member -Type NoteProperty -name 'Connect' -Value $connect_result
  $obj1 | Add-Member -type NoteProperty -name 'PendingReboot' -Value $pending_reboot
  $report += $obj1
  $x++

}
# Take contents of report object and output to .csv file and gridview.
[string]$outputfile = ("pending_reboot_check_" + (get-date -Format "yyyMMddHHmm") + ".csv")
$report | Out-GridView
$report | Export-Csv -Path .\$outputfile -NoTypeInformation

echo "Done. check $outputfile for results"