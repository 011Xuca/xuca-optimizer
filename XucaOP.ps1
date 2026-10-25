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
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $PSCommandPath + '"')
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Mostrar-Error($msg) {
    [Windows.MessageBox]::Show($msg, 'Xuca OPtimizer', 'OK', 'Error') | Out-Null
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
$VersionLocal = Join-Path $Root 'version.txt'
$ArchivosUpd = @(
    [pscustomobject]@{ Nombre = 'XucaOP.ps1'; Local = $AppPath; Remoto = 'XucaOP.ps1' },
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
# Idioma (por defecto ingles). Cada idioma tiene su carpeta en lang\<idioma>\textos.txt
# (cada linea: texto en espanol tal cual esta en la app o en los .bat, TAB, texto a mostrar).
# El espanol viene adentro de la app: lang\es-mx\textos.txt sirve para corregir textos sin tocar el codigo.
# Si falta el archivo de ingles, la app se muestra en espanol.
# ------------------------------------------------------------
$LangDir = Join-Path $Root 'lang'
$script:Idioma = [string](Leer-Config)['idioma']
if (-not $script:Idioma) { $script:Idioma = 'en-en' }
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
    @('\banos\b', ('a' + $Enie + 'os'))
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
$SoloScript = @('ver', 'ms_acc', 'al', 'cta')

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
'@
. ([scriptblock]::Create($FuncLectura))

# ------------------------------------------------------------
# Lista de juegos y de programas de fondo (compartida por "Prioridad alta" y "Afinidad")
# ------------------------------------------------------------
# Los catalogos se leen del .bat de gaming para no tenerlos repetidos
$AfiJuegosCat = ''; $AfiFondoCat = ''; $FuncCpu = ''
try {
    $tg = [IO.File]::ReadAllText($Rutas.Gaming)
    $AfiJuegosCat = [regex]::Match($tg, "(?m)^\`$afiJuegosCat = '([^']*)'").Groups[1].Value
    $AfiFondoCat = [regex]::Match($tg, "(?m)^\`$afiFondoCat = '([^']*)'").Groups[1].Value
    # Funciones que leen el procesador y dicen cuanto cambia la afinidad y si hace falta la Game Bar
    $FuncCpu = [regex]::Match($tg, '(?s)# >>> XUCA-CPU.*?# <<< XUCA-CPU').Value
} catch { }

$XucaDir = Join-Path $env:ProgramData 'XucaScripts'
$ListasArchivo = Join-Path $XucaDir 'listas_app.txt'

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
        Where-Object { $_ -and ($_ -match '^[^\\/:*?"<>|=;]+$') } | Select-Object -Unique)
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
    return $r
}

function Guardar-Listas($juegos, $fondo) {
    if (-not (Test-Path -LiteralPath $XucaDir)) { New-Item -ItemType Directory -Path $XucaDir -Force | Out-Null }
    $l = @()
    if ($null -ne $juegos) { $l += ('juegos=' + (@($juegos) -join ',')) }
    if ($null -ne $fondo) { $l += ('fondo=' + (@($fondo) -join ',')) }
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
        foreach ($pr in $actual) { if ($conocidos -notcontains $pr) { $items += [pscustomobject]@{ Procs = @($pr); Nombre = $pr; Marcado = $true } } }
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
    'Debloat|tel'   = { (Leer-Svc 'DiagTrack') -eq 4 }
    'Debloat|wg'    = { -not (HasAppx 'MicrosoftWindows.Client.WebExperience') }
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
    'Gaming|notif'  = { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled') -eq 0 }
    'Gaming|gf'     = { ((Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode') -eq 2) -and (([string](Leer-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings')) -like '*SwapEffectUpgradeEnable=1*') }
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
        $vals = @()
        foreach ($ad in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })) {
            foreach ($kw in '*EEE', 'EEE', 'AdvancedEEE', 'GreenEthernet', 'EnableGreenEthernet', 'PowerSavingMode') {
                $p = Get-NetAdapterAdvancedProperty -Name $ad.Name -RegistryKeyword $kw -ErrorAction SilentlyContinue
                if ($p) { $vals += [string]$p.RegistryValue }
            }
        }
        if ($vals.Count -eq 0) { return $null }
        @($vals | Where-Object { $_ -ne '0' }).Count -eq 0
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
        Title="Xuca OPtimizer" Width="1080" Height="740" MinWidth="880" MinHeight="580"
        WindowStartupLocation="CenterScreen" Background="#14161B" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Nav" TargetType="Button">
      <Setter Property="Foreground" Value="#C9CDD4"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Padding" Value="14,10"/>
      <Setter Property="Margin" Value="0,0,0,4"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#232833"/>
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
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Opacity" Value="0.85"/>
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
            <Border x:Name="b" Background="#F2C94C" CornerRadius="10" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
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
  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="230"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="#0E1014" Padding="16,22">
      <DockPanel LastChildFill="False">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Text="Xuca OPtimizer" Foreground="White" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,14"/>
          <Button x:Name="NavPerfiles" Style="{StaticResource Nav}" Content="Perfiles"/>
          <Button x:Name="NavDebloat" Style="{StaticResource Nav}" Content="Debloat y privacidad"/>
          <Button x:Name="NavGaming" Style="{StaticResource Nav}" Content="Optimizacion gaming"/>
          <Button x:Name="NavLimpieza" Style="{StaticResource Nav}" Content="Limpiar cache"/>
          <Button x:Name="NavHerr" Style="{StaticResource Nav}" Content="Herramientas"/>
        </StackPanel>
        <StackPanel DockPanel.Dock="Bottom">
          <Button x:Name="BtnIdioma" Style="{StaticResource Nav}" Margin="0,0,0,10">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0"/>
              <TextBlock x:Name="IdiomaTxt" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="BtnRefrescar" Style="{StaticResource Nav}" Content="Volver a leer los ajustes"/>
          <Button x:Name="BtnLogs" Style="{StaticResource Nav}" Content="Abrir carpeta de logs"/>
          <Button x:Name="BtnRedes" Style="{StaticResource Nav}" Content="Visita mis redes sociales!" Foreground="#F9A8D4" FontWeight="SemiBold"/>
          <TextBlock Text="Los scripts tambien se pueden usar solos, sin la app." Foreground="#5C6370" FontSize="11" TextWrapping="Wrap" Margin="4,8,0,0"/>
        </StackPanel>
      </DockPanel>
    </Border>

    <Grid Grid.Column="1" Margin="28,22,28,18">
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
        <TextBlock x:Name="Titulo" Foreground="White" FontSize="24" FontWeight="SemiBold"/>
        <TextBlock x:Name="Descripcion" Foreground="#9AA0A6" FontSize="13" TextWrapping="Wrap" Margin="0,4,0,0"/>
      </StackPanel>
      <ScrollViewer x:Name="Scroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,8,0"/>
      <DockPanel Grid.Row="2" Margin="0,14,0,0">
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
          <Button x:Name="BtnTodo" Style="{StaticResource Accion}" Content="Marcar todo"/>
          <Button x:Name="BtnNada" Style="{StaticResource Accion}" Content="Desmarcar todo"/>
          <Button x:Name="BtnRestablecer" Style="{StaticResource Accion}" Background="#7A3326" Content="Restablecer seleccionadas"/>
          <Button x:Name="BtnAplicar" Style="{StaticResource Accion}" Background="#3D6FD9" Content="Aplicar seleccionadas"/>
        </StackPanel>
        <TextBlock x:Name="Estado" Foreground="#9AA0A6" FontSize="12.5" VerticalAlignment="Center" TextWrapping="Wrap"/>
      </DockPanel>
    </Grid>

    <!-- Pantalla de carga: tapa todo mientras lee Windows o aplica cambios -->
    <Grid x:Name="Carga" Grid.ColumnSpan="2" Background="#14161B" Panel.ZIndex="10">
      <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="440">
        <TextBlock Text="Xuca OPtimizer" Foreground="White" FontSize="30" FontWeight="SemiBold" HorizontalAlignment="Center"/>
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
    </Grid>

    <!-- Numero de version arriba a la derecha: siempre a la vista, incluso sobre la pantalla de carga. En rojo si esta desactualizada. -->
    <TextBlock x:Name="VersionTxt" Grid.ColumnSpan="2" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,4,12,0"
               Panel.ZIndex="20" FontSize="12" FontWeight="SemiBold" Foreground="#5C6370" IsHitTestVisible="False"/>
  </Grid>
