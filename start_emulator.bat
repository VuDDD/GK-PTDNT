@echo off
cd /d "%~dp0"
echo Dang khoi dong Firebase Emulator Suite voi du lieu luu vinh vien tai .\emulator_data ...
echo Nhan Ctrl+C de dung va tu dong luu moi thay doi vao o dia.
npx firebase-tools emulators:start --only auth,firestore,storage --import=./emulator_data --export-on-exit=./emulator_data

