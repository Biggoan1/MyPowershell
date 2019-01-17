$O365Grace = cscript.exe "C:\Program Files (x86)\Microsoft Office\Office16\OSPP.VBS" /dstatus | Select-Object -ExpandProperty "REMAINING GRACE: "





