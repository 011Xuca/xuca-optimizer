@echo off
setlocal EnableExtensions
set "XUCA_SELF=%~f0"
rem Si el archivo quedo con saltos de linea de Linux (LF), cmd salta a etiquetas equivocadas: se corrige solo y se vuelve a abrir.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $f=$env:XUCA_SELF; $e=[Text.Encoding]::GetEncoding(28591); $t=$e.GetString([IO.File]::ReadAllBytes($f)); if ($t -match '(^|[^\r])\n') { [IO.File]::WriteAllText($f, ($t -replace '\r?\n', ([string][char]13 + [char]10)), $e); exit 9 }; exit 0 } catch { exit 0 }" >nul 2>&1
if errorlevel 9 "%~f0" %*
title Limpieza de cache (Xuca)
color 0B

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Pidiendo permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ==========================================
echo       LIMPIEZA DE CACHE - XUCA
echo ==========================================
echo.

echo Se va a limpiar, sin preguntar: temporales, cache de Windows Update, Windows.old,
echo volcados y logs de errores, caches de apps, Visor de Eventos,
echo Microsoft Store, DNS y componentes viejos de Windows (DISM).
echo Antes te pregunta por tres cosas que conviene decidir vos.

echo.
echo   Papelera de reciclaje:
echo   Que hace: vacia la papelera de todos los discos.
echo   A favor: libera el espacio de lo que ya borraste.
echo   En contra: lo que esta en la papelera ya no se puede recuperar.
choice /c SN /n /m "- Desea vaciar la papelera de reciclaje? [S] Si  [N] No: "
if errorlevel 2 (set "CLEAN_BIN=0") else (set "CLEAN_BIN=1")

echo.
echo   Cache de shaders de la placa de video:
echo   Que hace: borra los shaders que los juegos ya compilaron para tu placa de video.
echo   A favor: arregla tirones o graficos raros despues de actualizar el driver de video.
echo   En contra: la primera partida de cada juego va a tener tirones mientras los vuelve a armar.
echo   Conviene solo despues de actualizar el driver, no en cada limpieza.
choice /c SN /n /m "- Desea borrar la cache de shaders? [S] Si  [N] No: "
if errorlevel 2 (set "CLEAN_GPU=0") else (set "CLEAN_GPU=1")

echo.
echo   Puntos de restauracion:
echo   Que hace: borra los puntos de restauracion guardados; la proteccion del sistema sigue encendida.
echo   A favor: libera varios GB del disco.
echo   En contra: si algo sale mal, ya no podes volver a como estaba Windows antes.
choice /c SN /n /m "- Desea borrar los puntos de restauracion? [S] Si  [N] No: "
if errorlevel 2 (set "CLEAN_RP=0") else (set "CLEAN_RP=1")
echo.

set "XUCA_ARCH=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $s=[IO.File]::ReadAllText($env:XUCA_ARCH); Invoke-Expression $s.Substring($s.IndexOf('#PS_'+'START')) } catch { Write-Host ('Error en la limpieza: ' + $_.Exception.Message) -ForegroundColor Red }"

echo.
pause
exit /b

#PS_START
$ErrorActionPreference = 'SilentlyContinue'

function Format-Size([int64]$b) {
    if ($b -ge 1GB) { return ('{0:0.00} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:0.00} MB' -f ($b / 1MB)) }
    return ('{0:0.00} KB' -f ($b / 1KB))
}

# Expande los comodines (* o ?) de las rutas; las demas pasan tal cual
function Expand-Paths([string[]]$Paths) {
    foreach ($p in $Paths) {
        if ($p -match '[\*\?]') {
            Get-ChildItem -Path $p -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
        } else {
            $p
        }
    }
}

