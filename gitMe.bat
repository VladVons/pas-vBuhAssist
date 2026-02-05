@echo on
rem git config --global user.email "vladvons@gmail.com"
rem git config --global user.name "vladvons"

git status
git add .
set /p msg="Enter commit message: "
git commit -m "%msg%"
git push origin main
pause
