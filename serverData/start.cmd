echo off
powershell "D:\Fivem-stuff\Files\ProjectNmsh\Artifacts\FXServer.exe +exec server.cfg +set onesync on +set sv_enforceGameBuild 2372| tee ConsoleLogs\console_$(Get-Date -f yyyy-MM-dd-HHmm).log

