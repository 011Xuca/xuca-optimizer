@echo off
title Brio
if not exist "%~dp0Brio.ps1" goto falta
"%SystemRoot%\System32\reg.exe" query HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine /v PowerShellVersion 2>nul | "%SystemRoot%\System32\find.exe" " 5." >nul || goto ps
start "" /min "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Brio.ps1"
exit /b
:ps
echo Falta PowerShell 5.1. En Windows 7 SP1 instala WMF 5.1: https://aka.ms/wmf51download
pause
exit /b
:falta
echo Falta Brio.ps1 al lado de este archivo.
pause
exit /b
