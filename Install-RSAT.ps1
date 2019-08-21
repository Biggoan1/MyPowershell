$Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"}\
foreach ($Item in $Install) 
    {
        $RsatItem = $Item.Name
        Write-Verbose -Verbose "Adding $RsatItem to Windows"
        Add-WindowsCapability -Online -Name $RsatItem
    }
