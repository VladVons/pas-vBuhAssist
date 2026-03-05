@echo off
set PATH=C:\lazarus;C:\lazarus\fpc\3.2.2\bin\i386-win32;%PATH%

set App=vBuhAssist

RMDIR /S /Q _lib
call %App%_Rc.bat
lazbuild %App%.lpi
rem lazbuild vBuhAssist.lpi --build-mode=Release

set FileExe=%App%.exe
vAppUpd.exe --app_build=%FileExe% > %App%_ver.txt
set /p BUILD=<%App%_ver.txt
set FileArch=%App%_%BUILD%.exe.zip

"C:\Program Files\Utils\upx.exe" -5 %FileExe%
vAppUpd.exe --crc=%FileExe%
"C:\Program Files\7-Zip\7z.exe" a %FileArch% %FileExe%
"C:\Program Files\Utils\wput.exe" %FileArch% ftp://vladvons:19710819@oster.com.ua/www/download/public/update/vBuhAssist/
rem del %FileArch%
del %FileExe%
