# ============================================================
#  ACTUALIZACIONES DESDE GITHUB
#  La version se controla con el archivo version.txt del repo.
#  Si el version.txt de GitHub es distinto al de tu PC (al lado de este archivo),
#  al abrir la app sale el cartel amarillo de actualizacion.
# ============================================================
$XucaRepo = '011Xuca/xuca-optimizer'
$XucaRama = 'main'

$ErrorActionPreference = 'Stop'

# --- Permisos de administrador ---
$yo = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $yo.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $PSCommandPath + '"')
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Mostrar-Error($msg) {
    [Windows.MessageBox]::Show($msg, 'Xuca OPtimizer', 'OK', 'Error') | Out-Null
}

# La app corre como administrador: las paginas y los archivos se abren con explorer.exe para que el navegador
# o el visor arranquen como usuario normal (abrirlos como admin les da permisos que no necesitan).
function Abrir-Normal([string]$que) {
    if (-not $que) { return }
    try { Start-Process -FilePath (Join-Path $env:WINDIR 'explorer.exe') -ArgumentList ('"' + ($que -replace '"', '%22') + '"') -ErrorAction Stop }
    catch { try { Start-Process $que } catch { } }
}

try {

$AppPath = $PSCommandPath
$Root = Split-Path -Parent $AppPath
$Redes = 'https://linktr.ee/011xuca'
$Scripts = Join-Path $Root 'scripts'
$Rutas = [ordered]@{
    Debloat  = Join-Path $Scripts 'windows_debloat.bat'
    Gaming   = Join-Path $Scripts 'optimizacion_gaming.bat'
    Limpieza = Join-Path $Scripts 'limpiar_cache.bat'
}
# Archivos que se bajan al actualizar (Remoto = donde esta cada uno dentro del repo). El version.txt se baja ultimo.
# Si agregas un archivo nuevo al repo que la app necesita, sumalo a esta lista para que les llegue a todos.
# XucaOP.bat puede seguir abierto mientras se reemplaza y cmd sigue leyendo el archivo nuevo desde donde iba:
# no cambies nada de XucaOP.bat antes de la linea "exit /b" (lo de despues se puede cambiar).
$VersionLocal = Join-Path $Root 'version.txt'
$ArchivosUpd = @(
    [pscustomobject]@{ Nombre = 'XucaOP.ps1'; Local = $AppPath; Remoto = 'XucaOP.ps1' },
    [pscustomobject]@{ Nombre = 'XucaOP.bat'; Local = (Join-Path $Root 'XucaOP.bat'); Remoto = 'XucaOP.bat' },
    [pscustomobject]@{ Nombre = 'LEEME.txt'; Local = (Join-Path $Root 'LEEME.txt'); Remoto = 'LEEME.txt'; Opc = $true },
    [pscustomobject]@{ Nombre = 'windows_debloat.bat'; Local = $Rutas.Debloat; Remoto = 'scripts/windows_debloat.bat' },
    [pscustomobject]@{ Nombre = 'optimizacion_gaming.bat'; Local = $Rutas.Gaming; Remoto = 'scripts/optimizacion_gaming.bat' },
    [pscustomobject]@{ Nombre = 'limpiar_cache.bat'; Local = $Rutas.Limpieza; Remoto = 'scripts/limpiar_cache.bat' },
    [pscustomobject]@{ Nombre = 'lang/en-en/textos.txt'; Local = (Join-Path $Root 'lang\en-en\textos.txt'); Remoto = 'lang/en-en/textos.txt'; Opc = $true },
    [pscustomobject]@{ Nombre = 'lang/es-mx/textos.txt'; Local = (Join-Path $Root 'lang\es-mx\textos.txt'); Remoto = 'lang/es-mx/textos.txt'; Opc = $true }
)

# ------------------------------------------------------------
# Preferencias de la app (idioma y mensaje de Ko-fi). Se guardan en ProgramData\XucaScripts\app_config.txt
# ------------------------------------------------------------
$ConfigArchivo = Join-Path (Join-Path $env:ProgramData 'XucaScripts') 'app_config.txt'
# En esa carpeta quedan programas que Windows corre como SYSTEM: solo admins y SYSTEM pueden escribir ahi.
# Si un usuario comun la habia creado antes (y era el duenio), se le saca ese control.
try {
    $dXuca = Join-Path $env:ProgramData 'XucaScripts'
    if (-not (Test-Path -LiteralPath $dXuca)) { New-Item -ItemType Directory -Path $dXuca -Force | Out-Null }
    $aclX = Get-Acl -LiteralPath $dXuca
    $malX = (@('S-1-5-32-544', 'S-1-5-18') -notcontains $aclX.GetOwner([Security.Principal.SecurityIdentifier]).Value) -or (-not $aclX.AreAccessRulesProtected)
    if ($malX) {
        & icacls.exe $dXuca /setowner '*S-1-5-32-544' /T /C /Q 2>&1 | Out-Null
        & icacls.exe $dXuca /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' /C /Q 2>&1 | Out-Null
        if (@(Get-ChildItem -LiteralPath $dXuca -Force -ErrorAction SilentlyContinue).Count -gt 0) { & icacls.exe (Join-Path $dXuca '*') /reset /T /C /Q 2>&1 | Out-Null }
    }
} catch { }
function Leer-Config {
    $c = @{}
    try {
        if (Test-Path -LiteralPath $ConfigArchivo) {
            foreach ($l in @(Get-Content -LiteralPath $ConfigArchivo -ErrorAction Stop)) { $i = $l.IndexOf('='); if ($i -gt 0) { $c[$l.Substring(0, $i).Trim()] = $l.Substring($i + 1).Trim() } }
        }
    } catch { }
    return $c
}
function Guardar-Config([string]$clave, [string]$valor) {
    try {
        $c = Leer-Config
        $c[$clave] = $valor
        $d = Split-Path -Parent $ConfigArchivo
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Set-Content -LiteralPath $ConfigArchivo -Value @($c.Keys | Sort-Object | ForEach-Object { $_ + '=' + $c[$_] }) -Encoding ASCII
    } catch { }
}

# ------------------------------------------------------------
# Tema (Sistema, Claro u Oscuro). La app esta hecha en oscuro: en claro solo cambian el fondo, sus tonos y las letras;
# los colores de acento (botones, bordes, iconos) quedan iguales. Se guarda en app_config.txt como tema=...
# ------------------------------------------------------------
$script:TemaCfg = [string](Leer-Config)['tema']
if ($script:TemaCfg -notin 'sistema', 'claro', 'oscuro') { $script:TemaCfg = 'sistema' }
function Windows-EnClaro {
    try { return ([int](Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction Stop).AppsUseLightTheme -eq 1) } catch { return $false }
}
$script:Claro = ($script:TemaCfg -eq 'claro') -or (($script:TemaCfg -eq 'sistema') -and (Windows-EnClaro))
# Fondos y sus tonos (oscuro -> claro)
$MapaClaro = @{
    '#14161B' = '#F2F4F7'; '#0E1014' = '#FFFFFF'; '#1C2027' = '#FFFFFF'; '#181A1F' = '#F6F7F9'; '#232833' = '#E3E6EC'
    '#262B34' = '#E8EAEE'; '#2A2D33' = '#E8EAEE'; '#2E3440' = '#D5D9E0'; '#3A414E' = '#C2C8D1'; '#3A404C' = '#C2C8D1'
    '#1E232D' = '#E1E4EA'; '#1F2D4A' = '#DCE6FA'; '#1A2238' = '#EAF0FD'; '#231A2A' = '#FBEDF5'; '#171D2C' = '#FFFFFF'
    '#1C1722' = '#FCF6FA'; '#1B2130' = '#FFFFFF'; '#1D1A24' = '#FBF7FC'; '#1C1A26' = '#FAF4F8'; '#14222B' = '#E6F5FC'
    '#1A2A33' = '#E6F4FA'; '#221A0E' = '#FDF2E4'; '#3A2A12' = '#FAE2C4'; '#22D3EE' = '#0891B2'; '#0F2119' = '#E3F7EF'; '#163A2B' = '#C9EFDD'; '#182008' = '#F1FAE0'; '#263512' = '#DCF0BC'
    '#1E3A2C' = '#DDF3E6'; '#1E3A2B' = '#DDF3E6'; '#3A1E1E' = '#FBE3E3'; '#3A1F40' = '#F7E3FA'; '#3A1F1F' = '#FBE3E3'
    '#16291F' = '#E5F6EC'; '#2F5A40' = '#A9DCBC'
    '#14FFFFFF' = '#0F000000'; '#0AFFFFFF' = '#08000000'; '#30FFFFFF' = '#22000000'
    # Letras
    '#FFFFFF' = '#15181E'; '#C3C8D0' = '#3E4451'; '#C9CDD4' = '#374151'; '#9AA0A6' = '#5F6672'; '#7D8590' = '#6B7280'
    '#5C6370' = '#8A919C'; '#A9B0BD' = '#4B5260'; '#9AA6C4' = '#5A6684'; '#E6E8EB' = '#1F2937'; '#D3E9F3' = '#0C4A6E'
    '#9AC7A8' = '#3F7A52'; '#E8C4C0' = '#8A2A1E'
}
# Letras de color: en claro se oscurecen un poco para que se lean sobre el fondo blanco (solo en textos)
$MapaLetraClara = @{
    '#8AB4F8' = '#2B5FC9'; '#81C995' = '#1E7F45'; '#F28B82' = '#C5352A'; '#E5B567' = '#A86A12'; '#8FD3F4' = '#0B7FB3'
    '#C58AF9' = '#7C3AED'; '#F9A8D4' = '#C0307F'; '#6EE7B7' = '#0E8A63'; '#BEF264' = '#4D7C0F'; '#F6AD55' = '#B95A0A'; '#E879F9' = '#A626B8'
}
function Tema-Hex([string]$hex) {
    if ((-not $script:Claro) -or (-not $hex) -or (-not $hex.StartsWith('#'))) { return $hex }
    $v = $MapaClaro[$hex]
    if ($v) { return $v }
    return $hex
}
function Tema-Letra([string]$hex) {
    if ($script:Claro -and $hex) { $v = $MapaLetraClara[$hex]; if ($v) { return $v } }
    return (Tema-Hex $hex)
}
function Color-Tema([string]$hex) { return [Windows.Media.ColorConverter]::ConvertFromString((Tema-Hex $hex)) }
# Para los XAML: cambia cada color por el del tema
function Tema-Texto([string]$x) {
    if (-not $script:Claro) { return $x }
    return [regex]::Replace($x, '#[0-9A-Fa-f]{6,8}\b', [Text.RegularExpressions.MatchEvaluator] { param($m) Tema-Hex $m.Value })
}

# ------------------------------------------------------------
# Idioma (por defecto ingles). Cada idioma tiene su carpeta en lang\<idioma>\textos.txt
# (cada linea: texto en espanol tal cual esta en la app o en los .bat, TAB, texto a mostrar).
# El espanol viene adentro de la app: lang\es-mx\textos.txt sirve para corregir textos sin tocar el codigo.
# Si falta el archivo de ingles, la app se muestra en espanol.
# ------------------------------------------------------------
$LangDir = Join-Path $Root 'lang'
$script:Idioma = [string](Leer-Config)['idioma']
if ($script:Idioma -notmatch '^[a-z]{2}-[a-z]{2}$') { $script:Idioma = 'en-en' }
$script:Trad = $null
$script:TradRx = $null
$script:TradCache = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::Ordinal)
function Cargar-Idioma([string]$id) {
    $script:Trad = $null; $script:TradRx = $null; $script:TradCache.Clear()
    $f = Join-Path (Join-Path $LangDir $id) 'textos.txt'
    if (-not (Test-Path -LiteralPath $f)) { return ($id -eq 'es-mx') }
    $d = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::Ordinal)
    foreach ($l in [IO.File]::ReadAllLines($f, [Text.Encoding]::UTF8)) {
        if ((-not $l) -or $l.StartsWith('#')) { continue }
        $i = $l.IndexOf([char]9)
        if ($i -lt 1) { continue }
        $d[$l.Substring(0, $i)] = $l.Substring($i + 1)
    }
    if ($d.Count -eq 0) { return ($id -eq 'es-mx') }
    $script:Trad = $d
    # Para textos armados con partes (por ejemplo "Tenes " + version), se traducen los pedazos que esten en el archivo
    $pats = foreach ($k in @($d.Keys | Where-Object { $_.Length -ge 5 } | Sort-Object Length -Descending)) {
        $p = [regex]::Escape($k)
        if ($k -match '^\w') { $p = '(?<!\w)' + $p }
        if ($k -match '\w$') { $p = $p + '(?!\w)' }
        $p
    }
    if ($pats) { $script:TradRx = New-Object Text.RegularExpressions.Regex (($pats -join '|')) }
    return $true
}
function Traducir([string]$t) {
    if ((-not $t) -or (-not $script:Trad)) { return $t }
    $v = $null
    if ($script:Trad.TryGetValue($t, [ref]$v)) { return $v }
    if ($script:TradCache.TryGetValue($t, [ref]$v)) { return $v }
    $r = $t
    if ($script:TradRx) { $r = $script:TradRx.Replace($t, [Text.RegularExpressions.MatchEvaluator] { param($m) $script:Trad[$m.Value] }) }
    $script:TradCache[$t] = $r
    return $r
}
if (-not (Cargar-Idioma $script:Idioma)) { $script:Idioma = 'es-mx'; Cargar-Idioma 'es-mx' | Out-Null }

# Los .bat y este archivo van sin acentos (para que cmd y PowerShell no los rompan segun la PC);
# al mostrar el texto en la app se ponen las palabras con enie. La enie se arma con [char] para que el archivo siga en ASCII.
$Enie = [string][char]0xF1
$ConEnie = @(
    @('\bcontrasenas\b', ('contrase' + $Enie + 'as')),
    @('\bcontrasena\b', ('contrase' + $Enie + 'a')),
    @('\bContrasena\b', ('Contrase' + $Enie + 'a')),
    @('\bpestana\b', ('pesta' + $Enie + 'a')),
    @('\banos\b', ('a' + $Enie + 'os')),
    @('\btamano\b', ('tama' + $Enie + 'o'))
)
function Con-Enie([string]$t) {
    if (-not $t) { return $t }
    if ($script:Trad) { $t = Traducir $t }
    if ($script:Idioma -ne 'es-mx') { return $t }
    foreach ($par in $ConEnie) { $t = [regex]::Replace($t, $par[0], $par[1]) }
    return $t
}

$faltan = @($Rutas.Values | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($faltan.Count -gt 0) {
    Mostrar-Error ("Faltan estos archivos:`n`n" + ($faltan -join "`n") + "`n`nLos tres .bat van en la carpeta 'scripts', al lado de XucaOP.ps1.")
    exit
}

# Los .bat necesitan saltos de linea de Windows (CRLF). Si vienen con los de Linux (LF),
# cmd salta a etiquetas equivocadas: preguntas repetidas, "Fin" varias veces y PowerShell sin datos.
$latin = [Text.Encoding]::GetEncoding(28591)
foreach ($r in $Rutas.Values) {
    try {
        $txt = $latin.GetString([IO.File]::ReadAllBytes($r))
        if ($txt -match '(^|[^\r])\n') { [IO.File]::WriteAllText($r, ($txt -replace '\r?\n', "`r`n"), $latin) }
    } catch { }
}

# Opciones que te piden datos en la consola: van en la pagina Herramientas, no como casillas.
$SoloScript = @('ver', 'ms_acc', 'al', 'cta', 'drv', 'rp')

# "- Desea mouse competitivo? (Sin aceleracion...)" -> "Mouse competitivo"
function Titulo-Corto([string]$q) {
    $t = (($q -replace '^\s*-\s*Desea\s+', '' -replace '\s*\(.*$', '') -replace '\?\s*$', '').Trim()
    if ($t.Length -gt 0) { $t = $t.Substring(0, 1).ToUpper() + $t.Substring(1) }
    return $t
}

# ------------------------------------------------------------
# Leer las opciones de un .bat
# ------------------------------------------------------------
function Leer-Opciones([string]$ruta) {
    $items = New-Object System.Collections.Generic.List[object]
    $sec = 'General'
    $h = ''; $a = ''; $c = ''; $qid = $null
    $lineas = [IO.File]::ReadAllLines($ruta)
    for ($i = 0; $i -lt $lineas.Count; $i++) {
        $l = $lineas[$i]
        if ($l.StartsWith('::')) { continue }
        if ($l -match '^echo %C_TIT%=== (.+) ===%C_RST%$') { $sec = $Matches[1]; continue }
        if ($l -match '^echo   Que hace: (.*)$') { $h = ($Matches[1] -replace '\^', ''); continue }
        if ($l -match '^echo   A favor: (.*)$') { $a = ($Matches[1] -replace '\^', ''); continue }
        if ($l -match '^echo   En contra: (.*)$') { $c = ($Matches[1] -replace '\^', ''); continue }
        if ($l -match '^set "QID=(\w+)"$') { $qid = $Matches[1]; continue }
        if ($l -match '^set "Q=(- Desea .+)"$') {
            $q = $Matches[1]
            $conR = ($i + 1 -lt $lineas.Count) -and ($lineas[$i + 1] -match 'call :askR')
            if ($qid -and ($SoloScript -notcontains $qid)) {
                $items.Add([pscustomobject]@{ Id = $qid; Titulo = (Titulo-Corto $q); Hace = $h; Favor = $a; Contra = $c; ConR = $conR; Seccion = $sec })
            }
            $h = ''; $a = ''; $c = ''; $qid = $null
        }
    }
    return , $items
}

$Opciones = @{
    Debloat = Leer-Opciones $Rutas.Debloat
    Gaming  = Leer-Opciones $Rutas.Gaming
}

# ------------------------------------------------------------
# Funciones para leer Windows. Se usan aca y en la lectura de fondo (otro hilo),
# por eso van como texto: el hilo de fondo las vuelve a crear.
# ------------------------------------------------------------
$FuncLectura = @'
function Leer-Reg([string]$path, [string]$name) {
    try { return (Get-ItemProperty -LiteralPath $path -Name $name -ErrorAction Stop).$name } catch { return $null }
}
function Leer-Svc([string]$svc) { return (Leer-Reg ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $svc) 'Start') }
function HasAppx([string]$n) { return ($global:XAppx -contains $n) }
function Prio-Actuales {
    $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
    return @(Get-ChildItem -LiteralPath $ifeo -ErrorAction SilentlyContinue |
        Where-Object { (Leer-Reg ($_.PSPath + '\PerfOptions') 'XucaPrioridad') -eq 1 } |
        ForEach-Object { $_.PSChildName -replace '(?i)\.exe$', '' })
}
# Ahorro de energia de la placa de red. Se busca cada opcion por nombre exacto: con -RegistryKeyword '*EEE'
# Windows toma el * como comodin, junta varias opciones y la comparacion nunca daba "Ya aplicado".
function Leer-Nic {
    if ($global:XNicLeido) { return $global:XNic }
    $claves = '*EEE', 'EEE', 'AdvancedEEE', 'GreenEthernet', 'EnableGreenEthernet', 'PowerSavingMode'
    $r = @{ Placas = 0; Vals = @() }
    foreach ($ad in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })) {
        $r.Placas++
        foreach ($p in @($ad | Get-NetAdapterAdvancedProperty -AllProperties -ErrorAction SilentlyContinue)) {
            if ($claves -contains ([string]$p.RegistryKeyword)) { $r.Vals += [string](@($p.RegistryValue)[0]) }
        }
    }
    $global:XNic = $r; $global:XNicLeido = $true
    return $r
}
'@
. ([scriptblock]::Create($FuncLectura))

# ------------------------------------------------------------
# Lista de juegos y de programas de fondo (compartida por "Prioridad alta" y "Afinidad")
# ------------------------------------------------------------
# Los catalogos se leen del .bat de gaming para no tenerlos repetidos
$AfiJuegosCat = ''; $AfiFondoCat = ''; $FuncCpu = ''; $FuncJuegos = ''
try {
    $tg = [IO.File]::ReadAllText($Rutas.Gaming)
    $AfiJuegosCat = [regex]::Match($tg, "(?m)^\`$afiJuegosCat = '([^']*)'").Groups[1].Value
    $AfiFondoCat = [regex]::Match($tg, "(?m)^\`$afiFondoCat = '([^']*)'").Groups[1].Value
    # Funciones que leen el procesador y dicen cuanto cambia la afinidad y si hace falta la Game Bar
    $FuncCpu = [regex]::Match($tg, '(?s)# >>> XUCA-CPU.*?# <<< XUCA-CPU').Value
    # Funciones que detectan los juegos instalados (Steam, Epic, EA, Battle.net, Ubisoft, Riot, Xbox, GOG, Rockstar, Minecraft)
    $FuncJuegos = [regex]::Match($tg, '(?s)# >>> XUCA-JUEGOS.*?# <<< XUCA-JUEGOS').Value
} catch { }
# Funciones que dicen que apps de inicio son basura (las usa el chequeo de "Apps basura de inicio" en la lectura de fondo)
try {
    $FuncInicio = [regex]::Match([IO.File]::ReadAllText($Rutas.Debloat), '(?s)# >>> XUCA-INICIO.*?# <<< XUCA-INICIO').Value
    if ($FuncInicio) { $FuncLectura += ("`n" + $FuncInicio) }
} catch { }
# Las funciones de juegos tambien se cargan aca, para poner el nombre a los que agregas a mano
try { if ($FuncJuegos) { . ([scriptblock]::Create($FuncJuegos)) } } catch { }
if (-not (Get-Command Juego-Nombre -ErrorAction SilentlyContinue)) { function Juego-Nombre([string]$proc) { return $null } }

$XucaDir = Join-Path $env:ProgramData 'XucaScripts'
$ListasArchivo = Join-Path $XucaDir 'listas_app.txt'
$script:JuegosDet = @()     # juegos instalados que se detectaron (los carga la lectura de fondo)
$script:JuegosNuevos = 0    # cuantos juegos nuevos se sumaron solos a tu lista

# Lista de juegos para elegir: los instalados que se detectaron, con su plataforma (ya no hay lista fija)
function Cat-Juegos {
    $s = @($script:JuegosDet | ForEach-Object { [string]$_.Proc + '=' + [string]$_.Nombre + ' (' + [string]$_.Plat + ')' })
    if ($AfiJuegosCat) { $s = @($AfiJuegosCat) + $s }
    return ($s -join '; ')
}

# Lo que dejo guardado la afinidad (juegos, programas de fondo y nucleos elegidos)
function Afi-Config {
    $c = @{}
    $f = Join-Path $XucaDir 'afinidad.txt'
    if (-not (Test-Path -LiteralPath $f)) { return $c }
    foreach ($l in @(Get-Content -LiteralPath $f -ErrorAction SilentlyContinue)) { $i = $l.IndexOf('='); if ($i -gt 0) { $c[$l.Substring(0, $i)] = $l.Substring($i + 1) } }
    return $c
}

# "Juego.EXE", ' "cs2" ' -> "juego", "cs2"
function Normalizar-Procesos([string]$txt) {
    return @(($txt -split ',') | ForEach-Object { ($_.Trim().Trim('"').Trim() -replace '(?i)\.exe$', '').ToLower() } |
        Where-Object { $_ -and ($_ -match '^[^\\/:*?"<>|=;,\[\]]{1,100}$') -and ($_ -notmatch '^[. ]+$') } | Select-Object -Unique)
}

# Juegos instalados que ya se vieron alguna vez (los nuevos se suman solos a tu lista)
function Leer-Vistos {
    $v = @()
    if (Test-Path -LiteralPath $ListasArchivo) {
        foreach ($l in @(Get-Content -LiteralPath $ListasArchivo -ErrorAction SilentlyContinue)) { if ($l.StartsWith('detectados=')) { $v = @(Normalizar-Procesos $l.Substring(11)) } }
    }
    return , $v
}

# Devuelve @{ juegos = <lista o $null>; fondo = <lista o $null> }. $null = nunca se eligio (van todos los del catalogo).
function Leer-Listas {
    $r = @{ juegos = $null; fondo = $null }
    if (Test-Path -LiteralPath $ListasArchivo) {
        foreach ($l in @(Get-Content -LiteralPath $ListasArchivo -ErrorAction SilentlyContinue)) {
            $i = $l.IndexOf('='); if ($i -lt 1) { continue }
            $k = $l.Substring(0, $i)
            if ($k -in 'juegos', 'fondo') { $r[$k] = @(Normalizar-Procesos $l.Substring($i + 1)) }
        }
    }
    # Si todavia no hay lista guardada, se arma con lo que ya tenias puesto con los scripts
    $c = Afi-Config
    if ($null -eq $r.juegos) {
        $v = @()
        if ($c.ContainsKey('apps')) { $v += Normalizar-Procesos (([string]$c['juegos']) + ',' + ([string]$c['livianos'])) }
        $v += Normalizar-Procesos ((Prio-Actuales) -join ',')
        $v = @($v | Where-Object { $_ } | Select-Object -Unique)
        if ($v.Count -gt 0) { $r.juegos = $v }
    }
    if (($null -eq $r.fondo) -and $c.ContainsKey('apps')) { $r.fondo = @(Normalizar-Procesos ([string]$c['apps'])) }
    # Juegos que se instalaron desde la ultima vez: se suman solos a tu lista.
    # Los que ya se vieron y desmarcaste no vuelven a marcarse.
    $vistos = Leer-Vistos
    $nuevos = @($script:JuegosDet | ForEach-Object { [string]$_.Proc } | Where-Object { $_ -and ($vistos -notcontains $_) })
    if ($nuevos.Count -gt 0) {
        if ($null -ne $r.juegos) {
            $suma = @($nuevos | Where-Object { $r.juegos -notcontains $_ })
            if ($suma.Count -gt 0) { $r.juegos = @(@($r.juegos) + $suma); $script:JuegosNuevos += $suma.Count }
        }
        try { Guardar-Listas $r.juegos $r.fondo (@($vistos) + $nuevos) } catch { }
    }
    return $r
}

# $vistos = juegos instalados ya vistos ($null = deja los que habia)
function Guardar-Listas($juegos, $fondo, $vistos) {
    if ($null -eq $vistos) { $vistos = Leer-Vistos }
    if (-not (Test-Path -LiteralPath $XucaDir)) { New-Item -ItemType Directory -Path $XucaDir -Force | Out-Null }
    $l = @()
    if ($null -ne $juegos) { $l += ('juegos=' + (@($juegos) -join ',')) }
    if ($null -ne $fondo) { $l += ('fondo=' + (@($fondo) -join ',')) }
    if (@($vistos).Count -gt 0) { $l += ('detectados=' + (@($vistos | Select-Object -Unique) -join ',')) }
    Set-Content -LiteralPath $ListasArchivo -Value $l -Encoding ASCII
}

