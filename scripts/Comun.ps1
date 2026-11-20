# ============================================================
#  COMUN: lo que usan todas las partes del optimizador (Gaming, Debloat y, mas adelante, Limpieza).
#  La app Brio.ps1 carga este archivo y el de la parte (Gaming.ps1 o Debloat.ps1) en un hilo aparte,
#  dentro del mismo proceso: ya no se abre cmd ni un powershell.exe nuevo por cada opcion.
#  Cada cambio se verifica y queda anotado en la carpeta "logs", igual que con los .bat.
#  Este archivo va sin acentos (igual que los demas) para que ninguna PC lo rompa.
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

# Si a la PC le falta System32 en el PATH, sc.exe, reg.exe, powercfg y los demas no se encontrarian
$s32 = Join-Path $env:SystemRoot 'System32'
if ((';' + $env:Path + ';') -notlike ('*;' + $s32 + ';*')) { $env:Path = $s32 + ';' + $env:Path }

# Windows 7 no trae estos comandos (llegaron con Windows 8) y ahi no hay apps de la Store ni tareas nuevas.
# Se responden vacios: si faltaran, la limpieza y el resumen final se cortarian a la mitad.
if ([Environment]::OSVersion.Version -lt [version]'6.2') {
    foreach ($c in 'Get-AppxPackage', 'Get-AppxProvisionedPackage', 'Get-ScheduledTask') {
        if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { Set-Item -Path ('function:' + $c) -Value { } }
    }
}

# Estado de la corrida
$XSalida = $null            # lo que la app lee para mostrar el progreso
$XLog = $null               # archivo de log
$OptT = 0; $OptF = 0; $OptS = 0; $OptP = 0
$QAct = ''                  # opcion que se esta aplicando
$Reinicio = $false          # alguna opcion que necesita reiniciar cambio algo de verdad
$ReinIds = @()
$VgAviso = $false           # se apago algo de seguridad: hay que reiniciar antes de jugar Valorant
$VgBorrado = $false          # se quito Vanguard en esta corrida: reinicio obligatorio
$VgHecho = $false           # Vanguard ya se reviso (o se borro) en una opcion anterior
$Build = 0; $RamGB = 0; $EsHdd = $false; $Stamp = ''
$XCarpeta = ''              # carpeta scripts (donde estan los .ps1, Edge.txt y logs)
$XConsola = $false          # corre en una ventana de PowerShell a la vista (herramientas que te piden datos)
$Parar = $false             # una opcion pidio cortar aca (por ejemplo, se abrio el instalador de Windows)

