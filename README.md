# PalWorldServerAutomation
Helpful Powershell scripts to get your PalWorld server setup and keep your memory leaks in check!

Automated save data backups, memory monitoring, server shutdown and restart timers and more!

How To Install a dedicated Palworld Server using PalWorldAutoServerSetup:
- PalworldAutoServerSetup uses a PSAppDeployToolkit wrapper to execute several functions that will help fast track your Palworld server setup.  The script will:
    - Install steamcmd
    - Install Arrcon (the Remote Server Command Client)
    - Install PalWorld Server
    - Automatically configure a ServerName, ServerPassword, AdminPassword, and apply your current external IPAddress to the server configuration
    - All configured settings will be exported to a README and placed on your Desktop
    - A PalWorld Server launch script will also be placed on your desktop for easy launching

- How to use it:
    - Start by copying the "PalWorldAutoServerSetup" folder to your computer
    - Open the folder and doubleclick "Deploy-Application.exe"
    - Click Start Install and wait until you see a finished message

There is currently no error handling or logging, I will add those as I can update the script.

Instructions for PalWorld Server Maintenance will be added soon.