# Arma los items para elegir: el catalogo y, al final, los que agregaste vos.
function Items-De([string]$cat, $actual) {
    $items = @()
    foreach ($e in ($cat -split ';')) {
        $i = $e.IndexOf('='); if ($i -lt 1) { continue }
        $pr = @($e.Substring(0, $i) -split '\|' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
        $items += [pscustomobject]@{ Procs = $pr; Nombre = $e.Substring($i + 1).Trim(); Marcado = $true }
    }
    if ($null -ne $actual) {
        foreach ($it in $items) { $it.Marcado = (@($it.Procs | Where-Object { $actual -contains $_ }).Count -gt 0) }
        $conocidos = @($items | ForEach-Object { $_.Procs })
        foreach ($pr in $actual) {
            if ($conocidos -notcontains $pr) {
                $nm = Juego-Nombre $pr; if (-not $nm) { $nm = $pr }
                $items += [pscustomobject]@{ Procs = @($pr); Nombre = $nm; Marcado = $true }
            }
        }
    }
    return , $items
}

# Procesos que se usan de verdad (si nunca elegiste, todo el catalogo)
function Procesos-De([string]$cat, $actual) {
    $its = Items-De $cat $actual
    return @($its | Where-Object { $_.Marcado } | ForEach-Object { $_.Procs } | Select-Object -Unique)
}

function Resumen-De([string]$cat, $actual, [string]$etiqueta) {
    $its = Items-De $cat $actual
    $n = @($its | Where-Object { $_.Marcado } | ForEach-Object { $_.Nombre })
    if ($n.Count -eq 0) { return ($etiqueta + ': ninguno elegido.') }
    $t = ($n | Select-Object -First 4) -join ', '
    if ($n.Count -gt 4) { $t += (' ' + (Con-Enie 'y') + ' ' + ($n.Count - 4) + ' ' + (Con-Enie 'mas')) }
    return ($etiqueta + ' (' + $n.Count + '): ' + $t)
}

# ------------------------------------------------------------
# Chequeos para marcar "Ya aplicado". Cada uno devuelve $true (aplicado), $false (sin aplicar) o $null (no se sabe).
# Corren en el hilo de fondo: $global:XAppx (apps instaladas) y $global:XPlan (plan de energia) los carga ese hilo.
# ------------------------------------------------------------
$Chequeos = @{
    'Debloat|rpo'   = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' 'DisableSR') -eq 1 }
    'Debloat|av'    = {
        $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
        if ((-not $svc) -or ($svc.Status -ne 'Running')) { return $true }
        ((Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled -eq $false) -and ((Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen') -eq 0)
    }
    'Debloat|bl'    = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption') -eq 1 }
    'Debloat|hib'   = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled') -eq 0 }
    'Debloat|rc'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis') -eq 1 }
    'Debloat|sch'   = { ((Leer-Reg 'HKCU:\AppEvents\Schemes' '(default)') -eq '.None') -and ((Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' 'DisableStartupSound') -eq 1) }
    'Debloat|fx'    = { ((Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting') -eq 3) -and ((Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency') -eq 0) }
    'Debloat|cal'   = { (Leer-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter') -eq 1 }
    'Debloat|et'    = { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask') -eq 1 }
    'Debloat|apps'  = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground') -eq 2 }
    'Debloat|ini'   = { if (Get-Command Inicio-Basura -ErrorAction SilentlyContinue) { @(Inicio-Basura).Count -eq 0 } else { $null } }
    'Debloat|tel'   = { (Leer-Svc 'DiagTrack') -eq 4 }
    'Debloat|wg'    = { if ([Environment]::OSVersion.Version.Build -lt 22000) { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds') -eq 0 } else { -not (HasAppx 'MicrosoftWindows.Client.WebExperience') } }
    'Debloat|do'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode') -eq 0 }
    'Debloat|wud'   = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate') -eq 1 }
    'Debloat|wup'   = { (Leer-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'FlightSettingsMaxPauseDays') -eq 7300 }
    'Debloat|ad'    = { ((Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled') -eq 0) -and ((Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch') -eq 1) }
    'Debloat|sv'    = { ((Leer-Svc 'MapsBroker') -eq 4) -and ((Leer-Svc 'WerSvc') -eq 4) }
    'Debloat|pv'    = { ((Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed') -eq 0) -and ((Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation') -eq 1) }
    'Debloat|ter'   = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition' 'Teredo_State') -eq 'Disabled' }
    'Debloat|tp'    = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' 'POWERSHELL_TELEMETRY_OPTOUT') -eq '1' }
    'Debloat|hst'   = { [bool](Select-String -LiteralPath (Join-Path $env:SystemRoot 'System32\drivers\etc\hosts') -SimpleMatch -Pattern '# xuca-telemetria' -Quiet) }
    'Debloat|eb'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled') -eq 0 }
    'Debloat|su'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload') -eq 2 }
    'Debloat|ia'    = { ((Leer-Reg 'HKLM:\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures') -eq 1) -and ((Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableClickToDo') -eq 1) }
    'Debloat|db'    = { (-not (HasAppx 'Microsoft.BingNews')) -and (-not (HasAppx 'Microsoft.Copilot')) -and (-not (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\OneDrive.exe'))) }
    'Debloat|edge'  = { -not (Test-Path -LiteralPath (${env:ProgramFiles(x86)} + '\Microsoft\Edge\Application\msedge.exe')) }
    'Debloat|chr'   = { @(@(($env:ProgramFiles + '\Google\Chrome\Application\chrome.exe'), (${env:ProgramFiles(x86)} + '\Google\Chrome\Application\chrome.exe'), ($env:LOCALAPPDATA + '\Google\Chrome\Application\chrome.exe')) | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0 }
    'Gaming|ms'     = { ((Leer-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed') -eq '0') -and ((Leer-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1') -eq '0') }
    'Gaming|tk'     = { (Leer-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags') -eq '506' }
    'Gaming|du'     = { (Leer-Reg 'HKCU:\Software\Microsoft\Multimedia\Audio' 'UserDuckingPreference') -eq 3 }
    'Gaming|mm'     = { ((Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category') -eq 'High') -and ((Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness') -eq 10) }
    'Gaming|pri'    = { (Prio-Actuales).Count -gt 0 }
    'Gaming|afi'    = { [bool](Get-ScheduledTask -TaskName 'XucaAfinidad' -ErrorAction SilentlyContinue) }
    'Gaming|pw'     = { $global:XPlan -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
    'Gaming|cpu'    = { if (-not $global:XPlan) { return $null }; Test-Path -LiteralPath (Join-Path $env:ProgramData ('XucaScripts\cpu_' + $global:XPlan + '.txt')) }
    'Gaming|ll'     = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1213986446' 'EnabledState') -eq 2 }
    'Gaming|gm'     = { ((Leer-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled') -eq 1) -and ((Leer-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled') -eq 0) }
    'Gaming|xb'     = { if ($global:XCpuClase -eq 'x3d') { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled') -eq 0 } else { -not (HasAppx 'Microsoft.XboxGamingOverlay') } }
    'Gaming|xm'     = { $v = Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration' 'GamingHomeApp'; ($null -ne $v) -and ([string]$v -eq '') }
    'Gaming|wf'     = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' 'fMinimizeConnections') -eq 0 }
    'Gaming|notif'  = { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled') -eq 0 }
    'Gaming|gf'     = { ((Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode') -eq 2) -and (([Environment]::OSVersion.Version.Build -lt 22000) -or (([string](Leer-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings')) -like '*SwapEffectUpgradeEnable=1*')) }
    'Gaming|mpo'    = { (Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode') -eq 5 }
    'Gaming|msi'    = {
        $gpus = @(Get-PnpDevice -PresentOnly -Class Display -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'PCI\*' })
        if ($gpus.Count -eq 0) { return $null }
        @($gpus | Where-Object { (Leer-Reg ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties') 'MSISupported') -ne 1 }).Count -eq 0
    }
    'Gaming|pca'    = { (Leer-Svc 'PcaSvc') -eq 4 }
    'Gaming|tr'     = { ([bool](Get-ScheduledTask -TaskName 'XucaTimer' -ErrorAction SilentlyContinue)) -and ((Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests') -eq 1) }
    'Gaming|ram'    = { [bool](Get-ScheduledTask -TaskName 'XucaRAM' -ErrorAction SilentlyContinue) }
    'Gaming|sm'     = { (Leer-Svc 'SysMain') -eq 4 }
    'Gaming|pe'     = { if (-not $global:XPlan) { return $null }; (Leer-Reg ('HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $global:XPlan + '\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226') 'ACSettingIndex') -eq 0 }
    'Gaming|nic'    = {
        $n = Leer-Nic
        if (@($n.Vals).Count -eq 0) { return $null }
        @($n.Vals | Where-Object { $_ -ne '0' }).Count -eq 0
    }
    'Gaming|nag'    = {
        $vals = @()
        foreach ($k in @(Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue)) {
            $pp = Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue
            $ips = @(@($pp.DhcpIPAddress) + @($pp.IPAddress) | Where-Object { ([string]$_) -match '^\d+\.\d+\.\d+\.\d+$' -and ([string]$_) -ne '0.0.0.0' })
            if ($ips.Count -gt 0) { $vals += (($pp.TcpAckFrequency -eq 1) -and ($pp.TCPNoDelay -eq 1)) }
        }
        if ($vals.Count -eq 0) { return $null }
        @($vals | Where-Object { -not $_ }).Count -eq 0
    }
    'Gaming|dns'    = { @(Get-ChildItem -LiteralPath (Join-Path $env:ProgramData 'XucaScripts') -Filter 'dns_*.txt' -ErrorAction SilentlyContinue).Count -gt 0 }
    'Gaming|mi'     = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled') -eq 0 }
    'Gaming|avl'    = { (Get-MpPreference -ErrorAction Stop).ScanAvgCPULoadFactor -eq 5 }
    'Gaming|vbs'    = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity') -eq 0 }
    'Gaming|wsr'    = { (Leer-Svc 'WSearch') -eq 4 }
    'Gaming|stg'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense' 'AllowStorageSenseGlobal') -eq 0 }
    'Gaming|ext'    = { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt') -eq 0 }
    'Gaming|md'     = { (Leer-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay') -eq '0' }
    'Gaming|v4'     = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' 'DisabledComponents') -eq 32 }
}

# Lo que corre en el hilo de fondo: carga las apps y el plan de energia, y despues hace cada chequeo
# avisando por $Sync cuantos lleva, asi la barra avanza mientras la ventana sigue fluida.
$CodigoLectura = @'
param($Funcs, $Lista, $Sync)
$ErrorActionPreference = 'Stop'
. ([scriptblock]::Create($Funcs))
$res = @{}
try {
    $Sync.Paso = 'Apps instaladas'
    $global:XAppx = @()
    try { $global:XAppx = @(Get-AppxPackage -AllUsers -ErrorAction Stop | ForEach-Object { $_.Name }) } catch { }
    $Sync.Hecho = 1
    $Sync.Paso = 'Plan de energia'
    $global:XPlan = ''
    try { $global:XPlan = ([regex]::Match((& powercfg.exe /getactivescheme | Out-String), '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value).ToLower() } catch { }
    $Sync.Hecho = 2
    $Sync.Paso = 'Tu procesador'
    $global:XCpuClase = ''
    if ($Sync.FuncCpu) {
        try {
            function Log($a, $b) { }
            . ([scriptblock]::Create($Sync.FuncCpu))
            $pl = Afi-Plan
            $global:XCpuClase = [string]$pl.Clase
            $Sync.Cpu = @{ Nombre = $pl.Cpu; Ok = [bool]$pl.Ok; Motivo = [string]$pl.Motivo; Afi = (Afi-Consejo $pl); Gb = (Gb-Consejo $pl) }
        } catch { }
    }
    foreach ($e in $Lista) {
        $Sync.Paso = $e.Titulo
        $est = $null
        try { $r = & ([scriptblock]::Create($e.Codigo)); if ($null -ne $r) { $est = [bool](@($r)[-1]) } } catch { $est = $null }
        $res[$e.Clave] = $est
        $Sync.Hecho = $Sync.Hecho + 1
    }
    $Sync.Paso = 'Juegos instalados'
    if ($Sync.FuncJuegos) {
        try { . ([scriptblock]::Create($Sync.FuncJuegos)); $Sync.Juegos = @(Juegos-Detectados) } catch { }
    }
    $Sync.Hecho = $Sync.Hecho + 1
    $Sync.Paso = 'Compatibilidad con tu Windows'
    $i = @{ Build = 0; Ubr = 0; Display = ''; Edicion = ''; RamGB = 0; Hdd = $false; Recall = $false; BitLocker = $false; Winget = $false; AvOff = $false }
    try { $i.Build = [int](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'CurrentBuildNumber') } catch { }
    try { $i.Ubr = [int](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'UBR') } catch { }
    $i.Display = [string](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'DisplayVersion')
    $i.Edicion = [string](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'EditionID')
    try { $i.RamGB = [int][math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB) } catch { }
    try {
        $dk = Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1) -ErrorAction Stop | Get-Disk -ErrorAction Stop | Get-PhysicalDisk -ErrorAction Stop
        $i.Hdd = ([string]$dk.MediaType -eq 'HDD')
    } catch { }
    if ($i.Build -ge 26100) { try { $i.Recall = [bool](Get-WindowsOptionalFeature -Online -FeatureName Recall -ErrorAction Stop) } catch { } }
    $i.BitLocker = [bool](Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)
    $i.Winget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    # Placas de red fisicas: 9 = WiFi, 14 = cable (para "WiFi y cable a la vez")
    # Las placas apagadas en el Administrador de dispositivos no cuentan. WifiSinRed = la placa WiFi no ve ninguna red (sin antena, por ejemplo)
    $i.Wifi = 0; $i.Lan = 0; $i.WifiSinRed = $false
    try {
        $fis = @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { [string]$_.Status -ne 'Disabled' })
        $wfs = @($fis | Where-Object { $_.NdisPhysicalMedium -eq 9 })
        $i.Wifi = $wfs.Count
        $i.Lan = @($fis | Where-Object { $_.NdisPhysicalMedium -eq 14 }).Count
        if (($wfs.Count -gt 0) -and (@($wfs | Where-Object { [string]$_.Status -eq 'Up' }).Count -eq 0)) {
            $o = (& netsh.exe wlan show networks 2>$null | Out-String)
            $m = [regex]::Match($o, '(\d+)\s+(networks?|redes)')
            if ($m.Success -and ([int]$m.Groups[1].Value -eq 0)) { $i.WifiSinRed = $true }
        }
    } catch { }
    $i.NicPlacas = 0; $i.NicOpc = 0
    try { $nn = Leer-Nic; $i.NicPlacas = [int]$nn.Placas; $i.NicOpc = @($nn.Vals).Count } catch { }
    # Opciones que necesitan un driver que no tenes instalado (la app te manda a instalarlo antes de aplicarlas)
    $i.DrvFalta = @{}
    try {
        $gpu = @(Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { ([string]$_.PNPDeviceID) -like 'PCI\*' })
        if (@($gpu | Where-Object { (@('display.inf', 'basicdisplay.inf') -contains ([string]$_.InfFilename).ToLower()) -or ([int]$_.ConfigManagerErrorCode -ne 0) }).Count -gt 0) {
            $i.DrvFalta['Gaming|gf'] = 'tu placa de video usa el driver basico de Windows'
            $i.DrvFalta['Gaming|msi'] = 'tu placa de video usa el driver basico de Windows'
        }
    } catch { }
    try {
        $fis2 = @(Get-NetAdapter -Physical -ErrorAction Stop)
        if (@($fis2 | Where-Object { ($_.NdisPhysicalMedium -eq 14) -and ([string]$_.Status -ne 'Disabled') -and ([string]$_.DriverProvider -eq 'Microsoft') }).Count -gt 0) {
            $i.DrvFalta['Gaming|nic'] = 'tu placa de red usa el driver generico de Windows'
            if (-not $i.DrvFalta.ContainsKey('Gaming|msi')) { $i.DrvFalta['Gaming|msi'] = 'tu placa de red usa el driver generico de Windows' }
        }
        if ((-not $i.WifiSinRed) -and (@($fis2 | Where-Object { ($_.NdisPhysicalMedium -eq 9) -and ([string]$_.Status -ne 'Disabled') -and ([string]$_.DriverProvider -eq 'Microsoft') }).Count -gt 0)) {
            $i.DrvFalta['Gaming|wf'] = 'tu placa WiFi usa el driver generico de Windows'
        }
    } catch { }
    try {
        # Ryzen X3D de dos bloques: sin el driver de chipset de AMD falta el "3D V-Cache Performance Optimizer"
        $cpuN = [string](@(Get-CimInstance Win32_Processor -ErrorAction Stop)[0].Name)
        if ($cpuN -match '(7900|7950|9900|9950)X3D') {
            if (@(Get-CimInstance Win32_PnPEntity -Filter "Name LIKE '%3D V-Cache%'" -ErrorAction Stop).Count -eq 0) {
                $i.DrvFalta['Gaming|afi'] = 'falta el driver de chipset de AMD (3D V-Cache Performance Optimizer)'
            }
        }
    } catch { }
    try {
        $sv = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
        $i.AvOff = (-not $sv) -or ($sv.Status -ne 'Running') -or ((Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled -eq $false)
    } catch { }
    # Windows original o modificado (la misma revision que hacen los .bat al arrancar)
    $Sync.Paso = 'Si tu Windows es original'
    $mot = New-Object System.Collections.Generic.List[string]
    # Windows sin activar no cuenta como no original (es un Windows normal, solo falta la licencia)
    foreach ($sv in 'TrustedInstaller', 'wuauserv', 'WinDefend') {
        if (-not (Get-Service -Name $sv -ErrorAction SilentlyContinue)) { $mot.Add('falta el servicio ' + $sv + ', tipico de versiones recortadas') }
    }
    if (($global:XAppx.Count -gt 0) -and ($global:XAppx -notcontains 'Microsoft.WindowsStore')) { $mot.Add('no esta la Microsoft Store, tipico de versiones recortadas') }
    $editOk = 'Core', 'CoreSingleLanguage', 'Professional', 'ProfessionalN', 'ProfessionalWorkstation', 'ProfessionalEducation', 'Enterprise', 'EnterpriseN', 'Education', 'EducationN', 'ServerStandard', 'ServerDatacenter', 'CloudEdition'
    if ($i.Edicion -and ($editOk -notcontains $i.Edicion)) { $mot.Add('edicion de Windows poco comun: ' + $i.Edicion) }
    $txtCv = (([string](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'RegisteredOwner')) + ' ' + ([string](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'ProductName'))).ToLower()
    foreach ($pal in 'tiny', 'atlas', 'revi', 'ghost', 'lite', 'mini', 'kernel', 'custom') {
        if ($txtCv.Contains($pal)) { $mot.Add('el nombre de la edicion o el propietario registrado tiene palabras de versiones modificadas'); break }
    }
    $i.Orig = @($mot | Select-Object -Unique)
    $Sync.Info = $i
    $Sync.Hecho = $Sync.Hecho + 1
    $Sync.Paso = 'Ultimos detalles'
    try { $Sync.Prio = @(Prio-Actuales) } catch { $Sync.Prio = @() }
    try { $Sync.TareaAfi = [bool](Get-ScheduledTask -TaskName 'XucaAfinidad' -ErrorAction SilentlyContinue) } catch { $Sync.TareaAfi = $false }
} finally {
    $Sync.Resultados = $res
    $Sync.Listo = $true
}
'@

# ------------------------------------------------------------
# Ventana
# ------------------------------------------------------------
$XamlTexto = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Xuca OPtimizer" Width="1080" Height="740" MinWidth="420" MinHeight="320"
        WindowStartupLocation="CenterScreen" Background="#14161B" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Nav" TargetType="Button">
      <Setter Property="Foreground" Value="#C9CDD4"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Padding" Value="16,10"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Margin" Value="0,0,0,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid x:Name="g" RenderTransformOrigin="0.5,0.5">
              <Grid.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Grid.RenderTransform>
              <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="19"/>
              <!-- Brillo que aparece suave al pasar el mouse -->
              <Border x:Name="luz" Background="#14FFFFFF" CornerRadius="19" Opacity="0"/>
              <!-- Relleno blanco que se abre desde el centro al tocar (como en Android) -->
              <Border x:Name="onda" Background="White" CornerRadius="19" Opacity="0" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
                <Border.RenderTransform><ScaleTransform ScaleX="0.3" ScaleY="0.3"/></Border.RenderTransform>
              </Border>
              <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Left" VerticalAlignment="Center"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="luz" Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="luz" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.25"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.97" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.97" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" From="0" To="0.22" Duration="0:0:0.1"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.45"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Accion" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Background" Value="#2B313C"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="16,9"/>
      <Setter Property="Margin" Value="8,0,0,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <!-- Estilo Windows 11: esquinas de 6, borde fino claro arriba, sombra suave; se agranda la sombra al pasar el mouse y se achica un poco al tocar -->
            <Grid x:Name="g" RenderTransformOrigin="0.5,0.5">
              <Grid.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Grid.RenderTransform>
              <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="6">
                <Border.Effect><DropShadowEffect BlurRadius="8" ShadowDepth="2" Direction="270" Opacity="0.35" Color="#000000"/></Border.Effect>
              </Border>
              <Border CornerRadius="6" BorderThickness="1">
                <Border.BorderBrush>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#30FFFFFF" Offset="0"/>
                    <GradientStop Color="#0AFFFFFF" Offset="1"/>
                  </LinearGradientBrush>
                </Border.BorderBrush>
              </Border>
              <Border x:Name="luz" Background="White" CornerRadius="6" Opacity="0"/>
              <!-- Relleno blanco que se abre desde el centro al tocar (como en Android) -->
              <Border x:Name="onda" Background="White" CornerRadius="6" Opacity="0" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
                <Border.RenderTransform><ScaleTransform ScaleX="0.3" ScaleY="0.3"/></Border.RenderTransform>
              </Border>
              <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="luz" Storyboard.TargetProperty="Opacity" To="0.08" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="b" Storyboard.TargetProperty="(UIElement.Effect).(DropShadowEffect.BlurRadius)" To="16" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="b" Storyboard.TargetProperty="(UIElement.Effect).(DropShadowEffect.ShadowDepth)" To="4" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="luz" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.25"/>
                  <DoubleAnimation Storyboard.TargetName="b" Storyboard.TargetProperty="(UIElement.Effect).(DropShadowEffect.BlurRadius)" To="8" Duration="0:0:0.25"/>
                  <DoubleAnimation Storyboard.TargetName="b" Storyboard.TargetProperty="(UIElement.Effect).(DropShadowEffect.ShadowDepth)" To="2" Duration="0:0:0.25"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.95" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.95" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" From="0" To="0.22" Duration="0:0:0.1"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="0:0:0.18"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="0:0:0.18"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.45"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Cartel amarillo de actualizacion -->
    <Style x:Key="Amarillo" TargetType="Button">
      <Setter Property="Padding" Value="16,12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid x:Name="g" RenderTransformOrigin="0.5,0.5">
              <Grid.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Grid.RenderTransform>
              <Border x:Name="b" Background="#F2C94C" CornerRadius="10" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center"/>
              </Border>
              <!-- Relleno blanco que se abre desde el centro al tocar (como en Android) -->
              <Border x:Name="onda" Background="White" CornerRadius="10" Opacity="0" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
                <Border.RenderTransform><ScaleTransform ScaleX="0.3" ScaleY="0.3"/></Border.RenderTransform>
              </Border>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsPressed" Value="True">
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.97" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.97" Duration="0:0:0.08"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" From="0" To="0.22" Duration="0:0:0.1"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" From="0.3" To="1" Duration="0:0:0.3"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="g" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="onda" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.45"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#F7D96B"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <!-- Marco = lugar real de la ventana. Raiz = todo el contenido, que se achica con zoom si la ventana queda chica -->
  <Border x:Name="Marco">
  <Grid x:Name="Raiz">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="252"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <!-- Barra de la izquierda: panel flotante con bordes redondos -->
    <Border x:Name="Barra" Grid.Column="0" Background="#0E1014" BorderBrush="#1E232D" BorderThickness="1" CornerRadius="18" Margin="12,12,0,12" Padding="14,16">
      <Border.RenderTransform><TranslateTransform/></Border.RenderTransform>
      <Border.Effect><DropShadowEffect BlurRadius="20" ShadowDepth="0" Opacity="0.45" Color="#000000"/></Border.Effect>
      <DockPanel LastChildFill="False">
        <StackPanel DockPanel.Dock="Top">
          <!-- Recuadro del nombre, con el borde en celeste y magenta -->
          <Border CornerRadius="14" BorderThickness="1.5" Padding="14,12" Margin="0,0,0,18">
            <Border.BorderBrush>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#3D6FD9" Offset="0"/>
                <GradientStop Color="#F9A8D4" Offset="1"/>
              </LinearGradientBrush>
            </Border.BorderBrush>
            <Border.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#1A2238" Offset="0"/>
                <GradientStop Color="#231A2A" Offset="1"/>
              </LinearGradientBrush>
            </Border.Background>
            <StackPanel>
              <TextBlock Foreground="#FFFFFF" FontSize="20" FontWeight="SemiBold"><Run Text="Xuca "/><Run Text="OP" Foreground="#22D3EE" FontWeight="Bold"/><Run Text="timizer"/></TextBlock>
              <TextBlock Text="Optimizador para Windows" Foreground="#9AA6C4" FontSize="11.5" Margin="0,2,0,0"/>
            </StackPanel>
          </Border>
          <Button x:Name="NavPerfiles" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE77B;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Perfiles" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <Button x:Name="NavDebloat" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE72E;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Debloat y privacidad" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <Button x:Name="NavGaming" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE7FC;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Optimizacion gaming" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <Button x:Name="NavLimpieza" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Limpiar cache" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <Button x:Name="NavHerr" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE90F;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Herramientas" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <!-- Apps recomendadas en verde: programas gratis que se descargan de su pagina oficial -->
          <Button x:Name="NavApps" Style="{StaticResource Nav}" Foreground="#BEF264" FontWeight="SemiBold" Background="#182008" BorderBrush="#BEF264" BorderThickness="1" Margin="0,6,0,0">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE7B8;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Apps recomendadas" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <!-- Configs en naranja: configs de juegos y apps que se bajan de GitHub -->
          <Grid Margin="0,6,0,0">
            <Button x:Name="NavAdicional" Style="{StaticResource Nav}" Foreground="#F6AD55" FontWeight="SemiBold" Background="#221A0E" BorderBrush="#F6AD55" BorderThickness="1">
              <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Configs recomendadas" VerticalAlignment="Center"/></StackPanel>
            </Button>
            <!-- Circulito verde en la esquina con cuantas configs hay subidas (no aparece si no hay ninguna) -->
            <Border x:Name="CfgInsignia" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-7,-7,0,0" MinWidth="21" Height="21" CornerRadius="10.5" Padding="5,0"
                    Background="#22C55E" BorderBrush="#0E1014" BorderThickness="2" IsHitTestVisible="False" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <TextBlock x:Name="CfgInsigniaTxt" Text="0" Foreground="White" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
          </Grid>
        </StackPanel>
        <StackPanel DockPanel.Dock="Bottom">
          <Border Height="1" Background="#1E232D" Margin="6,0,6,12"/>
          <Button x:Name="BtnTema" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#xE706;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/>
              <TextBlock x:Name="TemaTxt" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="BtnIdioma" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/>
              <TextBlock x:Name="IdiomaTxt" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="BtnRefrescar" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE72C;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Volver a leer los ajustes" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <Button x:Name="BtnLogs" Style="{StaticResource Nav}">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Abrir carpeta de logs" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <!-- Redes en celeste clarito, con su borde -->
          <Button x:Name="BtnRedes" Style="{StaticResource Nav}" Foreground="#8FD3F4" FontWeight="SemiBold" Background="#14222B" BorderBrush="#8FD3F4" BorderThickness="1" Margin="0,4,0,0">
            <StackPanel Orientation="Horizontal"><TextBlock Text="&#xEB51;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,12,0"/><TextBlock Text="Visita mis redes sociales!" VerticalAlignment="Center"/></StackPanel>
          </Button>
          <TextBlock Text="Los scripts tambien se pueden usar solos, sin la app." Foreground="#5C6370" FontSize="11" TextWrapping="Wrap" Margin="6,10,0,0"/>
        </StackPanel>
      </DockPanel>
    </Border>

    <Grid x:Name="Contenido" Grid.Column="1" Margin="28,22,28,18">
      <Grid.RenderTransform><TranslateTransform/></Grid.RenderTransform>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <StackPanel Grid.Row="0" Margin="0,0,0,14">
        <Button x:Name="BtnUpdBarra" Style="{StaticResource Amarillo}" Padding="14,9" Margin="0,0,0,14" Visibility="Collapsed">
          <DockPanel>
            <TextBlock Text="&#x26A0;" DockPanel.Dock="Left" FontSize="18" Foreground="#3B2F00" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <TextBlock x:Name="UpdBarraTexto" Foreground="#1F1A08" FontSize="13" FontWeight="SemiBold" TextWrapping="Wrap" VerticalAlignment="Center"/>
          </DockPanel>
        </Button>
        <!-- Aviso de Windows no original o modificado (Tiny11, AtlasOS, ReviOS...) -->
        <Border x:Name="OrigBarra" Background="#3A1F1F" BorderBrush="#F28B82" BorderThickness="1" CornerRadius="10" Padding="14,10" Margin="0,0,0,14" Visibility="Collapsed">
          <DockPanel>
            <TextBlock Text="&#x26A0;" DockPanel.Dock="Left" FontSize="18" Foreground="#F28B82" VerticalAlignment="Top" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="Esta PC no parece tener un Windows original o estandar" Foreground="#F28B82" FontSize="13.5" FontWeight="SemiBold" TextWrapping="Wrap"/>
              <TextBlock x:Name="OrigTexto" Foreground="#E8C4C0" FontSize="12.5" TextWrapping="Wrap" Margin="0,3,0,0"/>
            </StackPanel>
          </DockPanel>
        </Border>
        <!-- Titulo de la pagina en un recuadro como el de la barra de la izquierda, con el icono de la categoria -->
        <Border x:Name="TituloCaja" CornerRadius="16" BorderThickness="1" Padding="16,12" RenderTransformOrigin="0.5,0.5">
          <Border.RenderTransform><TranslateTransform X="0" Y="0"/></Border.RenderTransform>
          <Border.Effect><DropShadowEffect BlurRadius="18" ShadowDepth="0" Opacity="0.4" Color="#000000"/></Border.Effect>
          <Border.BorderBrush>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
              <GradientStop Color="#3D6FD9" Offset="0"/>
              <GradientStop Color="#F9A8D4" Offset="1"/>
            </LinearGradientBrush>
          </Border.BorderBrush>
          <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
              <GradientStop Color="#1A2238" Offset="0"/>
              <GradientStop Color="#1C1A26" Offset="0.6"/>
              <GradientStop Color="#231A2A" Offset="1"/>
            </LinearGradientBrush>
          </Border.Background>
          <DockPanel>
            <Border DockPanel.Dock="Left" Width="44" Height="44" CornerRadius="12" Margin="0,0,14,0" VerticalAlignment="Center">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#3D6FD9" Offset="0"/>
                  <GradientStop Color="#C58AF9" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <TextBlock x:Name="TituloIcono" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <StackPanel VerticalAlignment="Center">
              <TextBlock x:Name="Titulo" Foreground="#FFFFFF" FontSize="22" FontWeight="SemiBold"/>
              <TextBlock x:Name="Descripcion" Foreground="#A9B0BD" FontSize="13" TextWrapping="Wrap" Margin="0,3,0,0"/>
            </StackPanel>
          </DockPanel>
        </Border>
      </StackPanel>
      <ScrollViewer x:Name="Scroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,8,0"/>
      <DockPanel Grid.Row="2" Margin="0,14,0,0">
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
          <Button x:Name="BtnSeguras" Style="{StaticResource Accion}" Background="#2E8B57" Content="Marcar solo seguras"/>
          <Button x:Name="BtnTodo" Style="{StaticResource Accion}" Content="Marcar todo"/>
          <Button x:Name="BtnNada" Style="{StaticResource Accion}" Content="Desmarcar todo"/>
          <Button x:Name="BtnRestablecer" Style="{StaticResource Accion}" Background="#7A3326" Content="Restablecer seleccionadas" Visibility="Collapsed"/>
          <Button x:Name="BtnAplicar" Style="{StaticResource Accion}" Background="#3D6FD9" Content="Aplicar seleccionadas" Visibility="Collapsed"/>
        </StackPanel>
        <TextBlock x:Name="Estado" Foreground="#9AA0A6" FontSize="12.5" VerticalAlignment="Center" TextWrapping="Wrap"/>
      </DockPanel>
    </Grid>

    <!-- Pantalla de carga: tapa todo mientras lee Windows o aplica cambios -->
    <Grid x:Name="Carga" Grid.ColumnSpan="2" Background="#14161B" Panel.ZIndex="10">
      <!-- Tarjeta con bordes redondos y borde celeste y magenta, como el recuadro del nombre -->
      <Border x:Name="CargaCaja" VerticalAlignment="Center" HorizontalAlignment="Center" CornerRadius="20" BorderThickness="1.5" Padding="32,28" RenderTransformOrigin="0.5,0.5" Opacity="0">
        <Border.RenderTransform><ScaleTransform ScaleX="0.6" ScaleY="0.6"/></Border.RenderTransform>
        <Border.BorderBrush>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#3D6FD9" Offset="0"/>
            <GradientStop Color="#F9A8D4" Offset="1"/>
          </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.Background>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#171D2C" Offset="0"/>
            <GradientStop Color="#1C1722" Offset="1"/>
          </LinearGradientBrush>
        </Border.Background>
        <Border.Effect><DropShadowEffect BlurRadius="40" ShadowDepth="0" Opacity="0.55" Color="#000000"/></Border.Effect>
      <StackPanel Width="440">
        <TextBlock x:Name="CargaMarca" Foreground="#FFFFFF" FontSize="30" FontWeight="SemiBold" HorizontalAlignment="Center"><Run Text="Xuca "/><Run Text="OP" Foreground="#22D3EE" FontWeight="Bold"/><Run Text="timizer"/></TextBlock>
        <TextBlock x:Name="CargaTitulo" Text="Leyendo como esta tu Windows" Foreground="#C3C8D0" FontSize="15" HorizontalAlignment="Center" Margin="0,10,0,0"/>
        <Grid x:Name="CargaZona" Margin="0,24,0,0" Height="8">
          <Border Background="#232833" CornerRadius="4"/>
          <Border x:Name="CargaBarra" HorizontalAlignment="Left" Width="0" CornerRadius="4">
            <Border.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                <GradientStop Color="#3D6FD9" Offset="0"/>
                <GradientStop Color="#F9A8D4" Offset="1"/>
              </LinearGradientBrush>
            </Border.Background>
          </Border>
        </Grid>
        <DockPanel x:Name="CargaInfo" Margin="0,10,0,0">
          <TextBlock x:Name="CargaPct" DockPanel.Dock="Right" Foreground="#9AA0A6" FontSize="12.5" Text="0%" Margin="12,0,0,0"/>
          <TextBlock x:Name="CargaDetalle" Foreground="#7D8590" FontSize="12.5" TextTrimming="CharacterEllipsis"/>
        </DockPanel>
        <!-- Prueba de DNS: cada DNS con su tiempo, mientras se aplica esa opcion -->
        <Border x:Name="CargaDns" Margin="0,18,0,0" Padding="16,12" CornerRadius="10" Background="#1C2027" Visibility="Collapsed">
          <StackPanel>
            <TextBlock x:Name="CargaDnsTitulo" Foreground="#C3C8D0" FontSize="13" FontWeight="SemiBold" Text="Probando los DNS desde tu conexion"/>
            <StackPanel x:Name="CargaDnsLista" Margin="0,6,0,0"/>
          </StackPanel>
        </Border>
        <!-- Aparece al abrir la app si hay una version nueva en GitHub -->
        <StackPanel x:Name="UpdCarga" Margin="0,24,0,0" Visibility="Collapsed">
          <Button x:Name="BtnUpd" Style="{StaticResource Amarillo}">
            <DockPanel>
              <TextBlock Text="&#x26A0;" DockPanel.Dock="Left" FontSize="28" Foreground="#3B2F00" VerticalAlignment="Center" Margin="0,0,14,0"/>
              <StackPanel VerticalAlignment="Center">
                <TextBlock x:Name="UpdTitulo" FontSize="15" FontWeight="SemiBold" Foreground="#1F1A08" TextWrapping="Wrap"/>
                <TextBlock x:Name="UpdTexto" FontSize="12.5" Foreground="#4A3F12" TextWrapping="Wrap" Margin="0,4,0,0"/>
              </StackPanel>
            </DockPanel>
          </Button>
          <Button x:Name="BtnUpdNo" Style="{StaticResource Nav}" HorizontalAlignment="Center" Margin="0,12,0,0" Foreground="#9AA0A6" FontSize="13" Content="No, seguir con esta version"/>
        </StackPanel>
      </StackPanel>
      </Border>
    </Grid>

    <!-- Numero de version arriba a la derecha: siempre a la vista, incluso sobre la pantalla de carga. En rojo si esta desactualizada. -->
    <TextBlock x:Name="VersionTxt" Grid.ColumnSpan="2" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,4,12,0"
               Panel.ZIndex="20" FontSize="12" FontWeight="SemiBold" Foreground="#5C6370" IsHitTestVisible="False"/>
  </Grid>
  </Border>
</Window>
'@
# Los textos fijos de la ventana tambien pasan por el idioma elegido
if ($script:Trad) {
    $XamlTexto = [regex]::Replace($XamlTexto, '(?<=\s(?:Text|Content)=")[^"&]*[A-Za-z][^"&]*(?=")', [Text.RegularExpressions.MatchEvaluator] { param($m) [Security.SecurityElement]::Escape((Traducir $m.Value)) })
}
$XamlTexto = Tema-Texto $XamlTexto
[xml]$xaml = $XamlTexto

# Identidad propia para la barra de tareas: sin esto Windows junta la ventana con PowerShell y muestra su icono.
# Tiene que ir antes de crear la ventana.
try {
    Add-Type -Namespace XucaWin -Name Barra -MemberDefinition '[DllImport("shell32.dll", CharSet = CharSet.Unicode)] public static extern int SetCurrentProcessExplicitAppUserModelID(string id);'
    [void][XucaWin.Barra]::SetCurrentProcessExplicitAppUserModelID('011Xuca.XucaOPtimizer')
} catch { }

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

# Estilos para todas las ventanas (la principal y los carteles): casillas con tilde moderno y barra de desplazamiento fina
$EstilosXaml = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <Style TargetType="CheckBox">
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Grid Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Grid x:Name="caja" Width="18" Height="18" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" RenderTransformOrigin="0.5,0.5">
              <Grid.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Grid.RenderTransform>
              <Border x:Name="fondo" CornerRadius="5" Background="#14161B" BorderBrush="#5C6370" BorderThickness="1.5"/>
              <Border x:Name="lleno" CornerRadius="5" Opacity="0">
                <Border.Background>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#4F86F0" Offset="0"/>
                    <GradientStop Color="#3D6FD9" Offset="1"/>
                  </LinearGradientBrush>
                </Border.Background>
              </Border>
              <!-- El tilde se "dibuja" solo cuando marcas -->
              <Path x:Name="tilde" Data="M 4.5,9.3 L 7.6,12.4 L 13.5,5.9" Stroke="White" StrokeThickness="2"
                    StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                    StrokeDashArray="7 9" StrokeDashOffset="8" Opacity="0"/>
            </Grid>
            <ContentPresenter Grid.Column="1" Margin="8,0,0,0" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" RecognizesAccessKey="False"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="lleno" Property="Opacity" Value="1"/>
              <Setter TargetName="tilde" Property="StrokeDashOffset" Value="0"/>
              <Setter TargetName="tilde" Property="Opacity" Value="1"/>
              <Trigger.EnterActions><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="lleno" Storyboard.TargetProperty="Opacity" From="0" To="1" Duration="0:0:0.15"/>
                <DoubleAnimation Storyboard.TargetName="tilde" Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0"/>
                <DoubleAnimation Storyboard.TargetName="tilde" Storyboard.TargetProperty="StrokeDashOffset" From="8" To="0" BeginTime="0:0:0.05" Duration="0:0:0.22"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                <DoubleAnimation Storyboard.TargetName="caja" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" From="0.8" To="1" Duration="0:0:0.25"><DoubleAnimation.EasingFunction><BackEase EasingMode="EaseOut" Amplitude="0.5"/></DoubleAnimation.EasingFunction></DoubleAnimation>
                <DoubleAnimation Storyboard.TargetName="caja" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" From="0.8" To="1" Duration="0:0:0.25"><DoubleAnimation.EasingFunction><BackEase EasingMode="EaseOut" Amplitude="0.5"/></DoubleAnimation.EasingFunction></DoubleAnimation>
              </Storyboard></BeginStoryboard></Trigger.EnterActions>
              <Trigger.ExitActions><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="lleno" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.15"/>
                <DoubleAnimation Storyboard.TargetName="tilde" Storyboard.TargetProperty="StrokeDashOffset" To="8" Duration="0:0:0.1"/>
                <DoubleAnimation Storyboard.TargetName="tilde" Storyboard.TargetProperty="Opacity" To="0" BeginTime="0:0:0.1" Duration="0:0:0"/>
              </Storyboard></BeginStoryboard></Trigger.ExitActions>
            </Trigger>
            <Trigger Property="IsMouseOver" Value="True">
              <Setter TargetName="fondo" Property="BorderBrush" Value="#8FD3F4"/>
            </Trigger>
            <Trigger Property="IsPressed" Value="True">
              <Setter TargetName="fondo" Property="Background" Value="#232833"/>
            </Trigger>
            <Trigger Property="IsEnabled" Value="False">
              <Setter Property="Opacity" Value="0.45"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style x:Key="BarraVacia" TargetType="RepeatButton">
    <Setter Property="Focusable" Value="False"/>
    <Setter Property="IsTabStop" Value="False"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="RepeatButton"><Border Background="Transparent"/></ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="BarraThumb" TargetType="Thumb">
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Thumb">
          <Border x:Name="t" Background="#3A414E" CornerRadius="3" Width="6" HorizontalAlignment="Center"/>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
              <Setter TargetName="t" Property="Background" Value="#5C6370"/>
              <Setter TargetName="t" Property="Width" Value="8"/>
              <Setter TargetName="t" Property="CornerRadius" Value="4"/>
            </Trigger>
            <Trigger Property="IsDragging" Value="True">
              <Setter TargetName="t" Property="Background" Value="#8FD3F4"/>
              <Setter TargetName="t" Property="Width" Value="8"/>
              <Setter TargetName="t" Property="CornerRadius" Value="4"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <!-- Barra de desplazamiento vertical: fina, redondeada y oscura (sin flechas) -->
  <Style TargetType="ScrollBar">
    <Style.Triggers>
      <Trigger Property="Orientation" Value="Vertical">
        <Setter Property="Width" Value="10"/>
        <Setter Property="MinWidth" Value="10"/>
        <Setter Property="Template">
          <Setter.Value>
            <ControlTemplate TargetType="ScrollBar">
              <Grid Background="Transparent">
                <Track x:Name="PART_Track" IsDirectionReversed="True">
                  <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Style="{StaticResource BarraVacia}"/></Track.DecreaseRepeatButton>
                  <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Style="{StaticResource BarraVacia}"/></Track.IncreaseRepeatButton>
                  <Track.Thumb><Thumb Style="{StaticResource BarraThumb}"/></Track.Thumb>
                </Track>
              </Grid>
            </ControlTemplate>
          </Setter.Value>
        </Setter>
      </Trigger>
    </Style.Triggers>
  </Style>
</ResourceDictionary>
'@
function Nuevos-Estilos { return [Windows.Markup.XamlReader]::Parse((Tema-Texto $EstilosXaml)) }
$win.Resources.MergedDictionaries.Add((Nuevos-Estilos))

# Icono: el del Administrador de tareas (rendimiento; esta en Windows 10 y 11), en la ventana, la barra de tareas y el acceso directo del escritorio
$IconoExe = Join-Path $env:SystemRoot 'System32\Taskmgr.exe'
if (Test-Path -LiteralPath $IconoExe) {
    try {
        Add-Type -AssemblyName System.Drawing
        $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($IconoExe)
        $win.Icon = [System.Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon($ico.Handle, [Windows.Int32Rect]::Empty, [Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions())
    } catch { }
    # Los que instalaron antes tienen el acceso directo con el icono viejo: se cambia solo
    try {
        $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Xuca OPtimizer.lnk'
        if (Test-Path -LiteralPath $lnk) {
            $acc = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
            $quiero = $IconoExe + ',0'
            if (($acc.TargetPath -like '*XucaOP.bat') -and ($acc.IconLocation -ne $quiero)) { $acc.IconLocation = $quiero; $acc.Save() }
        }
    } catch { }
}

$ui = @{}
foreach ($n in 'NavPerfiles', 'NavDebloat', 'NavGaming', 'NavLimpieza', 'NavHerr', 'NavApps', 'NavAdicional', 'CfgInsignia', 'CfgInsigniaTxt', 'BtnRefrescar', 'BtnLogs', 'BtnRedes', 'Titulo', 'Descripcion', 'TituloCaja', 'TituloIcono', 'Scroll', 'BtnSeguras', 'BtnTodo', 'BtnNada', 'BtnRestablecer', 'BtnAplicar', 'Estado', 'Carga', 'CargaTitulo', 'CargaBarra', 'CargaPct', 'CargaDetalle', 'CargaZona', 'CargaInfo', 'UpdCarga', 'BtnUpd', 'BtnUpdNo', 'UpdTitulo', 'UpdTexto', 'BtnUpdBarra', 'UpdBarraTexto', 'VersionTxt', 'OrigBarra', 'OrigTexto', 'BtnIdioma', 'IdiomaTxt', 'BtnTema', 'TemaTxt', 'Marco', 'Raiz', 'Barra', 'Contenido', 'CargaDns', 'CargaDnsTitulo', 'CargaDnsLista', 'CargaCaja', 'CargaMarca') { $ui[$n] = $win.FindName($n) }

# Numero de version (sale del version.txt de tu PC)
function Poner-Version([bool]$vieja, [bool]$distinta) {
    $v = ''
    try { if (Test-Path -LiteralPath $VersionLocal) { $v = (([IO.File]::ReadAllText($VersionLocal) -replace '^\uFEFF', '') -split "`r?`n")[0].Trim() } } catch { }
    if (-not $v) { $v = 'sin version' } elseif ($v -notmatch '^[vV]') { $v = 'v' + $v }
    if ($vieja) { $v += (Con-Enie $(if ($distinta) { ' (distinta)' } else { ' (desactualizada)' })) }
    $ui.VersionTxt.Text = (Con-Enie $v)
    $ui.VersionTxt.Foreground = $(if ($vieja) { (New-Object Windows.Media.BrushConverter).ConvertFromString('#F28B82') } else { (New-Object Windows.Media.BrushConverter).ConvertFromString('#5C6370') })
}
Poner-Version $false

foreach ($b in @($ui.BtnAplicar, $ui.BtnRestablecer)) { [Windows.Controls.ToolTipService]::SetShowOnDisabled($b, $true) }

$bc = New-Object Windows.Media.BrushConverter
function Pincel([string]$hex) { return $script:bc.ConvertFromString((Tema-Hex $hex)) }

# El "OP" de Xuca OPtimizer va siempre en celeste brillante
function Marcar-OP($tb) {
    $txt = [string]$tb.Text
    if ($txt -cnotmatch 'OPtimiz') { return }
    $tb.Inlines.Clear()
    foreach ($pz in ($txt -csplit '(OP)(?=timiz)')) {
        if (-not $pz) { continue }
        $r = New-Object Windows.Documents.Run($pz)
        if ($pz -ceq 'OP') { $r.Foreground = (Pincel '#22D3EE'); $r.FontWeight = 'Bold' }
        $tb.Inlines.Add($r)
    }
}

function Nuevo-Texto([string]$t, [double]$tam, [string]$color, [bool]$negrita) {
    $tb = New-Object Windows.Controls.TextBlock
    $tb.Text = (Con-Enie $t); $tb.FontSize = $tam; $tb.Foreground = $script:bc.ConvertFromString((Tema-Letra $color)); $tb.TextWrapping = 'Wrap'
    if ($negrita) { $tb.FontWeight = 'SemiBold' }
    Marcar-OP $tb
    return $tb
}

function Agregar-Linea($tb, [string]$etiqueta, [string]$color, [string]$texto) {
    if (-not $texto) { return }
    if ($tb.Inlines.Count -gt 0) { $tb.Inlines.Add((New-Object Windows.Documents.LineBreak)) }
    $r1 = New-Object Windows.Documents.Run((Con-Enie $etiqueta)); $r1.Foreground = $script:bc.ConvertFromString((Tema-Letra $color)); $r1.FontWeight = 'SemiBold'
    $r2 = New-Object Windows.Documents.Run((Con-Enie $texto))
    $tb.Inlines.Add($r1); $tb.Inlines.Add($r2)
}

# Animaciones suaves (arrancan rapido y frenan al final)
$script:Suave = New-Object Windows.Media.Animation.CubicEase
$script:Suave.EasingMode = 'EaseOut'
function Animar($obj, $prop, [double]$a, [int]$ms) {
    $an = [Windows.Media.Animation.DoubleAnimation]::new($a, [Windows.Duration]::new([TimeSpan]::FromMilliseconds($ms)))
    $an.EasingFunction = $script:Suave
    $obj.BeginAnimation($prop, $an)
}
# $st = ScaleTransform; si $desde es negativo arranca desde donde esta
function Escalar($st, [double]$desde, [double]$hasta, [int]$ms) {
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $an = [Windows.Media.Animation.DoubleAnimation]::new($hasta, [Windows.Duration]::new([TimeSpan]::FromMilliseconds($ms)))
        if ($desde -ge 0) { $an.From = $desde }
        $an.EasingFunction = $script:Suave
        $st.BeginAnimation($pr, $an)
    }
}

function Nueva-Caja {
    $card = New-Object Windows.Controls.Border
    $card.CornerRadius = 10; $card.Background = (Pincel '#1C2027'); $card.Padding = '16,12'; $card.Margin = '0,0,0,10'
    # Borde invisible que se prende en celeste al pasar el mouse
    $card.BorderThickness = 1
    $card.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(0, 0x8F, 0xD3, 0xF4))
    $card.Tag = @{ Color = [Windows.Media.Color]::FromRgb(0x8F, 0xD3, 0xF4); Reposo = 0; Encima = 150 }
    # Escala (para el mouse) y desplazamiento (para cuando se despliega la pagina)
    $card.RenderTransformOrigin = '0.5,0.5'
    $tg = New-Object Windows.Media.TransformGroup
    $tg.Children.Add((New-Object Windows.Media.ScaleTransform 1, 1))
    $tg.Children.Add((New-Object Windows.Media.TranslateTransform 0, 0))
    $card.RenderTransform = $tg
    $card.Add_MouseEnter({ Caja-Mouse $this $true })
    $card.Add_MouseLeave({ Caja-Mouse $this $false })
    return $card
}

# Borde de color fijo (mas fuerte al pasar el mouse)
function Caja-Borde($c, [string]$hex) {
    $col = Color-Tema($hex)
    # Se cambia el color sin perder lo demas que guarda la caja (por ejemplo su casilla)
    if ($c.Tag -is [hashtable]) { $c.Tag.Color = $col; $c.Tag.Reposo = 120; $c.Tag.Encima = 255 }
    else { $c.Tag = @{ Color = $col; Reposo = 120; Encima = 255 } }
    $c.BorderThickness = 2
    $c.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(120, $col.R, $col.G, $col.B))
}

function Caja-Mouse($c, [bool]$encima) {
    if ($encima -and ($c.Opacity -lt 0.99)) { return }
    $ms = $(if ($encima) { 160 } else { 240 })
    # Las no compatibles no se agrandan: solo se les prende el borde rojo
    $bloq = ($c.Tag -is [hashtable]) -and $c.Tag.Bloq
    if (-not $bloq) {
        $f = 1 + [math]::Min(0.012, 8 / [math]::Max([double]$c.ActualWidth, 1))
        Escalar $c.RenderTransform.Children[0] -1 $(if ($encima) { $f } else { 1.0 }) $ms
    }
    if ($c.Tag -is [hashtable]) {
        $b = $c.Tag.Color
        $col = [Windows.Media.Color]::FromArgb($(if ($encima) { $c.Tag.Encima } else { $c.Tag.Reposo }), $b.R, $b.G, $b.B)
        $ca = [Windows.Media.Animation.ColorAnimation]::new($col, [Windows.Duration]::new([TimeSpan]::FromMilliseconds($ms)))
        $c.BorderBrush.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, $ca)
    }
}

# Al cambiar de pagina, las cajas aparecen una atras de otra bajando un poco (como si se desplegara el menu)
function Desplegar($panel) {
    $i = 0
    foreach ($h in @($panel.Children)) {
        if ($h.Visibility -ne 'Visible') { continue }
        $tt = $null
        if ($h.RenderTransform -is [Windows.Media.TransformGroup]) { $tt = $h.RenderTransform.Children[1] }
        elseif ($h.RenderTransform -is [Windows.Media.TranslateTransform]) { $tt = $h.RenderTransform }
        else { $tt = New-Object Windows.Media.TranslateTransform; $h.RenderTransform = $tt }
        $espera = [TimeSpan]::FromMilliseconds([math]::Min($i, 14) * 30)
        $fin = $espera + [TimeSpan]::FromMilliseconds(280)
        # Opacidad: queda en 0 hasta su turno y sube hasta la que tiene (las grises siguen grises)
        $op = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $op.FillBehavior = 'Stop'
        [void]$op.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero)))
        [void]$op.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($espera)))
        [void]$op.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]$h.GetAnimationBaseValue([Windows.UIElement]::OpacityProperty), [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $script:Suave))
        $h.BeginAnimation([Windows.UIElement]::OpacityProperty, $op)
        $y = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $y.FillBehavior = 'Stop'
        [void]$y.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(-18.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero)))
        [void]$y.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(-18.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($espera)))
        [void]$y.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $script:Suave))
        $tt.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $y)
        $i++
    }
}

function Nuevo-Boton([string]$texto, [string]$color) {
    $b = New-Object Windows.Controls.Button
    $b.Style = $win.FindResource('Accion'); $b.Content = (Con-Enie $texto); $b.Margin = '0,10,8,0'
    if ($color) { $b.Background = (Pincel $color) }
    return $b
}

# ------------------------------------------------------------
# Ventanitas propias (oscuras, sin el marco de Windows)
# ------------------------------------------------------------
function Nuevo-Dialogo([double]$ancho) {
    $w = New-Object Windows.Window
    $w.Width = $ancho; $w.SizeToContent = 'Height'; $w.ResizeMode = 'NoResize'
    $w.WindowStyle = 'None'; $w.AllowsTransparency = $true; $w.Background = [Windows.Media.Brushes]::Transparent
    $w.WindowStartupLocation = 'CenterOwner'; $w.Owner = $win; $w.FontFamily = 'Segoe UI'; $w.ShowInTaskbar = $false
    $w.Resources.MergedDictionaries.Add((Nuevos-Estilos))
    $borde = New-Object Windows.Controls.Border
    $borde.CornerRadius = 16; $borde.BorderThickness = 1.5
    $fondo = New-Object Windows.Media.LinearGradientBrush (Color-Tema('#1B2130')), (Color-Tema('#1D1A24')), 45
    $borde.Background = $fondo
    $linea = New-Object Windows.Media.LinearGradientBrush (Color-Tema('#993D6FD9')), (Color-Tema('#99F9A8D4')), 45
    $borde.BorderBrush = $linea
    $borde.Padding = '24,20,24,18'; $borde.Margin = 12
    $sombra = New-Object Windows.Media.Effects.DropShadowEffect
    $sombra.BlurRadius = 22; $sombra.ShadowDepth = 0; $sombra.Opacity = 0.6
    $borde.Effect = $sombra
    $w.Content = $borde
    # Se abre creciendo con un pequeno rebote y se cierra achicandose (como en Android)
    $borde.RenderTransformOrigin = '0.5,0.5'
    $borde.RenderTransform = New-Object Windows.Media.ScaleTransform 0.9, 0.9
    $borde.Opacity = 0
    $w.Tag = @{ Listo = $false; Saliendo = $false; Res = $null }
    $w.Add_Loaded({ Dialogo-Entrar $this })
    $w.Add_Closing({ param($s, $e) Dialogo-Salir $s $e })
    # Se arrastra tocando cualquier parte vacia
    $borde.Add_MouseLeftButtonDown({ try { [Windows.Window]::GetWindow($this).DragMove() } catch { } })
    return $w
}

function Dialogo-Entrar($w) {
    $b = $w.Content
    $a = [Windows.Media.Animation.DoubleAnimation]::new(0, 1, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(180)))
    $a.EasingFunction = $script:Suave
    $b.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
    $be = New-Object Windows.Media.Animation.BackEase
    $be.EasingMode = 'EaseOut'; $be.Amplitude = 0.35
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $sa = [Windows.Media.Animation.DoubleAnimation]::new(0.9, 1, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(300)))
        $sa.EasingFunction = $be
        $b.RenderTransform.BeginAnimation($pr, $sa)
    }
}
# Al cerrar: se frena el cierre, se achica y se desvanece, y recien ahi se cierra con la misma respuesta
function Dialogo-Salir($w, $e) {
    if ($w.Tag.Listo) { return }
    $e.Cancel = $true
    if ($w.Tag.Saliendo) { return }
    $w.Tag.Saliendo = $true
    $w.Tag.Res = $w.DialogResult
    $b = $w.Content
    $ce = New-Object Windows.Media.Animation.CubicEase
    $ce.EasingMode = 'EaseIn'
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $sa = [Windows.Media.Animation.DoubleAnimation]::new(0.94, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(140)))
        $sa.EasingFunction = $ce
        $b.RenderTransform.BeginAnimation($pr, $sa)
    }
    $a = [Windows.Media.Animation.DoubleAnimation]::new(0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(140)))
    $a.EasingFunction = $ce
    $fin = {
        $w.Tag.Listo = $true
        if ($null -ne $w.Tag.Res) { $w.DialogResult = $w.Tag.Res } else { $w.Close() }
    }.GetNewClosure()
    $a.Add_Completed($fin)
    $b.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}

function Fila-Botones($izq, $der) {
    $fila = New-Object Windows.Controls.DockPanel
    $fila.Margin = '0,14,0,0'; $fila.LastChildFill = $false
    $pd = New-Object Windows.Controls.StackPanel; $pd.Orientation = 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($pd, 'Right')
    foreach ($b in $der) { $b.Margin = '8,0,0,0'; $pd.Children.Add($b) | Out-Null }
    $fila.Children.Add($pd) | Out-Null
    $pi = New-Object Windows.Controls.StackPanel; $pi.Orientation = 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($pi, 'Left')
    foreach ($b in $izq) { $b.Margin = '0,0,8,0'; $pi.Children.Add($b) | Out-Null }
    $fila.Children.Add($pi) | Out-Null
    return $fila
}

# Circulito de color con un icono, que entra con un rebote (lo usan los carteles)
function Icono-Dialogo([int]$icono, [string]$color, [double]$tam) {
    $col = Color-Tema($color)
    $b = New-Object Windows.Controls.Border
    $b.Width = $tam; $b.Height = $tam; $b.CornerRadius = $tam / 2; $b.VerticalAlignment = 'Top'
    $b.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(48, $col.R, $col.G, $col.B))
    $b.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(110, $col.R, $col.G, $col.B))
    $b.BorderThickness = 1.5
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = [string][char]$icono; $t.FontFamily = 'Segoe MDL2 Assets'; $t.FontSize = [math]::Round($tam * 0.42)
    $t.Foreground = (Pincel $color); $t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'
    $b.Child = $t
    $b.RenderTransformOrigin = '0.5,0.5'
    $st = New-Object Windows.Media.ScaleTransform 1, 1
    $b.RenderTransform = $st
    $re = New-Object Windows.Media.Animation.BackEase
    $re.EasingMode = 'EaseOut'; $re.Amplitude = 0.6
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $an = [Windows.Media.Animation.DoubleAnimation]::new(0.3, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(480)))
        $an.BeginTime = [TimeSpan]::FromMilliseconds(90); $an.EasingFunction = $re
        $st.BeginAnimation($pr, $an)
    }
    return $b
}

# Que icono y color lleva cada cartel, segun el boton principal o el titulo
function Tipo-Dialogo([string]$titulo, [string]$colorSi, [bool]$pregunta) {
    if ($colorSi -eq '#B3412F') { return @(0xE7BA, '#F28B82') }
    if ($colorSi -eq '#A21CAF') { return @(0xE896, $ColorDrv) }
    if ($titulo -match '(?i)^no se pudo|error|fallo') { return @(0xE783, '#F28B82') }
    if ($titulo -match '(?i)listo|terminad|descargad|aplicad') { return @(0xE73E, '#81C995') }
    if ($Aviso -and $titulo.StartsWith($Aviso)) { return @(0xE7BA, '#E5B567') }
    if ($pregunta) { return @(0xE897, '#8AB4F8') }
    return @(0xE946, '#8AB4F8')
}

# Pregunta Si/No. Devuelve $true si tocas el boton principal. Sin $textoNo es solo un aviso con un boton.
function Confirmar([string]$titulo, [string]$mensaje, [string]$textoSi, [string]$colorSi, [string]$textoNo) {
    if (-not $textoSi) { $textoSi = 'Seguir' }
    if (-not $colorSi) { $colorSi = '#3D6FD9' }
    $w = Nuevo-Dialogo 480
    $sp = New-Object Windows.Controls.StackPanel
    $tipo = Tipo-Dialogo $titulo $colorSi ([bool]$textoNo)
    $cab = New-Object Windows.Controls.Grid
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $cab.ColumnDefinitions.Add($c0); $cab.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $ic = Icono-Dialogo $tipo[0] $tipo[1] 42
    $ic.Margin = '0,0,14,0'
    $cab.Children.Add($ic) | Out-Null
    $tx = New-Object Windows.Controls.StackPanel
    $tx.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($tx, 1)
    $tx.Children.Add((Nuevo-Texto ($titulo -replace ('^' + [regex]::Escape($Aviso) + '\s*'), '') 17 '#FFFFFF' $true)) | Out-Null
    $m = Nuevo-Texto $mensaje 13 '#C3C8D0' $false
    $m.Margin = '0,6,0,0'; $m.LineHeight = 20
    $tx.Children.Add($m) | Out-Null
    $cab.Children.Add($tx) | Out-Null
    $sp.Children.Add($cab) | Out-Null
    $bSi = Nuevo-Boton $textoSi $colorSi; $bSi.IsDefault = $true
    $bSi.Add_Click({ [Windows.Window]::GetWindow($this).DialogResult = $true })
    $der = @()
    if ($textoNo) { $bNo = Nuevo-Boton $textoNo; $bNo.IsCancel = $true; $der += $bNo } else { $bSi.IsCancel = $true }
    $der += $bSi
    $sp.Children.Add((Fila-Botones @() $der)) | Out-Null
    $w.Content.Child = $sp
    return ($w.ShowDialog() -eq $true)
}
function Avisar([string]$titulo, [string]$mensaje) { Confirmar $titulo $mensaje 'Entendido' '#3D6FD9' '' | Out-Null }

# Cartel de "Limpieza terminada": tilde verde grande y los GB liberados bien a la vista
function Resultado-Limpieza([string]$liberado) {
    $w = Nuevo-Dialogo 400
    $sp = New-Object Windows.Controls.StackPanel
    $ic = Icono-Dialogo 0xE73E '#81C995' 60
    $ic.HorizontalAlignment = 'Center'
    $sp.Children.Add($ic) | Out-Null
    $t = Nuevo-Texto 'Limpieza terminada' 18 '#FFFFFF' $true
    $t.HorizontalAlignment = 'Center'; $t.Margin = '0,12,0,0'
    $sp.Children.Add($t) | Out-Null
    if ($liberado) {
        # Numero grande en degradado verde, con su cajita
        $caja = New-Object Windows.Controls.Border
        $caja.CornerRadius = 14; $caja.Padding = '18,10,18,12'; $caja.Margin = '0,14,0,0'; $caja.HorizontalAlignment = 'Center'
        $caja.Background = (Pincel '#16291F'); $caja.BorderBrush = (Pincel '#2F5A40'); $caja.BorderThickness = 1
        $cs = New-Object Windows.Controls.StackPanel
        $num = New-Object Windows.Controls.TextBlock
        $num.Text = $liberado; $num.FontSize = 34; $num.FontWeight = 'Bold'; $num.HorizontalAlignment = 'Center'
        $num.Foreground = New-Object Windows.Media.LinearGradientBrush (Color-Tema('#81C995')), (Color-Tema('#6EE7B7')), 0
        $cs.Children.Add($num) | Out-Null
        $sub = Nuevo-Texto 'de espacio liberado en tu disco' 12.5 '#9AC7A8' $false
        $sub.HorizontalAlignment = 'Center'
        $cs.Children.Add($sub) | Out-Null
        $caja.Child = $cs
        $sp.Children.Add($caja) | Out-Null
    } else {
        $m = Nuevo-Texto 'La cache quedo limpia.' 13 '#C3C8D0' $false
        $m.HorizontalAlignment = 'Center'; $m.Margin = '0,6,0,0'
        $sp.Children.Add($m) | Out-Null
    }
    $n = Nuevo-Texto 'Los detalles quedaron en la carpeta de logs.' 12 '#7D8590' $false
    $n.HorizontalAlignment = 'Center'; $n.Margin = '0,12,0,0'
    $sp.Children.Add($n) | Out-Null
    $b = Nuevo-Boton 'Genial' '#1F8A5B'; $b.IsDefault = $true; $b.IsCancel = $true
    $b.HorizontalAlignment = 'Center'; $b.MinWidth = 140; $b.Margin = '0,16,0,0'
    $b.Add_Click({ [Windows.Window]::GetWindow($this).DialogResult = $true })
    $sp.Children.Add($b) | Out-Null
    $w.Content.Child = $sp
    [void]$w.ShowDialog()
}

# Ventana con casillas para elegir juegos o programas, y un campo para agregar otros.
# Devuelve la lista de procesos elegidos ('' si ninguno) o $null si cancelas.
$script:Lst = $null
function Elegir-Lista([string]$titulo, [string]$mensaje, $items, [string]$ayudaExtra, $defecto) {
    $w = Nuevo-Dialogo 700
    $w.SizeToContent = 'Manual'; $w.Height = 680
    $dock = New-Object Windows.Controls.DockPanel
    $cab = New-Object Windows.Controls.StackPanel
    [Windows.Controls.DockPanel]::SetDock($cab, 'Top')
    $cab.Children.Add((Nuevo-Texto $titulo 17 '#FFFFFF' $true)) | Out-Null
    $msg = Nuevo-Texto $mensaje 12.5 '#C3C8D0' $false
    $msg.Margin = '0,6,0,12'; $msg.LineHeight = 19
    $cab.Children.Add($msg) | Out-Null
    $dock.Children.Add($cab) | Out-Null

    $abajo = New-Object Windows.Controls.StackPanel
    [Windows.Controls.DockPanel]::SetDock($abajo, 'Bottom')
    $lx = Nuevo-Texto $ayudaExtra 12 '#9AA0A6' $false
    $lx.Margin = '0,12,0,6'
    $abajo.Children.Add($lx) | Out-Null
    $filaAg = New-Object Windows.Controls.DockPanel
    $bAg = Nuevo-Boton 'Agregar'; $bAg.Margin = '8,0,0,0'
    [Windows.Controls.DockPanel]::SetDock($bAg, 'Right')
    $filaAg.Children.Add($bAg) | Out-Null
    $tx = New-Object Windows.Controls.TextBox
    $tx.Padding = '6,6'; $tx.FontSize = 13.5; $tx.VerticalContentAlignment = 'Center'
    $tx.Background = (Pincel '#0E1014'); $tx.Foreground = (Pincel '#FFFFFF'); $tx.BorderBrush = (Pincel '#3A404C'); $tx.CaretBrush = (Pincel '#FFFFFF')
    $filaAg.Children.Add($tx) | Out-Null
    $abajo.Children.Add($filaAg) | Out-Null
    $bTodo = Nuevo-Boton 'Marcar todo'; $bNada = Nuevo-Boton 'Desmarcar todo'; $bDef = Nuevo-Boton 'Lista por defecto'
    $bDef.ToolTip = (Con-Enie 'Vuelve a la lista de fabrica: todos los del catalogo marcados y sin los que agregaste vos.')
    $bc1 = Nuevo-Boton 'Cancelar'; $bc1.IsCancel = $true
    $bok = Nuevo-Boton 'Guardar' '#3D6FD9'
    $abajo.Children.Add((Fila-Botones @($bTodo, $bNada, $bDef) @($bc1, $bok))) | Out-Null
    $dock.Children.Add($abajo) | Out-Null

    $grilla = New-Object Windows.Controls.Primitives.UniformGrid
    $grilla.Columns = 2; $grilla.VerticalAlignment = 'Top'
    $caja = New-Object Windows.Controls.Border
    $caja.CornerRadius = 10; $caja.Background = (Pincel '#14161B'); $caja.Padding = '12,8'
    $sv = New-Object Windows.Controls.ScrollViewer
    $sv.VerticalScrollBarVisibility = 'Auto'
    $sv.Content = $grilla
    $caja.Child = $sv
    $dock.Children.Add($caja) | Out-Null

    $script:Lst = @{ Grilla = $grilla; Texto = $tx; Scroll = $sv; Casillas = (New-Object System.Collections.Generic.List[object]); Defecto = $defecto }
    foreach ($it in $items) { Lista-Agregar $it.Nombre $it.Procs ([bool]$it.Marcado) }

    $bAg.Add_Click({ Lista-AgregarTexto })
    $tx.Add_KeyDown({ if ($_.Key -eq 'Return') { Lista-AgregarTexto; $_.Handled = $true } })
    $bTodo.Add_Click({ foreach ($c in $script:Lst.Casillas) { $c.IsChecked = $true } })
    $bNada.Add_Click({ foreach ($c in $script:Lst.Casillas) { $c.IsChecked = $false } })
    $bDef.Add_Click({ Lista-Defecto })
    $bok.Add_Click({ Lista-AgregarTexto; [Windows.Window]::GetWindow($this).DialogResult = $true })
    $w.Content.Child = $dock
    $ok = $w.ShowDialog()
    $cas = $script:Lst.Casillas
    $script:Lst = $null
    if (-not $ok) { return $null }
    return (@($cas | Where-Object { $_.IsChecked -eq $true } | ForEach-Object { ([string]$_.Tag) -split ',' }) -join ',')
}

function Lista-Agregar([string]$nombre, $procs, [bool]$marcado) {
    $cb = New-Object Windows.Controls.CheckBox
    $cb.Margin = '2,4,8,4'; $cb.VerticalContentAlignment = 'Center'; $cb.IsChecked = $marcado
    $cb.Tag = (@($procs) -join ',')
    $cb.ToolTip = ((Con-Enie 'Proceso: ') + (@($procs) -join ', '))
    $t = New-Object Windows.Controls.TextBlock
    $t.TextWrapping = 'Wrap'
    $r1 = New-Object Windows.Documents.Run($nombre); $r1.Foreground = (Pincel '#FFFFFF'); $r1.FontSize = 13.5
    $t.Inlines.Add($r1)
    if ($nombre -ne (@($procs) -join ', ')) {
        $t.Inlines.Add((New-Object Windows.Documents.LineBreak))
        $r2 = New-Object Windows.Documents.Run((@($procs) -join ', ')); $r2.Foreground = (Pincel '#7D8590'); $r2.FontSize = 11
        $t.Inlines.Add($r2)
    }
    $cb.Content = $t
    $script:Lst.Grilla.Children.Add($cb) | Out-Null
    $script:Lst.Casillas.Add($cb)
}

# Vuelve a la lista de fabrica (se guarda recien cuando tocas Guardar)
function Lista-Defecto {
    if ((-not $script:Lst) -or (-not $script:Lst.Defecto)) { return }
    $script:Lst.Grilla.Children.Clear()
    $script:Lst.Casillas.Clear()
    foreach ($it in $script:Lst.Defecto) { Lista-Agregar $it.Nombre $it.Procs $true }
    $script:Lst.Scroll.ScrollToTop()
}

# Lo escrito en el campo se suma a la lista ya marcado (si ya estaba, solo se marca)
function Lista-AgregarTexto {
    if (-not $script:Lst) { return }
    $nuevos = @(Normalizar-Procesos $script:Lst.Texto.Text)
    $script:Lst.Texto.Text = ''
    foreach ($n in $nuevos) {
        $ya = @($script:Lst.Casillas | Where-Object { (([string]$_.Tag) -split ',') -contains $n })
        if ($ya.Count -gt 0) { foreach ($c in $ya) { $c.IsChecked = $true } }
        else { $nm = Juego-Nombre $n; if (-not $nm) { $nm = $n }; Lista-Agregar $nm @($n) $true }
    }
    if ($nuevos.Count -gt 0) { $script:Lst.Scroll.ScrollToEnd() }
}

# Abren la lista compartida y la guardan al instante. Devuelven $false si cancelaste.
# Con $aplicar, si la prioridad alta o la afinidad ya estan activas, se vuelven a aplicar solas con la lista nueva.
function Editar-Juegos([bool]$aplicar) {
    $L = Leer-Listas
    $r = Elegir-Lista 'Tus juegos' ('Esta lista la usan "Prioridad alta" y "Afinidad de CPU": lo que marques aca vale para las dos.' + "`n" + 'Al guardar, si alguna de las dos ya esta activa, se actualiza sola con la lista nueva.' + "`n" + 'La lista se arma sola con los juegos que tenes instalados en cualquier disco: Steam, Epic, EA, Battle.net, Ubisoft, Riot, Xbox, GOG, Rockstar y Minecraft.') (Items-De (Cat-Juegos) $L.juegos) 'Agregar otros juegos: escribi su proceso sin .exe (separados por comas) y toca Agregar. Lo ves con el juego abierto: Administrador de tareas, pestana Detalles.' (Items-De (Cat-Juegos) $null)
    if ($null -eq $r) { return $false }
    Guardar-Listas @(Normalizar-Procesos $r) $L.fondo
    Actualizar-Resumenes
    if ($aplicar) { Aplicar-ListaActiva $true $true }
    return $true
}
function Editar-Fondo([bool]$aplicar) {
    $L = Leer-Listas
    $r = Elegir-Lista 'Programas de fondo' ('Mientras jugas, estos programas se van a otros nucleos. Cuando cerras el juego vuelven a usar todos.' + "`n" + 'OBS, Visual Studio, Unreal, Godot, el sistema y los antitrampas nunca se tocan aunque los escribas.') (Items-De $AfiFondoCat $L.fondo) 'Agregar otros programas (separados por comas). No pongas launchers (Steam, Epic, Battle.net): los juegos que abren heredarian esos nucleos.' (Items-De $AfiFondoCat $null)
    if ($null -eq $r) { return $false }
    Guardar-Listas $L.juegos @(Normalizar-Procesos $r)
    Actualizar-Resumenes
    if ($aplicar) { Aplicar-ListaActiva $false $true }
    return $true
}

# Vuelve a aplicar la prioridad alta y/o la afinidad con la lista guardada, solo si ya estaban activas.
# Si dejaste la lista de juegos vacia, se quitan (la lista manda).
function Aplicar-ListaActiva([bool]$pri, [bool]$afi) {
    $pri = $pri -and (@(Prio-Actuales).Count -gt 0)
    $afi = $afi -and [bool](Get-ScheduledTask -TaskName 'XucaAfinidad' -ErrorAction SilentlyContinue)
    if (-not ($pri -or $afi)) { $ui.Estado.Text = (Con-Enie 'Lista guardada. Se usa cuando apliques "Prioridad alta" o "Afinidad".'); return }
    $L = Leer-Listas
    $jug = @(Procesos-De (Cat-Juegos) $L.juegos)
    $fon = @(Procesos-De $AfiFondoCat $L.fondo)
    $v = @{}; $n = 0
    if ($pri) {
        $n++
        if ($jug.Count -gt 0) { $v['XR_pri'] = 'S'; $v['PRIOJ'] = ($jug -join ','); $v['PRIOSYNC'] = '1' } else { $v['XR_pri'] = 'R' }
    }
    if ($afi) {
        $n++
        if ($jug.Count -gt 0) {
            $v['XR_afi'] = 'S'; $v['AFIAPP'] = '1'; $v['AFIJ'] = ($jug -join ',')
            if ($fon.Count -gt 0) { $v['AFIF'] = ($fon -join ',') }
        } else { $v['XR_afi'] = 'R' }
    }
    Correr @([pscustomobject]@{ Nombre = 'Tu lista de juegos'; Ruta = $Rutas.Gaming; Vars = $v; Cambios = $n; Visible = $false; Tipo = 'lista' }) $false 'Aplicando tu lista nueva'
}

# ------------------------------------------------------------
# Tarjetas
# ------------------------------------------------------------
# Etiqueta "Ya aplicado" / "Sin aplicar" a la derecha de cada tarjeta
$script:Pills = @{}
function Nueva-Pill {
    $pb = New-Object Windows.Controls.Border
    $pb.CornerRadius = 9; $pb.Padding = '9,2'; $pb.VerticalAlignment = 'Center'; $pb.Visibility = 'Collapsed'
    $pb.Child = (Nuevo-Texto '' 11.5 '#FFFFFF' $true)
    return $pb
}
function Poner-Pill($pb, $estado) {
    if ($null -eq $estado) { $pb.Visibility = 'Collapsed'; return }
    $pb.Visibility = 'Visible'
    if ($estado) { $pb.Background = (Pincel '#1E3A2B'); $pb.Child.Foreground = (Pincel '#81C995'); $pb.Child.Text = (Con-Enie 'Ya aplicado') }
    else { $pb.Background = (Pincel '#262B34'); $pb.Child.Foreground = (Pincel '#9AA0A6'); $pb.Child.Text = (Con-Enie 'Sin aplicar') }
}

function Nota([string]$t, [string]$color, [string]$margen) {
    $n = Nuevo-Texto $t 12 $color $false
    $n.Margin = $margen
    return $n
}

$script:PrioTexto = $null
$script:AfiTexto = $null
$script:CpuTxt = @{}        # 'afi' / 'xb' -> texto con lo que cambia con tu procesador
$script:XbIcono = $null     # icono de advertencia de la Game Bar (solo se ve en los Ryzen X3D de dos bloques)
$script:TxtJuegos = New-Object System.Collections.Generic.List[object]
$script:TxtFondo = $null
$script:Tarjetas = @{}      # 'Pagina|id' -> @{ Card; Cb; Nota }
$script:NoDisp = @{}        # 'Pagina|id' -> motivo por el que no es compatible con tu Windows
$script:Estados = @{}       # 'Pagina|id' -> $true (ya aplicado), $false o $null
$Aviso = [string][char]0x26A0

# Opciones que se sabe que en algunas PCs pueden dar problemas: llevan el icono de advertencia
$Advertencias = @{
    'Debloat|rpo'  = 'Ya no vas a poder volver atras con un punto de restauracion.'
    'Debloat|av'   = 'Si la Proteccion contra alteraciones sigue encendida, falla. Smart App Control no vuelve sin reinstalar Windows. Si cambia algo, borra Riot Vanguard y cierra Riot (lo reinstalas abriendo el cliente de Riot).'
    'Debloat|bl'   = 'Descifrar el disco puede tardar bastante en segundo plano. Si cambia algo, borra Riot Vanguard.'
    'Debloat|db'   = 'No tiene restablecimiento las apps borradas se reinstalan a mano desde la Store.'
    'Debloat|edge' = 'Si no tenes otro navegador, te quedas sin uno. Una actualizacion grande de Windows puede traerlo de vuelta.'
    'Debloat|hst'  = 'Defender a veces lo marca como amenaza porque toca el archivo hosts.'
    'Debloat|ter'  = 'Puede romper el chat de grupo de Xbox y el NAT en juegos de Xbox en PC.'
    'Gaming|afi'   = 'Algunos antitrampas (Valorant, Fortnite) no dejan cambiar la afinidad: ese juego usa todos los nucleos, pero lo de fondo igual se mueve aparte.'
    'Gaming|pw'    = 'Con undervolt, overclock o una fuente justa, la PC puede colgarse o reiniciarse al abrir juegos.'
    'Gaming|cpu'   = 'Mas consumo y calor; con undervolt u overclock puede volverse inestable.'
    'Gaming|gf'    = 'En algunas PCs viejas puede dar problemas.'
    'Gaming|ll'    = 'Es una funcion oculta que Microsoft todavia esta probando: si notas algo raro, restablecelo.'
    'Gaming|msi'   = 'Si el driver no lo soporta, al reiniciar podes ver pantalla negra o quedarte sin internet (se arregla restableciendolo desde Modo seguro, o con R en el script).'
    'Gaming|tr'    = 'Mas consumo y calor; con undervolt u overclock puede colgarse en juegos.'
    'Gaming|pe'    = 'Con mouse o auriculares inalambricos sin driver propio, la bateria puede durar menos.'
    'Gaming|nic'   = 'En placas madre de baja calidad puede cortar el internet.'
    'Gaming|mi'    = 'Si cambia algo, borra Riot Vanguard y cierra Riot (lo reinstalas abriendo el cliente de Riot).'
    'Gaming|vbs'   = 'Deja de andar WSL, Docker, Hyper-V y las maquinas virtuales. Si cambia algo, borra Riot Vanguard.'
}

# Opciones que necesitan un driver para funcionar bien: llevan un icono celeste de descarga y dicen cual bajar
$ColorDrv = '#E879F9'
$Drivers = @{
    'Gaming|wf'  = 'Para apagar "Disable Upon Wired Connect" hace falta el driver de WiFi de la marca (Intel, Realtek o MediaTek), bajado de la pagina de tu placa madre. Con el driver generico de Windows esa opcion no aparece; lo demas se aplica igual.'
    'Gaming|nic' = 'Necesita el driver de red de la pagina de tu placa madre (Realtek, Intel o Killer). Con el driver generico de Windows casi no aparecen estas opciones.'
    'Gaming|gf'  = 'Necesita el driver de tu placa de video actualizado (NVIDIA, AMD o Intel), bajado de su pagina oficial.'
    'Gaming|msi' = 'Usa los drivers originales de tus placas (video, red y sonido), no los genericos de Windows: con los genericos es mas probable que no lo soporten.'
    'Gaming|afi' = 'Si tenes un Ryzen X3D de dos bloques (7900X3D, 7950X3D, 9900X3D o 9950X3D), instala el driver de chipset de AMD desde amd.com.'
}

# Al marcar una casilla: si a esa opcion le falta el driver, no se marca y te manda a instalarlo
function Casilla-Click($cb0) {
    if ($cb0.IsChecked -eq $true) {
        $k = @($script:Tarjetas.Keys | Where-Object { $script:Tarjetas[$_].Cb -eq $cb0 })[0]
        if ($k -and $script:DrvFalta.ContainsKey($k)) { $cb0.IsChecked = $false; Actualizar-Contador; Pedir-Drivers @($k); return }
    }
    Actualizar-Contador
}

function Nueva-Tarjeta($it, $casillas, [bool]$marcada, [string]$pagina) {
    $clave = $pagina + '|' + $it.Id
    $adv = $Advertencias[$clave]
    $drv = $Drivers[$clave]
    $card = Nueva-Caja
    $sp = New-Object Windows.Controls.StackPanel
    $head = New-Object Windows.Controls.DockPanel
    $pb = Nueva-Pill
    [Windows.Controls.DockPanel]::SetDock($pb, 'Right')
    $head.Children.Add($pb) | Out-Null
    $cb = New-Object Windows.Controls.CheckBox
    $tit = New-Object Windows.Controls.StackPanel
    $tit.Orientation = 'Horizontal'
    $tit.Children.Add((Nuevo-Texto $it.Titulo 15 '#FFFFFF' $true)) | Out-Null
    if ((-not $adv) -and ($pagina -eq 'Gaming') -and ($it.Id -eq 'xb')) {
        $script:XbIcono = Nuevo-Texto $Aviso 15 '#E5B567' $true
        $script:XbIcono.FontFamily = 'Segoe UI Symbol'; $script:XbIcono.Margin = '8,0,0,0'; $script:XbIcono.Visibility = 'Collapsed'
        $tit.Children.Add($script:XbIcono) | Out-Null
    }
    if ($adv) {
        $ic = Nuevo-Texto $Aviso 15 '#E5B567' $true
        $ic.FontFamily = 'Segoe UI Symbol'; $ic.Margin = '8,0,0,0'; $ic.ToolTip = (Con-Enie $adv)
        $tit.Children.Add($ic) | Out-Null
    }
    if ($drv) {
        $id = Nuevo-Texto ([string][char]0xE896) 14 $ColorDrv $false
        $id.FontFamily = 'Segoe MDL2 Assets'; $id.Margin = '8,1,0,0'; $id.VerticalAlignment = 'Center'; $id.ToolTip = (Con-Enie $drv)
        $tit.Children.Add($id) | Out-Null
    }
    $cb.Content = $tit; $cb.VerticalContentAlignment = 'Center'; $cb.IsChecked = $marcada
    $cb.Tag = $it.Id
    $cb.Add_Click({ Casilla-Click $this })
    # Tocar en cualquier parte de la tarjeta marca o desmarca la casilla (menos en sus botones)
    $card.Cursor = 'Hand'
    $card.Tag.Cb = $cb
    $card.Add_MouseLeftButtonUp({
        param($s, $e)
        $o = $e.OriginalSource
        while ($o -and ($o -ne $s)) {
            if (($o -is [Windows.Controls.Primitives.ButtonBase]) -or ($o -is [Windows.Controls.Primitives.TextBoxBase])) { return }
            $o = $(if ($o -is [Windows.Media.Visual]) { [Windows.Media.VisualTreeHelper]::GetParent($o) } else { $o.Parent })
        }
        $c = $s.Tag.Cb
        if ((-not $c) -or (-not $c.IsEnabled)) { return }
        $c.IsChecked = -not ($c.IsChecked -eq $true)
        Casilla-Click $c
        $e.Handled = $true
    })
    $head.Children.Add($cb) | Out-Null
    $sp.Children.Add($head) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.Margin = '24,6,0,0'; $d.LineHeight = 19
    # Primero los avisos (drivers y problemas), un renglon libre y despues la descripcion
    if ($drv) {
        $ri = New-Object Windows.Documents.Run(([string][char]0xE896)); $ri.FontFamily = 'Segoe MDL2 Assets'; $ri.Foreground = (Pincel $ColorDrv); $ri.BaselineAlignment = 'Center'
        $r1 = New-Object Windows.Documents.Run((' ' + (Con-Enie 'Necesita drivers: '))); $r1.Foreground = (Pincel $ColorDrv); $r1.FontWeight = 'SemiBold'
        $d.Inlines.Add($ri); $d.Inlines.Add($r1); $d.Inlines.Add((New-Object Windows.Documents.Run((Con-Enie $drv))))
    }
    if ($adv) { Agregar-Linea $d ($Aviso + ' Puede dar problemas: ') '#E5B567' $adv }
    if ($d.Inlines.Count -gt 0) { $d.Inlines.Add((New-Object Windows.Documents.LineBreak)) }
    Agregar-Linea $d 'Que hace: ' '#8AB4F8' $it.Hace
    Agregar-Linea $d 'A favor: ' '#81C995' $it.Favor
    Agregar-Linea $d 'En contra: ' '#F28B82' $it.Contra
    $sp.Children.Add($d) | Out-Null
    if ($pagina -eq 'Gaming' -and $it.Id -in 'afi', 'xb') {
        $ct = New-Object Windows.Controls.TextBlock
        $ct.TextWrapping = 'Wrap'; $ct.FontSize = 12.5; $ct.Foreground = (Pincel '#C3C8D0'); $ct.Margin = '24,8,0,0'; $ct.LineHeight = 19; $ct.Visibility = 'Collapsed'
        $script:CpuTxt[$it.Id] = $ct
        $sp.Children.Add($ct) | Out-Null
    }
    if (-not $it.ConR) { $sp.Children.Add((Nota 'No tiene restablecimiento: lo que haga no se puede volver atras desde la app.' '#E5B567' '24,6,0,0')) | Out-Null }

    # Aviso de "no disponible" (version de Windows, edicion, hardware o el punto de restauracion)
    $nb = Nota '' '#E5B567' '24,6,0,0'
    $nb.Visibility = 'Collapsed'
    $sp.Children.Add($nb) | Out-Null

    if ($pagina -eq 'Gaming' -and $it.Id -in 'pri', 'afi') {
        $txtNota = $(if ($it.Id -eq 'pri') { 'Usa tu lista de juegos, la misma que la afinidad de CPU.' } else { 'Usa tu lista de juegos, la misma que la prioridad alta. Tu procesador se detecta solo.' })
        $sp.Children.Add((Nota $txtNota '#8AB4F8' '24,8,0,0')) | Out-Null
        $tj = Nota '' '#C3C8D0' '24,4,0,0'
        $script:TxtJuegos.Add($tj)
        $sp.Children.Add($tj) | Out-Null
        if ($it.Id -eq 'afi') {
            $script:TxtFondo = Nota '' '#C3C8D0' '24,2,0,0'
            $sp.Children.Add($script:TxtFondo) | Out-Null
        }
        $fila = New-Object Windows.Controls.WrapPanel
        $fila.Margin = '24,0,0,0'
        $bJ = Nuevo-Boton 'Editar mis juegos'
        $bJ.Add_Click({ Editar-Juegos $true | Out-Null })
        $fila.Children.Add($bJ) | Out-Null
        if ($it.Id -eq 'afi') {
            $bF = Nuevo-Boton 'Editar programas de fondo'
            $bF.Add_Click({ Editar-Fondo $true | Out-Null })
            $fila.Children.Add($bF) | Out-Null
        }
        $sp.Children.Add($fila) | Out-Null
        $estadoTxt = Nota '' '#81C995' '24,8,0,0'
        if ($it.Id -eq 'pri') { $script:PrioTexto = $estadoTxt } else { $script:AfiTexto = $estadoTxt }
        $sp.Children.Add($estadoTxt) | Out-Null
    }

    # Si tiene las dos cosas gana el color de drivers (es lo mas importante)
    if ($drv) { Caja-Borde $card $ColorDrv } elseif ($adv) { Caja-Borde $card '#E5B567' }
    $card.Child = $sp
    $casillas[$it.Id] = $cb
    if ($pagina) {
        $script:Pills[$clave] = $pb
        $script:Tarjetas[$clave] = @{ Card = $card; Cb = $cb; Nota = $nb }
        [Windows.Controls.ToolTipService]::SetShowOnDisabled($cb, $true)
        [Windows.Controls.ToolTipService]::SetShowOnDisabled($card, $true)
    }
    return $card
}

function Actualizar-Resumenes {
    $L = Leer-Listas
    $tj = Resumen-De (Cat-Juegos) $L.juegos 'Tus juegos'
    foreach ($t in $script:TxtJuegos) { $t.Text = (Con-Enie $tj) }
    if ($script:TxtFondo) { $script:TxtFondo.Text = (Con-Enie (Resumen-De $AfiFondoCat $L.fondo 'Programas de fondo')) }
}

function Nueva-Seccion([string]$t) {
    $tb = Nuevo-Texto ((Con-Enie $t).ToUpper()) 12 '#7D8590' $true
    $tb.Margin = '2,12,0,8'
    return $tb
}

# --- Paginas de opciones (Debloat y Gaming) ---
$Casillas = @{ Debloat = @{}; Gaming = @{} }
$Paginas = @{}
$TitulosChequeo = @{}
foreach ($k in 'Debloat', 'Gaming') {
    $sp = New-Object Windows.Controls.StackPanel
    $secAct = ''
    foreach ($it in $Opciones[$k]) {
        if ($it.Seccion -ne $secAct) { $secAct = $it.Seccion; $sp.Children.Add((Nueva-Seccion $secAct)) | Out-Null }
        $sp.Children.Add((Nueva-Tarjeta $it $Casillas[$k] $false $k)) | Out-Null
        $TitulosChequeo[$k + '|' + $it.Id] = $it.Titulo
    }
    $Paginas[$k] = $sp
}

# Que opciones no se pueden usar en esta PC. $i = datos de la PC que junta la lectura de fondo.
function Calcular-NoDisp($i, $cpu) {
    $r = @{}
    if (-not $i) { return $r }
    $b = [int]$i.Build
    $tuyo = $(if ($b -ge 22000) { 'Windows 11' } else { 'Windows 10' })
    if ($i.Display) { $tuyo += (' ' + $i.Display) }
    $tuyo += (' (build ' + $b + ')')
    $nv = 'Tu Windows no lo soporta: necesita '
    if ($b -lt 26100) { $r['Debloat|rc'] = ($nv + 'Windows 11 24H2 o mas nuevo en una PC Copilot+. Tenes ' + $tuyo + '.') }
    elseif (-not $i.Recall) { $r['Debloat|rc'] = 'Tu PC no tiene Recall: solo viene en las PCs Copilot+ (con NPU).' }
    if ($b -lt 22621) { $r['Debloat|et'] = ($nv + 'Windows 11 22H2 o mas nuevo. Tenes ' + $tuyo + '.') }
    if ($b -lt 26100) { $r['Debloat|ia'] = ($nv + 'Windows 11 24H2 o mas nuevo. Tenes ' + $tuyo + '.') }
    if ($b -lt 22000) { $r['Debloat|cal'] = ($nv + 'Windows 11 (en Windows 10 el calendario del reloj no se puede quitar). Tenes ' + $tuyo + '.') }
    if (-not $i.BitLocker) { $r['Debloat|bl'] = 'Tu edicion de Windows no tiene BitLocker: viene en Pro, Enterprise y Education.' }
    if (-not $i.Winget) { $r['Debloat|chr'] = 'Falta winget en tu PC: instala o actualiza el "Instalador de aplicaciones" desde la Microsoft Store.' }
    if ($b -lt 22000) { $r['Gaming|tr'] = ($nv + 'Windows 11 (el temporizador global fijo no existe en Windows 10). Tenes ' + $tuyo + '.') }
    if (($b -lt 26100) -or (($b -lt 26300) -and ([int]$i.Ubr -lt 8655))) { $r['Gaming|ll'] = ('Tu Windows todavia no trae Baja latencia: necesita Windows 11 24H2 o 25H2 con la actualizacion de junio de 2026 (build .8655 o mas nueva). Tenes la build ' + $b + '.' + $i.Ubr + ': actualiza Windows.') }
    if (($b -lt 26100) -or (($b -in 26100, 26200) -and ([int]$i.Ubr -lt 8328)) -or (($b -eq 28000) -and ([int]$i.Ubr -lt 2179))) { $r['Gaming|xm'] = ('Tu Windows todavia no trae el Modo Xbox: llega con Windows 11 24H2 o 25H2 actualizado (build .8328 o mas nueva). Tenes la build ' + $b + '.' + $i.Ubr + '.') }
    if (([int]$i.Wifi -eq 0) -or ([int]$i.Lan -eq 0)) { $r['Gaming|wf'] = 'No hace falta: es para PCs que tienen placa WiFi y de cable a la vez (las placas apagadas no cuentan).' }
    elseif ($i.WifiSinRed) { $r['Gaming|wf'] = 'Tu placa WiFi no ve ninguna red: puede que no tenga la antena puesta. Ponela y toca "Volver a leer los ajustes".' }
    if ($b -lt 19041) { $r['Gaming|gf'] = ($nv + 'Windows 10 2004 o mas nuevo. Tenes ' + $tuyo + '.') }
    if (([int]$i.RamGB -lt 16) -or $i.Hdd) {
        $q = @()
        if ([int]$i.RamGB -lt 16) { $q += ('tenes ' + $i.RamGB + ' GB de RAM') }
        if ($i.Hdd) { $q += 'Windows esta en un disco HDD' }
        $r['Gaming|sm'] = ('Tu PC no cumple los requisitos: necesita 16 GB de RAM o mas y Windows en un SSD o NVMe (' + ($q -join ' y ') + ').')
    }
    if ($i.AvOff) { $r['Gaming|avl'] = 'No hace falta: tu antivirus ya esta apagado.' }
    if (([int]$i.NicPlacas -gt 0) -and ([int]$i.NicOpc -eq 0) -and -not ($i.DrvFalta -and $i.DrvFalta.ContainsKey('Gaming|nic'))) { $r['Gaming|nic'] = 'Tu placa de red no tiene opciones de ahorro de energia para cambiar (depende del driver): no hace falta.' }
    if ($cpu -and (-not $cpu.Ok)) { $r['Gaming|afi'] = ('Tu procesador no sirve para esto: ' + $cpu.Motivo + '.') }
    return $r
}

# Deshabilita (gris, sin poder marcar) lo que no es compatible
function Actualizar-Bloqueos {
    foreach ($k in @($script:Tarjetas.Keys)) {
        $t = $script:Tarjetas[$k]
        $motivo = $null
        $noComp = $script:NoDisp.ContainsKey($k)
        if ($noComp) { $motivo = $script:NoDisp[$k] }
        $c = $t.Card
        # Se guarda el borde que tenia (celeste, amarillo o magenta) para devolverselo si vuelve a ser compatible
        if (-not $t.ContainsKey('Borde')) { $t.Borde = @{ Color = $c.Tag.Color; Reposo = $c.Tag.Reposo; Encima = $c.Tag.Encima; Grosor = $c.BorderThickness } }
        if ($motivo) {
            # Gris, con borde rojo y sin poder marcar; al pasar el mouse por encima dice por que
            $t.Cb.IsChecked = $false; $t.Cb.IsEnabled = $false
            $c.Opacity = 1
            $c.Child.Opacity = 0.45
            $c.Background = (Pincel '#181A1F')
            $rojo = Color-Tema '#F28B82'
            $c.Tag.Color = $rojo; $c.Tag.Reposo = 150; $c.Tag.Encima = 255; $c.Tag.Bloq = $true
            $c.BorderThickness = 2
            $c.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(150, $rojo.R, $rojo.G, $rojo.B))
            $motivo = Con-Enie $motivo
            $t.Nota.Text = $motivo; $t.Nota.Foreground = (Pincel (Tema-Letra '#F28B82')); $t.Nota.Visibility = 'Visible'
            $tip = (Con-Enie 'No es compatible con tu PC') + "`n" + $motivo
            $c.ToolTip = $tip; $t.Cb.ToolTip = $tip
            [Windows.Controls.ToolTipService]::SetInitialShowDelay($c, 150)
        } else {
            $t.Cb.IsEnabled = $true
            $c.Opacity = 1
            $c.Child.Opacity = 1
            $c.Background = (Pincel '#1C2027')
            if ($c.Tag.Bloq) {
                $bo = $t.Borde
                $c.Tag.Color = $bo.Color; $c.Tag.Reposo = $bo.Reposo; $c.Tag.Encima = $bo.Encima; $c.Tag.Bloq = $false
                $c.BorderThickness = $bo.Grosor
                $c.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb($bo.Reposo, $bo.Color.R, $bo.Color.G, $bo.Color.B))
            }
            $t.Nota.Visibility = 'Collapsed'
            $c.ToolTip = $null; $t.Cb.ToolTip = $null
        }
    }
    Actualizar-BotonesAccion
}

# Muestra un boton apareciendo suave, o lo esconde
function Mostrar-Boton($b, [bool]$si) {
    if (-not $si) { $b.BeginAnimation([Windows.UIElement]::OpacityProperty, $null); $b.Visibility = 'Collapsed'; return }
    if ($b.Visibility -eq 'Visible') { return }
    $b.Visibility = 'Visible'
    $a = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(200)))
    # Al terminar suelta la opacidad, asi el boton se sigue viendo en gris cuando esta bloqueado
    $a.FillBehavior = 'Stop'
    $b.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}

# Aplicar y Restablecer no aparecen hasta que marcas algo en Debloat o Gaming (en Limpiar cache Aplicar siempre esta: hay algo que limpiar)
function Actualizar-BotonesAccion {
    if ($script:Ocupado) { return }
    $hay = (@(Elegidas 'Debloat').Count + @(Elegidas 'Gaming').Count) -gt 0
    $opc = ($script:Pagina -in 'Debloat', 'Gaming')
    Mostrar-Boton $ui.BtnAplicar (($opc -and $hay) -or ($script:Pagina -eq 'Limpieza'))
    Mostrar-Boton $ui.BtnRestablecer ($opc -and $hay)
}

# --- Pagina de limpieza ---
$Limp = @(
    [pscustomobject]@{ Id = 'CLEAN_BIN'; Titulo = 'Vaciar la papelera de reciclaje'; Hace = 'vacia la papelera de todos los discos.'; Favor = 'libera el espacio de lo que ya borraste.'; Contra = 'lo que esta en la papelera ya no se puede recuperar.'; ConR = $true },
    [pscustomobject]@{ Id = 'CLEAN_GPU'; Titulo = 'Borrar la cache de shaders'; Hace = 'borra los shaders que los juegos ya compilaron para tu placa de video.'; Favor = 'arregla tirones o graficos raros despues de actualizar el driver de video.'; Contra = 'la primera partida de cada juego va a tener tirones mientras los vuelve a armar.'; ConR = $true },
    [pscustomobject]@{ Id = 'CLEAN_RP'; Titulo = 'Borrar los puntos de restauracion'; Hace = 'borra los puntos de restauracion guardados; la proteccion del sistema sigue encendida.'; Favor = 'libera varios GB del disco.'; Contra = 'si algo sale mal, ya no podes volver a como estaba Windows antes.'; ConR = $true }
)
$Casillas.Limpieza = @{}
$spL = New-Object Windows.Controls.StackPanel
$spL.Children.Add((Nueva-Seccion 'Siempre se limpia')) | Out-Null
$fijo = Nueva-Caja
$fijo.Child = (Nuevo-Texto 'Temporales, cache de Windows Update, Windows.old, volcados y logs de errores, cache de Discord, Steam, Epic y Store, Visor de Eventos, DNS y componentes viejos de Windows (DISM). Los navegadores no se tocan.' 13 '#C3C8D0' $false)
$spL.Children.Add($fijo) | Out-Null
$spL.Children.Add((Nueva-Seccion 'Opcional')) | Out-Null
foreach ($it in $Limp) { $spL.Children.Add((Nueva-Tarjeta $it $Casillas.Limpieza $false '')) | Out-Null }
$Paginas.Limpieza = $spL

# --- Pagina de herramientas (opciones que te piden datos) ---
$spH = New-Object Windows.Controls.StackPanel
$avisoH = Nuevo-Texto 'Estas opciones te piden datos o confirmaciones. Al tocar un boton se abre la ventana negra del script: responde ahi.' 13 '#9AA0A6' $false
$avisoH.Margin = '2,0,0,10'
$spH.Children.Add($avisoH) | Out-Null

function Nueva-Herramienta([string]$titulo, [string]$hace, [string]$favor, [string]$contra, $botones) {
    $card = Nueva-Caja
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((Nuevo-Texto $titulo 15 '#FFFFFF' $true)) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.Margin = '0,6,0,0'; $d.LineHeight = 19
    Agregar-Linea $d 'Que hace: ' '#8AB4F8' $hace
    Agregar-Linea $d 'A favor: ' '#81C995' $favor
    Agregar-Linea $d 'En contra: ' '#F28B82' $contra
    $sp.Children.Add($d) | Out-Null
    $fila = New-Object Windows.Controls.WrapPanel
    foreach ($b in $botones) { $fila.Children.Add($b) | Out-Null }
    $sp.Children.Add($fila) | Out-Null
    $card.Child = $sp
    return $card
}

$script:BtnVer = Nuevo-Boton 'Actualizar a 26H2' '#3D6FD9'
$script:BtnVer.Tag = 'ver=S'
$script:VerTexto = Nuevo-Texto '' 12 '#81C995' $false
$script:VerTexto.Margin = '0,8,0,0'
$cardVer = Nueva-Herramienta 'Actualizar Windows 11' 'si tenes 24H2 o 25H2, pide la 26H2 por Windows Update; si tenes una version mas vieja, instala la 25H2 desde el ISO oficial aunque tu PC no cumpla los requisitos.' 'tenes la version nueva, que usa menos RAM, con sus mejoras y parches.' 'desde una version vieja tarda cerca de una hora y en PCs no compatibles puede fallar. Hace backup antes.' @($script:BtnVer)
$cardVer.Child.Children.Add($script:VerTexto) | Out-Null
$spH.Children.Add($cardVer) | Out-Null

$bDrv = Nuevo-Boton 'Buscar drivers' '#3D6FD9'; $bDrv.Tag = 'drv=S'
$bDrv.Add_Click({ $this.Effect = $null })
$script:BtnDrv = $bDrv
$spH.Children.Add(($script:CardDrv = Nueva-Herramienta 'Drivers recomendados' 'revisa tu PC y te recomienda solo los drivers que aportan algo: lo que no tiene driver (sonido, red, Bluetooth...), la placa de video, el chipset de AMD y el programa de tu mouse, teclado o auriculares de marca, y te abre la pagina oficial de cada uno. Tambien te avisa si la BIOS de tu placa esta vieja.' 'tenes lo que hace falta, en su ultima version, y nada de programas de mas.' 'la BIOS no se actualiza sola: se hace a mano desde la pagina de tu placa.' @($bDrv))) | Out-Null

$bAcc = Nuevo-Boton 'Elegir cuenta para borrar' '#B3412F'; $bAcc.Tag = 'ms_acc=S'
$spH.Children.Add((Nueva-Herramienta 'Borrar una cuenta de esta PC' 'te muestra las otras cuentas de la PC (usuarios de Windows y cuentas de Microsoft vinculadas) y borras la que elijas. Tu cuenta actual no aparece.' 'limpia cuentas viejas que ya no usas.' 'si tambien borras su carpeta, se pierden sus archivos.' @($bAcc))) | Out-Null

$bSin = Nuevo-Boton 'Quitar la contrasena' '#3D6FD9'; $bSin.Tag = 'al=S'
$bCon = Nuevo-Boton 'Volver a usar contrasena'; $bCon.Tag = 'al=R'
$spH.Children.Add((Nueva-Herramienta 'Entrar a Windows sin contrasena' 'tu cuenta pasa a ser local y sin contrasena. Si es una cuenta de Microsoft, te guia para pasarla a local.' 'entras directo a Windows.' 'cualquiera que prenda la PC entra, y no anda el Escritorio remoto.' @($bSin, $bCon))) | Out-Null
$bWin = Nuevo-Boton 'Activacion de Windows' '#3D6FD9'
$bWin.Add_Click({
    if (-not (Confirmar 'Activar Windows' ('Se abre PowerShell y corre el comando oficial de Massgrave:' + "`n`n" + 'irm https://get.activated.win | iex') 'Abrir' '#3D6FD9' 'Cancelar')) { return }
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"'
})
$spH.Children.Add((Nueva-Herramienta 'Activar Windows' 'ejecuta el comando oficial de Massgrave para activar Windows de manera segura.' '' '' @($bWin))) | Out-Null
$Paginas.Herr = $spH

# --- Pagina Configs (por dentro se llama Adicional): configs de juegos y apps que subo a GitHub ---
# Solo cuentan los repos de mi perfil que se llaman "Algo-Config" (por ejemplo Valorant-Config o Marvel-Rivals-Config).
# En la app se ven sin guiones y con mayuscula al principio de cada palabra: "Marvel Rivals Config".
$CfgUsuario = ($XucaRepo -split '/')[0]
$ColorAdic = '#F6AD55'
$spA = New-Object Windows.Controls.StackPanel
$filaA = New-Object Windows.Controls.DockPanel
$filaA.Margin = '2,0,0,12'
$bRecargar = Nuevo-Boton 'Recargar' ''
$bRecargar.Margin = '12,0,0,0'; $bRecargar.VerticalAlignment = 'Center'
$bRecargar.Add_Click({ Cargar-Configs $true })
[Windows.Controls.DockPanel]::SetDock($bRecargar, 'Right')
$filaA.Children.Add($bRecargar) | Out-Null
$avisoA = Nuevo-Texto 'Toca Descargar y se guarda en tu escritorio una carpeta con los archivos y las instrucciones para usarla.' 13 '#9AA0A6' $false
$avisoA.VerticalAlignment = 'Center'
$filaA.Children.Add($avisoA) | Out-Null
$spA.Children.Add($filaA) | Out-Null
$script:CfgFijos = $spA.Children.Count
$script:CfgCargadas = $false
$script:CfgRun = $null
$script:CfgBoton = $null
$Paginas.Adicional = $spA


# --- Pagina Apps recomendadas: programas gratis que recomiendo, con su descarga oficial ---
$ColorApps = '#BEF264'
$AppsRec = @(
    [pscustomobject]@{ Sec = 'Discos y espacio'; Color = '#8FD3F4'; Icono = 0xEDA2; Nombre = 'CrystalDiskInfo'; Critica = $true; Url = 'https://sourceforge.net/projects/crystaldiskinfo/files/9.9.2/CrystalDiskInfo9_9_2Ads.exe/download'
        Texto = 'revisa la salud y la temperatura de tus discos y SSD, y te avisa si alguno esta por fallar, antes de que pierdas tus archivos.' },
    [pscustomobject]@{ Sec = 'Discos y espacio'; Color = '#8FD3F4'; Icono = 0xE8B7; Nombre = 'WizTree'; Critica = $false; Url = 'https://diskanalyzer.com/files/wiztree_4_33_setup.exe'
        Texto = 'analiza tu disco en segundos y te muestra con colores que archivos y carpetas te estan comiendo el espacio.' },
    [pscustomobject]@{ Sec = 'Limpieza y arranque'; Color = '#F9A8D4'; Icono = 0xE74D; Nombre = 'Bulk Crap Uninstaller (BCU)'; Critica = $false; Url = 'https://sourceforge.net/projects/bulk-crap-uninstaller/files/latest/download'
        Texto = 'desinstala programas de forma limpia y borra los archivos basura y las entradas del registro que dejan los desinstaladores normales.' },
    [pscustomobject]@{ Sec = 'Limpieza y arranque'; Color = '#F9A8D4'; Icono = 0xE7E8; Nombre = 'Autoruns (Sysinternals)'; Critica = $false; Url = 'https://download.sysinternals.com/files/Autoruns.zip'
        Texto = 'te muestra todo lo que arranca con Windows y te deja apagarlo. Lo mejor para que la PC prenda mas rapido y para encontrar malware escondido.' },
    [pscustomobject]@{ Sec = 'Limpieza y arranque'; Color = '#F9A8D4'; Icono = 0xE785; Nombre = 'LockHunter'; Critica = $false; Url = 'https://lockhunter.com/startdownload.htm'
        Texto = 'desbloquea y borra los archivos que Windows no te deja borrar porque "estan siendo usados por otro programa".' },
    [pscustomobject]@{ Sec = 'Hardware y temperaturas'; Color = '#E5B567'; Icono = 0xE9D9; Nombre = 'HWiNFO'; Critica = $false; Url = 'https://www.hwinfo.com/download/'
        Texto = 'muestra en detalle temperaturas, voltajes y ventiladores. Esencial para saber si tu PC se esta calentando de mas.' },
    [pscustomobject]@{ Sec = 'Hardware y temperaturas'; Color = '#E5B567'; Icono = 0xE946; Nombre = 'CPU-Z'; Critica = $false; Url = 'https://download.cpuid.com/cpu-z/cpu-z_3.01-en.exe'
        Texto = 'te dice el modelo exacto de tu procesador, tu placa madre y tu memoria RAM. Muy util para saber que tenes adentro de la PC.' },
    [pscustomobject]@{ Sec = 'Hardware y temperaturas'; Color = '#E5B567'; Icono = 0xE945; Nombre = 'OCCT'; Critica = $false; Url = 'https://www.ocbase.com/download/edition:Personal/os:Windows'
        Texto = 'pone al maximo el procesador, la placa de video o la fuente para probarlos. Ideal para saber por que la PC se apaga sola o da pantallazos azules.' },
    [pscustomobject]@{ Sec = 'Hardware y temperaturas'; Color = '#E5B567'; Icono = 0xEC4A; Nombre = 'Cinebench'; Critica = $false; Url = 'https://www.maxon.net/en/cinebench'
        Texto = 'mide la potencia de tu procesador con un benchmark y te deja comparar tu puntaje con el de otras PCs.' },
    [pscustomobject]@{ Sec = 'Juegos y video'; Color = '#C58AF9'; Icono = 0xE7F4; Nombre = 'DDU (Display Driver Uninstaller)'; Critica = $false; Url = 'https://download.wagnardsoft.com/DDU/DDU%20v18.1.6.0_setup.exe'
        Texto = 'borra por completo el driver de tu placa de video. La solucion cuando los juegos dan tirones o hay problemas de video despues de cambiar de driver.' },
    [pscustomobject]@{ Sec = 'Juegos y video'; Color = '#C58AF9'; Icono = 0xE7FC; Nombre = 'SCSKiller'; Critica = $false; Url = 'https://github.com/BlueHeisenberg/SCSKiller/releases/'
        Texto = 'compila antes de jugar los shaders del juego que elijas, asi no da tirones ni bajones de FPS en las primeras partidas. Anda con NVIDIA y AMD.' },
    [pscustomobject]@{ Sec = 'Otros'; Color = '#8AB4F8'; Icono = 0xE896; Nombre = 'LIII BitTorrent Client'; Critica = $false; Url = 'https://github.com/aliakseis/LIII/releases/download/0.1.1.20/LIII_setup.exe'
        Texto = 'cliente de torrent liviano, minimalista y de codigo abierto, sin publicidad ni programas de mas como uTorrent.' }
)

function Nueva-AppRec($a) {
    $card = Nueva-Caja
    $col = Color-Tema($a.Color)
    $card.Tag.Color = $col; $card.Tag.Reposo = 40
    $card.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(40, $col.R, $col.G, $col.B))
    $g = New-Object Windows.Controls.Grid
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $g.ColumnDefinitions.Add($c0); $g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    # Cuadradito de color con el icono
    $badge = New-Object Windows.Controls.Border
    $badge.Width = 40; $badge.Height = 40; $badge.CornerRadius = 10; $badge.VerticalAlignment = 'Top'; $badge.Margin = '0,2,14,0'
    $badge.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(46, $col.R, $col.G, $col.B))
    $ic = New-Object Windows.Controls.TextBlock
    $ic.Text = [string][char]$a.Icono; $ic.FontFamily = 'Segoe MDL2 Assets'; $ic.FontSize = 18; $ic.Foreground = (Pincel $a.Color)
    $ic.HorizontalAlignment = 'Center'; $ic.VerticalAlignment = 'Center'
    $badge.Child = $ic
    $g.Children.Add($badge) | Out-Null
    $sp = New-Object Windows.Controls.StackPanel
    [Windows.Controls.Grid]::SetColumn($sp, 1)
    # Nombre con sus etiquetas (Gratis y, si hace falta, Prioridad critica)
    $tit = New-Object Windows.Controls.WrapPanel
    $nom = Nuevo-Texto '' 15 '#FFFFFF' $true; $nom.Text = $a.Nombre; $nom.VerticalAlignment = 'Center'
    $tit.Children.Add($nom) | Out-Null
    $etiquetas = New-Object Collections.ArrayList
    [void]$etiquetas.Add(@('Gratis', '#1E3A2C', '#81C995'))
    if ($a.Critica) { [void]$etiquetas.Add(@('Prioridad critica', '#3A1E1E', '#F28B82')) }
    foreach ($et in $etiquetas) {
        $pl = New-Object Windows.Controls.Border
        $pl.CornerRadius = 8; $pl.Padding = '8,1,8,2'; $pl.Margin = '8,0,0,0'; $pl.VerticalAlignment = 'Center'; $pl.Background = (Pincel $et[1])
        $pl.Child = (Nuevo-Texto $et[0] 11 $et[2] $true)
        $tit.Children.Add($pl) | Out-Null
    }
    $sp.Children.Add($tit) | Out-Null
    $d = Nuevo-Texto ($a.Texto.Substring(0, 1).ToUpper() + $a.Texto.Substring(1)) 12.5 '#C3C8D0' $false
    $d.Margin = '0,4,0,0'; $d.LineHeight = 19
    $sp.Children.Add($d) | Out-Null
    $fila = New-Object Windows.Controls.WrapPanel
    $b = Nuevo-Boton 'Descargar' '#4D7C0F'
    $b.Tag = $a
    $b.Add_Click({
        $x = $this.Tag
        try { Abrir-Normal $x.Url; $ui.Estado.Text = (Con-Enie ('Se abrio la descarga de ' + $x.Nombre + ' en tu navegador.')) }
        catch { Avisar 'Descargar' 'No se pudo abrir el navegador.' }
    })
    $fila.Children.Add($b) | Out-Null
    # De donde se baja (para que se vea que es la pagina oficial)
    $host0 = ''
    try { $host0 = ([Uri]$a.Url).Host -replace '^(www|download|downloads)\.', '' } catch { }
    if ($host0) {
        $de = Nuevo-Texto ('Desde: ' + $host0) 11.5 '#7D8590' $false
        $de.VerticalAlignment = 'Bottom'; $de.Margin = '4,0,0,8'
        $fila.Children.Add($de) | Out-Null
    }
    $sp.Children.Add($fila) | Out-Null
    $g.Children.Add($sp) | Out-Null
    $card.Child = $g
    return $card
}

$spApps = New-Object Windows.Controls.StackPanel
$avisoApps = Nuevo-Texto 'Toca Descargar y se abre la descarga oficial en tu navegador. Despues lo instalas como cualquier programa.' 13 '#9AA0A6' $false
$avisoApps.Margin = '2,0,0,4'
$spApps.Children.Add($avisoApps) | Out-Null
$secApp = ''
foreach ($ap in $AppsRec) {
    if ($ap.Sec -ne $secApp) { $secApp = $ap.Sec; $spApps.Children.Add((Nueva-Seccion $secApp)) | Out-Null }
    $spApps.Children.Add((Nueva-AppRec $ap)) | Out-Null
}
$Paginas.Apps = $spApps


# --- Pagina de bienvenida: es la que se ve al abrir la app. No tiene boton: desde aca elegis una seccion a la izquierda ---
$spI = New-Object Windows.Controls.StackPanel

function Inicio-Caja([string]$titulo, $hijo) {
    $c = Nueva-Caja
    $sp = New-Object Windows.Controls.StackPanel
    if ($titulo) {
        $t = Nuevo-Texto $titulo 15 '#FFFFFF' $true
        $t.Margin = '0,0,0,10'
        $sp.Children.Add($t) | Out-Null
    }
    $sp.Children.Add($hijo) | Out-Null
    $c.Child = $sp
    return $c
}

# Una fila con un circulito o cuadradito de color a la izquierda y el texto al lado
function Inicio-Fila([string]$marca, [bool]$esIcono, [string]$color, [string]$nombre, [string]$texto) {
    $g = New-Object Windows.Controls.Grid
    $g.Margin = '0,0,0,10'
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $g.ColumnDefinitions.Add($c0); $g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $col = Color-Tema($color)
    $b = New-Object Windows.Controls.Border
    $b.Width = 30; $b.Height = 30; $b.VerticalAlignment = 'Top'; $b.Margin = '0,0,12,0'
    $b.CornerRadius = $(if ($esIcono) { 8 } else { 15 })
    $b.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(46, $col.R, $col.G, $col.B))
    $m = New-Object Windows.Controls.TextBlock
    $m.Text = $marca; $m.Foreground = (Pincel $color); $m.HorizontalAlignment = 'Center'; $m.VerticalAlignment = 'Center'
    if ($esIcono) { $m.FontFamily = 'Segoe MDL2 Assets'; $m.FontSize = 14 } else { $m.FontSize = 13; $m.FontWeight = 'Bold' }
    $b.Child = $m
    $g.Children.Add($b) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.LineHeight = 19; $d.VerticalAlignment = 'Center'
    $r1 = New-Object Windows.Documents.Run((Con-Enie $nombre)); $r1.Foreground = (Pincel '#FFFFFF'); $r1.FontWeight = 'SemiBold'
    $d.Inlines.Add($r1)
    if ($texto) { $d.Inlines.Add((New-Object Windows.Documents.Run((Con-Enie (' ' + $texto))))) }
    [Windows.Controls.Grid]::SetColumn($d, 1)
    $g.Children.Add($d) | Out-Null
    return $g
}

# Presentacion
$hola = New-Object Windows.Controls.StackPanel
$h1 = Nuevo-Texto 'Optimizador gratis para Windows 10 y 11.' 17 '#FFFFFF' $true
$hola.Children.Add($h1) | Out-Null
$h2 = Nuevo-Texto 'Saca lo que sobra de Windows, lo prepara para jugar con menos latencia y libera espacio. Antes de tocar nada, lee tu PC: lo que ya tenes aplicado lo marca, y lo que no es compatible queda en gris y se saltea solo. Cada opcion te explica que hace, que ganas y que perdes.' 13 '#C3C8D0' $false
$h2.Margin = '0,6,0,0'; $h2.LineHeight = 20
$hola.Children.Add($h2) | Out-Null
$cHola = Inicio-Caja '' $hola
Caja-Borde $cHola '#8AB4F8'
$spI.Children.Add($cHola) | Out-Null

# Como se usa
$pasos = New-Object Windows.Controls.StackPanel
$pasos.Children.Add((Inicio-Fila '1' $false '#8AB4F8' 'Elegi una seccion en la barra de la izquierda.' 'Si no sabes por donde empezar, anda a Perfiles.')) | Out-Null
$pasos.Children.Add((Inicio-Fila '2' $false '#C58AF9' 'Marca lo que quieras.' 'Toca cualquier parte de una opcion para marcarla. Lo que marques en Debloat y en Gaming se junta.')) | Out-Null
$pasos.Children.Add((Inicio-Fila '3' $false '#81C995' 'Toca Aplicar.' 'Antes te ofrece crear un punto de restauracion. Casi todo se deshace despues con Restablecer.')) | Out-Null
$spI.Children.Add((Inicio-Caja 'Como se usa' $pasos)) | Out-Null

# Que hay en cada seccion
$secs = New-Object Windows.Controls.StackPanel
$secs.Children.Add((Inicio-Fila ([string][char]0xE77B) $true '#8AB4F8' 'Perfiles:' 'combos listos, de Seguro a Full Optimizado, que se aplican con un toque.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE72E) $true '#81C995' 'Debloat y privacidad:' 'publicidad, telemetria, IA de Windows, apps basura y apps de inicio que no hacen falta.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE7FC) $true '#C58AF9' 'Optimizacion gaming:' 'mouse, prioridad y afinidad para tus juegos, energia, red, DNS y mas.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE74D) $true '#8FD3F4' 'Limpiar cache:' 'temporales, cache de Windows Update, shaders y otras cosas que ocupan espacio.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE90F) $true '#E5B567' 'Herramientas:' 'drivers recomendados, actualizar Windows, entrar sin contrasena y mas.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE7B8) $true '#BEF264' 'Apps recomendadas:' 'programas gratis para revisar, cuidar y limpiar tu PC.')) | Out-Null
$secs.Children.Add((Inicio-Fila ([string][char]0xE713) $true '#F6AD55' 'Configs recomendadas:' 'configs de juegos y apps que subo a GitHub, con sus instrucciones.')) | Out-Null
$spI.Children.Add((Inicio-Caja 'Que hay en cada seccion' $secs)) | Out-Null

# Antes de empezar
$ojo = New-Object Windows.Controls.StackPanel
$ojo.Children.Add((Inicio-Fila $Aviso $false '#E5B567' 'Las opciones en amarillo pueden dar problemas en algunas PCs.' 'Pasa el mouse por encima y te dice por que.')) | Out-Null
$ojo.Children.Add((Inicio-Fila ([string][char]0xE896) $true $ColorDrv 'Las opciones en violeta necesitan drivers.' 'Si te faltan, la app te avisa y te lleva a Herramientas a buscarlos.')) | Out-Null
$ojo.Children.Add((Inicio-Fila ([string][char]0xE838) $true '#9AA0A6' 'Todo lo que se cambia queda anotado.' 'Lo ves con "Abrir carpeta de logs", abajo a la izquierda.')) | Out-Null
$spI.Children.Add((Inicio-Caja 'Antes de empezar' $ojo)) | Out-Null

# Flechita que apunta a la barra de la izquierda
$fila = New-Object Windows.Controls.StackPanel
$fila.Orientation = 'Horizontal'; $fila.Margin = '4,4,0,8'
$fl = New-Object Windows.Controls.TextBlock
$fl.Text = [string][char]0xE72B; $fl.FontFamily = 'Segoe MDL2 Assets'; $fl.FontSize = 16; $fl.Foreground = (Pincel '#8AB4F8'); $fl.VerticalAlignment = 'Center'; $fl.Margin = '0,0,10,0'
$tfl = New-Object Windows.Media.TranslateTransform
$fl.RenderTransform = $tfl
$anFl = [Windows.Media.Animation.DoubleAnimation]::new(0, -7, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(650)))
$anFl.AutoReverse = $true; $anFl.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever; $anFl.EasingFunction = $script:Suave
$tfl.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, $anFl)
$fila.Children.Add($fl) | Out-Null
$fila.Children.Add((Nuevo-Texto 'Elegi una seccion a la izquierda para empezar.' 14 '#8AB4F8' $true)) | Out-Null
$spI.Children.Add($fila) | Out-Null
$Paginas.Inicio = $spI

# Corre aparte para que la ventana no se trabe: 'lista' lee los repos y 'bajar' descarga uno al escritorio
$CodigoCfg = @'
param($sync)
$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
function Pedir([string]$url, [int]$espera) {
    $rq = [Net.HttpWebRequest]::Create($url)
    $rq.Timeout = $espera; $rq.ReadWriteTimeout = $espera; $rq.UserAgent = 'XucaOP'
    return $rq.GetResponse()
}
try {
    if ($sync.Modo -eq 'lista') {
        $rs = Pedir ('https://api.github.com/users/' + $sync.Usuario + '/repos?per_page=100&nc=' + [DateTime]::UtcNow.Ticks) 8000
        try { $sr = New-Object IO.StreamReader($rs.GetResponseStream(), [Text.Encoding]::UTF8); $json = $sr.ReadToEnd() } finally { $rs.Close() }
        $lista = New-Object Collections.ArrayList
        foreach ($r in (ConvertFrom-Json $json)) {
            $n = [string]$r.name
            if ($r.fork -or ($n -notmatch '^[A-Za-z0-9]+(-[A-Za-z0-9]+)*-[Cc][Oo][Nn][Ff][Ii][Gg]$')) { continue }
            $partes = foreach ($p in ($n -split '-')) { $p.Substring(0, 1).ToUpper() + $p.Substring(1) }
            $rama = $(if ($r.default_branch) { [string]$r.default_branch } else { 'main' })
            [void]$lista.Add(@{ Repo = $n; Nombre = ($partes -join ' '); Desc = [string]$r.description; Rama = $rama })
        }
        $sync.Lista = @($lista | Sort-Object { $_.Nombre })
    } else {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('XucaCfg_' + [guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($tmp)
        try {
            $zip = Join-Path $tmp 'repo.zip'
            $rama = (@([string]$sync.Rama -split '/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
            $rs = Pedir ('https://github.com/' + $sync.Usuario + '/' + [uri]::EscapeDataString($sync.Repo) + '/archive/refs/heads/' + $rama + '.zip') 20000
            # Tope de 500 MB: una config nunca pesa tanto, asi no se llena el disco si algo sale mal
            $tope = 500MB
            try {
                $st = $rs.GetResponseStream(); $fs = [IO.File]::Create($zip)
                try {
                    $buf = New-Object byte[] 81920; $total = 0
                    while (($n = $st.Read($buf, 0, $buf.Length)) -gt 0) {
                        $total += $n
                        if ($total -gt $tope) { throw 'La config pesa demasiado.' }
                        $fs.Write($buf, 0, $n)
                    }
                } finally { $fs.Close() }
            } finally { $rs.Close() }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $sale = Join-Path $tmp 'x'
            $za = [IO.Compression.ZipFile]::OpenRead($zip)
            try { $suma = 0; foreach ($en in $za.Entries) { $suma += $en.Length }; if ($suma -gt (2 * $tope)) { throw 'La config pesa demasiado.' } } finally { $za.Dispose() }
            [IO.Compression.ZipFile]::ExtractToDirectory($zip, $sale)
            # El zip de GitHub trae todo adentro de una carpeta "Repo-main"
            $dentro = @(Get-ChildItem -LiteralPath $sale -Force)
            $origen = $(if (($dentro.Count -eq 1) -and $dentro[0].PSIsContainer) { $dentro[0].FullName } else { $sale })
            # Si ya hay una carpeta con ese nombre no se pisa: se agrega (2), (3)...
            $dest = Join-Path $sync.Escritorio $sync.Nombre; $k = 2
            while (Test-Path -LiteralPath $dest) { $dest = Join-Path $sync.Escritorio ($sync.Nombre + ' (' + $k + ')'); $k++ }
            Copy-Item -LiteralPath $origen -Destination $dest -Recurse -Force
            $sync.Carpeta = $dest
        } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
} catch { $sync.Error = $_.Exception.Message }
$sync.Listo = $true
'@

$cfgTimer = New-Object Windows.Threading.DispatcherTimer
$cfgTimer.Interval = [TimeSpan]::FromMilliseconds(100)

function Cfg-Iniciar($sync) {
    $sync.Usuario = $CfgUsuario; $sync.Listo = $false; $sync.Error = $null
    $ps = [powershell]::Create()
    [void]$ps.AddScript($CodigoCfg).AddArgument($sync)
    $script:CfgRun = @{ PS = $ps; Handle = $ps.BeginInvoke(); Sync = $sync }
    $bRecargar.IsEnabled = $false
    $cfgTimer.Start()
}

function Cfg-Limpiar {
    while ($spA.Children.Count -gt $script:CfgFijos) { $spA.Children.RemoveAt($spA.Children.Count - 1) }
}

# Cartel en el medio de la pagina (buscando, vacio o sin internet)
function Cfg-Mensaje([int]$icono, [string]$titulo, [string]$texto, [string]$color) {
    Cfg-Limpiar
    $card = Nueva-Caja
    $sp = New-Object Windows.Controls.StackPanel
    $sp.HorizontalAlignment = 'Center'; $sp.Margin = '0,18,0,18'
    $ic = New-Object Windows.Controls.TextBlock
    $ic.Text = [string][char]$icono; $ic.FontFamily = 'Segoe MDL2 Assets'; $ic.FontSize = 34; $ic.Foreground = (Pincel $color); $ic.HorizontalAlignment = 'Center'
    $sp.Children.Add($ic) | Out-Null
    $t1 = Nuevo-Texto $titulo 16 '#FFFFFF' $true
    $t1.HorizontalAlignment = 'Center'; $t1.TextAlignment = 'Center'; $t1.Margin = '0,10,0,0'
    $sp.Children.Add($t1) | Out-Null
    $t2 = Nuevo-Texto $texto 12.5 '#9AA0A6' $false
    $t2.HorizontalAlignment = 'Center'; $t2.TextAlignment = 'Center'; $t2.Margin = '0,4,0,0'; $t2.MaxWidth = 440
    $sp.Children.Add($t2) | Out-Null
    $card.Child = $sp
    $spA.Children.Add($card) | Out-Null
}

function Nueva-Config($c) {
    $card = Nueva-Caja
    # Borde naranja suave que se prende al pasar el mouse
    $col = Color-Tema($ColorAdic)
    $card.Tag.Color = $col; $card.Tag.Reposo = 50
    $card.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(50, $col.R, $col.G, $col.B))
    $g = New-Object Windows.Controls.Grid
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $g.ColumnDefinitions.Add($c0); $g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $badge = New-Object Windows.Controls.Border
    $badge.Width = 40; $badge.Height = 40; $badge.CornerRadius = 10; $badge.Background = (Pincel '#2EF6AD55'); $badge.VerticalAlignment = 'Top'; $badge.Margin = '0,2,14,0'
    $ic = New-Object Windows.Controls.TextBlock
    $ic.Text = [string][char]0xE713; $ic.FontFamily = 'Segoe MDL2 Assets'; $ic.FontSize = 18; $ic.Foreground = (Pincel $ColorAdic)
    $ic.HorizontalAlignment = 'Center'; $ic.VerticalAlignment = 'Center'
    $badge.Child = $ic
    $g.Children.Add($badge) | Out-Null
    $sp = New-Object Windows.Controls.StackPanel
    [Windows.Controls.Grid]::SetColumn($sp, 1)
    # El nombre y la descripcion se muestran tal cual estan en GitHub (sin traducir)
    $t1 = Nuevo-Texto '' 15 '#FFFFFF' $true; $t1.Text = $c.Nombre
    $sp.Children.Add($t1) | Out-Null
    if ($c.Desc) { $t2 = Nuevo-Texto '' 12.5 '#C3C8D0' $false; $t2.Text = $c.Desc }
    else { $t2 = Nuevo-Texto 'Sin descripcion.' 12.5 '#7D8590' $false }
    $t2.Margin = '0,4,0,0'; $t2.LineHeight = 19
    $sp.Children.Add($t2) | Out-Null
    $b = Nuevo-Boton 'Descargar en el escritorio' '#C27C0E'
    $b.HorizontalAlignment = 'Left'; $b.Tag = $c
    $b.Add_Click({ Bajar-Config $this })
    $sp.Children.Add($b) | Out-Null
    $g.Children.Add($sp) | Out-Null
    $card.Child = $g
    return $card
}

function Cargar-Configs([bool]$animar) {
    if ($script:CfgRun) { return }
    $script:CfgCargadas = $true
    Cfg-Mensaje 0xE895 'Buscando configs...' 'Revisando lo que hay subido en GitHub.' $ColorAdic
    if ($animar -and ($script:Pagina -eq 'Adicional')) { Desplegar $spA }
    Cfg-Iniciar ([hashtable]::Synchronized(@{ Modo = 'lista' }))
}

# Circulito verde del boton: siempre se ve (con 0 si no hay configs) y rebota cuando cambia el numero
function Poner-Insignia([int]$n) {
    if ($n -lt 0) { $n = 0 }
    $nuevo = ($ui.CfgInsigniaTxt.Text -ne [string]$n)
    $ui.CfgInsigniaTxt.Text = $(if ($n -gt 99) { '99+' } else { [string]$n })
    $ui.CfgInsignia.Visibility = 'Visible'
    if ($nuevo) {
        $rebote = New-Object Windows.Media.Animation.BackEase
        $rebote.EasingMode = 'EaseOut'; $rebote.Amplitude = 0.6
        foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
            $an = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(450)))
            $an.EasingFunction = $rebote
            $ui.CfgInsignia.RenderTransform.BeginAnimation($pr, $an)
        }
    }
}

function Mostrar-Configs($lista) {
    Cfg-Limpiar
    Poner-Insignia @($lista).Count
    if (@($lista).Count -eq 0) {
        Cfg-Mensaje 0xE8F1 'Vacio por ahora...' 'Todavia no subi ninguna config. Estoy armando las primeras: volve pronto que van a aparecer aca.' $ColorAdic
    } else {
        foreach ($c in @($lista)) { $spA.Children.Add((Nueva-Config $c)) | Out-Null }
    }
    if ($script:Pagina -eq 'Adicional') { Desplegar $spA }
}

function Bajar-Config($b) {
    if ($script:CfgRun) { Avisar 'Descargar config' 'Espera a que termine la descarga que esta en curso.'; return }
    $c = $b.Tag
    $script:CfgBoton = $b
    $b.IsEnabled = $false; $b.Content = (Con-Enie 'Descargando...')
    Cfg-Iniciar ([hashtable]::Synchronized(@{ Modo = 'bajar'; Repo = $c.Repo; Rama = $c.Rama; Nombre = $c.Nombre; Escritorio = [Environment]::GetFolderPath('Desktop') }))
}

$cfgTimer.Add_Tick({
    $u = $script:CfgRun
    if (-not $u) { $cfgTimer.Stop(); return }
    if (-not $u.Handle.IsCompleted) { return }
    $cfgTimer.Stop()
    $s = $u.Sync
    try { $u.PS.EndInvoke($u.Handle) | Out-Null } catch { if (-not $s.Error) { $s.Error = $_.Exception.Message } }
    try { $u.PS.Dispose() } catch { }
    $script:CfgRun = $null
    $bRecargar.IsEnabled = $true
    if ($s.Modo -eq 'lista') {
        if ($s.Error) {
            # Si fallo, al volver a entrar a la pagina se prueba de nuevo
            $script:CfgCargadas = $false
            Cfg-Mensaje 0xE783 'No se pudo conectar con GitHub' 'Revisa tu internet y toca Recargar.' '#F28B82'
            if ($script:Pagina -eq 'Adicional') { Desplegar $spA }
        } else { Mostrar-Configs $s.Lista }
        return
    }
    $b = $script:CfgBoton; $script:CfgBoton = $null
    if ($b) { $b.IsEnabled = $true; $b.Content = (Con-Enie 'Descargar en el escritorio') }
    if ($s.Error -or (-not $s.Carpeta)) { Avisar 'No se pudo descargar' 'No se pudo bajar la config. Revisa tu internet y proba de nuevo.'; return }
    Avisar 'Config descargada' ('Se guardo en tu escritorio, en esta carpeta:' + "`n`n" + (Split-Path $s.Carpeta -Leaf) + "`n`n" + 'Adentro estan los archivos y las instrucciones para usarla.')
    try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $s.Carpeta + '"') } catch { }
    # Si las instrucciones vienen en un .txt o .pdf, se abren tambien
    $ins = Get-ChildItem -LiteralPath $s.Carpeta -File -ErrorAction SilentlyContinue | Where-Object { ($_.Extension -in '.txt', '.pdf') -and ($_.BaseName -match '(?i)instruc|leeme|readme|guia') } | Select-Object -First 1
    if ($ins) { Abrir-Normal $ins.FullName }
})


function Actualizar-Version {
    $bld = 0
    try { $bld = [int](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'CurrentBuildNumber') } catch { }
    if ($bld -ge 26300) {
        $script:BtnVer.Content = (Con-Enie 'Actualizar a 26H2'); $script:BtnVer.IsEnabled = $false
        $script:VerTexto.Text = (Con-Enie ('Ya tenes la 26H2 o una build mas nueva (build ' + $bld + ').'))
    } elseif ($bld -ge 26100) {
        $script:BtnVer.Content = (Con-Enie 'Actualizar a 26H2'); $script:BtnVer.IsEnabled = $true
        $script:VerTexto.Text = (Con-Enie ('Tu build es ' + $bld + ' (24H2 o 25H2): la 26H2 te llega por Windows Update con un reinicio corto.'))
    } else {
        $script:BtnVer.Content = (Con-Enie 'Actualizar a 25H2'); $script:BtnVer.IsEnabled = $true
        $script:VerTexto.Text = (Con-Enie ('Tu build es ' + $bld + ': primero pasas a la 25H2 desde el ISO oficial; despues la 26H2 te llega por Windows Update.'))
    }
}


# --- Pagina de perfiles ---
$Perfiles = @(
    [pscustomobject]@{
        Id = 'seguro'; Nombre = 'Seguro (Debloat basico)'; Color = '#81C995'
        Hace = 'saca publicidad, sugerencias, Bing, telemetria, rastreo y Widgets, y apaga la IA de Windows; suma ajustes comodos para jugar que no tienen riesgo (sin carteles de Teclas especiales, sin bajar el volumen en llamadas, Modo Juego, menus sin retraso).'
        Ideal = 'cualquier PC, incluso la de alguien que no sabe de esto.'
        NoToca = 'la seguridad, las apps instaladas ni el procesador.'
        Adv = ''
        D = @('rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia')
        G = @('tk', 'du', 'gm', 'ext', 'md')
    },
    [pscustomobject]@{
        Id = 'comp'; Nombre = 'Competitivo'; Color = '#8AB4F8'
        Hace = 'lo maximo para jugar sin tocar la seguridad: mouse sin aceleracion, prioridad y afinidad para tus juegos, plan Alto rendimiento, Modo Nitro y baja latencia del procesador, temporizador al minimo, GPU por hardware, menos latencia de red, DNS mas rapido, sin Game Bar, sin Modo Xbox y sin notificaciones en partida.'
        Ideal = 'jugar competitivo (Valorant, CS2, Fortnite, Warzone, Marvel Rivals, LoL y Deadlock) con la PC protegida. Los antitrampas de esos juegos siguen andando.'
        NoToca = 'el antivirus, BitLocker, la integridad de memoria ni VBS; tampoco borra apps.'
        Adv = 'el plan Alto rendimiento y el temporizador al minimo suben el consumo y el calor; con undervolt u overclock la PC puede colgarse.'
        D = @()
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'll', 'gm', 'xb', 'xm', 'notif', 'gf', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'avl', 'md', 'v4')
    },
    [pscustomobject]@{
        Id = 'compopt'; Nombre = 'Competitivo + Optimizado'; Color = '#C58AF9'
        Hace = 'todo lo de Competitivo y lo de Seguro, y ademas borra las apps basura, apaga la hibernacion, los efectos visuales, los sonidos, servicios que casi nadie usa y el Storage Sense, y Windows Update deja de instalar drivers.'
        Ideal = 'la PC de juego de todos los dias: el mayor rendimiento con la PC todavia protegida.'
        NoToca = 'el antivirus, BitLocker, la integridad de memoria ni VBS.'
        Adv = 'borrar las apps basura no tiene restablecimiento: se reinstalan a mano desde la Store.'
        D = @('rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia', 'hib', 'fx', 'sch', 'sv', 'wud', 'db', 'ini')
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'll', 'gm', 'xb', 'notif', 'gf', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'avl', 'md', 'v4', 'ext', 'stg', 'xm')
    },
    [pscustomobject]@{
        Id = 'full'; Nombre = 'Full Optimizado'; Color = '#F28B82'
        Hace = 'Windows lo mas liviano posible: todo el debloat y la optimizacion del sistema, y ademas apaga la seguridad (antivirus, BitLocker, integridad de memoria y VBS), activa el modo MSI, bloquea la telemetria en hosts y apaga Teredo y Windows Search.'
        Ideal = 'una PC justa o vieja que necesita todo el rendimiento del sistema, sabiendo lo que haces.'
        NoToca = 'los ajustes de juego competitivo (mouse, prioridad, afinidad, plan de energia, temporizador y red), ni Edge ni Chrome. Crea un punto de restauracion antes de empezar.'
        Adv = 'la PC queda sin antivirus. Borra Riot Vanguard y cierra Riot (lo reinstalas abriendo el cliente de Riot), y deja de andar WSL, Docker y las maquinas virtuales.'
        D = @('rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia', 'hib', 'fx', 'sch', 'sv', 'wud', 'db', 'av', 'bl', 'hst', 'ter', 'ini')
        G = @('tk', 'du', 'gm', 'ext', 'md', 'mm', 'll', 'xb', 'gf', 'pca', 'ram', 'sm', 'stg', 'msi', 'mi', 'vbs', 'wsr')
    },
    [pscustomobject]@{
        Id = 'fullcomp'; Nombre = 'Full Optimizado + Competitivo'; Color = '#FF6B6B'
        Hace = 'todo, todo: cada opcion de Debloat y de Gaming. Es Full Optimizado mas todos los ajustes competitivos (mouse, prioridad y afinidad para tus juegos, plan Alto rendimiento, Modo Nitro, temporizador al minimo, red, DNS y notificaciones).'
        Ideal = 'una PC que es solo para jugar, donde queres el maximo absoluto y sabes lo que haces.'
        NoToca = 'Edge ni Chrome. No apaga los puntos de restauracion: crea uno antes de empezar.'
        Adv = 'suma los riesgos de Full Optimizado y de Competitivo: sin antivirus, Vanguard se borra (lo reinstalas abriendo el cliente de Riot), y con undervolt u overclock la PC puede colgarse por el plan de energia y el temporizador.'
        D = @('av', 'bl', 'hib', 'rc', 'sch', 'fx', 'et', 'apps', 'tel', 'wg', 'do', 'wud', 'wup', 'ad', 'sv', 'pv', 'ter', 'tp', 'hst', 'eb', 'su', 'ia', 'db', 'ini')
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'll', 'gm', 'xb', 'notif', 'gf', 'mpo', 'msi', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'mi', 'vbs', 'wsr', 'stg', 'ext', 'md', 'v4', 'xm')
    }
)

$spP = New-Object Windows.Controls.StackPanel
$script:InfoPC = Nuevo-Texto 'Tu PC: leyendo...' 13 '#9AA0A6' $false
$script:InfoPC.Margin = '2,0,0,12'
$spP.Children.Add($script:InfoPC) | Out-Null
$script:PerfilTxt = @{}
foreach ($pf in $Perfiles) {
    $card = Nueva-Caja
    $card.BorderBrush = (Pincel $pf.Color); $card.BorderThickness = '4,0,0,0'; $card.Tag = $null
    $sp = New-Object Windows.Controls.StackPanel
    $tit = New-Object Windows.Controls.StackPanel
    $tit.Orientation = 'Horizontal'
    $tit.Children.Add((Nuevo-Texto $pf.Nombre 17 '#FFFFFF' $true)) | Out-Null
    if ($pf.Id -like 'full*') {
        $porque = ('Tiene la alerta porque apaga el antivirus (Defender, SmartScreen y Smart App Control): la PC queda sin proteccion contra virus.' + "`n" + 'Tambien apaga BitLocker, la integridad de memoria y VBS, y desinstala Riot Vanguard (lo reinstalas abriendo el cliente de Riot).')
        $ic = Nuevo-Texto $Aviso 17 '#E5B567' $true
        $ic.FontFamily = 'Segoe UI Symbol'; $ic.Margin = '8,0,0,0'
        $tit.Children.Add($ic) | Out-Null
        $card.ToolTip = (Con-Enie $porque)
        [Windows.Controls.ToolTipService]::SetShowDuration($card, 30000)
    }
    $sp.Children.Add($tit) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.Margin = '0,6,0,0'; $d.LineHeight = 19
    Agregar-Linea $d 'Que hace: ' '#8AB4F8' $pf.Hace
    Agregar-Linea $d 'Ideal para: ' '#81C995' $pf.Ideal
    Agregar-Linea $d 'No toca: ' '#9AA0A6' $pf.NoToca
    if ($pf.Adv) { Agregar-Linea $d ($Aviso + ' Ojo: ') '#E5B567' $pf.Adv }
    $sp.Children.Add($d) | Out-Null
    $cuenta = Nota '' '#7D8590' '0,8,0,0'
    $script:PerfilTxt[$pf.Id] = $cuenta
    $sp.Children.Add($cuenta) | Out-Null
    $fila = New-Object Windows.Controls.WrapPanel
    $bA = Nuevo-Boton 'Aplicar perfil' $(if ($pf.Id -like 'full*') { '#B3412F' } else { '#3D6FD9' })
    $bA.Tag = $pf.Id
    $bA.Add_Click({ Aplicar-Perfil ([string]$this.Tag) })
    $bR = Nuevo-Boton 'Marcar y revisar'
    $bR.Tag = $pf.Id
    $bR.Add_Click({
        if (-not (Perfil-ConDrivers (Perfil-De ([string]$this.Tag)))) { return }
        if ((Marcar-Perfil ([string]$this.Tag)) -gt 0) { Ir-A $(if ((Elegidas 'Gaming').Count -gt (Elegidas 'Debloat').Count) { 'Gaming' } else { 'Debloat' }) }
    })
    $fila.Children.Add($bA) | Out-Null
    $fila.Children.Add($bR) | Out-Null
    $sp.Children.Add($fila) | Out-Null
    $card.Child = $sp
    $spP.Children.Add($card) | Out-Null
}
$Paginas.Perfiles = $spP

function Perfil-De([string]$id) { return @($Perfiles | Where-Object { $_.Id -eq $id })[0] }

# Cuenta que va a marcar cada perfil: lo que falta aplicar, lo que ya tenes y lo que no es compatible
function Actualizar-Perfiles {
    foreach ($pf in $Perfiles) {
        $falta = 0; $ya = 0; $nd = 0
        foreach ($par in @(@('Debloat', $pf.D), @('Gaming', $pf.G))) {
            foreach ($id in $par[1]) {
                $k = $par[0] + '|' + $id
                if (-not $script:Tarjetas.ContainsKey($k)) { continue }
                if ($script:NoDisp.ContainsKey($k)) { $nd++ }
                elseif ($script:Estados[$k] -eq $true) { $ya++ }
                else { $falta++ }
            }
        }
        $t = ([string]$falta + ' por aplicar')
        if ($ya -gt 0) { $t += (', ' + $ya + ' ya aplicadas') }
        if ($nd -gt 0) { $t += (', ' + $nd + ' no compatibles con tu PC') }
        $script:PerfilTxt[$pf.Id].Text = (Con-Enie ('Opciones: ' + $t + '.'))
    }
}

function Actualizar-InfoPC($i) {
    # Aviso rojo arriba (se ve en todas las paginas) si el Windows parece no original o modificado
    $mot = @()
    if ($i -and $i.Orig) { $mot = @($i.Orig) }
    if ($mot.Count -gt 0) {
        $m = $mot[0].Substring(0, 1).ToUpper() + $mot[0].Substring(1)
        if ($mot.Count -gt 1) { $m += '; ' + (($mot | Select-Object -Skip 1) -join '; ') }
        $ui.OrigTexto.Text = (Con-Enie ('Motivo: ' + $m + '.' + "`n" + 'En versiones recortadas, pirateadas o modificadas (Tiny11, AtlasOS, ReviOS y similares) varias opciones pueden fallar o no aplicar.'))
        $ui.OrigBarra.Visibility = 'Visible'
    } else { $ui.OrigBarra.Visibility = 'Collapsed' }
    if (-not $i) { $script:InfoPC.Text = (Con-Enie 'Tu PC: no se pudo leer.'); return }
    $nombre = $(if ([int]$i.Build -ge 22000) { 'Windows 11' } else { 'Windows 10' })
    $ed = switch -Regex ([string]$i.Edicion) { '^Core' { 'Home' } '^Professional' { 'Pro' } '^Enterprise' { 'Enterprise' } '^Education' { 'Education' } default { [string]$i.Edicion } }
    $t = ('Tu PC: ' + $nombre + ' ' + $ed + ' ' + $i.Display + ' (build ' + $i.Build + ')')
    if ([int]$i.RamGB -gt 0) { $t += ('  -  ' + $i.RamGB + ' GB de RAM') }
    $t += $(if ($i.Hdd) { '  -  Windows en disco HDD' } else { '' })
    if ($script:NoDisp.Count -eq 1) { $t += '  -  1 opcion no es compatible: queda en gris y se saltea sola' }
    elseif ($script:NoDisp.Count -gt 1) { $t += ('  -  ' + $script:NoDisp.Count + ' opciones no son compatibles: quedan en gris y se saltean solas') }
    if ($mot.Count -gt 0) { $t += '  -  Windows modificado o no original (mira el aviso rojo de arriba)' }
    $script:InfoPC.Text = (Con-Enie $t)
}

# Marca solo las opciones del perfil (desmarca el resto). Saltea lo no compatible y lo que ya esta aplicado.
# Devuelve cuantas marco.
# Opciones del perfil que se van a aplicar y necesitan un driver que te falta
function Faltan-Perfil($pf) {
    $r = @()
    foreach ($par in @(@('Debloat', $pf.D), @('Gaming', $pf.G))) {
        foreach ($oid in $par[1]) {
            $k = $par[0] + '|' + $oid
            if ($script:NoDisp.ContainsKey($k) -or ($script:Estados[$k] -eq $true)) { continue }
            if ($script:DrvFalta.ContainsKey($k)) { $r += $k }
        }
    }
    return $r
}

# Antes de marcar o aplicar un perfil: si le faltan drivers, avisa y te manda a Herramientas. Devuelve $true si se puede seguir.
function Perfil-ConDrivers($pf) {
    $f = @(Faltan-Perfil $pf)
    if ($f.Count -eq 0) { return $true }
    Pedir-Drivers $f ('El perfil "' + $pf.Nombre + '" tiene ajustes que necesitan drivers que te faltan. Antes de seguir, instalalos:')
    return $false
}

function Marcar-Perfil([string]$id) {
    $pf = Perfil-De $id
    foreach ($p in 'Debloat', 'Gaming') { foreach ($cb in $Casillas[$p].Values) { $cb.IsChecked = $false } }
    $n = 0
    foreach ($par in @(@('Debloat', $pf.D), @('Gaming', $pf.G))) {
        foreach ($oid in $par[1]) {
            $k = $par[0] + '|' + $oid
            $cb = $Casillas[$par[0]][$oid]
            if (-not $cb) { continue }
            if ($script:NoDisp.ContainsKey($k) -or ($script:Estados[$k] -eq $true)) { continue }
            $cb.IsChecked = $true; $n++
        }
    }
    Actualizar-Bloqueos
    $n = (Elegidas 'Debloat').Count + (Elegidas 'Gaming').Count
    Actualizar-Contador
    if ($n -eq 0) { Avisar $pf.Nombre 'Ya tenes todo este perfil aplicado (o lo que falta no es compatible con tu PC).' }
    return $n
}

function Aplicar-Perfil([string]$id) {
    $pf = Perfil-De $id
    if (-not (Perfil-ConDrivers $pf)) { return }
    if ($id -like 'full*') {
        if (-not (Confirmar ($Aviso + ' ' + $pf.Nombre) ('Este perfil apaga el antivirus, BitLocker, la integridad de memoria y VBS. La PC queda sin proteccion contra virus.' + "`n`n" + 'Seguir?') 'Si, aplicar' '#B3412F' 'Cancelar')) { return }
    }
    if ((Marcar-Perfil $id) -eq 0) { return }
    Aplicar-Seleccion
}

$IconosPag = @{ Inicio = 0xE80F; Perfiles = 0xE77B; Debloat = 0xE72E; Gaming = 0xE7FC; Limpieza = 0xE74D; Herr = 0xE90F; Apps = 0xE7B8; Adicional = 0xE713 }
$Textos = @{
    Inicio    = @('Bienvenido a Xuca OPtimizer', 'Que hace la app y como se usa. Cuando quieras, elegi una seccion a la izquierda.')
    Perfiles  = @('Perfiles', 'Elegi un perfil armado: aplicalo con un toque, o marcalo para revisar y ajustar las opciones antes de aplicar. Lo que no es compatible con tu PC o ya tenes aplicado se saltea solo.')
    Debloat   = @('Debloat y privacidad', 'Lo que se puede sacar o apagar de Windows. Lo que marques aca y en Gaming se aplica junto con un solo Aplicar.')
    Gaming    = @('Optimizacion gaming', 'Ajustes para mas FPS y menos latencia. Lo que marques aca y en Debloat se aplica junto con un solo Aplicar.')
    Limpieza  = @('Limpiar cache', 'Libera espacio. Lo de arriba se limpia siempre; lo de abajo solo si lo marcas.')
    Herr      = @('Herramientas', 'Opciones que te piden datos en la ventana del script.')
    Apps      = @('Apps recomendadas', 'Programas gratis que recomiendo para cuidar, revisar y limpiar tu PC. Cada uno se baja de su pagina oficial.')
    Adicional = @('Configs recomendadas', 'Configs de juegos y apps que subo a GitHub. Toca una y se descarga en tu escritorio con sus instrucciones.')
}
$Nav = @{ Perfiles = $ui.NavPerfiles; Debloat = $ui.NavDebloat; Gaming = $ui.NavGaming; Limpieza = $ui.NavLimpieza; Herr = $ui.NavHerr; Apps = $ui.NavApps; Adicional = $ui.NavAdicional }
$script:Pagina = 'Debloat'
$script:Ocupado = $false

# Paginas donde se ve el mensaje de "Windows leido" (las que tienen ajustes)
$PagAjustes = @('Debloat', 'Gaming', 'Perfiles')
$script:LeidoPag = $null
function No-Compatibles([int]$n) {
    if ($n -le 0) { return '' }
    if ($n -eq 1) { return ' 1 no es compatible con tu PC.' }
    return (' ' + $n + ' no son compatibles con tu PC.')
}
# En Debloat y Gaming cuenta solo las opciones de esa pagina; en Perfiles, todas
function Texto-Leido([string]$p) {
    if (-not $script:EstadoLeido) { return '' }
    $c = $null
    if ($script:LeidoPag) { $c = $script:LeidoPag[$p] }
    if (-not $c) { return (Con-Enie $script:EstadoLeido) }
    $t = 'Windows leido: ' + $c.A + ' ' + (Con-Enie 'de') + ' ' + $c.T + ' opciones de esta pagina ya estan aplicadas.' + (No-Compatibles $c.N)
    return (Con-Enie $t)
}

function Elegidas([string]$p) {
    return @($Casillas[$p].Keys | Where-Object { $Casillas[$p][$_].IsChecked -eq $true })
}

function Actualizar-Contador {
    Actualizar-Bloqueos
    if ($script:Ocupado) { return }
    if ($script:Pagina -notin $PagAjustes) { $ui.Estado.Text = ''; return }
    $d = (Elegidas 'Debloat').Count; $g = (Elegidas 'Gaming').Count
    if (($d + $g) -eq 0) { $t = Texto-Leido $script:Pagina; $ui.Estado.Text = $(if ($t) { $t } else { (Con-Enie 'No hay opciones marcadas.') }) }
    else { $ui.Estado.Text = (Con-Enie ('Marcadas: ' + $d + ' en Debloat y ' + $g + ' en Gaming. Se guardan aunque cambies de pagina.')) }
}

# Fondo sin elegir, fondo elegido, texto sin elegir, texto elegido
$NavColores = @{ Apps = @('#182008', '#263512', '#BEF264', '#E3FBB0'); Adicional = @('#221A0E', '#3A2A12', '#F6AD55', '#FFD08A') }
if ($script:Claro) { $NavColores = @{ Apps = @('#F1FAE0', '#DCF0BC', '#4D7C0F', '#365314'); Adicional = @('#FDF2E4', '#FAE2C4', '#C2410C', '#9A3412') } }
function Ir-A([string]$p) {
    $script:Pagina = $p
    foreach ($k in $Nav.Keys) {
        # Apps recomendadas (lima) y Configs (naranja) tienen su color propio
        $cp = $NavColores[$k]
        if ($cp) {
            $Nav[$k].Background = (Pincel $(if ($k -eq $p) { $cp[1] } else { $cp[0] }))
            $Nav[$k].Foreground = (Pincel $(if ($k -eq $p) { $cp[3] } else { $cp[2] }))
            $Nav[$k].BorderBrush = (Pincel $cp[2])
            continue
        }
        $Nav[$k].Background = (Pincel $(if ($k -eq $p) { '#1F2D4A' } else { '#00000000' }))
        $Nav[$k].Foreground = (Pincel $(if ($k -eq $p) { '#FFFFFF' } else { '#C9CDD4' }))
    }
    $ui.Titulo.Text = (Con-Enie $Textos[$p][0])
    Marcar-OP $ui.Titulo
    $ui.TituloIcono.Text = [string][char]($IconosPag[$p])
    # El recuadro del titulo entra suave desde la izquierda
    $a1 = [Windows.Media.Animation.DoubleAnimation]::new(0, 1, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(260)))
    $a1.EasingFunction = $script:Suave
    $ui.TituloCaja.BeginAnimation([Windows.UIElement]::OpacityProperty, $a1)
    $a2 = [Windows.Media.Animation.DoubleAnimation]::new(-12, 0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(320)))
    $a2.EasingFunction = $script:Suave
    $ui.TituloCaja.RenderTransform.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, $a2)
    $ui.Descripcion.Text = (Con-Enie $Textos[$p][1])
    # Un poco de margen a los costados para que las cajas no se corten cuando crecen con el mouse
    $Paginas[$p].Margin = '10,4,12,8'
    # La primera vez que entras a Adicional se buscan las configs en GitHub
    if (($p -eq 'Adicional') -and (-not $script:CfgCargadas)) { Cargar-Configs $false }
    $ui.Scroll.Content = $Paginas[$p]
    $ui.Scroll.ScrollToTop()
    Desplegar $Paginas[$p]
    $vis = $(if ($p -in 'Inicio', 'Herr', 'Perfiles', 'Apps', 'Adicional') { 'Collapsed' } else { 'Visible' })
    $ui.BtnTodo.Visibility = $vis; $ui.BtnNada.Visibility = $vis
    $ui.BtnSeguras.Visibility = $(if ($p -in 'Debloat', 'Gaming') { 'Visible' } else { 'Collapsed' })
    $ui.BtnAplicar.Content = (Con-Enie $(if ($p -eq 'Limpieza') { 'Limpiar ahora' } else { 'Aplicar seleccionadas' }))
    Actualizar-BotonesAccion
    # El mensaje de abajo cambia con la pagina (solo se ve donde hay ajustes)
    if ($script:Leido -and (-not $script:Ocupado)) { Actualizar-Contador }
    # Windows se lee una sola vez por cada vez que abris la app: la primera vez que entras a una pagina de ajustes
    if (($p -in $PagAjustes) -and (-not $script:Leido) -and (-not $script:Lectura) -and (-not $script:Ocupado)) { Refrescar-Estado }
}

