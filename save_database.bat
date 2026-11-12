@echo off
cd /d "%~dp0"
echo Dang luu snapshot database Firebase Emulator vao .\emulator_data ...
npx firebase-tools emulators:export ./emulator_data --force
node sync_to_firebase.mjs --export-local-only
pause
