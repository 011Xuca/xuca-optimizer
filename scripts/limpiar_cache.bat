@echo off
setlocal EnableExtensions
set "XUCA_SELF=%~f0"
rem ============================================================
rem  ACTUALIZACIONES DESDE GITHUB
rem  La version se controla con el archivo version.txt del repo.
rem  Si el version.txt de GitHub es distinto al que tenes en tu PC,
rem  al abrir sale el cartel amarillo de actualizacion.
rem ============================================================
set "XUCA_REPO=011Xuca/xuca-optimizer"
set "XUCA_RAMA=main"
set "XUCA_GH=scripts/limpiar_cache.bat"
rem Si el archivo quedo con saltos de linea de Linux (LF), cmd salta a etiquetas equivocadas: se corrige solo y se vuelve a abrir.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $f=$env:XUCA_SELF; $e=[Text.Encoding]::GetEncoding(28591); $t=$e.GetString([IO.File]::ReadAllBytes($f)); if ($t -match '(^|[^\r])\n') { [IO.File]::WriteAllText($f, ($t -replace '\r?\n', ([string][char]13 + [char]10)), $e); exit 9 }; exit 0 } catch { exit 0 }" >nul 2>&1
if errorlevel 9 "%~f0" %*
title Limpieza de cache (Xuca)
color 0B

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Pidiendo permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath $env:XUCA_SELF -Verb RunAs"
    exit /b
)

rem Buscar actualizacion en GitHub (no corre cuando lo usa la app ni cuando se abre con parametros).
rem Si hay una version nueva muestra el cartel amarillo y pregunta. Si la bajas, se cierra esta ventana y se abre la nueva.
if defined XUCA_AUTO goto upd_fin
if not "%~1"=="" goto upd_fin
powershell -NoProfile -ExecutionPolicy Bypass -Command "$global:XucaUpd=0; try { $s=[IO.File]::ReadAllText($env:XUCA_SELF); $a='<#'+'XUCA-UPD'; $b='XUCA-UPD'+'#>'; $i=$s.IndexOf($a)+$a.Length; Invoke-Expression $s.Substring($i, $s.IndexOf($b)-$i) } catch { }; exit [int]$global:XucaUpd"
if errorlevel 10 exit
:upd_fin

echo.
echo ==========================================
echo       LIMPIEZA DE CACHE - XUCA
echo ==========================================
echo.

echo Se va a limpiar, sin preguntar: temporales, cache de Windows Update, Windows.old,
echo volcados y logs de errores, caches de apps, Visor de Eventos,
echo Microsoft Store, DNS y componentes viejos de Windows (DISM).
echo Antes te pregunta por tres cosas que conviene decidir vos.
rem Modo app: las tres respuestas ya vienen en CLEAN_BIN, CLEAN_GPU y CLEAN_RP.
if defined XUCA_AUTO goto preguntas_fin

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
:preguntas_fin
echo.

set "XUCA_ARCH=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $s=[IO.File]::ReadAllText($env:XUCA_ARCH); Invoke-Expression $s.Substring($s.IndexOf('#PS_'+'START')) } catch { Write-Host ('Error en la limpieza: ' + $_.Exception.Message) -ForegroundColor Red }"

if not defined XUCA_AUTO echo.
if not defined XUCA_AUTO echo Este proyecto es gratis. Si te sirvio y queres apoyarme: https://ko-fi.com/011xuca
echo.
if not defined XUCA_AUTO pause
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