function Bloquear([bool]$si) {
    $script:Ocupado = $si
    foreach ($b in @($ui.NavPerfiles, $ui.NavDebloat, $ui.NavGaming, $ui.NavLimpieza, $ui.NavHerr, $ui.NavApps, $ui.NavAdicional, $ui.BtnRefrescar, $ui.BtnSeguras, $ui.BtnTodo, $ui.BtnNada, $ui.BtnRestablecer, $ui.BtnAplicar)) { $b.IsEnabled = -not $si }
    $ui.Scroll.IsEnabled = -not $si
    if (-not $si) { Actualizar-BotonesAccion }
}

# ------------------------------------------------------------
# Pantalla de carga (barra que se llena suave y se desvanece al terminar)
# ------------------------------------------------------------
$AnchoBarra = 440
$script:Carga = @{ Objetivo = 0.0; Mostrado = 0.0; Cerrar = $false; AlCerrar = $null }
$animTimer = New-Object Windows.Threading.DispatcherTimer
$animTimer.Interval = [TimeSpan]::FromMilliseconds(15)
$animTimer.Add_Tick({
    $c = $script:Carga
    $d = $c.Objetivo - $c.Mostrado
    if ([math]::Abs($d) -lt 0.002) { $c.Mostrado = $c.Objetivo } else { $c.Mostrado = $c.Mostrado + [math]::Max($d * 0.12, [math]::Min($d, 0.002)) }
    $ui.CargaBarra.Width = $AnchoBarra * $c.Mostrado
    $ui.CargaPct.Text = ([string][int][math]::Floor($c.Mostrado * 100)) + '%'
    if ($c.Cerrar -and ($c.Mostrado -ge 0.999)) {
        $c.Cerrar = $false
        $animTimer.Stop()
        Desvanecer-Carga
    }
})

