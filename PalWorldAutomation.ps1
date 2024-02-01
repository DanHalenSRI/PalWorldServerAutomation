## This Powershell Script helps monitor and maintain your PalWorld Server.
## You will need to download ARRCON which is an executable that can interface with PalWorld's RCON Service for remote Server commands.  See https://github.com/radj307/ARRCON/wiki
## This script can be run manually as it will loop based on the time set in settings below, or launched as a Scheduled Task on Startup / Login, etc.
## This script is still in the works so please feel free to submit feedback, feature requests, etc.
######################
### Basic Settings ###
######################

#Root Location of your Palworld Server.  This folder should contain PalServer.exe and the "Pal" folder.
$palServerLocation = "C:\steamcmd\steamapps\common\PalServer"

#Path to your Arrcon executable
$ArrconEXEPath = "C:\myPath\ARRCON-3.3.7-Windows\ARRCON.exe"

#Name of configured and saved hostname in Arrcon.  See https://github.com/radj307/ARRCON/wiki for details on setting this up.  Do not use any spaces.
$SavedHostName = "MyServer" 

#Frequency - How often, in seconds, do you want this script to run?  The more often this runs the more resources it will take.  15 minutes (900 seconds) seems reasonable.
$Frequency = 900

#Save the game when this script runs.
$PSGameSave = $true

#######################
### Backup Settings ###
#######################

#IncrementalBackups - creates a copy of your save data every hour, organized in folders by day.  $true to enable, $false to disable.
$IncrementalBackups = $true

#Path where you would like your PalWorld Save to be backed up to - only used if $IncrementalBackups is set to $true
$BackupSavePath = "D:\PalWorldBackup"

#How many days to keep backups? Only used if $IncrementalBackups is set to $true
$SaveHistory = 7

#Backup just game saves or entire PalWorld Server folder and configuration? $true for everything, $false for just save files.  Full server backups are 6+ GB every hour and probably not needed.
#Only used if $IncrementalBakcups is set to $true
$fullBackup = $false

####################################################
### Memory Monitoring and Server Reboot Settings ###
####################################################
## This will broadcast 4 warnings at 1/4 of the $ShutDownTime set below, followed by a manual /save command during the last 25% of time remaining.
## A /ShutDown command will be sent, and after 60 seconds the server will re-launch automatically

#Pal Server Memory monitoring and server reboot if over threshold set above
$PSMemory = $true

#How much memory in MB is the max memory you want PalServer to use before automatically restarting to clear ram usage
$MemoryThreshold = 7000

#Server shutdown time in seconds - how long to wait after a shutdown is triggered to give players time to find a safe spot?
$ShutDownTime = 300

#################################################################################
#DO NOT MODIFY ANYTHING BELOW.  Unless you know what you're doing, then have fun!
#################################################################################

### Script Functions ###

function Start-HighMemoryUsageRemediation {
    #concatenate saved hostname and function commands
    $functionParameters = $SavedHost + """broadcast MEM_Server_restart_in_($ShutDownTime)_sec"""
    $functionParameters3 = $SavedHost + "shutdown"
 
    Start-Process -FilePath $ArrconEXEPath -ArgumentList $functionParameters -Wait
    
    $timeLeft = $ShutDownTime
    $i = 4

    while ($i -gt 0) {
        write-host $i
        $timeleft = [math]::Ceiling($timeLeft - $ShutDownTime / 4)
        write-host $timeLeft
        start-sleep -Seconds ([math]::Ceiling($ShutDownTime / 4))
        write-host "shutdown in $timeleft seconds"
        $i = $i - 1
        $functionParameters2 = $SavedHost + """broadcast Server_restart_in_($timeleft)_seconds"""
        Start-Process -FilePath $ArrconEXEPath -ArgumentList $functionParameters2 -Wait
        if ($i -eq 1) {
            #Start-PalWorldSave
            write-host "starting save"
        }
    }

    Write-Host "starting shutdown process"

    Start-Process -FilePath $ArrconEXEPath -ArgumentList $functionParameters3 -Wait

    Start-Sleep -seconds 60

    Start-Process -FilePath "C:\steamcmd\steamapps\common\PalServer\PalServer.exe"


}

