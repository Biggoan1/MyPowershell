###https://social.technet.microsoft.com/Forums/en-US/5ed76a6b-3021-4b2b-a815-cd0cf7a31bc3/the-content-replication-is-working-fine-in-general-however-for-few-packages-randomly-jobs-are-lost?forum=configmanagergeneral


function write-log($severity, $message) 
{
   switch ($severity) 
   {
      w 
      {
         # Warning
         Write-Output "$(get-date -uFormat "%d/%m/%Y %H:%M:%S") -W- $message" |Out-File "C:\Temp\SCCM\Log.log" -Append
         break
      }   
      e 
      {
         # Error
         Write-Output "$(get-date -uFormat "%d/%m/%Y %H:%M:%S") -E- $message" |Out-File "C:\Temp\SCCM\Log.log" -Append
         break
      }
      default 
      {
         # Information
         Write-Output "$(get-date -uFormat "%d/%m/%Y %H:%M:%S") -I- $message" |Out-File "C:\Temp\SCCM\Log.log" -Append
         break
      }
   }
}

$SCCMserver = "prmwntu2"
$SiteCode = "CE1"
$Goodflag = '16777281'
$badflag = '16908353'
$date1 = get-date -Format "dd-mm-yyyy"

try
{
$myPackages = Get-WmiObject -ComputerName $SCCMserver -Namespace "root\SMS\Site_$($SiteCode)" -Query "SELECT *  FROM SMS_PackageBaseclass Where PkgFlags = '$badflag'"

write-log "i" "*********************************************************************"
write-log "i" "*********************************************************************"
write-log "i" "+++++++++++++++++++++++++++++++Script 1 Started at $date1 +++++++++++++++++++++++++++++++++++"

foreach($mypackage in $mypackages)
{
if($myPackage.PkgFlags -ne $Goodflag)
{
$myPackage.PkgFlags=$Goodflag
#$myPackage.Put()
write-log "i" "$myPackage.PackageID + "," + $myPackage.PkgFlags"
}
else
{
write-log "i" "$mypackage., No change required"
}
}
<#

$dps = Get-WmiObject -computer $SCCMserver -Namespace "root\SMS\Site_$($SiteCode)" -Query "Select * From SMS_DistributionDPStatus WHERE MessageState=4 OR MessageState=2"
"DP Name,Package ID,Error,Messagestate,Lastupdate,Ping" |out-file "C:\Temp\SCCM\$date1-Redistribution.csv" -Append

$dpignore = 0
foreach ($dp in $dps)
{
#$dn = $dp.Name
#$ping = test-connection $dn -count 1 -quiet
#$wmi = Test-WSMan -ComputerName $dn -ErrorAction SilentlyContinue
#if($wmi -or $ping) 
# {
$result="Online"
# } 
# else
# {
# $result="Offline"
# $dpignore= $dp.Name
# write-log "i" "$dp.Name,,,,,Offline"
#          }
          if ($result -eq "Online")
        {
        if(($dp.MessageState -eq 2) -or ($dp.MessageState -eq 4))
            {
            $dp.Name+","+$dp.PackageID+","+$dp.MessageID+","+$dp.MessageState+","+$dp.LastUpdateDate+",Online" |out-file "C:\Temp\SCCM\$date1-Redistribution.csv" -Append
            $PackageDP = Get-WmiObject -computer $SCCMserver -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_DistributionPoint -Filter "PackageID='$($dp.PackageID)' and ServerNALPath like '%$($dp.NALPath.Substring(12,13))%'"
            #$PackageDP.RefreshNow = $true
            #$PackageDP.Put() |Out-Null
            }
        }

}
#>
}
Catch
{
  write-log "e" "Exception Found"
  write-log "e"  $_.Exception.Message
}
write-log "i" "+++++++++++++++++++++++++++++++Script 1 Ended +++++++++++++++++++++++++++++++++++"
