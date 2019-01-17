<#
.SYNOPSIS
Remove User Profiles

.DESCRIPTION
This script is intended to remove Windows user profiles. 

Content source structure:

.EXAMPLE

.PARAMETER 

.NOTES
1.0 Initial Release 

.Author 
John Dykstra

#>
Function Remove-Profile
    ([string]$UserName,[string]$RemoteComputerName,[string]$AllUsers)
{ 
<#
    Param
    (
        [Parameter(Mandaroty=$false)]
        [string] $UserName,
        [Parameter(Mandaroty=$false)]
        [string] $RemoteComputerName,
        [Parameter(Mandaroty=$false)]
        [string] $AllUsers
        #[Parameter(Mandaroty=$false)]
        #[string] $StartDate

    )
#>
#If remote computer exists the run command on remote computer otherwise assume local computer
        if ($RemoteComputerName){$RemoteComputerName = $RemoteComputerName}else{$RemoteComputerName = $env:COMPUTERNAME}

#All Non-Admin Users
        if ($AllUsers)
            {
                if ($UserName){Write-Host 'Cannot select All Users and User Name at the same time.'| End}
                else{$Profiles = Get-WmiObject -Class Win32_UserProfile -ComputerName $RemoteComputerName | where {(!$_.special -and !$_.loaded)}}
                "Profiles set to remove:"
                $Multiple=$true
            }

#Specific User
        if ($UserName)
            {
                if($AllUsers){Write-Host 'Cannot select All Users and User Name at the same time.'|End}
                $Profile=Get-WmiObject -Class Win32_UserProfile -ComputerName $RemoteComputerName | where {($_.Localpath -like "*$UserName")}
                if ($Profile.Loaded){Write-Host "You can't delete a loaded profile. Please use a different user account."|End}
                elseif($Profile.Special){Write-Host "I can't delete Administrative profiles find a different way!"|End}
                else{$Multiple=$false}         
            }
        if ($Multiple) 
            {
                foreach ($Profile in $Profiles) 
                {
                    $Profile.LocalPath
                    $Profile | Remove-WmiObject
                }
            }
        Elseif (!$Multiple)
            {
                $Profile | Remove-WmiObject
            }      
}