</Window>
'@
# Los textos fijos de la ventana tambien pasan por el idioma elegido
if ($script:Trad) {
    $XamlTexto = [regex]::Replace($XamlTexto, '(?<=\s(?:Text|Content)=")[^"&]*[A-Za-z][^"&]*(?=")', [Text.RegularExpressions.MatchEvaluator] { param($m) [Security.SecurityElement]::Escape((Traducir $m.Value)) })
}
[xml]$xaml = $XamlTexto

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'NavPerfiles', 'NavDebloat', 'NavGaming', 'NavLimpieza', 'NavHerr', 'BtnRefrescar', 'BtnLogs', 'BtnRedes', 'Titulo', 'Descripcion', 'Scroll', 'BtnTodo', 'BtnNada', 'BtnRestablecer', 'BtnAplicar', 'Estado', 'Carga', 'CargaTitulo', 'CargaBarra', 'CargaPct', 'CargaDetalle', 'CargaZona', 'CargaInfo', 'UpdCarga', 'BtnUpd', 'BtnUpdNo', 'UpdTitulo', 'UpdTexto', 'BtnUpdBarra', 'UpdBarraTexto', 'VersionTxt', 'OrigBarra', 'OrigTexto', 'BtnIdioma', 'IdiomaTxt') { $ui[$n] = $win.FindName($n) }

# Numero de version (sale del version.txt de tu PC)
function Poner-Version([bool]$vieja) {
    $v = ''
    try { if (Test-Path -LiteralPath $VersionLocal) { $v = (([IO.File]::ReadAllText($VersionLocal) -replace '^\uFEFF', '') -split "`r?`n")[0].Trim() } } catch { }
    if (-not $v) { $v = 'sin version' } elseif ($v -notmatch '^[vV]') { $v = 'v' + $v }
    if ($vieja) { $v += (Con-Enie ' (desactualizada)') }
    $ui.VersionTxt.Text = (Con-Enie $v)
    $ui.VersionTxt.Foreground = $(if ($vieja) { (New-Object Windows.Media.BrushConverter).ConvertFromString('#F28B82') } else { (New-Object Windows.Media.BrushConverter).ConvertFromString('#5C6370') })
}
Poner-Version $false

foreach ($b in @($ui.BtnAplicar, $ui.BtnRestablecer)) { [Windows.Controls.ToolTipService]::SetShowOnDisabled($b, $true) }

$bc = New-Object Windows.Media.BrushConverter
function Pincel([string]$hex) { return $bc.ConvertFromString($hex) }

function Nuevo-Texto([string]$t, [double]$tam, [string]$color, [bool]$negrita) {
    $tb = New-Object Windows.Controls.TextBlock
    $tb.Text = (Con-Enie $t); $tb.FontSize = $tam; $tb.Foreground = (Pincel $color); $tb.TextWrapping = 'Wrap'
    if ($negrita) { $tb.FontWeight = 'SemiBold' }
    return $tb
}

