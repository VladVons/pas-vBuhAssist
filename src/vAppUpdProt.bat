@echo off
set FileExe=vBuhAssist.exe
vAppUpd.exe --app_build=%FileExe% > ver_build.txt
set /p BUILD=<ver_build.txt
set FileArch=vBuhAssist_%BUILD%.exe.zip

"C:\Program Files\Utils\upx.exe" -5 %FileExe%
vAppUpd.exe --crc=%FileExe%
"C:\Program Files\7-Zip\7z.exe" a %FileArch% %FileExe%
"C:\Program Files\Utils\wput.exe" %FileArch% ftp://vladvons:19710819@oster.com.ua/www/download/public/update/vBuhAssist/
del %FileArch%
del %FileExe%