# Intro: la tarjeta arranca invisible y chica, y crece hasta su tamano con un pequeno rebote.
# Despues aparece lo de adentro, de a una cosa por vez, subiendo un poco.
function Intro-Carga {
    $cj = $ui.CargaCaja
    $rebote = New-Object Windows.Media.Animation.BackEase
    $rebote.EasingMode = 'EaseOut'; $rebote.Amplitude = 0.3
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $an = [Windows.Media.Animation.DoubleAnimation]::new(0.6, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(700)))
        $an.EasingFunction = $rebote
        $cj.RenderTransform.BeginAnimation($pr, $an)
    }
    $op = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(500)))
    $op.EasingFunction = $script:Suave
    $cj.BeginAnimation([Windows.UIElement]::OpacityProperty, $op)
    $n = 0
    foreach ($h in @($cj.Child.Children)) {
        if ($h.Visibility -ne 'Visible') { continue }
        if (-not ($h.RenderTransform -is [Windows.Media.TranslateTransform])) { $h.RenderTransform = New-Object Windows.Media.TranslateTransform }
        $espera = [TimeSpan]::FromMilliseconds(200 + $n * 90)
        $fin = $espera + [TimeSpan]::FromMilliseconds(380)
        $a = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $a.FillBehavior = 'Stop'
        [void]$a.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero)))
        [void]$a.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($espera)))
        [void]$a.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new(1.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $script:Suave))
        $h.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
        $y = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $y.FillBehavior = 'Stop'
        [void]$y.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(14.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero)))
        [void]$y.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(14.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($espera)))
        [void]$y.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $script:Suave))
        $h.RenderTransform.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $y)
        $n++
    }
}

