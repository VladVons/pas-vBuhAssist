@echo off
rem git config --global user.email "vladvons@gmail.com"
rem git config --global user.name "vladvons"

rem git rm --cached vAppUpd.log
rem git rm --cached -r *.res
git rm --cached -r Data

git status
git add .
set /p msg="Enter commit message: "
git commit -m "%msg%"
rem git push origin main
rem git push origin main --force
pause
