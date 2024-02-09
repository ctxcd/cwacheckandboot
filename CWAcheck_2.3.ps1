<#
    This script checks the used CWA version for compatibility.
    Depending on the date, it prompts the user with different messages and actions, and logs the actions taken.

    Version    : 2.3
    Modified by: Christopher Dilkie
    Original Created by : Jeroen Tielen - Tielen Consultancy
#>

# Ensure the log directory exists
$logPath = "C:\temp\cwacheck.log"
If (-Not (Test-Path "C:\temp")) {
    New-Item -ItemType Directory -Force -Path "C:\temp"
}

# Function to log messages
function LogMessage {
    param (
        [string]$message
    )

    $logTimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$logTimeStamp - $message" | Out-File -FilePath $logPath -Append
}

# Set cutoff date
$cutoffDate = Get-Date "02/04/2024" -Format "MM/dd/yyyy"
$currentDate = Get-Date -Format "MM/dd/yyyy"

LogMessage "Script started. Cutoff date is set to $cutoffDate."
LogMessage "Current date is $currentDate."

# Determine the client session and version
$SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
$InfoFromRegistry = Get-ItemProperty -Path HKLM:\SOFTWARE\Citrix\Ica\Session\$SessionId\Connection
$ClientVersion = $InfoFromRegistry.ClientVersion
$ClientPlatform = $InfoFromRegistry.ClientProductID

# Define minimum versions
$MinimumWindowsVersion = "19.11.0.50"
$MinimumMacVersion = "20.9.0.17"
$MinimumLinuxVersion = "20.06.0.15"

# Add PresentationFramework for message boxes
Add-Type -AssemblyName PresentationFramework

# Function to show message
function ShowMessage {
    param (
        [string]$message
    )

    [System.Windows.MessageBox]::Show($message, 'Update Required', 'OK', 'Warning')
    LogMessage "Displayed message to user: $message"
}

# Function to handle the version check and potential logoff
function CheckVersionAndPrompt {
    param (
        [bool]$forceLogoff
    )

    $message = $null

    switch ($ClientPlatform) {
        1 {
            if ([version]$ClientVersion -lt [version]$MinimumWindowsVersion) {
                $message = "Windows client version ($ClientVersion) is out of date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app"
            }
        }
        82 {
            if ([version]$ClientVersion -lt [version]$MinimumMacVersion) {
                $message = "Mac client version ($ClientVersion) is out of date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app"
            }
        }
        81 {
            if ([version]$ClientVersion -lt [version]$MinimumLinuxVersion) {
                $message = "Linux client version ($ClientVersion) is out of date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app"
            }
        }
        257 {
            $message = "For the best Microsoft Teams experience, please install the Citrix Workspace App."
        }
    }

    if ($null -ne $message) {
        ShowMessage $message
    }

    if ($forceLogoff -and $null -ne $message) {
        LogOffUser
    }
}

# Separate function to log off the user
function LogOffUser {
    [System.Windows.MessageBox]::Show("You are out of date and will be logged off in 60 seconds.", 'Logoff Warning', 'OK', 'Warning')
    LogMessage "User warned of logoff. Logging off in 60 seconds."
    Start-Sleep -Seconds 60
    Start-Process "shutdown" -ArgumentList "/l" -NoNewWindow
    LogMessage "Executing logoff command."
}

# Determine flow based on date
if ($currentDate -lt $cutoffDate) {
    LogMessage "Current date is before the cutoff date. Executing the first flow."
    CheckVersionAndPrompt $false
} else {
    LogMessage "Current date is after the cutoff date. Executing the second flow."
    CheckVersionAndPrompt $true
}
