Connect-ConfigMgr

$PCNames = Get-Content C:\Temp\PCList\List.txt
$NotFound = "Device Not Found in SCCM"
$OutFile = "C:\Temp\PCList\OutFile.txt"

foreach ($PCName in $PCNames) 
    {
        
        $Results = Get-CMDevice -name $PCName | Select-Object LastLogonTimestamp, LastLogonUserName

            if ($Results) {$Results ="$PCName,$Results" }
            if (!$Results) {$Results = "$PCName,$NotFound"} 
            if ($OutFile) {Add-Content $OutFile $Results}
    }