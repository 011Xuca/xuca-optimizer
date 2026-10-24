@echo off
setlocal EnableExtensions
set "XUCA_SELF=%~f0"
rem Si el archivo quedo con saltos de linea de Linux (LF), cmd salta a etiquetas equivocadas: se corrige solo y se vuelve a abrir.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $f=$env:XUCA_SELF; $e=[Text.Encoding]::GetEncoding(28591); $t=$e.GetString([IO.File]::ReadAllBytes($f)); if ($t -match '(^|[^\r])\n') { [IO.File]::WriteAllText($f, ($t -replace '\r?\n', ([string][char]13 + [char]10)), $e); exit 9 }; exit 0 } catch { exit 0 }" >nul 2>&1
if errorlevel 9 "%~f0" %*
title Optimizacion para Gaming (Xuca)

:: ============================================================
::  OPTIMIZACION PARA GAMING
::  Compatible con Windows 11 v. 25H2
::  S = Si, N = No, R = Restaurar al valor por defecto de Windows.
::  Cada cambio se verifica y queda anotado en la carpeta "logs".
:: ============================================================

set "ARCHIVO=%~f0"
set "ACT="
set "SPI="
set "DX="
set "LOG="
set "BUILD=0"
set "STAMP=sin-fecha"
set "OPT_T=0"
set "OPT_F=0"
set "OPT_S=0"
set "OPT_P=0"
set "CHK="
set "RAMGB=0"
set "ESHDD=0"
set "VGAVISO="
set "VG_HECHO="

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Pidiendo permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

del /q "%TEMP%\xuca_info.txt" >nul 2>&1
set "ACT=INFO"
call :aplicar_ps
set "INFO="
if exist "%TEMP%\xuca_info.txt" set /p INFO=<"%TEMP%\xuca_info.txt"
set "PSMAL=0"
if not defined INFO set "PSMAL=1"
if defined INFO for /f "tokens=1-4" %%A in ("%INFO%") do (set "BUILD=%%A" & set "RAMGB=%%B" & set "ESHDD=%%C" & set "STAMP=%%D")
if %BUILD% EQU 0 for /f "tokens=3" %%V in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "BUILD=%%V"
if "%STAMP%"=="sin-fecha" set "STAMP=%date:/=-%_%time:~0,8%"
set "STAMP=%STAMP::=-%"
set "STAMP=%STAMP: =0%"

set "ESC="
set "C_OK="
set "C_ERR="
set "C_WARN="
set "C_TIT="
set "C_RST="
if %BUILD% GEQ 17763 for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if defined ESC set "C_OK=%ESC%[92m"
if defined ESC set "C_ERR=%ESC%[91m"
if defined ESC set "C_WARN=%ESC%[93m"
if defined ESC set "C_TIT=%ESC%[96m"
if defined ESC set "C_RST=%ESC%[0m"

set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%\" mkdir "%LOGDIR%" >nul 2>&1
if not exist "%LOGDIR%\" set "LOGDIR=%TEMP%"
set "LOG=%LOGDIR%\optimizacion_gaming_%STAMP%.txt"
set "ACT=HEADER"
call :aplicar_ps
call :log "INFO" "Inicio de optimizacion_gaming.bat"
if "%PSMAL%"=="1" call :log "ATENCION" "PowerShell no devolvio datos: puede estar bloqueado por el antivirus. Mira las lineas PS-ERROR"

del /q "%TEMP%\xuca_orig.txt" >nul 2>&1
set "ACT=ORIG_CHECK"
call :aplicar_ps
set "ORIGMSG="
if exist "%TEMP%\xuca_orig.txt" set /p ORIGMSG=<"%TEMP%\xuca_orig.txt"
if defined ORIGMSG set "ORIGMSG=%ORIGMSG:&= %"
if defined ORIGMSG set "ORIGMSG=%ORIGMSG:|= %"
if defined ORIGMSG set "ORIGMSG=%ORIGMSG:<= %"
if defined ORIGMSG set "ORIGMSG=%ORIGMSG:>= %"

cls
echo OPTIMIZACION PARA GAMING - build detectado: %BUILD%
if %BUILD% LSS 22000 echo Nota: esto esta pensado para Windows 11, en Windows 10 algunas opciones pueden no existir o fallar.
if defined ORIGMSG (
    echo.
    echo %C_WARN%AVISO: esta PC no parece tener una version original o estandar de Windows.%C_RST%
    echo %C_WARN%Motivo: %ORIGMSG%%C_RST%
    echo %C_WARN%En versiones recortadas, pirateadas o modificadas ^(Tiny11, AtlasOS, ReviOS y similares^) varias opciones de este script pueden fallar o no aplicar.%C_RST%
    call :log "ATENCION" "Posible Windows no original o version rara - %ORIGMSG%"
)
if "%PSMAL%"=="1" (
    echo.
    echo %C_ERR%AVISO: PowerShell no pudo ejecutar la parte avanzada del script en esta PC.%C_RST%
    echo %C_ERR%Puede ser el antivirus bloqueandolo. Muchas opciones van a fallar: mira el log.%C_RST%
)
echo.
echo Responde con S [Si], N [No] y, donde aparezca, R [Restaurar al valor por defecto].
echo Cada cambio se verifica y queda anotado en: %LOG%
echo.
if not defined XUCA_AUTO pause

echo.
echo.
echo %C_TIT%=== MOUSE ===%C_RST%

echo.
echo   Que hace: saca la aceleracion del mouse y el rastro, y deja la velocidad en el punto medio.
echo   A favor: el mismo movimiento de mano siempre mueve lo mismo: mejor punteria.
echo   En contra: en el escritorio el mouse puede sentirse distinto hasta que te acostumbras.
set "QID=ms"
set "Q=- Desea mouse competitivo? (Sin aceleracion ni rastro, velocidad media)"
call :askR
if errorlevel 3 goto ms_r
if errorlevel 2 goto ms_fin
call :opt_ini "Mouse competitivo"
set "DIF=0"
call :dif "HKCU\Control Panel\Mouse" "MouseSensitivity" "10" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseSpeed" "0" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseThreshold1" "0" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseThreshold2" "0" REG_SZ
if "%DIF%"=="0" goto ms_ya
set "SPI=P:0x0071:10;M:0:0:0;U:0x0060:0;U:0x005D:0;P:0x1021:0;"
set "ACT=SPI"
call :aplicar_ps
call :resps
call :chk "HKCU\Control Panel\Mouse" "MouseSensitivity" "10"
call :chk "HKCU\Control Panel\Mouse" "MouseSpeed" "0"
call :chk "HKCU\Control Panel\Mouse" "MouseThreshold1" "0"
call :chk "HKCU\Control Panel\Mouse" "MouseThreshold2" "0"
call :opt_fin "Mouse en modo competitivo"
goto ms_fin
:ms_ya
set /a OPT_S+=1
call :opt_fin "Mouse en modo competitivo"
goto ms_fin
:ms_r
call :opt_ini "Mouse competitivo (restaurar)"
set "DIF=0"
call :dif "HKCU\Control Panel\Mouse" "MouseSensitivity" "10" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseSpeed" "1" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseThreshold1" "6" REG_SZ
call :dif "HKCU\Control Panel\Mouse" "MouseThreshold2" "10" REG_SZ
if "%DIF%"=="0" goto ms_r_ya
set "SPI=P:0x0071:10;M:6:10:1;U:0x0060:0;U:0x005D:0;P:0x1021:1;"
set "ACT=SPI"
call :aplicar_ps
call :resps
call :chk "HKCU\Control Panel\Mouse" "MouseSensitivity" "10"
call :chk "HKCU\Control Panel\Mouse" "MouseSpeed" "1"
call :chk "HKCU\Control Panel\Mouse" "MouseThreshold1" "6"
call :chk "HKCU\Control Panel\Mouse" "MouseThreshold2" "10"
call :opt_fin "Mouse restaurado a los valores de Windows"
goto ms_fin
:ms_r_ya
set /a OPT_S+=1
call :opt_fin "Mouse restaurado a los valores de Windows"
:ms_fin

echo.
echo.
echo %C_TIT%=== TECLADO ===%C_RST%

echo.
echo   Que hace: apretar Shift 5 veces ya no abre carteles de accesibilidad.
echo   A favor: no te saca del juego en medio de una partida.
echo   En contra: si usas Teclas especiales por accesibilidad, las activas a mano.
set "QID=tk"
set "Q=- Desea desactivar los avisos de Teclas especiales? (Shift x5 ya no abre carteles en partida)"
call :askR
if errorlevel 3 goto tk_r
if errorlevel 2 goto tk_fin
call :opt_ini "Teclas especiales"
call :reg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ 506
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" REG_SZ 122
call :reg "HKCU\Control Panel\Accessibility\ToggleKeys" "Flags" REG_SZ 58
call :opt_fin "Avisos de Teclas especiales desactivados"
goto tk_fin
:tk_r
call :opt_ini "Teclas especiales (restaurar)"
call :reg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ 510
call :reg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" REG_SZ 126
call :reg "HKCU\Control Panel\Accessibility\ToggleKeys" "Flags" REG_SZ 62
call :opt_fin "Avisos de Teclas especiales restaurados"
:tk_fin

echo.
echo.
echo %C_TIT%=== SONIDO ===%C_RST%

echo.
echo   Que hace: Windows deja de bajar el volumen del juego cuando hay una llamada, por ejemplo en Discord.
echo   A favor: el juego suena siempre igual.
echo   En contra: ninguno.
set "QID=du"
set "Q=- Desea que Windows no baje el volumen en llamadas? (Sonido, Comunicaciones: No hacer nada)"
call :askR
if errorlevel 3 goto du_r
if errorlevel 2 goto du_fin
call :opt_ini "Comunicaciones de Windows"
call :reg "HKCU\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" REG_DWORD 3
call :opt_fin "Windows ya no reduce el volumen de los demas sonidos (si no lo notas, reinicia)"
goto du_fin
:du_r
call :opt_ini "Comunicaciones de Windows (restaurar)"
call :reg "HKCU\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" REG_DWORD 1
call :opt_fin "Windows vuelve a reducir un 80 por ciento el resto de los sonidos"
:du_fin

echo.
echo.
echo %C_TIT%=== CPU Y PRIORIDAD ===%C_RST%

echo.
echo   Que hace: el programador multimedia de Windows le da mas prioridad a los juegos y saca el limite de red.
echo   A favor: un poco mas de CPU para el juego y menos tirones.
echo   En contra: el efecto es chico.
set "QID=mm"
set "Q=- Desea dar prioridad multimedia a los juegos? (Mas CPU para el juego; efecto chico)"
call :askR
if errorlevel 3 goto mm_r
if errorlevel 2 goto mm_fin
call :opt_ini "Prioridad multimedia (MMCSS)"
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" REG_DWORD 8
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" REG_DWORD 6
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" REG_SZ High
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" REG_SZ High
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 0xffffffff
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" REG_DWORD 10
call :opt_fin "Prioridad multimedia para juegos aplicada"
goto mm_fin
:mm_r
call :opt_ini "Prioridad multimedia (restaurar)"
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" REG_DWORD 8
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" REG_DWORD 2
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" REG_SZ Medium
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" REG_SZ Normal
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 10
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" REG_DWORD 20
call :opt_fin "Prioridad multimedia restaurada a los valores de Windows"
:mm_fin

echo.
echo   Prioridad alta para tus juegos:
echo   Que hace: cada vez que abris esos juegos, Windows les da mas tiempo de CPU que a lo que corre de fondo.
echo   A favor: menos tirones cuando tenes cosas abiertas atras, como Discord, el navegador u OBS.
echo   En contra: si el CPU llega al 100 por ciento, lo de fondo puede trabarse un poco (por ejemplo, el stream de OBS).
echo   Se escribe el nombre del proceso de cada juego, sin el .exe, separados por comas.
echo   El nombre lo ves con el juego abierto: Administrador de tareas, pestana Detalles.
set "QID=pri"
set "Q=- Desea dar prioridad alta a tus juegos? (Escribis sus procesos separados por comas; R se la quita a todos)"
call :askR
if errorlevel 3 goto pri_r
if errorlevel 2 goto pri_fin
call :opt_ini "Prioridad alta para juegos"
if not defined XUCA_AUTO set "PRIOJ="
if not defined XUCA_AUTO set /p "PRIOJ=  Procesos sin .exe, separados por comas: "
set "ACT=PRIO_ON"
call :aplicar_ps
call :resps
set "PRIOJ="
call :opt_fin "Prioridad alta aplicada (cerra y abri el juego para que la tome)"
goto pri_fin
:pri_r
call :opt_ini "Prioridad alta para juegos (restaurar)"
set "ACT=PRIO_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Los juegos vuelven a la prioridad normal"
:pri_fin

echo.
echo   Afinidad de CPU para tus juegos:
echo   Se detecta solo tu procesador y se elige lo mejor para cada tipo:
echo     - Intel con P-cores y E-cores: los juegos van a los P-cores, lo de fondo a los E-cores.
echo     - AMD con dos bloques grandes, por ejemplo X3D: los juegos van al bloque con mas cache, lo de fondo al otro.
echo     - Ryzen 1000, 2000 y 3000, con bloques chicos: Minecraft, Valorant y otros juegos livianos van a un solo bloque;
echo       los pesados usan todos los nucleos para no perder FPS.
echo     - Nucleos iguales: lo de fondo va al ultimo nucleo. Con 8 o mas nucleos el juego lo deja libre.
echo   Ya trae una lista de juegos: Marvel Rivals, Fortnite, CS2, Valorant, Warzone, Apex, Minecraft, ARK, Spider-Man, GTA V y mas.
echo   Lo de fondo solo se mueve mientras un juego esta abierto. Al cerrarlo, todo vuelve a usar todos los nucleos.
echo   OBS, Visual Studio, Unreal, Godot, servidores Java, el audio de Windows y los antitrampas nunca se tocan.
echo   Que hace: un programa chico en segundo plano pone tus juegos en los mejores nucleos y lleva Discord, Spotify y el navegador a otros.
echo   A favor: lo de fondo no le roba nucleos al juego: frametimes mas parejos y menos tirones, sobre todo en Minecraft.
echo   En contra: mientras jugas, lo de fondo anda un poco mas lento. Algunos antitrampas no dejan cambiar la afinidad del juego: en ese caso se saltea.
set "QID=afi"
set "Q=- Desea usar afinidad de CPU para tus juegos? (Juegos en los mejores nucleos y programas de fondo aparte; se detecta tu procesador)"
call :askR
if errorlevel 3 goto afi_r
if errorlevel 2 goto afi_fin
call :opt_ini "Afinidad de CPU para juegos"
if not defined XUCA_AUTO set "AFIJ="
if not defined XUCA_AUTO set "AFIF="
if not defined XUCA_AUTO set "AFIAPP="
set "AFIJT="
set "AFIJX="
set "AFIFT="
set "AFIFX="
echo.
set "ACT=AFI_INFO"
call :aplicar_ps
if errorlevel 2 goto afi_aplicar
if defined XUCA_AUTO goto afi_aplicar
echo.
echo   Para sacar o volver a poner uno, escribi su numero. Para agregar otro, escribi su proceso sin .exe
echo   ^(lo ves con el juego abierto: Administrador de tareas, pestana Detalles^).
set /p "AFIJT=  Numeros de juegos para marcar o desmarcar, separados por comas (Enter = dejar asi): "
set /p "AFIJX=  Juegos nuevos para agregar, separados por comas (Enter = ninguno): "
echo.
set "ACT=AFI_INFO_F"
call :aplicar_ps
echo.
set /p "AFIFT=  Numeros de programas para marcar o desmarcar, separados por comas (Enter = dejar asi): "
set /p "AFIFX=  Programas nuevos para agregar, separados por comas (Enter = ninguno): "
:afi_aplicar
set "ACT=AFI_ON"
call :aplicar_ps
call :resps
set "AFIJ="
set "AFIF="
set "AFIJT="
set "AFIJX="
set "AFIFT="
set "AFIFX="
call :opt_fin "Afinidad activa (si el juego ya estaba abierto, se aplica en unos segundos)"
goto afi_fin
:afi_r
call :opt_ini "Afinidad de CPU (restaurar)"
set "ACT=AFI_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Afinidad quitada: todo vuelve a usar todos los nucleos"
:afi_fin
echo.
echo.
echo %C_TIT%=== PLAN DE ENERGIA ===%C_RST%
echo.
echo %C_WARN%AVISO: el CPU deja de bajar frecuencia y voltaje: mas consumo y calor. Con undervolt, overclock, fuente o refrigeracion justas,%C_RST%
echo %C_WARN%la PC puede colgarse o reiniciarse sola al abrir juegos. Si te pasa, elegi R.%C_RST%
echo.
echo   Que hace: activa el plan de energia Alto rendimiento.
echo   A favor: el CPU responde mas rapido y no baja tanto la frecuencia.
echo   En contra: mas consumo y calor, sobre todo en notebook.
set "QID=pw"
set "Q=- Desea usar el plan Alto rendimiento? (Mas consumo y calor en notebook)"
call :askR
if errorlevel 3 goto pw_r
if errorlevel 2 goto pw_fin
call :opt_ini "Plan de energia"
powercfg /getactivescheme | find /i "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" >nul 2>&1
if not errorlevel 1 goto pw_ya
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 (
    powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)
