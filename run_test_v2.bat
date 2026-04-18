@echo off
chcp 65001 >nul
cd /d "D:\Hikayati.com"

echo Starting Hikayati tests - step 1/3: pub get
echo. > "D:\Hikayati.com\01_pubget.log"
flutter pub get > "D:\Hikayati.com\01_pubget.log" 2>&1
echo Done pub get.

echo Starting step 2/3: analyze
flutter analyze > "D:\Hikayati.com\02_analyze.log" 2>&1
echo Done analyze.

echo Starting step 3/3: test
flutter test > "D:\Hikayati.com\03_test.log" 2>&1
echo Done test.

echo All done. Check 01_pubget.log, 02_analyze.log, 03_test.log
echo. > "D:\Hikayati.com\DONE.flag"
