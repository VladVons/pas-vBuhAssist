set Ver=42
set FileExe=vBuhAssist.exe
set FileArch=vBuhAssist_%Ver%.exe.zip

"C:\Program Files\Utils\upx.exe" -5 %FileExe%
vAppUpd.exe --crc=%FileExe%
"C:\Program Files\7-Zip\7z.exe" a %FileArch% %FileExe%
"C:\Program Files\Utils\wput.exe" %FileArch% ftp://vladvons:19710819@oster.com.ua/www/download/public/update/vBuhAssist/
del %FileArch%
del %FileExe%
