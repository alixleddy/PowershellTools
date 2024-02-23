# Test for existence of IntuneWinAppUtil in expected folder
$proceed = test-path "C:\servicedesk\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe"
if ($proceed) {
    
    # Initialise variables for script contents and file location
    $CMTTokenValue = (Read-Host -Prompt "Please enter the Chrome token GUID")
    $CMTName = (Read-Host -Prompt "Please enter the name of the OU managed by this token")

    #Change OutputFolder here to your preferred location
    $OutputFolder = "C:\servicedesk\ChromeManagementScripts"

    $CMTFolder = "$($OutputFolder)\$($CMTName)CMT"
    $CMTFilename = "$($CMTName)CMT.ps1"
    $CMTPath = "$($CMTFolder)\$($CMTFilename)"
    $CMTScriptContents = 'Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Google\Chrome -Name "CloudManagementEnrollmentToken" -Value "'+ $CMTTokenValue + '"'

    New-Item -Path $CMTPath -force
    set-content -Path $CMTPath -value $CMTScriptContents
    cd "C:\servicedesk\Microsoft-Win32-Content-Prep-Tool-master"
    cmd.exe /c "IntuneWinAppUtil -c $($CMTFolder) -s $($CMTFilename) -o $OutputFolder"

    $intunewinfilepath = "$($OutputFolder)\$($CMTName)CMT.intunewin"
    if (test-path $intunewinfilepath) {
        write-host "Your file has been generated at $($intunewinfilepath)."
        write-host "Upload to Intune now using the following details:"
        write-host "Install command: Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\$($CMTFilename)"
        write-host "(You can use the same value for the uninstall as this will not need to be uninstalled)"
        write-host "Manually  configure detection rules with rule type Registry"
        write-host "Key path is HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome"
        write-host "Value name is CloudManagementEnrollmentToken"
        write-host "Method string comparision with operator equals and value $($CMTTokenValue)"
    }
    else {
    write-host "The output file was not detected, please check your inputs"
    }

}
else {
    # If IntuneWinAppUtil not present in expected location, advise user
    write-host "Please ensure you have the Intune Content Prep tool downloaded and unzipped into folder C:\servicedesk"
}