# Al abrir la app la tarjeta muestra solo la marca, grande. Las demas cargas usan la tarjeta completa.
function Modo-Splash([bool]$si) {
    $v = $(if ($si) { 'Collapsed' } else { 'Visible' })
    $ui.CargaTitulo.Visibility = $v; $ui.CargaZona.Visibility = $v; $ui.CargaInfo.Visibility = $v
    $ui.CargaMarca.FontSize = $(if ($si) { 40 } else { 30 })
}

function Mostrar-Carga([string]$titulo, [bool]$conFade) {
    Mostrar-Dns $null
    Modo-Splash $false
    $c = $script:Carga
    $c.Objetivo = 0.0; $c.Mostrado = 0.0; $c.Cerrar = $false
    $ui.CargaBarra.Width = 0; $ui.CargaPct.Text = '0%'
    $ui.CargaTitulo.Text = (Con-Enie $titulo); $ui.CargaDetalle.Text = ''
    $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
    # Si estaba saliendo, se corta la salida y vuelve a entrar
    $yaVisible = ($ui.Carga.Visibility -eq 'Visible') -and (-not $script:CargaSaliendo)
    $script:CargaSaliendo = $false
    $script:CargaVuelta++
    $ui.Carga.Visibility = 'Visible'
    if ($conFade -and -not $yaVisible) {
        $a = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(220)))
        $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
    } else { $ui.Carga.Opacity = 1 }
    if (-not $yaVisible) { Intro-Carga }
    $animTimer.Start()
}

