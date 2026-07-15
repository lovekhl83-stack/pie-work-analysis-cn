Set fso   = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

src  = fso.GetParentFolderName(WScript.ScriptFullName) & "\PIE.html"
desk = shell.SpecialFolders("Desktop")
dst  = desk & "\PIE.html"

If Not fso.FileExists(src) Then
    MsgBox "PIE.html not found." & Chr(13) & "Place install.vbs and PIE.html in the same folder.", 16, "PIE Setup Error"
    WScript.Quit
End If

fso.CopyFile src, dst, True

MsgBox "PIE installed successfully!" & Chr(13) & Chr(13) & _
    "PIE.html copied to your Desktop." & Chr(13) & _
    "Double-click PIE.html to launch." & Chr(13) & Chr(13) & _
    "A license key is required on first launch." & Chr(13) & _
    "Contact: lovekhl83@gmail.com", 64, "PIE Setup"

shell.Run "explorer.exe /select," & Chr(34) & dst & Chr(34)
