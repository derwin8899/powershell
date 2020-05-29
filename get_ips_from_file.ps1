<####################################################################################### 
Script Name: get_ips_from_file.ps1
Description: Function for extracting list of IPs from a file. 
- Useful for parsing IPs from Accounting team equipment "dump" files.
- Output provided in "results.txt"
Author: DJE 
Date Created: 4/20/2019
Usage - Provide full path to input file for the $file variable then run the script: .\get_ips_from_file.ps1 
########################################################################################> 

#Function
Function ExtractValidIPAddress($String){
    $IPregex=�(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))�
    If ($String -Match $IPregex) {$Matches.Address}
}
 
#Log line
$file = gc 'C:\temp\equipment_dump_20190312.txt'
 
#Run function
foreach ($i in $file){
ExtractValidIPAddress $i >> results.txt
}