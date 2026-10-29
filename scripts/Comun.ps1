# ============================================================
#  COMUN: lo que usan todas las partes del optimizador (Gaming, Debloat y, mas adelante, Limpieza).
#  La app XucaOP.ps1 carga este archivo y el de la parte (Gaming.ps1 o Debloat.ps1) en un hilo aparte,
#  dentro del mismo proceso: ya no se abre cmd ni un powershell.exe nuevo por cada opcion.
#  Cada cambio se verifica y queda anotado en la carpeta "logs", igual que con los .bat.
#  Este archivo va sin acentos (igual que los demas) para que ninguna PC lo rompa.
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

# Estado de la corrida
$XSalida = $null            # lo que la app lee para mostrar el progreso
$XLog = $null               # archivo de log
$OptT = 0; $OptF = 0; $OptS = 0; $OptP = 0
$QAct = ''                  # opcion que se esta aplicando
$Reinicio = $false          # alguna opcion que necesita reiniciar cambio algo de verdad
$ReinIds = @()
$VgAviso = $false           # se apago algo de seguridad: hay que reiniciar antes de jugar Valorant
$VgHecho = $false           # Vanguard ya se reviso (o se borro) en una opcion anterior
$Build = 0; $RamGB = 0; $EsHdd = $false; $Stamp = ''
$XCarpeta = ''              # carpeta scripts (donde estan los .ps1, Edge.txt y logs)
$XConsola = $false          # corre en una ventana de PowerShell a la vista (herramientas que te piden datos)
$Parar = $false             # una opcion pidio cortar aca (por ejemplo, se abrio el instalador de Windows)

