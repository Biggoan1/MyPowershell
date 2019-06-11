#Extract Office Updates

$UpdatesPath = ""
$Updates = Get-ChildItem -Path $UpdatesPath -filter *.exe 
$PackagePath = ""

foreach($Update in $Updates)
    {
        $UpdatePath = $Update.FullName
        $UpdateName = $Update.BaseName
        $UpdateShortPath = $Update.PSParentPath

        Start-Process -FilePath $UpdatePath -ArgumentList "/extract:$UpdateName /q" -wait
        Move-Item -Path $UpdatePath -Destination $UpdateName
        Copy-Item -Path "$UpdateShortPath\$UpdateName\*.msp" -Destination $PackagePath
        Copy-Item -Path "$UpdateShortPath\$UpdateName\*.xml" -Destination $PackagePath
    }
