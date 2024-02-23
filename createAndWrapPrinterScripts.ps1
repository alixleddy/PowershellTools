# Get user input
$printername = (Read-Host -Prompt "Please enter the name of the printer as shown in Printers when installed manually")
$printerURL = (Read-Host -Prompt "Please enter the IP address of the printer")
$wrap = (Read-Host -Prompt "Enter Y to wrap this script for Intune")
$wrap = ($wrap -like "y")

#Change OutputFolder here to your preferred location
$OutputFolder = "C:\servicedesk\PrinterDeployment\$($printername)"

#Initialise the rest of the variables for script locations
$IntuneWinInputFolder = "$($OutputFolder)\IntuneWinInput"
$PrinterInstallFilename = "AddPrinter$($printername).ps1"
$PrinterUninstallFilename = "RemovePrinter.ps1"
$PrinterDetectFilename = "DetectPrinter.ps1"

#Initialise variables for script content
$InstallContents = 
@"
`$printer = get-printer -Name $($printername) -ErrorAction SilentlyContinue 
if (!`$printer) {
    Add-Printer -ippurl $($printerURL)
    start-sleep -Seconds 120
    }
"@

$RemoveContents = "Remove-Printer -Name $($printername)"

$DetectionContents = 
@"
`$printer = get-printer -Name $($printername) -ErrorAction SilentlyContinue
if (`$printer) {
    Write-Output "Detected"
    exit0
    }
else {
    exit 1
    }
"@

New-Item -Path $IntuneWinInputFolder\$PrinterInstallFilename -force
set-content -Path $IntuneWinInputFolder\$PrinterInstallFilename -value $InstallContents

New-Item -Path $IntuneWinInputFolder\$PrinterUninstallFilename -force
set-content -Path $IntuneWinInputFolder\$PrinterUninstallFilename -value $RemoveContents

New-Item -Path $OutputFolder\$PrinterDetectFilename -force
set-content -Path $OutputFolder\$PrinterDetectFilename -value $DetectionContents

# Test for existence of IntuneWinAppUtil in expected folder
$proceed = test-path "C:\servicedesk\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe"
if ($proceed -and $wrap) {

    cd "C:\servicedesk\Microsoft-Win32-Content-Prep-Tool-master"
    cmd.exe /c "IntuneWinAppUtil -c $($IntuneWinInputFolder) -s $($PrinterInstallFilename) -o $OutputFolder"

    $intunewinfilepath = "$($OutputFolder)\AddPrinter$($printername).intunewin"
    if (test-path $intunewinfilepath) {
        write-host "Your file has been generated at $($intunewinfilepath)."
        write-host "Upload to Intune now using the following details:"
        write-host "Please use a descriptive name and add to the description that the install must be run on site"
        write-host "Install command: Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\$($PrinterInstallFilename)"
        write-host "Uninstall command: Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\$($PrinterUninstallFilename)"
        write-host "In Detection rules, choose 'Use a custom detection script'"
        write-host "The script is at $($OutputFolder)\$($PrinterDetectFilename)"
        write-host "Suggest deploying this as available rather than required"
    }
    else {
    write-host "The output file was not detected, please check your inputs"
    }

}
elseif ($wrap) {
    # If IntuneWinAppUtil not present in expected location, advise user
    write-host "Please ensure you have the Intune Content Prep tool downloaded and unzipped into folder C:\servicedesk"
}