function Agregar-Linea($tb, [string]$etiqueta, [string]$color, [string]$texto) {
    if (-not $texto) { return }
    if ($tb.Inlines.Count -gt 0) { $tb.Inlines.Add((New-Object Windows.Documents.LineBreak)) }
    $r1 = New-Object Windows.Documents.Run((Con-Enie $etiqueta)); $r1.Foreground = (Pincel $color); $r1.FontWeight = 'SemiBold'
    $r2 = New-Object Windows.Documents.Run((Con-Enie $texto))
    $tb.Inlines.Add($r1); $tb.Inlines.Add($r2)
}

function Nueva-Caja {
    $card = New-Object Windows.Controls.Border
    $card.CornerRadius = 10; $card.Background = (Pincel '#1C2027'); $card.Padding = '16,12'; $card.Margin = '0,0,0,10'
    return $card
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
    $borde = New-Object Windows.Controls.Border
    $borde.CornerRadius = 12; $borde.Background = (Pincel '#1C2027'); $borde.BorderBrush = (Pincel '#2E3440'); $borde.BorderThickness = 1
    $borde.Padding = '24,20,24,18'; $borde.Margin = 12
    $sombra = New-Object Windows.Media.Effects.DropShadowEffect
    $sombra.BlurRadius = 18; $sombra.ShadowDepth = 0; $sombra.Opacity = 0.5
    $borde.Effect = $sombra
    $w.Content = $borde
    # Se arrastra tocando cualquier parte vacia
    $borde.Add_MouseLeftButtonDown({ try { [Windows.Window]::GetWindow($this).DragMove() } catch { } })
    return $w
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

# Pregunta Si/No. Devuelve $true si tocas el boton principal. Sin $textoNo es solo un aviso con un boton.
function Confirmar([string]$titulo, [string]$mensaje, [string]$textoSi, [string]$colorSi, [string]$textoNo) {
    if (-not $textoSi) { $textoSi = 'Seguir' }
    if (-not $colorSi) { $colorSi = '#3D6FD9' }
    $w = Nuevo-Dialogo 470
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((Nuevo-Texto $titulo 17 '#FFFFFF' $true)) | Out-Null
    $m = Nuevo-Texto $mensaje 13 '#C3C8D0' $false
    $m.Margin = '0,8,0,0'; $m.LineHeight = 20
    $sp.Children.Add($m) | Out-Null
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
        else { Lista-Agregar $n @($n) $true }
    }
    if ($nuevos.Count -gt 0) { $script:Lst.Scroll.ScrollToEnd() }
}

