set Ver=38
set FileArch=vBuhAssist_%Ver%.exe.zip

"C:\Program Files\Utils\upx.exe" -1 vBuhAssist.exe
vAppUpd.exe --crc=vBuhAssist.exe
"C:\Program Files\7-Zip\7z.exe" a %FileArch% vBuhAssist.exe
"C:\Program Files\Utils\wput.exe" %FileArch% ftp://vladvons:19710819@oster.com.ua/www/download/public/update/vBuhAssist/
del %FileArch%
