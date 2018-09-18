<#
.SYNOPSIS
Downgrade Dell BIOS for Testing

.DESCRIPTION
This script is intended Downgrade the Dell BIOS for testing. 

Content source structure:

Model
    BIOS 
        Version
            â”” OSDBIOS-Update.ps1
            â”” Flash64W.exe
            â”” BIOSUpdateFile.exe

.EXAMPLE
Copy this file, the bios file and Flash64W.exe to your flash drive or map a network drive after booting to WinPE and run it from there. 

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

#Flash the BIOS
$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait -ErrorAction Stop