# ------------------------------------------------------------
# Salida y log
# ------------------------------------------------------------
function Log([string]$tag, [string]$msg) {
    if (-not $script:XLog) { return }
    try { [IO.File]::AppendAllText($script:XLog, ('[{0}] [{1}] {2}' -f (Get-Date -Format 'HH:mm:ss.fff'), $tag, $msg) + "`r`n", [Text.Encoding]::Default) } catch { }
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
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
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
# Registro. Las rutas van como en reg.exe: "HKCU\Control Panel\Mouse". Los tipos son REG_DWORD o REG_SZ.
# ------------------------------------------------------------
# $modo: 'leer', 'borrar' (abre con permiso de escritura) o 'crear' (la crea si no existe)
function Reg-Abrir([string]$ruta, [string]$modo) {
    $i = $ruta.IndexOf('\')
    $raiz = $(if ($i -lt 0) { $ruta } else { $ruta.Substring(0, $i) })
    $sub = $(if ($i -lt 0) { '' } else { $ruta.Substring($i + 1) })
    $h = switch ($raiz.ToUpper()) {
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
function Svc([string]$nombre, [string]$modo, [string]$inicio) {
    $rk = 'HKLM\SYSTEM\CurrentControlSet\Services\' + $nombre
    if (-not (Reg-Existe $rk)) { Log 'OMITIDO' ('el servicio ' + $nombre + ' no existe en esta PC'); return }
    if (Reg-Igual (Reg-Leer $rk 'Start') $inicio 'REG_DWORD') { $script:OptS++; Log 'OK' ('el servicio ' + $nombre + ' ya estaba con inicio ' + $modo); return }
    # Disabled y manual se cambian sin abrir otro programa; auto y delayed-auto van por sc.exe (deja bien el "retrasado")
    $hecho = $false
    if (($modo -eq 'disabled') -or ($modo -eq 'demand')) {
        try { Set-Service -Name $nombre -StartupType $(if ($modo -eq 'disabled') { 'Disabled' } else { 'Manual' }) -ErrorAction Stop; $hecho = $true } catch { }
    }
    if (-not $hecho) { & sc.exe config $nombre start= $modo 2>&1 | Out-Null }
    $script:OptT++
    Reg-Verif $rk 'Start' $inicio
}

function Svc-Parar([string]$nombre) {
    $s = Get-Service -Name $nombre -ErrorAction SilentlyContinue
    if ((-not $s) -or ($s.Status -ne 'Running')) { return }
    & sc.exe stop $nombre 2>&1 | Out-Null
    Log 'INFO' ('servicio ' + $nombre + ' detenido')
}

function Svc-Arrancar([string]$nombre) {
    $s = Get-Service -Name $nombre -ErrorAction SilentlyContinue
    if ((-not $s) -or ($s.Status -ne 'Stopped')) { return }
    & sc.exe start $nombre 2>&1 | Out-Null
    Log 'INFO' ('servicio ' + $nombre + ' iniciado')
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
        foreach ($sv in 'vgc', 'vgk') {
            $s = Get-Service -Name $sv -ErrorAction SilentlyContinue
            if ($s) { & sc.exe stop $sv 2>&1 | Out-Null; & sc.exe delete $sv 2>&1 | Out-Null }
        }
        foreach ($e in $entradas) { if (Test-Path -LiteralPath $e.PSPath) { Remove-Item -LiteralPath $e.PSPath -Recurse -Force -ErrorAction SilentlyContinue } }
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
        if ($nRestos -gt 0) { Say ('  Restos de Vanguard borrados del disco: ' + $nRestos + '.') }
        Start-Sleep -Seconds 1
        $queda = (Get-Service -Name 'vgc', 'vgk' -ErrorAction SilentlyContinue) -or (Test-Path $vgDir) -or ($quedan.Count -gt 0)
        if (-not $queda) {
            Log 'OK' 'Riot Vanguard desinstalado del todo, sin restos en el disco: abri el cliente de Riot y te pide instalarlo de nuevo'
            Say '  Riot Vanguard desinstalado, sin restos. Reinicia, abri el cliente de Riot y te pide instalarlo de nuevo.' 'Yellow'
            $code = 0
        } else {
            Log 'PENDIENTE' 'Riot Vanguard quitado: quedan restos en uso que se borran al reiniciar'
            Say '  Riot Vanguard quitado: los restos que estaban en uso se borran al reiniciar. Despues abri el cliente de Riot y te pide instalarlo.' 'Yellow'
            $code = 6
        }
    } | Out-Null
    return $code
}

# ------------------------------------------------------------
# Respuesta de la app para cada opcion: viene en la variable XR_<id> (S, N o R). Sin respuesta = N.
# ------------------------------------------------------------
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
    param([string]$Nombre, [string]$Titulo, $Lista, [string[]]$Rein, [string]$Salida, [string]$Carpeta)
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
        $script:Reinicio = $false; $script:VgAviso = $false; $script:VgHecho = $false; $script:Parar = $false
        $dir = Join-Path $Carpeta 'logs'
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (-not (Test-Path -LiteralPath $dir)) { $dir = $env:TEMP }
        $script:XLog = Join-Path $dir ($Nombre + '_' + $script:Stamp + '.txt')
        Log-Cabecera
        Log 'INFO' ('Inicio de ' + $Nombre)

        Say ($Titulo + ' - build detectado: ' + $script:Build)
        if (($script:Build -gt 0) -and ($script:Build -lt 22000)) { Say 'Nota: esto esta pensado para Windows 11, en Windows 10 algunas opciones pueden no existir o fallar.' }
        Say ('Cada cambio se verifica y queda anotado en: ' + $script:XLog)

        $sec = ''
        foreach ($o in $Lista) {
            if ($o.Seccion -ne $sec) { $sec = $o.Seccion; Say ''; Say ''; Say ('=== ' + $sec + ' ===') }
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
            Log 'PREG' ($let + $de + ' - ' + $q.Substring(0, [math]::Min(80, $q.Length)))
            if ($let -eq 'N') { if ($o.N) { & $o.N | Out-Null }; continue }
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

        Say ''
        Say ''
        Say '=== RESUMEN ==='
        $txtLog = ''
        try { $txtLog = [IO.File]::ReadAllText($script:XLog) } catch { }
        $nFallo = ([regex]::Matches($txtLog, '\[FALLO\]')).Count
        $nAten = ([regex]::Matches($txtLog, '\[ATENCION\]')).Count
        Say ('  Cambios que fallaron: ' + $nFallo + '  -  Opciones con problemas: ' + $nAten)
        Say ('  Log completo en: ' + $script:XLog)
        Log 'INFO' ('Fin. Cambios fallidos: ' + $nFallo + ', opciones con problemas: ' + $nAten)
        if ($script:VgAviso) {
            Say ''
            Say 'OBLIGATORIO REINICIAR ANTES DE PODER JUGAR VALORANT YA QUE DESACTIVASTE LOS AJUSTES DE SEGURIDAD.'
            Log 'ATENCION' 'Se desactivaron ajustes de seguridad: hay que reiniciar antes de jugar Valorant'
            $script:Reinicio = $true
        }
        Say ''
        if ($script:Reinicio) { Say 'Hace falta reiniciar la PC para terminar de aplicar algunos cambios.' }
        else { Say 'No hace falta reiniciar: los cambios ya quedaron aplicados.' }
    } finally {
        if ($script:XSalida) { try { $script:XSalida.Dispose() } catch { }; $script:XSalida = $null }
        if ($fs) { try { $fs.Dispose() } catch { } }
    }
}
