# ============================================================
#  OPTIMIZACION PARA GAMING
#  Compatible con Windows 11 v. 25H2 (y Windows 10, salvo lo que avisa cada opcion).
#  La app XucaOP.ps1 lee de aca la lista de opciones ($ListaOpciones) y las corre en un hilo aparte,
#  junto con Comun.ps1: S = Si, R = Restaurar al valor por defecto de Windows (o al que tenias), N = no se toca.
#  Cada cambio se verifica y queda anotado en la carpeta "logs".
#  Este archivo solo define cosas: cargarlo no cambia nada en la PC.
# ============================================================

# Opciones que necesitan reiniciar para aplicarse. Solo se pide reiniciar si alguna de estas cambio algo de verdad.
$ReinGaming = @('tk', 'mm', 'notif', 'gf', 'mpo', 'msi', 'pca', 'tr', 'mi', 'vbs', 'md', 'v4', 'll', 'nag', 'nic', 'dup')
$GameBarProtocolos = @('ms-gamingoverlay', 'ms-gamebar', 'ms-gamebarservices')

$dnsCand = [ordered]@{
    'Cloudflare' = @('1.1.1.1', '1.0.0.1')
    'Google'     = @('8.8.8.8', '8.8.4.4')
    'Quad9'      = @('9.9.9.9', '149.112.112.112')
    'OpenDNS'    = @('208.67.222.222', '208.67.220.220')
}

# ---------- Afinidad de CPU (opcion afi) ----------
# Juegos: ya no hay lista fija. Se detectan los que tenes instalados (ver XUCA-JUEGOS) y se suman los que agregues vos.
$afiJuegosCat = ''
# Programas de fondo: catalogo predeterminado (proceso=Nombre; varios procesos del mismo programa van con |). La app tambien lo lee de aca.
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
        if (($n -notmatch '^[^\\/:*?"<>|=;,\[\]]{1,100}$') -or ($n -match '^[. ]+$')) { Log 'OMITIDO' ('nombre de proceso no valido: "' + $n + '"'); Say ('  "' + $n + '" no es un nombre de proceso valido, se salteo.') 'Yellow'; continue }
        if (Afi-Prohibido $n) { Log 'OMITIDO' ('"' + $n + '" no se toca para no romperlo'); Say ('  "' + $n + '" no se toca (sistema, OBS, editores, servidores Java o antitrampas), se salteo.') 'Yellow'; continue }
        $l.Add($n)
    }
    return @($l | Sort-Object -Unique)
}

# >>> XUCA-PROGRAMAS (la app XucaOP copia todo lo que esta entre estas dos marcas para saber si el programa instalado es el de esta version)
# Codigo de los programitas que se instalan en ProgramData\XucaScripts (temporizador, limpiador de RAM y afinidad).
# Al instalarlos se guarda al lado un .ver con la huella del codigo. Si una version nueva del script cambia el codigo,
# la huella no coincide: la app lo muestra como no aplicado y al aplicarlo se vuelve a instalar el nuevo.
$CodTimer = 'using System.Runtime.InteropServices; using System.Threading; public class P { [DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint d, bool s, out uint c); public static void Main() { uint c; NtSetTimerResolution(5000, true, out c); Thread.Sleep(Timeout.Infinite); } }'
$CodRam = 'using System; using System.Runtime.InteropServices; using System.Threading; public class P { [DllImport("ntdll.dll")] public static extern int NtSetSystemInformation(int i, ref int n, int l); [DllImport("advapi32.dll", SetLastError=true)] static extern bool OpenProcessToken(IntPtr p, uint d, out IntPtr t); [DllImport("advapi32.dll")] static extern bool LookupPrivilegeValue(string s, string n, out long l); [DllImport("advapi32.dll")] static extern bool AdjustTokenPrivileges(IntPtr t, bool d, ref TP n, uint b, IntPtr p, IntPtr r); [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess(); [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx(ref MS b); [StructLayout(LayoutKind.Sequential)] struct MS { public uint d; public uint l; public ulong tp; public ulong ap; public ulong tpf; public ulong apf; public ulong tv; public ulong av; public ulong aev; } [StructLayout(LayoutKind.Sequential, Pack=1)] struct TP { public uint c; public long l; public uint a; } public static void Main() { IntPtr t; if (OpenProcessToken(GetCurrentProcess(), 40, out t)) { TP tp = new TP(); tp.c = 1; tp.a = 2; LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out tp.l); AdjustTokenPrivileges(t, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero); } while(true) { MS m = new MS(); m.d = (uint)Marshal.SizeOf(typeof(MS)); if (GlobalMemoryStatusEx(ref m)) { if ((m.ap / 1048576) < 1024) { int c = 4; NtSetSystemInformation(80, ref c, 4); } } Thread.Sleep(10000); } } }'
$CodAfi = 'using System; using System.Collections.Generic; using System.Diagnostics; using System.IO; using System.Threading; public class P { static long juego, liviano, fondo, todo; static HashSet<string> juegos = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static HashSet<string> livianos = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static HashSet<string> apps = new HashSet<string>(StringComparer.OrdinalIgnoreCase); static void Lista(HashSet<string> h, string v) { foreach (string n in v.Split((char)44)) { string x = n.Trim(); if (x.Length > 0) h.Add(x); } } static void Leer(string ruta) { foreach (string l in File.ReadAllLines(ruta)) { int i = l.IndexOf((char)61); if (i < 1) continue; string k = l.Substring(0, i).Trim(); string v = l.Substring(i + 1).Trim(); if (k == "juego") juego = long.Parse(v); else if (k == "liviano") liviano = long.Parse(v); else if (k == "fondo") fondo = long.Parse(v); else if (k == "todo") todo = long.Parse(v); else if (k == "juegos") Lista(juegos, v); else if (k == "livianos") Lista(livianos, v); else if (k == "apps") Lista(apps, v); } } static bool Poner(Process p, long m) { try { if ((long)p.ProcessorAffinity != m) p.ProcessorAffinity = new IntPtr(m); p.Refresh(); return (long)p.ProcessorAffinity == m; } catch { return false; } } public static void Main() { string ruta = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "XucaScripts\\afinidad.txt"); try { Leer(ruta); } catch { return; } if (liviano == 0) liviano = juego; if (juego == 0 || todo == 0 || (juegos.Count + livianos.Count) == 0) return; try { Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.BelowNormal; } catch { } HashSet<int> rendidos = new HashSet<int>(); Dictionary<int, int> fallos = new Dictionary<int, int>(); HashSet<int> hechosF = new HashSet<int>(); while (true) { Process[] ps = Process.GetProcesses(); HashSet<int> vivos = new HashSet<int>(); bool hayJuego = false; foreach (Process p in ps) { string nom; try { nom = p.ProcessName; } catch { continue; } vivos.Add(p.Id); long m = 0; if (livianos.Contains(nom)) m = liviano; else if (juegos.Contains(nom)) m = juego; if (m == 0) continue; hayJuego = true; if (rendidos.Contains(p.Id)) continue; if (Poner(p, m)) fallos.Remove(p.Id); else { int c = 0; fallos.TryGetValue(p.Id, out c); c++; fallos[p.Id] = c; if (c >= 3) rendidos.Add(p.Id); } } if (hayJuego && fondo != 0) { foreach (Process p in ps) { string nom; try { nom = p.ProcessName; } catch { continue; } if (apps.Contains(nom) && Poner(p, fondo)) hechosF.Add(p.Id); } } else if (!hayJuego && hechosF.Count > 0) { foreach (Process p in ps) { if (hechosF.Contains(p.Id)) Poner(p, todo); } hechosF.Clear(); } rendidos.IntersectWith(vivos); hechosF.IntersectWith(vivos); List<int> viejos = new List<int>(); foreach (int k in fallos.Keys) if (!vivos.Contains(k)) viejos.Add(k); foreach (int k in viejos) fallos.Remove(k); foreach (Process p in ps) p.Dispose(); Thread.Sleep(2000); } } }'
function Ver-Codigo([string]$c) {
    $h = [Security.Cryptography.SHA256]::Create()
    try { return (-join @($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($c))[0..7] | ForEach-Object { $_.ToString('x2') })) } finally { $h.Dispose() }
}
function Ver-Igual([string]$exe, [string]$c) {
    $f = $exe + '.ver'
    if (-not (Test-Path -LiteralPath $f)) { return $false }
    return (([string](Get-Content -LiteralPath $f -TotalCount 1)).Trim() -eq (Ver-Codigo $c))
}
function Ver-Guardar([string]$exe, [string]$c) { try { Set-Content -LiteralPath ($exe + '.ver') -Value (Ver-Codigo $c) -Encoding ASCII } catch { } }
# <<< XUCA-PROGRAMAS

# >>> XUCA-CPU (la app XucaOP copia todo lo que esta entre estas dos marcas para leer el procesador)
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
    $r = [pscustomobject]@{ Ok = $false; Motivo = ''; Cpu = ''; Tipo = ''; Todo = [long]0; Juego = [long]0; Liviano = [long]0; Fondo = [long]0; Clase = ''; Nucleos = 0; Smt = $false; PCores = 0; NBloque = 0; Reserva = 0 }
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
    $r.Nucleos = $n; $r.Smt = ((Afi-Hilos $todo) -gt $n)
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
        $r.PCores = $pc.Count
        $r.Fondo = $todo -band (-bnot $pm)
        if ($pc.Count -ge 6) { $r.Clase = 'hib6'; $r.Juego = $pm; $r.Liviano = $pm; $r.Tipo = ('hibrido, ' + $pc.Count + ' P-cores y ' + ($n - $pc.Count) + ' E-cores: juegos en los P-cores') }
        elseif ($pc.Count -ge 4) { $r.Clase = 'hib4'; $r.Juego = $todo; $r.Liviano = $pm; $r.Tipo = ('hibrido, ' + $pc.Count + ' P-cores: los juegos pesados usan todo y los livianos solo los P-cores') }
        else { $r.Clase = 'hib2'; $r.Juego = $todo; $r.Liviano = $todo; $r.Tipo = ('hibrido, solo ' + $pc.Count + ' P-cores: los juegos usan todo y lo de fondo va a los E-cores') }
    } elseif ($l3.Count -gt 1) {
        # Varios bloques con su propia cache L3: el de mas cache (V-Cache en los X3D); si son iguales, el primero.
        $orden = @($l3 | Sort-Object @{ Expression = { $_.Cache }; Descending = $true }, @{ Expression = { Afi-BitBajo $_.Mascara }; Descending = $false })
        $bloque = $orden[0].Mascara -band $todo
        $nb = @($nucleos | Where-Object { ($_.Mascara -band $bloque) -ne 0 }).Count
        $vc = ($orden[0].Cache -gt $orden[1].Cache)
        if ($nb -ge 6) {
            $r.Juego = $bloque; $r.Liviano = $bloque; $r.Fondo = $todo -band (-bnot $bloque)
            $r.NBloque = $nb; $r.Clase = $(if ($vc) { 'x3d' } else { 'bloques' })
            if ($vc) { $r.Tipo = ($l3.Count.ToString() + ' bloques: juegos en el de V-Cache (' + [math]::Round($orden[0].Cache / 1MB) + ' MB de L3)') }
            else { $r.Tipo = ($l3.Count.ToString() + ' bloques de ' + $nb + ' nucleos: juegos en el primero') }
        } else {
            # Bloques chicos (Ryzen 1000, 2000 y 3000): pasar de un bloque a otro es lento.
            # Los juegos livianos van a un solo bloque; los pesados usan todos para no perder FPS.
            $primero = @($l3 | Sort-Object { Afi-BitBajo $_.Mascara })[0].Mascara -band $todo
            $r.Liviano = $primero; $r.Fondo = $ultimo; $r.Clase = 'ccx'
            if ($n -ge 8) { $r.Juego = $todo -band (-bnot $ultimo); $r.Reserva = $res } else { $r.Juego = $todo }
            if (($r.Liviano -band $r.Fondo) -ne 0) { $r.Liviano = $r.Juego }
            $r.Tipo = ($l3.Count.ToString() + ' bloques de ' + $nb + ' nucleos: livianos en el primer bloque, pesados en todos')
        }
    } else {
        $r.Fondo = $ultimo; $r.Liviano = $todo -band (-bnot $ultimo); $r.Clase = 'iguales'
        if ($n -ge 8) { $r.Juego = $todo -band (-bnot $ultimo); $r.Reserva = $res } else { $r.Juego = $todo }
        $r.Tipo = ($n.ToString() + ' nucleos iguales en un solo bloque')
    }
    if (($r.Juego -eq 0) -or ($r.Fondo -eq 0) -or ($r.Liviano -eq 0)) { $r.Motivo = 'no se pudo separar los nucleos del procesador'; return $r }
    $r.Ok = $true
    return $r
}
# Que tanto cambia la afinidad con TU procesador: cuanto se nota, que puede mejorar, que puede empeorar y que conviene.
function Afi-Consejo($pl) {
    $c = [pscustomobject]@{ Nivel = ''; Favor = ''; Contra = ''; Recom = '' }
    if (-not $pl.Ok) { $c.Nivel = 'NO SE PUEDE USAR'; $c.Recom = ('no se puede usar en esta PC: ' + $pl.Motivo + '.'); return $c }
    $n = $pl.Nucleos
    switch ($pl.Clase) {
        'x3d' {
            $c.Nivel = 'GRANDE'
            $c.Favor = ('el juego queda siempre en el bloque con V-Cache (' + $pl.NBloque + ' nucleos). Si cae en el otro bloque pierde muchos FPS, y eso pasa seguido si el driver de AMD o la Game Bar fallan.')
            $c.Contra = ('el juego usa solo ' + $pl.NBloque + ' de tus ' + $n + ' nucleos: los pocos juegos que aprovechan mas nucleos pueden rendir un poco menos.')
            $c.Recom = 'conviene activarla, junto con la Game Bar instalada y el Modo Juego: la Game Bar cubre los juegos que no estan en tu lista y los que tienen antitrampas (Valorant, Fortnite).'
        }
        'bloques' {
            $c.Nivel = 'MEDIANO'
            $c.Favor = 'el juego no salta de un bloque de nucleos al otro (eso suma demora): frametimes mas parejos y menos tirones.'
            $c.Contra = ('el juego usa solo ' + $pl.NBloque + ' de tus ' + $n + ' nucleos: en juegos que usan muchos hilos el FPS promedio puede bajar un poco.')
            $c.Recom = 'probala con y sin, y quedate con la que te de mejores 1% low.'
        }
        'ccx' {
            $c.Nivel = 'MEDIANO'
            $c.Favor = 'Minecraft, Valorant y otros juegos livianos quedan en un solo bloque de nucleos: menos tirones.'
            $c.Contra = $(if ($pl.Reserva -gt 0) { ('los juegos pesados pierden ' + $pl.Reserva + ' de tus ' + $n + ' nucleos y lo de fondo anda mas lento mientras jugas.') } else { 'lo de fondo anda mas lento mientras jugas.' })
            $c.Recom = 'conviene, sobre todo si jugas Minecraft.'
        }
        'hib6' {
            if ($pl.Smt) {
                $c.Nivel = 'MEDIANO'
                $c.Favor = 'el juego nunca cae en los E-cores (los lentos) y lo de fondo va ahi: menos tirones, sobre todo en juegos viejos.'
                $c.Contra = 'el juego no usa los E-cores: en juegos que usan muchos hilos (Cyberpunk, Battlefield) el FPS promedio puede bajar un poco.'
                $c.Recom = 'conviene probarla: en la mayoria de los juegos ayuda.'
            } else {
                $c.Nivel = 'CHICO'
                $c.Favor = 'lo de fondo va a los E-cores y el juego queda solo en los P-cores.'
                $c.Contra = 'en estos procesadores los E-cores ya son rapidos y varios juegos rinden mejor usandolos: el FPS puede bajar.'
                $c.Recom = 'probala con y sin; si no notas mejora, dejala apagada.'
            }
        }
        'hib4' {
            $c.Nivel = 'MEDIANO'
            $c.Favor = 'los juegos livianos quedan en los P-cores y lo de fondo va a los E-cores: el juego tiene los P-cores libres.'
            $c.Contra = 'lo de fondo anda mas lento mientras jugas.'
            $c.Recom = 'conviene.'
        }
        'hib2' {
            $c.Nivel = 'CHICO'
            $c.Favor = 'lo de fondo va a los E-cores y deja libres los P-cores para el juego.'
            $c.Contra = 'casi ninguno: el juego sigue usando todos los nucleos.'
            $c.Recom = 'conviene: no pierde nada.'
        }
        default {
            $c.Nivel = 'CHICO'
            if ($pl.Reserva -gt 0) {
                $c.Favor = 'lo de fondo (Discord, navegador, stream) queda en un nucleo aparte: los 1% low pueden quedar un poco mas parejos si tenes muchas cosas abiertas mientras jugas.'
                $c.Contra = ('el juego pierde ' + $pl.Reserva + ' de tus ' + $n + ' nucleos: en juegos que usan muchos hilos (CS2, Battlefield, Cyberpunk) el FPS promedio puede bajar un poco.')
                $c.Recom = 'la diferencia es chica: probala con y sin y quedate con la que ande mejor. Si jugas sin nada abierto atras, no hace falta.'
            } else {
                $c.Favor = 'lo de fondo queda en el ultimo nucleo y el juego sigue usando todos.'
                $c.Contra = 'casi ninguno: lo de fondo anda un poco mas lento mientras jugas.'
                $c.Recom = 'conviene: no pierde nada.'
            }
        }
    }
    return $c
}
# La Game Bar con TU procesador. Necesaria = $true en los Ryzen X3D de dos bloques: el driver de AMD la usa para mandar el juego al bloque con V-Cache.
function Gb-Consejo($pl) {
    if ($pl.Ok -and ($pl.Clase -eq 'x3d')) {
        return [pscustomobject]@{ Necesaria = $true; Aviso = 'en tu procesador la Game Bar NO se borra: el driver de AMD la usa para saber cuando jugas y mandar el juego al bloque con V-Cache. Solo se apagan sus grabaciones y capturas, asi que queda casi sin uso para vos, pero sigue haciendo ese trabajo de fondo.'; Texto = 'lo mejor es usarla junto con la afinidad de CPU: la afinidad asegura los juegos de tu lista y mueve lo de fondo al otro bloque; la Game Bar cubre los juegos que no estan en la lista y los que tienen antitrampas (Valorant, Fortnite). Deja el Modo Juego activado y el driver de chipset de AMD instalado.' }
    }
    return [pscustomobject]@{ Necesaria = $false; Aviso = ''; Texto = 'con tu procesador la Game Bar no hace falta para el rendimiento: se puede borrar sin perder nada.' }
}
# <<< XUCA-CPU