# Abren la lista compartida y la guardan al instante. Devuelven $false si cancelaste.
# Con $aplicar, si la prioridad alta o la afinidad ya estan activas, se vuelven a aplicar solas con la lista nueva.
function Editar-Juegos([bool]$aplicar) {
    $L = Leer-Listas
    $r = Elegir-Lista 'Tus juegos' ('Esta lista la usan "Prioridad alta" y "Afinidad de CPU": lo que marques aca vale para las dos.' + "`n" + 'Al guardar, si alguna de las dos ya esta activa, se actualiza sola con la lista nueva.') (Items-De $AfiJuegosCat $L.juegos) 'Agregar otros juegos: escribi su proceso sin .exe (separados por comas) y toca Agregar. Lo ves con el juego abierto: Administrador de tareas, pestana Detalles.' (Items-De $AfiJuegosCat $null)
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
    $jug = @(Procesos-De $AfiJuegosCat $L.juegos)
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

function Nueva-Tarjeta($it, $casillas, [bool]$marcada, [string]$pagina) {
    $clave = $pagina + '|' + $it.Id
    $adv = $Advertencias[$clave]
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
    $cb.Content = $tit; $cb.VerticalContentAlignment = 'Center'; $cb.IsChecked = $marcada
    $cb.Tag = $it.Id
    $cb.Add_Click({ Actualizar-Contador })
    $head.Children.Add($cb) | Out-Null
    $sp.Children.Add($head) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.Margin = '24,6,0,0'; $d.LineHeight = 19
    Agregar-Linea $d 'Que hace: ' '#8AB4F8' $it.Hace
    Agregar-Linea $d 'A favor: ' '#81C995' $it.Favor
    Agregar-Linea $d 'En contra: ' '#F28B82' $it.Contra
    if ($adv) { Agregar-Linea $d ($Aviso + ' Puede dar problemas: ') '#E5B567' $adv }
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
    $tj = Resumen-De $AfiJuegosCat $L.juegos 'Tus juegos'
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
    if ($b -lt 22000) { $r['Debloat|wg'] = ($nv + 'Windows 11 (los Widgets no existen en Windows 10). Tenes ' + $tuyo + '.') }
    if (-not $i.BitLocker) { $r['Debloat|bl'] = 'Tu edicion de Windows no tiene BitLocker: viene en Pro, Enterprise y Education.' }
    if (-not $i.Winget) { $r['Debloat|chr'] = 'Falta winget en tu PC: instala o actualiza el "Instalador de aplicaciones" desde la Microsoft Store.' }
    if ($b -lt 22000) { $r['Gaming|tr'] = ($nv + 'Windows 11 (el temporizador global fijo no existe en Windows 10). Tenes ' + $tuyo + '.') }
    if (($b -lt 26100) -or (($b -lt 26300) -and ([int]$i.Ubr -lt 8655))) { $r['Gaming|ll'] = ('Tu Windows todavia no trae Baja latencia: necesita Windows 11 24H2 o 25H2 con la actualizacion de junio de 2026 (build .8655 o mas nueva). Tenes la build ' + $b + '.' + $i.Ubr + ': actualiza Windows.') }
    if ($b -lt 19041) { $r['Gaming|gf'] = ($nv + 'Windows 10 2004 o mas nuevo. Tenes ' + $tuyo + '.') }
    if (([int]$i.RamGB -lt 16) -or $i.Hdd) {
        $q = @()
        if ([int]$i.RamGB -lt 16) { $q += ('tenes ' + $i.RamGB + ' GB de RAM') }
        if ($i.Hdd) { $q += 'Windows esta en un disco HDD' }
        $r['Gaming|sm'] = ('Tu PC no cumple los requisitos: necesita 16 GB de RAM o mas y Windows en un SSD o NVMe (' + ($q -join ' y ') + ').')
    }
    if ($i.AvOff) { $r['Gaming|avl'] = 'No hace falta: tu antivirus ya esta apagado.' }
    if ($cpu -and (-not $cpu.Ok)) { $r['Gaming|afi'] = ('Tu procesador no sirve para esto: ' + $cpu.Motivo + '.') }
    return $r
}

# Deshabilita (gris, sin poder marcar) lo que no es compatible, y "Crear un punto de restauracion"
# si marcaste (o ya tenes) los puntos apagados para siempre.
function Actualizar-Bloqueos {
    foreach ($k in @($script:Tarjetas.Keys)) {
        $t = $script:Tarjetas[$k]
        $motivo = $null
        $noComp = $script:NoDisp.ContainsKey($k)
        if ($noComp) { $motivo = $script:NoDisp[$k] }
        elseif ($k -eq 'Debloat|rp') {
            $rpo = $Casillas.Debloat['rpo']
            if ($rpo -and ($rpo.IsChecked -eq $true)) { $motivo = 'Marcaste apagar los puntos de restauracion para siempre: no se puede crear uno.' }
            elseif ($script:Estados['Debloat|rpo'] -eq $true) { $motivo = 'Tenes los puntos de restauracion apagados: no se puede crear uno. Para volver a usarlos, marca "Apagar los puntos de restauracion para siempre" y toca Restablecer seleccionadas.' }
        }
        if ($motivo) {
            # Gris y sin poder marcar; al pasar el mouse por encima dice por que
            $t.Cb.IsChecked = $false; $t.Cb.IsEnabled = $false
            $t.Card.Opacity = $(if ($noComp) { 0.4 } else { 0.55 })
            $t.Card.Background = (Pincel $(if ($noComp) { '#181A1F' } else { '#1C2027' }))
            $motivo = Con-Enie $motivo
            $t.Nota.Text = $motivo; $t.Nota.Foreground = (Pincel $(if ($noComp) { '#9AA0A6' } else { '#E5B567' })); $t.Nota.Visibility = 'Visible'
            $t.Card.ToolTip = $motivo; $t.Cb.ToolTip = $motivo
        } else {
            $t.Cb.IsEnabled = $true
            $t.Card.Opacity = 1
            $t.Card.Background = (Pincel '#1C2027')
            $t.Nota.Visibility = 'Collapsed'
            $t.Card.ToolTip = $null; $t.Cb.ToolTip = $null
        }
    }
    Actualizar-BotonesAccion
}

# Aplicar y Restablecer quedan en gris si no marcaste nada (en Limpiar cache siempre hay algo que limpiar)
function Actualizar-BotonesAccion {
    if ($script:Ocupado) { return }
    $hay = (@(Elegidas 'Debloat').Count + @(Elegidas 'Gaming').Count) -gt 0
    $msg = Con-Enie 'Marca al menos una opcion en Debloat o en Gaming.'
    $ui.BtnAplicar.IsEnabled = ($hay -or ($script:Pagina -eq 'Limpieza'))
    $ui.BtnAplicar.ToolTip = $(if ($ui.BtnAplicar.IsEnabled) { $null } else { $msg })
    $ui.BtnRestablecer.IsEnabled = $hay
    $ui.BtnRestablecer.ToolTip = $(if ($hay) { $null } else { $msg })
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
        D = @('rp', 'rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia')
        G = @('tk', 'du', 'gm', 'ext', 'md')
    },
    [pscustomobject]@{
        Id = 'comp'; Nombre = 'Competitivo'; Color = '#8AB4F8'
        Hace = 'lo maximo para jugar sin tocar la seguridad: mouse sin aceleracion, prioridad y afinidad para tus juegos, plan Alto rendimiento, Modo Nitro del procesador, temporizador al minimo, GPU por hardware, menos latencia de red, DNS mas rapido, sin Game Bar y sin notificaciones en partida.'
        Ideal = 'jugar competitivo (Valorant, CS2, Fortnite, Warzone) con la PC protegida.'
        NoToca = 'el antivirus, BitLocker, la integridad de memoria ni VBS; tampoco borra apps.'
        Adv = 'el plan Alto rendimiento y el temporizador al minimo suben el consumo y el calor; con undervolt u overclock la PC puede colgarse.'
        D = @('rp')
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'gm', 'xb', 'notif', 'gf', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'avl', 'md', 'v4')
    },
    [pscustomobject]@{
        Id = 'compopt'; Nombre = 'Competitivo + Optimizado'; Color = '#C58AF9'
        Hace = 'todo lo de Competitivo y lo de Seguro, y ademas borra las apps basura, apaga la hibernacion, los efectos visuales, los sonidos, servicios que casi nadie usa y el Storage Sense, y Windows Update deja de instalar drivers.'
        Ideal = 'la PC de juego de todos los dias: el mayor rendimiento con la PC todavia protegida.'
        NoToca = 'el antivirus, BitLocker, la integridad de memoria ni VBS.'
        Adv = 'borrar las apps basura no tiene restablecimiento: se reinstalan a mano desde la Store.'
        D = @('rp', 'rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia', 'hib', 'fx', 'sch', 'sv', 'wud', 'db')
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'll', 'gm', 'xb', 'notif', 'gf', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'avl', 'md', 'v4', 'ext', 'stg')
    },
    [pscustomobject]@{
        Id = 'full'; Nombre = 'Full Optimizado'; Color = '#F28B82'
        Hace = 'Windows lo mas liviano posible: todo el debloat y la optimizacion del sistema, y ademas apaga la seguridad (antivirus, BitLocker, integridad de memoria y VBS), activa el modo MSI, bloquea la telemetria en hosts y apaga Teredo y Windows Search.'
        Ideal = 'una PC justa o vieja que necesita todo el rendimiento del sistema, sabiendo lo que haces.'
        NoToca = 'los ajustes de juego competitivo (mouse, prioridad, afinidad, plan de energia, temporizador y red), ni Edge ni Chrome. Crea un punto de restauracion antes de empezar.'
        Adv = 'la PC queda sin antivirus. Borra Riot Vanguard y cierra Riot (lo reinstalas abriendo el cliente de Riot), y deja de andar WSL, Docker y las maquinas virtuales.'
        D = @('rp', 'rc', 'et', 'apps', 'tel', 'wg', 'do', 'ad', 'pv', 'tp', 'eb', 'su', 'ia', 'hib', 'fx', 'sch', 'sv', 'wud', 'db', 'av', 'bl', 'hst', 'ter')
        G = @('tk', 'du', 'gm', 'ext', 'md', 'mm', 'll', 'xb', 'gf', 'pca', 'ram', 'sm', 'stg', 'msi', 'mi', 'vbs', 'wsr')
    },
    [pscustomobject]@{
        Id = 'fullcomp'; Nombre = 'Full Optimizado + Competitivo'; Color = '#FF6B6B'
        Hace = 'todo, todo: cada opcion de Debloat y de Gaming. Es Full Optimizado mas todos los ajustes competitivos (mouse, prioridad y afinidad para tus juegos, plan Alto rendimiento, Modo Nitro, temporizador al minimo, red, DNS y notificaciones).'
        Ideal = 'una PC que es solo para jugar, donde queres el maximo absoluto y sabes lo que haces.'
        NoToca = 'Edge ni Chrome. No apaga los puntos de restauracion: crea uno antes de empezar.'
        Adv = 'suma los riesgos de Full Optimizado y de Competitivo: sin antivirus, Vanguard se borra (lo reinstalas abriendo el cliente de Riot), y con undervolt u overclock la PC puede colgarse por el plan de energia y el temporizador.'
        D = @('rp', 'av', 'bl', 'hib', 'rc', 'sch', 'fx', 'et', 'apps', 'tel', 'wg', 'do', 'wud', 'wup', 'ad', 'sv', 'pv', 'ter', 'tp', 'hst', 'eb', 'su', 'ia', 'db')
        G = @('ms', 'tk', 'du', 'mm', 'pri', 'afi', 'pw', 'cpu', 'll', 'gm', 'xb', 'notif', 'gf', 'mpo', 'msi', 'pca', 'tr', 'ram', 'sm', 'pe', 'nic', 'nag', 'dns', 'mi', 'vbs', 'wsr', 'stg', 'ext', 'md', 'v4')
    }
)

