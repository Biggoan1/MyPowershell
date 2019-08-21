# Setup the TSEnvironment for OSD
$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop

$Auth = netsh lan show interface | sls 'State' | ? { $_ -match 'Connected. Authentication succeeded.'}

if ($Auth -like "*Connected. Authentication succeeded.") 
    { 
        $TSEnvironment.Value("NACStatus") = $true 
    } 
else 
    { 
        $TSEnvironment.Value("NACStatus") = $false
    } 