# >>> XUCA-JUEGOS (la app XucaOP copia todo lo que esta entre estas dos marcas para detectar los juegos instalados)
# Detecta los juegos que tenes instalados, en TODOS los discos de la PC: Steam, Epic Games, EA app, Battle.net,
# Ubisoft Connect, Riot, Xbox / Microsoft Store, GOG, Rockstar y Minecraft Java. Si no esta instalado, no aparece.
# Para cada juego elige su .exe principal: es el proceso que se ve en el Administrador de tareas.

# Juegos conocidos (proceso = nombre). Sirven para dos cosas: si un juego trae varios .exe, se elige el conocido;
# y si agregas a mano uno de estos procesos, se muestra con su nombre.
$XucaJuegosConocidos = @{
    'marvel-win64-shipping' = 'Marvel Rivals';
    'fortniteclient-win64-shipping' = 'Fortnite';
    'cs2' = 'Counter-Strike 2';
    'valorant-win64-shipping' = 'Valorant';
    'cod' = 'Call of Duty (Warzone, BO6, BO7)';
    'modernwarfare' = 'CoD Modern Warfare (2019)';
    'blackopscoldwar' = 'CoD Black Ops Cold War';
    'blackops4' = 'CoD Black Ops 4';
    'blackops3' = 'CoD Black Ops III';
    't6mp' = 'CoD Black Ops II (multijugador)';
    't6zm' = 'CoD Black Ops II (zombies)';
    't6sp' = 'CoD Black Ops II (historia)';
    'blackops' = 'CoD Black Ops (historia y zombies)';
    'blackopsmp' = 'CoD Black Ops (multijugador)';
    'codwaw' = 'CoD World at War (historia y zombies)';
    'codwawmp' = 'CoD World at War (multijugador)';
    's2_mp64_ship' = 'CoD WWII (multijugador)';
    'r5apex' = 'Apex Legends';
    'r5apex_dx12' = 'Apex Legends (DX12)';
    'overwatch' = 'Overwatch 2';
    'rainbowsix' = 'Rainbow Six Siege';
    'tslgame' = 'PUBG: Battlegrounds';
    'league of legends' = 'League of Legends';
    'dota2' = 'Dota 2';
    'deadlock' = 'Deadlock';
    'rocketleague' = 'Rocket League';
    'bf6' = 'Battlefield 6';
    'warframe.x64' = 'Warframe';
    'hytaleclient' = 'Hytale';
    'javaw' = 'Minecraft Java';
    'minecraft.windows' = 'Minecraft Bedrock';
    'robloxplayerbeta' = 'Roblox';
    'sparkingzero-win64-shipping' = 'Dragon Ball: Sparking! Zero';
    'streetfighter6' = 'Street Fighter 6';
    'devilmaycry5' = 'Devil May Cry 5';
    're2' = 'Resident Evil 2';
    're3' = 'Resident Evil 3';
    're4' = 'Resident Evil 4';
    're7' = 'Resident Evil 7';
    're8' = 'Resident Evil Village';
    'arkascended' = 'ARK: Survival Ascended';
    'shootergame' = 'ARK: Survival Evolved';
    'rustclient' = 'Rust';
    'escapefromtarkov' = 'Escape from Tarkov';
    'helldivers2' = 'Helldivers 2';
    'monsterhunterwilds' = 'Monster Hunter Wilds';
    'eldenring' = 'Elden Ring';
    'b1-win64-shipping' = 'Black Myth: Wukong';
    'genshinimpact' = 'Genshin Impact';
    'starrail' = 'Honkai: Star Rail';
    'zenlesszonezero' = 'Zenless Zone Zero';
    'spider-man' = 'Spider-Man Remastered';
    'milesmorales' = 'Spider-Man: Miles Morales';
    'spider-man2' = 'Spider-Man 2';
    'gta5' = 'GTA V (Legacy)';
    'gta5_enhanced' = 'GTA V (Enhanced)';
    'cyberpunk2077' = 'Cyberpunk 2077';
    'rdr2' = 'Red Dead Redemption 2'
}
$XucaExesConocidos = @($XucaJuegosConocidos.Keys)

# Nombre de un proceso que agregaste a mano: el de la lista de conocidos, el que se guardo antes,
# o el que dice el propio .exe si el juego esta abierto (se guarda para la proxima vez). $null si no se sabe.
function Juego-Nombre([string]$proc) {
    $proc = ([string]$proc).Trim().ToLower()
    if (-not $proc) { return $null }
    if ($XucaJuegosConocidos.ContainsKey($proc)) { return $XucaJuegosConocidos[$proc] }
    $fn = Join-Path (Join-Path $env:ProgramData 'XucaScripts') 'nombres_juegos.txt'
    try {
        if ([IO.File]::Exists($fn)) {
            foreach ($l in [IO.File]::ReadAllLines($fn, [Text.Encoding]::UTF8)) { $c = $l -split "`t"; if (($c.Count -eq 2) -and ($c[0] -eq $proc)) { return $c[1] } }
        }
    } catch { }
    $n = $null
    try {
        foreach ($p in @(Get-Process -Name $proc -ErrorAction SilentlyContinue)) {
            try {
                $vi = $p.MainModule.FileVersionInfo
                foreach ($t in @([string]$vi.ProductName, [string]$vi.FileDescription)) {
                    $t = (($t -replace '[;=|,\t]', ' ') -replace '[\u2122\u00AE\u00A9]', '').Trim()
                    if ($t -and ($t -notmatch '(?i)^(java|microsoft|windows|unreal|unity|bootstrap|launcher)')) { $n = $t; break }
                }
            } catch { }
            if ($n) { break }
        }
    } catch { }
    if ($n) {
        try {
            $d = Split-Path -Parent $fn
            if (-not [IO.Directory]::Exists($d)) { [void][IO.Directory]::CreateDirectory($d) }
            [IO.File]::AppendAllText($fn, ($proc + "`t" + $n + "`r`n"), (New-Object Text.UTF8Encoding($false)))
        } catch { }
    }
    return $n
}

# La raiz de cada disco de la PC (internos y externos). Se mira una vez por busqueda (con discos HDD, IsReady puede tardar).
function Juegos-Discos {
    if ($null -ne $global:XJDiscos) { return $global:XJDiscos }
    $l = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($dv in [IO.DriveInfo]::GetDrives()) {
            try { if ($dv.IsReady -and (([string]$dv.DriveType -eq 'Fixed') -or ([string]$dv.DriveType -eq 'Removable'))) { $l.Add($dv.RootDirectory.FullName) } } catch { }
        }
    } catch { }
    $global:XJDiscos = $l.ToArray()
    return $global:XJDiscos
}

# Las subclaves de una clave del registro, cada una con sus valores y PSChildName (su nombre).
# Lee el registro directo: Get-ChildItem + Get-ItemProperty tardaban mucho con cientos de programas instalados.
function Juegos-RegSub([string]$ruta) {
    $hive = $(if ($ruta -like 'HKCU:*') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine })
    $k = $null
    try { $k = $hive.OpenSubKey(($ruta -replace '^HK(LM|CU):\\', '')) } catch { }
    if (-not $k) { return }
    try {
        foreach ($n in $k.GetSubKeyNames()) {
            $sk = $null
            try { $sk = $k.OpenSubKey($n) } catch { }
            if (-not $sk) { continue }
            try {
                $v = @{ PSChildName = $n }
                foreach ($vn in $sk.GetValueNames()) { if ($vn -and ($vn -ne 'PSChildName')) { $v[$vn] = $sk.GetValue($vn) } }
                [pscustomobject]$v
            } catch { } finally { $sk.Close() }
        }
    } finally { $k.Close() }
}

# Las subcarpetas de unas rutas fijas, probadas en cada disco (por ejemplo "EA Games" -> D:\EA Games\<juego>)
function Juegos-Carpetas([string[]]$rutas) {
    foreach ($d in @(Juegos-Discos)) {
        foreach ($r in $rutas) {
            try {
                $p = [IO.Path]::Combine($d, $r)
                if ([IO.Directory]::Exists($p)) { [IO.Directory]::GetDirectories($p) }
            } catch { }
        }
    }
}

