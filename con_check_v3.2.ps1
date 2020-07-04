<####################################################################################### 
Script Name: con_check.ps1
Description: Takes input file of servers and checks for winRM, icmp, port connectivity, and DNS entries (if providing IPs)
Output provided in .csv report. 
Author: DJE 
Date Created: 5/1/2019
Usage : .\concheck.ps1 -inputfile C:\temp\serverlist.txt"
########################################################################################> 

# Parameter for input file
param([string] $inputfile)

If(!$inputfile){
echo "Error - An input file with IPs or hostnames must be specified. Example: .\con_check.ps1 -inputfile C:\temp\serverlist.txt"
break}
else
{}

$ErrorActionPreference = "silentlycontinue"

 # Function to test winrm
function winrm_test{
param([string]$wti)
$wtc = (Get-service -ComputerName $wti | Where-Object {$_.name -like "*winrm*"} -WarningAction SilentlyContinue)
  if($wtc){
  return $wtc.status}
  else{
  return "FALSE"}
 }
 
# Function to test wmi
function wmi_check{
param([string]$wci)
$wct = (Get-WmiObject -Class Win32_Service -Filter "name='winmgmt'" -ComputerName $wci -WarningAction SilentlyContinue)
  if($wct.status){
  return $wct.state}
  else{
  return "FALSE"
  }
}

# Function test common tcp ports. List ports on the "$ports" line.  
Function prt_check1{
param([string]$pci)
$ar1=$null
$ar1=@()
$ports = "135","445","22","161","3389"
  foreach($p1 in $ports){
     $cmd1=Test-netconnection -ComputerName $pci -port $p1 -WarningAction SilentlyContinue
     $res1 = $cmd1.tcptestsucceeded
     $obj = ($p1 + ":" + $res1 + " ")
     $ar1 += $obj
  }
 $joined = [string]::Join('', $ar1)
 return $joined
 }

# Function icmp test
function test_con{
param([string]$tci)
$tct = (Test-Connection -computername $tci -Count 2 -quiet)
  if($tct){
  return "success"}
  else{
  return "FAILED"}
}

# Function to test DNS
function rev_dns{
param([string]$rdi)
$rdt =[System.Net.Dns]::gethostentry("$rdi").hostname
   If ($rdt){
   return $rdt
   }
   Else{
   $rdt = "NOT FOUND"
   }
    return $rdt
}

# Reporting results via PS custom object. 
$x=1
$file1 = get-content $inputfile
$countlines = ($file1).Count
$psreport = @()
foreach($i in $file1){
   $obj1= New-Object psobject
   echo "--------------------------------------------------"
   echo "Checking $i Item $x of $countlines"
   $tc = test_con($i)
   $rd = rev_dns($i)
   $pc = prt_check1($i)
   $wt = winrm_test($i)
   $wc = wmi_check($i)
   $obj1 | Add-Member -Type NoteProperty -name Input -Value $i
   $obj1 | Add-Member -type NoteProperty -name Ping -Value $tc
   $obj1 | Add-Member -type NoteProperty -name DNS -Value $rd
   $obj1 | Add-Member -Type NoteProperty -Name Ports -Value $pc
   $obj1 | Add-Member -Type NoteProperty -Name WinRM -Value $wt
   $obj1 | Add-Member -Type NoteProperty -Name WMI -Value $wc
   $psreport += $obj1
   $x++ 
}
  
[string]$outputfile = ("con_checker_" + (get-date -Format "yyyMMddHHmm") + ".csv")
$psreport | Out-GridView
$psreport | Export-Csv -Path .\$outputfile -NoTypeInformation

echo "Done. check $outputfile for results"



