<#
.SYNOPSIS
Get Dell BIOS Version During OSD

.DESCRIPTION
SMBIOSBIOSVersion is stored as a string, not an integer. This script will create a BIOS version number TS Variable. 

Content source structure:
OSDBIOS-Version

.EXAMPLE

.PARAMETER 

.NOTES
1.0 Initial Release 

Currently only verified with Dell Machines. 

#>

# Setup the TSEnvironment for OSD
$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop

# Get the BIOS Version from WMI 
$OSDBIOSVersion = Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion 

    if ($OSDBIOSVersion -like "A*")
        { 
            # If this is a legacy Dell BIOS basically do nothing. 
            $TSEnvironment.Value("SMSTSBiosVersion") = $OSDBIOSVersion 
        }
    else
        {
            # Convert the BIOS version to int and split it. 
            [int]$Major,[int]$Minor,[int]$Build = $OSDBIOSVersion.Split('{.}')

            # If BIOS Version is less than 100 then this will add the leading zeros. 
            if ($Major -lt 100) { $Major1 = $Major.ToString("000") } else { $Major1 = $Major }
            if ($Minor -lt 100) { $Minor1 = $Minor.ToString("000") } else { $Minor1 = $Minor }
            if ($MBuild -lt 100) { $Build1 = $Build.ToString("000") } else { $Build1 = $Build } 

            # Set the version with leading zeros. 
            $OSDBIOSVersion = "$Major1.$Minor1.$Build1"
            #$OSDBIOSVersion #Uncomment for testing
        }
# Sets SMSTSBiosVersion as a TS Variable. 
$TSEnvironment.Value("SMSTSBiosVersion") = $OSDBIOSVersion 

# Exit script. 
exit 0
