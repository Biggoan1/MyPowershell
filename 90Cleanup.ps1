$limit = (Get-Date).AddDays(-90)
$path = "C:\inetpub\logs\LogFiles\W3SVC1"

# Delete files older than the $limit.
Get-ChildItem -Path "C:\inetpub\logs\LogFiles\W3SVC1" -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt -90 } | Remove-Item -Force

# Delete any empty directories left behind after deleting the old files.
#Get-ChildItem -Path $path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
