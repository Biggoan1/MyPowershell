

#Copy stuff to a ps session
$TargetSession = New-PSSession -ComputerName
Copy-Item -ToSession $TargetSession -Path "C:\Users\Administrator\desktop\scripts\" -Destination "C:\Users\administrator.HALO\desktop\" -Recurse

#Copy stuff from a ps session

$SourceSession = New-PSSession -ComputerName 
Copy-Item -FromSession $SourceSession -Path "C:\Users\Administrator\desktop\scripts\" -Destination "C:\Users\administrator\desktop\" -Recurse
