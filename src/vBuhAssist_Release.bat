@echo off

rem set BuildMode=Release
set BuildMode=Default

set PATH=C:\lazarus;C:\lazarus\fpc\3.2.2\bin\i386-win32;C:\Program Files\Utils;C:\Program Files\7-Zip;%PATH%
set App=vBuhAssist
RMDIR /S /Q _lib
call %App%_Rc.bat
lazbuild %App%.lpi --build-mode=%BuildMode%

set FileExe=%App%.exe
vAppUpd.exe --app_build=%FileExe% > %App%_ver.txt
set /p BUILD=<%App%_ver.txt
set FileArch=%App%_%BUILD%.exe.zip

upx.exe -5 %FileExe%
vAppUpd.exe --crc=%FileExe%
7z.exe a %FileArch% %FileExe%
rem wput.exe %FileArch% ftp://vladvons:19710819@oster.com.ua/www/download/public/update/vBuhAssist/
rem del %FileArch%
del %FileExe%
