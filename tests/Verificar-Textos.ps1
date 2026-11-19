# Busca textos en espanol que la app puede mostrar en ingles sin traducir. No toca la PC: solo lee Brio.ps1, scripts\ y lang\.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File tests\Verificar-Textos.ps1   (sale con 1 si encuentra alguno)
# Como decide la app (igual que Traducir en Brio.ps1): coincidencia exacta con un "es:" de lang\en-en\textos.txt, o por pedazos
# (las claves de 5 o mas letras se reemplazan dentro de un texto mas largo). Revisa:
#   - los perfiles ($Perfiles): nombre, Que hace, Ideal para, No toca, Ojo y Consumo estimado
#   - los textos de tablas de Brio.ps1 ($Advertencias, $AvisosXbox, $SinVuelta, $Textos, $TextosSubmenu, ...) y los de $Elegibles de Debloat.ps1
#   - las cadenas que se pasan a los controles (Nuevo-Texto, Nuevo-Boton, Avisar, Confirmar, Nota, ...) y las que parecen espanol
#   - que a lo ya traducido no le queden palabras sueltas en espanol
# Lo que sea nombre propio o a proposito igual en los dos idiomas va en tests\textos-ignorar.txt (una cadena por linea).
param([string]$Repo = (Split-Path -Parent $PSScriptRoot), [switch]$Todo)
$ErrorActionPreference = 'Stop'
$enc = New-Object Text.UTF8Encoding $false

