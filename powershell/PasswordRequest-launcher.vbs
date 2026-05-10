Dim objShell
Set objShell = CreateObject("Schedule.Service")
objShell.Connect
Dim objFolder
Set objFolder = objShell.GetFolder("\")
Dim objTask
Set objTask = objFolder.GetTask("PasswordRequest")
objTask.Run(Null)
Set objShell = Nothing
WScript.Echo "Request has sent out. Please wait for a password."