call :planactivo "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
call :opt_fin "Plan Alto rendimiento activo"
goto pw_fin
:pw_ya
set /a OPT_S+=1
call :opt_fin "Plan Alto rendimiento activo"
goto pw_fin
:pw_r
call :opt_ini "Plan de energia (restaurar)"
powercfg /getactivescheme | find /i "381b4222-f694-41f0-9685-ff5bb260df2e" >nul 2>&1
if not errorlevel 1 goto pw_r_ya
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
call :planactivo "381b4222-f694-41f0-9685-ff5bb260df2e"
call :opt_fin "Plan Equilibrado activo"
goto pw_fin
:pw_r_ya
set /a OPT_S+=1
call :opt_fin "Plan Equilibrado activo"
:pw_fin

echo.
echo.
echo %C_TIT%=== PROCESADOR ===%C_RST%
echo.
echo Que hace cada ajuste, solo cuando la PC esta enchufada:
echo   - Nucleos siempre activos: Windows suele "dormir" nucleos que no usa y tarda un instante en despertarlos.
echo     Con todos despiertos hay menos tirones cuando el juego pide mas CPU de golpe.
echo   - Turbo al maximo: el procesador sube mas seguido y por mas tiempo por encima de su frecuencia base,
echo     lo que da mas FPS cuando el juego lo necesita.
echo   - Rendimiento al maximo: Windows prioriza la velocidad por sobre el ahorro de energia.
echo   - Frecuencia minima en 0: en reposo el procesador puede bajar su velocidad para no calentarse de mas.
echo     No limita el rendimiento cuando juegas.
echo.
echo %C_WARN%AVISO: a cambio hay un poco mas de consumo y calor, sobre todo en reposo.%C_RST%
echo.
echo   Que hace: deja todos los nucleos activos y el turbo y el rendimiento al maximo, solo con la PC enchufada.
echo   A favor: menos tirones cuando el juego pide mas CPU de golpe.
echo   En contra: un poco mas de consumo y calor.
set "QID=cpu"
set "Q=- Desea dejar el procesador como QuickCPU? (Nucleos siempre activos, turbo y rendimiento al maximo, solo con corriente)"
call :askR
if errorlevel 3 goto cpu_r
if errorlevel 2 goto cpu_fin
call :opt_ini "Procesador como QuickCPU"
set "ACT=CPU_ON"
call :aplicar_ps
call :resps
call :opt_fin "Procesador como QuickCPU: nucleos 100, frecuencia 0, turbo 100, rendimiento 100 (con corriente)"
goto cpu_fin
:cpu_r
call :opt_ini "Procesador como QuickCPU (restaurar)"
set "ACT=CPU_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Procesador restaurado a tus valores anteriores"
:cpu_fin

echo.
echo.
echo %C_TIT%=== MODO JUEGO Y GAME BAR ===%C_RST%

echo.
echo   Que hace: activa el Modo Juego y evita que el boton Xbox del joystick abra la Game Bar.
echo   A favor: Windows prioriza el juego y frena actualizaciones mientras jugas.
echo   En contra: ninguno importante.
set "QID=gm"
set "Q=- Desea activar el Modo Juego? (Y evitar que el joystick abra la Game Bar)"
call :askR
if errorlevel 3 goto gm_r
if errorlevel 2 goto gm_fin
call :opt_ini "Modo Juego"
call :reg "HKCU\Software\Microsoft\GameBar" "AutoGameModeEnabled" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\GameBar" "AllowAutoGameMode" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" REG_DWORD 0
call :reg "HKCU\Software\Microsoft\GameBar" "GamepadNexusChordEnabled" REG_DWORD 0
call :opt_fin "Modo Juego activo y Game Bar sin atajo del joystick"
goto gm_fin
:gm_r
call :opt_ini "Modo Juego (restaurar)"
call :reg "HKCU\Software\Microsoft\GameBar" "AutoGameModeEnabled" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\GameBar" "AllowAutoGameMode" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\GameBar" "GamepadNexusChordEnabled" REG_DWORD 1
call :opt_fin "Modo Juego y Game Bar restaurados"
:gm_fin

echo.
echo   Que hace: borra la app Xbox Game Bar y apaga sus grabaciones.
echo   A favor: menos procesos y nada grabando de fondo.
echo   En contra: perdes las capturas y clips de Windows; podes usar NVIDIA, AMD u OBS.
set "QID=xb"
set "Q=- Desea borrar la app Xbox Game Bar? (No toca los servicios de Xbox que usan los juegos)"
call :askR
if errorlevel 3 goto xb_r
if errorlevel 2 goto xb_fin
call :opt_ini "Xbox Game Bar"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" REG_DWORD 0
call :reg "HKCU\System\GameConfigStore" "GameDVR_Enabled" REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" REG_DWORD 0
for %%P in (ms-gamingoverlay ms-gamebar ms-gamebarservices) do call :protocolo "%%P"
set "ACT=GAMEBAR_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Xbox Game Bar borrada"
goto xb_fin
:xb_r
call :opt_ini "Xbox Game Bar (restaurar)"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" REG_DWORD 1
call :reg "HKCU\System\GameConfigStore" "GameDVR_Enabled" REG_DWORD 1
call :regdel "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR"
for %%P in (ms-gamingoverlay ms-gamebar ms-gamebarservices) do call :protodel "%%P"
set "ACT=GAMEBAR_ON"
call :aplicar_ps
call :resps
call :opt_fin "Xbox Game Bar restaurada. Si no vuelve, instalala desde la Microsoft Store"
:xb_fin

echo.
echo   Que hace: apaga los avisos emergentes y el Centro de notificaciones.
echo   A favor: nada te tapa la pantalla en partida.
echo   En contra: no ves avisos de apps como Discord o el correo.
set "QID=notif"
set "Q=- Desea desactivar las notificaciones de Windows? (Apaga los avisos emergentes y el Centro de notificaciones)"
call :askR
if errorlevel 3 goto notif_r
if errorlevel 2 goto notif_fin
call :opt_ini "Notificaciones de Windows"
call :reg "HKCU\Software\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter" REG_DWORD 1
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" REG_DWORD 0
call :opt_fin "Notificaciones desactivadas (se aplica al reiniciar el Explorador o la PC)"
goto notif_fin
:notif_r
call :opt_ini "Notificaciones de Windows (restaurar)"
call :regdel "HKCU\Software\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter"
call :regdel "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled"
call :opt_fin "Notificaciones restauradas (se aplica al reiniciar el Explorador o la PC)"
:notif_fin

echo.
echo.
echo %C_TIT%=== GRAFICOS ===%C_RST%

echo.
echo   Que hace: usa el modo moderno para juegos en ventana y activa la GPU acelerada por hardware.
echo   A favor: menos latencia en ventana y sin bordes, y hace falta para Frame Generation.
echo   En contra: en algunas PCs viejas puede dar problemas; R lo vuelve atras.
set "QID=gf"
set "Q=- Desea optimizar juegos en ventana y GPU por hardware? (Menos latencia; pide reiniciar)"
call :askR
if errorlevel 3 goto gf_r
if errorlevel 2 goto gf_fin
call :opt_ini "Graficos"
set "DX=SwapEffectUpgradeEnable=1;"
set "ACT=DX"
call :aplicar_ps
call :resps
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" REG_DWORD 2
call :opt_fin "Juegos en ventana optimizados y GPU acelerada por hardware (se aplica al reiniciar)"
goto gf_fin
:gf_r
call :opt_ini "Graficos (restaurar)"
set "DX=SwapEffectUpgradeEnable=DEL;"
set "ACT=DX"
call :aplicar_ps
call :resps
call :regdel "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
call :opt_fin "Graficos restaurados (se aplica al reiniciar)"
:gf_fin

echo.
echo   Que hace: desactiva MPO, una funcion de la pantalla que superpone imagenes.
echo   A favor: arregla parpadeos, pantallas negras y cursor invisible en algunas PCs.
echo   En contra: si no tenias esos problemas, puede subir un poco el uso de la GPU en ventana.
set "QID=mpo"
set "Q=- Desea desactivar MPO? (Evita parpadeos y cursor invisible; pide reiniciar)"
call :askR
if errorlevel 3 goto mpo_r
if errorlevel 2 goto mpo_fin
call :opt_ini "MPO"
call :reg "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" REG_DWORD 5
call :opt_fin "MPO desactivado (se aplica al reiniciar)"
goto mpo_fin
:mpo_r
call :opt_ini "MPO (restaurar)"
call :regdel "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"
call :opt_fin "MPO restaurado (se aplica al reiniciar)"
:mpo_fin

echo.
echo   Modo MSI en la placa de video y la de red:
echo   Que hace: las placas le avisan al procesador con mensajes ^(MSI^) en vez de usar la linea compartida vieja.
echo   A favor: un poco menos de latencia y de microtirones. Muchas placas nuevas ya vienen asi, en ese caso no cambia nada.
echo   En contra: si el driver no lo soporta bien, al reiniciar podes ver pantalla negra o quedarte sin internet.
echo   Si te pasa: entra en Modo seguro y corre el script con R, o usa un punto de restauracion.
set "QID=msi"
set "Q=- Desea activar el modo MSI en la placa de video y la de red? (Menos latencia; pide reiniciar)"
call :askR
if errorlevel 3 goto msi_r
if errorlevel 2 goto msi_fin
call :opt_ini "Modo MSI"
set "ACT=MSI_ON"
call :aplicar_ps
call :resps
call :opt_fin "Modo MSI activado (se aplica al reiniciar)"
goto msi_fin
:msi_r
call :opt_ini "Modo MSI (restaurar)"
set "ACT=MSI_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Modo MSI vuelto a como estaba (se aplica al reiniciar)"
:msi_fin

echo.
echo   Que hace: apaga el Asistente de compatibilidad de programas.
echo   A favor: evita ventanas que te roban el foco en partida.
echo   En contra: no te avisa de problemas con programas viejos.
set "QID=pca"
set "Q=- Desea desactivar el Asistente de compatibilidad (PcaSvc)? (Evita ventanas de consola que roban el foco en partida; deja de avisar problemas de compatibilidad de programas viejos; pide reiniciar)"
call :askR
if errorlevel 3 goto pca_r
if errorlevel 2 goto pca_fin
call :opt_ini "Asistente de compatibilidad (PcaSvc)"
call :svc "PcaSvc" disabled 4
call :svcparar "PcaSvc"
call :opt_fin "Asistente de compatibilidad desactivado (se aplica al reiniciar)"
goto pca_fin
:pca_r
call :opt_ini "Asistente de compatibilidad (restaurar)"
call :svc "PcaSvc" delayed-auto 2
call :svcarrancar "PcaSvc"
call :opt_fin "Asistente de compatibilidad restaurado (inicio automatico retrasado)"
:pca_fin

echo.
echo.
echo %C_TIT%=== TEMPORIZADOR Y LATENCIA ===%C_RST%
echo.
echo %C_WARN%AVISO: el temporizador al minimo mantiene el CPU mas activo: mas consumo y calor (en notebook, mas bateria).%C_RST%
echo %C_WARN%Si la PC se cuelga o se reinicia sola en juegos, elegi R.%C_RST%
echo.
echo   Que hace: deja el temporizador de Windows fijo en 0.5 ms para todo el sistema.
echo   A favor: menos latencia y tiempos de frame mas parejos.
echo   En contra: mas consumo y calor, sobre todo en notebook.
set "QID=tr"
set "Q=- Desea fijar el temporizador del sistema en el minimo? (Siempre 0.5 ms; menos latencia y tirones)"
call :askR
if errorlevel 3 goto tr_r
if errorlevel 2 goto tr_fin
call :opt_ini "Temporizador al minimo"
set "ACT=TIMER_ON"
call :aplicar_ps
call :resps
call :opt_fin "Temporizador fijo en el minimo para todo el sistema (se aplica del todo al reiniciar)"
goto tr_fin
:tr_r
call :opt_ini "Temporizador (restaurar)"
set "ACT=TIMER_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Temporizador restaurado al valor por defecto de Windows"
:tr_fin

echo.
echo.
echo %C_TIT%=== LIMPIEZA DE RAM (STANDBY LIST) ===%C_RST%

echo.
echo   Que hace: vacia la memoria en espera cuando quedan menos de 1024 MB libres.
echo   A favor: evita tirones cuando la RAM se llena.
echo   En contra: lo que estaba guardado en cache se vuelve a leer del disco.
set "QID=ram"
set "Q=- Desea activar la limpieza automatica de RAM en espera? (Vacia el cache al bajar de 1024 MB libres)"
call :askR
if errorlevel 3 goto ram_r
if errorlevel 2 goto ram_fin
call :opt_ini "Limpieza de RAM automatica"
set "ACT=RAM_ON"
call :aplicar_ps
call :resps
call :opt_fin "Limpiador de RAM activado"
goto ram_fin
:ram_r
call :opt_ini "Limpieza de RAM (restaurar)"
set "ACT=RAM_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Limpiador de RAM desactivado"
:ram_fin

set "SMOK=1"
if %RAMGB% LSS 16 set "SMOK=0"
if "%ESHDD%"=="1" set "SMOK=0"
if "%SMOK%"=="1" goto sm_ask
echo.
echo %C_WARN%  SysMain/Prefetch se omite: hace falta 16 GB de RAM o mas y Windows en SSD o NVMe.%C_RST%
call :log "SALTADO" "SysMain/Prefetch: RAM %RAMGB% GB, disco HDD=%ESHDD%"
goto sm_fin
:sm_ask
echo.
echo   Que hace: apaga SysMain y Prefetch, que precargan programas en la RAM.
echo   A favor: deja mas RAM libre para el juego.
echo   En contra: algunos programas abren un poco mas lento la primera vez.
set "QID=sm"
set "Q=- Desea desactivar SysMain y Prefetch? (Deja la RAM libre; hace falta 16 GB y SSD)"
call :askR
if errorlevel 3 goto sm_r
if errorlevel 2 goto sm_fin
call :opt_ini "SysMain y Prefetch"
call :svc "SysMain" disabled 4
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" REG_DWORD 0
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" REG_DWORD 0
call :svcparar "SysMain"
call :opt_fin "SysMain y Prefetch desactivados"
goto sm_fin
:sm_r
call :opt_ini "SysMain y Prefetch (restaurar)"
call :svc "SysMain" auto 2
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" REG_DWORD 3
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" REG_DWORD 3
call :svcarrancar "SysMain"
call :opt_fin "SysMain y Prefetch restaurados"
:sm_fin

echo.
echo.
echo %C_TIT%=== ENERGIA Y RED ===%C_RST%
echo.
echo %C_WARN%AVISO: Si tienes dispositivos inalambricos (Bluetooth o 2.4 GHz), desactivar esto puede bajar la bateria mas rapido si no tienen un driver dedicado que los apague.%C_RST%
echo.
echo   Que hace: apaga el ahorro de energia de USB y PCI Express.
echo   A favor: evita microcortes del mouse y el teclado.
echo   En contra: mas consumo de bateria en notebook.
set "QID=pe"
set "Q=- Desea desactivar el ahorro de energia de USB y PCIe? (Evita microcortes de mouse y teclado)"
call :askR
if errorlevel 3 goto pe_r
if errorlevel 2 goto pe_fin
call :opt_ini "Ahorro de energia USB y PCIe"
set "ACT=PWR_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Ahorro de energia de USB y PCIe desactivado"
goto pe_fin
:pe_r
call :opt_ini "Ahorro de energia USB y PCIe (restaurar)"
set "ACT=PWR_ON"
call :aplicar_ps
call :resps
call :opt_fin "Ahorro de energia de USB y PCIe restaurado"
:pe_fin

echo.
echo %C_WARN%AVISO: En placas madre de baja calidad, desactivarlo puede provocar que se vaya el internet por exceso de carga de paquetes o problemas de saturacion.%C_RST%
echo %C_WARN%AVISO: la conexion puede cortarse unos segundos al aplicar.%C_RST%
echo.
echo   Que hace: apaga el ahorro de energia de la placa de red.
echo   A favor: menos picos de ping.
echo   En contra: un poco mas de consumo; en placas malas puede causar cortes, y R lo vuelve atras.
set "QID=nic"
set "Q=- Desea desactivar el ahorro de energia de la red? (Menos picos de ping; no toca Wake-on-LAN)"
call :askR
if errorlevel 3 goto nic_r
if errorlevel 2 goto nic_fin
call :opt_ini "Ahorro de energia de la placa de red"
set "ACT=NIC_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Ahorro de energia de la placa de red desactivado"
goto nic_fin
:nic_r
call :opt_ini "Ahorro de energia de la placa de red (restaurar)"
set "ACT=NIC_ON"
call :aplicar_ps
call :resps
call :opt_fin "Ahorro de energia de la placa de red restaurado"
:nic_fin

