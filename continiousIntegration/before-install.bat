REM Install Internet Information Server (IIS).
REM c:\Windows\Sysnative\WindowsPowerShell\v1.0\powershell.exe -Command Import-Module -Name ServerManager
REM c:\Windows\Sysnative\WindowsPowerShell\v1.0\powershell.exe -Command Install-WindowsFeature Web-Server
C:\Installation\DocAuthority\uninstall.exe -dir c:\Installation\DocAuthority -q  -c -Vuninstall.force=true
rd /s /q "C:\Installation\DocAuthority"
rd /s /q "D:\da-data"
C:\Installation\bin\mysqladmin.exe -uroot -proot -f drop docauthority

