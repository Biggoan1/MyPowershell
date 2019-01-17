$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\All Users\Desktop\Error Logger.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Error Logger\CE.ErrorLogger.exe"
$Shortcut.Save()