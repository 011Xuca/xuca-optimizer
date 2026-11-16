# Verificacion automatica de las opciones de Debloat y Gaming. No toca la PC: solo lee Brio.ps1, los scripts y lang\.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File tests\Verificar-Opciones.ps1   (sale con 1 si algo falla)
# Revisa:
#   - que no haya ids repetidos (en la misma pagina o entre Debloat y Gaming: la app los pasa como variables XR_<id>)
#   - que cada opcion que muestra la app tenga su traduccion en lang\en-en\opciones.txt (Titulo, Hace, Favor y Contra)
#   - que cada opcion tenga su chequeo de estado ($Chequeos) y su lugar en el orden por impacto ($OrdenOpc)
#   - que cada categoria este en $OrdenSec y tenga su traduccion en lang\en-en\textos.txt
#   - las opciones divididas ($Divididas): que existan, que esten en todos los perfiles que tienen la original, que esten en
#     algun perfil si la original lo estaba, y que conserven el aviso (y el aviso de Xbox o sin vuelta atras) de la original
#   - que los perfiles solo nombren opciones que existen
param([string]$Repo = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$fallas = New-Object System.Collections.Generic.List[string]
function Falla([string]$m) { $fallas.Add($m) }

$src = [IO.File]::ReadAllText((Join-Path $Repo 'Brio.ps1'))
$ast = [Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
# Toma una variable de Brio.ps1 (son datos: listas y tablas, definirlas no hace nada)
function Tomar([string]$var) {
    $a = $ast.FindAll({ param($n) ($n -is [Management.Automation.Language.AssignmentStatementAst]) -and ($n.Operator -eq 'Equals') -and ($n.Left.Extent.Text -eq ('$' + $var)) }, $true) | Select-Object -First 1
    if (-not $a) { throw "Brio.ps1 no tiene `$$var" }
    return (& ([scriptblock]::Create($a.Extent.Text + "`n" + '$' + $var)))
}
$SoloScript = @(Tomar 'SoloScript'); $Perfiles = @(Tomar 'Perfiles'); $Divididas = Tomar 'Divididas'
$OrdenSec = Tomar 'OrdenSec'; $OrdenOpc = Tomar 'OrdenOpc'; $Chequeos = Tomar 'Chequeos'
$Advertencias = Tomar 'Advertencias'; $AvisosXbox = Tomar 'AvisosXbox'; $SinVuelta = Tomar 'SinVuelta'

# Opciones de los scripts
$ops = @{}
foreach ($p in 'Debloat', 'Gaming') {
    $txt = [IO.File]::ReadAllText((Join-Path $Repo "scripts\$p.ps1"))
    $lista = & { . ([scriptblock]::Create($args[0])); $ListaOpciones } $txt
    $ops[$p] = @($lista | Where-Object { $_ })
    # 'ver' esta dos veces a proposito (una por version de Windows; cada una se saltea en la otra) y la app no la muestra
    foreach ($g in @($ops[$p] | Group-Object { ([string]$_.Id).ToLower() } | Where-Object { ($_.Count -gt 1) -and ($_.Name -ne 'ver') })) { Falla "$p : id repetido '$($g.Name)'" }
}
$entre = @($ops.Debloat | ForEach-Object { ([string]$_.Id).ToLower() } | Where-Object { @($ops.Gaming | ForEach-Object { ([string]$_.Id).ToLower() }) -contains $_ })
foreach ($i in $entre) { Falla "id '$i' esta en Debloat y en Gaming" }

# Traducciones
$enc = New-Object Text.UTF8Encoding $false
$bl = @{}; $cur = $null
foreach ($l in [IO.File]::ReadAllLines((Join-Path $Repo 'lang\en-en\opciones.txt'), $enc)) {
    if ($l -match '^\[(\w+)\s+(\w+)\]\s*$') { $cur = @{}; $bl[$Matches[1] + '|' + $Matches[2]] = $cur }
    elseif ($cur -and ($l -match '^(Titulo|Hace|Favor|Contra):\s*(.+?)\s*$')) { $cur[$Matches[1]] = $Matches[2] }
}
$textos = @{}
foreach ($l in [IO.File]::ReadAllLines((Join-Path $Repo 'lang\en-en\textos.txt'), $enc)) { if ($l -match '^es:\s?(.*?)\s*$') { $textos[$Matches[1].Trim('"')] = 1 } }

foreach ($p in 'Debloat', 'Gaming') {
    $vis = @($ops[$p] | Where-Object { $SoloScript -notcontains $_.Id })
    $prio = @($OrdenOpc[$p])
    foreach ($o in $vis) {
        $k = $p + '|' + $o.Id
        if (-not $bl.ContainsKey($k)) { Falla "$k sin traduccion en lang\en-en\opciones.txt" }
        else { foreach ($c in 'Titulo', 'Hace', 'Favor', 'Contra') { if (-not $bl[$k][$c]) { Falla "$k sin '$c' en lang\en-en\opciones.txt" } } }
        if (-not $Chequeos.ContainsKey($k)) { Falla "$k sin chequeo de estado en `$Chequeos" }
        $n = @($prio | Where-Object { $_ -eq $o.Id }).Count
        if ($n -ne 1) { Falla "$k esta $n veces en `$OrdenOpc (tiene que estar 1)" }
    }
    foreach ($i in $prio) { if (-not @($vis | Where-Object { $_.Id -eq $i })) { Falla "$p|$i esta en `$OrdenOpc pero no hay opcion visible con ese id" } }
    foreach ($s in @($vis | ForEach-Object { $_.Seccion } | Select-Object -Unique)) {
        if (-not @($OrdenSec[$p] | Where-Object { $_[0] -eq $s })) { Falla "$p : la categoria '$s' no esta en `$OrdenSec" }
        if (-not $textos.ContainsKey($s)) { Falla "$p : la categoria '$s' no tiene traduccion en lang\en-en\textos.txt" }
    }
}

# Perfiles: ids que existen
$letra = @{ D = 'Debloat'; G = 'Gaming' }
foreach ($pf in $Perfiles) {
    foreach ($l in 'D', 'G') { foreach ($i in @($pf.$l)) { if (-not @($ops[$letra[$l]] | Where-Object { $_.Id -eq $i })) { Falla "perfil $($pf.Id): '$i' no existe en $($letra[$l])" } } }
}
# Opciones divididas
foreach ($k in $Divididas.Keys) {
    $p, $orig = $k -split '\|'
    $l = $(if ($p -eq 'Debloat') { 'D' } else { 'G' })
    if (-not @($ops[$p] | Where-Object { $_.Id -eq $orig })) { Falla "$k (original) ya no existe" }
    $conOrig = @($Perfiles | Where-Object { @($_.$l) -contains $orig })
    foreach ($i in @($Divididas[$k])) {
        $kn = $p + '|' + $i
        if (-not @($ops[$p] | Where-Object { $_.Id -eq $i })) { Falla "$kn (salio de $k) no existe en el script" }
        foreach ($pf in $conOrig) { if (@($pf.$l) -notcontains $i) { Falla "perfil $($pf.Id) tiene $orig pero no $i (salio de $k)" } }
        if (($conOrig.Count -gt 0) -and (-not @($Perfiles | Where-Object { @($_.$l) -contains $i }))) { Falla "$kn no esta en ningun perfil y $k si" }
        foreach ($tabla in @(@('aviso', $Advertencias), @('aviso de Xbox', $AvisosXbox), @('aviso sin vuelta atras', $SinVuelta))) {
            if ($tabla[1].Contains($k) -and (-not $tabla[1].Contains($kn))) { Falla "$kn no tiene $($tabla[0]) y $k si (Marcar solo seguras la marcaria)" }
        }
    }
}

if ($fallas.Count -gt 0) { $fallas | ForEach-Object { 'FALLA: ' + $_ }; "RESULTADO: $($fallas.Count) problemas"; exit 1 }
'Opciones: Debloat ' + $ops.Debloat.Count + ', Gaming ' + $ops.Gaming.Count + '. Divididas: ' + $Divididas.Count + '. Perfiles: ' + $Perfiles.Count + '.'
'RESULTADO: OK'
exit 0
