# ============================================================
#  LIMPIEZA DE CACHE (antes era limpiar_cache.bat)
#  Lo corre la app XucaOP.ps1 en un hilo aparte, con Comun.ps1 cargado: ya no se abre cmd ni otro PowerShell.
#  Se limpia sin preguntar: temporales, cache de Windows Update, Windows.old, volcados y logs de errores,
#  restos de instalaciones, caches de apps, Visor de Eventos, Microsoft Store, DNS y componentes viejos (DISM).
#  Lo que se decide en la app viene en CLEAN_BIN (papelera), CLEAN_GPU (shaders) y CLEAN_RP (puntos de restauracion).
#  La app sigue el progreso por las lineas que se escriben (ver $PasosLimpieza en XucaOP.ps1): si cambias un texto, cambialo alla tambien.
# ============================================================

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
    Say ("{0,-32} encontrados: {1,6}   borrados: {2,6}   en uso/omitidos: {3,5}   liberado: {4}" -f $Name, $found, $deleted, $skipped, (Format-Size $bytes))
    return [pscustomobject]@{ Deleted = $deleted; Bytes = $bytes }
}

# Lo que llama la app. $salida = archivo donde la app lee el progreso (y que despues guarda en logs).
function Correr-Limpieza([string]$salida, [string]$carpeta) {
    try {
        Abrir-Salida $salida
        Say ''
        Say '=========================================='
        Say '      LIMPIEZA DE CACHE - XUCA'
        Say '=========================================='
        Say ''
        Say ('Papelera: ' + $(if ($env:CLEAN_BIN -eq '1') { 'si' } else { 'no' }) + ' - Shaders: ' + $(if ($env:CLEAN_GPU -eq '1') { 'si' } else { 'no' }) + ' - Puntos de restauracion: ' + $(if ($env:CLEAN_RP -eq '1') { 'si' } else { 'no' }))
        Say ''

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
        Say "Deteniendo servicios de actualizacion..." 'Cyan'
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

        # Restos que dejan las instalaciones y actualizaciones en C:\ (instaladores de drivers ya descomprimidos,
        # descargas de actualizaciones de Windows que ya se usaron, temporales de OneDrive y logs de rendimiento).
        # NO se tocan a proposito: C:\inetpub (desde abril 2025 Windows la crea como proteccion de seguridad y Microsoft
        # pide no borrarla) ni ProgramData\Package Cache (sin eso no se pueden desinstalar ni reparar Visual C++, Visual Studio, etc.).
        # Igual que con Temp, Archivos-Seguro no entra en enlaces: si alguien crea C:\NVIDIA como enlace a otro lado, no se toca.
        $restos = @(
            ($sysDrive + '\OneDriveTemp'),
            ($sysDrive + '\PerfLogs'),
            ($sysDrive + '\$WINDOWS.~BT'),
            ($sysDrive + '\$WINDOWS.~WS'),
            ($sysDrive + '\$GetCurrent'),
            ($sysDrive + '\$SysReset'),
            ($sysDrive + '\ESD\Download'),
            ($sysDrive + '\ESD\Windows'),
            ($sysDrive + '\NVIDIA'),
            ($sysDrive + '\AMD'),
            ($env:ProgramData + '\NVIDIA Corporation\Downloader')
        )
        $r = Clear-Group 'Restos de instalaciones' $restos
        $totalFiles += $r.Deleted
        $totalBytes += $r.Bytes
        # Las carpetas que quedaron vacias tambien se borran (de la mas profunda a la de arriba; los enlaces no se tocan).
        # PerfLogs se deja vacia porque es de Windows.
        foreach ($raizR in $restos) {
            if ($raizR -like '*\PerfLogs') { continue }
            $ri = New-Object IO.DirectoryInfo($raizR)
            if ((-not $ri.Exists) -or (($ri.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { continue }
            $dirs = New-Object System.Collections.Generic.List[IO.DirectoryInfo]
            $pilaR = New-Object System.Collections.Generic.Stack[IO.DirectoryInfo]
            $pilaR.Push($ri)
            while ($pilaR.Count -gt 0) {
                $d = $pilaR.Pop(); $dirs.Add($d)
                try { foreach ($h in $d.GetDirectories()) { if (($h.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) { $pilaR.Push($h) } } } catch { }
            }
            for ($k = $dirs.Count - 1; $k -ge 0; $k--) { try { [IO.Directory]::Delete($dirs[$k].FullName, $false) } catch { } }
        }

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
            if (-not $oldOk) { Say 'Windows.old no parece la carpeta que deja Windows al actualizarse: no se toco.' 'Yellow' }
        }
        if ($oldOk) {
            Say ''
            Say ('Borrando Windows.old (' + $old + ')...') 'Cyan'
            Say '  OJO: Windows.old SIEMPRE tarda mucho en borrarse: tiene miles de archivos de tu Windows anterior.' 'Yellow'
            Say '  Puede llevar de 5 a 20 minutos (mas en un disco HDD). No cierres la ventana: no esta trabado.' 'Yellow'

            # 0) Permisos: sin ser administrador no se puede borrar
            $esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            if (-not $esAdmin) {
                Say '  No hay permisos de administrador: Windows.old no se toco. Abri la limpieza como administrador.' 'Yellow'
            }
        }
        if ($oldOk -and $esAdmin) {
            # 1) Cerrar todo lo que tenga abierto algo de Windows.old: programas que corren desde ahi o que abrieron un archivo
            #    de ahi (se ve en su linea de comandos) y servicios. La app y lo que lanza esta limpieza (cmd, robocopy...) no se tocan.
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
            if ($cerrados -gt 0) { Say ('  Se cerraron ' + $cerrados + ' programas o ventanas que tenian abierto algo de Windows.old.') 'Yellow' }

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
                        Say '  Quedaron archivos: un ultimo intento rapido...' 'Yellow'
                        & cmd.exe /c ('rd /s /q "' + $old + '"') 2>&1 | Out-Null
                        break
                    }
                    Say '  Revisando permisos de la carpeta...'
                    & takeown.exe /f $old /a /r /d s 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) { & takeown.exe /f $old /a /r /d y 2>&1 | Out-Null }
                    $okT = ($LASTEXITCODE -eq 0)
                    & icacls.exe $old /grant '*S-1-5-32-544:F' /t /c /q 2>&1 | Out-Null
                    $okI = ($LASTEXITCODE -eq 0)
                    if ($okT -and $okI) { Say '  Permisos: OK (los administradores tienen control total).' 'Green' }
                    else { Say '  Algunos archivos no dejaron cambiar sus permisos: se intenta borrar igual.' 'Yellow' }
                    Say '  Borrando los archivos (este es el paso lento)...'
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
            if ($vig.Cerrados -gt 0) { Say ('  Mientras se borraba se volvieron a cerrar ' + $vig.Cerrados + ' programas que abrian algo de Windows.old.') 'Yellow' }

            foreach ($s in $svcWo) { Start-Service -Name $s.Name }

            if (Test-Path -LiteralPath $old) {
                # 3) No se dejo borrar: aviso y se sigue de largo. Queda una tarea unica que lo borra al reiniciar (antes de que nada lo use).
                Say 'No se pudo borrar Windows.old ahora: Windows tiene algo en uso o no dio permiso. Se sigue con el resto de la limpieza.' 'Yellow'
                $tn = 'BorrarWindowsOld'
                try {
                    $act = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c rd /s /q "' + $old + '" & schtasks.exe /delete /tn ' + $tn + ' /f')
                    $trg = New-ScheduledTaskTrigger -AtStartup
                    $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
                    Register-ScheduledTask -TaskName $tn -Action $act -Trigger $trg -Principal $prn -Force | Out-Null
                } catch { }
                if (Get-ScheduledTask -TaskName $tn) {
                    Say '  Quedo programado para borrarse solo en el proximo REINICIO (reiniciar, no apagar).' 'Yellow'
                    Say 'XWOLD|programado'
                } else {
                    Say '  Proba de nuevo despues de reiniciar la PC.' 'Yellow'
                    Say 'XWOLD|fallo'
                }
            } else {
                Say 'Windows.old borrado.' 'Cyan'
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
            Say 'Cache de shaders: no se toco (los juegos no van a tener tirones de mas).' 'Yellow'
        }

        Say "Vaciando Visor de Eventos..." 'Cyan'
        wevtutil.exe el | ForEach-Object { wevtutil.exe cl $_ 2>$null | Out-Null }

        Say "Restableciendo Microsoft Store (WSReset)..." 'Cyan'
        Start-Process -FilePath 'WSReset.exe' -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Get-Process -Name 'WinStore.App' -ErrorAction SilentlyContinue | Stop-Process -Force

        Say "Restableciendo cache de resolucion DNS..." 'Cyan'
        ipconfig /flushdns | Out-Null

        # ---------------------------------------------------------------
        # COMPONENTES VIEJOS DE WINDOWS
        # ---------------------------------------------------------------
        Say "Limpiando componentes viejos de Windows (DISM), puede tardar varios minutos..." 'Cyan'
        Start-Process -FilePath 'DISM.exe' -ArgumentList '/Online', '/Cleanup-Image', '/StartComponentCleanup' -Wait -WindowStyle Hidden

        # ---------------------------------------------------------------
        # PAPELERA (solo si se pidio)
        # ---------------------------------------------------------------
        if ($env:CLEAN_BIN -eq '1') {
            try {
                Clear-RecycleBin -Force -ErrorAction Stop
                Say 'Papelera de reciclaje vaciada (no se suma al total).' 'Cyan'
            } catch { }
        } else {
            Say 'Papelera de reciclaje: no se toco.' 'Yellow'
        }

        # ---------------------------------------------------------------
        # PUNTOS DE RESTAURACION (solo si se pidio; la proteccion del sistema no se toca)
        # ---------------------------------------------------------------
        if ($env:CLEAN_RP -eq '1') {
            Say "Borrando puntos de restauracion..." 'Cyan'
            & vssadmin.exe delete shadows "/for=$sysDrive" /all /quiet 2>&1 | Out-Null
            $quedan = @(Get-CimInstance Win32_ShadowCopy).Count
            if ($quedan -eq 0) {
                Say 'Puntos de restauracion borrados.' 'Cyan'
            } else {
                Say ('Quedan ' + $quedan + ' puntos de restauracion que no se pudieron borrar.') 'Yellow'
            }
        } else {
            Say 'Puntos de restauracion: no se tocaron.' 'Yellow'
        }

        Say ''
        Say '=========================================='
        Say '             RESULTADO FINAL'
        Say '=========================================='
        Say ''
        Say ('Archivos eliminados : ' + $totalFiles)
        Say ('Espacio liberado    : ' + (Format-Size $totalBytes))
        Say ''
        Say '=========================================='
        Say 'Limpieza terminada.'
        Say '=========================================='
    } finally {
        Cerrar-Salida
    }
}
