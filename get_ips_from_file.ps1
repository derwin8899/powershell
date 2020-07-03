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
Function ExtractValidIPAddress($eii){
    $IPregex= [regex]:: new('((?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d))')
    $Matches = $IPregex.Matches($eii)
    return $Matches.value
}
 
# Get contents of file that contains possible IPs
$file = gc '.\ips.txt'
 
# Pass each line to the function to obtain IP address matches. If found, write them to results.txt
foreach ($i in $file){
ExtractValidIPAddress $i >> results.txt