function Poner-Progreso([double]$v, [string]$detalle) {
    if ($v -gt 1) { $v = 1 }
    if ($v -gt $script:Carga.Objetivo) { $script:Carga.Objetivo = $v }
    if ($null -ne $detalle) { $ui.CargaDetalle.Text = (Con-Enie $detalle) }
}

# Llena la barra hasta el final y despues se desvanece; $alCerrar corre cuando ya no se ve
function Cerrar-Carga([scriptblock]$alCerrar) {
    $script:Carga.AlCerrar = $alCerrar
    $script:Carga.Objetivo = 1.0
    $script:Carga.Cerrar = $true
    $animTimer.Start()
}

# Salida: lo mismo que la intro pero al reves. Lo de adentro se va de a uno (del ultimo al primero, bajando un poco),
# despues la tarjeta se achica y se desvanece, y recien ahi se va el fondo y aparecen los menus.
$script:CargaSaliendo = $false
$script:CargaVuelta = 0
function Animar-Salida($el, $tt, [double]$desdeY, [double]$hastaY, [int]$espera, [int]$ms) {
    $ini = [TimeSpan]::FromMilliseconds($espera)
    $fin = [TimeSpan]::FromMilliseconds($espera + $ms)
    $suave = New-Object Windows.Media.Animation.CubicEase
    $suave.EasingMode = 'EaseIn'
    $a = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    [void]$a.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new(1.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($ini)))
    [void]$a.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new(0.0, [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $suave))
    $el.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
    if ($tt) {
        $y = New-Object Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        [void]$y.KeyFrames.Add([Windows.Media.Animation.DiscreteDoubleKeyFrame]::new($desdeY, [Windows.Media.Animation.KeyTime]::FromTimeSpan($ini)))
        [void]$y.KeyFrames.Add([Windows.Media.Animation.EasingDoubleKeyFrame]::new($hastaY, [Windows.Media.Animation.KeyTime]::FromTimeSpan($fin), $suave))
        $tt.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $y)
    }
}

function Desvanecer-Carga {
    $script:CargaSaliendo = $true
    $vuelta = $script:CargaVuelta
    $cj = $ui.CargaCaja
    # 1) Lo de adentro, del ultimo al primero
    $hijos = @($cj.Child.Children | Where-Object { $_.Visibility -eq 'Visible' })
    [array]::Reverse($hijos)
    $n = 0
    foreach ($h in $hijos) {
        if (-not ($h.RenderTransform -is [Windows.Media.TranslateTransform])) { $h.RenderTransform = New-Object Windows.Media.TranslateTransform }
        Animar-Salida $h $h.RenderTransform 0 14 (150 + $n * 70) 260
        $n++
    }
    # 2) La tarjeta se achica (con el rebote al reves) y se desvanece
    $tCaja = 150 + [math]::Max($n - 1, 0) * 70 + 140
    $rebote = New-Object Windows.Media.Animation.BackEase
    $rebote.EasingMode = 'EaseIn'; $rebote.Amplitude = 0.3
    foreach ($pr in [Windows.Media.ScaleTransform]::ScaleXProperty, [Windows.Media.ScaleTransform]::ScaleYProperty) {
        $an = [Windows.Media.Animation.DoubleAnimation]::new(1.0, 0.6, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(520)))
        $an.BeginTime = [TimeSpan]::FromMilliseconds($tCaja)
        $an.EasingFunction = $rebote
        $cj.RenderTransform.BeginAnimation($pr, $an)
    }
    Animar-Salida $cj $null 0 0 ($tCaja + 120) 400
    # 3) Cuando la tarjeta ya no se ve, se va el fondo y entran los menus
    $a = [Windows.Media.Animation.DoubleAnimation]::new(1.0, 0.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(420)))
    $a.BeginTime = [TimeSpan]::FromMilliseconds($tCaja + 520)
    $a.EasingFunction = $script:Suave
    $script:CargaFinVuelta = $vuelta
    $a.Add_CurrentStateInvalidated({
        # Arranca la entrada de los menus justo cuando empieza a irse el fondo
        if (($this.CurrentState -eq 'Active') -and $script:CargaSaliendo -and ($script:CargaFinVuelta -eq $script:CargaVuelta) -and (-not $script:MenusEntrando)) {
            $script:MenusEntrando = $true
            Entrar-Menus
        }
    })
    $a.Add_Completed({
        $script:MenusEntrando = $false
        # Si mientras salia se volvio a abrir la carga, no se cierra
        if ((-not $script:CargaSaliendo) -or ($script:CargaFinVuelta -ne $script:CargaVuelta)) { return }
        $script:CargaSaliendo = $false
        $ui.Carga.Visibility = 'Collapsed'
        $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
        $ui.Carga.Opacity = 1
        $f = $script:Carga.AlCerrar
        $script:Carga.AlCerrar = $null
        if ($f) { & $f }
    })
    $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}

# Los menus entran suave: la barra de la izquierda desde el costado, la pagina desde abajo y sus cajas de a una
$script:MenusEntrando = $false
function Entrar-Menus {
    $dur = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(460))
    $o1 = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, $dur); $o1.EasingFunction = $script:Suave
    $ui.Barra.BeginAnimation([Windows.UIElement]::OpacityProperty, $o1)
    $x1 = [Windows.Media.Animation.DoubleAnimation]::new(-28.0, 0.0, $dur); $x1.EasingFunction = $script:Suave
    $ui.Barra.RenderTransform.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, $x1)
    $o2 = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, $dur); $o2.EasingFunction = $script:Suave
    $o2.BeginTime = [TimeSpan]::FromMilliseconds(80)
    $ui.Contenido.Opacity = 0
    $ui.Contenido.BeginAnimation([Windows.UIElement]::OpacityProperty, $o2)
    $y2 = [Windows.Media.Animation.DoubleAnimation]::new(18.0, 0.0, $dur); $y2.EasingFunction = $script:Suave
    $y2.BeginTime = [TimeSpan]::FromMilliseconds(80)
    $ui.Contenido.RenderTransform.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $y2)
    if ($Paginas[$script:Pagina]) { Desplegar $Paginas[$script:Pagina] }
}

# ------------------------------------------------------------
# Leer el estado de Windows (en segundo plano) y actualizar las etiquetas
# ------------------------------------------------------------
$script:Lectura = $null
$script:DespuesLectura = $null
$script:EstadoLeido = ''
$lecturaTimer = New-Object Windows.Threading.DispatcherTimer
$lecturaTimer.Interval = [TimeSpan]::FromMilliseconds(40)

function Refrescar-Estado([scriptblock]$despues) {
    if ($script:Lectura) { return }
    $script:DespuesLectura = $despues
    Bloquear $true
    Mostrar-Carga 'Leyendo como esta tu Windows' $true
    $lista = @()
    foreach ($k in @($script:Pills.Keys)) {
        if (-not $Chequeos.ContainsKey($k)) { continue }
        $lista += @{ Clave = $k; Titulo = [string]$TitulosChequeo[$k]; Codigo = $Chequeos[$k].ToString() }
    }
    $sync = [hashtable]::Synchronized(@{ Info = $null; Hecho = 0; Total = ($lista.Count + 5); Paso = ''; Listo = $false; Resultados = $null; Prio = @(); TareaAfi = $false; FuncCpu = $FuncCpu; Cpu = $null; FuncJuegos = $FuncJuegos; Juegos = $null })
    $ps = [powershell]::Create()
    [void]$ps.AddScript($CodigoLectura).AddArgument($FuncLectura).AddArgument($lista).AddArgument($sync)
    $script:Lectura = @{ PS = $ps; Handle = $ps.BeginInvoke(); Sync = $sync }
    $lecturaTimer.Start()
}

$lecturaTimer.Add_Tick({
    $l = $script:Lectura
    if (-not $l) { $lecturaTimer.Stop(); return }
    $s = $l.Sync
    $paso = $(if ($s.Paso) { 'Revisando: ' + $s.Paso } else { '' })
    Poner-Progreso (0.95 * $s.Hecho / [math]::Max($s.Total, 1)) $paso
    if (-not $l.Handle.IsCompleted) { return }
    $lecturaTimer.Stop()
    try { $l.PS.EndInvoke($l.Handle) | Out-Null } catch { }
    try { $l.PS.Dispose() } catch { }
    $script:Lectura = $null
    Aplicar-Lectura $s
    $ui.CargaDetalle.Text = (Con-Enie 'Listo')
    Cerrar-Carga {
        Bloquear $false
        $ui.Estado.Text = $(if ($script:Pagina -in $PagAjustes) { Texto-Leido $script:Pagina } else { '' })
        Actualizar-Bloqueos
        $f = $script:DespuesLectura
        $script:DespuesLectura = $null
        if ($f) { & $f }
        if (($script:JuegosNuevos -gt 0) -and (-not $script:Ocupado)) {
            $nn = $script:JuegosNuevos; $script:JuegosNuevos = 0
            Aplicar-ListaActiva $true $true
            if (-not $script:Ocupado) { $ui.Estado.Text = (Con-Enie ('Se sumaron ' + $nn + ' juegos nuevos instalados a tu lista.')) }
        }
    }
})

# Lo que cambia la afinidad y la Game Bar con TU procesador (lo calcula el .bat de gaming)
function Actualizar-Cpu($cpu) {
    foreach ($ct in $script:CpuTxt.Values) { $ct.Inlines.Clear(); $ct.Visibility = 'Collapsed' }
    if ($script:XbIcono) { $script:XbIcono.Visibility = 'Collapsed'; $script:XbIcono.ToolTip = $null }
    if (-not $cpu) { return }
    $a = $script:CpuTxt['afi']
    if ($a -and $cpu.Afi) {
        Agregar-Linea $a 'Con tu procesador: ' '#8AB4F8' ($cpu.Nombre + ' - cambio ' + $cpu.Afi.Nivel)
        Agregar-Linea $a 'Puede mejorar: ' '#81C995' $cpu.Afi.Favor
        Agregar-Linea $a 'Puede empeorar: ' '#F28B82' $cpu.Afi.Contra
        Agregar-Linea $a 'Conviene: ' '#E5B567' $cpu.Afi.Recom
        $a.Visibility = 'Visible'
    }
    $g = $script:CpuTxt['xb']
    if ($g -and $cpu.Gb) {
        if ($cpu.Gb.Aviso) {
            Agregar-Linea $g ($Aviso + ' Atencion: ') '#E5B567' $cpu.Gb.Aviso
            if ($script:XbIcono) { $script:XbIcono.ToolTip = (Con-Enie $cpu.Gb.Aviso); $script:XbIcono.Visibility = 'Visible' }
        }
        Agregar-Linea $g 'Con tu procesador: ' '#8AB4F8' $cpu.Gb.Texto
        $g.Visibility = 'Visible'
    }
}

function Aplicar-Lectura($s) {
    $res = $s.Resultados
    if ($null -ne $s.Juegos) { $script:JuegosDet = @($s.Juegos) }
    $script:NoDisp = Calcular-NoDisp $s.Info $s.Cpu
    $script:DrvFalta = @{}
    if ($s.Info -and $s.Info.DrvFalta) { foreach ($k in $s.Info.DrvFalta.Keys) { if (-not $script:NoDisp.ContainsKey($k)) { $script:DrvFalta[$k] = $s.Info.DrvFalta[$k] } } }
    $script:Estados = @{}
    $apl = 0; $tot = 0
    $porPag = @{}
    foreach ($k in @($script:Pills.Keys)) {
        $est = $null
        if ($res -and $res.ContainsKey($k)) { $est = $res[$k] }
        $script:Estados[$k] = $est
        $pg = ($k -split '\|')[0]
        if (-not $porPag.ContainsKey($pg)) { $porPag[$pg] = @{ A = 0; T = 0; N = 0 } }
        if ($script:NoDisp.ContainsKey($k)) { $porPag[$pg].N++ }
        elseif ($null -ne $est) { $porPag[$pg].T++; if ($est) { $porPag[$pg].A++ } }
        if ($script:NoDisp.ContainsKey($k)) {
            $pb = $script:Pills[$k]
            $pb.Visibility = 'Visible'; $pb.Background = (Pincel '#2A2D33'); $pb.Child.Foreground = (Pincel '#9AA0A6'); $pb.Child.Text = (Con-Enie 'No compatible')
            continue
        }
        Poner-Pill $script:Pills[$k] $est
        if ($script:DrvFalta.ContainsKey($k)) {
            $pb = $script:Pills[$k]
            $pb.Visibility = 'Visible'; $pb.Background = (Pincel '#3A1F40'); $pb.Child.Foreground = (Pincel $ColorDrv); $pb.Child.Text = (Con-Enie 'Faltan drivers')
            $pb.ToolTip = (Con-Enie ($script:DrvFalta[$k] + '.'))
        }
        if ($null -ne $est) { $tot++; if ($est) { $apl++ } }
    }
    if ($script:PrioTexto) {
        $pr = @($s.Prio)
        $script:PrioTexto.Text = $(if ($pr.Count -gt 0) { (Con-Enie 'Con prioridad alta ahora: ') + ($pr -join ', ') } else { '' })
    }
    if ($script:AfiTexto) {
        $ac = Afi-Config
        $script:AfiTexto.Text = $(if ($ac['desc'] -and $s.TareaAfi) { (Con-Enie 'Activa: ') + (Con-Enie $ac['desc']) } else { '' })
    }
    Actualizar-Cpu $s.Cpu
    Actualizar-Resumenes
    Actualizar-Version
    Actualizar-InfoPC $s.Info
    Actualizar-Perfiles
    if ($res) {
        $script:EstadoLeido = ('Windows leido: ' + $apl + ' ' + (Con-Enie 'de') + ' ' + $tot + ' opciones ya estan aplicadas.')
        $script:EstadoLeido += (No-Compatibles $script:NoDisp.Count)
        $script:LeidoPag = $porPag
    }
    else { $script:EstadoLeido = 'No se pudo leer el estado de Windows. Proba con "Volver a leer los ajustes".'; $script:LeidoPag = $null }
    $script:Leido = $true
}

