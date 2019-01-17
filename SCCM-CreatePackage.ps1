$Make = 'Dell'
$Model = 'Latitude E6430'
$BIOSVer = 'A22'
$BIOSVerDir = $BIOSVer -replace '\.', '-'
$BIOSUpdateRoot = "\\prmwntuf\Sources\OSD\DriverAutomationTool\Downloads\$Make\$Model\BIOS\$BIOSVerDir"
$BIOSUpdatePackage = ("BIOS Update - " + "$Make" + " " + $Model)

$SiteCode = 'CE1' 
$SiteServer  = 'brcwntrm.ce.corp.com'
$global:VendorBIOSFolder = ($SiteCode + ":" + "\Package" + "\BIOS Packages" + "\$Make")

$CurrentBIOSPackage = Get-CMPackage -Name $BIOSUpdatePackage | Select-Object PackageID, Version, Name | Where-Object { $_.Version -eq $BIOSVer }
if (![string]::IsNullOrEmpty($CurrentBIOSPackage.Version)) 
{
    Write-Host "Package already exists"
}
else
{
    New-CMPackage -Name "$BIOSUpdatePackage" -Path "$BIOSUpdateRoot" -Description "$Make $Model BIOS Update" -Manufacturer "$Make" -Language English -version $BIOSVer
    $SCCMPackage = Get-CMPackage -Name $BIOSUpdatePackage | Select-Object PackageID, Version, Name | Where-Object { $_.Version -eq $BIOSVer } 
    Move-CMObject -FolderPath $global:VendorBIOSFolder -ObjectID $SCCMPackage.PackageID
}