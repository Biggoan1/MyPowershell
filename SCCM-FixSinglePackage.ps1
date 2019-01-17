
$GetPackageID = "PS100C1E"
# Packages to Skip 

$SCCMserver = "prmwntu2"
$SiteCode = "CE1"
$Goodflag = '16777281'
$badflag = '16908353'
$date1 = get-date -Format "dd-mm-yyyy"




$myPackage = Get-WmiObject -ComputerName $SCCMserver -Namespace "root\SMS\Site_$($SiteCode)" -Query "SELECT *  FROM SMS_PackageBaseclass Where PkgFlags = '$badflag' AND PackageID = '$GetPackageID'"

if($myPackage.PkgFlags -ne $Goodflag)
    {
        $myPackage.PkgFlags=$Goodflag
        $myPackage.Put()
        Get-Date
    }