# ------------------------------------------------------------
# Actualizaciones desde GitHub
# Al abrir, compara el version.txt de tu PC con el de GitHub. Si el de GitHub es mas nuevo,
# la pantalla de carga muestra el cartel amarillo.
# Al tocarlo baja la app y los scripts, reemplaza los viejos y abre la app de nuevo.
# ------------------------------------------------------------
$CodigoUpd = @'
param($lista, $sync, $bajar)
$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
$latin = [Text.Encoding]::GetEncoding(28591)

function Limpiar([string]$t) { return (($t -replace '^(\u00EF\u00BB\u00BF|\uFEFF)', '') -split "`r?`n")[0].Trim() }
function Bajar([string]$remoto, [int]$espera, [double]$desde, [double]$peso) {
    $rq = [Net.HttpWebRequest]::Create($sync.Base + $remoto + '?nc=' + [DateTime]::UtcNow.Ticks)
    $rq.Timeout = $espera; $rq.ReadWriteTimeout = $espera; $rq.UserAgent = 'XucaOP'
    $rs = $rq.GetResponse()
    try {
        $len = $rs.ContentLength
        $st = $rs.GetResponseStream(); $ms = New-Object IO.MemoryStream; $buf = New-Object byte[] 65536
        while (($r = $st.Read($buf, 0, $buf.Length)) -gt 0) {
            $ms.Write($buf, 0, $r)
            if (($peso -gt 0) -and ($len -gt 0)) { $sync.Prog = $desde + $peso * [math]::Min(1.0, $ms.Length / $len) }
        }
        # Si se corto internet a mitad de camino llega un archivo cortado: no se usa
        if (($len -gt 0) -and ($ms.Length -ne $len)) { throw ('la descarga de ' + $remoto + ' llego incompleta') }
        return $latin.GetString($ms.ToArray())
    } finally { $rs.Close() }
}

if (-not $bajar) {
    # Buscar: compara el texto del version.txt de tu PC con el de GitHub
    $local = ''
    if (Test-Path -LiteralPath $sync.VerLocal) { try { $local = Limpiar ([IO.File]::ReadAllText($sync.VerLocal)) } catch { } }
    $remota = ''
    try { $remota = Limpiar (Bajar 'version.txt' 4000 0 0) } catch { }
    $sync.Local = $local
    $sync.Remota = $remota
    # Avisa siempre que tu version no sea la misma que la de GitHub (mas vieja o mas nueva).
    # Mas nueva pasa cuando cambiaste el version.txt y todavia no lo subiste: el cartel lo dice distinto.
    $sync.Hay = [bool]($remota -and ($remota -ne $local))
    $vr = $null; $vl = $null
    $sync.TuyaMasNueva = ($remota -and [version]::TryParse(($remota -replace '^[vV]', ''), [ref]$vr) -and [version]::TryParse(($local -replace '^[vV]', ''), [ref]$vl) -and ($vl -gt $vr))
    $sync.Listo = $true
    return
}

# Descargar: baja todo a archivos .nuevo y recien al final reemplaza los viejos (el version.txt ultimo)
$listos = @()
try {
    $cant = [math]::Max(@($lista).Count, 1); $i = 0
    foreach ($a in $lista) {
        $sync.Paso = $a.Nombre
        # Los opcionales (los idiomas) se saltean si todavia no estan en GitHub
        try { $txt = Bajar $a.Remoto 30000 ($i / $cant) (1.0 / $cant) } catch { if ($a.Opc) { $i++; continue }; throw }
        if (($txt.Length -lt 1) -or (($a.Remoto -match '(?i)\.(ps1|bat)$') -and ($txt.Length -lt 100))) { if ($a.Opc) { $i++; continue }; throw ('lo que llego de GitHub para ' + $a.Nombre + ' no es el archivo esperado') }
        # Un .ps1 con errores de escritura dejaria la app sin abrir: se revisa antes de guardarlo
        if ($a.Remoto -match '(?i)\.ps1$') {
            $errPs = $null
            [void][Management.Automation.Language.Parser]::ParseInput($txt, [ref]$null, [ref]$errPs)
            if (@($errPs).Count -gt 0) { throw ('lo que llego de GitHub para ' + $a.Nombre + ' tiene errores') }
        }
        $tmp = $a.Local + '.nuevo'
        $dd = Split-Path -Parent $tmp
        if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
        # Los de texto con saltos de linea de Windows; los demas (por ejemplo imagenes) tal cual llegan
        if ($a.Remoto -match '(?i)\.(ps1|bat|cmd|txt)$') { $txt = $txt -replace '\r?\n', "`r`n" }
        [IO.File]::WriteAllText($tmp, $txt, $latin)
        $listos += [pscustomobject]@{ Tmp = $tmp; Local = $a.Local }
        $i++
    }
    $tmp = $sync.VerLocal + '.nuevo'
    [IO.File]::WriteAllText($tmp, ($sync.Remota + "`r`n"), $latin)
    $listos += [pscustomobject]@{ Tmp = $tmp; Local = $sync.VerLocal }
    $sync.Paso = 'reemplazando la version vieja'
    foreach ($l in $listos) { Move-Item -LiteralPath $l.Tmp -Destination $l.Local -Force }
} catch {
    foreach ($l in $listos) { Remove-Item -LiteralPath $l.Tmp -Force -ErrorAction SilentlyContinue }
    $sync.Error = $_.Exception.Message
}
$sync.Listo = $true
'@

$script:UpdRemota = ''
$script:UpdHay = $false
$script:UpdRun = $null
$script:Leido = $false
$updTimer = New-Object Windows.Threading.DispatcherTimer
$updTimer.Interval = [TimeSpan]::FromMilliseconds(40)

function Upd-Iniciar([bool]$bajar) {
    $base = 'https://raw.githubusercontent.com/' + $XucaRepo + '/' + $XucaRama + '/'
    $sync = [hashtable]::Synchronized(@{ Base = $base; VerLocal = $VersionLocal; Remota = $script:UpdRemota; Local = ''; Hay = $false; Listo = $false; Prog = 0.0; Paso = ''; Error = $null })
    $ps = [powershell]::Create()
    [void]$ps.AddScript($CodigoUpd).AddArgument(@($ArchivosUpd)).AddArgument($sync).AddArgument($bajar)
    $script:UpdRun = @{ PS = $ps; Handle = $ps.BeginInvoke(); Sync = $sync; Bajar = $bajar; Desde = (Get-Date) }
    $updTimer.Start()
}

# Se llama al abrir la app (antes de leer Windows)
function Buscar-Actualizacion {
    Bloquear $true
    Mostrar-Carga 'Buscando actualizaciones' $false
    Modo-Splash $true
    Intro-Carga
    $script:SplashDesde = Get-Date
    if ((-not $XucaRepo) -or ($XucaRepo -like 'TU_USUARIO*')) { Fin-Splash; return }
    Upd-Iniciar $false
}

# La marca se ve por lo menos 1,6 segundos (para que se luzca la intro) y despues se va a los menus
$script:SplashTimer = New-Object Windows.Threading.DispatcherTimer
$script:SplashTimer.Add_Tick({ $script:SplashTimer.Stop(); Cerrar-Carga { Bloquear $false } })
function Fin-Splash {
    $falta = 1600 - ((Get-Date) - $script:SplashDesde).TotalMilliseconds
    $script:SplashTimer.Interval = [TimeSpan]::FromMilliseconds([math]::Max($falta, 1))
    $script:SplashTimer.Start()
}

function Upd-MostrarCartel([bool]$si) {
    $vis = $(if ($si) { 'Collapsed' } else { 'Visible' })
    $ui.CargaZona.Visibility = $vis; $ui.CargaInfo.Visibility = $vis
    $ui.UpdCarga.Visibility = $(if ($si) { 'Visible' } else { 'Collapsed' })
}

function Fin-Busqueda($s) {
    $script:UpdHay = [bool]$s.Hay
    $script:UpdRemota = [string]$s.Remota
    if (-not $script:UpdHay) { Fin-Splash; return }
    Modo-Splash $false
    Poner-Version $true ([bool]$s.TuyaMasNueva)
    $tuya = $(if ($s.Local) { [string]$s.Local } else { 'sin version' })
    if ($s.TuyaMasNueva) {
        $t = 'Tenes una version mas nueva: la ' + $tuya + ', y la publicada es la ' + $script:UpdRemota
        $ui.UpdTitulo.Text = (Con-Enie $t)
        $ui.UpdTexto.Text = (Con-Enie 'Si tocas este cartel se baja la publicada y reemplaza la tuya.')
    } else {
        $t = 'Hay una actualizacion disponible: tenes la ' + $tuya + ' y la nueva es la ' + $script:UpdRemota
        $ui.UpdTitulo.Text = (Con-Enie $t)
        $ui.UpdTexto.Text = (Con-Enie 'Toca este cartel para descargarla. Se cierra esta version y se abre la nueva sola.')
    }
    $ui.UpdBarraTexto.Text = (Con-Enie ($t + '. Toca aca para actualizar.'))
    $animTimer.Stop()
    $ui.CargaTitulo.Text = (Con-Enie $(if ($s.TuyaMasNueva) { 'Tu version de Xuca OPtimizer es distinta' } else { 'Hay una version nueva de Xuca OPtimizer' }))
    Marcar-OP $ui.CargaTitulo
    $ui.CargaDetalle.Text = ''
    Upd-MostrarCartel $true
}

function Descargar-Actualizacion {
    if ($script:UpdRun -or $script:Lectura -or (-not $script:UpdHay)) { return }
    if ($script:Proc -and -not $script:Proc.HasExited) { Avisar 'Actualizar' 'Espera a que termine lo que se esta aplicando y despues toca el cartel amarillo.'; return }
    Upd-MostrarCartel $false
    Bloquear $true
    Mostrar-Carga 'Descargando la actualizacion' $true
    Upd-Iniciar $true
}

function Fin-Descarga($s) {
    if ($s.Error) {
        $script:UpdError = $s.Error
        Cerrar-Carga {
            $ui.BtnUpdBarra.Visibility = 'Visible'
            Avisar 'No se pudo actualizar' ('No se pudo bajar la version nueva: ' + $script:UpdError + "`n`n" + 'Seguis usando esta version. Podes probar de nuevo con el cartel amarillo de arriba.')
            Bloquear $false
        }
        return
    }
    # Todo bajado y reemplazado: se abre la app nueva y se cierra esta
    $ui.CargaTitulo.Text = (Con-Enie 'Actualizacion lista')
    Poner-Progreso 1 'Abriendo la version nueva...'
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $AppPath + '"')
    $script:CierreTimer = New-Object Windows.Threading.DispatcherTimer
    $script:CierreTimer.Interval = [TimeSpan]::FromMilliseconds(900)
    $script:CierreTimer.Add_Tick({ $script:CierreTimer.Stop(); Cerrar-Suave $true })
    $script:CierreTimer.Start()
}

$updTimer.Add_Tick({
    $u = $script:UpdRun
    if (-not $u) { $updTimer.Stop(); return }
    $s = $u.Sync
    if ($u.Bajar) { Poner-Progreso (0.95 * $s.Prog) $(if ($s.Paso) { 'Descargando: ' + $s.Paso } else { '' }) }
    else { Poner-Progreso ((1 - [math]::Exp(-((Get-Date) - $u.Desde).TotalSeconds / 1.5)) * 0.9) 'Buscando versiones nuevas' }
    if (-not $u.Handle.IsCompleted) { return }
    $updTimer.Stop()
    try { $u.PS.EndInvoke($u.Handle) | Out-Null } catch { if ($u.Bajar -and -not $s.Error) { $s.Error = $_.Exception.Message } }
    try { $u.PS.Dispose() } catch { }
    $script:UpdRun = $null
    if ($u.Bajar) { Fin-Descarga $s } else { Fin-Busqueda $s }
})

$ui.BtnUpd.Add_Click({ Descargar-Actualizacion })
$ui.BtnUpdBarra.Add_Click({ Descargar-Actualizacion })
$ui.BtnUpdNo.Add_Click({
    # Sigue con esta version: el cartel queda chiquito arriba por si despues queres actualizar
    Upd-MostrarCartel $false
    $ui.BtnUpdBarra.Visibility = 'Visible'
    Cerrar-Carga { Bloquear $false }
})

# ------------------------------------------------------------
# Correr scripts en modo app (uno atras de otro)
# Las opciones de Debloat, Gaming y Limpieza (aplicar y restablecer) corren ocultas y su progreso se ve en la pantalla de carga.
# Las de Herramientas abren la ventana negra porque te piden datos.
# ------------------------------------------------------------
$script:Cola = New-Object System.Collections.Generic.Queue[object]
$script:Proc = $null
$script:Tarea = $null
$script:Corrida = $null
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(300)

$Esc = [string][char]27
function Sin-Colores([string]$t) { return ($t -replace ($Esc + '\[[0-9;]*m'), '') }

# Lee la salida del script aunque el script la tenga abierta
function Leer-Salida([string]$f) {
    try {
        $fs = [IO.File]::Open($f, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        try { $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::GetEncoding(850)); return (Sin-Colores $sr.ReadToEnd()) } finally { $fs.Dispose() }
    } catch { return '' }
}

# Pasos de la limpieza: cuando aparece la linea, empieza el paso que sigue
$PasosLimpieza = @(
    @('Deteniendo servicios de actualizacion', 'Cache de Windows Update'),
    @('(?m)^Windows Update\s+encontrados', 'Archivos temporales'),
    @('(?m)^Temporales\s+encontrados', 'Volcados y logs de errores'),
    @('(?m)^Errores, volcados y logs', 'Windows.old y caches de apps'),
    @('(?m)^Apps \(Discord', 'Cache de shaders'),
    @('Vaciando Visor de Eventos', 'Visor de Eventos'),
    @('Restableciendo Microsoft Store', 'Microsoft Store'),
    @('Restableciendo cache de resolucion DNS', 'DNS'),
    @('Limpiando componentes viejos', 'Componentes viejos de Windows (puede tardar varios minutos)'),
    @('Papelera de reciclaje', 'Papelera y puntos de restauracion'),
    @('RESULTADO FINAL', 'Terminando')
)

# Prueba de DNS en la pantalla de carga: lee lo que va escribiendo el .bat de gaming
# ("Probando Google...", "    Google: 12.3 ms") y lo muestra fila por fila.
$DnsNombres = @('Cloudflare', 'Google', 'Quad9', 'OpenDNS')
$script:DnsFilas = @{}
foreach ($dn in $DnsNombres) {
    $fila = New-Object Windows.Controls.DockPanel
    $fila.Margin = '0,4,0,0'
    $tv = Nuevo-Texto '' 12.5 '#5C6370' $true
    $tv.TextWrapping = 'NoWrap'
    [Windows.Controls.DockPanel]::SetDock($tv, 'Right')
    $fila.Children.Add($tv) | Out-Null
    $tn = Nuevo-Texto $dn 12.5 '#C3C8D0' $false
    $fila.Children.Add($tn) | Out-Null
    $ui.CargaDnsLista.Children.Add($fila) | Out-Null
    $script:DnsFilas[$dn] = @{ Nombre = $tn; Valor = $tv }
}

function Leer-Dns([string]$t) {
    $r = @{ Hechos = 0; Probando = ''; Ganador = ''; Ninguno = $false; Fin = $false; Filas = @{} }
    foreach ($dn in $DnsNombres) {
        $e = [regex]::Escape($dn)
        $m = [regex]::Match($t, '(?m)^\s+' + $e + ':\s*([\d.,]+)\s*ms')
        if ($m.Success) { $r.Filas[$dn] = @('ms', $m.Groups[1].Value); $r.Hechos++; continue }
        if ($t -match ('(?m)^\s+' + $e + ':\s*no responde')) { $r.Filas[$dn] = @('mal', ''); $r.Hechos++; continue }
        if ($t -match ('Probando ' + $e + '\.\.\.')) { $r.Filas[$dn] = @('prob', ''); $r.Probando = $dn; continue }
        $r.Filas[$dn] = @('espera', '')
    }
    $g = [regex]::Match($t, 'El mas rapido para tu conexion:\s*(\S+)')
    if ($g.Success) { $r.Ganador = $g.Groups[1].Value }
    $r.Ninguno = ($t -match 'Ningun DNS respondio')
    $r.Fin = $g.Success -or $r.Ninguno -or ($t -match 'no puede medir DNS') -or ($t -match 'No hay una placa de red conectada')
    return $r
}

function Mostrar-Dns($d) {
    if (-not $d) { if ($ui.CargaDns.Visibility -ne 'Collapsed') { $ui.CargaDns.Visibility = 'Collapsed' }; return }
    $ui.CargaDns.Visibility = 'Visible'
    $tit = 'Probando los DNS desde tu conexion'
    if ($d.Ganador) { $tit = 'El mas rapido para tu conexion: ' + $d.Ganador }
    elseif ($d.Ninguno) { $tit = 'Ningun DNS respondio a la prueba' }
    $ui.CargaDnsTitulo.Text = (Con-Enie $tit)
    foreach ($dn in $DnsNombres) {
        $f = $script:DnsFilas[$dn]; $e = $d.Filas[$dn]
        $gana = ($dn -eq $d.Ganador)
        switch ($e[0]) {
            'ms'   { $txt = $e[1] + ' ms'; $col = $(if ($gana) { '#81C995' } else { '#C3C8D0' }) }
            'mal'  { $txt = (Con-Enie 'no responde'); $col = '#F28B82' }
            'prob' { $txt = (Con-Enie 'probando...'); $col = '#E5B567' }
            default { $txt = (Con-Enie 'en espera'); $col = '#5C6370' }
        }
        $f.Valor.Text = $txt; $f.Valor.Foreground = (Pincel $col)
        $f.Nombre.FontWeight = $(if ($gana) { 'SemiBold' } else { 'Normal' })
        $f.Nombre.Foreground = (Pincel $(if ($gana) { '#81C995' } else { '#C3C8D0' }))
    }
}

function Limpiar-Variables {
    foreach ($v in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'XR_*' })) { Remove-Item -LiteralPath ('Env:' + $v.Name) -ErrorAction SilentlyContinue }
    foreach ($n in 'XUCA_AUTO', 'PRIOJ', 'PRIOSYNC', 'AFIAPP', 'AFIJ', 'AFIF', 'AFIJX', 'AFIFX', 'AFIJT', 'AFIFT', 'CLEAN_BIN', 'CLEAN_GPU', 'CLEAN_RP', 'XUCA_DRVAPP', 'XUCA_DRVPRUEBA') { Remove-Item -LiteralPath ('Env:' + $n) -ErrorAction SilentlyContinue }
}

function Correr($tareas, [bool]$reinicio, [string]$tituloCarga) {
    $total = 0; foreach ($t in $tareas) { $total += [int]$t.Cambios }
    $script:Corrida = @{ Reinicio = $reinicio; PideReinicio = $false; Total = [math]::Max($total, 1); Hechos = 0; Fallos = 0; Liberado = ''; Drivers = $null; Tipo = $tareas[0].Tipo; Oculta = $false }
    $script:Cola.Clear()
    foreach ($t in $tareas) { $script:Cola.Enqueue($t) }
    Bloquear $true
    if (@($tareas | Where-Object { -not $_.Visible }).Count -gt 0) {
        $script:Corrida.Oculta = $true
        Mostrar-Carga $tituloCarga $true
    }
    Siguiente
    $timer.Start()
}

function Siguiente {
    if ($script:Cola.Count -eq 0) { Terminar-Corrida; return }
    $t = $script:Cola.Dequeue()
    $script:Tarea = $t
    Limpiar-Variables
    $env:XUCA_AUTO = '1'
    foreach ($k in $t.Vars.Keys) { Set-Item -LiteralPath ('Env:' + $k) -Value ([string]$t.Vars[$k]) }
    $t | Add-Member -NotePropertyName Inicio -NotePropertyValue (Get-Date) -Force
    $t | Add-Member -NotePropertyName UltN -NotePropertyValue 0 -Force
    $t | Add-Member -NotePropertyName UltCambio -NotePropertyValue (Get-Date) -Force
    if ($t.Visible) {
        $ui.Estado.Text = (Con-Enie ($t.Nombre + ': responde en la ventana negra del script. Cuando termine, la app sigue sola.'))
        $script:Proc = Start-Process -FilePath $env:ComSpec -ArgumentList ('/c ""' + $t.Ruta + '""') -WorkingDirectory $Root -PassThru
    } else {
        $salida = Join-Path $env:TEMP ('xucaop_' + [guid]::NewGuid().ToString('N') + '.txt')
        $t | Add-Member -NotePropertyName Salida -NotePropertyValue $salida -Force
        # Oculto, sin teclado (<nul) y con todo lo que escribe guardado en un archivo para leer el progreso
        $script:Proc = Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ""' + $t.Ruta + '" <nul >"' + $salida + '" 2>&1"') -WorkingDirectory $Root -WindowStyle Hidden -PassThru
    }
}

# Progreso dentro de un paso largo: avanza solo un poco con el tiempo, sin pasarse del paso
function Avance-Tiempo($desde, [double]$seg) { return (1 - [math]::Exp(-((Get-Date) - $desde).TotalSeconds / $seg)) * 0.9 }

function Actualizar-Progreso {
    $t = $script:Tarea; $C = $script:Corrida
    if ((-not $t) -or $t.Visible) { return }
    $txt = Leer-Salida $t.Salida
    if ($t.Tipo -eq 'limpieza') {
        $n = 0; $det = 'Preparando'
        for ($i = 0; $i -lt $PasosLimpieza.Count; $i++) { if ($txt -match $PasosLimpieza[$i][0]) { $n = $i + 1; $det = $PasosLimpieza[$i][1] } }
        if ($n -ne $t.UltN) { $t.UltN = $n; $t.UltCambio = Get-Date }
        $tot = $PasosLimpieza.Count + 1
        Poner-Progreso ((($n + (Avance-Tiempo $t.UltCambio 25)) / $tot) * 0.97) $det
        return
    }
    $ms = [regex]::Matches($txt, '(?m)^- Desea (.+?)\s*\[(S|R)\]\s*$')
    $n = [math]::Min($ms.Count, [int]$t.Cambios)
    if ($n -ne $t.UltN) { $t.UltN = $n; $t.UltCambio = Get-Date }
    $act = $(if ($ms.Count -gt 0) { Titulo-Corto $ms[$ms.Count - 1].Groups[1].Value } else { 'Preparando' })
    $num = [math]::Min($C.Hechos + [math]::Max($n, 1), $C.Total)
    $sub = $(if ($n -gt 0) { Avance-Tiempo $t.UltCambio 6 } else { 0 })
    # Si el paso actual es la prueba de DNS: se muestra cada DNS con su tiempo y la barra avanza con cada uno que termina
    $dns = $null
    if ($ms.Count -gt 0) {
        $u = $ms[$ms.Count - 1]
        if (($u.Groups[2].Value -eq 'S') -and ($u.Groups[1].Value -like 'cambiar el DNS*')) { $dns = Leer-Dns $txt.Substring($u.Index) }
    }
    Mostrar-Dns $dns
    if ($dns) { $sub = $(if ($dns.Fin) { 0.95 } else { 0.95 * ($dns.Hechos + $(if ($dns.Probando) { 0.5 } else { 0 })) / $DnsNombres.Count }) }
    $base = $C.Hechos + [math]::Max($n - 1, 0) + $sub
    Poner-Progreso (($base / $C.Total) * 0.97) (Con-Enie ((Con-Enie 'Cambio') + ' ' + $num + ' ' + (Con-Enie 'de') + ' ' + $C.Total + '  -  ' + $act))
}

function Fin-Tarea {
    $t = $script:Tarea; $C = $script:Corrida
    if (-not $t) { return }
    $C.Hechos += [int]$t.Cambios
    if (-not $t.Visible) {
        $txt = Leer-Salida $t.Salida
        $m = [regex]::Match($txt, 'Cambios que fallaron:\s*(\d+)')
        if ($m.Success) { $C.Fallos += [int]$m.Groups[1].Value }
        # El script solo escribe esto si alguna opcion que necesita reiniciar cambio algo de verdad
        if ($txt -match 'Hace falta reiniciar la PC') { $C.PideReinicio = $true }
        $m = [regex]::Match($txt, 'Espacio liberado\s*:\s*(.+)')
        if ($m.Success) { $C.Liberado = $m.Groups[1].Value.Trim() }
        if ($t.Tipo -eq 'drivers') {
            # Cajitas del resultado: "XDRV|tipo|titulo|frase" y debajo sus items "XDRVSUB|texto"
            $items = New-Object System.Collections.Generic.List[object]
            foreach ($l in ($txt -split "`r?`n")) {
                if ($l -match '^XDRV\|([^|]*)\|([^|]*)\|(.*)$') { $items.Add(@{ Tipo = $Matches[1]; Titulo = $Matches[2].Trim(); Corto = $Matches[3].Trim(); Sub = (New-Object System.Collections.Generic.List[string]) }) }
                elseif (($l -match '^XDRVSUB\|(.*)$') -and ($items.Count -gt 0)) { $items[$items.Count - 1].Sub.Add($Matches[1].Trim()) }
            }
            $m = [regex]::Match($txt, 'Paginas abiertas:\s*(\d+)')
            $C.Drivers = @{ Items = $items; Paginas = $(if ($m.Success) { [int]$m.Groups[1].Value } else { 0 }) }
        }
        # La limpieza no tiene log propio: se guarda lo que mostro en la carpeta de logs
        if ($t.Tipo -eq 'limpieza') {
            try {
                $d = Join-Path $Scripts 'logs'
                if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
                Set-Content -LiteralPath (Join-Path $d ('limpiar_cache_' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '.txt')) -Value $txt -Encoding UTF8
            } catch { }
        }
        Remove-Item -LiteralPath $t.Salida -Force -ErrorAction SilentlyContinue
    }
    $script:Tarea = $null
}

$timer.Add_Tick({
    if (-not $script:Proc) { return }
    Actualizar-Progreso
    if ($script:Proc.HasExited) { $script:Proc = $null; Fin-Tarea; Siguiente }
})

# Cartel con el resultado de "Buscar drivers": una cajita de color con icono por cada cosa, separadas con espacio
$CajaDrv = @{
    'placa'     = @('#3D6FD9', 0xE896); 'gpu-nv' = @('#76B900', 0xE7F4); 'gpu-amd' = @('#ED1C24', 0xE7F4); 'gpu-intel' = @('#0071C5', 0xE7F4)
    'chipset'   = @('#F28B82', 0xE945); 'mouse' = @('#C58AF9', 0xE962); 'teclado' = @('#C58AF9', 0xE765); 'audio' = @('#8FD3F4', 0xE7F6)
    'perif'     = @('#C58AF9', 0xE7FC); 'rgb' = @('#F9A8D4', 0xE790); 'bios' = @('#E5B567', 0xE7BA); 'wu' = @('#8AB4F8', 0xE895); 'ok' = @('#81C995', 0xE73E)
}
function Resultado-Drivers($r) {
    $w = Nuevo-Dialogo 540
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((Nuevo-Texto 'Drivers recomendados' 17 '#FFFFFF' $true)) | Out-Null
    $lista = New-Object Windows.Controls.StackPanel
    $lista.Margin = '0,4,6,0'
    foreach ($it in $r.Items) {
        $def = $CajaDrv[$it.Tipo]; if (-not $def) { $def = $CajaDrv['perif'] }
        $col = Color-Tema($def[0])
        $caja = New-Object Windows.Controls.Border
        $caja.CornerRadius = 12; $caja.Padding = '12,10'; $caja.Margin = '0,12,0,0'; $caja.BorderThickness = 1
        $caja.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(0x24, $col.R, $col.G, $col.B))
        $caja.BorderBrush = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(0x70, $col.R, $col.G, $col.B))
        $dp = New-Object Windows.Controls.DockPanel
        $ic = New-Object Windows.Controls.Border
        $ic.Width = 34; $ic.Height = 34; $ic.CornerRadius = 9; $ic.Margin = '0,0,12,0'; $ic.VerticalAlignment = 'Top'
        $ic.Background = New-Object Windows.Media.SolidColorBrush $col
        $g = Nuevo-Texto ([string][char]($def[1])) 16 'White' $false
        $g.FontFamily = 'Segoe MDL2 Assets'; $g.HorizontalAlignment = 'Center'; $g.VerticalAlignment = 'Center'
        $ic.Child = $g
        [Windows.Controls.DockPanel]::SetDock($ic, 'Left')
        $dp.Children.Add($ic) | Out-Null
        $tx = New-Object Windows.Controls.StackPanel
        $tx.Children.Add((Nuevo-Texto $it.Titulo 13.5 '#FFFFFF' $true)) | Out-Null
        $c2 = Nuevo-Texto $it.Corto 12.5 '#C3C8D0' $false
        $c2.Margin = '0,2,0,0'
        $tx.Children.Add($c2) | Out-Null
        if ($it.Sub.Count -gt 0) {
            # Lo que hay que bajar, en chips chiquitos
            $wp = New-Object Windows.Controls.WrapPanel
            $wp.Margin = '0,4,0,0'
            foreach ($x in $it.Sub) {
                $chip = New-Object Windows.Controls.Border
                $chip.CornerRadius = 8; $chip.Padding = '8,3'; $chip.Margin = '0,4,6,0'; $chip.Background = (Pincel '#262B34')
                $chip.Child = (Nuevo-Texto $x 12 '#E6E8EB' $false)
                $wp.Children.Add($chip) | Out-Null
            }
            $tx.Children.Add($wp) | Out-Null
        }
        $dp.Children.Add($tx) | Out-Null
        $caja.Child = $dp
        $lista.Children.Add($caja) | Out-Null
    }
    $sv = New-Object Windows.Controls.ScrollViewer
    $sv.VerticalScrollBarVisibility = 'Auto'; $sv.MaxHeight = 470
    $sv.Content = $lista
    $sp.Children.Add($sv) | Out-Null
    if ($r.Paginas -gt 0) {
        $pie = Nuevo-Texto ($(if ($r.Paginas -eq 1) { 'Se abrio 1 pagina oficial en tu navegador.' } else { 'Se abrieron ' + $r.Paginas + ' paginas oficiales en tu navegador.' })) 12.5 '#81C995' $false
        $pie.Margin = '0,14,0,0'
        $sp.Children.Add($pie) | Out-Null
    }
    $bOk = Nuevo-Boton 'Entendido' '#3D6FD9'; $bOk.IsDefault = $true; $bOk.IsCancel = $true
    $bOk.Add_Click({ [Windows.Window]::GetWindow($this).DialogResult = $true })
    $sp.Children.Add((Fila-Botones @() @($bOk))) | Out-Null
    $w.Content.Child = $sp
    [void]$w.ShowDialog()
}

function Terminar-Corrida {
    $timer.Stop()
    Limpiar-Variables
    # Si solo se actualizo la lista de juegos, no se tocan las casillas que tengas marcadas
    if ((-not $script:Corrida) -or ($script:Corrida.Tipo -ne 'lista')) {
        foreach ($p in 'Debloat', 'Gaming') { foreach ($cb in $Casillas[$p].Values) { $cb.IsChecked = $false } }
    }
    Refrescar-Estado {
        $C = $script:Corrida
        $script:Corrida = $null
        if (-not $C) { return }
        $ui.Estado.Text = ($ui.Estado.Text + (Con-Enie ' Los detalles de cada cambio quedaron en la carpeta de logs.'))
        if ($C.Tipo -eq 'limpieza') {
            Resultado-Limpieza ([string]$C.Liberado)
            return
        }
        if ($C.Tipo -eq 'drivers') {
            if ($C.Drivers -and ($C.Drivers.Items.Count -gt 0)) { Resultado-Drivers $C.Drivers }
            else { Avisar 'Drivers recomendados' 'Termino la revision. El detalle quedo en la carpeta de logs.' }
            return
        }
        if ($C.Tipo -eq 'lista') {
            if ($C.Fallos -gt 0) { Avisar 'Tu lista de juegos' ('Se guardo, pero ' + $C.Fallos + ' cambios fallaron al aplicarla (mira la carpeta de logs).') }
            else { $ui.Estado.Text = (Con-Enie 'Listo: tu lista nueva ya esta aplicada, sin reiniciar.') }
            return
        }
        if (-not $C.Reinicio) { return }
        $m = $(if ($C.Fallos -gt 0) { 'Termino, pero ' + $C.Fallos + ' cambios fallaron (mira la carpeta de logs).' } else { 'Se aplico todo bien.' })
        if ($C.PideReinicio) {
            if (Confirmar 'Listo' ($m + "`n`n" + 'Algunos de estos cambios necesitan reiniciar la PC. Reiniciar ahora?') 'Reiniciar' '#3D6FD9' 'Despues') { & shutdown.exe /r /t 10 }
        } elseif ($C.Fallos -gt 0) {
            Avisar 'Listo' ($m + "`n`n" + 'No hace falta reiniciar.')
        } else {
            $ui.Estado.Text = ((Con-Enie 'Listo: se aplico todo bien y no hace falta reiniciar. ') + $ui.Estado.Text)
        }
    }
}

function Titulo-De([string]$p, [string]$id) {
    return (@($Opciones[$p] | Where-Object { $_.Id -eq $id })[0]).Titulo
}

# ------------------------------------------------------------
# Botones
# ------------------------------------------------------------
$ui.NavPerfiles.Add_Click({ Ir-A 'Perfiles' })
$ui.NavDebloat.Add_Click({ Ir-A 'Debloat' })
$ui.NavGaming.Add_Click({ Ir-A 'Gaming' })
$ui.NavLimpieza.Add_Click({ Ir-A 'Limpieza' })
$ui.NavHerr.Add_Click({ Ir-A 'Herr' })
$ui.NavApps.Add_Click({ Ir-A 'Apps' })
$ui.NavAdicional.Add_Click({ Ir-A 'Adicional' })
$ui.BtnRefrescar.Add_Click({ Refrescar-Estado })
$ui.BtnRedes.Add_Click({ Abrir-Normal $Redes })