$spP = New-Object Windows.Controls.StackPanel
$script:InfoPC = Nuevo-Texto 'Tu PC: leyendo...' 13 '#9AA0A6' $false
$script:InfoPC.Margin = '2,0,0,12'
$spP.Children.Add($script:InfoPC) | Out-Null
$script:PerfilTxt = @{}
foreach ($pf in $Perfiles) {
    $card = Nueva-Caja
    $card.BorderBrush = (Pincel $pf.Color); $card.BorderThickness = '4,0,0,0'
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
    if ($script:NoDisp.Count -gt 0) { $t += ('  -  ' + $script:NoDisp.Count + ' opciones no son compatibles: quedan en gris y se saltean solas') }
    $script:InfoPC.Text = (Con-Enie $t)
}

# Marca solo las opciones del perfil (desmarca el resto). Saltea lo no compatible y lo que ya esta aplicado.
# Devuelve cuantas marco.
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
    if ($id -like 'full*') {
        if (-not (Confirmar ($Aviso + ' ' + $pf.Nombre) ('Este perfil apaga el antivirus, BitLocker, la integridad de memoria y VBS. La PC queda sin proteccion contra virus.' + "`n`n" + 'Seguir?') 'Si, aplicar' '#B3412F' 'Cancelar')) { return }
    }
    if ((Marcar-Perfil $id) -eq 0) { return }
    Aplicar-Seleccion
}

$Textos = @{
    Perfiles  = @('Perfiles', 'Elegi un perfil armado: aplicalo con un toque, o marcalo para revisar y ajustar las opciones antes de aplicar. Lo que no es compatible con tu PC o ya tenes aplicado se saltea solo.')
    Debloat   = @('Debloat y privacidad', 'Lo que se puede sacar o apagar de Windows. Lo que marques aca y en Gaming se aplica junto con un solo Aplicar.')
    Gaming    = @('Optimizacion gaming', 'Ajustes para mas FPS y menos latencia. Lo que marques aca y en Debloat se aplica junto con un solo Aplicar.')
    Limpieza  = @('Limpiar cache', 'Libera espacio. Lo de arriba se limpia siempre; lo de abajo solo si lo marcas.')
    Herr      = @('Herramientas', 'Opciones que te piden datos en la ventana del script.')
}
$Nav = @{ Perfiles = $ui.NavPerfiles; Debloat = $ui.NavDebloat; Gaming = $ui.NavGaming; Limpieza = $ui.NavLimpieza; Herr = $ui.NavHerr }
$script:Pagina = 'Debloat'
$script:Ocupado = $false

