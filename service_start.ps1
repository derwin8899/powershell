<##################################################################
service_start.ps1
- checks wsus related services to see if stopped and if so, starts them. 
- runs a max number of 4 time with 60 seconds between runs
- designed to be run as a scheduled task at startup
- in scheduled task put "powershell" for the program and the path to the file for input.
- MUST be run as administrator.
###################################################################>


$ErrorActionPreference = "silentlycontinue"

[array]$services_list = @('WSUS Service', 'Windows Internal Database')
[string]$logfile = "C:\utils\logs\service_start.log"
[int]$x = 1
[int]$sleeptime = 60
[int]$max_tries = 4

# Function for logging and echo to screen if running interactivley for troublehsooting.
function logger([string]$li) {
  echo "$li"
  $li | out-file $logfile -Append
}

# Mark the time of the script start to log file
logger ""
logger "###### service_start script started $(get-date) #######" 

# Loop through list of services to check status and attempt to start until started or max tries. 
do {
  [array]$bad_array = @()
  foreach ($srv in $services_list) {
    $tst = Get-Service | Where-Object { $_.displayname -eq $srv } | % { $_.status }
    if (!$tst) {
      logger "$(get-date) : status: Failed to get status on $srv"
    }
    else {
      switch ($tst) {
        "Stopped" { logger "$(get-date) : status: $srv is stopped"; $bad_array += $srv }
        "Running" { logger "$(get-date) : status: $srv is started" }   
      }
    }
  }
  # Check bad_array count. Start any services in it or break if none exist. 
  if ($bad_array.count -lt 1) {
    logger "$(get-date) : No services found needing start command."
    break
  }
  else {
    foreach ($i in $bad_array) {
      #echo "$i"
      logger "$(get-date) : Attempting to start service - $i"
      start-service -DisplayName $i
    }
  }
  logger "$(get-date) : Done with checking start attempts for this round. Max checks is $max_tries. This attempt: $x" 
  logger "$(get-date) : Script paused to allow time for serice starts. Will recheck services in $sleeptime seconds"
  sleep -Seconds $sleeptime
}
Until (++$x -gt $max_tries)
logger "$(get-date) : Script finished. Exiting."