echo.
echo.
echo %C_TIT%=== DNS ===%C_RST%
echo.
echo   Prueba los DNS de Cloudflare, Google, Quad9 y OpenDNS desde tu conexion y deja el mas rapido.
echo   Tarda unos segundos. Sirve para resolver nombres mas rapido ^(login, matchmaking, web^); no baja el ping dentro de la partida.
echo %C_WARN%AVISO: la conexion puede cortarse unos segundos al aplicar.%C_RST%
echo.
echo   Que hace: mide Cloudflare, Google, Quad9 y OpenDNS desde tu conexion y pone el mas rapido.
echo   A favor: logins, matchmaking y paginas web cargan mas rapido.
echo   En contra: no baja el ping dentro de la partida.
set "QID=dns"
set "Q=- Desea cambiar el DNS por el mas rapido para tu conexion? (R vuelve al DNS que tenias)"
call :askR
if errorlevel 3 goto dns_r
if errorlevel 2 goto dns_fin
call :opt_ini "DNS mas rapido"
set "ACT=DNS_ON"
call :aplicar_ps
call :resps
call :opt_fin "DNS cambiado por el mas rapido (los tiempos de cada uno estan en el log)"
goto dns_fin
:dns_r
call :opt_ini "DNS (restaurar)"
set "ACT=DNS_OFF"
call :aplicar_ps
call :resps
call :opt_fin "DNS restaurado al que tenias antes"
:dns_fin

echo.
echo.
echo %C_TIT%=== SEGURIDAD (MAS RENDIMIENTO) ===%C_RST%
echo %C_WARN%AVISO: si tenes Riot Vanguard, se borra solo si una opcion de seguridad cambia algo de verdad (si ya la tenias asi, no se toca); se reinstala solo al abrir Valorant.%C_RST%
echo.
echo   Que hace: apaga la Integridad de memoria de Windows.
echo   A favor: mas FPS en algunos juegos.
echo   En contra: menos proteccion contra drivers maliciosos.
set "QID=mi"
set "Q=- Desea desactivar la Integridad de memoria? (Mas rendimiento, menos proteccion contra drivers maliciosos)"
call :askR
if errorlevel 3 goto mi_r
if errorlevel 2 goto mi_fin
call :opt_ini "Integridad de memoria"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" REG_DWORD 0
call :opt_fin "Integridad de memoria desactivada (se aplica al reiniciar)"
call :vanguard_check
goto mi_fin
:mi_r
call :opt_ini "Integridad de memoria (restaurar)"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" REG_DWORD 1
call :opt_fin "Integridad de memoria restaurada (se aplica al reiniciar)"
:mi_fin

set "ACT=AV_STATUS"
call :aplicar_ps
if errorlevel 10 (
    call :log "OMITIDO" "Antivirus liviano: el antivirus esta desactivado"
    echo %C_WARN%  Antivirus liviano se omite: el antivirus ya esta apagado.%C_RST%
    goto av_skip_avl
)

echo.
echo   Que hace: limita los analisis de Defender al 5 por ciento de CPU, con prioridad baja.
echo   A favor: los analisis no te bajan FPS.
echo   En contra: los analisis tardan mas en terminar.
set "QID=avl"
set "Q=- Desea que el antivirus use menos CPU? (Limita los analisis y sigue encendido)"
call :askR
if errorlevel 3 goto avl_r
if errorlevel 2 goto avl_fin
call :opt_ini "Antivirus liviano"
set "ACT=AV_LIGHT"
call :aplicar_ps
call :resps
call :opt_fin "Antivirus con menor impacto en la CPU"
goto avl_fin

:avl_r
call :opt_ini "Antivirus liviano (restaurar)"
set "ACT=AV_LIGHT_R"
call :aplicar_ps
call :resps
call :opt_fin "Antivirus con su limite de CPU original"
:avl_fin

:av_skip_avl

echo.
echo %C_WARN%AVISO: Riot recomienda dejar DEP, ASLR, SEHOP y heap en predeterminado para Valorant.%C_RST%
echo %C_WARN%Si da el error VAN9002 despues de esto, usa R.%C_RST%
echo.
echo   Que hace: apaga DEP, ASLR, SEHOP y la proteccion del heap; CFG queda activo.
echo   A favor: algo de rendimiento y menos cierres raros en juegos viejos.
echo   En contra: menos proteccion contra ataques, y Valorant puede dar el error VAN9002.
set "QID=ex"
set "Q=- Desea apagar la Proteccion contra vulnerabilidades? (DEP, ASLR, SEHOP y heap; el CFG queda activo)"
call :askR
if errorlevel 3 goto ex_r
if errorlevel 2 goto ex_fin
call :opt_ini "Proteccion contra vulnerabilidades"
set "ACT=EXPLOIT_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Proteccion contra vulnerabilidades apagada, CFG intacto (se aplica al reiniciar)"
call :vanguard_check
goto ex_fin
:ex_r
call :opt_ini "Proteccion contra vulnerabilidades (restaurar)"
set "ACT=EXPLOIT_ON"
call :aplicar_ps
call :resps
call :opt_fin "Proteccion contra vulnerabilidades restaurada (se aplica al reiniciar)"
:ex_fin

echo.
echo   Que hace: apaga la seguridad basada en virtualizacion.
echo   A favor: entre 5 y 10 por ciento mas de FPS.
echo   En contra: deja de andar WSL, Docker, Hyper-V y las maquinas virtuales.
set "QID=vbs"
set "Q=- Desea desactivar VBS? (5 a 10 por ciento mas en juegos; rompe Docker, WSL y Hyper-V)"
call :askR
if errorlevel 3 goto vbs_r
if errorlevel 2 goto vbs_fin
call :opt_ini "VBS"
echo   Revisando el estado de la virtualizacion, un momento...
set "ACT=VBS_FEATS_OFF"
call :aplicar_ps
call :resps
call :bcd hypervisorlaunchtype off
call :bcd vsmlaunchtype off
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "EnableVirtualizationBasedSecurity" REG_DWORD 0
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "LsaCfgFlags" REG_DWORD 0
call :opt_fin "VBS desactivado (se aplica al reiniciar)"
call :vanguard_check
goto vbs_fin
:vbs_r
call :opt_ini "VBS (restaurar)"
call :bcddel hypervisorlaunchtype
call :bcddel vsmlaunchtype
call :regdel "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity"
call :regdel "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "EnableVirtualizationBasedSecurity"
call :regdel "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "LsaCfgFlags"
call :opt_fin "VBS restaurado. Hyper-V y WSL, si los usabas, hay que volver a activarlos a mano"
:vbs_fin

echo.
echo.
echo %C_TIT%=== BUSQUEDA, ALMACENAMIENTO Y EXPLORADOR ===%C_RST%
echo.
echo.
echo   Que hace: apaga el indexado de archivos.
echo   A favor: libera disco y CPU.
echo   En contra: la busqueda del Inicio es mas lenta.
set "QID=wsr"
set "Q=- Desea desactivar Windows Search? (Sin indexado: libera disco y CPU, pero la busqueda del Inicio es mas lenta)"
call :askR
if errorlevel 3 goto wsr_r
if errorlevel 2 goto wsr_fin
call :opt_ini "Windows Search"
call :svc "WSearch" disabled 4
call :svcparar "WSearch"
call :opt_fin "Windows Search desactivado"
goto wsr_fin
:wsr_r
call :opt_ini "Windows Search (restaurar)"
call :svc "WSearch" delayed-auto 2
call :svcarrancar "WSearch"
call :opt_fin "Windows Search restaurado"
:wsr_fin

echo.
echo   Que hace: Windows deja de borrar archivos temporales por su cuenta.
echo   A favor: no borra nada solo mientras jugas.
echo   En contra: la limpieza la haces vos, por ejemplo con limpiar_cache.bat.
set "QID=stg"
set "Q=- Desea desactivar Storage Sense? (Windows deja de borrar archivos temporales por su cuenta)"
call :askR
if errorlevel 3 goto stg_r
if errorlevel 2 goto stg_fin
call :opt_ini "Storage Sense"
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" "AllowStorageSenseGlobal" REG_DWORD 0
call :opt_fin "Storage Sense desactivado"
goto stg_fin
:stg_r
call :opt_ini "Storage Sense (restaurar)"
call :regdel "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" "AllowStorageSenseGlobal"
call :opt_fin "Storage Sense restaurado"
:stg_fin

echo.
echo   Que hace: muestra el final del nombre de los archivos, como .exe o .txt.
echo   A favor: ves que tipo de archivo es y detectas virus disfrazados.
echo   En contra: ninguno.
set "QID=ext"
set "Q=- Desea mostrar las extensiones de los archivos? (Ves .exe, .bat, .txt al final del nombre)"
call :askR
if errorlevel 3 goto ext_r
if errorlevel 2 goto ext_fin
call :opt_ini "Extensiones de archivo"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" REG_DWORD 0
call :opt_fin "Extensiones de archivo visibles"
goto ext_fin
:ext_r
call :opt_ini "Extensiones de archivo (restaurar)"
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" REG_DWORD 1
call :opt_fin "Extensiones de archivo ocultas de nuevo"
:ext_fin

echo.
echo.
echo %C_TIT%=== AJUSTES EXTRA ===%C_RST%
echo.
echo.
echo   Que hace: baja de 400 a 0 ms la espera al abrir menus.
echo   A favor: Windows se siente mas rapido.
echo   En contra: ninguno.
set "QID=md"
set "Q=- Desea quitar el retraso de los menus? (Baja de 400 a 0 ms la espera al abrir menus; todo se siente mas rapido)"
call :askR
if errorlevel 3 goto md_r
if errorlevel 2 goto md_fin
call :opt_ini "Retraso de menus"
call :reg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ 0
call :opt_fin "Retraso de menus quitado (se aplica al volver a iniciar sesion)"
goto md_fin
:md_r
call :opt_ini "Retraso de menus (restaurar)"
call :reg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ 400
call :opt_fin "Retraso de menus restaurado"
:md_fin

echo.
echo   Que hace: Windows usa IPv4 antes que IPv6 cuando hay las dos.
echo   A favor: puede bajar la latencia con algunos servidores.
echo   En contra: casi ninguno; IPv6 sigue funcionando.
set "QID=v4"
set "Q=- Desea preferir IPv4 sobre IPv6? (Puede bajar la latencia en juegos; IPv6 sigue funcionando; pide reiniciar)"
call :askR
if errorlevel 3 goto v4_r
if errorlevel 2 goto v4_fin
call :opt_ini "IPv4 preferido"
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" REG_DWORD 32
call :opt_fin "IPv4 preferido (se aplica al reiniciar)"
goto v4_fin
:v4_r
call :opt_ini "IPv4 preferido (restaurar)"
call :regdel "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents"
call :opt_fin "IPv4 restaurado (se aplica al reiniciar)"
:v4_fin


echo.
echo.
echo %C_TIT%=== RESUMEN ===%C_RST%
set "NFALLO=0"
set "NATEN=0"
for /f %%N in ('find /c "[FALLO]" ^< "%LOG%"') do set "NFALLO=%%N"
for /f %%N in ('find /c "[ATENCION]" ^< "%LOG%"') do set "NATEN=%%N"
if %NFALLO% GTR 0 goto rsm_rojo
echo %C_OK%  Cambios que fallaron: %NFALLO%  -  Opciones con problemas: %NATEN%%C_RST%
goto rsm_fin
:rsm_rojo
echo %C_ERR%  Cambios que fallaron: %NFALLO%  -  Opciones con problemas: %NATEN%%C_RST%
:rsm_fin
echo   Log completo en: %LOG%
call :log "INFO" "Fin. Cambios fallidos: %NFALLO%, opciones con problemas: %NATEN%"

if not defined VGAVISO goto sin_aviso_vg
echo.
echo %C_WARN%OBLIGATORIO REINICIAR ANTES DE PODER JUGAR VALORANT YA QUE DESACTIVASTE LOS AJUSTES DE SEGURIDAD.%C_RST%
call :log "ATENCION" "Se desactivaron ajustes de seguridad: hay que reiniciar antes de jugar Valorant"
:sin_aviso_vg

set "Q=Desea abrir el log ahora?"
call :askS
if not errorlevel 2 start "" notepad "%LOG%"

set "Q=Desea reiniciar ahora? (Hace falta para aplicar algunos cambios)"
call :askS
if not errorlevel 2 (echo Reiniciando en 10 segundos... & shutdown /r /t 10) else (echo Reinicia cuando puedas. & if not defined XUCA_AUTO pause)
exit /b

:askR
if defined XUCA_AUTO goto ask_auto
echo.
choice /c SNR /n /m "%Q% [S] Si  [N] No  [R] Restaurar: "
set "RESP=%errorlevel%"
set "LET=N"
if "%RESP%"=="1" set "LET=S"
if "%RESP%"=="3" set "LET=R"
call :log "PREG" "%LET% - %Q:~0,80%"
exit /b %RESP%

:askS
if defined XUCA_AUTO goto ask_auto_s
echo.
choice /c SN /n /m "%Q% [S] Si  [N] No: "
set "RESP=%errorlevel%"
set "LET=N"
if "%RESP%"=="1" set "LET=S"
call :log "PREG" "%LET% - %Q:~0,80%"
exit /b %RESP%

rem Modo app: la respuesta viene en la variable XR_<id de la opcion> (S, N o R). Sin respuesta = N.
:ask_auto
set "LET="
if defined QID call set "LET=%%XR_%QID%%%"
set "QID="
if /i not "%LET%"=="S" if /i not "%LET%"=="R" set "LET=N"
set "RESP=2"
if /i "%LET%"=="S" set "RESP=1"
if /i "%LET%"=="R" set "RESP=3"
echo.
echo %Q% [%LET%]
call :log "PREG" "%LET% (app) - %Q:~0,80%"
exit /b %RESP%

:ask_auto_s
set "LET="
if defined QID call set "LET=%%XR_%QID%%%"
set "QID="
if /i not "%LET%"=="S" set "LET=N"
set "RESP=2"
if /i "%LET%"=="S" set "RESP=1"
echo.
echo %Q% [%LET%]
call :log "PREG" "%LET% (app) - %Q:~0,80%"
exit /b %RESP%

:aplicar_ps
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $t=[IO.File]::ReadAllText($env:ARCHIVO); $m='#'+'#PS'+'-INICIO'; $i=$t.LastIndexOf($m); Invoke-Expression $t.Substring($i+$m.Length) } catch { if ($env:LOG) { Add-Content -LiteralPath $env:LOG -Value ('[{0}] [PS-ERROR] {1} - {2}' -f (Get-Date -Format 'HH:mm:ss'), $env:ACT, ($_.Exception.Message -replace '\s+',' ')) }; exit 1 }"
set "PSRC=%errorlevel%"
set "ACT="
set "SPI="
set "DX="
set "CHK="
exit /b %PSRC%

:log
if not defined LOG goto :eof
>>"%LOG%" echo [%time:~0,8%] [%~1] %~2
goto :eof

:vanguard_check
rem Si ya se borro (o no estaba instalado) en una opcion anterior, no se vuelve a revisar ni a mostrar nada.
if defined VG_HECHO goto :eof
rem Si la opcion que se acaba de aplicar no cambio nada (ya estaba asi, no aplica o se omitio), Vanguard no se toca.
if %OPT_T% EQU 0 goto :eof
set "VGAVISO=1"
set "ACT=VANGUARD_CHECK"
call :aplicar_ps
if not errorlevel 10 (
    set "VG_HECHO=1"
    goto :eof
)
echo.
echo   Borrando Riot Vanguard y sus restos, un momento...
call :opt_ini "Riot Vanguard"
set "ACT=VANGUARD_OFF"
call :aplicar_ps
call :resps
call :opt_fin "Riot Vanguard borrado"
set "VG_HECHO=1"
goto :eof

:opt_ini
set "OPT_T=0"
set "OPT_F=0"
set "OPT_S=0"
set "OPT_P=0"
call :log "INFO" "== %~1"
goto :eof

:opt_fin
if %OPT_F% GTR 0 goto opt_mal
if %OPT_P% GTR 0 goto opt_pend
if %OPT_T% GTR 0 goto opt_ok
if %OPT_S% GTR 0 goto opt_ya
echo %C_WARN%  Omitido: no aplica en esta PC, no se cambio nada.%C_RST%
call :log "OMITIDO" "%~1 - no aplica en esta PC"
goto :eof
:opt_ok
echo %C_OK%  OK: %~1%C_RST%
call :log "LISTO" "%~1 - %OPT_T% cambios hechos y verificados, %OPT_S% ya estaban"
goto :eof
:opt_ya
echo %C_WARN%  Omitido: ya estaba asi, no se cambio nada.%C_RST%
call :log "LISTO" "%~1 - ya estaba todo aplicado"
goto :eof
:opt_pend
echo %C_WARN%  Pendiente: %~1%C_RST%
call :log "PENDIENTE" "%~1"
goto :eof
:opt_mal
echo %C_ERR%  ERROR: %~1 - fallaron %OPT_F% de %OPT_T% cambios, mira el log.%C_RST%
call :log "ATENCION" "%~1 - fallaron %OPT_F% de %OPT_T% cambios"
goto :eof

:res
if errorlevel 1 goto res_mal
set /a OPT_T+=1
call :log "OK" "%~1"
goto :eof
:res_mal
set /a OPT_T+=1
set /a OPT_F+=1
call :log "FALLO" "%~1"
goto :eof

:planactivo
powercfg /getactivescheme | find /i "%~1" >nul 2>&1
call :res "plan de energia activo %~1"
goto :eof

