' start_server.vbs - Launch Python HTTP server without console window or stdin inheritance
Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "D:\dailylifeapp"
WshShell.Run "python.exe serve_clean.py", 0, False
