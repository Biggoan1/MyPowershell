$IPAddress = ""
$ServerName = ""
$IPAddress1 = ""
$ServerName1 = ""

Start-Process powershell -Verb runAs -ArgumentList '-NoProfile -command "& { ` 
    Add-content -path "C:\Windows\System32\drivers\etc\hosts" -value """$IPAddress `t $Servername""" ; ` 
    Add-content -path "C:\Windows\System32\drivers\etc\hosts" -value """$IPAddress1 `t $ServerName1"""}"'