function Elegidas([string]$p) {
    return @($Casillas[$p].Keys | Where-Object { $Casillas[$p][$_].IsChecked -eq $true })
}

function Actualizar-Contador {
    Actualizar-Bloqueos
    if ($script:Ocupado) { return }
    $d = (Elegidas 'Debloat').Count; $g = (Elegidas 'Gaming').Count
    if (($d + $g) -eq 0) { $ui.Estado.Text = (Con-Enie $(if ($script:EstadoLeido) { $script:EstadoLeido } else { 'No hay opciones marcadas.' })) }
    else { $ui.Estado.Text = (Con-Enie ('Marcadas: ' + $d + ' en Debloat y ' + $g + ' en Gaming. Se guardan aunque cambies de pagina.')) }
}

function Ir-A([string]$p) {
    $script:Pagina = $p
    foreach ($k in $Nav.Keys) { $Nav[$k].Background = (Pincel $(if ($k -eq $p) { '#232833' } else { '#00000000' })) }
    $ui.Titulo.Text = (Con-Enie $Textos[$p][0])
    $ui.Descripcion.Text = (Con-Enie $Textos[$p][1])
    $ui.Scroll.Content = $Paginas[$p]
    $ui.Scroll.ScrollToTop()
    $vis = $(if ($p -in 'Herr', 'Perfiles') { 'Collapsed' } else { 'Visible' })
    $ui.BtnTodo.Visibility = $vis; $ui.BtnNada.Visibility = $vis
    $ui.BtnRestablecer.Visibility = $(if ($p -in 'Debloat', 'Gaming') { 'Visible' } else { 'Collapsed' })
    $ui.BtnAplicar.Visibility = $(if ($p -in 'Herr', 'Perfiles') { 'Collapsed' } else { 'Visible' })
    $ui.BtnAplicar.Content = (Con-Enie $(if ($p -eq 'Limpieza') { 'Limpiar ahora' } else { 'Aplicar seleccionadas' }))
    Actualizar-BotonesAccion
}

function Bloquear([bool]$si) {
    $script:Ocupado = $si
    foreach ($b in @($ui.NavPerfiles, $ui.NavDebloat, $ui.NavGaming, $ui.NavLimpieza, $ui.NavHerr, $ui.BtnRefrescar, $ui.BtnTodo, $ui.BtnNada, $ui.BtnRestablecer, $ui.BtnAplicar)) { $b.IsEnabled = -not $si }
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

function Mostrar-Carga([string]$titulo, [bool]$conFade) {
    $c = $script:Carga
    $c.Objetivo = 0.0; $c.Mostrado = 0.0; $c.Cerrar = $false
    $ui.CargaBarra.Width = 0; $ui.CargaPct.Text = '0%'
    $ui.CargaTitulo.Text = (Con-Enie $titulo); $ui.CargaDetalle.Text = ''
    $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
    $yaVisible = ($ui.Carga.Visibility -eq 'Visible')
    $ui.Carga.Visibility = 'Visible'
    if ($conFade -and -not $yaVisible) {
        $a = [Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(220)))
        $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
    } else { $ui.Carga.Opacity = 1 }
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

function Desvanecer-Carga {
    $a = [Windows.Media.Animation.DoubleAnimation]::new(1.0, 0.0, [Windows.Duration]::new([TimeSpan]::FromMilliseconds(450)))
    $a.BeginTime = [TimeSpan]::FromMilliseconds(250)
    $ease = New-Object Windows.Media.Animation.QuadraticEase
    $ease.EasingMode = 'EaseOut'
    $a.EasingFunction = $ease
    $a.Add_Completed({
        $ui.Carga.Visibility = 'Collapsed'
        $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
        $ui.Carga.Opacity = 1
        $f = $script:Carga.AlCerrar
        $script:Carga.AlCerrar = $null
        if ($f) { & $f }
    })
    $ui.Carga.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
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
    $sync = [hashtable]::Synchronized(@{ Info = $null; Hecho = 0; Total = ($lista.Count + 4); Paso = ''; Listo = $false; Resultados = $null; Prio = @(); TareaAfi = $false; FuncCpu = $FuncCpu; Cpu = $null })
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
        $ui.Estado.Text = (Con-Enie $script:EstadoLeido)
        Actualizar-Bloqueos
        $f = $script:DespuesLectura
        $script:DespuesLectura = $null
        if ($f) { & $f }
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
    $script:NoDisp = Calcular-NoDisp $s.Info $s.Cpu
    $script:Estados = @{}
    $apl = 0; $tot = 0
    foreach ($k in @($script:Pills.Keys)) {
        $est = $null
        if ($res -and $res.ContainsKey($k)) { $est = $res[$k] }
        $script:Estados[$k] = $est
        if ($script:NoDisp.ContainsKey($k)) {
            $pb = $script:Pills[$k]
            $pb.Visibility = 'Visible'; $pb.Background = (Pincel '#2A2D33'); $pb.Child.Foreground = (Pincel '#9AA0A6'); $pb.Child.Text = (Con-Enie 'No compatible')
            continue
        }
        Poner-Pill $script:Pills[$k] $est
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
        if ($script:NoDisp.Count -gt 0) { $script:EstadoLeido += (' ' + $script:NoDisp.Count + ' no son compatibles con tu PC.') }
    }
    else { $script:EstadoLeido = 'No se pudo leer el estado de Windows. Proba con "Volver a leer los ajustes".' }
    $script:Leido = $true
}

# ------------------------------------------------------------
# Actualizaciones desde GitHub
# Al abrir, compara el version.txt de tu PC con el de GitHub. Si son distintos,
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
    $sync.Hay = [bool]($remota -and ($remota -ne $local))
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
        if ($txt.Length -lt 100) { if ($a.Opc) { $i++; continue }; throw ('lo que llego de GitHub para ' + $a.Nombre + ' no es el archivo esperado') }
        $tmp = $a.Local + '.nuevo'
        $dd = Split-Path -Parent $tmp
        if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
        [IO.File]::WriteAllText($tmp, ($txt -replace '\r?\n', "`r`n"), $latin)
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
    if ((-not $XucaRepo) -or ($XucaRepo -like 'TU_USUARIO*')) { Refrescar-Estado; return }
    Bloquear $true
    Mostrar-Carga 'Buscando actualizaciones' $false
    Upd-Iniciar $false
}