$ui.BtnLogs.Add_Click({
    $d = Join-Path $Scripts 'logs'
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $d + '"')
})

$ui.BtnTodo.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $true }; Actualizar-Contador })
$ui.BtnNada.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $false }; Actualizar-Contador })

# Boton verde: marca solo lo que no tiene el icono de advertencia, y nunca "Instalar Google Chrome". Lo demas de la pagina se desmarca.
$ui.BtnSeguras.ToolTip = (Con-Enie 'Marca solo las opciones sin el icono de advertencia (no incluye instalar Google Chrome).')
$ui.BtnSeguras.Add_Click({
    $p = $script:Pagina
    foreach ($id in @($Casillas[$p].Keys)) {
        $k = $p + '|' + $id
        $cb = $Casillas[$p][$id]
        $riesgo = $Advertencias.ContainsKey($k) -or ($k -eq 'Debloat|chr') -or (($k -eq 'Gaming|xb') -and $script:XbIcono -and ($script:XbIcono.Visibility -eq 'Visible'))
        $cb.IsChecked = ($cb.IsEnabled -and -not $riesgo)
    }
    Actualizar-Contador
})

# Punto de restauracion: antes de aplicar algo pregunta una sola vez (no por cada ajuste) si queres crear uno.
# No pregunta si ya creaste uno en esta sesion, si marcaste "No volver a preguntar" o si los puntos estan apagados.
$script:PuntoHecho = $false
function Preguntar-Punto($selD) {
    if ($script:PuntoHecho) { return $false }
    if (([string](Leer-Config)['punto']) -eq '0') { return $false }
    if ((@($selD) -contains 'rpo') -or ($script:Estados['Debloat|rpo'] -eq $true)) { return $false }
    $w = Nuevo-Dialogo 480
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((Nuevo-Texto 'Crear un punto de restauracion antes de continuar?' 17 '#FFFFFF' $true)) | Out-Null
    $m = Nuevo-Texto 'Guarda una copia de como esta Windows ahora. Si algo sale mal, volves atras en unos minutos. Tarda un poco mas y ocupa algo de espacio en el disco.' 13 '#C3C8D0' $false
    $m.Margin = '0,8,0,0'; $m.LineHeight = 20
    $sp.Children.Add($m) | Out-Null
    $chk = New-Object Windows.Controls.CheckBox
    $chk.Margin = '0,12,0,0'; $chk.VerticalContentAlignment = 'Center'
    $chk.Content = (Nuevo-Texto 'No volver a preguntar' 12.5 '#C3C8D0' $false)
    $sp.Children.Add($chk) | Out-Null
    $bNo = Nuevo-Boton 'No, seguir sin crear'; $bNo.IsCancel = $true
    $bSi = Nuevo-Boton 'Crear y seguir' '#2E8B57'; $bSi.IsDefault = $true
    $bSi.Add_Click({ [Windows.Window]::GetWindow($this).DialogResult = $true })
    $sp.Children.Add((Fila-Botones @() @($bNo, $bSi))) | Out-Null
    $w.Content.Child = $sp
    $ok = ($w.ShowDialog() -eq $true)
    if ($chk.IsChecked -eq $true) { Guardar-Config 'punto' '0' }
    if ($ok) { $script:PuntoHecho = $true }
    return $ok
}

# Botones de Herramientas: cada uno corre el debloat con una sola opcion respondida (con la ventana negra a la vista)
$accionHerr = {
    $par = ([string]$this.Tag) -split '='
    $nombres = @{ ver = 'Actualizar Windows 11'; ms_acc = 'Borrar una cuenta'; al = 'Entrar sin contrasena'; drv = 'Drivers recomendados' }
    $txt = $nombres[$par[0]]
    if ($par[1] -eq 'R') { $txt = 'Volver a usar contrasena' }
    if ($par[0] -eq 'drv') {
        # Drivers corre sin ventana negra: revisa, instala lo que falta desde Windows Update y abre las paginas solo
        if (-not (Confirmar $txt 'Revisa tu PC (tarda un minuto) y te abre la pagina oficial de cada driver recomendado. No instala nada: lo bajas vos desde ahi.' 'Buscar' '#3D6FD9' 'Cancelar')) { return }
        $v = @{ XR_drv = 'S'; XUCA_DRVAPP = '1' }
        $n = 1
        if (Preguntar-Punto @()) { $v['XR_rp'] = 'S'; $n++ }
        Correr @([pscustomobject]@{ Nombre = $txt; Ruta = $Rutas.Debloat; Vars = $v; Cambios = $n; Visible = $false; Tipo = 'drivers' }) $false 'Buscando drivers'
        return
    }
    if (-not (Confirmar $txt 'Se abre la ventana negra del script y ahi te va pidiendo lo que necesita.' 'Seguir' '#3D6FD9' 'Cancelar')) { return }
    $v = @{}; $v['XR_' + $par[0]] = $par[1]
    if (Preguntar-Punto @()) { $v['XR_rp'] = 'S' }
    Correr @([pscustomobject]@{ Nombre = $txt; Ruta = $Rutas.Debloat; Vars = $v; Cambios = 1; Visible = $true; Tipo = 'herramienta' }) $false ''
}
foreach ($b in @($script:BtnVer, $bDrv, $bAcc, $bSin, $bCon)) { $b.Add_Click($accionHerr) }

# Opciones que necesitan un driver que no tenes: antes de seguir te manda a Herramientas y remarca "Buscar drivers"
$script:DrvFalta = @{}
function Pedir-Drivers($claves, [string]$intro) {
    $lineas = @(foreach ($k in $claves) { $pp = $k -split '\|'; '- ' + (Titulo-De $pp[0] $pp[1]) + ': ' + $script:DrvFalta[$k] + '.' })
    if (-not $intro) { $intro = 'Antes de aplicar o seguir con lo que seleccionaste, tenes que instalar los drivers:' }
    $m = ($intro + "`n" + ($lineas -join "`n") + "`n`n" + 'Te llevo a Herramientas, a "Buscar drivers". Cuando los instales, toca "Volver a leer los ajustes".')
    if (Confirmar 'Primero instala los drivers' $m 'Ir a instalar drivers' '#A21CAF' 'Cancelar') { Mostrar-Drivers }
}
function Mostrar-Drivers {
    Ir-A 'Herr'
    $c = $script:CardDrv
    $col = Color-Tema($ColorDrv)
    # Borde magenta que titila unas veces y queda prendido
    Caja-Borde $c $ColorDrv
    $c.Tag.Reposo = 255
    $c.BorderBrush = New-Object Windows.Media.SolidColorBrush $col
    $an = [Windows.Media.Animation.ColorAnimation]::new([Windows.Media.Color]::FromArgb(40, $col.R, $col.G, $col.B), [Windows.Duration]::new([TimeSpan]::FromMilliseconds(450)))
    $an.AutoReverse = $true; $an.RepeatBehavior = New-Object Windows.Media.Animation.RepeatBehavior 4
    $c.BorderBrush.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, $an)
    # Brillo magenta alrededor del boton (se apaga cuando lo tocas)
    $sh = New-Object Windows.Media.Effects.DropShadowEffect
    $sh.Color = $col; $sh.ShadowDepth = 0; $sh.BlurRadius = 20; $sh.Opacity = 0.95
    $script:BtnDrv.Effect = $sh
    $ab = [Windows.Media.Animation.DoubleAnimation]::new(6, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(450)))
    $ab.AutoReverse = $true; $ab.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
    $sh.BeginAnimation([Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty, $ab)
    $win.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Loaded, [Action] { $script:CardDrv.BringIntoView() }) | Out-Null
}

# Aplica lo marcado en Debloat y Gaming, en una sola pasada (lo usan Aplicar y los perfiles)
function Aplicar-Seleccion {
    $selD = Elegidas 'Debloat'
    $selG = Elegidas 'Gaming'
    if (($selD.Count + $selG.Count) -eq 0) { Avisar 'Aplicar' 'No marcaste ninguna opcion.'; return }
    $faltan = @(@($selD | ForEach-Object { 'Debloat|' + $_ }) + @($selG | ForEach-Object { 'Gaming|' + $_ }) | Where-Object { $script:DrvFalta.ContainsKey($_) })
    if ($faltan.Count -gt 0) { Pedir-Drivers $faltan; return }

    $vG = @{}
    foreach ($id in $selG) { $vG['XR_' + $id] = 'S' }
    if (($selG -contains 'pri') -or ($selG -contains 'afi')) {
        # Prioridad alta y afinidad usan la misma lista de juegos guardada
        $L = Leer-Listas
        $jug = @(Procesos-De (Cat-Juegos) $L.juegos)
        if ($jug.Count -eq 0) {
            if (-not (Editar-Juegos $false)) { return }
            $L = Leer-Listas
            $jug = @(Procesos-De (Cat-Juegos) $L.juegos)
            if ($jug.Count -eq 0) { Avisar 'Tus juegos' 'No elegiste ningun juego. Elegi al menos uno o desmarca "Prioridad alta" y "Afinidad".'; return }
        }
        $fon = @(Procesos-De $AfiFondoCat $L.fondo)
        if (($null -eq $L.juegos) -or ($null -eq $L.fondo)) { Guardar-Listas $jug $fon }
        if ($selG -contains 'pri') { $vG['PRIOJ'] = ($jug -join ','); $vG['PRIOSYNC'] = '1' }
        if ($selG -contains 'afi') {
            $vG['AFIAPP'] = '1'
            $vG['AFIJ'] = ($jug -join ',')
            if ($fon.Count -gt 0) { $vG['AFIF'] = ($fon -join ',') }
        }
    }

    $vD = @{}
    foreach ($id in $selD) { $vD['XR_' + $id] = 'S' }
    if ($selD -contains 'av') {
        Start-Process 'windowsdefender://threatsettings'
        if (-not (Confirmar 'Antivirus' ('Para apagar el antivirus del todo, primero apaga vos la "Proteccion contra alteraciones" (Windows no deja que un programa la apague).' + "`n`n" + 'Se abrio Seguridad de Windows. Apagala y despues toca Listo.') 'Listo' '#3D6FD9' 'Cancelar')) { return }
    }

    $n = $selD.Count + $selG.Count
    $txtN = $(if ($n -eq 1) { 'Se va a aplicar 1 cambio.' } else { 'Se van a aplicar ' + $n + ' cambios.' })
    if (-not (Confirmar 'Aplicar cambios' ($txtN + ' Seguir?') 'Aplicar' '#3D6FD9' 'Cancelar')) { return }

    $tareas = @()
    $nD = $selD.Count
    if (Preguntar-Punto $selD) { $vD['XR_rp'] = 'S'; $nD++ }
    if ($nD -gt 0) { $tareas += [pscustomobject]@{ Nombre = $(if ($selD.Count -gt 0) { 'Debloat y privacidad' } else { 'Punto de restauracion' }); Ruta = $Rutas.Debloat; Vars = $vD; Cambios = $nD; Visible = $false; Tipo = 'opciones' } }
    if ($selG.Count -gt 0) { $tareas += [pscustomobject]@{ Nombre = 'Optimizacion gaming'; Ruta = $Rutas.Gaming; Vars = $vG; Cambios = $selG.Count; Visible = $false; Tipo = 'opciones' } }
    Correr $tareas $true 'Aplicando cambios'
}

# Restablece lo marcado en Debloat y Gaming a como viene Windows: es la misma pasada que Aplicar, pero con R.
# Para restablecer todo: "Marcar todo" en las dos paginas y despues Restablecer seleccionadas.
function Restablecer-Seleccion {
    $total = (Elegidas 'Debloat').Count + (Elegidas 'Gaming').Count
    if ($total -eq 0) { Avisar 'Restablecer' 'No marcaste ninguna opcion. Marca las que quieras volver a como vienen en Windows (con "Marcar todo" en Debloat y en Gaming restableces todo).'; return }
    $tareas = @(); $n = 0; $sinR = @(); $sel = @()
    foreach ($p in 'Debloat', 'Gaming') {
        $v = @{}; $c = 0
        foreach ($id in (Elegidas $p)) {
            $it = @($Opciones[$p] | Where-Object { $_.Id -eq $id })[0]
            if ($it -and $it.ConR) { $v['XR_' + $id] = 'R'; $c++; $sel += ($p + '|' + $id) } else { $sinR += (Titulo-De $p $id) }
        }
        if ($c -gt 0) { $tareas += [pscustomobject]@{ Nombre = ('Restablecer ' + $p); Ruta = $Rutas[$p]; Vars = $v; Cambios = $c; Visible = $false; Tipo = 'opciones' }; $n += $c }
    }
    if ($n -eq 0) { Avisar 'Restablecer' ('Las opciones que marcaste no tienen restablecimiento: ' + ($sinR -join ', ') + '.'); return }
    $m = $(if ($n -eq 1) { 'Se va a restablecer 1 opcion a como viene en Windows.' } else { 'Se van a restablecer ' + $n + ' opciones a como vienen en Windows.' })
    $notas = @()
    if ($sel -contains 'Debloat|av') { $notas += 'El antivirus vuelve, pero la Proteccion contra alteraciones la encendes vos y Smart App Control no vuelve sin reinstalar Windows.' }
    if ($sel -contains 'Debloat|bl') { $notas += 'BitLocker solo deja de estar bloqueado: no vuelve a cifrar el disco.' }
    if (($sel -contains 'Debloat|edge') -or ($sel -contains 'Debloat|wg') -or ($sel -contains 'Gaming|xb')) { $notas += 'Edge, los Widgets y la Game Bar se reinstalan (tarda un poco mas).' }
    if ($notas.Count -gt 0) { $m += ("`n`n" + 'Tene en cuenta: ' + ($notas -join ' ')) }
    if ($sinR.Count -gt 0) {
        # Marcaste alguna que no se puede restablecer: se avisa cuales y se pregunta si seguir con el resto
        $q = ('Hay ajustes que no se pueden restablecer y se van a saltear:' + "`n" + (($sinR | ForEach-Object { '- ' + $_ }) -join "`n") + "`n`n" + $m + "`n`n" + 'Deseas continuar igualmente?')
        if (-not (Confirmar 'Algunos ajustes no se pueden restablecer' $q 'Continuar igualmente' '#B3412F' 'Cancelar')) { return }
    } else {
        if (-not (Confirmar 'Restablecer seleccionadas' ($m + "`n`n" + 'Seguir?') 'Restablecer' '#B3412F' 'Cancelar')) { return }
    }
    if (Preguntar-Punto @()) {
        $tD = @($tareas | Where-Object { $_.Ruta -eq $Rutas.Debloat })[0]
        if ($tD) { $tD.Vars['XR_rp'] = 'S'; $tD.Cambios++ }
        else { $tareas = @([pscustomobject]@{ Nombre = 'Punto de restauracion'; Ruta = $Rutas.Debloat; Vars = @{ XR_rp = 'S' }; Cambios = 1; Visible = $false; Tipo = 'opciones' }) + $tareas }
    }
    Correr $tareas $true 'Restableciendo ajustes'
}

$ui.BtnRestablecer.Add_Click({ Restablecer-Seleccion })

$ui.BtnAplicar.Add_Click({
    $p = $script:Pagina

    if ($p -eq 'Limpieza') {
        $v = @{}
        foreach ($k in $Casillas.Limpieza.Keys) { $v[$k] = $(if ($Casillas.Limpieza[$k].IsChecked) { '1' } else { '0' }) }
        if (-not (Confirmar 'Limpiar cache' 'Cerra los juegos y programas abiertos antes de seguir.' 'Limpiar' '#3D6FD9' 'Cancelar')) { return }
        Correr @([pscustomobject]@{ Nombre = 'Limpieza'; Ruta = $Rutas.Limpieza; Vars = $v; Cambios = 1; Visible = $false; Tipo = 'limpieza' }) $false 'Limpiando la cache'
        return
    }

    Aplicar-Seleccion
})

# ------------------------------------------------------------
# Salir: pregunta si queres salir y, si no lo apagaste, muestra el mensaje de Ko-fi
# ------------------------------------------------------------
$KoFi = 'https://ko-fi.com/011xuca'
$script:SalirYa = $false
function Confirmar-Salida {
    $mostrarKofi = ([string](Leer-Config)['kofi']) -ne '0'
    $w = Nuevo-Dialogo 500
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((Nuevo-Texto 'Seguro que queres salir?' 17 '#FFFFFF' $true)) | Out-Null
    $chk = $null
    if ($mostrarKofi) {
        $caja = New-Object Windows.Controls.Border
        $caja.CornerRadius = 10; $caja.Background = (Pincel '#1A2A33'); $caja.BorderBrush = (Pincel '#8FD3F4'); $caja.BorderThickness = 1
        $caja.Padding = '14,12'; $caja.Margin = '0,14,0,0'
        $sk = New-Object Windows.Controls.StackPanel
        $m = Nuevo-Texto 'Este proyecto es gratis y lo hago en mi tiempo libre. Si te sirvio y queres apoyarme, podes donarme un Ko-fi:' 13 '#D3E9F3' $false
        $m.LineHeight = 20
        $sk.Children.Add($m) | Out-Null
        $link = Nuevo-Texto $KoFi 12.5 '#8FD3F4' $false
        $link.Margin = '0,4,0,0'
        $sk.Children.Add($link) | Out-Null
        $bK = Nuevo-Boton 'Apoyar en Ko-fi' '#8FD3F4'; $bK.Foreground = (Pincel '#0B2533')
        $bK.HorizontalAlignment = 'Left'
        $bK.Add_Click({ Abrir-Normal $KoFi })
        $sk.Children.Add($bK) | Out-Null
        $caja.Child = $sk
        $sp.Children.Add($caja) | Out-Null
        $chk = New-Object Windows.Controls.CheckBox
        $chk.Margin = '0,12,0,0'; $chk.VerticalContentAlignment = 'Center'
        $chk.Content = (Nuevo-Texto 'No volver a mostrar el mensaje de Ko-fi' 12.5 '#C3C8D0' $false)
        $sp.Children.Add($chk) | Out-Null
    }
    $bNo = Nuevo-Boton 'Cancelar'; $bNo.IsCancel = $true
    $bSi = Nuevo-Boton 'Salir' '#B3412F'; $bSi.IsDefault = $true
    $bSi.Add_Click({ [Windows.Window]::GetWindow($this).DialogResult = $true })
    $sp.Children.Add((Fila-Botones @() @($bNo, $bSi))) | Out-Null
    $w.Content.Child = $sp
    $ok = ($w.ShowDialog() -eq $true)
    # "No volver a mostrar" se guarda aunque toques Cancelar
    if ($chk -and ($chk.IsChecked -eq $true)) { Guardar-Config 'kofi' '0' }
    return $ok
}

# Cierre suave: todo se desvanece hasta quedar el color del fondo y recien ahi se cierra la ventana
$script:Cerrando = $false
# Si la app se vuelve a abrir (tema, idioma o actualizacion), la ventana vacia espera un rato mas
# para que la nueva aparezca encima antes de que esta se cierre.
function Cerrar-Suave([bool]$reabre) {
    if ($script:Cerrando) { return }
    $script:Cerrando = $true
    $script:EsperaCierre = $(if ($reabre) { 1800 } else { 500 })
    $a = [Windows.Media.Animation.DoubleAnimation]::new(1.0, 0.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(950)))
    $a.EasingFunction = $script:Suave
    # Minimizada no se dibuja nada (la animacion queda frenada): se cierra en el momento
    if ($win.WindowState -eq 'Minimized') { Cerrar-Ya; return }
    # El reloj cuenta aparte de la animacion, asi se cierra aunque la minimices a mitad del desvanecido
    $script:TimerCierre = New-Object Windows.Threading.DispatcherTimer
    $script:TimerCierre.Interval = [TimeSpan]::FromMilliseconds(950 + $script:EsperaCierre)
    $script:TimerCierre.Add_Tick({ Cerrar-Ya })
    $script:TimerCierre.Start()
    $win.Content.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}

function Cerrar-Ya {
    if ($script:TimerCierre) { $script:TimerCierre.Stop() }
    if ($script:SalirYa) { return }
    $script:SalirYa = $true
    $win.Close()
}

# Si la minimizas mientras se desvanece, se cierra enseguida en vez de quedar esperando en la barra de tareas
$win.Add_StateChanged({ if ($script:Cerrando -and ($win.WindowState -eq 'Minimized')) { Cerrar-Ya } })

$win.Add_Closing({
    param($s, $e)
    # Al actualizar o cambiar de idioma la app se cierra sola para abrirse de nuevo: no se pregunta nada
    if ($script:SalirYa) { return }
    # Ya se esta desvaneciendo para cerrarse
    if ($script:Cerrando) { $e.Cancel = $true; return }
    if ($script:Proc -and -not $script:Proc.HasExited) {
        $m = $(if ($script:Tarea -and -not $script:Tarea.Visible) { 'Todavia se estan aplicando cambios. Si cerras la app, el script sigue en segundo plano hasta terminar.' } else { 'Todavia se esta aplicando un script. Si cerras la app, el script sigue solo en su ventana.' })
        if (-not (Confirmar 'Cerrar la app' ($m + "`n`n" + 'Cerrar igual?') 'Cerrar' '#B3412F' 'Seguir en la app')) { $e.Cancel = $true }
        return
    }
    if (-not (Confirmar-Salida)) { $e.Cancel = $true; return }
    # Se frena el cierre para hacerlo con el desvanecido
    $e.Cancel = $true
    Cerrar-Suave
})

# ------------------------------------------------------------
# Tema: el boton de arriba del idioma abre un cartel con Sistema, Claro y Oscuro, y te dice cual usas ahora
# ------------------------------------------------------------
$TemaNombres = @{ sistema = 'Sistema'; claro = 'Claro'; oscuro = 'Oscuro' }
function Texto-Tema {
    $t = 'Tema: ' + $TemaNombres[$script:TemaCfg]
    if ($script:TemaCfg -eq 'sistema') { $t += $(if ($script:Claro) { ' (claro)' } else { ' (oscuro)' }) }
    return (Con-Enie $t)
}
$ui.TemaTxt.Text = (Texto-Tema)
if ($script:Claro) { $ui.BtnRedes.Foreground = $script:bc.ConvertFromString('#0369A1') }

function Elegir-Tema {
    $w = Nuevo-Dialogo 470
    $w.Tag.Elegido = $null
    $sp = New-Object Windows.Controls.StackPanel
    $cab = New-Object Windows.Controls.Grid
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $cab.ColumnDefinitions.Add($c0); $cab.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $ic = Icono-Dialogo 0xE706 '#8AB4F8' 42
    $ic.Margin = '0,0,14,0'
    $cab.Children.Add($ic) | Out-Null
    $tx = New-Object Windows.Controls.StackPanel
    $tx.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($tx, 1)
    $tx.Children.Add((Nuevo-Texto 'Tema de la app' 17 '#FFFFFF' $true)) | Out-Null
    $ahora = 'Ahora usas: ' + $TemaNombres[$script:TemaCfg]
    if ($script:TemaCfg -eq 'sistema') { $ahora += $(if ($script:Claro) { ' (Windows esta en claro)' } else { ' (Windows esta en oscuro)' }) }
    $sub = Nuevo-Texto $ahora 13 '#9AA0A6' $false
    $sub.Margin = '0,4,0,0'
    $tx.Children.Add($sub) | Out-Null
    $cab.Children.Add($tx) | Out-Null
    $sp.Children.Add($cab) | Out-Null
    $winClaro = Windows-EnClaro
    $ops = @(
        @('sistema', 0xE7F4, 'Sistema', ('Usa el mismo modo que Windows (ahora: ' + $(if ($winClaro) { 'claro' } else { 'oscuro' }) + ').')),
        @('claro', 0xE706, 'Claro', 'Fondo claro y letras oscuras.'),
        @('oscuro', 0xE708, 'Oscuro', 'Fondo oscuro y letras claras.')
    )
    $primera = $true
    foreach ($o in $ops) {
        $es = ($o[0] -eq $script:TemaCfg)
        $card = New-Object Windows.Controls.Border
        $card.CornerRadius = 12; $card.Padding = '14,10'; $card.Margin = $(if ($primera) { '0,16,0,0' } else { '0,8,0,0' }); $primera = $false
        $card.Background = (Pincel $(if ($es) { '#1F2D4A' } else { '#232833' }))
        $card.BorderBrush = (Pincel $(if ($es) { '#3D6FD9' } else { '#2E3440' })); $card.BorderThickness = $(if ($es) { 2 } else { 1 })
        $card.Cursor = [Windows.Input.Cursors]::Hand
        $card.Tag = $o[0]
        $g = New-Object Windows.Controls.Grid
        $ca = New-Object Windows.Controls.ColumnDefinition; $ca.Width = 'Auto'
        $cc = New-Object Windows.Controls.ColumnDefinition; $cc.Width = 'Auto'
        $g.ColumnDefinitions.Add($ca); $g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition)); $g.ColumnDefinitions.Add($cc)
        $i1 = Nuevo-Texto ([string][char]$o[1]) 18 '#8AB4F8' $false
        $i1.FontFamily = 'Segoe MDL2 Assets'; $i1.VerticalAlignment = 'Center'; $i1.Margin = '2,0,14,0'
        $g.Children.Add($i1) | Out-Null
        $t2 = New-Object Windows.Controls.StackPanel
        [Windows.Controls.Grid]::SetColumn($t2, 1)
        $t2.Children.Add((Nuevo-Texto $o[2] 14 '#FFFFFF' $true)) | Out-Null
        $d2 = Nuevo-Texto $o[3] 12 '#9AA0A6' $false
        $d2.Margin = '0,2,0,0'
        $t2.Children.Add($d2) | Out-Null
        $g.Children.Add($t2) | Out-Null
        if ($es) {
            $ok = Nuevo-Texto ([string][char]0xE73E) 16 '#8AB4F8' $true
            $ok.FontFamily = 'Segoe MDL2 Assets'; $ok.VerticalAlignment = 'Center'; $ok.Margin = '10,0,2,0'
            [Windows.Controls.Grid]::SetColumn($ok, 2)
            $g.Children.Add($ok) | Out-Null
        }
        $card.Child = $g
        $card.Add_MouseEnter({ if ($this.BorderThickness.Left -lt 2) { $this.BorderBrush = (Pincel '#8AB4F8') } })
        $card.Add_MouseLeave({ if ($this.BorderThickness.Left -lt 2) { $this.BorderBrush = (Pincel '#2E3440') } })
        # Se elige al apretar (no al soltar): el cartel se puede arrastrar y el arrastre se comia el clic.
        # Handled corta el evento para que no llegue al borde del cartel y no empiece a arrastrarlo.
        $card.Add_MouseLeftButtonDown({
            param($s, $e)
            $e.Handled = $true
            $ww = [Windows.Window]::GetWindow($s)
            $ww.Tag.Elegido = [string]$s.Tag
            $ww.DialogResult = $true
        })
        $sp.Children.Add($card) | Out-Null
    }
    $nota = Nuevo-Texto 'Al cambiarlo, la app se vuelve a abrir sola.' 11.5 '#7D8590' $false
    $nota.Margin = '2,12,0,0'
    $sp.Children.Add($nota) | Out-Null
    $bCerrar = Nuevo-Boton 'Cerrar'; $bCerrar.IsCancel = $true
    $sp.Children.Add((Fila-Botones @() @($bCerrar))) | Out-Null
    $w.Content.Child = $sp
    if ($w.ShowDialog() -ne $true) { return }
    $nuevo = [string]$w.Tag.Elegido
    if ((-not $nuevo) -or ($nuevo -eq $script:TemaCfg)) { return }
    $claroNuevo = ($nuevo -eq 'claro') -or (($nuevo -eq 'sistema') -and (Windows-EnClaro))
    Guardar-Config 'tema' $nuevo
    $script:TemaCfg = $nuevo
    # Si se ve igual (por ejemplo Sistema con Windows en oscuro y ya estabas en Oscuro) no hace falta reabrir
    if ($claroNuevo -eq $script:Claro) { $ui.TemaTxt.Text = (Texto-Tema); return }
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $AppPath + '"')
    Cerrar-Suave $true
}
$ui.BtnTema.ToolTip = (Con-Enie 'Cambiar el tema (Sistema, Claro u Oscuro)')
$ui.BtnTema.Add_Click({
    if (($script:Proc -and -not $script:Proc.HasExited) -or $script:UpdRun -or $script:Lectura) { Avisar 'Cambiar tema' 'Espera a que termine lo que se esta aplicando para cambiar el tema.'; return }
    Elegir-Tema
})

# ------------------------------------------------------------
# Idioma: el boton de abajo a la izquierda cambia entre ingles y espanol, lo guarda y abre la app de nuevo
# ------------------------------------------------------------
$ui.IdiomaTxt.Text = $(if ($script:Idioma -eq 'es-mx') { 'Set to English' } else { 'Cambiar a Espa' + $Enie + 'ol' })
$ui.BtnIdioma.ToolTip = (Con-Enie 'Cambiar idioma')
$ui.BtnIdioma.Add_Click({
    if (($script:Proc -and -not $script:Proc.HasExited) -or $script:UpdRun -or $script:Lectura) { Avisar 'Cambiar idioma' 'Espera a que termine lo que se esta aplicando para cambiar el idioma.'; return }
    $nuevo = $(if ($script:Idioma -eq 'es-mx') { 'en-en' } else { 'es-mx' })
    $f = Join-Path (Join-Path $LangDir $nuevo) 'textos.txt'
    if (($nuevo -ne 'es-mx') -and (-not (Test-Path -LiteralPath $f))) { Avisar 'Cambiar idioma' ((Con-Enie 'No se encontro el archivo de idioma:') + "`n" + $f); return }
    Guardar-Config 'idioma' $nuevo
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $AppPath + '"')
    Cerrar-Suave $true
})

# ------------------------------------------------------------
# Zoom: si la ventana queda chica, todo se achica junto en vez de aplastarse.
# Ctrl + rueda del mouse (o Ctrl + y Ctrl -) lo agranda o achica a mano; Ctrl + 0 lo vuelve a normal. Se guarda.
# ------------------------------------------------------------
$AnchoBase = 1080; $AltoBase = 620
$Inv = [Globalization.CultureInfo]::InvariantCulture
$script:ZoomTr = New-Object Windows.Media.ScaleTransform 1.0, 1.0
$ui.Raiz.LayoutTransform = $script:ZoomTr
$script:ZoomUsuario = 1.0
try {
    $zz = 0.0
    if ([double]::TryParse([string](Leer-Config)['zoom'], [Globalization.NumberStyles]::Float, $Inv, [ref]$zz) -and ($zz -ge 0.6) -and ($zz -le 1.6)) { $script:ZoomUsuario = $zz }
} catch { }
$script:ZoomReal = 1.0

function Ajustar-Zoom {
    $w = $ui.Marco.ActualWidth; $h = $ui.Marco.ActualHeight
    if (($w -le 0) -or ($h -le 0)) { return }
    # Nunca mas grande de lo que entra: el contenido siempre tiene el lugar para el que fue armado
    $s = [math]::Min($script:ZoomUsuario, [math]::Min($w / $AnchoBase, $h / $AltoBase))
    $s = [math]::Max(0.3, $s)
    $script:ZoomReal = $s
    $script:ZoomTr.ScaleX = $s; $script:ZoomTr.ScaleY = $s
}

function Cambiar-Zoom([double]$nuevo) {
    $nuevo = [math]::Round([math]::Max(0.6, [math]::Min(1.6, $nuevo)), 2)
    $script:ZoomUsuario = $nuevo
    Guardar-Config 'zoom' $nuevo.ToString($Inv)
    Ajustar-Zoom
    if ($script:Ocupado) { return }
    $t = (Con-Enie 'Zoom: ') + [int][math]::Round($script:ZoomReal * 100) + '%'
    if ($script:ZoomUsuario -gt ($script:ZoomReal + 0.01)) { $t += (Con-Enie ' (maximo para este tamano de ventana)') }
    $ui.Estado.Text = ($t + '  -  ' + (Con-Enie 'Ctrl + 0 lo vuelve al tamano normal'))
}

$ui.Marco.Add_SizeChanged({ Ajustar-Zoom })
$win.Add_PreviewMouseWheel({
    param($o, $e)
    if (([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) -eq 0) { return }
    Cambiar-Zoom ($script:ZoomUsuario + $(if ($e.Delta -gt 0) { 0.1 } else { -0.1 }))
    $e.Handled = $true
})
$win.Add_PreviewKeyDown({
    param($o, $e)
    if (([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) -eq 0) { return }
    $k = [string]$e.Key
    if ($k -in 'OemPlus', 'Add') { Cambiar-Zoom ($script:ZoomUsuario + 0.1); $e.Handled = $true }
    elseif ($k -in 'OemMinus', 'Subtract') { Cambiar-Zoom ($script:ZoomUsuario - 0.1); $e.Handled = $true }
    elseif ($k -in 'D0', 'NumPad0') { Cambiar-Zoom 1.0; $e.Handled = $true }
})

$win.Add_ContentRendered({ Buscar-Actualizacion; Cargar-Configs $false })

# Si algo falla al tocar un boton, la app no se cierra: el error queda anotado en logs\app_errores.txt y se avisa.
$script:EnError = $false
$win.Dispatcher.Add_UnhandledException({
    param($o, $e)
    $e.Handled = $true
    $ex = $e.Exception
    while ($ex.InnerException -and (-not $ex.ErrorRecord)) { $ex = $ex.InnerException }
    $lin = ''
    try { if ($ex.ErrorRecord -and $ex.ErrorRecord.InvocationInfo) { $lin = [string]$ex.ErrorRecord.InvocationInfo.ScriptLineNumber } } catch { }
    try {
        $d = Join-Path $Scripts 'logs'
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Add-Content -LiteralPath (Join-Path $d 'app_errores.txt') -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] linea ' + $lin + ': ' + $ex.Message) -Encoding UTF8
    } catch { }
    if ($script:EnError) { return }
    $script:EnError = $true
    try { Avisar 'No se pudo completar' ((Con-Enie 'Algo fallo, pero la app sigue abierta. Proba de nuevo; el detalle quedo en la carpeta de logs (app_errores.txt).') + "`n`n" + $ex.Message) } catch { }
    $script:EnError = $false
})

Ir-A 'Inicio'
$ui.Estado.Text = ''
$win.ShowDialog() | Out-Null

} catch {
    Mostrar-Error ('La app tuvo un error y se cerro:' + "`n`n" + $_.Exception.Message + "`n`n" + 'Linea: ' + $_.InvocationInfo.ScriptLineNumber)
}
