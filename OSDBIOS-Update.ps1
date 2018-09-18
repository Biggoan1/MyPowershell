<#
.SYNOPSIS
Update Dell BIOS During OSD

.DESCRIPTION
This script is intended update Dell BIOS during OSD. 

Content source structure:

Model
    BIOS 
        Version
            â”” OSDBIOS-Update.ps1
            â”” Flash64W.exe
            â”” BIOSUpdateFile.exe

.EXAMPLE

.PARAMETER 

.NOTES
1.0 Initial Release 

Currently only verified with Dell Machines. 

#>

$Path = $PSScriptRoot

#Get the flash utility filename
$FlashUtility = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "Flash64W.exe" } | Select-Object -ExpandProperty FullName

#Get the BIOS filename
$CurrentBIOSFile = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -notlike ($FlashUtility | Split-Path -leaf) } | Select-Object -ExpandProperty FullName

#Set the switches
$FlashSwitches = "/b="+"""$CurrentBIOSFile"""+" /s /f"

#Setup the TSEnvironment for OSD
$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop

#Flash the BIOS
$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait -ErrorAction Stop

# Set reboot flag if restart required determined (exit code 2) - Note I set the exit code to 1 so it doesn't fail the task sequence. 

    if ($FlashProcess.ExitCode -match "0|2") 
    {
        # Set reboot required flag
            $TSEnvironment.Value("SMSTSBiosUpdateRebootRequired") = "True"
            $TSEnvironment.Value("SMSTSBiosInOSUpdateRequired") = "False"
	}
    elseif ($FlashProcess.ExitCode -eq "10") 
    {
        exit 1
	}
	else 
    {
        exit 1
	}
