#Automatically setup a PalWorld Server using steamcmd.  Includes Arrcon for remote RCON server commands.

$directoryPath = "C:\Program Files\steamcmd2"
$arrconDirectoryPath = "C:\Program Files\Arrcon"
$palServerPath = Join-Path -Path $directoryPath -ChildPath "steamapps\common\PalServer"
$palSettingsPath = Join-Path -Path $palServerPath -ChildPath "Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
$publicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$serverName = Read-Host -Prompt "Enter your Server Name with No Spaces"
$serverDescription = Read-Host "Enter your Server Description."
$serverPassword = Read-Host "Enter the password to use for server access"
$adminPassword = Read-Host -Prompt "Enter the password to set as the Server Admin Password."
$iniFilePath = "$PSScriptRoot\DefaultPalWorldSettings.ini"



# Check if the directory exists
if (-not (Test-Path $directoryPath -PathType Container)) {
    # If it doesn't exist, create the directory
    New-Item -ItemType Directory -Path $directoryPath -Force
}

Invoke-WebRequest https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -OutFile "$directoryPath\steamcmd.zip"

while (!(Test-Path -Path "$directoryPath\steamcmd.zip")) {
    start-sleep -Seconds 10
}

Expand-Archive -Path "$directoryPath\steamcmd.zip" -DestinationPath "$directoryPath"

Start-Process -FilePath "$directoryPath\steamcmd.exe" -ArgumentList "+login anonymous +app_update 2394010 validate +quit" -Wait

Start-Process -FilePath "$palServerPath\PalServer.exe"

While (!(Test-Path -Path "$palServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")) {
    Start-Sleep -Seconds 15
}

Start-Sleep -Seconds 30

Get-Process -Name "Pal*" | Stop-Process -Force


$iniFilePath = "C:\users\dbart\desktop\DefaultPalWorldSettings.ini"


# Define hashtable with placeholders and their values
$placeholderValues = @{
    "###ServerName###" = "$serverName"
    "###ServerDescription###" = "$serverDescription"
    "###AdminPassword###" = "$adminPassword"
    "###ServerPassword###" = "$serverPassword"
    "###PublicIP###" = "$publicIP"
}

# Read the content of the INI file
$fileContent = Get-Content -Path $iniFilePath -Raw

# Iterate through the hashtable and replace placeholders with values
foreach ($placeholder in $placeholderValues.Keys) {
    $fileContent = $fileContent -replace $placeholder, $placeholderValues[$placeholder]
}

# Save the updated content back to the INI file
$fileContent | Set-Content -Path $iniFilePath
Write-Host "INI file updated successfully."

#Download Arrcon

# Check if the directory exists
if (-not (Test-Path $arrconDirectoryPath -PathType Container)) {
    # If it doesn't exist, create the directory
    New-Item -ItemType Directory -Path $arrconDirectoryPath -Force
}

Invoke-WebRequest -Uri "https://github.com/radj307/ARRCON/releases/download/3.3.7/ARRCON-3.3.7-Windows.zip" -UseBasicParsing -OutFile "$arrconDirectoryPath\Arrcon-3.3.7-Windows.zip"

Expand-Archive -Path "$arrconDirectoryPath\Arrcon-3.3.7-Windows.zip" -DestinationPath "$arrconDirectoryPath"

Start-Process -FilePath "$palServerPath\PalServer.exe"

start-sleep -Seconds 30

Start-Process -FilePath "$arrconDirectoryPath\ARRCON.exe" -ArgumentList "-H $publicIP -P 25575 -p $adminPassword --save-host $serverName" -Wait



 
