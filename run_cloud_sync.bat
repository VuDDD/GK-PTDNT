@echo off
cd /d "%~dp0"
set TARGET_DEVICE=%~1
if "%TARGET_DEVICE%"=="" set TARGET_DEVICE=chrome

echo === 1. Dong bo du lieu tu may len Cloud Firestore (gk-ptdnt) ===
node sync_to_firebase.mjs
if errorlevel 1 (
  echo.
  echo Dong bo that bai. Kiem tra lai file serviceAccountKey.json hoac cau hinh Firebase.
  pause
  exit /b 1
)

echo.
echo === 2. Khoi chay ung dung Flutter tren %TARGET_DEVICE% ===
cd /d "%~dp0product_admin"
flutter run -d %TARGET_DEVICE%