# Bibliotecas de Steam: las que tiene anotadas Steam (libraryfolders.vdf) y las carpetas tipicas de cada disco
function Steam-Bibliotecas {
    $raices = New-Object System.Collections.Generic.List[string]
    foreach ($k in @(@('HKCU:\Software\Valve\Steam', 'SteamPath'), @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath'), @('HKLM:\SOFTWARE\Valve\Steam', 'InstallPath'))) {
        try { $v = [string](Get-ItemProperty -LiteralPath $k[0] -ErrorAction Stop).($k[1]); if ($v) { $raices.Add(($v -replace '/', '\')) } } catch { }
    }
    $tipicas = 'Program Files (x86)\Steam', 'Program Files\Steam', 'Steam', 'SteamLibrary', 'Steam Library', 'Games', 'Games\Steam', 'Games\SteamLibrary', 'Juegos', 'Juegos\Steam', 'Juegos\SteamLibrary'
    foreach ($d in @(Juegos-Discos)) { foreach ($t in $tipicas) { $raices.Add([IO.Path]::Combine($d, $t)) } }
    foreach ($r in @($raices)) {
        try {
            $vdf = [IO.Path]::Combine($r, 'steamapps\libraryfolders.vdf')
            if ([IO.File]::Exists($vdf)) {
                foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) { $raices.Add(($m.Groups[1].Value -replace '\\\\', '\')) }
            }
        } catch { }
    }
    $vistas = @{}
    foreach ($r in $raices) {
        try {
            $sa = [IO.Path]::GetFullPath([IO.Path]::Combine($r, 'steamapps'))
            if (-not [IO.Directory]::Exists($sa)) { continue }
            $k = $sa.TrimEnd('\').ToLower()
            if ($vistas.ContainsKey($k)) { continue }
            $vistas[$k] = $true
            $sa
        } catch { }
    }
}

# El .exe principal de un juego: se descartan instaladores, crash reporters, antitrampas, launchers y herramientas.
# Gana el de la lista de conocidos o el que dice la plataforma, despues el de Unreal (-Win64-Shipping),
# despues el que se llama parecido al juego y despues el mas grande.
function Juego-Exe([string]$dir, $pistas, [string]$preferido) {
    $malo = 'unins|setup|install|redist|dxsetup|prereq|crash|report|anticheat|battleye|beservice|cefsharp|qtwebengine|webhelper|helper|updat|patch|config|benchmark|server|editor|sdk|python|ffmpeg|bugsplat|activation|touchup|cleanup|repair|launcher|vcredist|dotnet|directx|uploader|overlay|register|vanguard|riotclient|^7za?$'
    $carpMala = '\\(_?commonredist|redist|redistributables?|directx|dotnet|prereqs?|support|_?installers?|easyanticheat|battleye|thirdparty|extras|tools)\\'
    $ps = @(@($pistas) | ForEach-Object { ([string]$_).ToLower() -replace '[^a-z0-9]', '' } | Where-Object { $_.Length -ge 2 })
    $preferido = ([string]$preferido).ToLower()
    $mejor = $null; $pm = -99999
    $exes = @()
    try { $exes = @(Get-ChildItem -LiteralPath $dir -Filter '*.exe' -File -Recurse -Depth 5 -Force -ErrorAction SilentlyContinue) } catch { }
    foreach ($f in $exes) {
        $rel = $f.FullName.Substring($dir.Length)
        if ($rel -match $carpMala) { continue }
        $b = [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()
        if ($b -match $malo) { continue }
        $s = 0
        if ($XucaExesConocidos -contains $b) { $s += 2000 }
        if ($preferido -and ($b -eq $preferido)) { $s += 800 }
        if ($b -match '-win(64|gdk)-shipping$') { $s += 1000 }
        $a = $b -replace '[^a-z0-9]', ''
        if ($a.Length -ge 2) { foreach ($p in $ps) { if ($p.Contains($a) -or $a.Contains($p)) { $s += 300; break } } }
        $s += [math]::Min(200, [int]($f.Length / 1MB))
        $s -= 15 * ($rel.Split('\').Count - 2)
        if ($s -gt $pm) { $pm = $s; $mejor = $b }
    }
    return $mejor
}

# Programas instalados (lo que sale en "Agregar o quitar programas"), para EA, Battle.net, Ubisoft, Riot y Rockstar
function Juegos-Desinstalar {
    foreach ($b in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall') {
        foreach ($p in @(Juegos-RegSub $b)) {
            try { [pscustomobject]@{ Id = [string]$p.PSChildName; Nombre = [string]$p.DisplayName; Editor = [string]$p.Publisher; Dir = ([string]$p.InstallLocation).Trim().Trim('"') } } catch { }
        }
    }
}

# Devuelve los juegos instalados: Proc (proceso sin .exe), Nombre y Plat (plataforma).
# El .exe elegido se guarda en ProgramData\XucaScripts\juegos_detectados.txt y solo se vuelve a buscar si la carpeta cambio.
function Juegos-Detectados {
    # Lo que no es un juego (launchers, herramientas, redistribuibles...)
    $noJuego = '(?i)soundtrack|redistributable|dedicated server|\bsdk\b|steamworks|proton|steam linux runtime|steamvr|wallpaper engine|lossless scaling|blender|aseprite|krita|soundpad|\bobs\b|vtube studio|voicemod|rpg maker|gamemaker|3dmark|benchmark|launcher|battle\.net|^ea app|^ea$|^origin$|ea desktop|ea core|ubisoft connect|^uplay|riot client|vanguard|social club|anti-?cheat|unreal engine|epic online services|directx|visual c\+\+|\.net |microsoft edge|webview|gog galaxy|^xbox$|gaming services|game bar'
    $procNo = '^(blender|resolve|obs(32|64)?|code|devenv|java|godot.*|unrealeditor.*|losslessscaling|aseprite|krita|soundpad|wallpaper(32|64)|steam.*|vtube studio|voicemod|explorer|cmd|powershell|epicgameslauncher|eadesktop|ealauncher|origin|battle\.net|agent|upc|ubisoftconnect|uplay|riotclient.*|rockstarservice|playgtav|socialclub.*|galaxyclient|gamebar|xboxpcapp)$'
    $fuera = @('228980', '1070560', '1391110', '1628350', '1493710', '250820', '431960', '1007', '2180100')
    $global:XJDiscos = $null
    $dirC = Join-Path $env:ProgramData 'XucaScripts'
    $fc = Join-Path $dirC 'juegos_detectados.txt'
    $cache = @{}
    try { if ([IO.File]::Exists($fc)) { foreach ($l in [IO.File]::ReadAllLines($fc, [Text.Encoding]::UTF8)) { $c = $l -split "`t"; if ($c.Count -eq 3) { $cache[$c[0]] = $c } } } } catch { }
    $nuevaC = New-Object System.Collections.Generic.List[string]
    $res = New-Object System.Collections.Generic.List[object]
    $ya = @{}; $dirs = @{}

    # Suma un juego. Con $exeFijo se usa ese .exe; si no, se busca el principal dentro de $dir.
    function Agregar([string]$plat, [string]$id, [string]$nombre, [string]$dir, $pistas, [string]$preferido, [string]$exeFijo, [string]$extra) {
        try {
            $nombre = (($nombre -replace '[;=|,]', ' ') -replace '[\u2122\u00AE\u00A9]', '').Trim()
            if ((-not $nombre) -or ($nombre -match $noJuego)) { return }
            $proc = ''
            if ($exeFijo) {
                $proc = ([IO.Path]::GetFileNameWithoutExtension(($exeFijo -replace '/', '\'))).ToLower()
            } else {
                if ((-not $dir) -or (-not [IO.Directory]::Exists($dir))) { return }
                $dir = [IO.Path]::GetFullPath($dir).TrimEnd('\')
                # La raiz de un disco o carpetas de sistema no son la carpeta de un juego
                if (($dir.Length -le 3) -or ($dir -match '(?i)\\(windows|program files( \(x86\))?|users|programdata)$')) { return }
                if ($dirs.ContainsKey($dir.ToLower())) { return }
                $dirs[$dir.ToLower()] = $true
                $k = $plat + ':' + $id
                $marca = [string]([IO.Directory]::GetLastWriteTimeUtc($dir).Ticks) + '|' + $extra + '|' + $dir
                if ($cache.ContainsKey($k) -and ($cache[$k][1] -eq $marca)) { $proc = [string]$cache[$k][2] }
                else { $proc = [string](Juego-Exe $dir (@($pistas) + @($nombre)) $preferido) }
                $nuevaC.Add((@($k, $marca, $proc) -join "`t"))
            }
            if ((-not $proc) -or ($proc -notmatch '^[^\\/:*?"<>|=;,]+$') -or ($proc -match $procNo) -or $ya.ContainsKey($proc)) { return }
            $ya[$proc] = $true
            $res.Add([pscustomobject]@{ Proc = $proc; Nombre = $nombre; Plat = $plat })
        } catch { }
    }

    # Steam: los appmanifest de cada biblioteca
    foreach ($sa in @(Steam-Bibliotecas)) {
        $mans = @()
        try { $mans = @([IO.Directory]::GetFiles($sa, 'appmanifest_*.acf')) } catch { }
        foreach ($mf in $mans) {
            try {
                $txt = [IO.File]::ReadAllText($mf, [Text.Encoding]::UTF8)
                $id = [regex]::Match($txt, '"appid"\s+"(\d+)"').Groups[1].Value
                $nom = [regex]::Match($txt, '"name"\s+"([^"]*)"').Groups[1].Value
                $inst = [regex]::Match($txt, '"installdir"\s+"([^"]*)"').Groups[1].Value
                if ((-not $id) -or (-not $inst) -or ($fuera -contains $id)) { continue }
                Agregar 'Steam' $id $nom ([IO.Path]::Combine([IO.Path]::Combine($sa, 'common'), $inst)) @($inst) '' '' ([string]([IO.File]::GetLastWriteTimeUtc($mf).Ticks))
            } catch { }
        }
    }

    # Epic Games: los manifiestos del launcher (sin DLC ni instalaciones a medias)
    $me = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
    if ([IO.Directory]::Exists($me)) {
        foreach ($f in @([IO.Directory]::GetFiles($me, '*.item'))) {
            try {
                $j = [IO.File]::ReadAllText($f) | ConvertFrom-Json
                if ($j.bIsIncompleteInstall) { continue }
                if ($j.MainGameAppName -and ($j.MainGameAppName -ne $j.AppName)) { continue }
                if ($j.AppCategories -and (@($j.AppCategories) -notcontains 'games')) { continue }
                $pref = [IO.Path]::GetFileNameWithoutExtension(([string]$j.LaunchExecutable -replace '/', '\'))
                Agregar 'Epic' ([string]$j.AppName) ([string]$j.DisplayName) ([string]$j.InstallLocation) @($pref) $pref '' ''
            } catch { }
        }
    }

    # GOG: el registro dice el .exe de cada juego (sin DLC)
    foreach ($b in 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games', 'HKLM:\SOFTWARE\GOG.com\Games') {
        foreach ($p in @(Juegos-RegSub $b)) {
            try {
                if ([string]$p.dependsOn) { continue }
                Agregar 'GOG' ([string]$p.PSChildName) ([string]$p.gameName) '' @() '' ([string]$p.exe) ''
            } catch { }
        }
    }

    # Xbox / Microsoft Store: los juegos traen un MicrosoftGame.config que dice su .exe
    $configs = New-Object System.Collections.Generic.List[object]
    foreach ($g in @(Juegos-Carpetas @('XboxGames'))) {
        try { $cf = [IO.Path]::Combine($g, 'Content\MicrosoftGame.config'); if ([IO.File]::Exists($cf)) { $configs.Add(@($cf, [IO.Path]::GetFileName($g))) } } catch { }
    }
    # Las carpetas de las apps instaladas se leen del registro (Get-AppxPackage tarda en cargar); si no se puede, como antes
    $pkgs = @(Juegos-RegSub 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages' | Where-Object { [string]$_.PackageRootFolder })
    if ($pkgs.Count -gt 0) {
        foreach ($pk in $pkgs) {
            try { $cf = [IO.Path]::Combine([string]$pk.PackageRootFolder, 'MicrosoftGame.config'); if ([IO.File]::Exists($cf)) { $configs.Add(@($cf, ([string]$pk.PSChildName -split '_')[0])) } } catch { }
        }
    } else {
        try {
            foreach ($pk in @(Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { (-not $_.IsFramework) -and $_.InstallLocation })) {
                try { $cf = [IO.Path]::Combine([string]$pk.InstallLocation, 'MicrosoftGame.config'); if ([IO.File]::Exists($cf)) { $configs.Add(@($cf, [string]$pk.Name)) } } catch { }
            }
        } catch { }
    }
    foreach ($c in $configs) {
        try {
            [xml]$x = [IO.File]::ReadAllText($c[0])
            $exe = @($x.Game.ExecutableList.Executable | ForEach-Object { [string]$_.Name } | Where-Object { $_ -and ($_ -notmatch '(?i)launcher|crash|setup') })[0]
            $nom = [string]$x.Game.ShellVisuals.DefaultDisplayName
            if ((-not $nom) -or ($nom -like 'ms-resource*')) { $nom = [string]$c[1] }
            if ($exe) { Agregar 'Xbox' ([string]$c[1]) $nom '' @() '' $exe '' }
        } catch { }
    }

    # EA app, Battle.net, Ubisoft, Riot y Rockstar: lo que figura instalado en Windows, segun quien lo publica
    $editores = @(@('(?i)electronic arts', 'EA'), @('(?i)blizzard', 'Battle.net'), @('(?i)ubisoft', 'Ubisoft'), @('(?i)riot games', 'Riot'), @('(?i)rockstar games', 'Rockstar'))
    $instalados = @(Juegos-Desinstalar)
    foreach ($e in $instalados) {
        if ((-not $e.Dir) -or (-not $e.Nombre)) { continue }
        foreach ($ed in $editores) {
            if ($e.Editor -match $ed[0]) { Agregar $ed[1] $e.Id $e.Nombre $e.Dir @([IO.Path]::GetFileName($e.Dir.TrimEnd('\'))) '' '' ''; break }
        }
    }
    # Registros propios de EA, Ubisoft y Rockstar
    foreach ($b in 'HKLM:\SOFTWARE\WOW6432Node\EA Games', 'HKLM:\SOFTWARE\EA Games', 'HKLM:\SOFTWARE\WOW6432Node\Electronic Arts', 'HKLM:\SOFTWARE\Electronic Arts') {
        foreach ($p in @(Juegos-RegSub $b)) {
            try {
                $d = [string]$p.'Install Dir'; if (-not $d) { $d = [string]$p.InstallDir }
                $n = [string]$p.DisplayName; if (-not $n) { $n = [string]$p.PSChildName }
                if ($d) { Agregar 'EA' ([string]$p.PSChildName) $n $d @([string]$p.PSChildName) '' '' '' }
            } catch { }
        }
    }
    foreach ($b in 'HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs', 'HKLM:\SOFTWARE\Ubisoft\Launcher\Installs') {
        foreach ($p in @(Juegos-RegSub $b)) {
            try {
                $d = [string]$p.InstallDir
                if (-not $d) { continue }
                $d = $d -replace '/', '\'
                $n = [string](@($instalados | Where-Object { $_.Id -eq ('Uplay Install ' + $p.PSChildName) })[0].Nombre)
                if (-not $n) { $n = [IO.Path]::GetFileName($d.TrimEnd('\')) }
                Agregar 'Ubisoft' ([string]$p.PSChildName) $n $d @() '' '' ''
            } catch { }
        }
    }
    foreach ($b in 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games', 'HKLM:\SOFTWARE\Rockstar Games') {
        foreach ($p in @(Juegos-RegSub $b)) {
            try {
                $d = [string]$p.InstallFolder
                if ($d) { Agregar 'Rockstar' ([string]$p.PSChildName) ([string]$p.PSChildName) $d @() '' '' '' }
            } catch { }
        }
    }
    # Rutas predefinidas de cada plataforma, en todos los discos
    foreach ($par in @(
        @('EA', @('Program Files\EA Games', 'EA Games', 'Program Files (x86)\Origin Games', 'Origin Games')),
        @('Ubisoft', @('Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games', 'Program Files\Ubisoft\Ubisoft Game Launcher\games', 'Ubisoft Game Launcher\games', 'Ubisoft\games')),
        @('Riot', @('Riot Games', 'Program Files\Riot Games')),
        @('Epic', @('Program Files\Epic Games', 'Epic Games')),
        @('Rockstar', @('Program Files\Rockstar Games', 'Rockstar Games')))) {
        foreach ($g in @(Juegos-Carpetas $par[1])) { Agregar $par[0] ([IO.Path]::GetFileName($g)) ([IO.Path]::GetFileName($g)) $g @() '' '' '' }
    }

    # Minecraft Java: si alguna cuenta de la PC tiene la carpeta .minecraft, el juego corre como javaw
    try {
        $hayMc = $false
        foreach ($u in @([IO.Directory]::GetDirectories([IO.Path]::Combine($env:SystemDrive + '\', 'Users')))) {
            if ([IO.Directory]::Exists([IO.Path]::Combine($u, 'AppData\Roaming\.minecraft'))) { $hayMc = $true; break }
        }
        if ($hayMc) { Agregar 'Minecraft' 'java' 'Minecraft Java' '' @() '' 'javaw.exe' '' }
    } catch { }

    try {
        if (-not [IO.Directory]::Exists($dirC)) { [void][IO.Directory]::CreateDirectory($dirC) }
        [IO.File]::WriteAllLines($fc, $nuevaC.ToArray(), (New-Object Text.UTF8Encoding($false)))
    } catch { }
    $res | Sort-Object Nombre
}
# <<< XUCA-JUEGOS

# Juegos detectados (una vez por corrida) y la lista para elegir: nombre (plataforma) y abajo el proceso
function Afi-Detectados {
    if ($null -eq $global:XAfiDet) { $global:XAfiDet = @(Juegos-Detectados | Where-Object { -not (Afi-Prohibido $_.Proc) }) }
    return $global:XAfiDet
}
function Afi-DetectadosProcs { return @(Afi-Detectados | ForEach-Object { $_.Proc }) }
function Afi-Mostrar($pl) {
    Say ('  Procesador: ' + $pl.Cpu + ' - ' + $pl.Tipo) 'Cyan'
    Say ('    Juegos:           ' + (Afi-Lista $pl.Juego) + ' (' + (Afi-Hilos $pl.Juego) + ' hilos)') 'Cyan'
    if ($pl.Liviano -ne $pl.Juego) { Say ('    Juegos livianos:  ' + (Afi-Lista $pl.Liviano) + ' (' + (Afi-Hilos $pl.Liviano) + ' hilos) - ' + ($afiLivianos -join ', ')) 'Cyan' }
    Say ('    Fondo:            ' + (Afi-Lista $pl.Fondo) + ' (' + (Afi-Hilos $pl.Fondo) + ' hilos), solo mientras jugas') 'Cyan'
}

# ------------------------------------------------------------
# Acciones: lo que antes hacia la parte de PowerShell del .bat (una por cada ACT).
# Devuelven 0 = hecho, 1 = fallo, 2 = no aplica en esta PC, 5 = ya estaba, 6 = queda un paso para despues, 10 = caso especial.
# $XDato: los valores para SPI (mouse) y DX (graficos).
# ------------------------------------------------------------
function Gaming-Act([string]$XAct, [string]$XDato) {
    $code = 0
    . {
    switch ($XAct) {

    'GB_CHECK' {
        # 10 = Ryzen X3D de dos bloques: la app Game Bar se deja instalada.
        $pl = Afi-Plan
        $g = Gb-Consejo $pl
        if ($g.Necesaria) {
            $code = 10
            Log 'INFO' ('Game Bar: no se borra la app porque ' + $pl.Cpu + ' es un X3D de dos bloques')
            if (@(Get-AppxPackage -AllUsers -Name 'Microsoft.XboxGamingOverlay*').Count -eq 0) {
                Say '  La Game Bar no esta instalada: en tu procesador conviene tenerla. Reinstalala con R en esta opcion o desde la Microsoft Store.' 'Yellow'
                Log 'ATENCION' 'la Game Bar no esta instalada y este procesador la necesita para el driver de V-Cache de AMD'
            }
        }
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
        foreach ($e in ($XDato -split ';')) {
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
            foreach ($e in (([string]$actual + ';' + $XDato) -split ';')) {
                if ($e -match '^(.+?)=(.*)$') {
                    if ($Matches[2] -eq 'DEL') { $mapa.Remove($Matches[1]) } else { $mapa[$Matches[1]] = $Matches[2] }
                }
            }
            $nuevo = ($mapa.GetEnumerator() | ForEach-Object { '{0}={1};' -f $_.Key, $_.Value }) -join ''
            New-ItemProperty -Path $k -Name DirectXUserGlobalSettings -Value $nuevo -PropertyType String -Force | Out-Null
            $leido = (Get-ItemProperty -Path $k -Name DirectXUserGlobalSettings).DirectXUserGlobalSettings
            foreach ($e in ($XDato -split ';')) {
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
            $on = ($XAct -eq 'PWR_ON')
            $usb = 0
            $pcie = 0
            if ($on) {
                $usb = 1
                $pcie = 1
                if ($g -in '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c', 'e9a42b02-d5df-448d-aa00-03f14749eb61') { $pcie = 0 }
            }
            # Ac / Dc = valor con corriente / con bateria ($null = no se toca). Opc = si no existe en esta PC, se saltea.
            $cfg = @(
                @{ Nom = 'suspension selectiva USB'; Sub = '2a737441-1930-4402-8d77-b2bebba308a3'; Cfg = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'; Ac = $usb; Dc = $usb },
                @{ Nom = 'ahorro de energia PCI Express'; Sub = '501a4d13-42af-4429-9fd1-a8218c268e20'; Cfg = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Ac = $pcie; Dc = $pcie },
                @{ Nom = 'ahorro de energia de USB 3 (0 = apagado, 2 = moderado)'; Sub = '2a737441-1930-4402-8d77-b2bebba308a3'; Cfg = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'; Ac = $(if ($on) { 2 } else { 0 }); Dc = $(if ($on) { 2 } else { 0 }); Opc = $true },
                @{ Nom = 'apagar el disco con corriente (segundos, 0 = nunca)'; Sub = '0012ee47-9041-4b5d-9b77-535fba8b1442'; Cfg = '6738e2c4-e8a5-4a42-b16a-e040e769756e'; Ac = $(if ($on) { 1200 } else { 0 }); Dc = $null; Opc = $true }
            )
            $hizo = $false
            foreach ($c in $cfg) {
                if ($c.Opc) {
                    & powercfg /query $g $c.Sub $c.Cfg *> $null
                    if ($LASTEXITCODE -ne 0) { Log 'OMITIDO' ('no existe en esta PC: ' + $c.Nom); continue }
                }
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $g + '\' + $c.Sub + '\' + $c.Cfg
                $ac = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).ACSettingIndex
                $dc = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).DCSettingIndex
                $txt = 'corriente ' + $c.Ac + $(if ($null -ne $c.Dc) { ', bateria ' + $c.Dc } else { '' })
                if (($ac -eq $c.Ac) -and (($null -eq $c.Dc) -or ($dc -eq $c.Dc))) {
                    Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $txt + ' en el plan ' + $g)
                    continue
                }
                $hizo = $true
                & powercfg /setacvalueindex $g $c.Sub $c.Cfg $c.Ac
                $a = $LASTEXITCODE
                $d = 0
                if ($null -ne $c.Dc) { & powercfg /setdcvalueindex $g $c.Sub $c.Cfg $c.Dc; $d = $LASTEXITCODE }
                $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).ACSettingIndex
                if ($a -eq 0 -and $d -eq 0 -and $v -eq $c.Ac) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $txt + ' en el plan ' + $g) }
                else { Log 'FALLO' ('no se pudo verificar ' + $c.Nom); $code = 1 }
            }
            if ($hizo) { & powercfg /setactive $g }
            elseif ($code -eq 0) { $code = 5 }
        }
    }

    { $_ -eq 'NAGLE_OFF' -or $_ -eq 'NAGLE_ON' } {
        # NAGLE_OFF: TcpAckFrequency 1, TCPNoDelay 1 y TcpDelAckTicks 0 en cada conexion con IP.
        # NAGLE_ON: se borran esos valores y Windows vuelve a su comportamiento normal.
        $base = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
        $vals = [ordered]@{ TcpAckFrequency = 1; TCPNoDelay = 1; TcpDelAckTicks = 0 }
        $ifs = @(Get-ChildItem -Path $base -ErrorAction SilentlyContinue | Where-Object {
            $pp = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            $ips = @(@($pp.DhcpIPAddress) + @($pp.IPAddress) | Where-Object { ([string]$_) -match '^\d+\.\d+\.\d+\.\d+$' -and ([string]$_) -ne '0.0.0.0' })
            $ips.Count -gt 0
        })
        if ($ifs.Count -eq 0) {
            Log 'OMITIDO' 'no se encontro ninguna conexion de red con IP'
            $code = 2
        } else {
            $hizo = $false
            foreach ($k in $ifs) {
                $id = Split-Path -Leaf $k.Name
                foreach ($n in @($vals.Keys)) {
                    $act = (Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue).$n
                    if ($XAct -eq 'NAGLE_OFF') {
                        if (($null -ne $act) -and ([int]$act -eq $vals[$n])) { Log 'OK' ('ya estaba: ' + $id + ' ' + $n + ' = ' + $vals[$n]); continue }
                        $hizo = $true
                        try { New-ItemProperty -Path $k.PSPath -Name $n -Value $vals[$n] -PropertyType DWord -Force -ErrorAction Stop | Out-Null } catch { }
                        $v = (Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue).$n
                        if (($null -ne $v) -and ([int]$v -eq $vals[$n])) { Log 'OK' ('verificado: ' + $id + ' ' + $n + ' = ' + $vals[$n]) }
                        else { Log 'FALLO' ('no se pudo poner ' + $id + ' ' + $n); $code = 1 }
                    } else {
                        if ($null -eq $act) { Log 'OK' ('ya no existia: ' + $id + ' ' + $n); continue }
                        $hizo = $true
                        try { Remove-ItemProperty -Path $k.PSPath -Name $n -ErrorAction Stop } catch { }
                        if ($null -eq (Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue).$n) { Log 'OK' ('borrado: ' + $id + ' ' + $n) }
                        else { Log 'FALLO' ('no se pudo borrar ' + $id + ' ' + $n); $code = 1 }
                    }
                }
            }
            if ((-not $hizo) -and ($code -eq 0)) { $code = 5 }
        }
    }

    # Cable a 1 Gbps: "Speed & Duplex" (*SpeedDuplex) de las placas de cable de 2.5 Gbps o mas.
    # Lo que tenia cada placa se anota en velocidad_cable.txt para que R lo deje como estaba.
    { $_ -eq 'DUP_ON' -or $_ -eq 'DUP_R' } {
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $guarda = Join-Path $dir 'velocidad_cable.txt'
        $notas = @()
        if (Test-Path -LiteralPath $guarda) { $notas = @(Get-Content -LiteralPath $guarda) }
        $hay = 0
        $hizo = $false
        foreach ($a in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { ($_.NdisPhysicalMedium -eq 14) -and ([string]$_.Status -ne 'Disabled') })) {
            # Se busca por nombre exacto: con -RegistryKeyword Windows toma el * como comodin
            $pr = @($a | Get-NetAdapterAdvancedProperty -AllProperties -ErrorAction SilentlyContinue | Where-Object { ([string]$_.RegistryKeyword) -eq '*SpeedDuplex' }) | Select-Object -First 1
            if (-not $pr) { continue }
            $nom = @($pr.ValidDisplayValues); $val = @($pr.ValidRegistryValues)
            $mas = $false; $uno = $null; $auto = $null
            for ($k = 0; $k -lt [math]::Min($nom.Count, $val.Count); $k++) {
                $t = [string]$nom[$k]
                if ($t -match '(?<![\d.])(2\.5|5|10)\s*Gbps') { $mas = $true }
                if (($t -match '(?<![\d.])(1(\.0)?\s*Gbps|1000\s*Mbps)') -and ($t -match '(?i)full|complet')) { $uno = [string]$val[$k] }
                if ($t -match '(?i)auto') { $auto = [string]$val[$k] }
            }
            if (-not ($mas -and $uno)) { continue }
            $hay++
            $antes = [string](@($pr.RegistryValue)[0])
            if ($a.Status -eq 'Up') { Log 'INFO' ($a.Name + ' conectado a ' + $a.LinkSpeed) }
            if ($XAct -eq 'DUP_ON') {
                if ($antes -eq $uno) { Log 'OK' ('ya estaba: ' + $a.Name + ' a 1 Gbps'); continue }
                if (-not ($notas | Where-Object { $_ -like ('dup|' + $a.InterfaceGuid + '|*') })) { $notas += ('dup|' + $a.InterfaceGuid + '|' + $antes) }
                $nuevo = $uno
            } else {
                $nota = @($notas | Where-Object { $_ -like ('dup|' + $a.InterfaceGuid + '|*') }) | Select-Object -First 1
                $nuevo = $(if ($nota) { ($nota -split '\|')[2] } elseif ($antes -eq $uno) { $auto } else { $null })
                if ((-not $nuevo) -or ($nuevo -eq $antes)) { Log 'OK' ('ya estaba: ' + $a.Name + ' sin limite de velocidad'); continue }
            }
            try {
                $pr | Set-NetAdapterAdvancedProperty -RegistryValue $nuevo -NoRestart -ErrorAction Stop
                Log 'OK' ($a.Name + ': Speed & Duplex = ' + $nuevo + ' (se aplica al reiniciar)')
                $hizo = $true
            } catch { Log 'FALLO' ('no se pudo cambiar Speed & Duplex en ' + $a.Name + ': ' + $_.Exception.Message); $code = 1 }
        }
        if ($XAct -eq 'DUP_ON') { if ($notas.Count) { Set-Content -LiteralPath $guarda -Value @($notas | Select-Object -Unique) } }
        elseif ($code -eq 0) { Remove-Item -LiteralPath $guarda -Force -ErrorAction SilentlyContinue }
        if ($hay -eq 0) {
            Log 'OMITIDO' 'no hay placa de cable de 2.5 Gbps o mas'
            Say '  Tu placa de cable es de 1 Gbps o menos: no hace falta.' 'Yellow'
            $code = 2
        } elseif ((-not $hizo) -and ($code -eq 0)) { $code = 5 }
    }

    # WiFi y cable a la vez. Lo que se cambia de cada placa se anota en wifi_lan.txt para que R lo deje como estaba.
    { $_ -eq 'WIFILAN_ON' -or $_ -eq 'WIFILAN_R' } {
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $guarda = Join-Path $dir 'wifi_lan.txt'
        $placas = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue)
        $wifi = @($placas | Where-Object { $_.NdisPhysicalMedium -eq 9 })
        $lan = @($placas | Where-Object { $_.NdisPhysicalMedium -eq 14 })
        # Plan de energia: "Configuracion de adaptador inalambrico" (0 = Rendimiento maximo)
        $subW = '19cad22e-06db-433b-a9f3-6a1d0b7c4b19'; $setW = '12bbebe6-58d6-4636-95bb-3217ef867c1a'

        if ($XAct -eq 'WIFILAN_ON') {
            if (($wifi.Count -eq 0) -or ($lan.Count -eq 0)) { Log 'OMITIDO' 'esta PC no tiene placa WiFi y de cable a la vez'; $code = 2; break }
            $notas = @()
            if (Test-Path -LiteralPath $guarda) { $notas = @(Get-Content -LiteralPath $guarda) }
            # Prioridad: el cable primero (numero mas bajo = se usa primero)
            foreach ($a in $lan) {
                try { Set-NetIPInterface -InterfaceIndex $a.ifIndex -AutomaticMetric Disabled -InterfaceMetric 10 -ErrorAction Stop; Log 'OK' ('prioridad 10 para el cable: ' + $a.Name) }
                catch { Log 'INFO' ('no se pudo poner la prioridad de ' + $a.Name + ': ' + $_.Exception.Message) }
            }
            foreach ($a in $wifi) {
                try { Set-NetIPInterface -InterfaceIndex $a.ifIndex -AutomaticMetric Disabled -InterfaceMetric 20 -ErrorAction Stop; Log 'OK' ('prioridad 20 para el WiFi: ' + $a.Name) }
                catch { Log 'INFO' ('no se pudo poner la prioridad de ' + $a.Name + ': ' + $_.Exception.Message) }
                # "Disable Upon Wired Connect" del driver (solo existe con el driver de la marca, por ejemplo Intel)
                foreach ($pr in @($a | Get-NetAdapterAdvancedProperty -AllProperties -ErrorAction SilentlyContinue | Where-Object { ([string]$_.DisplayName) -match '(?i)wired connect' })) {
                    $apagado = @($pr.ValidDisplayValues | Where-Object { $_ -match '(?i)^(disabled?|deshabilitad|desactivad)' }) | Select-Object -First 1
                    if (-not $apagado) { continue }
                    if ([string]$pr.DisplayValue -eq [string]$apagado) { Log 'OK' ('ya estaba: ' + $a.Name + ' ' + $pr.DisplayName + ' = ' + $apagado); continue }
                    $notas += ('adv|' + $a.InterfaceGuid + '|' + $pr.RegistryKeyword + '|' + [string](@($pr.RegistryValue)[0]))
                    try { $pr | Set-NetAdapterAdvancedProperty -DisplayValue $apagado -NoRestart -ErrorAction Stop; Log 'OK' ($a.Name + ': ' + $pr.DisplayName + ' = ' + $apagado) }
                    catch { Log 'FALLO' ('no se pudo cambiar ' + $pr.DisplayName + ' en ' + $a.Name); $code = 1 }
                }
                # Que Windows no apague la placa WiFi para ahorrar energia
                try {
                    $pm = Get-NetAdapterPowerManagement -Name $a.Name -ErrorAction Stop
                    if ([string]$pm.AllowComputerToTurnOffDevice -eq 'Enabled') {
                        $notas += ('pm|' + $a.InterfaceGuid)
                        Set-NetAdapterPowerManagement -Name $a.Name -AllowComputerToTurnOffDevice Disabled -NoRestart -ErrorAction Stop
                        Log 'OK' ('Windows ya no apaga ' + $a.Name + ' para ahorrar energia')
                    } else { Log 'OK' ('ya estaba: Windows no apaga ' + $a.Name) }
                } catch { Log 'INFO' ('ahorro de energia de ' + $a.Name + ': ' + $_.Exception.Message) }
            }
            # Plan de energia: WiFi a Rendimiento maximo (se guarda lo que habia, enchufado y con bateria)
            $q = (& powercfg /query SCHEME_CURRENT $subW $setW | Out-String)
            $hx = @([regex]::Matches($q, '0x[0-9a-fA-F]{8}') | ForEach-Object { $_.Value })
            if ($hx.Count -ge 2) {
                if (-not ($notas | Where-Object { $_ -like 'plan|*' })) { $notas += ('plan|' + [Convert]::ToInt32($hx[-2], 16) + '|' + [Convert]::ToInt32($hx[-1], 16)) }
                & powercfg /setacvalueindex SCHEME_CURRENT $subW $setW 0 | Out-Null
                & powercfg /setdcvalueindex SCHEME_CURRENT $subW $setW 0 | Out-Null
                & powercfg /setactive SCHEME_CURRENT | Out-Null
                Log 'OK' 'plan de energia: WiFi en Rendimiento maximo'
            } else { Log 'INFO' 'el plan de energia no tiene la opcion del adaptador inalambrico' }
            Set-Content -LiteralPath $guarda -Value @($notas | Select-Object -Unique)
        } else {
            foreach ($a in @($lan + $wifi)) {
                try { Set-NetIPInterface -InterfaceIndex $a.ifIndex -AutomaticMetric Enabled -ErrorAction Stop; Log 'OK' ('prioridad automatica otra vez: ' + $a.Name) } catch { }
            }
            $notas = @()
            if (Test-Path -LiteralPath $guarda) { $notas = @(Get-Content -LiteralPath $guarda) }
            foreach ($n in $notas) {
                $c = $n -split '\|'
                try {
                    if ($c[0] -eq 'adv') {
                        $a = @($placas | Where-Object { [string]$_.InterfaceGuid -eq $c[1] }) | Select-Object -First 1
                        if ($a) { Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $c[2] -RegistryValue $c[3] -NoRestart -ErrorAction Stop; Log 'OK' ($a.Name + ': ' + $c[2] + ' vuelve a ' + $c[3]) }
                    } elseif ($c[0] -eq 'pm') {
                        $a = @($placas | Where-Object { [string]$_.InterfaceGuid -eq $c[1] }) | Select-Object -First 1
                        if ($a) { Set-NetAdapterPowerManagement -Name $a.Name -AllowComputerToTurnOffDevice Enabled -NoRestart -ErrorAction Stop; Log 'OK' ('Windows puede volver a apagar ' + $a.Name) }
                    } elseif ($c[0] -eq 'plan') {
                        & powercfg /setacvalueindex SCHEME_CURRENT $subW $setW ([int]$c[1]) | Out-Null
                        & powercfg /setdcvalueindex SCHEME_CURRENT $subW $setW ([int]$c[2]) | Out-Null
                        & powercfg /setactive SCHEME_CURRENT | Out-Null
                        Log 'OK' 'plan de energia del WiFi como estaba'
                    }
                } catch { Log 'FALLO' ('no se pudo restaurar: ' + $n); $code = 1 }
            }
            Remove-Item -LiteralPath $guarda -Force -ErrorAction SilentlyContinue
        }
    }

    { $_ -eq 'NIC_OFF' -or $_ -eq 'NIC_ON' } {
        $val = 0
        if ($XAct -eq 'NIC_ON') { $val = 1 }
        $claves = '*EEE', 'EEE', 'AdvancedEEE', 'GreenEthernet', 'EnableGreenEthernet', 'PowerSavingMode'
        $existen = 0
        $cambio = $false
        $omitio = $false
        # Las opciones se buscan por nombre exacto. Con -RegistryKeyword '*EEE' Windows toma el * como comodin y trae
        # tambien EEE y AdvancedEEE juntas: la comparacion fallaba siempre y la app quedaba en "Sin aplicar".
        function Nic-Prop($ad, [string]$kw) { return (@($ad | Get-NetAdapterAdvancedProperty -AllProperties -ErrorAction SilentlyContinue | Where-Object { ([string]$_.RegistryKeyword) -eq $kw }) | Select-Object -First 1) }
        function Nic-Valor($p) { if (-not $p) { return $null }; return [string](@($p.RegistryValue)[0]) }
        foreach ($a in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })) {
            $clase = $null
            try {
                $clase = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction Stop |
                    Where-Object { (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $a.InterfaceGuid } |
                    Select-Object -First 1
            } catch { }
            $todas = @($a | Get-NetAdapterAdvancedProperty -AllProperties -ErrorAction SilentlyContinue)
            foreach ($kw in $claves) {
                $pr = @($todas | Where-Object { ([string]$_.RegistryKeyword) -eq $kw }) | Select-Object -First 1
                if (-not $pr) { continue }
                $existen++
                if ((Nic-Valor $pr) -eq ([string]$val)) {
                    Log 'OK' ('ya estaba: ' + $a.Name + ' ' + $kw + ' = ' + $val)
                    continue
                }
                try { $pr | Set-NetAdapterAdvancedProperty -RegistryValue ([string]$val) -NoRestart -ErrorAction Stop }
                catch { Log 'INFO' ('Set-NetAdapterAdvancedProperty ' + $kw + ': ' + $_.Exception.Message) }
                if ((Nic-Valor (Nic-Prop $a $kw)) -eq ([string]$val)) {
                    Log 'OK' ('verificado: ' + $a.Name + ' ' + $kw + ' = ' + $val + ' (se aplica al reiniciar)')
                    $cambio = $true
                    continue
                }
                if ($clase) {
                    try { Set-ItemProperty -Path $clase.PSPath -Name $kw -Value ([string]$val) -ErrorAction Stop }
                    catch { Log 'INFO' ('registro directo ' + $kw + ': ' + $_.Exception.Message) }
                    $leido = (Get-ItemProperty -Path $clase.PSPath -ErrorAction SilentlyContinue).PSObject.Properties[$kw].Value
                    if (([string]$leido) -eq ([string]$val)) {
                        Log 'OK' ('verificado por registro: ' + $a.Name + ' ' + $kw + ' = ' + $val + ' (se aplica al reiniciar)')
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
                # Pausa para que se vean los resultados (en la app se muestran en la pantalla de carga)
                Start-Sleep -Milliseconds 1500
                $code = 2
            } else {
                $mejor = $validos[0]
                $deseado = @($mejor.Ips)
                Say ('  El mas rapido para tu conexion: ' + $mejor.Nombre + ' (' + ($deseado -join ', ') + ')') 'Green'
                # Pausa para que se vean los ms de cada DNS (en la app se muestran en la pantalla de carga)
                Start-Sleep -Milliseconds 1500
                Log 'INFO' ('DNS elegido: ' + $mejor.Nombre + ' ' + ($deseado -join ', '))
                if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                Proteger-Carpeta $dir
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
        Proteger-Carpeta $dir
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
        if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe) -and (Ver-Igual $exe $CodTimer)) {
            if ($globOk) { Log 'OK' 'ya estaba: temporizador corriendo para todo el sistema'; $code = 5 }
            else { Log 'OK' 'ya estaba: temporizador corriendo' }
        }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue | Stop-Process -Force
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            Proteger-Carpeta $dir
            $cs = $CodTimer
            Esperar-Cierre 'XucaTimer'
            # Si el programa ya es el de esta version, se usa ese (no hace falta compilarlo de nuevo).
            # Si no, se borra el viejo antes de compilar: si quedara trabado, no se instala encima con la huella nueva.
            if ((-not (Test-Path $exe)) -or (-not (Ver-Igual $exe $cs))) {
                Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
                try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar TIMER: ' + $_.Exception.Message); $code = 1 }
            }
            if (Test-Path $exe) {
                $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                Start-ScheduledTask -TaskName $tn
                if (Esperar-Tarea $tn) { Ver-Guardar $exe $cs; Log 'OK' 'verificado: temporizador a 0.5ms' } else { Log 'FALLO' 'la tarea XucaTimer no quedo corriendo'; $code = 1 }
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
            Esperar-Cierre 'XucaTimer'
            Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $kk -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue
            $queda = (Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue) -or (Get-Process -Name 'XucaTimer' -ErrorAction SilentlyContinue) -or ($null -ne (Get-ItemProperty -Path $kk -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests)
            if ($queda) { Log 'FALLO' 'el temporizador no se pudo borrar del todo'; $code = 1 }
            else { Log 'OK' 'verificado: temporizador borrado (Windows vuelve a su valor por defecto)' }
        }
    }

    'RAM_ON' {
        $tn = 'XucaRAM'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaRAM.exe'
        Proteger-Carpeta $dir
        $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
        if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe) -and (Ver-Igual $exe $CodRam)) { Log 'OK' 'ya estaba: limpiador RAM corriendo'; $code = 5 }
        else {
            if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
            Get-Process -Name 'XucaRAM' -ErrorAction SilentlyContinue | Stop-Process -Force
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            $cs = $CodRam
            Esperar-Cierre 'XucaRAM'
            # Si el programa ya es el de esta version, se usa ese (no hace falta compilarlo de nuevo).
            # Si no, se borra el viejo antes de compilar: si quedara trabado, no se instala encima con la huella nueva.
            if ((-not (Test-Path $exe)) -or (-not (Ver-Igual $exe $cs))) {
                Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
                try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar RAM: ' + $_.Exception.Message); $code = 1 }
            }
            if (Test-Path $exe) {
                $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                Start-ScheduledTask -TaskName $tn
                if (Esperar-Tarea $tn) { Ver-Guardar $exe $cs; Log 'OK' 'verificado: limpiador RAM (< 1024MB)' } else { Log 'FALLO' 'la tarea XucaRAM no quedo corriendo'; $code = 1 }
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
            Esperar-Cierre 'XucaRAM'
            Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
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
                @{ Nom = 'rendimiento (preferencia energia-rendimiento, 0 = maximo)'; Cfg = '36687f9e-e3a5-4dbf-b1dc-15eb381c6863'; Val = 0 },
                # Extras: si alguno no existe en esta PC (depende del procesador y de Windows) se saltea sin dar error
                @{ Nom = 'estado maximo del procesador'; Cfg = 'bc5038f7-23e0-4960-96da-33abaf5935ec'; Val = 100; Opc = $true },
                @{ Nom = 'modo del turbo (2 = agresivo)'; Cfg = 'be337238-6d82-4146-a960-4f3749d470c7'; Val = 2; Opc = $true },
                @{ Nom = 'subida de velocidad (2 = rapida, Rocket)'; Cfg = '465e1f50-b610-473a-ab58-00d1077dc418'; Val = 2; Opc = $true },
                @{ Nom = 'enfriamiento (1 = ventiladores primero, activo)'; Cfg = '94d3a615-a899-4ac5-ae2b-e4d8f634367f'; Val = 1; Opc = $true }
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
            # Los extras que no existen en esta PC se sacan de la lista
            $cfg = @($cfg | Where-Object { (-not $_.Opc) -or ($null -ne (Actual $_.Cfg)) })
            if ($XAct -eq 'CPU_ON') {
                $faltan = @($cfg | Where-Object { (Actual $_.Cfg) -ne $_.Val })
                if ($faltan.Count -eq 0) {
                    Log 'OK' ('ya estaba: Modo Nitro del procesador en el plan ' + $g)
                    $code = 5
                } else {
                    $sinCopia = $false
                    if (Test-Path $bak) {
                        Log 'INFO' ('ya existia una copia de tus valores anteriores, se conserva: ' + $bak)
                        # Si la copia es de una version vieja del script, se le suman los ajustes nuevos con su valor de ahora
                        $tiene = @(Get-Content $bak | ForEach-Object { ($_ -split '=')[0] })
                        $suma = @(foreach ($c in $cfg) { if ($tiene -notcontains $c.Cfg) { $c.Cfg + '=' + (Actual $c.Cfg) } })
                        if ($suma.Count -gt 0) { Add-Content -Path $bak -Value $suma; Log 'INFO' ('se sumaron ' + $suma.Count + ' ajustes nuevos a la copia de tus valores anteriores') }
                    } else {
                        if (-not (Test-Path $dir)) {
                            New-Item -Path $dir -ItemType Directory -Force | Out-Null
                            Proteger-Carpeta $dir
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

    { $_ -eq 'NB_ON' -or $_ -eq 'NB_OFF' } {
        # Solo cambia los valores "a bateria" (DC) del plan activo: enchufada la notebook rinde igual que antes
        $g = [regex]::Match((& powercfg /getactivescheme | Out-String), '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value
        $bat = $false
        try { $bat = (@(Get-CimInstance Win32_Battery -ErrorAction Stop).Count -gt 0) } catch { }
        $dir = Join-Path $env:ProgramData 'XucaScripts'
        $bak = Join-Path $dir ('nb_' + $g + '.txt')
        if (-not $g) {
            Log 'FALLO' 'no se pudo leer el plan de energia activo'
            $code = 1
        } elseif (($XAct -eq 'NB_ON') -and (-not $bat)) {
            Log 'OMITIDO' 'esta PC no tiene bateria: es para notebooks'
            Say '  Tu PC no tiene bateria: esto es para notebooks.' 'Yellow'
            $code = 2
        } else {
            $sp = '54533251-82be-4824-96c1-47b60b740d00'
            # Si alguno no existe en esta PC (depende del procesador y de Windows) se saltea sin dar error
            $cfg = @(
                @{ Nom = 'turbo a bateria (3 = eficiente)'; Sub = $sp; Cfg = 'be337238-6d82-4146-a960-4f3749d470c7'; Val = 3 },
                @{ Nom = 'preferencia energia-rendimiento a bateria (70 = prioriza la bateria)'; Sub = $sp; Cfg = '36687f9e-e3a5-4dbf-b1dc-15eb381c6863'; Val = 70 },
                @{ Nom = 'enfriamiento a bateria (0 = baja la velocidad antes de prender los ventiladores)'; Sub = $sp; Cfg = '94d3a615-a899-4ac5-ae2b-e4d8f634367f'; Val = 0 },
                @{ Nom = 'ahorro de bateria automatico (30 por ciento)'; Sub = 'de830923-a562-41af-a086-e3a2c6bad2da'; Cfg = 'e69653ca-cf7f-4f05-aa73-cb833fa90ad4'; Val = 30 }
            )
            function LeerDc($c) {
                $o = & powercfg /query $g $c.Sub $c.Cfg | Out-String
                $m = [regex]::Matches($o, '0x[0-9a-fA-F]{8}')
                if ($m.Count -lt 2) { return $null }
                return [Convert]::ToInt32($m[$m.Count - 1].Value.Substring(2), 16)
            }
            function LeerRegDc($c) {
                $rk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $g + '\' + $c.Sub + '\' + $c.Cfg
                return (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).DCSettingIndex
            }
            function ActualDc($c) {
                $x = LeerDc $c
                if ($null -eq $x) { $x = LeerRegDc $c }
                return $x
            }
            function PonerDc($c, $val) {
                & powercfg /setdcvalueindex $g $c.Sub $c.Cfg $val 2>&1 | Out-Null
                return (((LeerDc $c) -eq $val) -or ((LeerRegDc $c) -eq $val))
            }
            $cfg = @($cfg | Where-Object { $null -ne (ActualDc $_) })
            if ($XAct -eq 'NB_ON') {
                $faltan = @($cfg | Where-Object { (ActualDc $_) -ne $_.Val })
                if ($cfg.Count -eq 0) {
                    Log 'OMITIDO' 'este plan de energia no tiene ninguno de estos ajustes'
                    $code = 2
                } elseif ($faltan.Count -eq 0) {
                    Log 'OK' ('ya estaba: bateria priorizada en el plan ' + $g)
                    $code = 5
                } else {
                    $sinCopia = $false
                    if (Test-Path $bak) {
                        Log 'INFO' ('ya existia una copia de tus valores anteriores, se conserva: ' + $bak)
                    } else {
                        if (-not (Test-Path $dir)) {
                            New-Item -Path $dir -ItemType Directory -Force | Out-Null
                            Proteger-Carpeta $dir
                        }
                        Set-Content -Path $bak -Value @(foreach ($c in $cfg) { $c.Cfg + '=' + (ActualDc $c) })
                        if (Test-Path $bak) { Log 'INFO' ('copia de tus valores anteriores guardada en ' + $bak) }
                        else { Log 'FALLO' 'no se pudo guardar la copia de tus valores anteriores, no se cambio nada'; $code = 1; $sinCopia = $true }
                    }
                    if (-not $sinCopia) {
                        foreach ($c in $cfg) {
                            if ((ActualDc $c) -eq $c.Val) { Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $c.Val); continue }
                            if (PonerDc $c $c.Val) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $c.Val + ' en el plan ' + $g) }
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
                        $pz = $l -split '='
                        if ($pz.Count -eq 2 -and $pz[1] -match '^\d+$') { $guardado[$pz[0]] = [int]$pz[1] }
                    }
                    $hizo = $false
                    foreach ($c in $cfg) {
                        if (-not $guardado.ContainsKey($c.Cfg)) { continue }
                        $val = $guardado[$c.Cfg]
                        if ((ActualDc $c) -eq $val) { Log 'OK' ('ya estaba: ' + $c.Nom + ' = ' + $val); continue }
                        $hizo = $true
                        if (PonerDc $c $val) { Log 'OK' ('verificado: ' + $c.Nom + ' = ' + $val + ' (restaurado)') }
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
        foreach ($t in ($XDato -split ';')) {
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
        # Procesos de Windows: cambiarles la prioridad puede trabar o colgar la PC.
        $prioNo = @('system', 'idle', 'registry', 'smss', 'csrss', 'wininit', 'winlogon', 'services', 'lsass', 'lsaiso', 'svchost', 'dwm', 'explorer', 'audiodg', 'fontdrvhost', 'sihost', 'ctfmon', 'conhost', 'taskmgr', 'spoolsv', 'searchindexer', 'msmpeng', 'runtimebroker', 'dllhost', 'rundll32', 'cmd', 'powershell', 'pwsh')
        # Cada nombre es el proceso del juego tal como aparece en el Administrador de tareas, sin el .exe.
        $exes = New-Object System.Collections.Generic.List[string]
        foreach ($e in (([string]$env:PRIOJ) -split ',')) {
            $txt = $e.Trim().Trim('"').Trim()
            if (-not $txt) { continue }
            $txt = $txt -replace '(?i)\.exe$', ''
            if (($txt -notmatch '^[^\\/:*?"<>|=;,\[\]]{1,100}$') -or ($txt -match '^[. ]+$')) { Log 'OMITIDO' ('nombre de proceso no valido: "' + $txt + '"'); Say ('  "' + $txt + '" no es un nombre de proceso valido, se salteo.') 'Yellow' }
            elseif ($prioNo -contains $txt.ToLower()) { Log 'OMITIDO' ('"' + $txt + '" es de Windows, no se toca'); Say ('  "' + $txt + '" es un proceso de Windows, no se toca.') 'Yellow' }
            else { $exes.Add($txt + '.exe') }
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
            # Desde la app, la lista de juegos es la que manda: a los que sacaste de la lista se les quita la prioridad.
            if ($env:PRIOSYNC -eq '1') {
                foreach ($k in @(Get-ChildItem -LiteralPath $ifeo -ErrorAction SilentlyContinue | Where-Object { (Get-ItemProperty -LiteralPath ($_.PSPath + '\PerfOptions') -ErrorAction SilentlyContinue).XucaPrioridad -eq 1 })) {
                    if ($exes -contains $k.PSChildName) { continue }
                    Remove-Item -LiteralPath ($k.PSPath + '\PerfOptions') -Recurse -Force -ErrorAction SilentlyContinue
                    $resto = Get-Item -LiteralPath $k.PSPath -ErrorAction SilentlyContinue
                    if ($resto -and ($resto.SubKeyCount -eq 0) -and ($resto.ValueCount -eq 0)) { Remove-Item -LiteralPath $k.PSPath -Force -ErrorAction SilentlyContinue }
                    if (Test-Path -LiteralPath ($k.PSPath + '\PerfOptions')) { Log 'FALLO' ('no se pudo quitar la prioridad de ' + $k.PSChildName); $code = 1 }
                    else { $hizo++; Log 'OK' ('ya no esta en tu lista: ' + $k.PSChildName + ' vuelve a prioridad normal') }
                }
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

    'AFI_ON' {
        $tn = 'XucaAfinidad'; $dir = Join-Path $env:ProgramData 'XucaScripts'; $exe = Join-Path $dir 'XucaAfinidad.exe'; $cfg = Join-Path $dir 'afinidad.txt'
        $pl = Afi-Plan
        Proteger-Carpeta $dir
        if (-not $pl.Ok) { Log 'OMITIDO' $pl.Motivo; Say ('  No se cambio nada: ' + $pl.Motivo + '.') 'Yellow'; $code = 2 }
        else {
            # La app manda la eleccion completa: AFIJ (juegos) y AFIF (programas de fondo)
            $txtJ = [string]$env:AFIJ; $txtF = [string]$env:AFIF
            $juegos = @(Afi-Nombres $txtJ)
            $apps = @(Afi-Nombres $txtF | Where-Object { $juegos -notcontains $_ })
            $livianos = @($juegos | Where-Object { $afiLivianos -contains $_ })
            $pesados = @($juegos | Where-Object { $afiLivianos -notcontains $_ })
            if ($juegos.Count -eq 0) { Log 'OMITIDO' 'no quedo ningun juego elegido'; Say '  No quedo ningun juego elegido: no se cambio nada.' 'Yellow'; $code = 2 }
            else {
                $desc = ($pl.Cpu + ' (' + $pl.Tipo + '): juegos en ' + (Afi-Lista $pl.Juego) + ', livianos en ' + (Afi-Lista $pl.Liviano) + ', fondo en ' + (Afi-Lista $pl.Fondo))
                Log 'INFO' ('Procesador: ' + $desc)
                Afi-Mostrar $pl
                $txt = (@(('juego=' + $pl.Juego), ('liviano=' + $pl.Liviano), ('fondo=' + $pl.Fondo), ('todo=' + $pl.Todo), ('juegos=' + ($pesados -join ',')), ('livianos=' + ($livianos -join ',')), ('apps=' + ($apps -join ',')), ('desc=' + $desc), ('detectados=' + ((Afi-DetectadosProcs) -join ',')), 'ver=3') -join "`r`n")
                $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
                $viejo = ''; if (Test-Path -LiteralPath $cfg) { $viejo = [string](Get-Content -LiteralPath $cfg -Raw) }
                if ($t -and ($t.State -eq 'Running') -and (Test-Path $exe) -and (Ver-Igual $exe $CodAfi) -and ($viejo.Trim() -eq $txt.Trim())) {
                    Log 'OK' 'ya estaba: afinidad corriendo con los mismos juegos y programas'; $code = 5
                } else {
                    if ($t) { Stop-ScheduledTask -TaskName $tn; Unregister-ScheduledTask -TaskName $tn -Confirm:$false }
                    Get-Process -Name 'XucaAfinidad' -ErrorAction SilentlyContinue | Stop-Process -Force
                    Esperar-Cierre 'XucaAfinidad'
                    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                    Proteger-Carpeta $dir
                    Set-Content -LiteralPath $cfg -Value $txt -Encoding ASCII
                    Log 'OK' ('juegos: ' + ($pesados -join ', '))
                    if ($livianos.Count -gt 0) { Log 'OK' ('juegos livianos: ' + ($livianos -join ', ')) }
                    Log 'OK' ('programas de fondo: ' + ($apps -join ', '))
                    # Programa chico: cada 2 segundos mira que hay abierto y le vuelve a poner sus nucleos a cada juego si se los cambiaron
                    # (CS2 y otros los vuelven a poner en todos al arrancar). Si el antitrampas no deja (Valorant, Fortnite), lo saltea.
                    # Mientras haya un juego abierto, aunque sea uno protegido, lleva lo de fondo a sus nucleos; al cerrarlo, lo devuelve a todos.
                    $cs = $CodAfi
                    # Si el programa ya es el de esta version, se usa ese (solo cambio la lista de juegos, que lee de afinidad.txt)
                    if ((-not (Test-Path $exe)) -or (-not (Ver-Igual $exe $cs))) {
                        Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
                        try { Add-Type -TypeDefinition $cs -Language CSharp -OutputAssembly $exe -OutputType WindowsApplication } catch { Log 'FALLO' ('Compilar AFINIDAD: ' + $_.Exception.Message); $code = 1 }
                    }
                    if (Test-Path $exe) {
                        $acc = New-ScheduledTaskAction -Execute $exe; $trg = New-ScheduledTaskTrigger -AtStartup; $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
                        Register-ScheduledTask -TaskName $tn -Action $acc -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
                        Start-ScheduledTask -TaskName $tn
                        if (Esperar-Tarea $tn) { Ver-Guardar $exe $cs; Log 'OK' ('verificado: afinidad corriendo - ' + $desc) } else { Log 'FALLO' 'la tarea XucaAfinidad no quedo corriendo'; $code = 1 }
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
            Esperar-Cierre 'XucaAfinidad'
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
            Remove-Item -LiteralPath $exe, ($exe + '.ver') -Force -ErrorAction SilentlyContinue
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

    'LL_ON' {
        # Baja latencia (Low Latency Profile): es lo mismo que "vivetool /enable /id:58989092", escrito directo en el registro
        # (prioridad User = 8). La clave usa el ID ofuscado como lo guarda Windows: 58989092 -> 1213986446.
        $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $b = [int]$cv.CurrentBuildNumber; $u = [int]$cv.UBR
        if (($b -lt 26100) -or (($b -lt 26300) -and ($u -lt 8655))) {
            Log 'OMITIDO' ('Baja latencia necesita Windows 11 24H2 o 25H2 con la actualizacion de junio de 2026 (build .8655 o mas nueva); esta PC tiene ' + $b + '.' + $u)
            Say ('  Tu Windows todavia no trae Baja latencia: actualiza Windows (necesita build ' + $b + '.8655 o mas nueva, tenes ' + $b + '.' + $u + ').') 'Yellow'
            $code = 2
        } else {
            $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1213986446'
            if ((Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue).EnabledState -eq 2) {
                Log 'OK' 'ya estaba: Baja latencia activada (ID 58989092)'
                $code = 5
            } else {
                New-Item -Path $k -Force | Out-Null
                New-ItemProperty -LiteralPath $k -Name 'EnabledState' -Value 2 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $k -Name 'EnabledStateOptions' -Value 0 -PropertyType DWord -Force | Out-Null
                if ((Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue).EnabledState -eq 2) { Log 'OK' 'verificado: Baja latencia activada (ID 58989092), se aplica al reiniciar' }
                else { Log 'FALLO' 'no se pudo activar Baja latencia'; $code = 1 }
            }
        }
    }

    'LL_OFF' {
        # Igual que "vivetool /reset /id:58989092": se borra el cambio y Windows vuelve a decidir solo
        $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\1213986446'
        if (-not (Test-Path -LiteralPath $k)) {
            Log 'OK' 'ya estaba: Baja latencia sin cambios del script'
            $code = 5
        } else {
            Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $k) { Log 'FALLO' 'no se pudo quitar Baja latencia'; $code = 1 }
            else { Log 'OK' 'verificado: Baja latencia vuelve a como la maneja Windows' }
        }
    }

    }
    } | Out-Null
    return $code
}

# Corre una accion y devuelve su codigo (si se rompe, queda como PS-ERROR en el log)
function Act([string]$a, [string]$dato = '') { return (Hacer { Gaming-Act $a $dato } $a) }

# ------------------------------------------------------------
# Las opciones, en el orden en que se aplican. La app arma las casillas con Id, Seccion, Q, Hace, Favor y Contra.
# ------------------------------------------------------------
$ListaOpciones = @(
    @{
        Id = 'ms'; Seccion = 'MOUSE'
        Q = '- Desea mouse competitivo? (Sin aceleracion ni rastro, velocidad media)'
        Hace = 'saca la aceleracion del mouse y el rastro, y deja la velocidad en el punto medio.'
        Favor = 'el mismo movimiento de mano siempre mueve lo mismo: mejor punteria.'
        Contra = 'en el escritorio el mouse puede sentirse distinto hasta que te acostumbras.'
        S = {
            Opt-Ini 'Mouse competitivo'
            $m = 'HKCU\Control Panel\Mouse'
            $dif = (Reg-Dif $m 'MouseSensitivity' '10' 'REG_SZ') -or (Reg-Dif $m 'MouseSpeed' '0' 'REG_SZ') -or (Reg-Dif $m 'MouseThreshold1' '0' 'REG_SZ') -or (Reg-Dif $m 'MouseThreshold2' '0' 'REG_SZ')
            if (-not $dif) { Ya-Estaba }
            else {
                Resps (Act 'SPI' 'P:0x0071:10;M:0:0:0;U:0x0060:0;U:0x005D:0;P:0x1021:0;')
                Reg-Chk $m 'MouseSensitivity' '10'
                Reg-Chk $m 'MouseSpeed' '0'
                Reg-Chk $m 'MouseThreshold1' '0'
                Reg-Chk $m 'MouseThreshold2' '0'
            }
            Opt-Fin 'Mouse en modo competitivo'
        }
        R = {
            Opt-Ini 'Mouse competitivo (restaurar)'
            $m = 'HKCU\Control Panel\Mouse'
            $dif = (Reg-Dif $m 'MouseSensitivity' '10' 'REG_SZ') -or (Reg-Dif $m 'MouseSpeed' '1' 'REG_SZ') -or (Reg-Dif $m 'MouseThreshold1' '6' 'REG_SZ') -or (Reg-Dif $m 'MouseThreshold2' '10' 'REG_SZ')
            if (-not $dif) { Ya-Estaba }
            else {
                Resps (Act 'SPI' 'P:0x0071:10;M:6:10:1;U:0x0060:0;U:0x005D:0;P:0x1021:1;')
                Reg-Chk $m 'MouseSensitivity' '10'
                Reg-Chk $m 'MouseSpeed' '1'
                Reg-Chk $m 'MouseThreshold1' '6'
                Reg-Chk $m 'MouseThreshold2' '10'
            }
            Opt-Fin 'Mouse restaurado a los valores de Windows'
        }
    },
    @{
        Id = 'tk'; Seccion = 'TECLADO'
        Q = '- Desea desactivar los atajos de accesibilidad? (Shift x5, Alt+Shift y otros ya no abren carteles en partida)'
        Hace = 'apaga los atajos de accesibilidad que se activan sin querer jugando: Shift 5 veces, Shift derecho 8 segundos, Bloq Num 5 segundos, Alt+Shift+Bloq Num (teclas del mouse), Alt+Shift+Impr Pant (alto contraste) y Win+Ctrl+Enter (Narrador).'
        Favor = 'no te saca del juego en medio de una partida ni te cambia los colores de toda la pantalla.'
        Contra = 'si usas alguna de estas funciones por accesibilidad, la activas a mano desde Configuracion.'
        S = {
            Opt-Ini 'Atajos de accesibilidad'
            Reg-Set 'HKCU\Control Panel\Accessibility\StickyKeys' 'Flags' 'REG_SZ' '506'
            Reg-Set 'HKCU\Control Panel\Accessibility\Keyboard Response' 'Flags' 'REG_SZ' '122'
            Reg-Set 'HKCU\Control Panel\Accessibility\ToggleKeys' 'Flags' 'REG_SZ' '58'
            Reg-Set 'HKCU\Control Panel\Accessibility\MouseKeys' 'Flags' 'REG_SZ' '58'
            Reg-Set 'HKCU\Control Panel\Accessibility\HighContrast' 'Flags' 'REG_SZ' '122'
            Reg-Set 'HKCU\Software\Microsoft\Narrator\NoRoam' 'WinEnterLaunchEnabled' 'REG_DWORD' '0'
            Opt-Fin 'Atajos de accesibilidad desactivados'
        }
        R = {
            Opt-Ini 'Atajos de accesibilidad (restaurar)'
            Reg-Set 'HKCU\Control Panel\Accessibility\StickyKeys' 'Flags' 'REG_SZ' '510'
            Reg-Set 'HKCU\Control Panel\Accessibility\Keyboard Response' 'Flags' 'REG_SZ' '126'
            Reg-Set 'HKCU\Control Panel\Accessibility\ToggleKeys' 'Flags' 'REG_SZ' '62'
            Reg-Set 'HKCU\Control Panel\Accessibility\MouseKeys' 'Flags' 'REG_SZ' '62'
            Reg-Set 'HKCU\Control Panel\Accessibility\HighContrast' 'Flags' 'REG_SZ' '126'
            Reg-Set 'HKCU\Software\Microsoft\Narrator\NoRoam' 'WinEnterLaunchEnabled' 'REG_DWORD' '1'
            Opt-Fin 'Atajos de accesibilidad restaurados'
        }
    },
    @{
        Id = 'du'; Seccion = 'SONIDO'
        Q = '- Desea que Windows no baje el volumen en llamadas? (Sonido, Comunicaciones: No hacer nada)'
        Hace = 'Windows deja de bajar el volumen del juego cuando hay una llamada, por ejemplo en Discord.'
        Favor = 'el juego suena siempre igual.'
        Contra = 'ninguno.'
        S = {
            Opt-Ini 'Comunicaciones de Windows'
            Reg-Set 'HKCU\Software\Microsoft\Multimedia\Audio' 'UserDuckingPreference' 'REG_DWORD' '3'
            Opt-Fin 'Windows ya no reduce el volumen de los demas sonidos (si no lo notas, reinicia)'
        }
        R = {
            Opt-Ini 'Comunicaciones de Windows (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Multimedia\Audio' 'UserDuckingPreference' 'REG_DWORD' '1'
            Opt-Fin 'Windows vuelve a reducir un 80 por ciento el resto de los sonidos'
        }
    },
    @{
        Id = 'mm'; Seccion = 'CPU Y PRIORIDAD'
        Q = '- Desea dar prioridad multimedia a los juegos? (Mas CPU para el juego; efecto chico)'
        Hace = 'el programador multimedia de Windows le da mas prioridad a los juegos. El limite de red queda en 10, el valor de Windows, porque sacarlo puede empeorar la latencia.'
        Favor = 'un poco mas de CPU para el juego y menos tirones.'
        Contra = 'el efecto es chico.'
        S = {
            Opt-Ini 'Prioridad multimedia (MMCSS)'
            $g = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
            $sp = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Reg-Set $g 'GPU Priority' 'REG_DWORD' '8'
            Reg-Set $g 'Priority' 'REG_DWORD' '6'
            Reg-Set $g 'Scheduling Category' 'REG_SZ' 'High'
            Reg-Set $g 'SFIO Priority' 'REG_SZ' 'High'
            Reg-Set $sp 'NetworkThrottlingIndex' 'REG_DWORD' '10'
            Reg-Set $sp 'SystemResponsiveness' 'REG_DWORD' '10'
            Opt-Fin 'Prioridad multimedia para juegos aplicada'
        }
        R = {
            Opt-Ini 'Prioridad multimedia (restaurar)'
            $g = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
            $sp = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Reg-Set $g 'GPU Priority' 'REG_DWORD' '8'
            Reg-Set $g 'Priority' 'REG_DWORD' '2'
            Reg-Set $g 'Scheduling Category' 'REG_SZ' 'Medium'
            Reg-Set $g 'SFIO Priority' 'REG_SZ' 'Normal'
            Reg-Set $sp 'NetworkThrottlingIndex' 'REG_DWORD' '10'
            Reg-Set $sp 'SystemResponsiveness' 'REG_DWORD' '20'
            Opt-Fin 'Prioridad multimedia restaurada a los valores de Windows'
        }
    },
    @{
        Id = 'pri'; Seccion = 'CPU Y PRIORIDAD'
        Q = '- Desea dar prioridad alta a tus juegos? (Escribis sus procesos separados por comas; R se la quita a todos)'
        Hace = 'cada vez que abris esos juegos, Windows les da mas tiempo de CPU que a lo que corre de fondo.'
        Favor = 'menos tirones cuando tenes cosas abiertas atras, como Discord, el navegador u OBS.'
        Contra = 'si el CPU llega al 100 por ciento, lo de fondo puede trabarse un poco (por ejemplo, el stream de OBS).'
        S = {
            Opt-Ini 'Prioridad alta para juegos'
            Resps (Act 'PRIO_ON')
            Opt-Fin 'Prioridad alta aplicada (cerra y abri el juego para que la tome)'
        }
        R = {
            Opt-Ini 'Prioridad alta para juegos (restaurar)'
            Resps (Act 'PRIO_OFF')
            Opt-Fin 'Los juegos vuelven a la prioridad normal'
        }
    },
    @{
        Id = 'afi'; Seccion = 'CPU Y PRIORIDAD'
        Q = '- Desea usar afinidad de CPU para tus juegos? (Juegos en los mejores nucleos y programas de fondo aparte; se detecta tu procesador)'
        Hace = 'un programa chico en segundo plano pone tus juegos en los mejores nucleos y lleva Discord, Spotify y el navegador a otros.'
        Favor = 'lo de fondo no le roba nucleos al juego: frametimes mas parejos y menos tirones, sobre todo en Minecraft.'
        Contra = 'mientras jugas, lo de fondo anda un poco mas lento.'
        S = {
            Opt-Ini 'Afinidad de CPU para juegos'
            Resps (Act 'AFI_ON')
            Opt-Fin 'Afinidad activa (si el juego ya estaba abierto, se aplica en unos segundos)'
        }
        R = {
            Opt-Ini 'Afinidad de CPU (restaurar)'
            Resps (Act 'AFI_OFF')
            Opt-Fin 'Afinidad quitada: todo vuelve a usar todos los nucleos'
        }
    },
    @{
        Id = 'pw'; Seccion = 'PLAN DE ENERGIA'
        Q = '- Desea usar el plan Alto rendimiento? (Mas consumo y calor en notebook)'
        Hace = 'activa el plan de energia Alto rendimiento.'
        Favor = 'el CPU responde mas rapido y no baja tanto la frecuencia.'
        Contra = 'mas consumo y calor, sobre todo en notebook.'
        S = {
            Opt-Ini 'Plan de energia'
            $alto = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            if (Plan-Es $alto) { Ya-Estaba }
            else {
                & powercfg.exe -setactive $alto 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    & powercfg.exe -duplicatescheme $alto $alto 2>&1 | Out-Null
                    & powercfg.exe -setactive $alto 2>&1 | Out-Null
                }
                Res (Plan-Es $alto) ('plan de energia activo ' + $alto)
            }
            Opt-Fin 'Plan Alto rendimiento activo'
        }
        R = {
            Opt-Ini 'Plan de energia (restaurar)'
            $equi = '381b4222-f694-41f0-9685-ff5bb260df2e'
            if (Plan-Es $equi) { Ya-Estaba }
            else {
                & powercfg.exe -setactive $equi 2>&1 | Out-Null
                Res (Plan-Es $equi) ('plan de energia activo ' + $equi)
            }
            Opt-Fin 'Plan Equilibrado activo'
        }
    },
    @{
        Id = 'nb'; Seccion = 'PLAN DE ENERGIA'
        Q = '- Desea priorizar la bateria de la notebook? (Solo a bateria: turbo eficiente, ahorro de energia y ahorro de bateria al 30 por ciento)'
        Hace = 'solo con la notebook a bateria: el turbo se usa cuando hace falta, el procesador prioriza el ahorro de energia, baja la velocidad antes de prender los ventiladores y el ahorro de bateria de Windows se prende solo al 30 por ciento. Enchufada no cambia nada.'
        Favor = 'la bateria dura bastante mas y la notebook calienta y hace menos ruido fuera del cargador.'
        Contra = 'a bateria rinde un poco menos; para jugar, enchufala.'
        S = {
            Opt-Ini 'Bateria de la notebook'
            Resps (Act 'NB_ON')
            Opt-Fin 'Bateria priorizada: turbo eficiente, ahorro de energia y ahorro de bateria al 30 por ciento (solo a bateria)'
        }
        R = {
            Opt-Ini 'Bateria de la notebook (restaurar)'
            Resps (Act 'NB_OFF')
            Opt-Fin 'Bateria de la notebook: vuelven tus valores anteriores'
        }
    },
    @{
        Id = 'cpu'; Seccion = 'PROCESADOR'
        Q = '- Desea activar el Modo Nitro del procesador? (Nucleos siempre despiertos, turbo y rendimiento al maximo, solo con corriente)'
        Hace = 'deja todos los nucleos activos, el turbo al maximo y en modo agresivo, la subida de velocidad rapida y los ventiladores antes que bajar la velocidad, con la PC enchufada; ademas Windows deja de frenar los programas de fondo.'
        Favor = 'menos tirones cuando el juego pide mas CPU de golpe.'
        Contra = 'mas consumo, calor y ruido de ventiladores.'
        S = {
            Opt-Ini 'Modo Nitro del procesador'
            Resps (Act 'CPU_ON')
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 'REG_DWORD' '1'
            Opt-Fin 'Modo Nitro activo: nucleos 100, frecuencia 0 a 100, turbo 100 agresivo, subida rapida, ventiladores primero (con corriente) y sin limitar programas de fondo'
        }
        R = {
            Opt-Ini 'Modo Nitro del procesador (restaurar)'
            Resps (Act 'CPU_OFF')
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff'
            Opt-Fin 'Procesador restaurado a tus valores anteriores'
        }
    },
    @{
        Id = 'll'; Seccion = 'PROCESADOR'
        Q = '- Desea activar Baja latencia? (El CPU sube al maximo 1 a 3 segundos al abrir menus y apps; pide reiniciar)'
        Hace = 'activa Baja latencia (Low Latency Profile), una funcion oculta de Windows 11 que tambien se activa con ViVeTool y el ID 58989092: al abrir el Inicio, menus, la busqueda o apps, el procesador sube al maximo por 1 a 3 segundos.'
        Favor = 'el Inicio, los menus y las apps abren mas rapido, sobre todo en PCs de gama baja.'
        Contra = 'picos cortos de consumo y calor; Microsoft todavia la esta probando y en PCs potentes casi no se nota.'
        S = {
            Opt-Ini 'Baja latencia'
            Resps (Act 'LL_ON')
            Opt-Fin 'Baja latencia activada (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Baja latencia (restaurar)'
            Resps (Act 'LL_OFF')
            Opt-Fin 'Baja latencia vuelve a como la maneja Windows (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'gm'; Seccion = 'MODO JUEGO Y GAME BAR'
        Q = '- Desea activar el Modo Juego? (Y evitar que el joystick abra la Game Bar)'
        Hace = 'activa el Modo Juego y evita que el boton Xbox del joystick abra la Game Bar.'
        Favor = 'Windows prioriza el juego y frena actualizaciones mientras jugas.'
        Contra = 'ninguno importante.'
        S = {
            Opt-Ini 'Modo Juego'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'AllowAutoGameMode' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'GamepadNexusChordEnabled' 'REG_DWORD' '0'
            Opt-Fin 'Modo Juego activo y Game Bar sin atajo del joystick'
        }
        R = {
            Opt-Ini 'Modo Juego (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'AllowAutoGameMode' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\GameBar' 'GamepadNexusChordEnabled' 'REG_DWORD' '1'
            Opt-Fin 'Modo Juego y Game Bar restaurados'
        }
    },
    @{
        Id = 'xb'; Seccion = 'MODO JUEGO Y GAME BAR'
        Q = '- Desea borrar la app Xbox Game Bar? (No toca los servicios de Xbox que usan los juegos)'
        Hace = 'borra la app Xbox Game Bar y apaga sus grabaciones. En los Ryzen X3D de dos bloques (7900X3D, 7950X3D, 9900X3D, 9950X3D) solo apaga las grabaciones: ahi la app hace falta.'
        Favor = 'menos procesos y nada grabando de fondo.'
        Contra = 'perdes las capturas y clips de Windows; podes usar NVIDIA, AMD u OBS.'
        S = {
            Opt-Ini 'Xbox Game Bar'
            if ((Act 'GB_CHECK') -ge 10) {
                # Ryzen X3D de dos bloques: solo se apagan las grabaciones. Si una version anterior la habia bloqueado, se desbloquea.
                Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 'REG_DWORD' '0'
                Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled' 'REG_DWORD' '0'
                Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR'
                foreach ($p in $GameBarProtocolos) { Proto-Del $p }
                Opt-Fin 'Grabaciones de la Game Bar apagadas. La app no se borro: tu Ryzen X3D la usa para mandar los juegos al bloque con V-Cache'
                return
            }
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\System\GameConfigStore' 'GameDVR_Enabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 'REG_DWORD' '0'
            foreach ($p in $GameBarProtocolos) { Protocolo $p }
            Resps (Act 'GAMEBAR_OFF')
            Opt-Fin 'Xbox Game Bar borrada'
        }
        R = {
            Opt-Ini 'Xbox Game Bar (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\System\GameConfigStore' 'GameDVR_Enabled' 'REG_DWORD' '1'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR'
            foreach ($p in $GameBarProtocolos) { Proto-Del $p }
            Resps (Act 'GAMEBAR_ON')
            Opt-Fin 'Xbox Game Bar restaurada. Si no vuelve, instalala desde la Microsoft Store'
        }
    },
    @{
        Id = 'notif'; Seccion = 'MODO JUEGO Y GAME BAR'
        Q = '- Desea desactivar las notificaciones de Windows? (Apaga los avisos emergentes y el Centro de notificaciones)'
        Hace = 'apaga los avisos emergentes y el Centro de notificaciones.'
        Favor = 'nada te tapa la pantalla en partida.'
        Contra = 'no ves avisos de apps como Discord o el correo.'
        S = {
            Opt-Ini 'Notificaciones de Windows'
            Reg-Set 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled' 'REG_DWORD' '0'
            Opt-Fin 'Notificaciones desactivadas (se aplica al reiniciar el Explorador o la PC)'
        }
        R = {
            Opt-Ini 'Notificaciones de Windows (restaurar)'
            Reg-Del 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter'
            Reg-Del 'HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled'
            Opt-Fin 'Notificaciones restauradas (se aplica al reiniciar el Explorador o la PC)'
        }
    },
    @{
        Id = 'xm'; Seccion = 'MODO JUEGO Y GAME BAR'
        Q = '- Desea desactivar el Modo Xbox? (La pantalla completa tipo consola de Windows 11)'
        Hace = 'apaga el Modo Xbox de Windows 11 (la pantalla completa tipo consola con la app de Xbox).'
        Favor = 'no se abre ni te lo ofrece Windows si no lo usas. No cambia los FPS: es solo por comodidad.'
        Contra = 'para usar la PC como consola con el control, lo tenes que volver a prender.'
        S = {
            Opt-Ini 'Modo Xbox'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration' 'GamingHomeApp' 'REG_SZ' ''
            Opt-Fin 'Modo Xbox desactivado'
        }
        R = {
            Opt-Ini 'Modo Xbox (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\GamingConfiguration' 'GamingHomeApp' 'REG_SZ' 'Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App'
            Opt-Fin 'Modo Xbox restaurado'
        }
    },
    @{
        Id = 'gf'; Seccion = 'GRAFICOS'
        Q = '- Desea optimizar juegos en ventana y GPU por hardware? (Menos latencia; pide reiniciar)'
        Hace = 'usa el modo moderno para juegos en ventana y activa la GPU acelerada por hardware.'
        Favor = 'menos latencia en ventana y sin bordes, y hace falta para Frame Generation.'
        Contra = 'en algunas PCs viejas puede dar problemas; R lo vuelve atras.'
        S = {
            Opt-Ini 'Graficos'
            # "Optimizaciones para juegos en ventana" existe solo en Windows 11 (22000 o mas). En Windows 10 se aplica solo la GPU por hardware.
            if (-not (($Build -gt 0) -and ($Build -lt 22000))) { Resps (Act 'DX' 'SwapEffectUpgradeEnable=1;') }
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 'REG_DWORD' '2'
            Opt-Fin 'Juegos en ventana optimizados y GPU acelerada por hardware (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Graficos (restaurar)'
            Resps (Act 'DX' 'SwapEffectUpgradeEnable=DEL;')
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
            Opt-Fin 'Graficos restaurados (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'mpo'; Seccion = 'GRAFICOS'
        Q = '- Desea desactivar MPO? (Evita parpadeos y cursor invisible; pide reiniciar)'
        Hace = 'desactiva MPO, una funcion de la pantalla que superpone imagenes.'
        Favor = 'arregla parpadeos, pantallas negras y cursor invisible en algunas PCs.'
        Contra = 'si no tenias esos problemas, puede subir un poco el uso de la GPU en ventana.'
        S = {
            Opt-Ini 'MPO'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 'REG_DWORD' '5'
            Opt-Fin 'MPO desactivado (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'MPO (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode'
            Opt-Fin 'MPO restaurado (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'msi'; Seccion = 'GRAFICOS'
        Q = '- Desea activar el modo MSI en la placa de video y la de red? (Menos latencia; pide reiniciar)'
        Hace = 'las placas le avisan al procesador con mensajes (MSI) en vez de usar la linea compartida vieja.'
        Favor = 'un poco menos de latencia y de microtirones. Muchas placas nuevas ya vienen asi, en ese caso no cambia nada.'
        Contra = 'si el driver no lo soporta bien, al reiniciar podes ver pantalla negra o quedarte sin internet.'
        S = {
            Opt-Ini 'Modo MSI'
            Resps (Act 'MSI_ON')
            Opt-Fin 'Modo MSI activado (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Modo MSI (restaurar)'
            Resps (Act 'MSI_OFF')
            Opt-Fin 'Modo MSI vuelto a como estaba (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'pca'; Seccion = 'GRAFICOS'
        Q = '- Desea desactivar el Asistente de compatibilidad (PcaSvc)? (Evita ventanas que roban el foco en partida; pide reiniciar)'
        Hace = 'apaga el Asistente de compatibilidad de programas.'
        Favor = 'evita ventanas que te roban el foco en partida.'
        Contra = 'no te avisa de problemas con programas viejos.'
        S = {
            Opt-Ini 'Asistente de compatibilidad (PcaSvc)'
            Svc 'PcaSvc' 'disabled' '4'
            Svc-Parar 'PcaSvc'
            Opt-Fin 'Asistente de compatibilidad desactivado (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Asistente de compatibilidad (restaurar)'
            Svc 'PcaSvc' 'delayed-auto' '2'
            Svc-Arrancar 'PcaSvc'
            Opt-Fin 'Asistente de compatibilidad restaurado (inicio automatico retrasado)'
        }
    },
    @{
        Id = 'tr'; Seccion = 'TEMPORIZADOR Y LATENCIA'
        Q = '- Desea fijar el temporizador del sistema en el minimo? (Siempre 0.5 ms; menos latencia y tirones)'
        Hace = 'deja el temporizador de Windows fijo en 0.5 ms para todo el sistema.'
        Favor = 'menos latencia y tiempos de frame mas parejos.'
        Contra = 'mas consumo y calor, sobre todo en notebook.'
        Saltar = {
            # En Windows 10 (2004 o mas nuevo) cada programa tiene su propio temporizador: uno fijo para todo el sistema no llega a los juegos.
            if (($Build -gt 0) -and ($Build -lt 22000)) { Log 'SALTADO' ('Temporizador: el temporizador global fijo necesita Windows 11 - build ' + $Build); return $true }
            return $false
        }
        S = {
            Opt-Ini 'Temporizador al minimo'
            Resps (Act 'TIMER_ON')
            Opt-Fin 'Temporizador fijo en el minimo para todo el sistema (se aplica del todo al reiniciar)'
        }
        R = {
            Opt-Ini 'Temporizador (restaurar)'
            Resps (Act 'TIMER_OFF')
            Opt-Fin 'Temporizador restaurado al valor por defecto de Windows'
        }
    },
    @{
        Id = 'ram'; Seccion = 'LIMPIEZA DE RAM (STANDBY LIST)'
        Q = '- Desea activar la limpieza automatica de RAM en espera? (Vacia el cache al bajar de 1024 MB libres)'
        Hace = 'vacia la memoria en espera cuando quedan menos de 1024 MB libres.'
        Favor = 'evita tirones cuando la RAM se llena.'
        Contra = 'lo que estaba guardado en cache se vuelve a leer del disco.'
        S = {
            Opt-Ini 'Limpieza de RAM automatica'
            Resps (Act 'RAM_ON')
            Opt-Fin 'Limpiador de RAM activado'
        }
        R = {
            Opt-Ini 'Limpieza de RAM (restaurar)'
            Resps (Act 'RAM_OFF')
            Opt-Fin 'Limpiador de RAM desactivado'
        }
    },
    @{
        Id = 'sm'; Seccion = 'LIMPIEZA DE RAM (STANDBY LIST)'
        Q = '- Desea desactivar SysMain y Prefetch? (Deja la RAM libre; hace falta 16 GB y SSD)'
        Hace = 'apaga SysMain y Prefetch, que precargan programas en la RAM.'
        Favor = 'deja mas RAM libre para el juego.'
        Contra = 'algunos programas abren un poco mas lento la primera vez.'
        Saltar = {
            if (($RamGB -ge 16) -and (-not $EsHdd)) { return $false }
            Say ''
            Say '  SysMain/Prefetch se omite: hace falta 16 GB de RAM o mas y Windows en SSD o NVMe.'
            Log 'SALTADO' ('SysMain/Prefetch: RAM ' + $RamGB + ' GB, disco HDD=' + $(if ($EsHdd) { 1 } else { 0 }))
            return $true
        }
        S = {
            Opt-Ini 'SysMain y Prefetch'
            $pf = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
            Svc 'SysMain' 'disabled' '4'
            Reg-Set $pf 'EnablePrefetcher' 'REG_DWORD' '0'
            Reg-Set $pf 'EnableSuperfetch' 'REG_DWORD' '0'
            Svc-Parar 'SysMain'
            Opt-Fin 'SysMain y Prefetch desactivados'
        }
        R = {
            Opt-Ini 'SysMain y Prefetch (restaurar)'
            $pf = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
            Svc 'SysMain' 'auto' '2'
            Reg-Set $pf 'EnablePrefetcher' 'REG_DWORD' '3'
            Reg-Set $pf 'EnableSuperfetch' 'REG_DWORD' '3'
            Svc-Arrancar 'SysMain'
            Opt-Fin 'SysMain y Prefetch restaurados'
        }
    },
    @{
        Id = 'pe'; Seccion = 'ENERGIA Y RED'
        Q = '- Desea desactivar el ahorro de energia de USB, PCIe y discos? (Evita microcortes de mouse y teclado, y tirones de discos HDD)'
        Hace = 'apaga el ahorro de energia de USB, USB 3 y PCI Express, y con la PC enchufada los discos ya no se apagan solos.'
        Favor = 'evita microcortes del mouse y el teclado, y los tirones de unos segundos cuando un disco HDD se vuelve a encender.'
        Contra = 'en reposo la PC gasta unos vatios mas y la placa de video y los SSD NVMe pueden calentar un poco mas; en notebook la bateria dura menos (tambien con la tapa cerrada) y los discos HDD quedan girando mientras la PC esta prendida.'
        S = {
            Opt-Ini 'Ahorro de energia USB, PCIe y discos'
            Resps (Act 'PWR_OFF')
            Opt-Fin 'Ahorro de energia de USB, PCIe y discos desactivado'
        }
        R = {
            Opt-Ini 'Ahorro de energia USB, PCIe y discos (restaurar)'
            Resps (Act 'PWR_ON')
            Opt-Fin 'Ahorro de energia de USB, PCIe y discos restaurado'
        }
    },
    @{
        Id = 'nic'; Seccion = 'ENERGIA Y RED'
        Q = '- Desea desactivar el ahorro de energia de la red? (Menos picos de ping; no toca Wake-on-LAN; pide reiniciar)'
        Hace = 'apaga el ahorro de energia de la placa de red.'
        Favor = 'menos picos de ping.'
        Contra = 'un poco mas de consumo; en placas malas puede causar cortes, y R lo vuelve atras.'
        S = {
            Opt-Ini 'Ahorro de energia de la placa de red'
            Resps (Act 'NIC_OFF')
            Opt-Fin 'Ahorro de energia de la placa de red desactivado (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Ahorro de energia de la placa de red (restaurar)'
            Resps (Act 'NIC_ON')
            Opt-Fin 'Ahorro de energia de la placa de red restaurado (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'dup'; Seccion = 'ENERGIA Y RED'
        Q = '- Desea limitar el cable a 1 Gbps? (Para placas de cable de 2.5 Gbps o mas que se cortan solas; pide reiniciar)'
        Hace = 'pone la placa de cable en 1 Gbps fijo en vez de automatico (Speed & Duplex = 1.0 Gbps Full Duplex). Solo en placas de 2.5 Gbps o mas, como las Realtek 2.5GbE.'
        Favor = 'arregla los cortes de unos segundos en los que el cable se desconecta y se vuelve a conectar solo. Con internet de 1 Gbps o menos no perdes nada.'
        Contra = 'la placa no pasa de 1 Gbps: si tu internet es de mas de 1 Gbps, o pasas archivos entre PCs de tu casa, va mas lento; R lo vuelve atras.'
        S = {
            Opt-Ini 'Cable a 1 Gbps'
            Resps (Act 'DUP_ON')
            Opt-Fin 'Cable limitado a 1 Gbps (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Cable a 1 Gbps (restaurar)'
            Resps (Act 'DUP_R')
            Opt-Fin 'Velocidad del cable otra vez en automatico (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'wf'; Seccion = 'ENERGIA Y RED'
        Q = '- Desea usar WiFi y cable a la vez sin cortes? (Para PCs con WiFi y cable; el cable queda primero)'
        Hace = 'deja el WiFi y el cable conectados a la vez: Windows ya no corta el WiFi cuando enchufas el cable, el cable queda primero y el WiFi no se apaga por ahorro de energia.'
        Favor = 'el WiFi deja de desconectarse solo en las PCs que tienen WiFi y cable (como las placas madre con WiFi integrado).'
        Contra = 'un poco mas de consumo, porque las dos conexiones quedan prendidas.'
        S = {
            Opt-Ini 'WiFi y cable a la vez'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' 'fMinimizeConnections' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' 'fSoftDisconnectConnections' 'REG_DWORD' '0'
            Resps (Act 'WIFILAN_ON')
            Opt-Fin 'WiFi y cable a la vez activado'
        }
        R = {
            Opt-Ini 'WiFi y cable a la vez (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' 'fMinimizeConnections'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy' 'fSoftDisconnectConnections'
            Resps (Act 'WIFILAN_R')
            Opt-Fin 'WiFi y cable restaurados'
        }
    },
    @{
        Id = 'nag'; Seccion = 'ENERGIA Y RED'
        Q = '- Desea desactivar el algoritmo de Nagle? (Paquetes de red sin espera; menos ping en juegos que usan TCP; pide reiniciar)'
        Hace = 'apaga el algoritmo de Nagle en tus conexiones de red: Windows manda cada paquete chico al instante en vez de juntarlos y esperar.'
        Favor = 'puede bajar unos milisegundos el ping en juegos que usan TCP, como Minecraft o juegos de MMO y estrategia.'
        Contra = 'la mayoria de los shooters modernos usan UDP y no notan cambio; con conexiones lentas puede subir un poco el uso de red.'
        S = {
            Opt-Ini 'Algoritmo de Nagle'
            Resps (Act 'NAGLE_OFF')
            Opt-Fin 'Algoritmo de Nagle desactivado (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'Algoritmo de Nagle (restaurar)'
            Resps (Act 'NAGLE_ON')
            Opt-Fin 'Algoritmo de Nagle restaurado a como viene en Windows (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'dns'; Seccion = 'DNS'
        Q = '- Desea cambiar el DNS por el mas rapido para tu conexion? (R vuelve al DNS que tenias)'
        Hace = 'mide Cloudflare, Google, Quad9 y OpenDNS desde tu conexion y pone el mas rapido.'
        Favor = 'logins, matchmaking y paginas web cargan mas rapido.'
        Contra = 'no baja el ping dentro de la partida.'
        S = {
            Opt-Ini 'DNS mas rapido'
            Resps (Act 'DNS_ON')
            Opt-Fin 'DNS cambiado por el mas rapido (los tiempos de cada uno estan en el log)'
        }
        R = {
            Opt-Ini 'DNS (restaurar)'
            Resps (Act 'DNS_OFF')
            Opt-Fin 'DNS restaurado al que tenias antes'
        }
    },
    @{
        Id = 'mi'; Seccion = 'SEGURIDAD (MAS RENDIMIENTO)'
        Q = '- Desea desactivar la Integridad de memoria? (Mas rendimiento, menos proteccion contra drivers maliciosos)'
        Hace = 'apaga la Integridad de memoria de Windows.'
        Favor = 'mas FPS en algunos juegos.'
        Contra = 'menos proteccion contra drivers maliciosos.'
        S = {
            Opt-Ini 'Integridad de memoria'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 'REG_DWORD' '0'
            Opt-Fin 'Integridad de memoria desactivada (se aplica al reiniciar)'
            Vanguard-Check
        }
        R = {
            Opt-Ini 'Integridad de memoria (restaurar)'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 'REG_DWORD' '1'
            Opt-Fin 'Integridad de memoria restaurada (se aplica al reiniciar)'
        }
    },
    @{
        Id = 'avl'; Seccion = 'SEGURIDAD (MAS RENDIMIENTO)'
        Q = '- Desea que el antivirus use menos CPU? (Limita los analisis y sigue encendido)'
        Hace = 'limita los analisis de Defender al 5 por ciento de CPU, con prioridad baja.'
        Favor = 'los analisis no te bajan FPS.'
        Contra = 'los analisis tardan mas en terminar.'
        Saltar = {
            # Si no marcaste "Antivirus liviano" no se revisa el antivirus
            if ((Respuesta 'avl') -eq 'N') { return $true }
            if ((Act 'AV_STATUS') -ge 10) {
                Log 'OMITIDO' 'Antivirus liviano: el antivirus esta desactivado'
                Say '  Antivirus liviano se omite: el antivirus ya esta apagado.'
                return $true
            }
            return $false
        }
        S = {
            Opt-Ini 'Antivirus liviano'
            Resps (Act 'AV_LIGHT')
            Opt-Fin 'Antivirus con menor impacto en la CPU'
        }
        R = {
            Opt-Ini 'Antivirus liviano (restaurar)'
            Resps (Act 'AV_LIGHT_R')
            Opt-Fin 'Antivirus con su limite de CPU original'
        }
    },
    @{
        Id = 'vbs'; Seccion = 'SEGURIDAD (MAS RENDIMIENTO)'
        Q = '- Desea desactivar VBS? (5 a 10 por ciento mas en juegos; rompe Docker, WSL y Hyper-V)'
        Hace = 'apaga la seguridad basada en virtualizacion.'
        Favor = 'entre 5 y 10 por ciento mas de FPS.'
        Contra = 'deja de andar WSL, Docker, Hyper-V y las maquinas virtuales.'
        S = {
            Opt-Ini 'VBS'
            Say '  Revisando el estado de la virtualizacion, un momento...'
            Resps (Act 'VBS_FEATS_OFF')
            Bcd 'hypervisorlaunchtype' 'off'
            Bcd 'vsmlaunchtype' 'off'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' 'EnableVirtualizationBasedSecurity' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa' 'LsaCfgFlags' 'REG_DWORD' '0'
            Opt-Fin 'VBS desactivado (se aplica al reiniciar)'
            Vanguard-Check
        }
        R = {
            Opt-Ini 'VBS (restaurar)'
            Bcd-Del 'hypervisorlaunchtype'
            Bcd-Del 'vsmlaunchtype'
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' 'EnableVirtualizationBasedSecurity'
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa' 'LsaCfgFlags'
            Opt-Fin 'VBS restaurado. Hyper-V y WSL, si los usabas, hay que volver a activarlos a mano'
        }
    },
    @{
        Id = 'wsr'; Seccion = 'BUSQUEDA, ALMACENAMIENTO Y EXPLORADOR'
        Q = '- Desea desactivar Windows Search? (Sin indexado: libera disco y CPU, pero la busqueda del Inicio es mas lenta)'
        Hace = 'apaga el indexado de archivos.'
        Favor = 'libera disco y CPU.'
        Contra = 'la busqueda del Inicio es mas lenta.'
        S = {
            Opt-Ini 'Windows Search'
            Svc 'WSearch' 'disabled' '4'
            Svc-Parar 'WSearch'
            Opt-Fin 'Windows Search desactivado'
        }
        R = {
            Opt-Ini 'Windows Search (restaurar)'
            Svc 'WSearch' 'delayed-auto' '2'
            Svc-Arrancar 'WSearch'
            Opt-Fin 'Windows Search restaurado'
        }
    },
    @{
        Id = 'stg'; Seccion = 'BUSQUEDA, ALMACENAMIENTO Y EXPLORADOR'
        Q = '- Desea desactivar Storage Sense? (Windows deja de borrar archivos temporales por su cuenta)'
        Hace = 'Windows deja de borrar archivos temporales por su cuenta.'
        Favor = 'no borra nada solo mientras jugas.'
        Contra = 'la limpieza la haces vos, por ejemplo con Limpiar cache de la app.'
        S = {
            Opt-Ini 'Storage Sense'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense' 'AllowStorageSenseGlobal' 'REG_DWORD' '0'
            Opt-Fin 'Storage Sense desactivado'
        }
        R = {
            Opt-Ini 'Storage Sense (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense' 'AllowStorageSenseGlobal'
            Opt-Fin 'Storage Sense restaurado'
        }
    },
    @{
        Id = 'ext'; Seccion = 'BUSQUEDA, ALMACENAMIENTO Y EXPLORADOR'
        Q = '- Desea mostrar las extensiones de los archivos? (Ves .exe, .bat, .txt al final del nombre)'
        Hace = 'muestra el final del nombre de los archivos, como .exe o .txt.'
        Favor = 'ves que tipo de archivo es y detectas virus disfrazados.'
        Contra = 'ninguno.'
        S = {
            Opt-Ini 'Extensiones de archivo'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 'REG_DWORD' '0'
            Opt-Fin 'Extensiones de archivo visibles'
        }
        R = {
            Opt-Ini 'Extensiones de archivo (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 'REG_DWORD' '1'
            Opt-Fin 'Extensiones de archivo ocultas de nuevo'
        }
    },
    @{
        Id = 'md'; Seccion = 'AJUSTES EXTRA'
        Q = '- Desea quitar el retraso de los menus? (Baja de 400 a 0 ms la espera al abrir menus; todo se siente mas rapido)'
        Hace = 'baja de 400 a 0 ms la espera al abrir menus.'
        Favor = 'Windows se siente mas rapido.'
        Contra = 'ninguno.'
        S = {
            Opt-Ini 'Retraso de menus'
            Reg-Set 'HKCU\Control Panel\Desktop' 'MenuShowDelay' 'REG_SZ' '0'
            Opt-Fin 'Retraso de menus quitado (se aplica al volver a iniciar sesion)'
        }
        R = {
            Opt-Ini 'Retraso de menus (restaurar)'
            Reg-Set 'HKCU\Control Panel\Desktop' 'MenuShowDelay' 'REG_SZ' '400'
            Opt-Fin 'Retraso de menus restaurado'
        }
    },
    @{
        Id = 'v4'; Seccion = 'AJUSTES EXTRA'
        Q = '- Desea preferir IPv4 sobre IPv6? (Puede bajar la latencia en juegos; IPv6 sigue funcionando; pide reiniciar)'
        Hace = 'Windows usa IPv4 antes que IPv6 cuando hay las dos.'
        Favor = 'puede bajar la latencia con algunos servidores.'
        Contra = 'casi ninguno; IPv6 sigue funcionando.'
        S = {
            Opt-Ini 'IPv4 preferido'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' 'DisabledComponents' 'REG_DWORD' '32'
            Opt-Fin 'IPv4 preferido (se aplica al reiniciar)'
        }
        R = {
            Opt-Ini 'IPv4 preferido (restaurar)'
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' 'DisabledComponents'
            Opt-Fin 'IPv4 restaurado (se aplica al reiniciar)'
        }
    }
)

# Lo que llama la app (en otro hilo, con Comun.ps1 cargado). $salida = archivo donde la app lee el progreso.
function Correr-Gaming([string]$salida, [string]$carpeta) {
    Correr-Opciones -Nombre 'gaming' -Titulo 'OPTIMIZACION PARA GAMING' -Lista $ListaOpciones -Rein $ReinGaming -Salida $salida -Carpeta $carpeta
}
