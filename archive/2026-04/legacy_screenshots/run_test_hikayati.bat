@echo off
chcp 65001 >nul
cd /d "D:\Hikayati.com"

set LOG=D:\Hikayati.com\test_results.log
echo ================================================== > "%LOG%"
echo Hikayati Test Run - %DATE% %TIME% >> "%LOG%"
echo ================================================== >> "%LOG%"

echo. >> "%LOG%"
echo ===== [1] flutter --version ===== >> "%LOG%"
flutter --version >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [2] dart --version ===== >> "%LOG%"
dart --version >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [3] flutter doctor -v ===== >> "%LOG%"
flutter doctor -v >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [4] flutter pub get ===== >> "%LOG%"
flutter pub get >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [5] flutter analyze ===== >> "%LOG%"
flutter analyze >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [6] flutter test ===== >> "%LOG%"
flutter test >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== [7] flutter build web (check build errors) ===== >> "%LOG%"
flutter build web --release >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ================================================== >> "%LOG%"
echo DONE. Output saved to %LOG% >> "%LOG%"
echo ================================================== >> "%LOG%"

echo.
echo Tests finished. Check test_results.log
pause