:resps
if errorlevel 6 goto resps_pend
if errorlevel 5 goto resps_ya
if errorlevel 2 goto resps_na
if errorlevel 1 goto resps_mal
set /a OPT_T+=1
goto :eof
:resps_pend
set /a OPT_P+=1
call :log "PENDIENTE" "queda un paso para despues"
goto :eof
:resps_ya
set /a OPT_S+=1
call :log "OK" "ya estaba asi, no se toco nada"
goto :eof
:resps_na
call :log "OMITIDO" "esta parte no aplica en esta PC"
goto :eof
:resps_mal
set /a OPT_T+=1
set /a OPT_F+=1
goto :eof

:leer
set "LINE="
set "REST="
set "VVAL="
set "VTIPO="
for /f "delims=" %%L in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /c:"REG_"') do set "LINE=%%L"
if not defined LINE goto :eof
if "%LINE:REG_DWORD=%"=="%LINE%" goto leer_sz
set "VTIPO=REG_DWORD"
set "REST=%LINE:*REG_DWORD=%"
goto leer_fin
:leer_sz
set "VTIPO=REG_SZ"
set "REST=%LINE:*REG_SZ=%"
:leer_fin
for /f "tokens=* delims= " %%V in ("%REST%") do set "VVAL=%%V"
goto :eof

:comparar
set "IGUAL=0"
if not defined VTIPO goto :eof
if not "%~2"=="" if /i not "%VTIPO%"=="%~2" goto :eof
if /i not "%VTIPO%"=="REG_DWORD" goto cmp_sz
set "VA=x"
set "VB=y"
set /a "VA=%VVAL%" 2>nul
set /a "VB=%~1" 2>nul
if "%VA%"=="%VB%" set "IGUAL=1"
goto :eof
:cmp_sz
if /i "%VVAL%"=="%~1" set "IGUAL=1"
goto :eof

:dif
call :leer "%~1" "%~2"
call :comparar "%~3" %~4
if "%IGUAL%"=="0" set "DIF=1"
goto :eof

:reg
call :leer "%~1" "%~2"
call :comparar "%~4" %~3
if "%IGUAL%"=="1" goto reg_ya
set /a OPT_T+=1
reg add "%~1" /v "%~2" /t %~3 /d "%~4" /f >nul 2>"%TEMP%\xuca_err.txt"
if not errorlevel 1 goto reg_ok
set /a OPT_F+=1
call :motivo
call :log "FALLO" "no se pudo escribir %~1 %~2 - %ERRMSG%"
goto :eof
:reg_ok
call :verif "%~1" "%~2" "%~4"
goto :eof
:reg_ya
set /a OPT_S+=1
call :log "OK" "ya estaba %~1 %~2 = %~4"
goto :eof

:motivo
set "ERRMSG=sin detalle"
if exist "%TEMP%\xuca_err.txt" set /p ERRMSG=<"%TEMP%\xuca_err.txt"
set "ERRMSG=%ERRMSG:&= %"
set "ERRMSG=%ERRMSG:|= %"
set "ERRMSG=%ERRMSG:<= %"
set "ERRMSG=%ERRMSG:>= %"
goto :eof

:regdel
reg query "%~1" /v "%~2" >nul 2>&1
if errorlevel 1 goto regdel_ya
set /a OPT_T+=1
reg delete "%~1" /v "%~2" /f >nul 2>&1
reg query "%~1" /v "%~2" >nul 2>&1
if errorlevel 1 (
    call :log "OK" "borrado %~1 %~2"
) else (
    set /a OPT_F+=1
    call :log "FALLO" "no se pudo borrar %~1 %~2"
)
goto :eof
:regdel_ya
set /a OPT_S+=1
call :log "OK" "ya no existia %~1 %~2"
goto :eof

:chk
set /a OPT_T+=1
call :verif "%~1" "%~2" "%~3"
goto :eof

:verif
call :leer "%~1" "%~2"
if not defined VTIPO goto verif_nolee
call :comparar "%~3"
if "%IGUAL%"=="1" goto verif_ok
set /a OPT_F+=1
call :log "FALLO" "valor distinto en %~1 %~2 - esperado %~3 y quedo %VVAL%"
goto :eof
:verif_nolee
set /a OPT_F+=1
call :log "FALLO" "no se pudo leer %~1 %~2"
goto :eof
:verif_ok
call :log "OK" "%~1 %~2 = %~3"
goto :eof

:svc
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1
if errorlevel 1 (
    call :log "OMITIDO" "el servicio %~1 no existe en esta PC"
    goto :eof
)
call :leer "HKLM\SYSTEM\CurrentControlSet\Services\%~1" "Start"
call :comparar "%~3" REG_DWORD
if "%IGUAL%"=="1" goto svc_ya
sc config "%~1" start= %~2 >nul 2>&1
set /a OPT_T+=1
call :verif "HKLM\SYSTEM\CurrentControlSet\Services\%~1" "Start" "%~3"
goto :eof
:svc_ya
set /a OPT_S+=1
call :log "OK" "el servicio %~1 ya estaba con inicio %~2"
goto :eof

:svcparar
sc query "%~1" 2>nul | find "RUNNING" >nul 2>&1
if errorlevel 1 goto :eof
sc stop "%~1" >nul 2>&1
call :log "INFO" "servicio %~1 detenido"
goto :eof

:svcarrancar
sc query "%~1" 2>nul | find "STOPPED" >nul 2>&1
if errorlevel 1 goto :eof
sc start "%~1" >nul 2>&1
call :log "INFO" "servicio %~1 iniciado"
goto :eof

:tarea
schtasks /query /tn "%~1" >nul 2>&1
if errorlevel 1 (
    call :log "OMITIDO" "la tarea no existe %~1"
    goto :eof
)
set "TDIS=0"
schtasks /query /tn "%~1" /xml 2>nul | find /i "<Enabled>false</Enabled>" >nul 2>&1 && set "TDIS=1"
if /i "%~2"=="disable" if "%TDIS%"=="1" goto tarea_ya
if /i "%~2"=="enable" if "%TDIS%"=="0" goto tarea_ya
schtasks /change /tn "%~1" /%~2 >nul 2>&1
call :res "tarea %~1 - %~2"
goto :eof
:tarea_ya
set /a OPT_S+=1
call :log "OK" "la tarea ya estaba en %~2: %~1"
goto :eof

:bcd
bcdedit /enum {current} 2>nul | findstr /i /r /c:"^%~1 *%~2 *$" >nul 2>&1
if not errorlevel 1 goto bcd_ya
bcdedit /set %~1 %~2 >nul 2>&1
bcdedit /enum {current} 2>nul | findstr /i /r /c:"^%~1 *%~2 *$" >nul 2>&1
call :res "bcdedit %~1 %~2"
goto :eof
:bcd_ya
set /a OPT_S+=1
call :log "OK" "bcdedit %~1 ya estaba en %~2"
goto :eof

:bcddel
bcdedit /enum {current} 2>nul | findstr /i /r /c:"^%~1 " >nul 2>&1
if errorlevel 1 goto bcddel_ya
bcdedit /deletevalue %~1 >nul 2>&1
bcdedit /enum {current} 2>nul | findstr /i /r /c:"^%~1 " >nul 2>&1
if errorlevel 1 (
    set /a OPT_T+=1
    call :log "OK" "bcdedit %~1 quitado"
) else (
    set /a OPT_T+=1
    set /a OPT_F+=1
    call :log "FALLO" "bcdedit %~1 sigue puesto"
)
goto :eof
:bcddel_ya
set /a OPT_S+=1
call :log "OK" "bcdedit %~1 ya no estaba puesto"
goto :eof

:protocolo
reg query "HKCR\%~1\shell\open\command" /ve 2>nul | find /i "systray.exe" >nul 2>&1
if not errorlevel 1 goto proto_ya
reg add "HKCR\%~1" /ve /d "URL:%~1" /f >nul 2>&1
call :res "protocolo %~1 - valor"
reg add "HKCR\%~1" /v "URL Protocol" /d "" /f >nul 2>&1
call :res "protocolo %~1 - URL Protocol"
reg add "HKCR\%~1\shell\open\command" /ve /d "%SystemRoot%\System32\systray.exe" /f >nul 2>&1
call :res "protocolo %~1 - comando"
goto :eof
:proto_ya
set /a OPT_S+=1
call :log "OK" "el protocolo %~1 ya estaba redirigido"
goto :eof

:protodel
reg query "HKCR\%~1" >nul 2>&1
if errorlevel 1 goto protodel_ya
set /a OPT_T+=1
reg delete "HKCR\%~1" /f >nul 2>&1
reg query "HKCR\%~1" >nul 2>&1
if errorlevel 1 (
    call :log "OK" "protocolo %~1 borrado"
) else (
    set /a OPT_F+=1
    call :log "FALLO" "no se pudo borrar el protocolo %~1"
)
goto :eof
:protodel_ya
set /a OPT_S+=1
call :log "OK" "el protocolo %~1 ya no existia"
goto :eof

exit /b

##PS-INICIO
$ErrorActionPreference = 'SilentlyContinue'
$code = 0
$chk = ($env:CHK -eq '1')

function Log($tag, $msg) {
    if ($env:LOG) { Add-Content -LiteralPath $env:LOG -Value ('[{0}] [{1}] {2}' -f (Get-Date -Format 'HH:mm:ss'), $tag, $msg) }
}
function Say($msg, $color) {
    if ($color) { Write-Host $msg -ForegroundColor $color } else { Write-Host $msg }
}

function Get-FeatMap {
    $m = @{}
    foreach ($f in @(Get-WindowsOptionalFeature -Online)) { $m[[string]$f.FeatureName] = [string]$f.State }
    return $m
}

function Test-AvOff {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ((-not $svc) -or ($svc.Status -ne 'Running')) { return $true }
    $s = Get-MpComputerStatus
    $m = Get-MpPreference
    return (($s.RealTimeProtectionEnabled -eq $false) -and ($s.BehaviorMonitorEnabled -eq $false) -and ($s.IoavProtectionEnabled -eq $false) -and ($s.OnAccessProtectionEnabled -eq $false) -and ($m.MAPSReporting -eq 0) -and ($m.EnableNetworkProtection -eq 0) -and ($m.EnableControlledFolderAccess -eq 0) -and ($m.PUAProtection -eq 0))
}

$dnsCand = [ordered]@{
    'Cloudflare' = @('1.1.1.1', '1.0.0.1')
    'Google'     = @('8.8.8.8', '8.8.4.4')
    'Quad9'      = @('9.9.9.9', '149.112.112.112')
    'OpenDNS'    = @('208.67.222.222', '208.67.220.220')
}

# ---------- Afinidad de CPU (opcion afi) ----------
# Catalogos predeterminados (proceso=Nombre; varios procesos del mismo juego van con |). La app tambien los lee de aca.
$afiJuegosCat = 'marvel-win64-shipping=Marvel Rivals; fortniteclient-win64-shipping=Fortnite; cs2=Counter-Strike 2; valorant-win64-shipping=Valorant; cod=Call of Duty / Warzone; r5apex|r5apex_dx12=Apex Legends; overwatch=Overwatch 2; rainbowsix=Rainbow Six Siege; tslgame=PUBG; league of legends=League of Legends; rocketleague=Rocket League; bf6=Battlefield 6; javaw=Minecraft Java (Lunar, Feather); minecraft.windows=Minecraft Bedrock; arkascended=ARK Survival Ascended; shootergame=ARK Survival Evolved; spider-man=Spider-Man Remastered; milesmorales=Spider-Man Miles Morales; spider-man2=Spider-Man 2; gta5|gta5_enhanced=GTA V; robloxplayerbeta=Roblox; cyberpunk2077=Cyberpunk 2077; rdr2=Red Dead Redemption 2; eldenring=Elden Ring'
$afiFondoCat = 'discord=Discord; spotify=Spotify; chrome=Google Chrome; msedge=Microsoft Edge; firefox=Firefox; opera=Opera / Opera GX; brave=Brave; steamwebhelper=Steam (tienda y ventanas); epicwebhelper=Epic Games (ventanas); onedrive=OneDrive; whatsapp=WhatsApp; telegram=Telegram; wallpaper32|wallpaper64=Wallpaper Engine'
# Juegos que usan pocos hilos y dependen de la latencia: en los Ryzen con bloques chicos van a un solo bloque.
$afiLivianos = @('javaw', 'minecraft.windows', 'valorant-win64-shipping', 'league of legends', 'rocketleague', 'robloxplayerbeta')
# Nunca se tocan: sistema, audio, antivirus y antitrampas, OBS, editores y compiladores.
$afiProhibidos = @('system', 'idle', 'registry', 'smss', 'csrss', 'wininit', 'winlogon', 'services', 'lsass', 'lsaiso', 'svchost', 'dwm', 'fontdrvhost', 'memory compression', 'audiodg', 'explorer', 'sihost', 'ctfmon', 'taskmgr', 'searchhost', 'startmenuexperiencehost', 'shellexperiencehost', 'textinputhost', 'runtimebroker', 'securityhealthservice', 'msmpeng', 'nissrv', 'vgc', 'vgtray', 'vgk', 'easyanticheat', 'easyanticheat_eos', 'beservice', 'faceit', 'faceitservice', 'devenv', 'msbuild', 'vbcscompiler', 'servicehub.host.dotnet.x64', 'code', 'rider64', 'shadercompileworker', 'resolve', 'blender', 'fmod studio', 'java', 'xucaafinidad', 'xucatimer', 'xucaram')

