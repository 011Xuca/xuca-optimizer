@echo off
title Xuca Optimizer
rem Abre la app con casillas. Los .bat tambien se pueden usar solos.
if not exist "%~dp0XucaOP.ps1" goto falta
set "XUCA_DIR=%~dp0."
rem Quita la marca de "descargado de internet" para que Windows no pregunte antes de abrir.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath $env:XUCA_DIR -File -Recurse | Unblock-File -ErrorAction SilentlyContinue"
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0XucaOP.ps1"
exit /b
:falta
echo Falta XucaOP.ps1 en la misma carpeta que este archivo.
pause
exit /b