$WMIPath = "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass] $WMIPath
[Void]$SMSwmi.RepairClient()