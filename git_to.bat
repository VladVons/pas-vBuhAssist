@echo on
rem git config --global user.email "vladvons@gmail.com"
rem git config --global user.name "vladvons"
rem git rm --cached src/*.dll

git status
git add .
set /p msg="Enter commit message: "
git commit -m "%msg%"
rem git push origin main
git push origin main --force
pause
