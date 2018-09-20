<#
.SYNOPSIS
Write Microsoft Asset Info VIA OSD

.DESCRIPTION
Write Microsoft Asset Info VIA OSD

Content source structure:


.EXAMPLE

.PARAMETER 

.NOTES
1.0 Initial Release 


#>

#Setup the TSEnvironment for OSD
$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop

# Get PC Name
$OSDComputerName = $TSEnvironment.Value("OSDComputername")

# Write to Asset
Start-Process -FilePath .\AssetTag.exe -ArgumentList "-s $OSDComputerName"
