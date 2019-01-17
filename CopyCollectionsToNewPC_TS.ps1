
$SiteServer = "prmwntu2"
$SiteCode = "CE1"

Import-Module 'C:\WIndows\Corp\Modules\WriteLog'
Import-Module -Name "$(split-path $Env:SMS_ADMIN_UI_PATH)\ConfigurationManager.psd1"

#Get TS Machine Info
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
Write-Log "Successfully initiaed Task Sequence Variable"
$ReferenceMachine = $tsenv.Value("OldPCTag")
Write-Log "OldPCTag : $ReferenceMachine"
$ReplacementMachine = $tsenv.Value("OSDComputerName")
Write-Log "newpctag : $ReplacementMachine"

$location = $SiteCode + ":"

Set-Location -Path $location

if(Get-CMDevice -Name $ReferenceMachine){
    if(Get-CMDevice -Name $ReferenceMachine){
        $ReplacementID = (Get-CMDevice -Name $ReplacementMachine).ResourceID
        $ResID = (Get-CMDevice -Name $ReferenceMachine).ResourceID
        Get-WmiObject -ComputerName $SiteServer -Class sms_fullcollectionmembership -Namespace root\sms\site_$SiteCode -Filter "ResourceID = '$($ResID)'"  | % {
            if(Get-CMDeviceCollectionDirectMembershipRule -CollectionID $_.CollectionID -ResourceName $ReferenceMachine){
                Write-Log "adding" $ReplacementMachine "to collection" $_.CollectionID
                Add-CMDeviceCollectionDirectMembershipRule -CollectionId $_.CollectionID -ResourceId $ReplacementID
            }
        }
    }
    else {
        Write-Log "Error. Unknown replacement machine :" $ReplacementMachine
    }
}
else {
    Write-Log "Error. Unknown reference machine :" $ReferenceMachine
}

