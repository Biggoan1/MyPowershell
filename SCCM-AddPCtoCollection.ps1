Connect-ConfigMgr

$VDINames = Get-Content "C:\Temp\VDIMoveList.txt"

foreach ($VDIName in $VDINames) 
    {
        $ResourceID = (Get-CMDevice -Name $VDIName).ResourceID
        If ($ResourceID) 
            {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName "RAD Win7 Move" -ResourceId $ResourceID
            }
    }