function Clear-Group([string]$Name, [string[]]$Paths) {
    $found = 0
    $deleted = 0
    $bytes = [int64]0
    foreach ($p in (Expand-Paths $Paths | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $p)) { continue }
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $files = @(Get-Item -LiteralPath $p -Force)
        } else {
            $files = @(Get-ChildItem -LiteralPath $p -File -Recurse -Force)
        }
        foreach ($f in $files) {
            $found++
            $len = $f.Length
            try {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                $deleted++
                $bytes += $len
            } catch { }
        }
    }
    $skipped = $found - $deleted
    Write-Host ("{0,-32} encontrados: {1,6}   borrados: {2,6}   en uso/omitidos: {3,5}   liberado: {4}" -f $Name, $found, $deleted, $skipped, (Format-Size $bytes))
    return [pscustomobject]@{ Deleted = $deleted; Bytes = $bytes }
}

$sysRoot = $env:SystemRoot
$sysDrive = $env:SystemDrive
$users = @(Get-ChildItem -LiteralPath ($sysDrive + '\Users') -Directory -Force |
    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
    ForEach-Object { $_.FullName })

function Per-User([string]$rel) { return @($users | ForEach-Object { Join-Path $_ $rel }) }

$totalFiles = 0
$totalBytes = [int64]0

# ---------------------------------------------------------------
# TEMPORALES
# ---------------------------------------------------------------
Write-Host "Deteniendo servicios de actualizacion..." -ForegroundColor Cyan
$svcs = @('wuauserv', 'bits' | ForEach-Object { Get-Service -Name $_ } | Where-Object { $_.Status -eq 'Running' })
foreach ($s in $svcs) { Stop-Service -Name $s.Name -Force }

$r = Clear-Group 'Windows Update' @(
    ($sysRoot + '\SoftwareDistribution\Download'),
    ($sysRoot + '\Logs\WindowsUpdate')
)
$totalFiles += $r.Deleted
$totalBytes += $r.Bytes

foreach ($s in $svcs) { Start-Service -Name $s.Name }

try { Delete-DeliveryOptimizationCache -Force } catch { }

$tempPaths = @(
    ($sysRoot + '\Temp'),
    ($sysRoot + '\ServiceProfiles\LocalService\AppData\Local\Temp'),
    ($sysRoot + '\ServiceProfiles\NetworkService\AppData\Local\Temp'),
    ($sysRoot + '\System32\config\systemprofile\AppData\Local\Temp')
) + (Per-User 'AppData\Local\Temp')
$r = Clear-Group 'Temporales' $tempPaths
$totalFiles += $r.Deleted
$totalBytes += $r.Bytes

$errPaths = @(
    ($sysRoot + '\MEMORY.DMP'),
    ($sysRoot + '\Minidump'),
    ($sysRoot + '\LiveKernelReports'),
    ($sysRoot + '\Logs\CBS'),
    ($sysRoot + '\Logs\DISM'),
    ($env:ProgramData + '\Microsoft\Windows\WER\ReportArchive'),
    ($env:ProgramData + '\Microsoft\Windows\WER\ReportQueue'),
    ($env:ProgramData + '\Microsoft\Windows\WER\Temp')
) + (Per-User 'AppData\Local\Microsoft\Windows\WER\ReportArchive') `
  + (Per-User 'AppData\Local\Microsoft\Windows\WER\ReportQueue') `
  + (Per-User 'AppData\Local\Microsoft\Windows\WER\Temp') `
  + (Per-User 'AppData\Local\CrashDumps') `
  + (Per-User 'AppData\Local\Microsoft\Windows\INetCache') `
  + (Per-User 'AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db') `
  + (Per-User 'AppData\Local\Microsoft\Terminal Server Client\Cache')
$r = Clear-Group 'Errores, volcados y logs' $errPaths
$totalFiles += $r.Deleted
$totalBytes += $r.Bytes