# ---- diccionario de ingles, como Cargar-Idioma ----
$d = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::Ordinal); $es = $null   # distingue mayusculas, como la app
foreach ($l in [IO.File]::ReadAllLines((Join-Path $Repo 'lang\en-en\textos.txt'), $enc)) {
    $l = $l.TrimStart([char]0xFEFF)
    if ((-not $l) -or $l.StartsWith('#')) { continue }
    if ($l -match '^(es|en):\s?(.*)$') {
        $v = $Matches[2].TrimEnd()
        if (($v.Length -ge 2) -and $v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
        if ($Matches[1] -eq 'es') { $es = $v } elseif ($es) { $d[$es] = $v; $es = $null }
    }
}
$pats = foreach ($k in @($d.Keys | Where-Object { $_.Length -ge 5 } | Sort-Object Length -Descending)) {
    $p = [regex]::Escape($k)
    if ($k -match '^\w') { $p = '(?<!\w)' + $p }
    if ($k -match '\w$') { $p = $p + '(?!\w)' }
    $p
}
$rx = New-Object Text.RegularExpressions.Regex (($pats -join '|'))
function Trad([string]$t) {
    if ($d.ContainsKey($t)) { return $d[$t] }
    $t0 = $t
    return $rx.Replace($t, [Text.RegularExpressions.MatchEvaluator] { param($m) $d[$m.Value] })
}
# Opciones: Titulo/Hace/Favor/Contra de opciones.txt tambien traducen por texto exacto (se compara con los de los scripts)
$ign = @{}
$fi = Join-Path $PSScriptRoot 'textos-ignorar.txt'
if (Test-Path $fi) { foreach ($l in [IO.File]::ReadAllLines($fi, $enc)) { if ($l.Trim() -and (-not $l.StartsWith('#'))) { $ign[$l.Trim()] = 1 } } }

# ---- espanol? ----
# solo palabras que no existen en ingles (no, en, es, a, lo... se leen igual)
$vacias = 'de la el los las que para con sin tu tus una por mas solo ya esta estas este como cuando hay queda tenes podes usa abri elegi sus pero tambien cuenta sobre'.Split(' ')
function Pinta-Espanol([string]$t) {
    $w = @([regex]::Matches($t.ToLowerInvariant(), "[a-záéíóúñ]+") | ForEach-Object { $_.Value })
    $n = @($w | Where-Object { $vacias -contains $_ } | Select-Object -Unique).Count
    return (($n -ge 2) -or (($n -ge 1) -and ($t.Length -ge 10)))
}
$bad = New-Object 'System.Collections.Generic.Dictionary[string,string]'
function Revisar([string]$origen, [string]$t, [bool]$seguroUI) {
    if ((-not $t) -or ($t.Length -lt 3) -or ($t -notmatch '[A-Za-z]')) { return }
    if ($t -match '^(#[0-9A-Fa-f]{6,8}|White|Black)$') { return }
    # los textos se buscan tal cual (los pedazos pueden llevar un espacio al final o al principio); la lista de ignorados va sin espacios
    if ($ign.ContainsKey($t.Trim()) -or $bad.ContainsKey($t)) { return }
    $r = Trad $t
    # frases que la app escribe con la primera letra en mayuscula (Apps recomendadas)
    if (($t -cmatch '^[a-z]') -and $d.ContainsKey($t.Substring(0, 1).ToUpperInvariant() + $t.Substring(1))) { return }
    if (($r -eq $t) -and ($t -ne $t.Trim())) { $r = Trad $t.Trim(); if ($r -ne $t.Trim()) { $t = $t.Trim() } }
    if ($r -eq $t) {
        if ($seguroUI -or (Pinta-Espanol $t)) { $bad[$t] = $origen }
    } elseif ((Pinta-Espanol $r) -and (-not $ign.ContainsKey($r))) {
        $bad[$t] = $origen + ' (queda en espanol: ' + $(if ($r.Length -gt 70) { $r.Substring(0, 70) + '...' } else { $r }) + ')'
    }
}

# ---- Brio.ps1 ----
$src = [IO.File]::ReadAllText((Join-Path $Repo 'Brio.ps1'))
$ast = [Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
function Tomar([string]$var) {
    $a = $ast.FindAll({ param($n) ($n -is [Management.Automation.Language.AssignmentStatementAst]) -and ($n.Operator -eq 'Equals') -and ($n.Left.Extent.Text -eq ('$' + $var)) }, $true) | Select-Object -First 1
    if (-not $a) { return $null }
    return (& ([scriptblock]::Create($a.Extent.Text + "`n" + '$' + $var)))
}
function Planos($o) {
    if ($null -eq $o) { return }
    if ($o -is [string]) { $o; return }
    if ($o -is [System.Collections.IDictionary]) { foreach ($k in $o.Keys) { Planos $o[$k] }; return }
    if ($o -is [System.Collections.IEnumerable]) { foreach ($x in $o) { Planos $x }; return }
}
# Perfiles
foreach ($pf in @(Tomar 'Perfiles')) {
    foreach ($c in 'Nombre', 'Hace', 'Ideal', 'NoToca', 'Adv', 'Estima') { if ($pf.$c) { Revisar ('perfil ' + $pf.Id + ' ' + $c) ([string]$pf.$c) $true } }
}
foreach ($v in 'Advertencias', 'AvisosXbox', 'SinVuelta', 'Textos', 'TextosSubmenu', 'NombresApp', 'AppsRec', 'GruposPerf') {
    $o = Tomar $v
    foreach ($s in @(Planos $o)) { Revisar ('$' + $v) ([string]$s) $false }
}
foreach ($g in @((Tomar 'OrdenSec'))) { foreach ($k in 'Debloat', 'Gaming') { foreach ($x in @($g[$k])) { Revisar '$OrdenSec' ([string]$x[0]) $true } } }
# Elegibles de Debloat.ps1 (nombres y descripciones de los submenus)
try {
    $dt = [IO.File]::ReadAllText((Join-Path $Repo 'scripts\Debloat.ps1'))
    $eleg = & { . ([scriptblock]::Create($args[0])); $Elegibles } $dt
    foreach ($k in $eleg.Keys) { foreach ($e in @($eleg[$k])) { Revisar ('Elegibles ' + $k) ([string]$e.Nombre) $true; Revisar ('Elegibles ' + $k) ([string]$e.Desc) $true } }
} catch { }

# Cadenas que se pasan a los controles
$ui = 'Nuevo-Texto', 'Nuevo-Boton', 'Nota', 'Avisar', 'Confirmar', 'Agregar-Linea', 'Nueva-Herramienta', 'Con-Enie', 'Traducir', 'Inicio-Fila', 'Nueva-Seccion', 'Elegir-Lista', 'Nuevo-Marco', 'Item', 'Elegir3', 'Pedir-Texto', 'Nueva-AppRec', 'Inicio-Caja', 'Cfg-Mensaje', 'Nueva-Config', 'Caja-Gpu', 'Nueva-SeccionPlegable', 'Lista-Agregar', 'Poner-Progreso', 'Mostrar-Carga'
$cmds = $ast.FindAll({ param($n) $n -is [Management.Automation.Language.CommandAst] }, $true)
function Hojas($a) {
    if ($a -is [Management.Automation.Language.StringConstantExpressionAst]) { [string]$a.Value; return }
    foreach ($h in $a.FindAll({ param($n) $n -is [Management.Automation.Language.StringConstantExpressionAst] }, $true)) { [string]$h.Value }
}
foreach ($c in $cmds) {
    $nom = [string]$c.GetCommandName()
    if ($ui -notcontains $nom) { continue }
    foreach ($e in @($c.CommandElements | Select-Object -Skip 1)) {
        if ($e -is [Management.Automation.Language.CommandParameterAst]) { continue }
        # concatenacion de constantes: el texto entero; con variables: cada pedazo
        $full = $null
        try { $full = $e.SafeGetValue() } catch { }
        if ($full -is [string]) { Revisar ($nom + ' linea ' + $e.Extent.StartLineNumber) $full $true }
        else { foreach ($h in @(Hojas $e)) { if (($h.Length -ge 5) -and ($h -match '[a-záéíóúñ]{3}') -and ($h -notmatch '^[#$\\/<{\[]|\.exe|HK|::')) { Revisar ($nom + ' linea ' + $e.Extent.StartLineNumber + ' (pedazo)') $h $false } } }
    }
}
# Cualquier otra cadena que parezca espanol (por ejemplo los pedazos de "N por aplicar" que se arman con +)
if ($Todo -or $true) {
    foreach ($n in $ast.FindAll({ param($x) $x -is [Management.Automation.Language.StringConstantExpressionAst] }, $true)) {
        $v = [string]$n.Value
        if (($v.Length -lt 6) -or ($v.Length -gt 700) -or ($v -match '\$|\x5C|::|HK[LC]|\.exe|\.ps1|\(\?|[\r\n]|using System|<Window|<Border|^http|^[-/^#<{\[(]')) { continue }
        if ($n.Parent -is [Management.Automation.Language.CommandAst] -and ($n.Parent.GetCommandName() -in 'Log', 'Say', 'Write-Host', 'Add-Type')) { continue }
        # $TitulosCortos y $Limp se traducen por Id con lang\en-en\opciones.txt (lo revisa Verificar-Opciones.ps1)
        $pa = $n.Parent; $porId = $false
        while ($pa) { if (($pa -is [Management.Automation.Language.AssignmentStatementAst]) -and ($pa.Left.Extent.Text -in '$TitulosCortos', '$Limp')) { $porId = $true; break }; $pa = $pa.Parent }
        if ($porId) { continue }
        Revisar ('texto linea ' + $n.Extent.StartLineNumber) $v $false
    }
}
# Texto fijo de la ventana (XAML)
foreach ($m in [regex]::Matches($src, '(?<=\s)(Text|Content|ToolTip|Header)="([^"{<>&]{3,})"')) { Revisar ('XAML ' + $m.Groups[1].Value) $m.Groups[2].Value $true }

$res = @($bad.GetEnumerator() | Sort-Object Value, Key)
foreach ($r in $res) { if ($Todo) { '[' + $r.Value + ']' + "`n" + $r.Key + "`n" } else { '{0}  --> {1}' -f $r.Value, ($(if ($r.Key.Length -gt 110) { $r.Key.Substring(0, 110) + '...' } else { $r.Key })) } }
''
'Cadenas en espanol sin traducir: ' + $res.Count
if ($res.Count -gt 0) { exit 1 }
'RESULTADO: OK'
