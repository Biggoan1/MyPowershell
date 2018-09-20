<#
.SYNOPSIS
Set PC Name During OSD

.DESCRIPTION
This script is intended to set the PC Name based on the asset tag info in BIOS or Prompt for PCName. 

Content source structure:

.EXAMPLE

.PARAMETER 

.NOTES
1.0 Initial Release 
#>

Function Load-Form 
{
    $Form.Controls.Add($TBComputerName)
    $Form.Controls.Add($GBComputerName)
    $Form.Controls.Add($ButtonOK)
    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()
}
 
Function Set-OSDComputerName 
{
        $ErrorProvider.Clear()
        if ($TBComputerName.Text.Length -eq 0) 
        {
            $ErrorProvider.SetError($GBComputerName, $OSDPromptValue)
        }

        elseif ($TBComputerName.Text.Length -gt 15) 
        {
            $ErrorProvider.SetError($GBComputerName, "Computer name cannot be more than 15 characters.")
        }

        #Validation Rule for computer names.
        elseif ($TBComputerName.Text -match "^[-_]|[^a-zA-Z0-9-_]")
        {
            $ErrorProvider.SetError($GBComputerName, "Computer name invalid, please correct the computer name.")
        }

        else 
        {
            $OSDComputerName = $TBComputerName.Text.ToUpper()
            $TSEnv.Value("OSDComputerName") = "$($OSDComputerName)"
            $Form.Close()
        }
}

# Setup the TSEnvironment for OSD
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Get the Asset Tag Info from WMI 
$OSDAsset = Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -ExpandProperty SMBIOSAssetTag 
$OSDVirtual = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer
$OSDVirtual1 = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
 
$Global:ErrorProvider = New-Object System.Windows.Forms.ErrorProvider

# Configure the form 
$Form = New-Object System.Windows.Forms.Form    
#$Form.Size = New-Object System.Drawing.Size(285,400)  
#$Form.MinimumSize = New-Object System.Drawing.Size(285,200)
#$Form.MaximumSize = New-Object System.Drawing.Size(2,200)
$Form.StartPosition = "CenterScreen"
$Form.SizeGripStyle = "Hide"
$Form.Text = "Enter Computer Info"
$Form.ControlBox = $false
$Form.TopMost = $true
$form.AutoSize = $true
 
$TBComputerName = New-Object System.Windows.Forms.TextBox
$TBComputerName.Location = New-Object System.Drawing.Size(30,40)
$TBComputerName.Size = New-Object System.Drawing.Size(215,50)
$TBComputerName.TabIndex = "1"
 
$GBComputerName = New-Object System.Windows.Forms.Label
$GBComputerName.Location = New-Object System.Drawing.Size(20,10)
$GBComputerName.Size = New-Object System.Drawing.Size(225,55)
$GBComputerName.Text = $OSDPromptValue
 
$ButtonOK = New-Object System.Windows.Forms.Button
$ButtonOK.Location = New-Object System.Drawing.Size(195,80)
$ButtonOK.Size = New-Object System.Drawing.Size(50,30)
$ButtonOK.Text = "OK"
$ButtonOK.TabIndex = "2"
$ButtonOK.Add_Click({Set-OSDComputerName})

$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter"){Set-OSDComputerName}})


# Run the script
if ($OSDAsset -eq $null -or $OSDAsset -eq "" -or $OSDVirtual -like "*VMWare*" -or $OSDVirtual1 -like "*Virtual Machine*") { $OSDPromptValue = "Please enter the asset tag number or computer name." ; Load-Form } `
    else { $TSEnv.Value("OSDComputerName") = "$($OSDAsset)" ; "$($OSDAsset)" }
