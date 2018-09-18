<#
.SYNOPSIS
Copy OSDBIOS-Update.ps1 to BIOS Folders

.DESCRIPTION
This script is intended to copy OSDBIOS-Update.ps1 to each BIOS folder.

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

#>

$MakeFolders = get-childitem $PSScriptRoot\Downloads -Exclude Fallback -Directory 

foreach ($MakeFolder in $MakeFolders) 
    {
        $ModelFolders = get-childitem $MakeFolders -Directory -Exclude Flash64Utility
        foreach ($ModelFolder in $ModelFolders) 
        {
        $BIOSVersionFolders = get-childitem $ModelFolder\BIOS -Directory
            foreach ($BIOSVersionFolder in $BIOSVersionFolders) 
            {
            Copy-Item -Path .\OSDBIOS-Update.ps1 -Destination $BIOSVersionFolder.FullName -Force
            }
        }
    }
