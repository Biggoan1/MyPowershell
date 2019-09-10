#Set Content Source to Download from Microsoft
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -name RepairContentServerSource -Type dword -Value 2 

#Get RSAT Package Names
$Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"}

#Install RSAT Packages
foreach ($Item in $Install) 
    {
        $RsatItem = $Item.Name
        Write-Verbose -Verbose "Adding $RsatItem to Windows"
        Add-WindowsCapability -Online -Name $RsatItem
    }

#Clean Up
Remove-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -name RepairContentServerSource

#End