function Upd-MostrarCartel([bool]$si) {
    $vis = $(if ($si) { 'Collapsed' } else { 'Visible' })
    $ui.CargaZona.Visibility = $vis; $ui.CargaInfo.Visibility = $vis
    $ui.UpdCarga.Visibility = $(if ($si) { 'Visible' } else { 'Collapsed' })
}

function Fin-Busqueda($s) {
    $script:UpdHay = [bool]$s.Hay
    $script:UpdRemota = [string]$s.Remota
    if (-not $script:UpdHay) { Refrescar-Estado; return }
    Poner-Version $true
    $tuya = $(if ($s.Local) { [string]$s.Local } else { 'sin version' })
    $t = 'Hay una actualizacion disponible: tenes la ' + $tuya + ' y en GitHub esta la ' + $script:UpdRemota
    $ui.UpdTitulo.Text = (Con-Enie $t)
    $ui.UpdTexto.Text = (Con-Enie 'Toca este cartel para descargarla. Se cierra esta version y se abre la nueva sola.')
    $ui.UpdBarraTexto.Text = (Con-Enie ($t + '. Toca aca para actualizar.'))
    $animTimer.Stop()
    $ui.CargaTitulo.Text = (Con-Enie 'Hay una version nueva de Xuca OPtimizer')
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
            if ($script:Leido) { Bloquear $false } else { Refrescar-Estado }
        }
        return
    }
    # Todo bajado y reemplazado: se abre la app nueva y se cierra esta
    $ui.CargaTitulo.Text = (Con-Enie 'Actualizacion lista')
    Poner-Progreso 1 'Abriendo la version nueva...'
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $AppPath + '"')
    $script:CierreTimer = New-Object Windows.Threading.DispatcherTimer
    $script:CierreTimer.Interval = [TimeSpan]::FromMilliseconds(900)
    $script:CierreTimer.Add_Tick({ $script:CierreTimer.Stop(); $script:SalirYa = $true; $win.Close() })
    $script:CierreTimer.Start()
}

$updTimer.Add_Tick({
    $u = $script:UpdRun
    if (-not $u) { $updTimer.Stop(); return }
    $s = $u.Sync
    if ($u.Bajar) { Poner-Progreso (0.95 * $s.Prog) $(if ($s.Paso) { 'Descargando: ' + $s.Paso } else { '' }) }
    else { Poner-Progreso ((1 - [math]::Exp(-((Get-Date) - $u.Desde).TotalSeconds / 1.5)) * 0.9) 'Comparando tu version con la de GitHub' }
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
    Refrescar-Estado
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

function Limpiar-Variables {
    foreach ($v in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'XR_*' })) { Remove-Item -LiteralPath ('Env:' + $v.Name) -ErrorAction SilentlyContinue }
    foreach ($n in 'XUCA_AUTO', 'PRIOJ', 'PRIOSYNC', 'AFIAPP', 'AFIJ', 'AFIF', 'AFIJX', 'AFIFX', 'AFIJT', 'AFIFT', 'CLEAN_BIN', 'CLEAN_GPU', 'CLEAN_RP') { Remove-Item -LiteralPath ('Env:' + $n) -ErrorAction SilentlyContinue }
}

function Correr($tareas, [bool]$reinicio, [string]$tituloCarga) {
    $total = 0; foreach ($t in $tareas) { $total += [int]$t.Cambios }
    $script:Corrida = @{ Reinicio = $reinicio; PideReinicio = $false; Total = [math]::Max($total, 1); Hechos = 0; Fallos = 0; Liberado = ''; Tipo = $tareas[0].Tipo; Oculta = $false }
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
    $base = $C.Hechos + [math]::Max($n - 1, 0) + $(if ($n -gt 0) { Avance-Tiempo $t.UltCambio 6 } else { 0 })
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
            $m = 'La cache quedo limpia.'
            if ($C.Liberado) { $m = ('Liberaste ' + $C.Liberado + '.') }
            Avisar 'Limpieza terminada' $m
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
$ui.BtnRefrescar.Add_Click({ Refrescar-Estado })
$ui.BtnRedes.Add_Click({ Start-Process $Redes })

$ui.BtnLogs.Add_Click({
    $d = Join-Path $Scripts 'logs'
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $d + '"')
})

$ui.BtnTodo.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $true }; Actualizar-Contador })
$ui.BtnNada.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $false }; Actualizar-Contador })

