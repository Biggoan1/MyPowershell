$SoftList = "Microsoft Visual C++", "Office"

foreach($i in $SoftList)
{
    $x = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | `
    select DisplayName, Publisher, InstallDate, UninstallString | Where-Object {$_.DisplayName -like $("$i*")}
    $x
}

foreach($i in $SoftList)
{
    $x = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | `
    select DisplayName, Publisher, InstallDate, UninstallString | Where-Object {$_.DisplayName -like $("$i*")}
    $x
}