# Lista los archivos de una carpeta sin entrar en accesos directos de carpeta (junctions o enlaces).
# Un usuario comun puede crear en Temp un enlace a System32: si se siguiera, la limpieza (que corre como admin) borraria archivos de Windows.
function Archivos-Seguro([string]$raiz) {
    $rp = [IO.FileAttributes]::ReparsePoint
    $ini = New-Object IO.DirectoryInfo($raiz)
    if ((-not $ini.Exists) -or (($ini.Attributes -band $rp) -ne 0)) { return }
    # Tampoco si alguna carpeta del medio es un enlace (por ejemplo AppData\Local\Microsoft apuntando a otro lado)
    for ($a = $ini.Parent; $a -and ($a.FullName.TrimEnd('\').Split('\').Count -gt 3); $a = $a.Parent) { if (($a.Attributes -band $rp) -ne 0) { return } }
    $pila = New-Object System.Collections.Generic.Stack[IO.DirectoryInfo]
    $pila.Push($ini)
    while ($pila.Count -gt 0) {
        $d = $pila.Pop()
        try { $hijos = $d.GetFileSystemInfos() } catch { continue }
        foreach ($h in $hijos) {
            if ($h -is [IO.DirectoryInfo]) { if (($h.Attributes -band $rp) -eq 0) { $pila.Push($h) } }
            else { $h }
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
            $files = @(Archivos-Seguro $p)
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
# Solo se borra si es la carpeta que dejo Windows: no un enlace y con duenio SYSTEM, TrustedInstaller o Administradores.
# (Cualquier usuario puede crear una carpeta en C:\; si se borrara a ciegas, como admin, podria usarse para romper Windows.)
$oldOk = $false
if (Test-Path -LiteralPath $old) {
    try {
        $oi = Get-Item -LiteralPath $old -Force
        $dn = (Get-Acl -LiteralPath $old).GetOwner([Security.Principal.SecurityIdentifier]).Value
        $duenioOk = ($dn -in 'S-1-5-18', 'S-1-5-32-544', 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464', [Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
        if (-not $duenioOk) { try { $duenioOk = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop | Where-Object { $_.SID.Value -eq $dn }).Count -gt 0 } catch { } }
        $oldOk = (($oi.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) -and $duenioOk
    } catch { }
    if (-not $oldOk) { Write-Host 'Windows.old no parece la carpeta que deja Windows al actualizarse: no se toco.' -ForegroundColor Yellow }
}
if ($oldOk) {
    Write-Host ''
    Write-Host ('Borrando Windows.old (' + $old + ')...') -ForegroundColor Cyan
    Write-Host '  OJO: Windows.old SIEMPRE tarda mucho en borrarse: tiene miles de archivos de tu Windows anterior.' -ForegroundColor Yellow
    Write-Host '  Puede llevar de 5 a 20 minutos (mas en un disco HDD). No cierres la ventana: no esta trabado.' -ForegroundColor Yellow

    # 0) Permisos: sin ser administrador no se puede borrar
    $esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $esAdmin) {
        Write-Host '  No hay permisos de administrador: Windows.old no se toco. Abri la limpieza como administrador.' -ForegroundColor Yellow
    }
}
if ($oldOk -and $esAdmin) {
    # 1) Cerrar todo lo que tenga abierto algo de Windows.old: programas que corren desde ahi o que abrieron un archivo
    #    de ahi (se ve en su linea de comandos) y servicios. Lo que lanza esta limpieza (cmd, robocopy...) no se toca.
    $cerrarWo = {
        param($old)
        $n = 0
        $yo = $PID
        foreach ($pr in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
            if (($pr.ProcessId -eq $yo) -or ($pr.ParentProcessId -eq $yo)) { continue }
            $ruta = [string]$pr.ExecutablePath; $cl = [string]$pr.CommandLine
            if (($ruta -like ($old + '\*')) -or ($cl -like ('*' + $old + '\*')) -or ($cl -like ('*' + $old + '"*'))) {
                try { Stop-Process -Id $pr.ProcessId -Force -ErrorAction Stop; $n++ } catch { }
            }
        }
        foreach ($sv in @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ([string]$_.PathName -like ('*' + $old + '\*')) -and ($_.State -eq 'Running') })) {
            try { Stop-Service -Name $sv.Name -Force -ErrorAction Stop; $n++ } catch { }
        }
        return $n
    }
    # Ventanas del Explorador abiertas en Windows.old (o en una carpeta de adentro)
    function Cerrar-VentanasWo {
        $n = 0
        try {
            $sh = New-Object -ComObject Shell.Application
            foreach ($w in @($sh.Windows())) {
                $ru = ''
                try { $ru = [string]$w.Document.Folder.Self.Path } catch { }
                if ($ru -and (($ru -eq $old) -or ($ru -like ($old + '\*')))) { try { $w.Quit(); $n++ } catch { } }
            }
        } catch { }
        return $n
    }
    $svcWo = @('WSearch', 'SysMain', 'TrustedInstaller' | ForEach-Object { Get-Service -Name $_ } | Where-Object { $_.Status -eq 'Running' })
    foreach ($s in $svcWo) { Stop-Service -Name $s.Name -Force }
    $cerrados = [int](& $cerrarWo $old) + [int](Cerrar-VentanasWo)
    if ($cerrados -gt 0) { Write-Host ('  Se cerraron ' + $cerrados + ' programas o ventanas que tenian abierto algo de Windows.old.') -ForegroundColor Yellow }

    # Vigilante: mientras se borra, cada segundo vuelve a cerrar lo que se abra desde Windows.old
    $vig = [hashtable]::Synchronized(@{ Seguir = $true; Cerrados = 0 })
    $vps = [powershell]::Create()
    [void]$vps.AddScript({
        param($old, $vig, $codigo)
        $f = [scriptblock]::Create($codigo)
        while ($vig.Seguir) {
            try { $vig.Cerrados += [int](& $f $old) } catch { }
            Start-Sleep -Milliseconds 1000
        }
    }).AddArgument($old).AddArgument($vig).AddArgument($cerrarWo.ToString())
    $vh = $vps.BeginInvoke()

    # 2) Una pasada: tomar propiedad, dar permisos y borrar. Si queda algo, un solo reintento rapido (sin volver a
    #    tomar permisos, que es lo lento) y se sigue con el resto de la limpieza.
    try {
        for ($i = 1; $i -le 2 -and (Test-Path -LiteralPath $old); $i++) {
            if ($i -gt 1) {
                Write-Host '  Quedaron archivos: un ultimo intento rapido...' -ForegroundColor Yellow
                & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
                break
            }
            Write-Host '  Revisando permisos de la carpeta...'
            & takeown.exe /f $old /a /r /d s 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { & takeown.exe /f $old /a /r /d y 2>&1 | Out-Null }
            $okT = ($LASTEXITCODE -eq 0)
            & icacls.exe $old /grant '*S-1-5-32-544:F' /t /c /q 2>&1 | Out-Null
            $okI = ($LASTEXITCODE -eq 0)
            if ($okT -and $okI) { Write-Host '  Permisos: OK (los administradores tienen control total).' -ForegroundColor Green }
            else { Write-Host '  Algunos archivos no dejaron cambiar sus permisos: se intenta borrar igual.' -ForegroundColor Yellow }
            Write-Host '  Borrando los archivos (este es el paso lento)...'
            & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
            if (Test-Path -LiteralPath $old) {
                # Truco de robocopy: espeja una carpeta vacia encima (sirve con rutas muy largas)
                $empty = Join-Path $env:TEMP ('vacia_' + [guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path $empty -Force | Out-Null
                & robocopy.exe $empty $old /MIR /XJ /R:1 /W:1 /NFL /NDL /NJH /NJS /NP 2>&1 | Out-Null
                Remove-Item -LiteralPath $empty -Force
                & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
            }
            if (Test-Path -LiteralPath $old) { [void](& $cerrarWo $old); [void](Cerrar-VentanasWo); Start-Sleep -Seconds 3 }
        }
    } finally {
        $vig.Seguir = $false
        try { [void]$vps.EndInvoke($vh) } catch { }
        try { $vps.Dispose() } catch { }
    }
    if ($vig.Cerrados -gt 0) { Write-Host ('  Mientras se borraba se volvieron a cerrar ' + $vig.Cerrados + ' programas que abrian algo de Windows.old.') -ForegroundColor Yellow }

    foreach ($s in $svcWo) { Start-Service -Name $s.Name }

    if (Test-Path -LiteralPath $old) {
        # 3) No se dejo borrar: aviso y se sigue de largo. Queda una tarea unica que lo borra al reiniciar (antes de que nada lo use).
        Write-Host 'No se pudo borrar Windows.old ahora: Windows tiene algo en uso o no dio permiso. Se sigue con el resto de la limpieza.' -ForegroundColor Yellow
        $tn = 'BorrarWindowsOld'
        try {
            $act = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c rd /s /q "' + $old + '" & schtasks.exe /delete /tn ' + $tn + ' /f')
            $trg = New-ScheduledTaskTrigger -AtStartup
            $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
            Register-ScheduledTask -TaskName $tn -Action $act -Trigger $trg -Principal $prn -Force | Out-Null
        } catch { }
        if (Get-ScheduledTask -TaskName $tn) {
            Write-Host '  Quedo programado para borrarse solo en el proximo REINICIO (reiniciar, no apagar).' -ForegroundColor Yellow
            if ($env:XUCA_AUTO) { Write-Host 'XWOLD|programado' }
        } else {
            Write-Host '  Proba de nuevo despues de reiniciar la PC.' -ForegroundColor Yellow
            if ($env:XUCA_AUTO) { Write-Host 'XWOLD|fallo' }
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

<#XUCA-UPD
# ------------------------------------------------------------
# Buscador de actualizaciones. Lo corre la parte de arriba del .bat.
# Esta dentro de un comentario para que el resto del PowerShell de este archivo lo ignore.
# Compara el version.txt de tu PC con el de GitHub: si son distintos, avisa.
# ------------------------------------------------------------
& {
    $ErrorActionPreference = 'Stop'
    $repo = [string]$env:XUCA_REPO; $rama = [string]$env:XUCA_RAMA; $gh = [string]$env:XUCA_GH
    $self = [string]$env:XUCA_SELF
    if ((-not $repo) -or ($repo -like 'TU_USUARIO*')) { return }
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
    $latin = [Text.Encoding]::GetEncoding(28591)
    $base = 'https://raw.githubusercontent.com/' + $repo + '/' + $rama + '/'

    # Si el .bat esta en la carpeta scripts de la app, el version.txt es el de la app (al lado de XucaOP.ps1).
    # Si esta suelto, el version.txt va en la misma carpeta que el .bat.
    $dir = Split-Path -Parent $self
    $arriba = Split-Path -Parent $dir
    $conApp = [bool]($arriba -and (Test-Path -LiteralPath (Join-Path $arriba 'XucaOP.ps1')))
    $raiz = $(if ($conApp) { $arriba } else { $dir })
    $verLocal = Join-Path $raiz 'version.txt'

    function Limpiar([string]$t) { return (($t -replace '^(\u00EF\u00BB\u00BF|\uFEFF)', '') -split "`r?`n")[0].Trim() }
    function Bajar([string]$remoto, [int]$espera, [string]$etiqueta) {
        $rq = [Net.HttpWebRequest]::Create($base + $remoto + '?nc=' + [DateTime]::UtcNow.Ticks)
        $rq.Timeout = $espera; $rq.ReadWriteTimeout = $espera; $rq.UserAgent = 'XucaOP'
        $rs = $rq.GetResponse()
        try {
            $len = $rs.ContentLength
            $st = $rs.GetResponseStream(); $ms = New-Object IO.MemoryStream; $buf = New-Object byte[] 65536
            while (($r = $st.Read($buf, 0, $buf.Length)) -gt 0) {
                $ms.Write($buf, 0, $r)
                if ($etiqueta -and ($len -gt 0)) { [Console]::Write("`r  Descargando " + $etiqueta + ': ' + [int](100 * $ms.Length / $len) + '%   ') }
            }
            if ($etiqueta) { [Console]::WriteLine('') }
            return $latin.GetString($ms.ToArray())
        } finally { $rs.Close() }
    }

    $local = ''
    if (Test-Path -LiteralPath $verLocal) { try { $local = Limpiar ([IO.File]::ReadAllText($verLocal)) } catch { } }
    [Console]::Write('Buscando actualizaciones...')
    $remota = ''
    try { $remota = Limpiar (Bajar 'version.txt' 4000 '') } catch { }
    [Console]::Write("`r" + (' ' * 30) + "`r")
    if ((-not $remota) -or ($remota -eq $local)) { return }

    # Cartel amarillo. En Windows Terminal se ve el simbolo de advertencia; en la consola vieja va /!\
    $icono = '/!\'
    if ($env:WT_SESSION) { $icono = [string][char]0x26A0 }
    $ancho = 76
    try { $ancho = [math]::Max(40, [math]::Min([Console]::WindowWidth - 1, 76)) } catch { }
    $tuya = $(if ($local) { $local } else { 'sin version' })
    Write-Host ''
    foreach ($l in @('', ('  ' + $icono + '  HAY UNA ACTUALIZACION DISPONIBLE'), ('     Tenes la version ' + $tuya + ' y en GitHub esta la ' + $remota + '.'), '     Si la bajas, se cierra esta ventana y se abre la version nueva sola.', '')) {
        $t = $l; if ($t.Length -gt $ancho) { $t = $t.Substring(0, $ancho) }
        Write-Host ($t.PadRight($ancho)) -ForegroundColor Black -BackgroundColor Yellow
    }
    Write-Host ''
    Write-Host '- Desea descargar la actualizacion? [S] Si  [N] No: ' -NoNewline -ForegroundColor Yellow
    $k = ''
    while (@('S', 'N') -notcontains $k) { $k = ([string][Console]::ReadKey($true).KeyChar).ToUpper() }
    Write-Host $k
    if ($k -eq 'N') {
        Write-Host '  Seguis con esta version.' -ForegroundColor DarkGray
        Write-Host ''
        return
    }

    # Que se baja: con la app, todo (app y los 3 scripts). Suelto, este .bat y los otros scripts que esten en la misma carpeta.
    $lista = @()
    if ($conApp) {
        foreach ($r in 'XucaOP.ps1', 'scripts/windows_debloat.bat', 'scripts/optimizacion_gaming.bat', 'scripts/limpiar_cache.bat', 'lang/en-en/textos.txt', 'lang/es-mx/textos.txt') {
            $lista += [pscustomobject]@{ Remoto = $r; Local = (Join-Path $raiz ($r -replace '/', '\')); Opc = ($r -like 'lang/*') }
        }
    } else {
        $lista += [pscustomobject]@{ Remoto = $gh; Local = $self }
        foreach ($n in 'windows_debloat.bat', 'optimizacion_gaming.bat', 'limpiar_cache.bat') {
            $p = Join-Path $dir $n
            if (('scripts/' + $n) -ne $gh -and (Test-Path -LiteralPath $p)) { $lista += [pscustomobject]@{ Remoto = ('scripts/' + $n); Local = $p } }
        }
    }

    # Se baja todo a archivos .nuevo; el version.txt va ultimo
    $nuevos = @()
    try {
        foreach ($a in $lista) {
            # Los opcionales (los idiomas de la app) se saltean si todavia no estan en GitHub
            try { $txt = Bajar $a.Remoto 30000 (Split-Path -Leaf $a.Remoto) } catch { if ($a.Opc) { continue }; throw }
            if ($txt.Length -lt 100) { if ($a.Opc) { continue }; throw ('lo que llego de GitHub para ' + $a.Remoto + ' no es el archivo esperado') }
            $tmp = $a.Local + '.nuevo'
            $dd = Split-Path -Parent $tmp
            if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
            [IO.File]::WriteAllText($tmp, ($txt -replace '\r?\n', "`r`n"), $latin)
            $nuevos += [pscustomobject]@{ Tmp = $tmp; Local = $a.Local }
        }
        $tmp = $verLocal + '.nuevo'
        [IO.File]::WriteAllText($tmp, ($remota + "`r`n"), $latin)
        $nuevos += [pscustomobject]@{ Tmp = $tmp; Local = $verLocal }
    } catch {
        foreach ($n in $nuevos) { Remove-Item -LiteralPath $n.Tmp -Force -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath ($verLocal + '.nuevo') -Force -ErrorAction SilentlyContinue
        Write-Host ('  No se pudo descargar: ' + $_.Exception.Message) -ForegroundColor Red
        Write-Host '  Seguis con esta version.' -ForegroundColor DarkGray
        Start-Sleep -Seconds 3
        return
    }

    # Un ayudante oculto espera a que se cierre esta ventana, pone los archivos nuevos en lugar de los viejos y abre este .bat.
    $padre = 0
    try { $padre = [int](Get-CimInstance Win32_Process -Filter ('ProcessId=' + $PID)).ParentProcessId } catch { }
    $c = { param($s) "'" + ($s -replace "'", "''") + "'" }
    $h = @(
        ('$p = ' + $padre),
        'Start-Sleep -Milliseconds 800',
        '$fin = (Get-Date).AddSeconds(30)',
        'while (($p -gt 0) -and (Get-Process -Id $p -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $fin)) { Start-Sleep -Milliseconds 200 }'
    )
    foreach ($n in $nuevos) {
        $h += ('for ($i = 0; $i -lt 30; $i++) { try { Move-Item -LiteralPath ' + (& $c $n.Tmp) + ' -Destination ' + (& $c $n.Local) + ' -Force -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds 300 } }')
    }
    $h += ('Start-Process -FilePath ' + (& $c $self) + ' -WorkingDirectory ' + (& $c $dir))
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($h -join "`n")))
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + $enc)
    Write-Host '  Listo. Se cierra esta ventana y se abre la version nueva.' -ForegroundColor Green
    Start-Sleep -Milliseconds 1200
    $global:XucaUpd = 10
}
XUCA-UPD#>