# Botones de Herramientas: cada uno corre el debloat con una sola opcion respondida (con la ventana negra a la vista)
$accionHerr = {
    $par = ([string]$this.Tag) -split '='
    $nombres = @{ ver = 'Actualizar Windows 11'; ms_acc = 'Borrar una cuenta'; al = 'Entrar sin contrasena' }
    $txt = $nombres[$par[0]]
    if ($par[1] -eq 'R') { $txt = 'Volver a usar contrasena' }
    if (-not (Confirmar $txt 'Se abre la ventana negra del script y ahi te va pidiendo lo que necesita.' 'Seguir' '#3D6FD9' 'Cancelar')) { return }
    $v = @{}; $v['XR_' + $par[0]] = $par[1]
    Correr @([pscustomobject]@{ Nombre = $txt; Ruta = $Rutas.Debloat; Vars = $v; Cambios = 1; Visible = $true; Tipo = 'herramienta' }) $false ''
}
foreach ($b in @($script:BtnVer, $bAcc, $bSin, $bCon)) { $b.Add_Click($accionHerr) }

# Aplica lo marcado en Debloat y Gaming, en una sola pasada (lo usan Aplicar y los perfiles)
function Aplicar-Seleccion {
    $selD = Elegidas 'Debloat'
    $selG = Elegidas 'Gaming'
    if (($selD.Count + $selG.Count) -eq 0) { Avisar 'Aplicar' 'No marcaste ninguna opcion.'; return }

    $vG = @{}
    foreach ($id in $selG) { $vG['XR_' + $id] = 'S' }
    if (($selG -contains 'pri') -or ($selG -contains 'afi')) {
        # Prioridad alta y afinidad usan la misma lista de juegos guardada
        $L = Leer-Listas
        $jug = @(Procesos-De $AfiJuegosCat $L.juegos)
        if ($jug.Count -eq 0) {
            if (-not (Editar-Juegos $false)) { return }
            $L = Leer-Listas
            $jug = @(Procesos-De $AfiJuegosCat $L.juegos)
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
    if ($selD.Count -gt 0) { $tareas += [pscustomobject]@{ Nombre = 'Debloat y privacidad'; Ruta = $Rutas.Debloat; Vars = $vD; Cambios = $selD.Count; Visible = $false; Tipo = 'opciones' } }
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
        $caja.CornerRadius = 10; $caja.Background = (Pincel '#2A2130'); $caja.BorderBrush = (Pincel '#F9A8D4'); $caja.BorderThickness = 1
        $caja.Padding = '14,12'; $caja.Margin = '0,14,0,0'
        $sk = New-Object Windows.Controls.StackPanel
        $m = Nuevo-Texto 'Este proyecto es gratis y lo hago en mi tiempo libre. Si te sirvio y queres apoyarme, podes invitarme un Ko-fi:' 13 '#E8D5E0' $false
        $m.LineHeight = 20
        $sk.Children.Add($m) | Out-Null
        $link = Nuevo-Texto $KoFi 12.5 '#F9A8D4' $false
        $link.Margin = '0,4,0,0'
        $sk.Children.Add($link) | Out-Null
        $bK = Nuevo-Boton 'Apoyar en Ko-fi' '#FF5E5B'
        $bK.HorizontalAlignment = 'Left'
        $bK.Add_Click({ Start-Process $KoFi })
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

$win.Add_Closing({
    param($s, $e)
    # Al actualizar o cambiar de idioma la app se cierra sola para abrirse de nuevo: no se pregunta nada
    if ($script:SalirYa) { return }
    if ($script:Proc -and -not $script:Proc.HasExited) {
        $m = $(if ($script:Tarea -and -not $script:Tarea.Visible) { 'Todavia se estan aplicando cambios. Si cerras la app, el script sigue en segundo plano hasta terminar.' } else { 'Todavia se esta aplicando un script. Si cerras la app, el script sigue solo en su ventana.' })
        if (-not (Confirmar 'Cerrar la app' ($m + "`n`n" + 'Cerrar igual?') 'Cerrar' '#B3412F' 'Seguir en la app')) { $e.Cancel = $true }
        return
    }
    if (-not (Confirmar-Salida)) { $e.Cancel = $true }
})

# ------------------------------------------------------------
# Idioma: el boton de abajo a la izquierda cambia entre ingles y espanol, lo guarda y abre la app de nuevo
# ------------------------------------------------------------
$ui.IdiomaTxt.Text = $(if ($script:Idioma -eq 'es-mx') { 'English' } else { 'Espa' + $Enie + 'ol' })
$ui.BtnIdioma.ToolTip = (Con-Enie 'Cambiar idioma')
$ui.BtnIdioma.Add_Click({
    if (($script:Proc -and -not $script:Proc.HasExited) -or $script:UpdRun -or $script:Lectura) { Avisar 'Cambiar idioma' 'Espera a que termine lo que se esta aplicando para cambiar el idioma.'; return }
    $nuevo = $(if ($script:Idioma -eq 'es-mx') { 'en-en' } else { 'es-mx' })
    $f = Join-Path (Join-Path $LangDir $nuevo) 'textos.txt'
    if (($nuevo -ne 'es-mx') -and (-not (Test-Path -LiteralPath $f))) { Avisar 'Cambiar idioma' ((Con-Enie 'No se encontro el archivo de idioma:') + "`n" + $f); return }
    Guardar-Config 'idioma' $nuevo
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $AppPath + '"')
    $script:SalirYa = $true
    $win.Close()
})

$win.Add_ContentRendered({ Buscar-Actualizacion })

Ir-A 'Perfiles'
$ui.Estado.Text = ''
$win.ShowDialog() | Out-Null

} catch {
    Mostrar-Error ('La app tuvo un error y se cerro:' + "`n`n" + $_.Exception.Message + "`n`n" + 'Linea: ' + $_.InvocationInfo.ScriptLineNumber)
}