# ------------------------------------------------------------
# Salida y log
# ------------------------------------------------------------
# Los logs se escriben en UTF-8 con BOM (las tildes se leen bien en cualquier lector). Si el archivo ya existe sin BOM (de una version
# vieja, en ANSI) se sigue escribiendo igual que lo que ya tiene, para no mezclar dos codificaciones en el mismo archivo.
$XLogRuta = ''; $XLogEnc = $null
function Log([string]$tag, [string]$msg) {
    if (-not $script:XLog) { return }
    try {
        if ($script:XLogRuta -ne $script:XLog) {
            $script:XLogRuta = $script:XLog; $script:XLogEnc = (New-Object Text.UTF8Encoding $true)
            if ((Test-Path -LiteralPath $script:XLog) -and ((Get-Item -LiteralPath $script:XLog).Length -gt 0)) {
                $b3 = [byte[]](Get-Content -LiteralPath $script:XLog -Encoding Byte -TotalCount 3)
                if (-not (($b3.Count -ge 3) -and ($b3[0] -eq 0xEF) -and ($b3[1] -eq 0xBB) -and ($b3[2] -eq 0xBF))) { $script:XLogEnc = [Text.Encoding]::Default }
            }
        }
        [IO.File]::AppendAllText($script:XLog, ('[{0}] [{1}] {2}' -f (Get-Date -Format 'HH:mm:ss.fff'), $tag, $msg) + "`r`n", $script:XLogEnc)
    } catch { }
}
# Lo que antes se veia en la ventana negra: ahora va al archivo que lee la app (el color no se usa).
# En la ventana de PowerShell a la vista se muestra ahi, con su color.
function Say([string]$msg, $color) {
    if ($script:XSalida) { try { $script:XSalida.WriteLine($msg) } catch { } }
    elseif ($script:XConsola) { if ($color) { Write-Host $msg -ForegroundColor $color } else { Write-Host $msg } }
}
# Abre y cierra el archivo donde escribe Say (para las partes que no usan Correr-Opciones, como la limpieza)
function Abrir-Salida([string]$s) {
    if (-not $s) { return }
    $fs = [IO.FileStream]::new($s, [IO.FileMode]::Create, [IO.FileAccess]::Write, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    $script:XSalida = [IO.StreamWriter]::new($fs, [Text.Encoding]::GetEncoding(850))
    $script:XSalida.AutoFlush = $true
}
function Cerrar-Salida {
    if ($script:XSalida) { try { $script:XSalida.Dispose() } catch { }; $script:XSalida = $null }
}

# Las paginas se abren con explorer.exe para que el navegador arranque como usuario normal y no como administrador.
function Abrir-Pagina([string]$u) {
    try { Start-Process -FilePath (Join-Path $env:WINDIR 'explorer.exe') -ArgumentList ('"' + ($u -replace '"', '%22') + '"') -ErrorAction Stop }
    catch { Start-Process $u }
}

# ------------------------------------------------------------
# Datos de la PC: build, RAM, disco y fecha. La app ya los leyo y los pasa en XUCA_INFO ("build ram hdd fecha").
# ------------------------------------------------------------
function Leer-Info {
    $info = [string]$env:XUCA_INFO
    if (-not $info) {
        $bn = (Get-CimInstance Win32_OperatingSystem).BuildNumber
        if (-not $bn) { $bn = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber }
        $ram = 0
        try { $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB) } catch { }
        $hdd = 0
        try {
            $d = Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1) -ErrorAction Stop | Get-Disk -ErrorAction Stop | Get-PhysicalDisk -ErrorAction Stop
            if ($d.MediaType -eq 'HDD') { $hdd = 1 }
        } catch { }
        $info = ('{0} {1} {2} {3}' -f $bn, $ram, $hdd, (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
    }
    $p = $info -split ' '
    $n = 0
    if ([int]::TryParse([string]$p[0], [ref]$n)) { $script:Build = $n }
    if ([int]::TryParse([string]$p[1], [ref]$n)) { $script:RamGB = $n }
    $script:EsHdd = ([string]$p[2] -eq '1')
    $script:Stamp = $(if ($p.Count -ge 4 -and $p[3]) { [string]$p[3] } else { Get-Date -Format 'yyyy-MM-dd_HH-mm-ss' })
}

function Log-Cabecera {
    $os = Get-CimInstance Win32_OperatingSystem -Property Caption,BuildNumber
    $cpu = (Get-CimInstance Win32_Processor -Property Name | Select-Object -First 1).Name
    $gpu = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join ' / '
    $ubr = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
    Log 'INFO' ('{0} (build {1}.{2})' -f $os.Caption, $os.BuildNumber, $ubr)
    Log 'INFO' ('CPU: ' + ([string]$cpu).Trim())
    Log 'INFO' ('GPU: ' + $gpu)
    Log 'INFO' ('RAM: {0} GB' -f $script:RamGB)
    Log 'INFO' ('Usuario: {0} - Equipo: {1}' -f $env:USERNAME, $env:COMPUTERNAME)
}

# ------------------------------------------------------------
# Contadores de cada opcion (OPT_T = cambios hechos, OPT_F = fallidos, OPT_S = ya estaban, OPT_P = pendientes)
# ------------------------------------------------------------
function Opt-Ini([string]$nombre) {
    $script:OptT = 0; $script:OptF = 0; $script:OptS = 0; $script:OptP = 0
    Log 'INFO' ('== ' + $nombre)
}

function Opt-Fin([string]$msg) {
    if (($script:OptT -gt 0) -and ($script:ReinIds -contains $script:QAct)) { $script:Reinicio = $true }
    # Para el cartel final de la app: solo cuenta como "aplicada" la que cambio algo de verdad (ok), no las que ya estaban o no aplican
    if ($env:XR_XRES -eq '1') {
        $est = $(if ($script:OptF -gt 0) { 'fallo' } elseif (($script:OptP -gt 0) -or ($script:OptT -gt 0)) { 'ok' } elseif ($script:OptS -gt 0) { 'ya' } else { 'noap' })
        Say ('XRES|op|' + $script:QAct + '|' + $est)
    }
    if ($script:OptF -gt 0) {
        Say ('  ERROR: ' + $msg + ' - fallaron ' + $script:OptF + ' de ' + $script:OptT + ' cambios, mira el log.')
        Log 'ATENCION' ($msg + ' - fallaron ' + $script:OptF + ' de ' + $script:OptT + ' cambios')
    } elseif ($script:OptP -gt 0) {
        Say ('  Pendiente: ' + $msg)
        Log 'PENDIENTE' $msg
    } elseif ($script:OptT -gt 0) {
        Say ('  OK: ' + $msg)
        Log 'LISTO' ($msg + ' - ' + $script:OptT + ' cambios hechos y verificados, ' + $script:OptS + ' ya estaban')
    } elseif ($script:OptS -gt 0) {
        Say '  Omitido: ya estaba asi, no se cambio nada.'
        Log 'LISTO' ($msg + ' - ya estaba todo aplicado')
    } else {
        Say '  Omitido: no aplica en esta PC, no se cambio nada.'
        Log 'OMITIDO' ($msg + ' - no aplica en esta PC')
    }
}

# Ya estaba como se pide: no se toco nada
function Ya-Estaba { $script:OptS++ }

# Un cambio hecho: suma y anota si salio bien o mal
function Res([bool]$ok, [string]$msg) {
    $script:OptT++
    if ($ok) { Log 'OK' $msg } else { $script:OptF++; Log 'FALLO' $msg }
}

# Lo que devuelve una accion: 0 = hecho, 1 = fallo, 2 = no aplica en esta PC, 5 = ya estaba, 6 = queda un paso para despues
function Resps([int]$code) {
    if ($code -ge 6) { $script:OptP++; Log 'PENDIENTE' 'queda un paso para despues' }
    elseif ($code -eq 5) { $script:OptS++; Log 'OK' 'ya estaba asi, no se toco nada' }
    elseif ($code -ge 2) { Log 'OMITIDO' 'esta parte no aplica en esta PC' }
    elseif ($code -eq 1) { $script:OptT++; $script:OptF++ }
    else { $script:OptT++ }
}

# Corre una accion y devuelve su codigo. Si se rompe, queda anotado como PS-ERROR (igual que antes).
function Hacer([scriptblock]$accion, [string]$nombre) {
    try {
        $r = @(& $accion)
        if ($r.Count -eq 0) { return 0 }
        return [int]$r[$r.Count - 1]
    } catch {
        Log 'PS-ERROR' ($nombre + ' - ' + ($_.Exception.Message -replace '\s+', ' ') + ' (linea ' + $_.InvocationInfo.ScriptLineNumber + ')')
        return 1
    }
}

# ------------------------------------------------------------
# Registro. Las rutas van como en reg.exe: "HKCU\Control Panel\Mouse". Los tipos son REG_DWORD, REG_SZ o REG_MULTI_SZ
# (este ultimo con los renglones separados por |).
# ------------------------------------------------------------
# $modo: 'leer', 'borrar' (abre con permiso de escritura) o 'crear' (la crea si no existe)
function Reg-Abrir([string]$ruta, [string]$modo) {
    $i = $ruta.IndexOf('\')
    $raiz = $(if ($i -lt 0) { $ruta } else { $ruta.Substring(0, $i) })
    $sub = $(if ($i -lt 0) { '' } else { $ruta.Substring($i + 1) })
    # acepta tambien el estilo de PowerShell (HKCU:\...): el log del pendrive fallaba por eso
    $h = switch ($raiz.ToUpper().TrimEnd(':')) {
        'HKCU' { [Microsoft.Win32.RegistryHive]::CurrentUser }
        'HKLM' { [Microsoft.Win32.RegistryHive]::LocalMachine }
        'HKCR' { [Microsoft.Win32.RegistryHive]::ClassesRoot }
        'HKU'  { [Microsoft.Win32.RegistryHive]::Users }
        default { throw ('raiz de registro desconocida: ' + $raiz) }
    }
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($h, [Microsoft.Win32.RegistryView]::Registry64)
    if (-not $sub) { return $base }
    if ($modo -eq 'crear') { return $base.CreateSubKey($sub) }
    return $base.OpenSubKey($sub, ($modo -eq 'borrar'))
}

function Reg-Existe([string]$ruta) {
    $k = $null
    try { $k = Reg-Abrir $ruta 'leer'; return ($null -ne $k) } catch { return $false } finally { if ($k) { $k.Dispose() } }
}

# @{ Tipo; Valor } o $null si no existe. Los DWORD se leen sin signo (como los muestra reg.exe).
function Reg-Leer([string]$ruta, [string]$nombre) {
    $k = $null
    try {
        $k = Reg-Abrir $ruta 'leer'
        if (-not $k) { return $null }
        if (@($k.GetValueNames()) -notcontains $nombre) { return $null }
        $tipo = $k.GetValueKind($nombre)
        $v = $k.GetValue($nombre, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($tipo -eq [Microsoft.Win32.RegistryValueKind]::DWord) { return @{ Tipo = 'REG_DWORD'; Valor = ([int64]$v -band 4294967295) } }
        if ($tipo -eq [Microsoft.Win32.RegistryValueKind]::MultiString) { return @{ Tipo = 'REG_MULTI_SZ'; Valor = (@($v) -join '|') } }
        return @{ Tipo = 'REG_SZ'; Valor = [string]$v }
    } catch { return $null } finally { if ($k) { $k.Dispose() } }
}

# Si lo que hay es igual a lo que se quiere (con $tipo, tambien tiene que ser del mismo tipo)
function Reg-Igual($leido, [string]$quiero, [string]$tipo) {
    if (-not $leido) { return $false }
    if ($tipo -and ($leido.Tipo -ne $tipo)) { return $false }
    if ($leido.Tipo -eq 'REG_DWORD') {
        $q = 0L
        if (-not [int64]::TryParse($quiero, [ref]$q)) { return $false }
        return ($leido.Valor -eq ($q -band 4294967295))
    }
    return ([string]$leido.Valor -ieq $quiero)
}

# $true si el valor no esta como se pide (sirve para saber si hace falta cambiar algo)
function Reg-Dif([string]$ruta, [string]$nombre, [string]$valor, [string]$tipo) {
    return (-not (Reg-Igual (Reg-Leer $ruta $nombre) $valor $tipo))
}

function Reg-Verif([string]$ruta, [string]$nombre, [string]$valor) {
    $l = Reg-Leer $ruta $nombre
    if (-not $l) { $script:OptF++; Log 'FALLO' ('no se pudo leer ' + $ruta + ' ' + $nombre); return }
    if (Reg-Igual $l $valor '') { Log 'OK' ($ruta + ' ' + $nombre + ' = ' + $valor) }
    else { $script:OptF++; Log 'FALLO' ('valor distinto en ' + $ruta + ' ' + $nombre + ' - esperado ' + $valor + ' y quedo ' + $l.Valor) }
}

# Escribe un valor si no estaba asi y despues lo verifica
function Reg-Set([string]$ruta, [string]$nombre, [string]$tipo, [string]$valor) {
    if (Reg-Igual (Reg-Leer $ruta $nombre) $valor $tipo) { $script:OptS++; Log 'OK' ('ya estaba ' + $ruta + ' ' + $nombre + ' = ' + $valor); return }
    $script:OptT++
    $k = $null
    try {
        $k = Reg-Abrir $ruta 'crear'
        if ($tipo -eq 'REG_DWORD') { $k.SetValue($nombre, [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$valor), 0), [Microsoft.Win32.RegistryValueKind]::DWord) }
        elseif ($tipo -eq 'REG_MULTI_SZ') { $k.SetValue($nombre, [string[]]($valor -split '\|'), [Microsoft.Win32.RegistryValueKind]::MultiString) }
        else { $k.SetValue($nombre, $valor, [Microsoft.Win32.RegistryValueKind]::String) }
    } catch {
        $script:OptF++
        Log 'FALLO' ('no se pudo escribir ' + $ruta + ' ' + $nombre + ' - ' + ($_.Exception.Message -replace '\s+', ' '))
        return
    } finally { if ($k) { $k.Dispose() } }
    Reg-Verif $ruta $nombre $valor
}

# Como Reg-Set, pero si Windows no deja escribir no cuenta como error (queda OMITIDO en el log)
function Reg-Soft([string]$ruta, [string]$nombre, [string]$tipo, [string]$valor) {
    if (Reg-Igual (Reg-Leer $ruta $nombre) $valor $tipo) { $script:OptS++; Log 'OK' ('ya estaba ' + $ruta + ' ' + $nombre + ' = ' + $valor); return }
    $k = $null
    try {
        $k = Reg-Abrir $ruta 'crear'
        if ($tipo -eq 'REG_DWORD') { $k.SetValue($nombre, [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$valor), 0), [Microsoft.Win32.RegistryValueKind]::DWord) }
        else { $k.SetValue($nombre, $valor, [Microsoft.Win32.RegistryValueKind]::String) }
    } catch {
        Log 'OMITIDO' ('Windows no deja escribir ' + $ruta + ' ' + $nombre + ' - ' + ($_.Exception.Message -replace '\s+', ' '))
        return
    } finally { if ($k) { $k.Dispose() } }
    $script:OptT++
    Reg-Verif $ruta $nombre $valor
}

# Solo verifica (el cambio lo hizo otra cosa, por ejemplo SystemParametersInfo)
function Reg-Chk([string]$ruta, [string]$nombre, [string]$valor) {
    $script:OptT++
    Reg-Verif $ruta $nombre $valor
}

function Reg-Del([string]$ruta, [string]$nombre) {
    if (-not (Reg-Leer $ruta $nombre)) { $script:OptS++; Log 'OK' ('ya no existia ' + $ruta + ' ' + $nombre); return }
    $script:OptT++
    $k = $null
    try { $k = Reg-Abrir $ruta 'borrar'; $k.DeleteValue($nombre, $false) } catch { } finally { if ($k) { $k.Dispose() } }
    if (-not (Reg-Leer $ruta $nombre)) { Log 'OK' ('borrado ' + $ruta + ' ' + $nombre) }
    else { $script:OptF++; Log 'FALLO' ('no se pudo borrar ' + $ruta + ' ' + $nombre) }
}

# ------------------------------------------------------------
# Servicios (modo = disabled, auto, delayed-auto o demand; inicio = el valor Start que tiene que quedar)
# ------------------------------------------------------------
# Servicios de la licencia y la activacion de Windows: ninguna opcion los apaga nunca (si se apagan, Windows con cuenta
# local puede pasar a "no activado" o "copia no original"). Proteccion de software, licencia de cliente (licencias digitales
# OEM/HWID), licencias de la Store, inicio de sesion de cuenta Microsoft del equipo y aislamiento de claves.
$SvcLicencia = @('sppsvc', 'ClipSVC', 'LicenseManager', 'wlidsvc', 'KeyIso')

# Corre un comando como SYSTEM (tarea programada de un solo uso). Sirve para los servicios y tareas que Windows protege
# (WaaSMedicSvc, UsoSvc, UpdateOrchestrator): el administrador no puede cambiarlos, SYSTEM si. Devuelve $true si corrio.
function Como-Sistema([string]$cmd) {
    $tn = 'BrioSistema_' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    try {
        $a = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/d /c ' + $cmd)
        Register-ScheduledTask -TaskName $tn -Action $a -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest -Force -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName $tn -ErrorAction Stop
        $sw = [Diagnostics.Stopwatch]::StartNew()
        do { Start-Sleep -Milliseconds 150 } while (((Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue).State -eq 'Running') -and ($sw.ElapsedMilliseconds -lt 15000))
        return $true
    } catch { Log 'INFO' ('no se pudo correr como SYSTEM: ' + $_.Exception.Message); return $false }
    finally { Unregister-ScheduledTask -TaskName $tn -Confirm:$false -ErrorAction SilentlyContinue }
}

# Lo que elegiste en el submenu de la app para una opcion (variable XSEL_<id>, separado con tab).
# Sin submenu (perfiles o la consola) devuelve $null y la opcion usa su lista de siempre.
function Elegidos([string]$id) {
    $v = [Environment]::GetEnvironmentVariable('XSEL_' + $id)
    if ($null -eq $v) { return $null }
    return , @($v -split "`t" | Where-Object { $_ })
}
# Notebook (lo pasa la app): no se apagan wifi, sensores, biometria ni bateria si no los elegiste a mano
function Es-Notebook { return ([string]$env:XNOTEBOOK -eq '1') }

# Versiones viejas apagaban LicenseManager (opcion "str"): con eso Windows con cuenta local podia salir como no activado.
# Si alguno de los servicios de la activacion quedo deshabilitado, vuelve a como viene en Windows.
function Reparar-Licencia {
    $def = @{ sppsvc = 2; ClipSVC = 3; LicenseManager = 3; wlidsvc = 3; KeyIso = 3 }
    foreach ($n in $script:SvcLicencia) {
        $v = Reg-Leer ('HKLM\SYSTEM\CurrentControlSet\Services\' + $n) 'Start'
        if ($v -and ([int64]$v.Valor -eq 4)) {
            Log 'INFO' ($n + ' estaba deshabilitado (afecta la activacion de Windows): vuelve a como viene en Windows')
            try { Set-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $n) -Name 'Start' -Value $def[$n] -ErrorAction Stop } catch { Como-Sistema ('reg add "HKLM\SYSTEM\CurrentControlSet\Services\' + $n + '" /v Start /t REG_DWORD /d ' + $def[$n] + ' /f') | Out-Null }
        }
    }
}

function Svc([string]$nombre, [string]$modo, [string]$inicio) {
    $rk = 'HKLM\SYSTEM\CurrentControlSet\Services\' + $nombre
    if (($modo -eq 'disabled') -and ($script:SvcLicencia -contains $nombre)) { Log 'OMITIDO' ($nombre + ' es parte de la activacion de Windows: no se apaga'); return }
    if (-not (Reg-Existe $rk)) { Log 'OMITIDO' ('el servicio ' + $nombre + ' no existe en esta PC'); return }
    if (Reg-Igual (Reg-Leer $rk 'Start') $inicio 'REG_DWORD') { $script:OptS++; Log 'OK' ('el servicio ' + $nombre + ' ya estaba con inicio ' + $modo); return }
    # Disabled y manual se cambian sin abrir otro programa; auto y delayed-auto van por sc.exe (deja bien el "retrasado")
    $hecho = $false
    if (($modo -eq 'disabled') -or ($modo -eq 'demand')) {
        try { Set-Service -Name $nombre -StartupType $(if ($modo -eq 'disabled') { 'Disabled' } else { 'Manual' }) -ErrorAction Stop; $hecho = $true } catch { }
    }
    if (-not $hecho) { & sc.exe config $nombre start= $modo 2>&1 | Out-Null }
    # Algunos servicios rechazan el cambio por el administrador de servicios pero aceptan el registro directo
    if (-not (Reg-Igual (Reg-Leer $rk 'Start') $inicio 'REG_DWORD')) { try { Set-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $nombre) -Name 'Start' -Value ([int]$inicio) -ErrorAction Stop } catch { } }
    # Servicio protegido (WaaSMedicSvc, UsoSvc...): el administrador no tiene permiso, SYSTEM si
    if (-not (Reg-Igual (Reg-Leer $rk 'Start') $inicio 'REG_DWORD')) {
        Log 'INFO' ($nombre + ' esta protegido: se cambia como SYSTEM')
        Como-Sistema ('reg add "HKLM\SYSTEM\CurrentControlSet\Services\' + $nombre + '" /v Start /t REG_DWORD /d ' + [int]$inicio + ' /f') | Out-Null
    }
    $script:OptT++
    Reg-Verif $rk 'Start' $inicio
}

function Svc-Parar([string]$nombre) {
    $s = Get-Service -Name $nombre -ErrorAction SilentlyContinue
    if ((-not $s) -or ($s.Status -ne 'Running')) { return }
    & sc.exe stop $nombre 2>&1 | Out-Null
    # El inicio ya quedo cambiado: si no se deja parar ahora (dependencias, protegido), se nota al reiniciar
    if ($LASTEXITCODE -eq 0) { Log 'INFO' ('servicio ' + $nombre + ' detenido') } else { Log 'INFO' ('servicio ' + $nombre + ' no se pudo detener ahora (sc.exe ' + $LASTEXITCODE + '): queda asi al reiniciar') }
}

function Svc-Arrancar([string]$nombre) {
    $s = Get-Service -Name $nombre -ErrorAction SilentlyContinue
    if ((-not $s) -or ($s.Status -ne 'Stopped')) { return }
    & sc.exe start $nombre 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Log 'INFO' ('servicio ' + $nombre + ' iniciado') } else { Log 'INFO' ('servicio ' + $nombre + ' no se pudo iniciar ahora (sc.exe ' + $LASTEXITCODE + '): arranca al reiniciar') }
}

# Tareas programadas ($modo = disable o enable)
# Se usa el Programador de tareas directo (mucho mas rapido que abrir schtasks.exe dos veces por tarea).
# Si no se puede, sigue con schtasks.exe como antes.
function Sched {
    if (-not $script:XSched) { $s = New-Object -ComObject Schedule.Service; $s.Connect(); $script:XSched = $s }
    return $script:XSched
}
function Sched-Tarea([string]$tn) {
    $i = $tn.LastIndexOf('\')
    $dir = $(if ($i -gt 0) { $tn.Substring(0, $i) } else { '\' })
    return (Sched).GetFolder($dir).GetTask($tn.Substring($i + 1))
}
function Tarea([string]$tn, [string]$modo) {
    # Las tareas de la licencia de Windows no se apagan nunca (sin ellas la activacion no se renueva)
    if (($modo -eq 'disable') -and ($tn -match '(?i)\\(SoftwareProtectionPlatform|Clip|Subscription)\\')) { Log 'OMITIDO' ('tarea de la activacion de Windows, no se apaga: ' + $tn); return }
    $t = $null
    try { $t = Sched-Tarea $tn } catch { }
    if ($t) {
        $quiero = ($modo -eq 'enable')
        if ([bool]$t.Enabled -eq $quiero) { $script:OptS++; Log 'OK' ('la tarea ya estaba en ' + $modo + ': ' + $tn); return }
        try { $t.Enabled = $quiero; Res ([bool](Sched-Tarea $tn).Enabled -eq $quiero) ('tarea ' + $tn + ' - ' + $modo); return } catch { }
    }
    $xml = (& schtasks.exe /query /tn $tn /xml 2>$null | Out-String)
    if ($LASTEXITCODE -ne 0) { Log 'OMITIDO' ('la tarea no existe ' + $tn); return }
    $apagada = ($xml -match '(?i)<Enabled>false</Enabled>')
    if ((($modo -eq 'disable') -and $apagada) -or (($modo -eq 'enable') -and (-not $apagada))) { $script:OptS++; Log 'OK' ('la tarea ya estaba en ' + $modo + ': ' + $tn); return }
    & schtasks.exe /change /tn $tn ('/' + $modo) 2>&1 | Out-Null
    Res ($LASTEXITCODE -eq 0) ('tarea ' + $tn + ' - ' + $modo)
}

# Esperas cortas: en vez de dormir un tiempo fijo, se mira cada 100 ms y se sigue apenas esta listo
function Esperar-Cierre([string[]]$nombres, [int]$ms = 3000) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ((Get-Process -Name $nombres -ErrorAction SilentlyContinue) -and ($sw.ElapsedMilliseconds -lt $ms)) { Start-Sleep -Milliseconds 100 }
}
function Tarea-Corre([string]$tn) {
    try { return ((Sched-Tarea $tn).State -eq 4) }
    catch { $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue; return [bool]($t -and ($t.State -eq 'Running')) }
}
# Espera a que la tarea quede corriendo y 300 ms despues se fija que siga (que el programa no se haya cerrado al arrancar)
function Esperar-Tarea([string]$tn, [int]$ms = 3000) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Tarea-Corre $tn)) { if ($sw.ElapsedMilliseconds -ge $ms) { return $false }; Start-Sleep -Milliseconds 100 }
    Start-Sleep -Milliseconds 300
    return (Tarea-Corre $tn)
}

# ------------------------------------------------------------
# Arranque (bcdedit) y plan de energia
# ------------------------------------------------------------
# Lo que dice bcdedit se lee una vez y se guarda; se vuelve a leer despues de cada cambio
$XBcd = $null
function Bcd-Tiene([string]$nombre, [string]$valor) {
    if ($null -eq $script:XBcd) { $script:XBcd = (& bcdedit.exe /enum '{current}' 2>$null | Out-String) }
    $o = $script:XBcd
    if ($valor) { return ($o -match ('(?im)^' + [regex]::Escape($nombre) + ' +' + [regex]::Escape($valor) + ' *\r?$')) }
    return ($o -match ('(?im)^' + [regex]::Escape($nombre) + ' '))
}

function Bcd([string]$nombre, [string]$valor) {
    if (Bcd-Tiene $nombre $valor) { $script:OptS++; Log 'OK' ('bcdedit ' + $nombre + ' ya estaba en ' + $valor); return }
    & bcdedit.exe /set $nombre $valor 2>&1 | Out-Null
    $script:XBcd = $null
    Res (Bcd-Tiene $nombre $valor) ('bcdedit ' + $nombre + ' ' + $valor)
}

function Bcd-Del([string]$nombre) {
    if (-not (Bcd-Tiene $nombre '')) { $script:OptS++; Log 'OK' ('bcdedit ' + $nombre + ' ya no estaba puesto'); return }
    & bcdedit.exe /deletevalue $nombre 2>&1 | Out-Null
    $script:XBcd = $null
    $script:OptT++
    if (Bcd-Tiene $nombre '') { $script:OptF++; Log 'FALLO' ('bcdedit ' + $nombre + ' sigue puesto') }
    else { Log 'OK' ('bcdedit ' + $nombre + ' quitado') }
}

function Plan-Es([string]$guid) { return ((& powercfg.exe /getactivescheme 2>$null | Out-String) -match [regex]::Escape($guid)) }

# ------------------------------------------------------------
# Protocolos (ms-gamebar y similares): se mandan a systray.exe para que no abran nada
# ------------------------------------------------------------
function Protocolo([string]$p) {
    $l = Reg-Leer ('HKCR\' + $p + '\shell\open\command') ''
    if ($l -and ([string]$l.Valor -like '*systray.exe*')) { $script:OptS++; Log 'OK' ('el protocolo ' + $p + ' ya estaba redirigido'); return }
    $pasos = @(
        @(('HKCR\' + $p), '', ('URL:' + $p), ('protocolo ' + $p + ' - valor')),
        @(('HKCR\' + $p), 'URL Protocol', '', ('protocolo ' + $p + ' - URL Protocol')),
        @(('HKCR\' + $p + '\shell\open\command'), '', (Join-Path $env:SystemRoot 'System32\systray.exe'), ('protocolo ' + $p + ' - comando'))
    )
    foreach ($x in $pasos) {
        $k = $null; $ok = $true
        try { $k = Reg-Abrir $x[0] 'crear'; $k.SetValue($x[1], $x[2], [Microsoft.Win32.RegistryValueKind]::String) } catch { $ok = $false } finally { if ($k) { $k.Dispose() } }
        Res $ok $x[3]
    }
}

# Avisa al Explorador que cambiaron sus opciones (extensiones, ocultos) para que las ventanas abiertas se actualicen sin reiniciarlo
function Refrescar-Explorer {
    try {
        if (-not ('XucaShell' -as [type])) {
            Add-Type -Namespace '' -Name 'XucaShell' -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)] public static extern System.IntPtr SendMessageTimeout(System.IntPtr h, uint m, System.UIntPtr w, string l, uint f, uint t, out System.UIntPtr r);' -ErrorAction Stop
        }
        $r = [UIntPtr]::Zero
        [void][XucaShell]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'ShellState', 2, 2000, [ref]$r)
    } catch { Log 'INFO' ('no se pudo avisar al Explorador: ' + $_.Exception.Message) }
}

# ------------------------------------------------------------
# Devolver las carpetas de Windows (Escritorio, Documentos, Imagenes...) de OneDrive a su lugar normal, moviendo TODO su contenido.
# Es lo mismo que "Propiedades > Ubicacion > Restaurar valores predeterminados > Mover". Mueve datos del usuario, asi que:
#   - todo se revisa ANTES y si falla algo no se mueve nada
#   - nunca se borra nada del destino (sin /PURGE ni /MIR) ni se pisa un archivo: si el nombre ya existe, el de OneDrive se renombra "(desde OneDrive)"
#   - el registro de una carpeta solo cambia cuando todo su contenido llego y se verifico por conteo y tamano
#   - jamas se toca la carpeta raiz de OneDrive ni nada fuera de estas carpetas conocidas
# Las rutas y las claves de registro se reciben como parametros para poder probarlo en carpetas y claves falsas.
# ------------------------------------------------------------
$OdConocidas = @(@('Desktop', 'Desktop'), @('Personal', 'Documents'), @('My Pictures', 'Pictures'), @('My Music', 'Music'), @('My Video', 'Videos'), @('{374DE290-123F-4565-9164-39C4925E467B}', 'Downloads'))
$OdSufijo = ' (desde OneDrive)'

# Carpetas conocidas que hoy estan dentro de OneDrive: @{ Clave; Normal; Origen; Destino }
function Od-Carpetas([string]$usfKey, [string]$perfil, [string]$raizOd) {
    $r = @()
    $usf = Get-ItemProperty -Path $usfKey -ErrorAction SilentlyContinue
    if (-not $usf) { return $r }
    foreach ($k in $OdConocidas) {
        $v = [string]$usf.($k[0]); if (-not $v) { continue }
        $o = [Environment]::ExpandEnvironmentVariables($v).TrimEnd('\')
        $dentro = ($o -match '\\OneDrive[^\\]*(\\|$)') -or ($raizOd -and $o.StartsWith($raizOd.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase))
        if (-not $dentro) { continue }
        $r += @{ Clave = $k[0]; Normal = $k[1]; Origen = $o; Destino = (Join-Path $perfil $k[1]) }
    }
    return $r
}

# Tipo de reparse point de un archivo o carpeta (lo lee de WIN32_FIND_DATA.dwReserved0). 0 = no tiene, -1 = no se pudo leer
function Od-Tag([string]$ruta) {
    try {
        if (-not ('OdTag' -as [type])) {
            Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class OdTag { [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct FD { public uint attr; public System.Runtime.InteropServices.ComTypes.FILETIME c, a, w; public uint hi, lo, res0, res1; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string name; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string alt; } [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr FindFirstFileW(string p, out FD d); [DllImport("kernel32.dll")] static extern bool FindClose(IntPtr h); public static long Tag(string path) { FD d; IntPtr h = FindFirstFileW(path, out d); if (h == (IntPtr)(-1)) return -1; FindClose(h); return ((d.attr & 0x400) != 0) ? (long)d.res0 : 0; } }' -Language CSharp -ErrorAction Stop
        }
        return [long][OdTag]::Tag($ruta)
    } catch { return -1 }
}
# Que es de verdad un archivo o carpeta con el atributo ReparsePoint (0x400), segun su ETIQUETA y no solo el atributo:
#   'enlace' = junction (0xA0000003) o enlace simbolico (0xA000000C): bloquean, se siguen hacia afuera
#   'nube'   = marcador de OneDrive / Files On-Demand (0x9000X01A, por ejemplo 0x9000701A): es un archivo o carpeta normal de OneDrive, se recorre
#   'otro'   = cualquier otra etiqueta (compresion de Windows, etc.): se trata como normal
#   'normal' = sin atributo ReparsePoint
function Od-Clase([int]$at, [long]$tag) {
    if (-not ($at -band 0x400)) { return 'normal' }
    if (($tag -eq 0xA0000003L) -or ($tag -eq 0xA000000CL)) { return 'enlace' }
    if (($tag -band 0xFFFF0FFFL) -eq 0x9000001AL) { return 'nube' }
    if ($tag -gt 0) { return 'otro' }
    if ($at -band 0x441000) { return 'nube' }    # etiqueta ilegible pero con marcas de nube
    return 'enlace'                                # sin etiqueta y sin marcas de nube: por prudencia se trata como enlace
}

# Recorre una carpeta sin seguir enlaces reales. Devuelve archivos, bytes, y lo que impide moverla (nube, enlaces, en uso, rutas largas)
function Od-Revisar($c, [string]$raizOd) {
    $res = @{ Archivos = 0; Bytes = [long]0; Motivos = @(); Causas = @(); Nube = @(); Enlaces = @(); EnUso = @() }
    $src = [string]$c.Origen
    if (-not (Test-Path -LiteralPath $src -PathType Container)) { $res.Motivos += ('la carpeta de origen no existe: ' + $src); $res.Causas += 'otro'; return $res }
    $dst = [string]$c.Destino
    if ($raizOd -and ($src.TrimEnd('\') -eq $raizOd.TrimEnd('\'))) { $res.Motivos += ('la carpeta es la raiz de OneDrive, no se mueve: ' + $src); $res.Causas += 'otro'; return $res }
    if (($dst.TrimEnd('\') -eq $src.TrimEnd('\')) -or ($dst -like ($src.TrimEnd('\') + '\*')) -or ($src -like ($dst.TrimEnd('\') + '\*'))) { $res.Motivos += ('origen y destino estan uno dentro del otro: ' + $src + ' -> ' + $dst); $res.Causas += 'otro'; return $res }
    if ((Test-Path -LiteralPath $dst) -and (-not (Test-Path -LiteralPath $dst -PathType Container))) { $res.Motivos += ('el destino existe y no es una carpeta: ' + $dst); $res.Causas += 'otro'; return $res }
    $pila = New-Object System.Collections.Generic.Stack[string]; $pila.Push($src); $largas = 0
    while ($pila.Count -gt 0) {
        $d = $pila.Pop()
        try { $hijos = @((New-Object IO.DirectoryInfo $d).GetFileSystemInfos()) } catch { $res.EnUso += ($d + ' (no se pudo leer)'); continue }
        foreach ($h in $hijos) {
            $at = [int]$h.Attributes
            $tag = [long]0; if ($at -band 0x400) { $tag = Od-Tag $h.FullName }
            $cl = Od-Clase $at $tag
            if ($cl -eq 'enlace') { $res.Enlaces += $h.FullName; continue }
            if ($at -band 0x10) { $pila.Push($h.FullName); continue }
            if ($h.Name -ieq 'desktop.ini') { continue }
            # Solo en la nube (RECALL_ON_DATA_ACCESS 0x400000, RECALL_ON_OPEN 0x40000 u OFFLINE 0x1000): moverlo no lo descargaria y se perderia el acceso
            if (($at -band 0x441000) -ne 0) { $res.Nube += $h.FullName; continue }
            $res.Archivos++; $res.Bytes += [long]$h.Length
            if (($h.FullName.Length - $src.Length + $dst.Length) -gt 240) { $largas++ }
            try { $fs = [IO.File]::Open($h.FullName, 'Open', 'Read', 'None'); $fs.Close() } catch { $res.EnUso += $h.FullName }
        }
    }
    if ($res.Nube.Count -gt 0) { $res.Motivos += ('hay ' + $res.Nube.Count + ' archivos que solo estan en la nube dentro de ' + $src + ': ' + (($res.Nube | Select-Object -First 3) -join ', ') + $(if ($res.Nube.Count -gt 3) { ' ...' } else { '' }) + ' (en OneDrive: clic derecho > Mantener siempre en este dispositivo, y espera a que termine de sincronizar)'); $res.Causas += 'nube' }
    if ($res.Enlaces.Count -gt 0) { $res.Motivos += ('hay enlaces reales (junction o acceso simbolico) dentro de ' + $src + ': ' + (($res.Enlaces | Select-Object -First 3) -join ', ')); $res.Causas += 'enlaces' }
    if ($largas -gt 0) { $res.Motivos += ('hay ' + $largas + ' archivos con ruta demasiado larga en ' + $src); $res.Causas += 'larga' }
    if ($res.EnUso.Count -gt 0) { $res.Motivos += ('hay archivos abiertos por algun programa o sin permiso en ' + $src + ': ' + (($res.EnUso | Select-Object -First 3) -join ', ')); $res.Causas += 'uso' }
    return $res
}

function Od-Libre([string]$raiz) { return (New-Object IO.DriveInfo $raiz).AvailableFreeSpace }
# Cuenta archivos y bytes de un arbol (sin desktop.ini)
function Od-Contar([string]$ruta) {
    $n = 0; $b = [long]0
    if (Test-Path -LiteralPath $ruta -PathType Container) {
        foreach ($f in @(Get-ChildItem -LiteralPath $ruta -Recurse -File -Force -ErrorAction SilentlyContinue)) { if ($f.Name -ine 'desktop.ini') { $n++; $b += [long]$f.Length } }
    }
    return @{ Archivos = $n; Bytes = $b }
}

# Si el destino ya tiene algo con el mismo nombre, lo de OneDrive se renombra (en OneDrive) para que robocopy nunca pise nada
function Od-Renombrar-Choques([string]$src, [string]$dst) {
    $n = 0
    foreach ($h in @(Get-ChildItem -LiteralPath $src -Force -ErrorAction SilentlyContinue)) {
        if ($h.Name -ieq 'desktop.ini') { continue }
        $dp = Join-Path $dst $h.Name; $actual = $h.FullName
        if (Test-Path -LiteralPath $dp) {
            $dirS = $h.PSIsContainer; $dirD = (Test-Path -LiteralPath $dp -PathType Container)
            # Carpeta con carpeta se junta sin problema; todo lo demas es un choque
            if (-not ($dirS -and $dirD)) {
                $base = $(if ($dirS) { $h.Name } else { [IO.Path]::GetFileNameWithoutExtension($h.Name) }); $ext = $(if ($dirS) { '' } else { $h.Extension })
                $nom = $base + $OdSufijo + $ext; $i = 2
                while ((Test-Path -LiteralPath (Join-Path $dst $nom)) -or (Test-Path -LiteralPath (Join-Path $src $nom))) { $nom = $base + $OdSufijo + ' ' + $i + $ext; $i++ }
                Rename-Item -LiteralPath $h.FullName -NewName $nom -ErrorAction Stop
                $n++; $actual = Join-Path $src $nom; $dp = Join-Path $dst $nom
            }
        }
        if ($h.PSIsContainer -and (Test-Path -LiteralPath $dp -PathType Container)) { $n += (Od-Renombrar-Choques $actual $dp) }
    }
    return $n
}

# Apunta la carpeta a su lugar normal en el registro (como lo deja Windows): User Shell Folders con variable, Shell Folders con la ruta completa
function Od-Registro($c, [string]$usfKey, [string]$sfKey) {
    Set-ItemProperty -Path $usfKey -Name $c.Clave -Value ('%USERPROFILE%\' + $c.Normal) -Type ExpandString -ErrorAction Stop
    if ($sfKey) { Set-ItemProperty -Path $sfKey -Name $c.Clave -Value $c.Destino -Type String -ErrorAction Stop }
}

# Mueve por renombrado cada archivo y carpeta (mismo volumen: es un cambio de metadatos, no copia ni descarga nada, y no hace falta espacio). Si la carpeta ya existe en el destino, se juntan. Devuelve los errores.
function Od-Mover-Directo([string]$src, [string]$dst) {
    $malos = @()
    foreach ($h in @(Get-ChildItem -LiteralPath $src -Force -ErrorAction SilentlyContinue)) {
        if ($h.Name -ieq 'desktop.ini') { continue }
        $dp = Join-Path $dst $h.Name
        try {
            if ($h.PSIsContainer) {
                if (Test-Path -LiteralPath $dp -PathType Container) { $malos += @(Od-Mover-Directo $h.FullName $dp) } else { [IO.Directory]::Move($h.FullName, $dp) }
            } else { [IO.File]::Move($h.FullName, $dp) }
        } catch { $malos += ($h.FullName + ': ' + $_.Exception.Message) }
    }
    return $malos
}

# Mueve una carpeta (ya revisada). Mismo volumen: renombrado; otro volumen: robocopy /MOVE. Devuelve @{ Ok; Archivos; Bytes; Motivo }
function Od-Mover-Una($c, [string]$usfKey, [string]$sfKey) {
    $src = [string]$c.Origen; $dst = [string]$c.Destino
    $antes = Od-Contar $src; $ant = Od-Contar $dst
    try {
        if (-not (Test-Path -LiteralPath $dst)) { New-Item -ItemType Directory -Path $dst -ErrorAction Stop | Out-Null }
        [void](Od-Renombrar-Choques $src $dst)
    } catch { return @{ Ok = $false; Archivos = 0; Bytes = [long]0; Motivo = ('no se pudo preparar el destino: ' + $_.Exception.Message) } }
    $mismoVol = ([IO.Path]::GetPathRoot($src) -ieq [IO.Path]::GetPathRoot($dst)) -and (-not $script:OdForzarRobocopy)
    $rc = 0; $errs = @()
    if ($mismoVol) { $errs = @(Od-Mover-Directo $src $dst) }
    else {
        # /XJ: no sigue enlaces. Sin /PURGE ni /MIR: nunca borra nada del destino. desktop.ini se deja (cada carpeta ya tiene el suyo).
        $sal = & robocopy.exe $src $dst /E /MOVE /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /XF desktop.ini /NFL /NDL /NP /NJH /NJS 2>&1
        $rc = $LASTEXITCODE
    }
    $desp = Od-Contar $dst; $resto = Od-Contar $src
    $okConteo = ((($desp.Archivos - $ant.Archivos) -eq $antes.Archivos) -and (($desp.Bytes - $ant.Bytes) -eq $antes.Bytes) -and ($resto.Archivos -eq 0))
    if (($rc -ge 8) -or ($errs.Count -gt 0) -or (-not $okConteo)) {
        return @{ Ok = $false; Archivos = ($desp.Archivos - $ant.Archivos); Bytes = ($desp.Bytes - $ant.Bytes); Motivo = ('no se pudo mover todo (' + $(if ($mismoVol) { 'renombrado' } else { 'robocopy codigo ' + $rc }) + '): quedaron ' + $resto.Archivos + ' archivos en ' + $src + ' y la carpeta sigue apuntando a OneDrive; los archivos ya movidos estan en ' + $dst + $(if ($errs.Count -gt 0) { '. Primer error: ' + $errs[0] } else { '' })) }
    }
    try { Od-Registro $c $usfKey $sfKey } catch { return @{ Ok = $false; Archivos = $antes.Archivos; Bytes = $antes.Bytes; Motivo = ('se movio todo a ' + $dst + ' pero no se pudo actualizar el registro: ' + $_.Exception.Message) } }
    return @{ Ok = $true; Archivos = $antes.Archivos; Bytes = $antes.Bytes; Motivo = '' }
}

# Proceso completo: revisa todas las carpetas; si alguna falla, no mueve nada; si no, las mueve una por una.
# Devuelve @{ Movidas = lista de @{Carpeta;Archivos;Bytes}; Fallos = textos; Revisado = $true/$false }
function Od-Proceso([string]$usfKey, [string]$sfKey, [string]$perfil, [string]$raizOd) {
    $out = @{ Movidas = @(); Fallos = @(); Causas = @(); Revisado = $false; Total = 0; Bytes = [long]0 }
    $cs = @(Od-Carpetas $usfKey $perfil $raizOd)
    if ($cs.Count -eq 0) { return $out }
    $rev = @{}; $porDisco = @{}
    foreach ($c in $cs) {
        $r = Od-Revisar $c $raizOd; $rev[$c.Clave] = $r
        $out.Fallos += $r.Motivos; $out.Causas += $r.Causas
        $dr = [IO.Path]::GetPathRoot([string]$c.Destino).ToUpper()
        $porDisco[$dr] = [long]$porDisco[$dr] + [long]$r.Bytes
        $out.Total += $r.Archivos; $out.Bytes += [long]$r.Bytes
    }
    # Espacio libre en el disco de destino: lo que se mueve (robocopy copia y despues borra) mas 10 % y 256 MB de margen
    foreach ($dr in @($porDisco.Keys)) {
        try {
            $libre = Od-Libre $dr
            $necesita = [long]($porDisco[$dr] * 1.1) + 256MB
            if ($libre -lt $necesita) { $out.Causas += 'espacio'; $out.Fallos += ('no hay espacio en ' + $dr + ': hacen falta ' + [math]::Round($necesita / 1GB, 2) + ' GB y hay ' + [math]::Round($libre / 1GB, 2) + ' GB libres') }
        } catch { $out.Fallos += ('no se pudo medir el espacio libre de ' + $dr) }
    }
    $out.Revisado = $true
    if ($out.Fallos.Count -gt 0) { $out.Causas = @($out.Causas | Select-Object -Unique); return $out }
    foreach ($c in $cs) {
        $m = Od-Mover-Una $c $usfKey $sfKey
        if ($m.Ok) { $out.Movidas += @{ Carpeta = $c.Normal; Origen = $c.Origen; Destino = $c.Destino; Archivos = $m.Archivos; Bytes = $m.Bytes } }
        else { $out.Causas += 'otro'; $out.Fallos += ($c.Normal + ': ' + $m.Motivo) }
    }
    $out.Causas = @($out.Causas | Select-Object -Unique)
    return $out
}

# Avisa al Explorador para que el Escritorio y las carpetas ya aparezcan en su lugar nuevo (reinicia explorer.exe: Windows lo vuelve a abrir solo)
function Od-Avisar-Shell {
    try {
        if (-not ('XucaShellN' -as [type])) { Add-Type -Namespace '' -Name 'XucaShellN' -MemberDefinition '[System.Runtime.InteropServices.DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);' }
        [XucaShellN]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
        Refrescar-Explorer
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 1500
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    } catch { Log 'INFO' ('no se pudo avisar al Explorador: ' + $_.Exception.Message) }
}

function Proto-Del([string]$p) {
    if (-not (Reg-Existe ('HKCR\' + $p))) { $script:OptS++; Log 'OK' ('el protocolo ' + $p + ' ya no existia'); return }
    $script:OptT++
    $k = $null
    try { $k = Reg-Abrir 'HKCR' 'leer'; $k.DeleteSubKeyTree($p, $false) } catch { } finally { if ($k) { $k.Dispose() } }
    if (Reg-Existe ('HKCR\' + $p)) { $script:OptF++; Log 'FALLO' ('no se pudo borrar el protocolo ' + $p) }
    else { Log 'OK' ('protocolo ' + $p + ' borrado') }
}

# ------------------------------------------------------------
# Cosas que usan varias partes
# ------------------------------------------------------------
# La carpeta de los programas que corren como SYSTEM: duenio Administradores, solo admins y SYSTEM pueden escribir.
# Si la carpeta la habia creado un usuario comun, asi ya no puede cambiar los .exe ni los permisos.
function Proteger-Carpeta([string]$d) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
    & icacls.exe $d /setowner '*S-1-5-32-544' /T /C /Q 2>&1 | Out-Null
    & icacls.exe $d /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' /C /Q 2>&1 | Out-Null
    if (@(Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue).Count -gt 0) { & icacls.exe (Join-Path $d '*') /reset /T /C /Q 2>&1 | Out-Null }
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

# ------------------------------------------------------------
# Riot Vanguard: si una opcion de seguridad cambio algo de verdad, se desinstala del todo
# (con la seguridad apagada Vanguard no deja jugar; al abrir el cliente de Riot se vuelve a instalar).
# ------------------------------------------------------------
function Vanguard-Instalado {
    $vgDir = Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Riot Vanguard'
    return [bool]((Get-Service -Name 'vgc', 'vgk' -ErrorAction SilentlyContinue) -or (Test-Path $vgDir))
}

# $cambios = cambios de la parte de seguridad de la opcion (si no se pasa, cuentan todos los de la opcion)
function Vanguard-Check([int]$cambios = -1) {
    if ($cambios -lt 0) { $cambios = $script:OptT }
    # Si ya se borro (o no estaba instalado) en una opcion anterior, no se vuelve a revisar ni a mostrar nada.
    if ($script:VgHecho) { return }
    # Si la seguridad ya estaba apagada (no cambio nada, no aplica o se omitio), Vanguard no se toca.
    if ($cambios -eq 0) { return }
    $script:VgAviso = $true
    if (-not (Vanguard-Instalado)) { $script:VgHecho = $true; return }
    Say ''
    Say '  Borrando Riot Vanguard y sus restos, un momento...'
    Opt-Ini 'Riot Vanguard'
    Resps (Hacer { Vanguard-Borrar } 'VANGUARD_OFF')
    Opt-Fin 'Riot Vanguard borrado'
    $script:VgHecho = $true
}

function Vanguard-Borrar {
    $code = 0
    . {
        $pf = [Environment]::GetFolderPath('ProgramFiles')
        $vgDir = Join-Path $pf 'Riot Vanguard'
        $vgc = Join-Path $vgDir 'vgc.exe'
        # 1) Cerrar Riot: el cliente, Valorant, League y la bandeja de Vanguard. Asi tenes que volver a abrir
        #    el cliente de Riot, que te pide instalar Vanguard de nuevo y no queda a medias.
        $riot = @('VALORANT-Win64-Shipping', 'VALORANT', 'RiotClientServices', 'RiotClientUx', 'RiotClientUxRender', 'RiotClientCrashHandler', 'Riot Client', 'LeagueClient', 'LeagueClientUx', 'LeagueClientUxRender', 'League of Legends', 'vgtray', 'vgc')
        $abiertos = @(Get-Process -Name $riot -ErrorAction SilentlyContinue)
        if ($abiertos.Count -gt 0) {
            $abiertos | Stop-Process -Force -ErrorAction SilentlyContinue
            Log 'OK' ('Riot cerrado: ' + ((@($abiertos | ForEach-Object { $_.ProcessName } | Select-Object -Unique)) -join ', '))
            Esperar-Cierre $riot
        }
        # 2) Desinstalarlo como desde el Panel de control (su propio desinstalador, sin preguntas si se puede)
        $claves = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
        $entradas = @(foreach ($c in $claves) { Get-ChildItem -LiteralPath $c -ErrorAction SilentlyContinue | Where-Object { $dn = ''; try { $dn = [string]$_.GetValue('DisplayName') } catch { }; $dn -like 'Riot Vanguard*' } })
        foreach ($e in $entradas) {
            $cmd = ''
            try { $cmd = [string]$e.GetValue('QuietUninstallString') } catch { }
            if (-not $cmd) { try { $cmd = [string]$e.GetValue('UninstallString') } catch { } }
            if (-not $cmd) { continue }
            $exeU = ''; $argU = ''
            if ($cmd -match '^\s*"([^"]+)"\s*(.*)$') { $exeU = $Matches[1]; $argU = $Matches[2] }
            elseif ($cmd -match '^\s*(.+?\.exe)\s*(.*)$') { $exeU = $Matches[1]; $argU = $Matches[2] }
            if (-not (Test-Path -LiteralPath $exeU)) { continue }
            try {
                $pu = $(if ($argU) { Start-Process -FilePath $exeU -ArgumentList $argU -PassThru -ErrorAction Stop } else { Start-Process -FilePath $exeU -PassThru -ErrorAction Stop })
                # Como mucho 2 minutos: si el desinstalador pide confirmar, aparece su ventana
                if (-not $pu.WaitForExit(120000)) { Log 'INFO' 'el desinstalador de Vanguard sigue abierto: se continua con la limpieza' }
                else { Log 'OK' ('desinstalador de Riot Vanguard ejecutado (' + $exeU + ')') }
            } catch { Log 'INFO' ('desinstalador de Vanguard: ' + $_.Exception.Message) }
        }
        # 3) Si quedo algo, su desinstalacion directa y despues borrar servicios, carpeta y la entrada del Panel de control
        if (Test-Path $vgc) {
            try { $pv = Start-Process -FilePath $vgc -ArgumentList '/uninstall' -WindowStyle Hidden -PassThru -ErrorAction Stop; $pv.WaitForExit(60000) | Out-Null } catch { }
            Esperar-Cierre 'vgc', 'vgtray' 2000
        }
        # Servicios vgc y vgk: se dejan en Deshabilitado (Start=4) para que no arranquen, se paran y se borran; cada paso se comprueba
        $pasos = @()
        foreach ($sv in 'vgc', 'vgk') {
            $s = Get-Service -Name $sv -ErrorAction SilentlyContinue
            $kv = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $sv
            if ((-not $s) -and (-not (Test-Path -LiteralPath $kv))) { continue }
            if (Test-Path -LiteralPath $kv) { try { Set-ItemProperty -LiteralPath $kv -Name 'Start' -Value 4 -Type DWord -ErrorAction Stop } catch { } }
            & sc.exe stop $sv 2>&1 | Out-Null
            & sc.exe delete $sv 2>&1 | Out-Null
            Start-Sleep -Milliseconds 500
            if (Get-Service -Name $sv -ErrorAction SilentlyContinue) { Log 'INFO' ('servicio ' + $sv + ' sigue marcado para borrar: se termina al reiniciar'); $pasos += ('servicio ' + $sv + ': deshabilitado, se borra al reiniciar') }
            else { Log 'OK' ('servicio ' + $sv + ' parado y borrado'); $pasos += ('servicio ' + $sv + ': borrado') }
        }
        # Driver vgk registrado en el almacen de drivers de Windows
        $pn = (& pnputil.exe /enum-drivers 2>&1 | Out-String)
        foreach ($blq in @($pn -split '(?:\r?\n){2,}')) {
            if ($blq -notmatch '(?im)^\s*[^:\r\n]+:\s*(oem\d+\.inf)\s*$') { continue }
            $oem = $Matches[1]
            if ($blq -match '(?i)\bvgk(\.sys|\.inf)?\b|riot vanguard') {
                & pnputil.exe /delete-driver $oem /uninstall /force 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { Log 'OK' ('driver de Vanguard quitado del almacen: ' + $oem); $pasos += 'driver vgk: quitado del almacen' }
                else { Log 'INFO' ('driver de Vanguard (' + $oem + ') no se pudo quitar ahora: se reintenta al reiniciar con los restos') }
            }
        }
        # Tareas programadas de Vanguard (no la del cliente de Riot)
        foreach ($tk in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { ($_.TaskName -like '*Vanguard*') -or ($_.TaskPath -like '*Vanguard*') -or (@($_.Actions | Where-Object { [string]$_.Execute -like '*Riot Vanguard*' }).Count -gt 0) })) {
            if ($tk.TaskName -eq 'BorrarRestosVanguard') { continue }
            try { Unregister-ScheduledTask -TaskName $tk.TaskName -TaskPath $tk.TaskPath -Confirm:$false -ErrorAction Stop; Log 'OK' ('tarea programada de Vanguard borrada: ' + $tk.TaskName); $pasos += 'tarea programada de Vanguard: borrada' } catch { Log 'INFO' ('tarea de Vanguard ' + $tk.TaskName + ': ' + $_.Exception.Message) }
        }
        # Restos de claves de registro de los servicios (sin tocar el cliente de Riot ni los juegos)
        foreach ($sv in 'vgc', 'vgk') {
            $kv = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $sv
            if (Test-Path -LiteralPath $kv) { Remove-Item -LiteralPath $kv -Recurse -Force -ErrorAction SilentlyContinue; if (-not (Test-Path -LiteralPath $kv)) { Log 'OK' ('clave del servicio ' + $sv + ' borrada') } }
        }
        foreach ($e in $entradas) { if (Test-Path -LiteralPath $e.PSPath) { Remove-Item -LiteralPath $e.PSPath -Recurse -Force -ErrorAction SilentlyContinue; if (-not (Test-Path -LiteralPath $e.PSPath)) { $pasos += 'entrada de Riot Vanguard en Programas: borrada' } } }
        # 4) Restos en el disco principal: carpetas "Riot Vanguard" (o "Vanguard" dentro de una carpeta de Riot) en
        #    Archivos de programa, ProgramData, AppData de cada usuario y Temp; el driver vgk.sys y el inicio automatico
        #    de la bandeja (vgtray). No toca el cliente de Riot ni los juegos.
        $sd = $env:SystemDrive
        # Cada raiz con cuantos niveles se revisan (pocos, para que sea rapido)
        $raices = @(@($pf, 1), @(${env:ProgramFiles(x86)}, 1), @($env:ProgramData, 2), @((Join-Path $env:SystemRoot 'Temp'), 1))
        foreach ($u in @(Get-ChildItem -LiteralPath ($sd + '\Users') -Directory -Force -ErrorAction SilentlyContinue | Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })) {
            foreach ($sub in 'AppData\Local', 'AppData\Roaming', 'AppData\LocalLow') { $raices += , @((Join-Path $u.FullName $sub), 2) }
            $raices += , @((Join-Path $u.FullName 'AppData\Local\Temp'), 1)
        }
        $rp = [IO.FileAttributes]::ReparsePoint
        $restos = New-Object System.Collections.Generic.List[string]
        # Sin entrar en accesos directos de carpeta (junctions)
        foreach ($par in $raices) {
            $r0 = [string]$par[0]
            if ((-not $r0) -or (-not (Test-Path -LiteralPath $r0))) { continue }
            $nivel = @(Get-Item -LiteralPath $r0 -Force -ErrorAction SilentlyContinue)
            for ($d = 0; $d -lt [int]$par[1] -and $nivel.Count -gt 0; $d++) {
                $sig = @()
                foreach ($c in $nivel) {
                    foreach ($h in @(Get-ChildItem -LiteralPath $c.FullName -Directory -Force -ErrorAction SilentlyContinue)) {
                        if ($h.Attributes -band $rp) { continue }
                        $esVg = ($h.Name -like '*Riot Vanguard*') -or (($h.Name -eq 'Vanguard') -and ($c.Name -like '*Riot*'))
                        if ($esVg) { $restos.Add($h.FullName) } else { $sig += $h }
                    }
                }
                $nivel = $sig
            }
        }
        $drvVgk = Join-Path $env:SystemRoot 'System32\drivers\vgk.sys'
        if (Test-Path -LiteralPath $drvVgk) { $restos.Add($drvVgk) }
        $quedan = @()
        foreach ($x in @($restos | Select-Object -Unique)) {
            if (Test-Path -LiteralPath $x -PathType Container) {
                # rd no sigue los accesos directos de carpeta que haya adentro: solo borra lo que es de Vanguard
                & takeown.exe /f $x /a /r /d s 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) { & takeown.exe /f $x /a /r /d y 2>&1 | Out-Null }
                & icacls.exe $x /grant '*S-1-5-32-544:F' /t /c /q 2>&1 | Out-Null
                & cmd.exe /c ('rd /s /q "' + $x + '"') 2>&1 | Out-Null
            } else {
                & takeown.exe /f $x /a 2>&1 | Out-Null
                & icacls.exe $x /grant '*S-1-5-32-544:F' /c /q 2>&1 | Out-Null
                Remove-Item -LiteralPath $x -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $x) { $quedan += $x; Log 'INFO' ('resto de Vanguard en uso, se borra al reiniciar: ' + $x) }
            else { Log 'OK' ('resto de Vanguard borrado: ' + $x) }
        }
        # Inicio automatico de la bandeja de Vanguard
        foreach ($rk in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
            $vals = Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue
            if (-not $vals) { continue }
            foreach ($pp in @($vals.PSObject.Properties | Where-Object { ($_.Name -notlike 'PS*') -and (([string]$_.Value -like '*Riot Vanguard*') -or ([string]$_.Value -like '*vgtray*')) })) {
                Remove-ItemProperty -LiteralPath $rk -Name $pp.Name -Force -ErrorAction SilentlyContinue
                Log 'OK' ('inicio automatico de Vanguard quitado: ' + $pp.Name)
            }
        }
        # Lo que esta en uso (por ejemplo el driver cargado) se borra solo al reiniciar, antes de que nada lo use
        if ($quedan.Count -gt 0) {
            $tn = 'BorrarRestosVanguard'
            $cmds = @(foreach ($x in $quedan) { if ($x -like '*.sys') { 'del /f /q "' + $x + '"' } else { 'rd /s /q "' + $x + '"' } })
            try {
                $act = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c ' + ($cmds -join ' & ') + ' & schtasks.exe /delete /tn ' + $tn + ' /f')
                $trg = New-ScheduledTaskTrigger -AtStartup
                $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
                Register-ScheduledTask -TaskName $tn -Action $act -Trigger $trg -Principal $prn -Force | Out-Null
            } catch { Log 'INFO' ('no se pudo programar el borrado al reiniciar: ' + $_.Exception.Message) }
        }
        $nRestos = @($restos | Select-Object -Unique).Count - $quedan.Count
        if ($nRestos -gt 0) { Say ('  Restos de Vanguard borrados del disco: ' + $nRestos + '.'); $pasos += ('carpetas y archivos de Vanguard borrados: ' + $nRestos) }
        foreach ($ps in @($pasos | Select-Object -Unique)) { Say ('  - ' + $ps) }
        $script:VgBorrado = $true
        Start-Sleep -Seconds 1
        $queda = (Get-Service -Name 'vgc', 'vgk' -ErrorAction SilentlyContinue) -or (Test-Path $vgDir) -or ($quedan.Count -gt 0)
        if (-not $queda) {
            Log 'OK' 'Riot Vanguard desinstalado del todo, sin restos en el disco: abri el cliente de Riot y te pide instalarlo de nuevo'
            Say '  Riot Vanguard desinstalado, sin restos. REINICIA LA PC SIN FALTA antes de volver a instalar Vanguard (o abrir VALORANT o LoL): si lo instalas sin reiniciar pueden salir errores y bucles de instalacion.' 'Yellow'
            $code = 0
        } else {
            Log 'PENDIENTE' 'Riot Vanguard quitado: quedan restos en uso que se borran al reiniciar'
            Say '  Riot Vanguard quitado: los restos que estaban en uso se borran al reiniciar. REINICIA LA PC SIN FALTA antes de volver a instalar Vanguard (o abrir VALORANT o LoL): si lo instalas sin reiniciar pueden salir errores y bucles de instalacion.' 'Yellow'
            $code = 6
        }
    } | Out-Null
    return $code
}

# ------------------------------------------------------------
# Respuesta de la app para cada opcion: viene en la variable XR_<id> (S, N o R). Sin respuesta = N.
# ------------------------------------------------------------
# Nombres de las apps instaladas (Store y programas de escritorio): comparar antes y despues dice que se desinstalo
function Snap-Apps {
    $l = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($p in @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue)) {
        if ((-not $p.IsFramework) -and ($p.SignatureKind -ne 'System')) { [void]$l.Add(([string]$p.Name -replace '^Microsoft\.', '')) }
    }
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        foreach ($i in @(Get-ItemProperty -Path $k -ErrorAction SilentlyContinue)) {
            # sin la version del final, para que una actualizacion durante la corrida no cuente como app borrada
            if ($i.DisplayName -and (-not $i.SystemComponent)) { [void]$l.Add((([string]$i.DisplayName) -replace '\s+v?\d+(\.\d+)+.*$', '').Trim()) }
        }
    }
    return , $l
}

function Respuesta([string]$id) {
    $l = ([string][Environment]::GetEnvironmentVariable('XR_' + $id)).Trim().ToUpper()
    if (($l -eq 'S') -or ($l -eq 'R')) { return $l }
    return 'N'
}

# ------------------------------------------------------------
# Corre la lista de opciones de una parte. Cada opcion es un hashtable:
#   Id, Seccion, Q ("- Desea ...?"), Hace, Favor, Contra, S (lo que hace con S), R (con R; si no tiene, no hay restaurar)
#   Saltar (opcional): devuelve $true si la opcion no va en esta PC (ya anota el motivo)
# ------------------------------------------------------------
function Correr-Opciones {
    param([string]$Nombre, [string]$Titulo, $Lista, [string[]]$Rein, [string[]]$Win10, [string]$Salida, [string]$Carpeta)
    $enc = [Text.Encoding]::GetEncoding(850)
    $fs = $null
    try {
        if ($Salida) {
            $fs = New-Object IO.FileStream($Salida, [IO.FileMode]::Create, [IO.FileAccess]::Write, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            $script:XSalida = New-Object IO.StreamWriter($fs, $enc)
            $script:XSalida.AutoFlush = $true
        }
        Leer-Info
        $script:XCarpeta = $Carpeta
        $script:ReinIds = @($Rein)
        $script:Reinicio = $false; $script:VgAviso = $false; $script:VgBorrado = $false; $script:VgHecho = $false; $script:Parar = $false
        $dir = Join-Path $Carpeta 'logs'
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (-not (Test-Path -LiteralPath $dir)) { $dir = $env:TEMP }
        $script:XLog = Join-Path $dir ($Nombre + '_' + $script:Stamp + '.txt')
        Log-Cabecera
        Log 'INFO' ('Inicio de ' + $Nombre)
        Reparar-Licencia

        Say ($Titulo + ' - build detectado: ' + $script:Build)
        $viejo = ($script:Build -gt 0) -and ($script:Build -lt 10240)
        if ($viejo) { Say 'Nota: tenes Windows 7 u 8. Las opciones que necesitan Windows 10 u 11 se saltean solas.' }
        elseif (($script:Build -gt 0) -and ($script:Build -lt 22000)) { Say 'Nota: esto esta pensado para Windows 11, en Windows 10 algunas opciones pueden no existir o fallar.' }
        Say ('Cada cambio se verifica y queda anotado en: ' + $script:XLog)

        # Para el resumen final de la app: espacio libre y apps instaladas antes de tocar nada (solo cuando la app lee la salida)
        $apps0 = $null; $libre0 = -1
        # XR_XRES lo pone la app solo en Aplicar/Restablecer: las tareas de drivers o de la lista de juegos no necesitan el resumen
        $conResumen = ($script:XSalida -and ($env:XR_XRES -eq '1'))
        if ($conResumen) {
            try { $libre0 = [int64]([IO.DriveInfo]::new($env:SystemDrive.Substring(0, 1)).AvailableFreeSpace) } catch { }
            $apps0 = Snap-Apps
        }
        $sec = ''
        foreach ($o in $Lista) {
            if ($o.Seccion -ne $sec) { $sec = $o.Seccion; Say ''; Say ''; Say ('=== ' + $sec + ' ===') }
            # Windows 7 y 8: lo que necesita Windows 10 u 11 no se corre (ni su Saltar/Antes/N); si la habias marcado, se avisa
            if ($viejo -and (@($Win10) -contains $o.Id)) {
                if (((Respuesta $o.Id) -ne 'N') -or ($script:XConsola -and $o.Preguntar)) {
                    Say ''; Say ([string]$o.Q); Say '  Omitido: necesita Windows 10 u 11, en tu Windows no existe.'
                    Log 'OMITIDO' ($o.Id + ' - necesita Windows 10 u 11 (build ' + $script:Build + ')')
                }
                continue
            }
            if ($o.Saltar -and (& $o.Saltar)) { continue }
            # Avisos que van antes de la pregunta
            if ($o.Antes) { foreach ($l in @(& $o.Antes)) { Say ([string]$l) 'Yellow' } }
            $script:QAct = $o.Id
            $let = Respuesta $o.Id
            $q = [string]$o.Q
            $de = ' (app)'
            # En la ventana a la vista se explica cada opcion; las que tienen Preguntar se contestan ahi
            if ($script:XConsola) {
                Say ''
                if ($o.Hace) { Say ('  Que hace: ' + $o.Hace) }
                if ($o.Favor) { Say ('  A favor: ' + $o.Favor) }
                if ($o.Contra) { Say ('  En contra: ' + $o.Contra) }
                if ($o.Preguntar) {
                    $let = ([string](Read-Host ($q + ' [S] Si  [N] No'))).Trim().ToUpper()
                    if ($let -ne 'S') { $let = 'N' }
                    $de = ''
                }
            }
            if (($let -eq 'R') -and (-not $o.R)) { $let = 'N' }
            Say ''
            Say ($q + ' [' + $let + ']')
            # Las que contestaron N no se anotan en el log: solo lo que se activo y lo que dio error
            if ($let -eq 'N') { if ($o.N) { & $o.N | Out-Null }; continue }
            Log 'PREG' ($let + $de + ' - ' + $q.Substring(0, [math]::Min(80, $q.Length)))
            try {
                if ($let -eq 'S') { & $o.S | Out-Null } else { & $o.R | Out-Null }
            } catch {
                Log 'PS-ERROR' ($o.Id + ' - ' + ($_.Exception.Message -replace '\s+', ' ') + ' (linea ' + $_.InvocationInfo.ScriptLineNumber + ')')
                $script:OptT++; $script:OptF++
                Opt-Fin $o.Id
            }
            # Se corta aca, sin resumen (por ejemplo: se abrio el instalador de Windows 11)
            if ($script:Parar) { return }
        }

        # Lineas para la app (XRES|...): espacio que gano el disco y apps que ya no estan. Si algo cambia, sale en el cartel final.
        if ($conResumen) {
            try {
                $libre1 = [int64]([IO.DriveInfo]::new($env:SystemDrive.Substring(0, 1)).AvailableFreeSpace)
                if (($libre0 -ge 0) -and (($libre1 - $libre0) -ge 1048576)) { Say ('XRES|libre|' + ($libre1 - $libre0)) }
            } catch { }
            if ($apps0) { foreach ($n in @(Snap-Apps | ForEach-Object { $_ })) { [void]$apps0.Remove($n) } ; foreach ($n in ($apps0 | Sort-Object)) { Say ('XRES|app|' + $n) } }
        }
        Say ''
        Say ''
        Say '=== RESUMEN ==='
        $txtLog = ''
        try { $txtLog = [IO.File]::ReadAllText($script:XLog) } catch { }
        $nFallo = ([regex]::Matches($txtLog, '\[(FALLO|PS-ERROR)\]')).Count
        $nAten = ([regex]::Matches($txtLog, '\[ATENCION\]')).Count
        $nPend = ([regex]::Matches($txtLog, '\[PENDIENTE\]')).Count
        Say ('  Cambios que fallaron: ' + $nFallo + '  -  Opciones con problemas: ' + $nAten + '  -  Pendientes: ' + $nPend)
        if (($nFallo + $nAten + $nPend) -eq 0) { Say '  Todo salio bien: no hubo errores ni cosas sin encontrar.' 'Green' }
        else {
            Say '  NO todo salio bien. Esto fallo o quedo pendiente (detalle en el log):' 'Yellow'
            foreach ($l in @($txtLog -split "`r?`n" | Where-Object { $_ -match '\[(FALLO|PS-ERROR|PENDIENTE)\]' } | Select-Object -First 15)) { Say ('   ' + ($l -replace '^\[[\d:.]+\]\s*', '')) 'Yellow' }
        }
        Say ('  Log completo en: ' + $script:XLog)
        Log 'INFO' ('Fin. Cambios fallidos: ' + $nFallo + ', opciones con problemas: ' + $nAten)
        if ($script:VgBorrado) {
            Say ''
            Say 'REINICIA LA PC SIN FALTA ANTES de volver a instalar Vanguard (o abrir VALORANT o LoL): si lo instalas sin reiniciar pueden salir errores y bucles de instalacion.' 'Yellow'
            Log 'ATENCION' 'Vanguard quitado: hay que reiniciar la PC antes de reinstalarlo'
            $script:Reinicio = $true
        }
        if ($script:VgAviso) {
            Say ''
            Say 'OBLIGATORIO REINICIAR ANTES DE PODER JUGAR VALORANT YA QUE DESACTIVASTE LOS AJUSTES DE SEGURIDAD.'
            Log 'ATENCION' 'Se desactivaron ajustes de seguridad: hay que reiniciar antes de jugar Valorant'
            $script:Reinicio = $true
        }
        Say ''
        foreach ($ra in @($script:ReinicioApps | Where-Object { $_ } | Select-Object -Unique)) { Say ('XRES|reinicio|' + $ra) }
        foreach ($oa in @($script:OmitidasApps | Where-Object { $_ } | Select-Object -Unique)) { Say ('XRES|omitida|' + $oa) }
        if ($script:Reinicio) { Say 'Hace falta reiniciar la PC para terminar de aplicar algunos cambios.' }
        else { Say 'No hace falta reiniciar: los cambios ya quedaron aplicados.' }
    } finally {
        if ($script:XSalida) { try { $script:XSalida.Dispose() } catch { }; $script:XSalida = $null }
        if ($fs) { try { $fs.Dispose() } catch { } }
    }
}