function Afi-Prohibido([string]$n) { return (($afiProhibidos -contains $n) -or ($n -like 'obs*') -or ($n -like 'unrealeditor*') -or ($n -like 'godot*') -or ($n -like 'unrealinsights*')) }
function Afi-Nombres([string]$txt) {
    $l = New-Object System.Collections.Generic.List[string]
    foreach ($e in ($txt -split ',')) {
        $n = ($e.Trim().Trim('"').Trim() -replace '(?i)\.exe$', '').ToLower()
        if (-not $n) { continue }
        if ($n -notmatch '^[^\\/:*?"<>|=]+$') { Log 'OMITIDO' ('nombre de proceso no valido: "' + $n + '"'); Say ('  "' + $n + '" no es un nombre de proceso valido, se salteo.') 'Yellow'; continue }
        if (Afi-Prohibido $n) { Log 'OMITIDO' ('"' + $n + '" no se toca para no romperlo'); Say ('  "' + $n + '" no se toca (sistema, OBS, editores, servidores Java o antitrampas), se salteo.') 'Yellow'; continue }
        $l.Add($n)
    }
    return @($l | Sort-Object -Unique)
}
function Afi-Config {
    $c = @{}
    $f = Join-Path $env:ProgramData 'XucaScripts\afinidad.txt'
    if (Test-Path -LiteralPath $f) { foreach ($l in @(Get-Content -LiteralPath $f)) { $i = $l.IndexOf('='); if ($i -gt 0) { $c[$l.Substring(0, $i)] = $l.Substring($i + 1) } } }
    return $c
}
# Lo que elegiste la vez anterior ('juegos' o 'apps'); $null si nunca se aplico (se usan todos los predeterminados).
function Afi-Actual([string]$clave) {
    $c = Afi-Config
    if (-not $c.ContainsKey('apps')) { return $null }
    if ($clave -eq 'juegos') { $t = ([string]$c['juegos']) + ',' + ([string]$c['livianos']) } else { $t = [string]$c['apps'] }
    return , @($t -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
# Arma la lista para elegir: el catalogo y, al final, los que agregaste vos. Marcado = elegido.
function Afi-Items([string]$cat, $actual) {
    $items = @()
    foreach ($e in ($cat -split ';')) {
        $i = $e.IndexOf('='); if ($i -lt 1) { continue }
        $pr = @($e.Substring(0, $i) -split '\|' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
        $items += [pscustomobject]@{ Procs = $pr; Nombre = $e.Substring($i + 1).Trim(); Marcado = $true }
    }
    if ($null -ne $actual) {
        foreach ($it in $items) { $it.Marcado = (@($it.Procs | Where-Object { $actual -contains $_ }).Count -gt 0) }
        $conocidos = @($items | ForEach-Object { $_.Procs })
        foreach ($pr in $actual) { if ($conocidos -notcontains $pr) { $items += [pscustomobject]@{ Procs = @($pr); Nombre = $pr; Marcado = $true } } }
    }
    return , $items
}
function Afi-MostrarItems($items, [string]$titulo) {
    Say ('  ' + $titulo + '  [X] = elegido') 'White'
    for ($i = 0; $i -lt $items.Count; $i++) {
        $m = ' '; if ($items[$i].Marcado) { $m = 'X' }
        Say ('   {0,2}. [{1}] {2,-32} {3}' -f ($i + 1), $m, $items[$i].Nombre, ('(' + ($items[$i].Procs -join ', ') + ')')) $null
    }
}
# Aplica los numeros que escribiste (marca o desmarca cada uno) y suma los procesos nuevos.
function Afi-Elegir([string]$cat, [string]$clave, [string]$cambios, [string]$extra) {
    $items = Afi-Items $cat (Afi-Actual $clave)
    foreach ($t in ([string]$cambios -split '[,;\s]+')) {
        $k = 0
        if ([int]::TryParse($t, [ref]$k) -and ($k -ge 1) -and ($k -le $items.Count)) { $items[$k - 1].Marcado = -not $items[$k - 1].Marcado }
    }
    $sel = @($items | Where-Object { $_.Marcado } | ForEach-Object { $_.Procs })
    return (($sel -join ',') + ',' + $extra)
}
function Afi-Bit([long]$m, [int]$i) { return (($m -band ([long]1 -shl $i)) -ne 0) }
function Afi-BitBajo([long]$m) { for ($i = 0; $i -lt 64; $i++) { if (Afi-Bit $m $i) { return $i } }; return 64 }
function Afi-Hilos([long]$m) { $c = 0; for ($i = 0; $i -lt 64; $i++) { if (Afi-Bit $m $i) { $c++ } }; return $c }
function Afi-Lista([long]$m) {
    $idx = @(); for ($i = 0; $i -lt 64; $i++) { if (Afi-Bit $m $i) { $idx += $i } }
    $partes = @(); $i = 0
    while ($i -lt $idx.Count) {
        $j = $i
        while (($j + 1 -lt $idx.Count) -and ($idx[$j + 1] -eq ($idx[$j] + 1))) { $j++ }
        if ($j -eq $i) { $partes += [string]$idx[$i] } else { $partes += ([string]$idx[$i] + '-' + [string]$idx[$j]) }
        $i = $j + 1
    }
    return ('CPU ' + ($partes -join ', '))
}

# Mira como es el procesador por dentro y decide que nucleos van para cada cosa.
#   Juego   = nucleos para los juegos normales.
#   Liviano = nucleos para los juegos de pocos hilos (Minecraft, Valorant...).
#   Fondo   = nucleos para los programas de fondo, solo mientras jugas.
function Afi-Plan {
    $r = [pscustomobject]@{ Ok = $false; Motivo = ''; Cpu = ''; Tipo = ''; Todo = [long]0; Juego = [long]0; Liviano = [long]0; Fondo = [long]0 }
    $csTopo = 'using System; using System.Collections.Generic; using System.Runtime.InteropServices; public class XucaPieza { public long Mascara; public int Grupo; public int Clase; public int Nivel; public long Cache; } public class XucaTopo { [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetLogicalProcessorInformationEx(int rel, IntPtr buf, ref uint len); public static List<XucaPieza> Leer(int rel) { List<XucaPieza> r = new List<XucaPieza>(); uint len = 0; GetLogicalProcessorInformationEx(rel, IntPtr.Zero, ref len); if (len == 0) return r; IntPtr buf = Marshal.AllocHGlobal((int)len); try { if (!GetLogicalProcessorInformationEx(rel, buf, ref len)) return r; long off = 0; while (off < len) { IntPtr p = new IntPtr(buf.ToInt64() + off); int tipo = Marshal.ReadInt32(p, 0); int size = Marshal.ReadInt32(p, 4); if (size <= 0) break; if (tipo == 0) { int gc = Marshal.ReadInt16(p, 30); if (gc < 1) gc = 1; for (int g = 0; g < gc; g++) { XucaPieza x = new XucaPieza(); x.Mascara = Marshal.ReadInt64(p, 32 + g * 16); x.Grupo = Marshal.ReadInt16(p, 40 + g * 16); x.Clase = Marshal.ReadByte(p, 9); r.Add(x); } } else if (tipo == 2) { int gc = Marshal.ReadInt16(p, 38); if (gc < 1) gc = 1; for (int g = 0; g < gc; g++) { XucaPieza x = new XucaPieza(); x.Mascara = Marshal.ReadInt64(p, 40 + g * 16); x.Grupo = Marshal.ReadInt16(p, 48 + g * 16); x.Nivel = Marshal.ReadByte(p, 8); x.Cache = (long)(uint)Marshal.ReadInt32(p, 12); r.Add(x); } } off += size; } } finally { Marshal.FreeHGlobal(buf); } return r; } }'
    $nucleos = @(); $l3 = @()
    try {
        if (-not ('XucaTopo' -as [type])) { Add-Type -TypeDefinition $csTopo -Language CSharp -ErrorAction Stop }
        $nucleos = @([XucaTopo]::Leer(0))
        $l3 = @([XucaTopo]::Leer(2) | Where-Object { $_.Nivel -eq 3 })
    } catch { Log 'FALLO' ('Leer el procesador: ' + $_.Exception.Message) }
    $r.Cpu = ([string](Get-CimInstance Win32_Processor | Select-Object -First 1).Name).Trim()
    if ($nucleos.Count -eq 0) { $r.Motivo = 'no se pudo leer como son los nucleos del procesador'; return $r }
    if (@($nucleos | Where-Object { $_.Grupo -ne 0 }).Count -gt 0) { $r.Motivo = 'el procesador tiene mas de 64 hilos y esta opcion no lo soporta'; return $r }
    $n = $nucleos.Count
    if ($n -lt 4) { $r.Motivo = ('el procesador tiene ' + $n + ' nucleos: no alcanza para separar el juego de lo de fondo'); return $r }
    $todo = [long]0; foreach ($c in $nucleos) { $todo = $todo -bor $c.Mascara }
    $r.Todo = $todo
    $ord = @($nucleos | Sort-Object { Afi-BitBajo $_.Mascara })
    # Regla para nucleos iguales: lo de fondo va al ultimo nucleo (a los 2 ultimos con 12 o mas).
    # Con 8 o mas, el juego deja ese nucleo libre. Con menos, el juego igual puede usarlo: nunca pierde potencia.
    $res = 1; if ($n -ge 12) { $res = 2 }
    $ultimo = [long]0; for ($i = $n - $res; $i -lt $n; $i++) { $ultimo = $ultimo -bor $ord[$i].Mascara }
    $clases = @($nucleos | ForEach-Object { $_.Clase } | Sort-Object -Unique)
    if ($clases.Count -gt 1) {
        # Intel hibrido: la clase mas alta son los P-cores (los rapidos).
        $max = ($clases | Measure-Object -Maximum).Maximum
        $pc = @($nucleos | Where-Object { $_.Clase -eq $max })
        $pm = [long]0; foreach ($c in $pc) { $pm = $pm -bor $c.Mascara }
        $r.Fondo = $todo -band (-bnot $pm)
        if ($pc.Count -ge 6) { $r.Juego = $pm; $r.Liviano = $pm; $r.Tipo = ('hibrido, ' + $pc.Count + ' P-cores y ' + ($n - $pc.Count) + ' E-cores: juegos en los P-cores') }
        elseif ($pc.Count -ge 4) { $r.Juego = $todo; $r.Liviano = $pm; $r.Tipo = ('hibrido, ' + $pc.Count + ' P-cores: los juegos pesados usan todo y los livianos solo los P-cores') }
        else { $r.Juego = $todo; $r.Liviano = $todo; $r.Tipo = ('hibrido, solo ' + $pc.Count + ' P-cores: los juegos usan todo y lo de fondo va a los E-cores') }
    } elseif ($l3.Count -gt 1) {
        # Varios bloques con su propia cache L3: el de mas cache (V-Cache en los X3D); si son iguales, el primero.
        $orden = @($l3 | Sort-Object @{ Expression = { $_.Cache }; Descending = $true }, @{ Expression = { Afi-BitBajo $_.Mascara }; Descending = $false })
        $bloque = $orden[0].Mascara -band $todo
        $nb = @($nucleos | Where-Object { ($_.Mascara -band $bloque) -ne 0 }).Count
        $vc = ($orden[0].Cache -gt $orden[1].Cache)
        if ($nb -ge 6) {
            $r.Juego = $bloque; $r.Liviano = $bloque; $r.Fondo = $todo -band (-bnot $bloque)
            if ($vc) { $r.Tipo = ($l3.Count.ToString() + ' bloques: juegos en el de V-Cache (' + [math]::Round($orden[0].Cache / 1MB) + ' MB de L3)') }
            else { $r.Tipo = ($l3.Count.ToString() + ' bloques de ' + $nb + ' nucleos: juegos en el primero') }
        } else {
            # Bloques chicos (Ryzen 1000, 2000 y 3000): pasar de un bloque a otro es lento.
            # Los juegos livianos van a un solo bloque; los pesados usan todos para no perder FPS.
            $primero = @($l3 | Sort-Object { Afi-BitBajo $_.Mascara })[0].Mascara -band $todo
            $r.Liviano = $primero; $r.Fondo = $ultimo
            if ($n -ge 8) { $r.Juego = $todo -band (-bnot $ultimo) } else { $r.Juego = $todo }
            if (($r.Liviano -band $r.Fondo) -ne 0) { $r.Liviano = $r.Juego }
            $r.Tipo = ($l3.Count.ToString() + ' bloques de ' + $nb + ' nucleos: livianos en el primer bloque, pesados en todos')
        }
    } else {
        $r.Fondo = $ultimo; $r.Liviano = $todo -band (-bnot $ultimo)
        if ($n -ge 8) { $r.Juego = $todo -band (-bnot $ultimo) } else { $r.Juego = $todo }
        $r.Tipo = ($n.ToString() + ' nucleos iguales en un solo bloque')
    }
    if (($r.Juego -eq 0) -or ($r.Fondo -eq 0) -or ($r.Liviano -eq 0)) { $r.Motivo = 'no se pudo separar los nucleos del procesador'; return $r }
    $r.Ok = $true
    return $r
}
function Afi-Mostrar($pl) {
    Say ('  Procesador: ' + $pl.Cpu + ' - ' + $pl.Tipo) 'Cyan'
    Say ('    Juegos:           ' + (Afi-Lista $pl.Juego) + ' (' + (Afi-Hilos $pl.Juego) + ' hilos)') 'Cyan'
    if ($pl.Liviano -ne $pl.Juego) { Say ('    Juegos livianos:  ' + (Afi-Lista $pl.Liviano) + ' (' + (Afi-Hilos $pl.Liviano) + ' hilos) - ' + ($afiLivianos -join ', ')) 'Cyan' }
    Say ('    Fondo:            ' + (Afi-Lista $pl.Fondo) + ' (' + (Afi-Hilos $pl.Fondo) + ' hilos), solo mientras jugas') 'Cyan'
}

switch ($env:ACT) {

    'INFO' {
        $os = Get-CimInstance Win32_OperatingSystem
        $bn = $os.BuildNumber
        if (-not $bn) { $bn = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber }
        $ram = 0
        try { $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB) } catch { }
        if (-not $ram) {
            try { Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop; $ram = [math]::Round((New-Object Microsoft.VisualBasic.Devices.ComputerInfo).TotalPhysicalMemory / 1GB) } catch { }
        }
        if (-not $ram) { $ram = 0 }
        $hdd = 0
        try {
            $d = Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1) -ErrorAction Stop | Get-Disk -ErrorAction Stop | Get-PhysicalDisk -ErrorAction Stop
            if ($d.MediaType -eq 'HDD') { $hdd = 1 }
        } catch { }
        $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
        Set-Content -Path (Join-Path $env:TEMP 'xuca_info.txt') -Value ('{0} {1} {2} {3}' -f $bn, $ram, $hdd, $stamp)
    }

    'HEADER' {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        $gpu = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join ' / '
        $ubr = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
        Log 'INFO' ('{0} (build {1}.{2})' -f $os.Caption, $os.BuildNumber, $ubr)
        Log 'INFO' ('CPU: ' + ([string]$cpu).Trim())
        Log 'INFO' ('GPU: ' + $gpu)
        Log 'INFO' ('RAM: {0} GB' -f $env:RAMGB)
        Log 'INFO' ('Usuario: {0} - Equipo: {1}' -f $env:USERNAME, $env:COMPUTERNAME)
    }

    'ORIG_CHECK' {
        $motivos = New-Object System.Collections.Generic.List[string]
        try {
            $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop | Select-Object -First 1
            if ($lic -and $lic.LicenseStatus -ne 1) { $motivos.Add('Windows no esta activado o la activacion no es valida') }
        } catch { }
        foreach ($sv in 'TrustedInstaller', 'wuauserv', 'WinDefend') {
            if (-not (Get-Service -Name $sv -ErrorAction SilentlyContinue)) { $motivos.Add('falta el servicio ' + $sv + ', tipico de versiones recortadas') }
        }
        if (-not (Get-AppxPackage -AllUsers -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue)) { $motivos.Add('no esta la Microsoft Store, tipico de versiones recortadas') }
        $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        $editOk = 'Core', 'CoreSingleLanguage', 'Professional', 'ProfessionalN', 'ProfessionalWorkstation', 'ProfessionalEducation', 'Enterprise', 'EnterpriseN', 'Education', 'EducationN', 'ServerStandard', 'ServerDatacenter', 'CloudEdition'
        if ($cv -and $cv.EditionID -and ($editOk -notcontains $cv.EditionID)) { $motivos.Add('edicion de Windows poco comun: ' + $cv.EditionID) }
        $sospechoso = 'tiny', 'atlas', 'revi', 'ghost', 'lite', 'mini', 'kernel', 'custom'
        $textoCv = (([string]$cv.RegisteredOwner) + ' ' + ([string]$cv.ProductName)).ToLower()
        foreach ($p in $sospechoso) {
            if ($textoCv.Contains($p)) { $motivos.Add('el nombre de edicion o el propietario registrado tiene palabras de versiones modificadas'); break }
        }
        $archivo = Join-Path $env:TEMP 'xuca_orig.txt'
        if ($motivos.Count -gt 0) {
            Set-Content -Path $archivo -Value (($motivos | Select-Object -Unique) -join ' - ')
            $code = 1
        } elseif (Test-Path $archivo) {
            Remove-Item $archivo -ErrorAction SilentlyContinue
        }
    }

    'FREE' {
        $mb = [math]::Round(([IO.DriveInfo]$env:SystemDrive).AvailableFreeSpace / 1MB)
        Set-Content -Path (Join-Path $env:TEMP 'xuca_free.txt') -Value $mb
    }

    'GAMEBAR_OFF' {
        $n = 'Microsoft.XboxGamingOverlay*'
        $pk = @(Get-AppxPackage -AllUsers -Name $n)
        if ($pk.Count -eq 0) {
            Log 'OK' 'ya estaba: la app Xbox Game Bar no esta instalada'
            $code = 5
        } else {
            foreach ($p in $pk) { try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop } catch { } }
            $quedan = @(Get-AppxPackage -AllUsers -Name $n).Count
            if ($quedan -eq 0) { Log 'OK' 'verificado: la app Xbox Game Bar se borro' }
            else { Log 'FALLO' 'la app Xbox Game Bar sigue instalada'; $code = 1 }
        }
    }

    'GAMEBAR_ON' {
        $n = 'Microsoft.XboxGamingOverlay*'
        if (@(Get-AppxPackage -AllUsers -Name $n).Count -gt 0) {
            Log 'OK' 'ya estaba: la app Xbox Game Bar esta instalada'
            $code = 5
        } else {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Say '  Instalando Xbox Game Bar con winget...'
                & winget install --id 9NZKPSTSNW4P --source msstore --accept-package-agreements --accept-source-agreements | Out-Null
                Log 'INFO' ('winget install Xbox Game Bar termino con codigo ' + $LASTEXITCODE)
            } else {
                Log 'FALLO' 'winget no esta disponible en esta PC'
            }
            if (@(Get-AppxPackage -AllUsers -Name $n).Count -gt 0) { Log 'OK' 'verificado: la app Xbox Game Bar esta instalada' }
            else { Log 'FALLO' 'la app Xbox Game Bar no quedo instalada, instalala desde la Microsoft Store'; $code = 1 }
        }
    }

    'DX' {
        $k = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
        if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        $actual = (Get-ItemProperty -Path $k -Name DirectXUserGlobalSettings).DirectXUserGlobalSettings
        $falta = $false
        foreach ($e in ($env:DX -split ';')) {
            if ($e -match '^(.+?)=(.*)$') {
                $nombre = $Matches[1]
                $valor = $Matches[2]
                $hay = (([string]$actual -split ';') -contains ($nombre + '=' + $valor))
                $existe = ((([string]$actual -split ';') | Where-Object { $_ -like ($nombre + '=*') }) | Measure-Object).Count -gt 0
                if ($valor -eq 'DEL') { if ($existe) { $falta = $true } }
                else { if (-not $hay) { $falta = $true } }
            }
        }
        if (-not $falta) {
            Log 'OK' 'ya estaba asi en DirectXUserGlobalSettings'
            $code = 5
        } else {
            $mapa = [ordered]@{}
            foreach ($e in (([string]$actual + ';' + $env:DX) -split ';')) {
                if ($e -match '^(.+?)=(.*)$') {
                    if ($Matches[2] -eq 'DEL') { $mapa.Remove($Matches[1]) } else { $mapa[$Matches[1]] = $Matches[2] }
                }
            }
            $nuevo = ($mapa.GetEnumerator() | ForEach-Object { '{0}={1};' -f $_.Key, $_.Value }) -join ''
            New-ItemProperty -Path $k -Name DirectXUserGlobalSettings -Value $nuevo -PropertyType String -Force | Out-Null
            $leido = (Get-ItemProperty -Path $k -Name DirectXUserGlobalSettings).DirectXUserGlobalSettings
            foreach ($e in ($env:DX -split ';')) {
                if ($e -match '^(.+?)=(.*)$') {
                    $nombre = $Matches[1]
                    $valor = $Matches[2]
                    $hay = (([string]$leido -split ';') -contains ($nombre + '=' + $valor))
                    $existe = ((([string]$leido -split ';') | Where-Object { $_ -like ($nombre + '=*') }) | Measure-Object).Count -gt 0
                    if ($valor -eq 'DEL') {
                        if (-not $existe) { Log 'OK' ('verificado: ' + $nombre + ' ya no esta en DirectXUserGlobalSettings') }
                        else { Log 'FALLO' ($nombre + ' sigue en DirectXUserGlobalSettings'); $code = 1 }
                    } else {
                        if ($hay) { Log 'OK' ('verificado: ' + $nombre + '=' + $valor + ' en DirectXUserGlobalSettings') }
                        else { Log 'FALLO' ($nombre + ' no quedo en DirectXUserGlobalSettings'); $code = 1 }
                    }
                }
            }
        }
    }

    { $_ -eq 'PWR_OFF' -or $_ -eq 'PWR_ON' } {
        $g = [regex]::Match((& powercfg /getactivescheme | Out-String), '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value
        if (-not $g) {
            Log 'FALLO' 'no se pudo leer el plan de energia activo'
            $code = 1
        } else {
            $usb = 0
            $pcie = 0
            if ($env:ACT -eq 'PWR_ON') {
                $usb = 1
                $pcie = 1
                if ($g -in '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c', 'e9a42b02-d5df-448d-aa00-03f14749eb61') { $pcie = 0 }
            }
            $cfg = @(
                @{ Nom = 'suspension selectiva USB'; Sub = '2a737441-1930-4402-8d77-b2bebba308a3'; Cfg = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'; Val = $usb },
                @{ Nom = 'ahorro de energia PCI Express'; Sub = '501a4d13-42af-4429-9fd1-a8218c268e20'; Cfg = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Val = $pcie }
            )
            $hizo = $false
            foreach ($c in $cfg) {
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $g + '\' + $c.Sub + '\' + $c.Cfg
                $ac = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).ACSettingIndex
                $dc = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).DCSettingIndex
                if (($ac -eq $c.Val) -and ($dc -eq $c.Val)) {
                    Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $c.Val + ' en el plan ' + $g)
                    continue
                }
                $hizo = $true
                & powercfg /setacvalueindex $g $c.Sub $c.Cfg $c.Val
                $a = $LASTEXITCODE
                & powercfg /setdcvalueindex $g $c.Sub $c.Cfg $c.Val
                $d = $LASTEXITCODE
                $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).ACSettingIndex
                if ($a -eq 0 -and $d -eq 0 -and $v -eq $c.Val) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $c.Val + ' en el plan ' + $g) }
                else { Log 'FALLO' ('no se pudo verificar ' + $c.Nom); $code = 1 }
            }
            if ($hizo) { & powercfg /setactive $g }
            elseif ($code -eq 0) { $code = 5 }
        }
    }

    { $_ -eq 'NIC_OFF' -or $_ -eq 'NIC_ON' } {
        $val = 0
        if ($env:ACT -eq 'NIC_ON') { $val = 1 }
        $claves = '*EEE', 'EEE', 'AdvancedEEE', 'GreenEthernet', 'EnableGreenEthernet', 'PowerSavingMode'
        $existen = 0
        $cambio = $false
        $omitio = $false
        foreach ($a in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })) {
            $clase = $null
            try {
                $clase = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction Stop |
                    Where-Object { (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $a.InterfaceGuid } |
                    Select-Object -First 1
            } catch { }
            foreach ($kw in $claves) {
                $pr = Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -ErrorAction SilentlyContinue
                if (-not $pr) { continue }
                $existen++
                if (([string]$pr.RegistryValue) -eq ([string]$val)) {
                    Log 'OK' ('ya estaba: ' + $a.Name + ' ' + $kw + ' = ' + $val)
                    continue
                }
                try { Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue $val -NoRestart -ErrorAction Stop }
                catch { Log 'INFO' ('Set-NetAdapterAdvancedProperty ' + $kw + ': ' + $_.Exception.Message) }
                $nuevo = (Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw).RegistryValue
                if (([string]$nuevo) -eq ([string]$val)) {
                    Log 'OK' ('verificado: ' + $a.Name + ' ' + $kw + ' = ' + $val)
                    $cambio = $true
                    continue
                }
                if ($clase) {
                    try { Set-ItemProperty -Path $clase.PSPath -Name $kw -Value ([string]$val) -ErrorAction Stop }
                    catch { Log 'INFO' ('registro directo ' + $kw + ': ' + $_.Exception.Message) }
                    $leido = (Get-ItemProperty -Path $clase.PSPath -ErrorAction SilentlyContinue).PSObject.Properties[$kw].Value
                    if (([string]$leido) -eq ([string]$val)) {
                        Log 'OK' ('verificado por registro: ' + $a.Name + ' ' + $kw + ' = ' + $val + ' (se aplica al reiniciar la red)')
                        $cambio = $true
                        continue
                    }
                }
                $omitio = $true
                Log 'OMITIDO' ('el driver de ' + $a.Name + ' no deja cambiar ' + $kw + ' (no es un error del script)')
            }
        }
        if ($existen -eq 0) {
            Log 'OMITIDO' 'la placa de red activa no tiene opciones de ahorro de energia que cambiar'
            Say '  Tu placa de red no tiene esas opciones, no se cambio nada.' 'Yellow'
            $code = 2
        } elseif (-not $cambio) {
            if ($omitio) { Say '  Tu driver no deja cambiar alguna opcion; el resto ya estaba como lo pedis.' 'Yellow' }
            if ($code -eq 0) { $code = 5 }
        }
    }

 'DNS_ON' {
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        $rk0 = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\'
        $adaps = @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })
        if (-not (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
            Log 'OMITIDO' 'Resolve-DnsName no existe en esta PC, no se puede medir'
            Say '  Esta PC no puede medir DNS, no se cambio nada.' 'Yellow'
            $code = 2
        } elseif ($adaps.Count -eq 0) {
            Log 'OMITIDO' 'no hay ninguna placa de red conectada'
            Say '  No hay una placa de red conectada, no se cambio nada.' 'Yellow'
            $code = 2
        } else {
            $dominios = 'google.com', 'youtube.com', 'microsoft.com', 'steampowered.com', 'epicgames.com', 'riotgames.com', 'discord.com', 'twitch.tv', 'amazon.com', 'cloudflare.com'
            $res = @()
            foreach ($n in $dnsCand.Keys) {
                Say ('  Probando ' + $n + '...')
                $tiempos = @()
                $fallos = 0
                foreach ($ronda in 1..3) {
                    foreach ($d in $dominios) {
                        $sw = [Diagnostics.Stopwatch]::StartNew()
                        $ok = $true
                        try { Resolve-DnsName -Name $d -Server $dnsCand[$n][0] -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop | Out-Null } catch { $ok = $false }
                        $sw.Stop()
                        if (-not $ok) { $fallos++ }
                        elseif ($ronda -gt 1) { $tiempos += $sw.Elapsed.TotalMilliseconds }
                        if ($fallos -gt 3) { break }
                    }
                    if ($fallos -gt 3) { break }
                }
                $med = 99999
                if ($tiempos.Count -gt 0) { $ord = @($tiempos | Sort-Object); $med = $ord[[int][math]::Floor(($ord.Count - 1) / 2)] }
                $med = [math]::Round($med, 1)
                $res += [pscustomobject]@{ Nombre = $n; Ms = $med; Fallos = $fallos; Ips = $dnsCand[$n] }
                if ($fallos -gt 3) {
                    Say ('    ' + $n + ': no responde bien, se descarta') 'Yellow'
                    Log 'INFO' ('prueba DNS ' + $n + ': descartado por fallos')
                } else {
                    Say ('    ' + $n + ': ' + $med + ' ms')
                    Log 'INFO' ('prueba DNS ' + $n + ': ' + $med + ' ms (mediana), ' + $fallos + ' fallos')
                }
            }
            $validos = @($res | Where-Object { $_.Fallos -le 3 -and $_.Ms -lt 99999 } | Sort-Object Ms)
            if ($validos.Count -eq 0) {
                Log 'OMITIDO' 'ningun DNS respondio a la prueba (sin internet o bloqueados)'
                Say '  Ningun DNS respondio a la prueba, no se cambio nada.' 'Yellow'
                $code = 2
            } else {
                $mejor = $validos[0]
                $deseado = @($mejor.Ips)
                Say ('  El mas rapido para tu conexion: ' + $mejor.Nombre + ' (' + ($deseado -join ', ') + ')') 'Green'
                Log 'INFO' ('DNS elegido: ' + $mejor.Nombre + ' ' + ($deseado -join ', '))
                if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                & icacls $dir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
                $cambio = $false
                foreach ($a in $adaps) {
                    $act = @((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses)
                    if (($act -join ',') -eq ($deseado -join ',')) {
                        Log 'OK' ('ya estaba: ' + $a.Name + ' usa ' + ($deseado -join ', '))
                        continue
                    }
                    $ns = [string](Get-ItemProperty -Path ($rk0 + $a.InterfaceGuid) -ErrorAction SilentlyContinue).NameServer
                    $bak = Join-Path $dir ('dns_' + $a.InterfaceGuid + '.txt')
                    $esNuestro = $false
                    foreach ($k in $dnsCand.Keys) { if (($act -join ',') -eq ($dnsCand[$k] -join ',')) { $esNuestro = $true } }
                    if ((-not (Test-Path $bak)) -or (-not $esNuestro)) {
                        if ($ns) { Set-Content -Path $bak -Value ('STATIC=' + $ns) } else { Set-Content -Path $bak -Value 'DHCP' }
                    }
                    if (-not (Test-Path $bak)) {
                        Log 'FALLO' ('no se pudo guardar la copia del DNS anterior de ' + $a.Name + ', no se cambio')
                        $code = 1
                        continue
                    }
                    try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $deseado -ErrorAction Stop }
                    catch { Log 'INFO' ('Set-DnsClientServerAddress ' + $a.Name + ': ' + $_.Exception.Message) }
                    $nuevo = @((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses)
                    if (($nuevo -join ',') -eq ($deseado -join ',')) {
                        Log 'OK' ('verificado: ' + $a.Name + ' usa ' + ($deseado -join ', '))
                        $cambio = $true
                    } else {
                        Log 'FALLO' ('el DNS de ' + $a.Name + ' quedo en ' + ($nuevo -join ', '))
                        $code = 1
                    }
                }
                if ($cambio) { Clear-DnsClientCache; & ipconfig /flushdns | Out-Null }
                elseif ($code -eq 0) { $code = 5 }
            }
        }
    }

    'DNS_OFF' {
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        $rk0 = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\'
        $adaps = @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })
        if ($adaps.Count -eq 0) {
            Log 'OMITIDO' 'no hay ninguna placa de red conectada'
            Say '  No hay una placa de red conectada, no se cambio nada.' 'Yellow'
            $code = 2
        } else {
            $cambio = $false
            $sinCopia = $false
            foreach ($a in $adaps) {
                $act = @((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses)
                $ns = [string](Get-ItemProperty -Path ($rk0 + $a.InterfaceGuid) -ErrorAction SilentlyContinue).NameServer
                $bak = Join-Path $dir ('dns_' + $a.InterfaceGuid + '.txt')
                $dest = $null
                if (Test-Path $bak) {
                    $l = [string](Get-Content $bak | Select-Object -First 1)
                    if ($l -eq 'DHCP') { $dest = @() }
                    elseif ($l -like 'STATIC=*') {
                        $dest = @(($l.Substring(7) -split '[,\s]+') | Where-Object { $ip = $null; $_ -and [ipaddress]::TryParse($_, [ref]$ip) -and $ip.AddressFamily -eq 'InterNetwork' })
                        if ($dest.Count -eq 0) { $dest = $null }
                    }
                } else {
                    $esNuestro = $false
                    foreach ($k in $dnsCand.Keys) { if (($act -join ',') -eq ($dnsCand[$k] -join ',')) { $esNuestro = $true } }
                    if ($esNuestro -or (-not $ns)) { $dest = @() }
                }
                if ($null -eq $dest) {
                    Log 'OMITIDO' ('no hay copia del DNS anterior de ' + $a.Name + ' y el DNS actual no lo puso este script, no se toco')
                    $sinCopia = $true
                    continue
                }
                if ($dest.Count -eq 0) {
                    if (-not $ns) {
                        Log 'OK' ('ya estaba: ' + $a.Name + ' usa DNS automatico')
                        Remove-Item -Path $bak -Force -ErrorAction SilentlyContinue
                        continue
                    }
                    try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop }
                    catch { Log 'INFO' ('ResetServerAddresses ' + $a.Name + ': ' + $_.Exception.Message) }
                    $ns2 = [string](Get-ItemProperty -Path ($rk0 + $a.InterfaceGuid) -ErrorAction SilentlyContinue).NameServer
                    if (-not $ns2) {
                        Log 'OK' ('verificado: ' + $a.Name + ' vuelve a DNS automatico')
                        Remove-Item -Path $bak -Force -ErrorAction SilentlyContinue
                        $cambio = $true
                    } else {
                        Log 'FALLO' ('el DNS de ' + $a.Name + ' sigue fijo en ' + $ns2)
                        $code = 1
                    }
                } else {
                    if (($act -join ',') -eq ($dest -join ',')) {
                        Log 'OK' ('ya estaba: ' + $a.Name + ' usa ' + ($dest -join ', '))
                        Remove-Item -Path $bak -Force -ErrorAction SilentlyContinue
                        continue
                    }
                    try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $dest -ErrorAction Stop }
                    catch { Log 'INFO' ('Set-DnsClientServerAddress ' + $a.Name + ': ' + $_.Exception.Message) }
                    $nuevo = @((Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses)
                    if (($nuevo -join ',') -eq ($dest -join ',')) {
                        Log 'OK' ('verificado: ' + $a.Name + ' vuelve a ' + ($dest -join ', '))
                        Remove-Item -Path $bak -Force -ErrorAction SilentlyContinue
                        $cambio = $true
                    } else {
                        Log 'FALLO' ('no se pudo restaurar el DNS de ' + $a.Name)
                        $code = 1
                    }
                }
            }
            if ($cambio) { Clear-DnsClientCache; & ipconfig /flushdns | Out-Null }
            elseif ($code -eq 0) {
                if ($sinCopia) { Say '  No hay copia de tu DNS anterior, no se cambio nada.' 'Yellow'; $code = 2 }
                else { $code = 5 }
            }
        }
    }

    'TIMER_ON' {
        $tn = 'XucaTimer'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaTimer.exe'
        # En Windows 11 el temporizador es por programa: sin esta clave, el pedido de XucaTimer no llega a los juegos.
        $kk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
        $glob = (Get-ItemProperty -Path $kk -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests
        $globOk = ($glob -eq 1)
        if (-not $globOk) {
            New-ItemProperty -Path $kk -Name 'GlobalTimerResolutionRequests' -Value 1 -PropertyType DWord -Force | Out-Null
            if ((Get-ItemProperty -Path $kk -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests -eq 1) { Log 'OK' 'verificado: GlobalTimerResolutionRequests = 1 (el temporizador vale para todo el sistema, se aplica al reiniciar)' }
            else { Log 'FALLO' 'no se pudo escribir GlobalTimerResolutionRequests'; $code = 1 }
        }
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe)) {
            if ($globOk) { Log 'OK' 'ya estaba: temporizador corriendo para todo el sistema'; $code = 5 }
            else { Log 'OK' 'ya estaba: temporizador corriendo' }
        }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue | Stop-Process -Force
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            & icacls $dir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
            $cs = 'using System.Runtime.InteropServices; using System.Threading; public class P { [DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint d, bool s, out uint c); public static void Main() { uint c; NtSetTimerResolution(5000, true, out c); Thread.Sleep(Timeout.Infinite); } }'
            try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar TIMER: ' + $_.Exception.Message); $code = 1 }
            if (Test-Path $exe) {
                $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                Start-ScheduledTask -TaskName $tn; Start-Sleep -Seconds 2
                $t2 = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
                if ($t2 -and ($t2.State -eq 'Running')) { Log 'OK' 'verificado: temporizador a 0.5ms' } else { Log 'FALLO' 'la tarea XucaTimer no quedo corriendo'; $code = 1 }
            }
        }
    }

    'TIMER_OFF' {
        $tn = 'XucaTimer'; $exe = Join-Path (Join-Path $env:ProgramData 'XucaScripts') 'XucaTimer.exe'
        $kk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        $p = Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue
        $hayGlob = ($null -ne (Get-ItemProperty -Path $kk -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests)
        if ((-not $t) -and (-not $p) -and (-not $hayGlob) -and (-not (Test-Path $exe))) { Log 'OK' 'ya estaba: sin temporizador fijo'; $code = 5 }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Milliseconds 500
            Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $kk -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue
            $queda = (Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue) -or (Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue) -or ($null -ne (Get-ItemProperty -Path $kk -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests)
            if ($queda) { Log 'FALLO' 'el temporizador no se pudo borrar del todo'; $code = 1 }
            else { Log 'OK' 'verificado: temporizador borrado (Windows vuelve a su valor por defecto)' }
        }
    }

    'RAM_ON' {
        $tn = 'XucaRAM'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaRAM.exe'
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe)) { Log 'OK' 'ya estaba: limpiador RAM corriendo'; $code = 5 }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaRAM' -ErrorAction SilentlyContinue | Stop-Process -Force
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            $cs = 'using System; using System.Runtime.InteropServices; using System.Threading; public class P { [DllImport("ntdll.dll")] public static extern int NtSetSystemInformation(int i, ref int n, int l); [DllImport("advapi32.dll", SetLastError=true)] static extern bool OpenProcessToken(IntPtr p, uint d, out IntPtr t); [DllImport("advapi32.dll")] static extern bool LookupPrivilegeValue(string s, string n, out long l); [DllImport("advapi32.dll")] static extern bool AdjustTokenPrivileges(IntPtr t, bool d, ref TP n, uint b, IntPtr p, IntPtr r); [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess(); [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx(ref MS b); [StructLayout(LayoutKind.Sequential)] struct MS { public uint d; public uint l; public ulong tp; public ulong ap; public ulong tpf; public ulong apf; public ulong tv; public ulong av; public ulong aev; } [StructLayout(LayoutKind.Sequential, Pack=1)] struct TP { public uint c; public long l; public uint a; } public static void Main() { IntPtr t; if (OpenProcessToken(GetCurrentProcess(), 40, out t)) { TP tp = new TP(); tp.c = 1; tp.a = 2; LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out tp.l); AdjustTokenPrivileges(t, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero); } while(true) { MS m = new MS(); m.d = (uint)Marshal.SizeOf(typeof(MS)); if (GlobalMemoryStatusEx(ref m)) { if ((m.ap / 1048576) < 1024) { int c = 4; NtSetSystemInformation(80, ref c, 4); } } Thread.Sleep(10000); } } }'
            try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar RAM: ' + $_.Exception.Message); $code = 1 }
            if (Test-Path $exe) {
                $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                Start-ScheduledTask -TaskName $tn; Start-Sleep -Seconds 2
                $t2 = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
                if ($t2 -and ($t2.State -eq 'Running')) { Log 'OK' 'verificado: limpiador RAM (< 1024MB)' } else { Log 'FALLO' 'la tarea XucaRAM no quedo corriendo'; $code = 1 }
            }
        }
    }

    'RAM_OFF' {
        $tn = 'XucaRAM'; $exe = Join-Path (Join-Path $env:ProgramData 'XucaScripts') 'XucaRAM.exe'
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        $p = Get-Process -Name 'XucaRAM' -ErrorAction SilentlyContinue
        if ((-not $t) -and (-not $p) -and (-not (Test-Path $exe))) { Log 'OK' 'ya estaba: sin limpiador de RAM'; $code = 5 }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaRAM' -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Milliseconds 500
            Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
            if ((Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue) -or (Get-Process -Name 'XucaRAM' -ErrorAction SilentlyContinue)) { Log 'FALLO' 'el limpiador de RAM no se pudo borrar del todo'; $code = 1 }
            else { Log 'OK' 'verificado: limpiador RAM borrado' }
        }
    }

    { $_ -eq 'CPU_ON' -or $_ -eq 'CPU_OFF' } {
        # Mismos valores que QuickCPU (modo AC): Core parking 100, Frequency scaling 0, Turbo boost 100, Performance 100
        $g = [regex]::Match((& powercfg /getactivescheme | Out-String), '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value
        if (-not $g) {
            Log 'FALLO' 'no se pudo leer el plan de energia activo'
            $code = 1
        } else {
            $sub = '54533251-82be-4824-96c1-47b60b740d00'
            $cfg = @(
                @{ Nom = 'nucleos activos (core parking)'; Cfg = '0cc5b647-c1df-4637-891a-dec35c318583'; Val = 100 },
                @{ Nom = 'estado minimo del procesador (frequency scaling)'; Cfg = '893dee8e-2bef-41e0-89c6-b55d0929964c'; Val = 0 },
                @{ Nom = 'turbo boost'; Cfg = '45bcc044-d885-43e2-8605-ee0ec6e96b59'; Val = 100 },
                @{ Nom = 'rendimiento (preferencia energia-rendimiento, 0 = maximo)'; Cfg = '36687f9e-e3a5-4dbf-b1dc-15eb381c6863'; Val = 0 }
            )
            $dir = Join-Path $env:ProgramData 'XucaScripts'
            $bak = Join-Path $dir ('cpu_' + $g + '.txt')
            function LeerAc($id) {
                $o = & powercfg /query $g $sub $id | Out-String
                $m = [regex]::Matches($o, '0x[0-9a-fA-F]{8}')
                if ($m.Count -lt 2) { return $null }
                return [Convert]::ToInt32($m[$m.Count - 2].Value.Substring(2), 16)
            }
            function LeerReg($id) {
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $g + '\' + $sub + '\' + $id
                return (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).ACSettingIndex
            }
            function Actual($id) {
                $x = LeerAc $id
                if ($null -eq $x) { $x = LeerReg $id }
                return $x
            }
            function Poner($c, $val) {
                $antes = Actual $c.Cfg
                $out = (& powercfg /setacvalueindex $g $sub $c.Cfg $val 2>&1 | Out-String).Trim()
                $a = $LASTEXITCODE
                $q = LeerAc $c.Cfg
                $r = LeerReg $c.Cfg
                if (($q -eq $val) -or ($r -eq $val)) { return $true }
                $raw = ''
                if ($null -eq $q) { $raw = ((& powercfg /query $g $sub $c.Cfg 2>&1 | Out-String) -replace '\s+', ' ') }
                if ($raw.Length -gt 300) { $raw = $raw.Substring(0, 300) }
                Log 'INFO' ('detalle ' + $c.Nom + ': codigo de powercfg=' + $a + ', antes=' + $antes + ', pedido=' + $val + ', leido con powercfg=' + $q + ', leido en el registro=' + $r + ', mensaje=' + ($out -replace '\s+', ' ') + ' ' + $raw)
                return $false
            }
            if ($env:ACT -eq 'CPU_ON') {
                $faltan = @($cfg | Where-Object { (Actual $_.Cfg) -ne $_.Val })
                if ($faltan.Count -eq 0) {
                    Log 'OK' ('ya estaba: procesador como QuickCPU en el plan ' + $g)
                    $code = 5
                } else {
                    $sinCopia = $false
                    if (Test-Path $bak) {
                        Log 'INFO' ('ya existia una copia de tus valores anteriores, se conserva: ' + $bak)
                    } else {
                        if (-not (Test-Path $dir)) {
                            New-Item -Path $dir -ItemType Directory -Force | Out-Null
                            & icacls $dir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
                        }
                        $lineas = @(foreach ($c in $cfg) { $c.Cfg + '=' + (Actual $c.Cfg) })
                        Set-Content -Path $bak -Value $lineas
                        if (Test-Path $bak) { Log 'INFO' ('copia de tus valores anteriores guardada en ' + $bak) }
                        else { Log 'FALLO' 'no se pudo guardar la copia de tus valores anteriores, no se cambio nada'; $code = 1; $sinCopia = $true }
                    }
                    if (-not $sinCopia) {
                        foreach ($c in $cfg) {
                            if ((Actual $c.Cfg) -eq $c.Val) { Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $c.Val); continue }
                            if (Poner $c $c.Val) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $c.Val + ' en el plan ' + $g) }
                            else { Log 'FALLO' ('no se pudo verificar ' + $c.Nom); $code = 1 }
                        }
                        & powercfg /setactive $g
                    }
                }
            } else {
                if (-not (Test-Path $bak)) {
                    Log 'OMITIDO' 'no hay copia de tus valores anteriores para este plan, no se cambio nada'
                    Say '  No hay copia de tus valores anteriores, no se cambio nada.' 'Yellow'
                    $code = 2
                } else {
                    $guardado = @{}
                    foreach ($l in (Get-Content $bak)) {
                        $p = $l -split '='
                        if ($p.Count -eq 2 -and $p[1] -match '^\d+$') { $guardado[$p[0]] = [int]$p[1] }
                    }
                    $hizo = $false
                    foreach ($c in $cfg) {
                        if (-not $guardado.ContainsKey($c.Cfg)) { continue }
                        $val = $guardado[$c.Cfg]
                        if ((Actual $c.Cfg) -eq $val) { Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $val); continue }
                        $hizo = $true
                        if (Poner $c $val) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $val + ' (restaurado)') }
                        else { Log 'FALLO' ('no se pudo restaurar ' + $c.Nom); $code = 1 }
                    }
                    if ($hizo) { & powercfg /setactive $g }
                    elseif ($code -eq 0) { $code = 5 }
                    if ($code -ne 1) { Remove-Item -Path $bak -Force }
                }
            }
        }
    }

    'SPI' {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SpiNative {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
'@
        $flags = 3
        $M = [System.Runtime.InteropServices.Marshal]
        foreach ($t in ($env:SPI -split ';')) {
            if (-not $t) { continue }
            $p = $t -split ':'
            $r = $false
            switch ($p[0]) {
                'P' { $r = [SpiNative]::SystemParametersInfo([Convert]::ToUInt32($p[1], 16), 0, [IntPtr][int]$p[2], $flags) }
                'U' { $r = [SpiNative]::SystemParametersInfo([Convert]::ToUInt32($p[1], 16), [uint32]$p[2], [IntPtr]::Zero, $flags) }
                'M' {
                    $buf = $M::AllocHGlobal(12)
                    0..2 | ForEach-Object { $M::WriteInt32($buf, 4 * $_, [int]$p[$_ + 1]) }
                    $r = [SpiNative]::SystemParametersInfo(4, 0, $buf, $flags)
                    $M::FreeHGlobal($buf)
                }
            }
            if ($r) { Log 'OK' ('SystemParametersInfo ' + $t) }
            else { Log 'FALLO' ('SystemParametersInfo ' + $t); $code = 1 }
        }
    }

    'AV_STATUS' {
        if (Test-AvOff) { $code = 10 } else { $code = 0 }
    }

    'AV_LIGHT' {
        $m = Get-MpPreference
        if ($m.ScanAvgCPULoadFactor -eq 5 -and $m.EnableLowCpuPriority -eq $true) {
            Log 'OK' 'ya estaba: analisis con tope de CPU de 5 por ciento y prioridad baja'
            $code = 5
        } else {
            try { Set-MpPreference -ScanAvgCPULoadFactor 5 -EnableLowCpuPriority $true -ErrorAction Stop }
            catch { Log 'FALLO' ('Set-MpPreference: ' + $_.Exception.Message); $code = 1 }
            $m = Get-MpPreference
            if ($m.ScanAvgCPULoadFactor -eq 5 -and $m.EnableLowCpuPriority -eq $true) { Log 'OK' 'verificado: analisis con tope de CPU de 5 por ciento y prioridad baja' }
            else { Log 'FALLO' 'no se pudo verificar el limite de CPU del antivirus'; $code = 1 }
        }
    }

    'AV_LIGHT_R' {
        $m = Get-MpPreference
        if ($m.ScanAvgCPULoadFactor -eq 50 -and $m.EnableLowCpuPriority -eq $false) {
            Log 'OK' 'ya estaba: limite de CPU del antivirus original'
            $code = 5
        } else {
            try { Set-MpPreference -ScanAvgCPULoadFactor 50 -EnableLowCpuPriority $false -ErrorAction Stop }
            catch { Log 'FALLO' ('Set-MpPreference: ' + $_.Exception.Message); $code = 1 }
            $m = Get-MpPreference
            if ($m.ScanAvgCPULoadFactor -eq 50 -and $m.EnableLowCpuPriority -eq $false) { Log 'OK' 'verificado: limite de CPU del antivirus restaurado' }
            else { Log 'FALLO' 'no se pudo verificar el limite de CPU del antivirus'; $code = 1 }
        }
    }

     'EXPLOIT_OFF' {
        $pm = Get-ProcessMitigation -System
        $ya = (([string]$pm.DEP.Enable -in 'OFF','NOTSET') -and ([string]$pm.SEHOP.Enable -in 'OFF','NOTSET') -and ([string]$pm.ASLR.BottomUp -in 'OFF','NOTSET') -and ([string]$pm.ASLR.HighEntropy -in 'OFF','NOTSET') -and ([string]$pm.Heap.TerminateOnError -in 'OFF','NOTSET'))
        if ($ya) {
            Log 'OK' 'ya estaba: DEP, SEHOP, ASLR e integridad del heap apagados'
            $code = 5
        } else {
            foreach ($i in 'DEP', 'SEHOP', 'BottomUp', 'HighEntropy', 'TerminateOnError') {
                try { Set-ProcessMitigation -System -Disable $i -ErrorAction Stop } catch { Log 'FALLO' ($i + ': ' + $_.Exception.Message); $code = 1 }
            }
            $pm = Get-ProcessMitigation -System
            $vals = @(
                @{ N = 'DEP'; V = [string]$pm.DEP.Enable },
                @{ N = 'SEHOP'; V = [string]$pm.SEHOP.Enable },
                @{ N = 'ASLR ascendente'; V = [string]$pm.ASLR.BottomUp },
                @{ N = 'ASLR de alta entropia'; V = [string]$pm.ASLR.HighEntropy },
                @{ N = 'integridad del heap'; V = [string]$pm.Heap.TerminateOnError }
            )
            foreach ($x in $vals) {
                if (($x.V -eq 'OFF') -or ($x.V -eq 'NOTSET')) { Log 'OK' ('verificado: ' + $x.N + ' apagado (' + $x.V + ')') }
                else { Log 'FALLO' ($x.N + ' quedo en ' + $x.V); $code = 1 }
            }
        }
        $cfg = [string]$pm.CFG.Enable
        if ($cfg -ne 'OFF') { Log 'OK' ('verificado: CFG intacto (' + $cfg + ')') }
        else { Log 'FALLO' 'el CFG aparece apagado, activalo en Seguridad de Windows > Proteccion contra vulnerabilidades'; $code = 1 }
    }

    'EXPLOIT_ON' {
        $pm = Get-ProcessMitigation -System
        $ya = (([string]$pm.DEP.Enable -in 'ON','NOTSET') -and ([string]$pm.SEHOP.Enable -in 'ON','NOTSET') -and ([string]$pm.ASLR.BottomUp -in 'ON','NOTSET') -and ([string]$pm.ASLR.HighEntropy -in 'ON','NOTSET') -and ([string]$pm.Heap.TerminateOnError -in 'ON','NOTSET'))
        if ($ya) {
            Log 'OK' 'ya estaba: DEP, SEHOP, ASLR e integridad del heap activados'
            $code = 5
        } else {
            foreach ($i in 'DEP', 'SEHOP', 'BottomUp', 'HighEntropy', 'TerminateOnError') {
                try { Set-ProcessMitigation -System -Enable $i -ErrorAction Stop } catch { Log 'FALLO' ($i + ': ' + $_.Exception.Message); $code = 1 }
            }
            $pm = Get-ProcessMitigation -System
            $vals = @(
                @{ N = 'DEP'; V = [string]$pm.DEP.Enable },
                @{ N = 'SEHOP'; V = [string]$pm.SEHOP.Enable },
                @{ N = 'ASLR ascendente'; V = [string]$pm.ASLR.BottomUp },
                @{ N = 'ASLR de alta entropia'; V = [string]$pm.ASLR.HighEntropy },
                @{ N = 'integridad del heap'; V = [string]$pm.Heap.TerminateOnError }
            )
            foreach ($x in $vals) {
                if (($x.V -eq 'ON') -or ($x.V -eq 'NOTSET')) { Log 'OK' ('verificado: ' + $x.N + ' en su valor por defecto (' + $x.V + ')') }
                else { Log 'FALLO' ($x.N + ' quedo en ' + $x.V); $code = 1 }
            }
        }
    }

    'VBS_FEATS_OFF' {
        $lista = 'Microsoft-Hyper-V-All', 'Microsoft-Hyper-V', 'VirtualMachinePlatform', 'Microsoft-Windows-Subsystem-Linux', 'HypervisorPlatform', 'Containers'
        $feats = Get-FeatMap
        $activas = @($lista | Where-Object { $feats.ContainsKey($_) -and ([string]$feats[$_] -notlike 'Disable*') })
        foreach ($f in $lista) { if (-not $feats.ContainsKey($f)) { Log 'OMITIDO' ('la caracteristica ' + $f + ' no existe en esta PC') } }
        if ($activas.Count -eq 0) {
            Log 'OK' 'ya estaba: ninguna caracteristica de virtualizacion esta activa'
            $code = 5
        } else {
            foreach ($f in $activas) {
                try { Disable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction Stop | Out-Null }
                catch { Log 'FALLO' ($f + ': ' + $_.Exception.Message); $code = 1 }
            }
            $despues = Get-FeatMap
            foreach ($f in $activas) {
                $y = [string]$despues[$f]
                if ($y -like 'Disable*') { Log 'OK' ($f + ' desactivada (' + $y + ')') }
                else { Log 'FALLO' ($f + ' quedo en estado ' + $y); $code = 1 }
            }
        }
    }

    'PRIO_ON' {
        $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'
        # Cada nombre es el proceso del juego tal como aparece en el Administrador de tareas, sin el .exe.
        $exes = New-Object System.Collections.Generic.List[string]
        foreach ($e in (([string]$env:PRIOJ) -split ',')) {
            $txt = $e.Trim().Trim('"').Trim()
            if (-not $txt) { continue }
            $txt = $txt -replace '(?i)\.exe$', ''
            if ($txt -match '^[^\\/:*?"<>|]+$') { $exes.Add($txt + '.exe') }
            else { Log 'OMITIDO' ('nombre de proceso no valido: "' + $txt + '"'); Say ('  "' + $txt + '" no es un nombre de proceso valido, se salteo.') 'Yellow' }
        }
        $exes = @($exes | Sort-Object -Unique)
        if ($exes.Count -eq 0) {
            Log 'OMITIDO' 'no se escribio ningun juego valido'
            $code = 2
        } else {
            $hizo = 0
            foreach ($x in $exes) {
                $po = $ifeo + $x + '\PerfOptions'
                $p = Get-ItemProperty -LiteralPath $po -ErrorAction SilentlyContinue
                if ($p -and $p.CpuPriorityClass -eq 3) { Log 'OK' ('ya estaba: ' + $x + ' con prioridad alta'); continue }
                New-Item -Path $po -Force | Out-Null
                New-ItemProperty -LiteralPath $po -Name 'CpuPriorityClass' -Value 3 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $po -Name 'XucaPrioridad' -Value 1 -PropertyType DWord -Force | Out-Null
                if ((Get-ItemProperty -LiteralPath $po -ErrorAction SilentlyContinue).CpuPriorityClass -eq 3) { $hizo++; Log 'OK' ('verificado: ' + $x + ' arranca con prioridad alta') }
                else { Log 'FALLO' ('no se pudo dar prioridad alta a ' + $x); $code = 1 }
            }
            if (($hizo -eq 0) -and ($code -eq 0)) { $code = 5 }
        }
    }

    'PRIO_OFF' {
        $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
        $nuestros = @(Get-ChildItem -LiteralPath $ifeo -ErrorAction SilentlyContinue | Where-Object { (Get-ItemProperty -LiteralPath ($_.PSPath + '\PerfOptions') -ErrorAction SilentlyContinue).XucaPrioridad -eq 1 })
        if ($nuestros.Count -eq 0) {
            Log 'OK' 'ya estaba: ningun juego tenia prioridad alta puesta por este script'
            $code = 5
        } else {
            foreach ($k in $nuestros) {
                Remove-Item -LiteralPath ($k.PSPath + '\PerfOptions') -Recurse -Force -ErrorAction SilentlyContinue
                $resto = Get-Item -LiteralPath $k.PSPath -ErrorAction SilentlyContinue
                if ($resto -and ($resto.SubKeyCount -eq 0) -and ($resto.ValueCount -eq 0)) { Remove-Item -LiteralPath $k.PSPath -Force -ErrorAction SilentlyContinue }
                if (Test-Path -LiteralPath ($k.PSPath + '\PerfOptions')) { Log 'FALLO' ('no se pudo quitar la prioridad de ' + $k.PSChildName); $code = 1 }
                else { Log 'OK' ('verificado: ' + $k.PSChildName + ' vuelve a prioridad normal') }
            }
        }
    }

    'AFI_INFO' {
        $pl = Afi-Plan
        if (-not $pl.Ok) { Say ('  No se puede usar en esta PC: ' + $pl.Motivo + '.') 'Yellow'; $code = 2 }
        else {
            Afi-Mostrar $pl
            Say '' $null
            Afi-MostrarItems (Afi-Items $afiJuegosCat (Afi-Actual 'juegos')) 'Juegos:'
        }
    }

    'AFI_INFO_F' {
        Afi-MostrarItems (Afi-Items $afiFondoCat (Afi-Actual 'apps')) 'Programas de fondo (se mueven solo mientras jugas):'
    }

    'AFI_ON' {
        $tn = 'XucaAfinidad'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaAfinidad.exe'; $cfg = Join-Path $dir 'afinidad.txt'
        $pl = Afi-Plan
        if (-not $pl.Ok) { Log 'OMITIDO' $pl.Motivo; Say ('  No se cambio nada: ' + $pl.Motivo + '.') 'Yellow'; $code = 2 }
        else {
            # La app manda la eleccion completa (AFIAPP=1, AFIJ y AFIF). En la consola: lo de la vez anterior (o los
            # predeterminados), con los numeros que marcaste o desmarcaste (AFIJT/AFIFT) y lo que agregaste (AFIJX/AFIFX).
            if ($env:AFIAPP -eq '1') { $txtJ = [string]$env:AFIJ; $txtF = [string]$env:AFIF }
            else {
                $txtJ = Afi-Elegir $afiJuegosCat 'juegos' ([string]$env:AFIJT) ([string]$env:AFIJX)
                $txtF = Afi-Elegir $afiFondoCat 'apps' ([string]$env:AFIFT) ([string]$env:AFIFX)
            }
            $juegos = @(Afi-Nombres $txtJ)
            $apps = @(Afi-Nombres $txtF | Where-Object { $juegos -notcontains $_ })
            $livianos = @($juegos | Where-Object { $afiLivianos -contains $_ })
            $pesados = @($juegos | Where-Object { $afiLivianos -notcontains $_ })
            if ($juegos.Count -eq 0) { Log 'OMITIDO' 'no quedo ningun juego elegido'; Say '  No quedo ningun juego elegido: no se cambio nada.' 'Yellow'; $code = 2 }
            else {
                $desc = ($pl.Cpu + ' (' + $pl.Tipo + '): juegos en ' + (Afi-Lista $pl.Juego) + ', livianos en ' + (Afi-Lista $pl.Liviano) + ', fondo en ' + (Afi-Lista $pl.Fondo))
                Log 'INFO' ('Procesador: ' + $desc)
                Afi-Mostrar $pl
                $txt = (@(('juego=' + $pl.Juego), ('liviano=' + $pl.Liviano), ('fondo=' + $pl.Fondo), ('todo=' + $pl.Todo), ('juegos=' + ($pesados -join ',')), ('livianos=' + ($livianos -join ',')), ('apps=' + ($apps -join ',')), ('desc=' + $desc)) -join "`r`n")
                $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
                $viejo = ''; if (Test-Path -LiteralPath $cfg) { $viejo = [string](Get-Content -LiteralPath $cfg -Raw) }
                if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe) -and ($viejo.Trim() -eq $txt.Trim())) {
                    Log 'OK' 'ya estaba: afinidad corriendo con los mismos juegos y programas'; $code = 5
                } else {
                    if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
                    Get-Process -Name 'XucaAfinidad' -ErrorAction SilentlyContinue | Stop-Process -Force
                    Start-Sleep -Milliseconds 500
                    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                    & icacls $dir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
                    Set-Content -LiteralPath $cfg -Value $txt -Encoding ASCII
                    Log 'OK' ('juegos: ' + ($pesados -join ', '))
                    if ($livianos.Count -gt 0) { Log 'OK' ('juegos livianos: ' + ($livianos -join ', ')) }
                    Log 'OK' ('programas de fondo: ' + ($apps -join ', '))
                    # Programa chico: cada 2 segundos mira que hay abierto. A cada juego le pone sus nucleos una sola vez.
                    # Mientras haya un juego abierto lleva lo de fondo a sus nucleos; cuando no queda ninguno, lo devuelve a todos.
                    $cs = 'using System; using System.Collections.Generic; using System.Diagnostics; using System.IO; using System.Threading; public class P { static long juego, liviano, fondo, todo; static HashSet<string> juegos = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static HashSet<string> livianos = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static HashSet<string> apps = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static void Lista(HashSet<string> h, string v) { foreach (string n in v.Split((char)44)) { string x = n.Trim(); if (x.Length > 0) h.Add(x); } } static void Leer(string ruta) { foreach (string l in File.ReadAllLines(ruta)) { int i = l.IndexOf((char)61); if (i < 1) continue; string k = l.Substring(0, i).Trim(); string v = l.Substring(i + 1).Trim(); if (k == "juego") juego = long.Parse(v); else if (k == "liviano") liviano = long.Parse(v); else if (k == "fondo") fondo = long.Parse(v); else if (k == "todo") todo = long.Parse(v); else if (k == "juegos") Lista(juegos, v); else if (k == "livianos") Lista(livianos, v); else if (k == "apps") Lista(apps, v); } } static void Poner(Process p, long m) { try { if ((long)p.ProcessorAffinity != m) p.ProcessorAffinity = new IntPtr(m); } catch { } } public static void Main() { string ruta = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "XucaScripts\\afinidad.txt"); try { Leer(ruta); } catch { return; } if (liviano == 0) liviano = juego; if (juego == 0 || todo == 0 || (juegos.Count + livianos.Count) == 0) return; try { Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.BelowNormal; } catch { } HashSet<int> hechosJ = new HashSet<int>(); HashSet<int> hechosF = new HashSet<int>(); while (true) { Process[] ps = Process.GetProcesses(); HashSet<int> vivos = new HashSet<int>(); bool hayJuego = false; foreach (Process p in ps) { string nom; try { nom = p.ProcessName; } catch { continue; } vivos.Add(p.Id); long m = 0; if (livianos.Contains(nom)) m = liviano; else if (juegos.Contains(nom)) m = juego; if (m != 0) { hayJuego = true; if (!hechosJ.Contains(p.Id)) { Poner(p, m); hechosJ.Add(p.Id); } } } if (hayJuego && fondo != 0) { foreach (Process p in ps) { if (hechosF.Contains(p.Id)) continue; string nom; try { nom = p.ProcessName; } catch { continue; } if (apps.Contains(nom)) { Poner(p, fondo); hechosF.Add(p.Id); } } } else if (!hayJuego && hechosF.Count > 0) { foreach (Process p in ps) { if (hechosF.Contains(p.Id)) Poner(p, todo); } hechosF.Clear(); } hechosJ.IntersectWith(vivos); hechosF.IntersectWith(vivos); foreach (Process p in ps) p.Dispose(); Thread.Sleep(2000); } } }'
                    Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
                    try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar AFINIDAD: ' + $_.Exception.Message); $code = 1 }
                    if (Test-Path $exe) {
                        $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                        Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                        Start-ScheduledTask -TaskName $tn; Start-Sleep -Seconds 2
                        $t2 = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
                        if ($t2 -and ($t2.State -eq 'Running')) { Log 'OK' ('verificado: afinidad corriendo - ' + $desc) } else { Log 'FALLO' 'la tarea XucaAfinidad no quedo corriendo'; $code = 1 }
                    }
                }
            }
        }
    }

    'AFI_OFF' {
        $tn = 'XucaAfinidad'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaAfinidad.exe'; $cfg = Join-Path $dir 'afinidad.txt'
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        $p = Get-Process -Name 'XucaAfinidad' -ErrorAction SilentlyContinue
        if ((-not $t) -and (-not $p) -and (-not (Test-Path $exe)) -and (-not (Test-Path $cfg))) { Log 'OK' 'ya estaba: sin afinidad puesta'; $code = 5 }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaAfinidad' -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Milliseconds 500
            # Lo que este abierto ahora vuelve a usar todos los nucleos.
            if (Test-Path -LiteralPath $cfg) {
                $c = @{}
                foreach ($l in @(Get-Content -LiteralPath $cfg)) { $i = $l.IndexOf('='); if ($i -gt 0) { $c[$l.Substring(0, $i)] = $l.Substring($i + 1) } }
                $todo = [long]0; [void][long]::TryParse([string]$c['todo'], [ref]$todo)
                $nombres = @((([string]$c['juegos']) + ',' + ([string]$c['livianos']) + ',' + ([string]$c['apps'])) -split ',' | Where-Object { $_ })
                if (($todo -ne 0) -and ($nombres.Count -gt 0)) {
                    foreach ($pr in @(Get-Process -Name $nombres -ErrorAction SilentlyContinue)) { try { $pr.ProcessorAffinity = (New-Object IntPtr $todo) } catch { } }
                    Log 'OK' 'lo que estaba abierto vuelve a usar todos los nucleos'
                }
            }
            Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $cfg -Force -ErrorAction SilentlyContinue
            if ((Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue) -or (Get-Process -Name 'XucaAfinidad' -ErrorAction SilentlyContinue)) { Log 'FALLO' 'la afinidad no se pudo quitar del todo'; $code = 1 }
            else { Log 'OK' 'verificado: afinidad quitada' }
        }
    }

    'MSI_ON' {
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        $bak = Join-Path $dir 'msi_backup.txt'
        $devs = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { ($_.Class -in 'Display', 'Net') -and ($_.InstanceId -like 'PCI\*') -and ($_.Status -eq 'OK') })
        if ($devs.Count -eq 0) {
            Log 'OMITIDO' 'no se encontro placa de video ni de red PCI'
            $code = 2
        } else {
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            $guardados = @()
            if (Test-Path $bak) { $guardados = @(Get-Content $bak | ForEach-Object { ($_ -split '\|')[0] }) }
            $hizo = 0
            foreach ($d in $devs) {
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $d.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
                $prev = (Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue).MSISupported
                if ($prev -eq 1) { Log 'OK' ('ya estaba: ' + $d.FriendlyName + ' en modo MSI'); continue }
                if ($guardados -notcontains $d.InstanceId) {
                    $v = 'NONE'; if ($null -ne $prev) { $v = [string]$prev }
                    Add-Content -LiteralPath $bak -Value ($d.InstanceId + '|' + $v)
                }
                try {
                    if (-not (Test-Path -LiteralPath $rk)) { New-Item -Path $rk -Force -ErrorAction Stop | Out-Null }
                    New-ItemProperty -LiteralPath $rk -Name 'MSISupported' -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                } catch { Log 'INFO' ('MSI ' + $d.FriendlyName + ': ' + $_.Exception.Message) }
                if ((Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue).MSISupported -eq 1) { $hizo++; Log 'OK' ('verificado: ' + $d.FriendlyName + ' en modo MSI (se aplica al reiniciar)') }
                else { Log 'FALLO' ('no se pudo activar MSI en ' + $d.FriendlyName); $code = 1 }
            }
            if (($hizo -eq 0) -and ($code -eq 0)) { $code = 5; Say '  Tus placas ya usan modo MSI, no hacia falta cambiar nada.' 'Yellow' }
        }
    }

    'MSI_OFF' {
        $bak = Join-Path (Join-Path $env:ProgramData 'XucaScripts') 'msi_backup.txt'
        if (-not (Test-Path $bak)) {
            Log 'OMITIDO' 'no hay copia de como estaba el modo MSI, no se toco nada'
            Say '  No hay copia de como estaba el modo MSI: no se cambio nada.' 'Yellow'
            $code = 2
        } else {
            foreach ($l in @(Get-Content $bak)) {
                $p = $l -split '\|'
                if ($p.Count -ne 2) { continue }
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $p[0] + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
                if (-not (Test-Path -LiteralPath $rk)) { Log 'OMITIDO' ('el dispositivo ya no esta: ' + $p[0]); continue }
                if ($p[1] -eq 'NONE') { Remove-ItemProperty -LiteralPath $rk -Name 'MSISupported' -ErrorAction SilentlyContinue; $ok = ($null -eq (Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue).MSISupported) }
                else { New-ItemProperty -LiteralPath $rk -Name 'MSISupported' -Value ([int]$p[1]) -PropertyType DWord -Force | Out-Null; $ok = ((Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue).MSISupported -eq [int]$p[1]) }
                if ($ok) { Log 'OK' ('verificado: ' + $p[0] + ' vuelve a como estaba') } else { Log 'FALLO' ('no se pudo restaurar ' + $p[0]); $code = 1 }
            }
            if ($code -ne 1) { Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue }
        }
    }

    'VANGUARD_CHECK' {
        $pf = [Environment]::GetFolderPath('ProgramFiles')
        $vgDir = Join-Path $pf 'Riot Vanguard'
        $inst = (Get-Service -Name 'vgc','vgk' -ErrorAction SilentlyContinue) -or (Test-Path $vgDir)
        if ($inst) { $code = 10 } else { $code = 0 }
    }

    'VANGUARD_OFF' {
        $pf = [Environment]::GetFolderPath('ProgramFiles')
        $vgDir = Join-Path $pf 'Riot Vanguard'
        $vgc = Join-Path $vgDir 'vgc.exe'
        Stop-Process -Name 'vgc', 'vgtray' -Force -ErrorAction SilentlyContinue
        if (Test-Path $vgc) {
            try { Start-Process -FilePath $vgc -ArgumentList '/uninstall' -Wait -WindowStyle Hidden -ErrorAction Stop } catch { }
            Start-Sleep -Seconds 2
        }
        foreach ($sv in 'vgc', 'vgk') {
            $s = Get-Service -Name $sv -ErrorAction SilentlyContinue
            if ($s) { & sc.exe delete $sv | Out-Null }
        }
        if (Test-Path $vgDir) { Remove-Item -Path $vgDir -Recurse -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 1
        $queda = (Get-Service -Name 'vgc','vgk' -ErrorAction SilentlyContinue) -or (Test-Path $vgDir)
        if (-not $queda) { 
            Log 'OK' 'Riot Vanguard desinstalado y sus restos borrados'
            $code = 0
        } else { 
            Log 'PENDIENTE' 'Riot Vanguard quitado: quedan restos que se limpian al reiniciar'
            $code = 6 
        }
    }

}

exit $code