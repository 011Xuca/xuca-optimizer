@echo off
title Xuca Optimizer
rem Abre la app con casillas. Los .bat tambien se pueden usar solos.
if not exist "%~dp0XucaOP.ps1" goto falta
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0XucaOP.ps1"
exit /b
:falta
echo Falta XucaOP.ps1 en la misma carpeta que este archivo.
pause
exit /b