function Start-PalWorldSave {
    
    $functionParameters = $SavedHost + "save"
    
    Start-Process -FilePath $ArrconEXEPath -ArgumentList $functionParameters -Wait -NoNewWindow

}


function Start-PalWorldIncrementalBackup {
    
    if (!(Test-Path $BackupSavePath)) {
        return
    } else {

        #Get today's date
        $currentDate = Get-Date

        # Round time to the previous hour
        $roundedTime = $currentDate.AddMinutes( - ($currentDate.Minute)).AddSeconds( - ($currentDate.Second))

        # Display the rounded time
        Write-Host "Current time: $($currentTime.ToString('HH:mm:ss'))"
        Write-Host "Rounded time to the previous hour: $($roundedTime.ToString('HH'))"

        #Check for today's folder and create one if it doesn't exist
        # Check if the date folder already exists
        $dateFolder = "$BackupSavePath\$($currentDate.ToString('yyyy-MM-dd'))"
        if (-not (Test-Path $dateFolder)) {
            # If it doesn't exist, create the folder
            New-Item -Path $dateFolder -ItemType Directory

            #cleanup old saves
            #Get the date of the number of days provided for save history
            $DateLastBackupToKeep = $currentDate.AddDays(-$SaveHistory)

            #Get all saves
            $allSaveHistory = Get-ChildItem $BackupSavePath

            #Filter out saves we want to keep
            $savesToDelete = $allSaveHistory | Where-Object -Property "Name" -LT $DateLastBackupToKeep.ToString('yyyy-MM-dd')

            #Pass all folders we want to delete to the delete commandlet
            $savesToDelete | Remove-Item -Recurse -Force
        }
    
        #Check for hourly backup folder
        $hourlyFolder = "$BackupSavePath\$($currentDate.ToString('yyyy-MM-dd'))\$($roundedTime.ToString('HH'))"
        if (-not (Test-Path $hourlyFolder)) {
            # If it doesn't exist, create the folder
            New-Item -Path $hourlyFolder -ItemType Directory

            if ($fullBackup -eq $true) {

                Copy-Item -Path $palServerLocation -Destination $hourlyFolder -Recurse -Force

            }
            else {

                Copy-Item -Path $palWorldSave -Destination $hourlyFolder -Recurse -Force

            }
        }
    }
}



### Main Script - do not modify below unles you know what you are doing.  Feel free to submit pull requests with improvements if you find some! ###

#create fully qualified variables from data provided above
$palWorldSave = (Join-Path $palServerLocation -ChildPath "Pal\Saved\SaveGames")
$SavedHost = "--saved " + $SavedHostName + " "

while ($true) {

    if ($MemoryMonitoring -eq $true) {
        #Get machine memory statistics
        $MemoryUsageData = Get-WmiObject Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize
        $palServerMemoryConsumption = [math]::Ceiling((Get-Process -Name "PalServer-Win64*").WorkingSet / 1MB)
        $totalMemory = $MemoryUsageData.TotalVisibleMemorySize
        $freeMemory = $MemoryUsageData.FreePhysicalMemory
        $usedMemory = $totalMemory - $freeMemory
        $memoryPercentage = [math]::Ceiling(($usedMemory / $totalMemory) * 100)


    }
    
    if ($PSGameSave -eq $true) {
        Start-PalWorldSave
    }

    if ($IncrementalBackups -eq $true) {
        Start-PalWorldIncrementalBackup
    }

    if (($palServerMemoryConsumption -gt $MemoryThreshold) -and ($PSMemory -eq $true)) {
        Start-HighMemoryUsageRemediation
    }

    Start-Sleep -Seconds $Frequency

}
