<#
    This script checks the used CWA version for compatibility.
    Depending on the date, it prompts the user with different messages and actions, and logs the actions taken.

    Version    : 2.1
    Modified by: Christopher Dilkie
    Original Created by : Jeroen Tielen - Tielen Consultancy
#>

# Ensure the log directory exists
$logPath = "C:\temp\cwacheck.log"
If (-Not (Test-Path "C:\temp")) { New-Item -ItemType Directory -Force -Path "C:\temp" }

# Function to log messages
function LogMessage {
    param (
        [string]$message
    )

    $logTimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$logTimeStamp - $message" | Out-File -FilePath $logPath -Append
}

# Set cutoff date
$cutoffDate = Get-Date "02/04/2024" -Format "MM/dd/yyyy"  # Update Get-Date "mm/dd/yyyy" to your specific cutoff date
LogMessage "Script started. Cutoff date is set to $cutoffDate."

# Determine the current date
$currentDate = Get-Date -Format "MM/dd/yyyy"

# Determine the client session and version
$SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
$InfoFromRegistry = Get-ItemProperty -Path HKLM:\SOFTWARE\Citrix\Ica\Session\$SessionId\Connection
$ClientVersion = $InfoFromRegistry.ClientVersion
$ClientPlatform = $InfoFromRegistry.ClientProductID  # ClientProductID 1=Windows, 257=HTML5, 81=Linux, 82=Macintosh

# Define minimum versions
$MinimumWindowsVersion = "19.11.0.50"
$MinimumMacVersion = "20.9.0.17"
$MinimumLinuxVersion = "20.06.0.15"

# Add PresentationFramework for message boxes
Add-Type -AssemblyName PresentationFramework

# Determine flow based on date
if ($currentDate -lt $cutoffDate) {
    LogMessage "Current date is before the cutoff date. Executing the first flow."
    CheckVersionAndPrompt $false
} else {
    LogMessage "Current date is after the cutoff date. Executing the second flow."
    CheckVersionAndPrompt $true
}

function CheckVersionAndPrompt {
    param (
        [bool]$forceLogoff
    )

    if ($ClientPlatform -eq "1") {  # Windows
        if ([version]$ClientVersion -lt [version]$MinimumWindowsVersion) {
            ShowMessage "Windows client version ($ClientVersion) is out off date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app" $forceLogoff
        } else {
            LogMessage "Windows client version ($ClientVersion) is out off date."
        }
    } elseif ($ClientPlatform -eq "82") {  # Mac
        if ([version]$ClientVersion -lt [version]$MinimumMacVersion) {
            ShowMessage "Mac client version ($ClientVersion) is out off date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app" $forceLogoff
        } else {
            LogMessage "Mac client version ($ClientVersion)  is out off date."
        }
    } elseif ($ClientPlatform -eq "81") {  # Linux
        if ([version]$ClientVersion -lt [version]$MinimumLinuxVersion) {
            ShowMessage "Linux client version ($ClientVersion) is out off date. Please update to the latest version of Citrix Workspace from here on your laptop https://www.citrix.com/downloads/workspace-app" $forceLogoff
        } else {
            LogMessage "Linux client version ($ClientVersion)  is out off date."
        }
    } elseif ($ClientPlatform -eq "257") {  # HTML5
        ShowMessage "For the best Microsoft Teams experience, please install the Citrix Workspace App." $false
        LogMessage "HTML5 client detected. Advised to install Citrix Workspace App."
    }
}

function ShowMessage {
    param (
        [string]$message,
        [bool]$forceLogoff
    )

    [System.Windows.MessageBox]::Show($message,'Update Required','OK','WARNING')
    LogMessage "Displayed message to user: $message"

    if ($forceLogoff) {
        # Show logoff message
        [System.Windows.MessageBox]::Show("You are out of date and will be logged off in 60 seconds.",'Logoff Warning','OK','WARNING')
        LogMessage "User warned of logoff. Logging off in 25 seconds."
        Start-Sleep -Seconds 25
        # Log off the current user
        LogMessage "Executing logoff command."
        Start-Process "shutdown" -ArgumentList "/l" -NoNewWindow
    }
}