$old = $sysDrive + '\Windows.old'
if (Test-Path -LiteralPath $old) {
    Write-Host "Eliminando $old..." -ForegroundColor Cyan

    # 1) Liberar lo que tenga abierto Windows.old: procesos y servicios que corren desde ahi
    #    y servicios que suelen bloquear archivos (se vuelven a iniciar al terminar)
    $liberar = {
        Get-Process | Where-Object { $_.Path -and $_.Path -like ($old + '\*') } | Stop-Process -Force
        Get-CimInstance Win32_Service | Where-Object { $_.PathName -like ('*' + $old + '*') -and $_.State -eq 'Running' } |
            ForEach-Object { Stop-Service -Name $_.Name -Force }
    }
    $svcWo = @('WSearch', 'SysMain', 'TrustedInstaller' | ForEach-Object { Get-Service -Name $_ } | Where-Object { $_.Status -eq 'Running' })
    foreach ($s in $svcWo) { Stop-Service -Name $s.Name -Force }
    & $liberar

    # 2) Hasta 3 pasadas: tomar propiedad, dar permisos y borrar
    for ($i = 1; $i -le 3 -and (Test-Path -LiteralPath $old); $i++) {
        & takeown.exe /f $old /a /r /d s 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { & takeown.exe /f $old /a /r /d y 2>&1 | Out-Null }
        & icacls.exe $old /grant '*S-1-5-32-544:F' /t /c /q 2>&1 | Out-Null
        & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
        if (Test-Path -LiteralPath $old) {
            # Truco de robocopy: espeja una carpeta vacia encima (sirve con rutas muy largas)
            $empty = Join-Path $env:TEMP ('vacia_' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $empty -Force | Out-Null
            & robocopy.exe $empty $old /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP 2>&1 | Out-Null
            Remove-Item -LiteralPath $empty -Force
            & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
        }
        if (Test-Path -LiteralPath $old) { & $liberar; Start-Sleep -Seconds 3 }
    }

    foreach ($s in $svcWo) { Start-Service -Name $s.Name }

    if (Test-Path -LiteralPath $old) {
        # 3) Si todavia queda algo en uso: tarea unica que lo borra al reiniciar (antes de que nada lo use)
        $tn = 'BorrarWindowsOld'
        $act = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c rd /s /q ' + $old + ' & schtasks.exe /delete /tn ' + $tn + ' /f')
        $trg = New-ScheduledTaskTrigger -AtStartup
        $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName $tn -Action $act -Trigger $trg -Principal $prn -Force | Out-Null
        if (Get-ScheduledTask -TaskName $tn) {
            Write-Host 'Windows.old tiene archivos en uso: quedo programado el borrado para el proximo REINICIO (no apagar, reiniciar).' -ForegroundColor Yellow
        } else {
            Write-Host 'Windows.old no se pudo borrar del todo.' -ForegroundColor Yellow
        }
    } else {
        Write-Host 'Windows.old borrado.' -ForegroundColor Cyan
    }
}

# ---------------------------------------------------------------
# CACHES DE APPS Y VIDEO
# ---------------------------------------------------------------
$appPaths = @(
    (${env:ProgramFiles(x86)} + '\Steam\appcache\httpcache'),
    (${env:ProgramFiles(x86)} + '\Steam\htmlcache')
) + (Per-User 'AppData\Roaming\discord\Cache') `
  + (Per-User 'AppData\Roaming\discord\Code Cache') `
  + (Per-User 'AppData\Roaming\discord\GPUCache') `
  + (Per-User 'AppData\Local\Steam\htmlcache') `
  + (Per-User 'AppData\Local\EpicGamesLauncher\Saved\webcache*') `
  + (Per-User 'AppData\Local\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache')
$r = Clear-Group 'Apps (Discord/Steam/Epic/Store)' $appPaths
$totalFiles += $r.Deleted
$totalBytes += $r.Bytes

$gpuPaths = @(
    ($env:ProgramData + '\NVIDIA Corporation\NV_Cache')
) + (Per-User 'AppData\Local\NVIDIA\GLCache') `
  + (Per-User 'AppData\Local\NVIDIA\DXCache') `
  + (Per-User 'AppData\Local\NVIDIA\ComputeCache') `
  + (Per-User 'AppData\Local\NVIDIA\OptixCache') `
  + (Per-User 'AppData\Local\NVIDIA Corporation\NV_Cache') `
  + (Per-User 'AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache') `
  + (Per-User 'AppData\LocalLow\NVIDIA\PerDriverVersion\GLCache') `
  + (Per-User 'AppData\Local\AMD\DxCache') `
  + (Per-User 'AppData\Local\AMD\GLCache') `
  + (Per-User 'AppData\Local\AMD\VkCache') `
  + (Per-User 'AppData\Local\AMD\DxcCache') `
  + (Per-User 'AppData\Roaming\AMD\ComputeCache') `
  + (Per-User 'AppData\Local\Intel\ShaderCache') `
  + (Per-User 'AppData\Local\D3DSCache')
if ($env:CLEAN_GPU -eq '1') {
    $r = Clear-Group 'Cache de video (shaders)' $gpuPaths
    $totalFiles += $r.Deleted
    $totalBytes += $r.Bytes
} else {
    Write-Host 'Cache de shaders: no se toco (los juegos no van a tener tirones de mas).' -ForegroundColor Yellow
}

Write-Host "Vaciando Visor de Eventos..." -ForegroundColor Cyan
wevtutil.exe el | ForEach-Object { wevtutil.exe cl $_ 2>$null }

Write-Host "Restableciendo Microsoft Store (WSReset)..." -ForegroundColor Cyan
Start-Process -FilePath 'WSReset.exe' -Wait -WindowStyle Hidden
Start-Sleep -Seconds 2
Get-Process -Name 'WinStore.App' -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Restableciendo cache de resolucion DNS..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null

# ---------------------------------------------------------------
# COMPONENTES VIEJOS DE WINDOWS
# ---------------------------------------------------------------
Write-Host "Limpiando componentes viejos de Windows (DISM), puede tardar varios minutos..." -ForegroundColor Cyan
Start-Process -FilePath 'DISM.exe' -ArgumentList '/Online', '/Cleanup-Image', '/StartComponentCleanup' -Wait -NoNewWindow

# ---------------------------------------------------------------
# PAPELERA (solo si se pidio)
# ---------------------------------------------------------------
if ($env:CLEAN_BIN -eq '1') {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host 'Papelera de reciclaje vaciada (no se suma al total).' -ForegroundColor Cyan
    } catch { }
} else {
    Write-Host 'Papelera de reciclaje: no se toco.' -ForegroundColor Yellow
}

# ---------------------------------------------------------------
# PUNTOS DE RESTAURACION (solo si se pidio; la proteccion del sistema no se toca)
# ---------------------------------------------------------------
if ($env:CLEAN_RP -eq '1') {
    Write-Host "Borrando puntos de restauracion..." -ForegroundColor Cyan
    & vssadmin.exe delete shadows "/for=$sysDrive" /all /quiet 2>&1 | Out-Null
    $quedan = @(Get-CimInstance Win32_ShadowCopy).Count
    if ($quedan -eq 0) {
        Write-Host 'Puntos de restauracion borrados.' -ForegroundColor Cyan
    } else {
        Write-Host ('Quedan ' + $quedan + ' puntos de restauracion que no se pudieron borrar.') -ForegroundColor Yellow
    }
} else {
    Write-Host 'Puntos de restauracion: no se tocaron.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=========================================='
Write-Host '             RESULTADO FINAL'
Write-Host '=========================================='
Write-Host ''
Write-Host ('Archivos eliminados : ' + $totalFiles)
Write-Host ('Espacio liberado    : ' + (Format-Size $totalBytes))
Write-Host ''
Write-Host '=========================================='
Write-Host 'Limpieza terminada.'
Write-Host '=========================================='
