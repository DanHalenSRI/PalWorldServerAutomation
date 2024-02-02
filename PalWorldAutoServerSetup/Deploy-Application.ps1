<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = 'DanHalenSRI'
    [String]$appName = 'Automatic PalWorld Server and Arrcon Setup'
    [String]$appVersion = ''
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '02/02/2024'
    [String]$appScriptAuthor = 'DanHalenSRI'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.3'
    [String]$deployAppScriptDate = '02/05/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Installation tasks here>

        #Set Variables
        $directoryPath = "C:\Program Files\steamcmd"
        $arrconDirectoryPath = "C:\Program Files\Arrcon"


        #create install directories if they don't already exist

        Show-InstallationProgress -StatusMessage "Checking for and creating steamcmd and Arrcon directories..."

        if (-not (Test-Path $directoryPath -PathType Container)) {
            # If it doesn't exist, create the directory
            New-Item -ItemType Directory -Path $directoryPath -Force
        }

        # Check if the Arrcon directory exists
        if (-not (Test-Path $arrconDirectoryPath -PathType Container)) {
         # If it doesn't exist, create the directory
        New-Item -ItemType Directory -Path $arrconDirectoryPath -Force
        }

        Show-InstallationProgress -StatusMessage "Downloading Steamcmd..."
        Start-BitsTransfer -Source "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -Destination "$directoryPath\steamcmd.zip"

        Show-InstallationProgress -StatusMessage "Downloading Arrcon..."
        Start-BitsTransfer "https://github.com/radj307/ARRCON/releases/download/3.3.7/ARRCON-3.3.7-Windows.zip" -Destination "$arrconDirectoryPath\Arrcon-3.3.7-Windows.zip"

        Show-InstallationProgress -StatusMessage "Extracting Steamcmd files..."
        Expand-Archive -Path "$directoryPath\steamcmd.zip" -DestinationPath "$directoryPath"

        Show-InstallationProgress -StatusMessage "Extracting Arrcon files..."
        Expand-Archive -Path "$arrconDirectoryPath\Arrcon-3.3.7-Windows.zip" -DestinationPath "$arrconDirectoryPath"

        Show-InstallationProgress -StatusMessage "Pre-install complete."

        
        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        ## Handle Zero-Config MSI Installations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) {
                $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ }
            }
        }

        ## <Perform Installation tasks here>
        #Set Variables
        # Define hashtable with placeholders and their values

        $palServerPath = Join-Path -Path $directoryPath -ChildPath "steamapps\common\PalServer"
        $palSettingsPath = Join-Path -Path $palServerPath -ChildPath "Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
        $publicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content
        $serverName = ("$env:USERNAME" + "Server").replace(" ","")
        $serverDescription = $env:USERNAME + "'s fun server!"
        $adminPassword = (-join ((65..90) + (97..122) | Get-Random -Count (-join ((2..5) | Get-Random -Count 1)) | % {[char]$_})) + (-join ((1..10) | Get-Random -Count (-join ((2..5) | Get-Random -Count 1))))
        $serverPassword = (-join ((65..90) + (97..122) | Get-Random -Count (-join ((2..5) | Get-Random -Count 1)) | % {[char]$_})) + (-join ((1..10) | Get-Random -Count (-join ((2..5) | Get-Random -Count 1))))

        $placeholderValues = @{
            "###ServerName###" = "$serverName"
            "###ServerDescription###" = "$serverDescription"
            "###AdminPassword###" = "$adminPassword"
            "###ServerPassword###" = "$serverPassword"
            "###PublicIP###" = "$publicIP"
        }

        Show-InstallationProgress -StatusMessage "Launching steamcmd and installing PalWorld Server.  Do not exit out of the steamcmd window if one appears."
        Execute-Process -Path "$directoryPath\steamcmd.exe" -Parameters "+login anonymous +app_update 2394010 validate +quit" -WindowStyle 'Hidden'

        Show-InstallationProgress -StatusMessage "Start PalWorld Server First Launch Tasks. Do not close any windows during this process."
        Execute-Process -Path "$palServerPath\PalServer.exe" -NoWait

        While (!(Test-Path -Path "$palServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")) {
            Show-InstallationProgress -StatusMessage "Still waiting for PalWorld Server First Launch Tasks to finish.  Please wait."
            Start-Sleep -Seconds 30
        }
        
        Show-InstallationProgress -StatusMessage "First Launch tasks complete... attempting to close PalWorld Server for configuration.  Please wait, this can take a few minutes."

        Start-Sleep -Seconds 30

        Get-Process -Name "Pal*" | Stop-Process -Force


    # Save the updated content back to the INI file
    $fileContent | Set-Content -Path $palSettingsPath

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>

        Show-InstallationProgress -StatusMessage "Copying config file..."
        Copy-Item -Path "$dirSupportFiles\DefaultPalWorldSettings.ini" -Destination "$palSettingsPath" -Force

        Show-InstallationProgress -StatusMessage "Copying server launch script to your desktop..."
        Copy-Item -Path "$dirSupportFiles\StartPalServer.bat" -Destination $envUserDesktop
        
        $fileContent = Get-Content -Path $palSettingsPath -Raw

        Show-InstallationProgress -StatusMessage "Setting custom configurations..."
        # Iterate through the hashtable and replace placeholders with values
        foreach ($placeholder in $placeholderValues.Keys) {
            $fileContent = $fileContent -replace $placeholder, $placeholderValues[$placeholder]
        }

        Show-InstallationProgress -StatusMessage "Launching Arrcon and creating a save for your server..."
        Execute-Process -Path "$arrconDirectoryPath\ARRCON.exe" -Parameters "-H $publicIP -P 25575 -p $adminPassword --save-host $serverName" -Wait

        Show-InstallationProgress -StatusMessage "creating README file with server settings on your desktop..."
        $content = @"
Here are the PalWorld Server Configurations you need to know:
Server connection information is: $($publicIP):8211
Server name is: $serverName
Server Password for players to join is: $serverPassword
Server Administrator Password is: $adminPassword

You can change these settings by editing the PalWorldSettings.ini file located here:
$palSettingsPath

You can launch the server by running "StartPalServer.bat" located here: $envUserDesktop

You will need to create Port Forwards on your router for the following ports: 8211 and 25575
"@

        # Write content to the text file
        $content | Out-File -FilePath $outputFilePath -Encoding UTF8

        # Display success message
        Write-Host "PalWorld Server Configurations file created at: $outputFilePath"


        ## Display a message at the end of the install
        If (-not $useDefaultMsi) {
            Show-InstallationPrompt -Message 'Your PalWorld Server and Arrcon remote admin command app have been setup!  Please see' -ButtonRightText 'OK' -Icon Information -NoWait
        }
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Uninstallation tasks here>


        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }

        ## <Perform Uninstallation tasks here>


        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>


    }
    ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        ## <Perform Repair tasks here>

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
