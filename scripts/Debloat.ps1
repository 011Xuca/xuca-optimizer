param([string]$Consola = '')
# ============================================================
#  DEBLOAT Y PRIVACIDAD (antes era windows_debloat.bat)
#  Lo corre la app XucaOP.ps1 en un hilo aparte, con Comun.ps1 cargado: ya no se abre cmd
#  ni un powershell.exe nuevo por cada opcion.
#  Las herramientas que te piden datos (actualizar Windows, borrar una cuenta, entrar sin contrasena)
#  la app las abre en una ventana de PowerShell a la vista: Debloat.ps1 -Consola herr
#  S = Si, N = No, R = Restaurar. R deja la opcion en el valor por defecto de Windows, no en lo que tenias antes.
#  Cada cambio se verifica y queda anotado en la carpeta "logs".
# ============================================================

# Opciones que necesitan reiniciar para aplicarse. Solo se pide reiniciar si alguna de estas cambio algo de verdad.
$ReinDebloat = @('av', 'rc', 'ad', 'sv', 'pv', 'ms_acc', 'al', 'cta')

# Tareas de telemetria (opcion "Reducir la telemetria")
$TareasTelemetria = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Microsoft\Windows\Application Experience\MareBackup',
    '\Microsoft\Windows\Application Experience\StartupAppTask',
    '\Microsoft\Windows\Maps\MapsUpdateTask',
    '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'
)

# Sugerencias y apps que Windows instala solo (opcion "Quitar anuncios")
$ClavesAnuncios = @(
    'SystemPaneSuggestionsEnabled', 'SoftLandingEnabled', 'RotatingLockScreenOverlayEnabled',
    'SilentInstalledAppsEnabled', 'PreInstalledAppsEnabled', 'OemPreInstalledAppsEnabled',
    'PreInstalledAppsEverEnabled', 'SubscribedContentEnabled', 'ContentDeliveryAllowed',
    'SubscribedContent-310093Enabled', 'SubscribedContent-338387Enabled', 'SubscribedContent-338388Enabled',
    'SubscribedContent-338389Enabled', 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled',
    'SubscribedContent-353696Enabled', 'SubscribedContent-353698Enabled'
)

# Servidores de telemetria que se bloquean en el archivo hosts
$HostsTelemetria = @(
    'vortex.data.microsoft.com', 'vortex-win.data.microsoft.com', 'v10.vortex-win.data.microsoft.com',
    'us.vortex-win.data.microsoft.com', 'eu.vortex-win.data.microsoft.com', 'v10.events.data.microsoft.com',
    'v20.events.data.microsoft.com', 'self.events.data.microsoft.com', 'umwatson.events.data.microsoft.com',
    'watson.events.data.microsoft.com', 'telecommand.telemetry.microsoft.com',
    'telecommand.telemetry.microsoft.com.nsatc.net', 'oca.telemetry.microsoft.com',
    'oca.telemetry.microsoft.com.nsatc.net', 'sqm.telemetry.microsoft.com',
    'sqm.telemetry.microsoft.com.nsatc.net', 'watson.telemetry.microsoft.com',
    'watson.telemetry.microsoft.com.nsatc.net', 'watson.ppe.telemetry.microsoft.com',
    'df.telemetry.microsoft.com', 'reports.wes.df.telemetry.microsoft.com', 'wes.df.telemetry.microsoft.com',
    'services.wes.df.telemetry.microsoft.com', 'sqm.df.telemetry.microsoft.com', 'telemetry.microsoft.com',
    'telemetry.urs.microsoft.com', 'telemetry.appex.bing.net', 'redir.metaservices.microsoft.com',
    'choice.microsoft.com', 'choice.microsoft.com.nsatc.net', 'settings-sandbox.data.microsoft.com',
    'vortex-sandbox.data.microsoft.com', 'survey.watson.microsoft.com', 'watson.live.com',
    'watson.microsoft.com', 'statsfe2.ws.microsoft.com', 'corpext.msitadfs.glbdns2.microsoft.com',
    'compatexchange.cloudapp.net'
)

function Hosts-Tiene([string]$h) {
    try { return ([IO.File]::ReadAllText($h, [Text.Encoding]::Default)).Contains('# xuca-telemetria') } catch { return $false }
}

# Politicas del antivirus, SmartScreen y Smart App Control
function Av-RegsOff {
    $def = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender'
    Reg-Set $def 'DisableAntiSpyware' 'REG_DWORD' '1'
    Reg-Set $def 'PUAProtection' 'REG_DWORD' '0'
    foreach ($n in 'DisableRealtimeMonitoring', 'DisableBehaviorMonitoring', 'DisableOnAccessProtection', 'DisableScanOnRealtimeEnable', 'DisableIOAVProtection') { Reg-Set ($def + '\Real-Time Protection') $n 'REG_DWORD' '1' }
    Reg-Set ($def + '\Spynet') 'SpynetReporting' 'REG_DWORD' '0'
    Reg-Set ($def + '\Spynet') 'SubmitSamplesConsent' 'REG_DWORD' '2'
    Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications' 'DisableNotifications' 'REG_DWORD' '1'
    Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen' 'REG_DWORD' '0'
    Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'REG_SZ' 'Off'
    Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost' 'EnableWebContentEvaluation' 'REG_DWORD' '0'
    Reg-Set 'HKCU\Software\Microsoft\Edge' 'SmartScreenEnabled' 'REG_DWORD' '0'
    Reg-Set 'HKCU\Software\Microsoft\Edge' 'SmartScreenPuaEnabled' 'REG_DWORD' '0'
    foreach ($n in 'ServiceEnabled', 'NotifyMalicious', 'NotifyPasswordReuse', 'NotifyUnsafeApp') { Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' $n 'REG_DWORD' '0' }
    Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy' 'VerifiedAndReputablePolicyState' 'REG_DWORD' '0'
    Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealth'
    Reg-Del 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealth'
}

function Av-RegsOn {
    $def = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender'
    Reg-Del $def 'DisableAntiSpyware'
    Reg-Del $def 'PUAProtection'
    foreach ($n in 'DisableRealtimeMonitoring', 'DisableBehaviorMonitoring', 'DisableOnAccessProtection', 'DisableScanOnRealtimeEnable', 'DisableIOAVProtection') { Reg-Del ($def + '\Real-Time Protection') $n }
    Reg-Del ($def + '\Spynet') 'SpynetReporting'
    Reg-Del ($def + '\Spynet') 'SubmitSamplesConsent'
    Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications' 'DisableNotifications'
    Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen'
    Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled' 'REG_SZ' 'Warn'
    Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost' 'EnableWebContentEvaluation' 'REG_DWORD' '1'
    Reg-Set 'HKCU\Software\Microsoft\Edge' 'SmartScreenEnabled' 'REG_DWORD' '1'
    Reg-Set 'HKCU\Software\Microsoft\Edge' 'SmartScreenPuaEnabled' 'REG_DWORD' '1'
    foreach ($n in 'ServiceEnabled', 'NotifyMalicious', 'NotifyPasswordReuse', 'NotifyUnsafeApp') { Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components' $n }
    # El icono de Seguridad de Windows en la bandeja (va como REG_EXPAND_SZ, igual que lo deja Windows)
    $run = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    if (-not (Reg-Leer $run 'SecurityHealth')) {
        $k = $null
        try { $k = Reg-Abrir $run 'crear'; $k.SetValue('SecurityHealth', '%windir%\system32\SecurityHealthSystray.exe', [Microsoft.Win32.RegistryValueKind]::ExpandString) } catch { } finally { if ($k) { $k.Dispose() } }
        Res ([bool](Reg-Leer $run 'SecurityHealth')) 'icono de Seguridad de Windows en la bandeja restaurado'
    }
    Log 'INFO' 'Smart App Control no se reactiva por script'
}

# LogonUser: para saber si tu cuenta entra con la contrasena vacia (Entrar sin contrasena)
function Cargar-Lg {
    if ('XucaWin.Lg' -as [type]) { return }
Add-Type -Namespace XucaWin -Name Lg -MemberDefinition @'
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string pass, int type, int provider, out IntPtr token);
[DllImport("kernel32.dll")]
public static extern bool CloseHandle(IntPtr handle);
'@
}

function Extraer-Bin($texto, $clave, $destino, $sha) {
    try {
        $sb = New-Object System.Text.StringBuilder
        foreach ($m in [regex]::Matches($texto, '(?m)^::EDGEBIN:' + $clave + ':([A-Za-z0-9+/=]+)')) { [void]$sb.Append($m.Groups[1].Value) }
        if ($sb.Length -eq 0) { return $false }
        $gz = [Convert]::FromBase64String($sb.ToString())
        $ent = New-Object System.IO.MemoryStream(, $gz)
        $zip = New-Object System.IO.Compression.GZipStream($ent, [System.IO.Compression.CompressionMode]::Decompress)
        $sal = [System.IO.File]::Create($destino)
        try { $zip.CopyTo($sal) } finally { $sal.Close(); $zip.Close(); $ent.Close() }
        $h = (Get-FileHash -LiteralPath $destino -Algorithm SHA256).Hash.ToLower()
        if ($h -ne $sha) { Remove-Item -LiteralPath $destino -Force -ErrorAction SilentlyContinue; return $false }
        return $true
    } catch { return $false }
}

# Los nombres aceptan comodines (por ejemplo *LinkedIn*, porque el nombre del paquete cambia segun la version).
# Lo que Windows marca como parte del sistema (NonRemovable) no se toca: borrarlo a la fuerza rompe el menu Inicio.
function Quitar-Apps($lista) {
    $instaladas = @(Get-AppxPackage -AllUsers)
    $prov = @(Get-AppxProvisionedPackage -Online)
    $ok = 0; $mal = 0; $nada = 0
    foreach ($n in $lista) {
        $pk = @($instaladas | Where-Object { $_.Name -like $n })
        $pv = @($prov | Where-Object { $_.DisplayName -like $n })
        $fijas = @($pk | Where-Object { $_.NonRemovable })
        if ($fijas.Count -gt 0) {
            Log 'OMITIDO' ($n + ' es parte de Windows: Windows no deja borrarla')
            $pk = @($pk | Where-Object { -not $_.NonRemovable })
        }
        if ($pk.Count -eq 0 -and $pv.Count -eq 0) { $nada++; if ($fijas.Count -eq 0) { Log 'OMITIDO' ($n + ' no estaba instalada') }; continue }
        foreach ($p in $pk) { 
            try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop | Out-Null } 
            catch { try { Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop | Out-Null } catch { } } 
        }
        foreach ($p in $pv) { try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null } catch { } }
        $quedan = @(Get-AppxPackage -AllUsers -Name $n | Where-Object { -not $_.NonRemovable }).Count
        if ($quedan -eq 0) { 
            $ok++; Log 'OK' ('quitada ' + $n) 
        } else { 
            $quedanLocal = @(Get-AppxPackage -Name $n | Where-Object { -not $_.NonRemovable }).Count
            if ($quedanLocal -eq 0) {
                $ok++; Log 'OK' ('quitada ' + $n + ' para el usuario actual')
            } else {
                $mal++; Log 'FALLO' ('no se pudo quitar ' + $n); $global:XMal = $true 
            }
        }
    }
    $global:tocadas = $ok + $mal
    if ($global:tocadas -eq 0) { Say '  Esas apps ya no estaban instaladas.' 'Yellow' }
    else { Say ('  Apps quitadas: {0} - con error: {1} - ya no estaban: {2}' -f $ok, $mal, $nada) }
}

function Test-AvOn {
    $s = Get-MpComputerStatus
    $m = Get-MpPreference
    return (($s.RealTimeProtectionEnabled -eq $true) -and ($s.BehaviorMonitorEnabled -eq $true) -and ($s.IoavProtectionEnabled -eq $true) -and ($s.OnAccessProtectionEnabled -eq $true) -and ($m.MAPSReporting -ne 0))
}

function Test-Blank($u) {
    $tok = [IntPtr]::Zero
    $r = [XucaWin.Lg]::LogonUser($u, '.', '', 2, 0, [ref]$tok)
    $global:lgErr = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($r) { [void][XucaWin.Lg]::CloseHandle($tok); return $true }
    if ($global:lgErr -eq 1327) {
        $tok2 = [IntPtr]::Zero
        $r2 = [XucaWin.Lg]::LogonUser($u, '.', ('x' + [guid]::NewGuid().ToString('N')), 2, 0, [ref]$tok2)
        $e2 = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($r2) { [void][XucaWin.Lg]::CloseHandle($tok2) }
        if ((-not $r2) -and ($e2 -eq 1326)) { return $true }
    }
    return $false
}

function Quitar-Contrasena($name) {
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $s = Read-Host '  Contrasena actual de tu cuenta (Enter si no tiene)' -AsSecureString
    $old = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
    & net user $name /passwordreq:no | Out-Null
    if ($LASTEXITCODE -eq 0) { Log 'OK' 'la cuenta queda habilitada para no tener contrasena' }
    else { Log 'FALLO' 'net user /passwordreq:no'; $global:XMal = $true }
    if ($old) {
        try {
            $u = [ADSI]('WinNT://' + $env:COMPUTERNAME + '/' + $name + ',user')
            $u.Invoke('ChangePassword', $old, '')
            Log 'OK' 'contrasena quitada (cambio con la contrasena actual, no se pierden datos guardados)'
        } catch {
            Log 'FALLO' ('no se pudo quitar la contrasena: ' + $_.Exception.Message)
            $global:XMal = $true
        }
    }
    $old = $null
    if (Test-Blank $name) {
        if ($global:lgErr -eq 1327) { Log 'OK' 'verificado: la contrasena esta vacia (Windows solo deja probarla en la consola, error 1327 esperado)' }
        else { Log 'OK' 'verificado: la cuenta entra con contrasena vacia' }
    } else {
        Log 'FALLO' ('la cuenta todavia tiene contrasena (error ' + $global:lgErr + ')')
        Say '  La cuenta todavia tiene contrasena: corre la opcion de nuevo y escribi la actual.' 'Red'
        $global:XMal = $true
    }
    $du = (Get-ItemProperty -Path $k).DefaultUserName
    if ($du -and ([string]$du) -like '*@*') {
        Remove-ItemProperty -Path $k -Name 'DefaultUserName' -ErrorAction SilentlyContinue
        Log 'OK' 'se quito un usuario con email que habia quedado del inicio automatico viejo'
    }
    $otras = @(Get-LocalUser | Where-Object { $_.Enabled -and $_.Name -ne $name -and $_.SID.Value -notmatch '-(500|501|503|504)$' })
    if ($otras.Count -gt 0) {
        Say ''
        Say '  Otras cuentas en esta PC:'
        foreach ($c in $otras) { Say ('   - ' + $c.Name + '  [' + $c.PrincipalSource + ']') }
        Log 'INFO' ('otras cuentas: ' + (($otras | ForEach-Object { $_.Name }) -join ', '))
        $del = ([string](Read-Host '  Si alguna sobra, escribi su nombre para borrarla (Enter = no borrar nada)')).Trim()
        if ($del) {
            $t = $otras | Where-Object { $_.Name -eq $del } | Select-Object -First 1
            if (-not $t) {
                Say '  Ese nombre no coincide con ninguna cuenta, no se borro nada.' 'Yellow'
                Log 'INFO' 'el nombre escrito no coincide con ninguna cuenta'
            } else {
                $conf = Read-Host ('  Escribi SI para borrar la cuenta ' + $t.Name + ' (su carpeta de usuario no se borra)')
                if ($conf -ceq 'SI') {
                    try { Remove-LocalUser -Name $t.Name -ErrorAction Stop } catch { Log 'FALLO' ('Remove-LocalUser: ' + $_.Exception.Message); $global:XMal = $true }
                    if (-not (Get-LocalUser -Name $t.Name -ErrorAction SilentlyContinue)) { Log 'OK' ('cuenta borrada: ' + $t.Name) }
                    else { Log 'FALLO' ('la cuenta ' + $t.Name + ' sigue existiendo'); $global:XMal = $true }
                } else { Log 'INFO' 'borrado de cuenta cancelado' }
            }
        }
    }
}

# >>> XUCA-INICIO (la app XucaOP copia todo lo que esta entre estas dos marcas para saber si quedan apps de inicio basura)
# Programas que se abren solos al prender la PC. Se apagan igual que desde el Administrador de tareas (StartupApproved),
# asi se pueden volver a prender desde ahi, desde Configuracion o con R.
# Nunca se apaga lo que esta en la carpeta de Windows (seguridad y drivers) ni lo que coincide con esta lista:
# drivers y paneles de hardware, perifericos, RGB, Wallpaper Engine, antivirus, VPN, antitrampas y gestores de contrasenas.
$InicioDejar = @(
    'SecurityHealth', 'Windows Defender', 'ctfmon', 'Xuca',
    'Realtek', 'RtkAud', 'RtHDVCpl', 'Nahimic', 'Waves', 'MaxxAudio', 'Dolby', 'DTS', 'Sonic Studio', 'Sound Blaster', 'SBCommand',
    'NVIDIA', 'AMD', 'Radeon', 'Intel', 'igfx',
    'Synaptics', 'ELAN', 'ETD', 'Alps', 'Wacom', 'XP-Pen', 'Huion', 'Tobii',
    'Logitech', 'LGHUB', 'LogiOptions', 'Razer', 'Corsair', 'iCUE', 'SteelSeries', 'Sonar', 'HyperX', 'NGENUITY', 'Wooting', 'Glorious',
    'ROCCAT', 'Turtle Beach', 'Cooler Master', 'MasterPlus', 'Redragon', 'Keychron', 'Fantech', 'Attack Shark', 'VGN', 'Pulsar', 'Lamzu', 'Endgame Gear', 'Zowie',
    'ASUS', 'Armoury', 'ROG', 'MSI', 'Dragon Center', 'Mystic Light', 'Gigabyte', 'AORUS', 'RGB Fusion', 'ASRock', 'Polychrome', 'SignalRGB', 'OpenRGB',
    'Lenovo', 'Legion', 'Vantage', 'Dell', 'Alienware', 'HP', 'OMEN', 'Acer', 'Predator', 'NitroSense',
    'Bluetooth', 'Thunderbolt', 'Hotkey', 'Afterburner', 'RivaTuner', 'RTSS', 'FanControl',
    'Wallpaper Engine', 'wallpaper32', 'wallpaper64', 'Lively',
    'VoiceMeeter', 'Elgato', 'Stream Deck', 'GoXLR', 'Focusrite', 'Wave Link',
    'Vanguard', 'vgtray', 'FACEIT', 'EasyAntiCheat', 'BattlEye',
    'Malwarebytes', 'Bitdefender', 'Kaspersky', 'ESET', 'Avast', 'AVG', 'Norton', 'McAfee', 'Avira', 'Sophos', 'Webroot',
    'NordVPN', 'ProtonVPN', 'Mullvad', 'WireGuard', 'OpenVPN', 'ExpressVPN', 'Surfshark', 'Cloudflare WARP', 'Tailscale',
    'Bitwarden', '1Password', 'KeePass', 'Dashlane', 'PowerToys', 'AutoHotkey'
)
$InicioArchivo = Join-Path $env:ProgramData 'XucaScripts\inicio_apagado.txt'

# 'HKCU:\...' o 'HKLM:\...' -> clave del registro (se crea si falta y $crear)
function Inicio-Clave([string]$p, [bool]$crear) {
    $raiz = $(if ($p -like 'HKCU:*') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine })
    $sub = $p -replace '^HK(CU|LM):\\', ''
    if ($crear) { return $raiz.CreateSubKey($sub) }
    return $raiz.OpenSubKey($sub)
}
function Inicio-Leer([string]$p, [string]$n) {
    $k = Inicio-Clave $p $false
    if (-not $k) { return $null }
    # La coma evita que PowerShell desarme el byte[] de StartupApproved (sin ella llegaba como object[] y todo parecia prendido)
    try { $v = $k.GetValue($n); if ($v -is [array]) { return , $v } else { return $v } } finally { $k.Close() }
}

# Todo lo que arranca solo, con Activo (si hoy arranca) y Dejar (si es de lo que nunca se apaga)
function Inicio-Lista {
    $rx = '(?i)(?<![a-z0-9])(' + (($InicioDejar | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
    $aprob = 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\'
    $r = @()
    foreach ($f in @(
        @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', ('HKCU:\' + $aprob + 'Run')),
        @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', ('HKLM:\' + $aprob + 'Run')),
        @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', ('HKLM:\' + $aprob + 'Run32')))) {
        $k = Inicio-Clave $f[0] $false
        if (-not $k) { continue }
        foreach ($n in @($k.GetValueNames())) {
            if (-not $n) { continue }
            $cmd = [string]$k.GetValue($n)
            if ([string]::IsNullOrWhiteSpace($cmd)) { continue }   # vacia: no arranca nada (el Administrador de tareas no la muestra)
            $r += [pscustomobject]@{ Tipo = 'reg'; Nombre = $n; Texto = ($n + ' ' + $cmd); Ruta = $cmd; Aprob = $f[1]; Clave = $n; Activo = $true; Dejar = $false }
        }
        $k.Close()
    }
    # Carpetas de Inicio (la tuya y la de todos los usuarios)
    foreach ($f in @(
        @([Environment]::GetFolderPath('Startup'), ('HKCU:\' + $aprob + 'StartupFolder')),
        @([Environment]::GetFolderPath('CommonStartup'), ('HKLM:\' + $aprob + 'StartupFolder')))) {
        if ((-not $f[0]) -or (-not (Test-Path -LiteralPath $f[0]))) { continue }
        foreach ($a in @(Get-ChildItem -LiteralPath $f[0] -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })) {
            $dest = ''
            if ($a.Extension -eq '.lnk') { try { $dest = [string](New-Object -ComObject WScript.Shell).CreateShortcut($a.FullName).TargetPath } catch { } }
            $r += [pscustomobject]@{ Tipo = 'reg'; Nombre = $a.BaseName; Texto = ($a.Name + ' ' + $dest); Ruta = $dest; Aprob = $f[1]; Clave = $a.Name; Activo = $true; Dejar = $false }
        }
    }
    # Si arranca o no lo dice StartupApproved: el primer byte par = prendido (o si no hay nada), impar = apagado
    # El Administrador de tareas a veces guarda el apagado de una entrada de HKLM en HKCU (o en Run32): se miran todos
    # los lugares y, si alguno dice apagado, cuenta como apagada.
    foreach ($e in $r) {
        $lugares = @($e.Aprob)
        if ($e.Aprob -match 'StartupApproved\\Run(32)?$') {
            foreach ($h in 'HKCU:\', 'HKLM:\') { foreach ($k in 'Run', 'Run32') { $lugares += ($h + $aprob + $k) } }
        }
        $prendida = $null
        foreach ($l in @($lugares | Select-Object -Unique)) {
            $b = Inicio-Leer $l $e.Clave
            if (($b -is [byte[]]) -and ($b.Length -gt 0)) {
                if (($b[0] -band 1) -ne 0) { $prendida = $false; break }
                $prendida = $true
            }
        }
        if ($null -ne $prendida) { $e.Activo = $prendida }
    }
    # Apps de la Store que arrancan solas (Spotify, Teams, WhatsApp...): State 2 = prendida, 1 = apagada por vos
    $base = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData'
    $kb = Inicio-Clave $base $false
    # Paquetes instalados: los restos de apps ya borradas quedan en SystemAppData pero no arrancan ni se ven en el Administrador de tareas
    $fams = Inicio-Clave 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Families' $false
    if ($kb) {
        foreach ($pk in @($kb.GetSubKeyNames())) {
            if ($fams) {
                $kf = $fams.OpenSubKey($pk)
                if (-not $kf) { continue }
                $hay = ($kf.SubKeyCount -gt 0); $kf.Close()
                if (-not $hay) { continue }
            }
            $kp = $kb.OpenSubKey($pk)
            if (-not $kp) { continue }
            foreach ($t in @($kp.GetSubKeyNames())) {
                $kt = $kp.OpenSubKey($t)
                if (-not $kt) { continue }
                $st = $kt.GetValue('State'); $kt.Close()
                if ($st -isnot [int]) { continue }
                $r += [pscustomobject]@{ Tipo = 'store'; Nombre = ($pk -replace '_[a-z0-9]+$', ''); Texto = ($pk + ' ' + $t); Ruta = ''; Aprob = ($base + '\' + $pk + '\' + $t); Clave = 'State'; Activo = ($st -eq 2); Dejar = $false }
            }
            $kp.Close()
        }
        $kb.Close()
    }
    if ($fams) { $fams.Close() }
    $win = [string]$env:SystemRoot
    foreach ($e in $r) {
        $e.Dejar = ($e.Texto -match $rx) -or ($win -and ($e.Ruta -like ('*' + $win + '\*')))
    }
    return $r
}

# Las que se apagan con la opcion (las que hoy arrancan y no son de la lista para dejar)
function Inicio-Basura { return @(Inicio-Lista | Where-Object { $_.Activo -and -not $_.Dejar }) }

# Prende o apaga una. Devuelve $true si quedo como se pidio.
function Inicio-Poner($e, [bool]$prender) {
    try {
        if ($e.Tipo -eq 'store') {
            $k = Inicio-Clave $e.Aprob $false
            if (-not $k) { return $prender }
            $k.Close()
            $k = Inicio-Clave $e.Aprob $true
            $k.SetValue('State', $(if ($prender) { 2 } else { 1 }), [Microsoft.Win32.RegistryValueKind]::DWord); $k.Close()
            return ((Inicio-Leer $e.Aprob 'State') -eq $(if ($prender) { 2 } else { 1 }))
        }
        $b = New-Object byte[] 12
        if ($prender) { $b[0] = 2 } else { $b[0] = 3; [BitConverter]::GetBytes([DateTime]::UtcNow.ToFileTimeUtc()).CopyTo($b, 4) }
        $k = Inicio-Clave $e.Aprob $true
        $k.SetValue($e.Clave, $b, [Microsoft.Win32.RegistryValueKind]::Binary); $k.Close()
        $v = Inicio-Leer $e.Aprob $e.Clave
        return (($v -is [byte[]]) -and ($v[0] -eq $b[0]))
    } catch { return $false }
}
# <<< XUCA-INICIO

# ------------------------------------------------------------
# Las acciones (antes cada una abria su propio PowerShell desde el .bat). Devuelven un codigo:
# 0 = hecho, 1 = fallo, 2 = no aplica, 3 = instalador lanzado, 4 = cancelado, 5 = ya estaba, 6 = queda un paso para despues.
# $XDato: los valores para SPI (efectos visuales). $XChk: AV_OFF solo revisa si ya estaba todo apagado.
# ------------------------------------------------------------
function Debloat-Act([string]$XAct, [string]$XDato, [bool]$XChk) {
    $code = 0
    # Quitar-Apps y Quitar-Contrasena anotan sus errores aca (antes tocaban el codigo de todo el script)
    $global:XMal = $false
    . {
    switch ($XAct) {

    'RP_CHECK' {
        $pol = 0
        $reg = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -ErrorAction SilentlyContinue
        if ($reg -and $reg.DisableSR -eq 1) { $pol = 1 }
        
        # Solo se saltea si una politica prohibe los puntos de restauracion.
        # Si la Proteccion del sistema esta apagada, RP_CREATE la enciende sola.
        if ($pol -eq 1) { $code = 5 }
    }

    'RP_OFF' {
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        $pol = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -ErrorAction SilentlyContinue).DisableSR
        $rp = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).RPSessionInterval
        $hay = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue).Count
        if (($pol -eq 1) -and ($rp -eq 0) -and ($hay -eq 0)) {
            Log 'OK' 'ya estaba: puntos de restauracion apagados y sin copias guardadas'
            $code = 5
        } else {
            try { Disable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop } catch { Log 'INFO' ('Disable-ComputerRestore: ' + $_.Exception.Message) }
            & vssadmin.exe delete shadows /for=$env:SystemDrive /all /quiet | Out-Null
            Start-Sleep -Seconds 1
            $rp2 = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).RPSessionInterval
            $hay2 = @(Get-ComputerRestorePoint -ErrorAction SilentlyContinue).Count
            if (($rp2 -eq 0) -or ($null -eq $rp2)) { Log 'OK' 'verificado: proteccion del sistema apagada' } else { Log 'FALLO' 'la proteccion del sistema sigue encendida'; $code = 1 }
            if ($hay2 -eq 0) { Log 'OK' ('verificado: se borraron los puntos de restauracion (habia ' + $hay + ')') } else { Log 'FALLO' ('quedan ' + $hay2 + ' puntos de restauracion'); $code = 1 }
        }
    }

    'RP_ON' {
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        if ((Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).RPSessionInterval -eq 1) {
            Log 'OK' 'ya estaba: proteccion del sistema encendida'
            $code = 5
        } else {
            try { Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop } catch { Log 'FALLO' ('Enable-ComputerRestore: ' + $_.Exception.Message); $code = 1 }
            if ((Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).RPSessionInterval -eq 1) { Log 'OK' ('verificado: proteccion del sistema encendida en ' + $env:SystemDrive) }
            else { Log 'FALLO' 'la proteccion del sistema no quedo encendida'; $code = 1 }
        }
    }

    'RP_CREATE' {
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        $desc = 'Antes de optimizar (script)'
        $pol = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore').DisableSR
        $hoy = $null
        try {
            $hoy = Get-ComputerRestorePoint | Where-Object { $_.Description -eq $desc } | ForEach-Object { [Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime) } | Where-Object { $_ -gt (Get-Date).AddHours(-24) } | Select-Object -First 1
        } catch { }
        if ($pol -eq 1) {
            Log 'OMITIDO' 'los puntos de restauracion estan apagados por politica (los apago este script)'
            Say '  Los puntos de restauracion estan apagados. Para usarlos, elegi R en "apagar los puntos de restauracion".' 'Yellow'
            $code = 2
        } elseif ($hoy) {
            Log 'OK' ('ya habia un punto de restauracion de las ultimas 24 horas (' + $hoy + ')')
            Say '  Ya habia un punto de restauracion de las ultimas 24 horas.' 'Yellow'
            $code = 5
        } else {
            try {
                Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop
                Set-ItemProperty -Path $k -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type DWord -ErrorAction Stop
                Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
            } catch {
                Log 'FALLO' ('no se pudo crear el punto de restauracion: ' + $_.Exception.Message)
                $code = 1
            }
            Remove-ItemProperty -Path $k -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue
            if ($code -eq 0) {
                $rp = @(Get-ComputerRestorePoint | Where-Object { $_.Description -eq $desc })
                if ($rp.Count -gt 0) { Log 'OK' 'punto de restauracion creado y verificado' }
                else { Log 'FALLO' 'el punto de restauracion no aparece en la lista'; $code = 1 }
            }
        }
    }

    'HIB_OFF' {
        $hibProp = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction SilentlyContinue
        $hibOn = ($null -eq $hibProp) -or ($hibProp.HibernateEnabled -ne 0)
        
        if (-not $hibOn) {
            Log 'OK' 'ya estaba: sin hibernacion'
            $code = 5
        } else {
            & powercfg /hibernate off
            if ($LASTEXITCODE -eq 0) { Log 'OK' 'powercfg /hibernate off' } else { Log 'FALLO' 'powercfg /hibernate off'; $code = 1 }
            try { Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue } catch { }
        }
    }

    'HIB_ON' {
        $hibOn = [IO.File]::Exists($env:SystemDrive + '\hiberfil.sys')
        $mm = [bool](Get-MMAgent).MemoryCompression
        if ($hibOn -and $mm) {
            Log 'OK' 'ya estaba: con hibernacion y con compresion de memoria'
            $code = 5
        } else {
            if (-not $hibOn) {
                & powercfg /hibernate on
                if ($LASTEXITCODE -eq 0) { Log 'OK' 'powercfg /hibernate on' } else { Log 'FALLO' 'powercfg /hibernate on'; $code = 1 }
                if ([IO.File]::Exists($env:SystemDrive + '\hiberfil.sys')) { Log 'OK' 'verificado: hiberfil.sys existe' }
                else { Log 'FALLO' 'no aparecio hiberfil.sys'; $code = 1 }
            } else {
                Log 'OK' 'ya estaba: la hibernacion estaba activada'
            }
            if (-not $mm) {
                try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch { Log 'FALLO' ('Enable-MMAgent: ' + $_.Exception.Message); $code = 1 }
                if ((Get-MMAgent).MemoryCompression) { Log 'OK' 'verificado: compresion de memoria activada (estaba apagada)' }
                else { Log 'FALLO' 'la compresion de memoria no quedo activa'; $code = 1 }
            } else {
                Log 'OK' 'ya estaba: la compresion de memoria estaba activa'
            }
        }
    }

    'AV_OFF' {
        if (Test-AvOff) {
            Log 'OK' 'ya estaba todo apagado'
            $code = 5
        } elseif (-not $XChk) {
            $ops = @(
                @{ N = 'proteccion en tiempo real'; S = { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop } },
                @{ N = 'monitoreo de comportamiento'; S = { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction Stop } },
                @{ N = 'analisis de descargas'; S = { Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop } },
                @{ N = 'analisis de scripts'; S = { Set-MpPreference -DisableScriptScanning $true -ErrorAction Stop } },
                @{ N = 'bloqueo al primer vistazo'; S = { Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction Stop } },
                @{ N = 'proteccion en la nube'; S = { Set-MpPreference -MAPSReporting 0 -ErrorAction Stop } },
                @{ N = 'envio automatico de muestras'; S = { Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction Stop } },
                @{ N = 'proteccion de red'; S = { Set-MpPreference -EnableNetworkProtection Disabled -ErrorAction Stop } },
                @{ N = 'acceso controlado a carpetas'; S = { Set-MpPreference -EnableControlledFolderAccess Disabled -ErrorAction Stop } },
                @{ N = 'bloqueo de apps no deseadas'; S = { Set-MpPreference -PUAProtection Disabled -ErrorAction Stop } }
            )
            foreach ($o in $ops) {
                try { & $o.S } catch { Log 'FALLO' ($o.N + ': ' + $_.Exception.Message); $code = 1 }
            }
            Start-Sleep -Seconds 2
            $s = Get-MpComputerStatus
            $m = Get-MpPreference
            $vf = @(
                @{ N = 'proteccion en tiempo real'; V = ($s.RealTimeProtectionEnabled -eq $false) },
                @{ N = 'monitoreo de comportamiento'; V = ($s.BehaviorMonitorEnabled -eq $false) },
                @{ N = 'analisis de descargas'; V = ($s.IoavProtectionEnabled -eq $false) },
                @{ N = 'proteccion de acceso'; V = ($s.OnAccessProtectionEnabled -eq $false) },
                @{ N = 'proteccion en la nube'; V = ($m.MAPSReporting -eq 0) },
                @{ N = 'proteccion de red'; V = ($m.EnableNetworkProtection -eq 0) },
                @{ N = 'acceso controlado a carpetas'; V = ($m.EnableControlledFolderAccess -eq 0) },
                @{ N = 'bloqueo de apps no deseadas'; V = ($m.PUAProtection -eq 0) }
            )
            foreach ($c in $vf) {
                if ($c.V) { Log 'OK' ('verificado: ' + $c.N + ' apagada') }
                else { Log 'FALLO' ($c.N + ' sigue encendida (probablemente por la Proteccion contra alteraciones)'); $code = 1 }
            }
        }
    }

    'AV_ON' {
        if (Test-AvOn) {
            Log 'OK' 'ya estaba todo encendido'
            $code = 5
        } else {
            $ops = @(
                @{ N = 'proteccion en tiempo real'; S = { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop } },
                @{ N = 'monitoreo de comportamiento'; S = { Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction Stop } },
                @{ N = 'analisis de descargas'; S = { Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop } },
                @{ N = 'analisis de scripts'; S = { Set-MpPreference -DisableScriptScanning $false -ErrorAction Stop } },
                @{ N = 'bloqueo al primer vistazo'; S = { Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction Stop } },
                @{ N = 'proteccion en la nube'; S = { Set-MpPreference -MAPSReporting 2 -ErrorAction Stop } },
                @{ N = 'envio automatico de muestras'; S = { Set-MpPreference -SubmitSamplesConsent 1 -ErrorAction Stop } },
                @{ N = 'bloqueo de apps no deseadas'; S = { Set-MpPreference -PUAProtection Enabled -ErrorAction Stop } }
            )
            foreach ($o in $ops) {
                try { & $o.S } catch { Log 'FALLO' ($o.N + ': ' + $_.Exception.Message); $code = 1 }
            }
            Start-Service -Name WinDefend -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $s = Get-MpComputerStatus
            $vf = @(
                @{ N = 'proteccion en tiempo real'; V = ($s.RealTimeProtectionEnabled -eq $true) },
                @{ N = 'monitoreo de comportamiento'; V = ($s.BehaviorMonitorEnabled -eq $true) },
                @{ N = 'analisis de descargas'; V = ($s.IoavProtectionEnabled -eq $true) },
                @{ N = 'proteccion de acceso'; V = ($s.OnAccessProtectionEnabled -eq $true) }
            )
            foreach ($c in $vf) {
                if ($c.V) { Log 'OK' ('verificado: ' + $c.N + ' encendida') }
                else { Log 'FALLO' ($c.N + ' no se encendio'); $code = 1 }
            }
        }
    }

    'BL_OFF' {
        # Rapido: se pregunta directo a Windows (WMI) si algun disco esta cifrado. Cargar el modulo de BitLocker
        # tarda varios segundos y casi siempre no hace falta (BitLocker ya apagado).
        $cifrados = -1
        try {
            $ev = @(Get-CimInstance -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -ErrorAction Stop)
            $cifrados = @($ev | Where-Object { [int](Invoke-CimMethod -InputObject $_ -MethodName GetConversionStatus -ErrorAction Stop).ConversionStatus -ne 0 }).Count
        } catch { $cifrados = -1 }
        if ($cifrados -eq 0) {
            Log 'OK' 'BitLocker ya estaba desactivado en todos los discos'
            $code = 5
        }
        elseif (-not (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
            Log 'OMITIDO' 'BitLocker no esta disponible en esta edicion de Windows'
            Say '  BitLocker no esta disponible en esta edicion de Windows.' 'Yellow'
            $code = 2
        } else {
            $vols = @(Get-BitLockerVolume | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' })
            if ($vols.Count -eq 0) {
                Log 'OK' 'BitLocker ya estaba desactivado en todos los discos'
                $code = 5
            }
            # Error 0x80310029: C: no se puede descifrar mientras haya discos de datos con desbloqueo automatico.
            # Por eso se quita primero el desbloqueo automatico y se procesan los discos de datos antes que C:.
            if ($vols.Count -gt 0) {
                try { Clear-BitLockerAutoUnlock -ErrorAction Stop | Out-Null; Log 'OK' 'desbloqueo automatico de los discos de datos quitado' }
                catch { Log 'INFO' ('desbloqueo automatico: ' + $_.Exception.Message) }
            }
            $vols = @($vols | Sort-Object { if ($_.VolumeType -eq 'OperatingSystem') { 1 } else { 0 } })
            foreach ($v in $vols) {
                if ($v.VolumeStatus -eq 'DecryptionInProgress') { Log 'OK' ('verificado: ' + $v.MountPoint + ' ya se estaba descifrando'); continue }
                $hecho = $false
                for ($i = 0; ($i -lt 2) -and (-not $hecho); $i++) {
                    try { Disable-BitLocker -MountPoint $v.MountPoint -ErrorAction Stop | Out-Null; $hecho = $true }
                    catch {
                        if (($i -eq 0) -and ($_.Exception.Message -match '80310029')) {
                            foreach ($d in @(Get-BitLockerVolume | Where-Object { $_.VolumeType -ne 'OperatingSystem' })) {
                                try { Disable-BitLockerAutoUnlock -MountPoint $d.MountPoint -ErrorAction Stop | Out-Null } catch { }
                            }
                            continue
                        }
                        Log 'FALLO' ('Disable-BitLocker ' + $v.MountPoint + ': ' + $_.Exception.Message); $code = 1; break
                    }
                }
                if (-not $hecho) { continue }
                $est = (Get-BitLockerVolume -MountPoint $v.MountPoint).VolumeStatus
                if ($est -in 'DecryptionInProgress', 'FullyDecrypted') { Log 'OK' ('verificado: ' + $v.MountPoint + ' en estado ' + $est) }
                else { Log 'FALLO' ('el disco ' + $v.MountPoint + ' quedo en estado ' + $est); $code = 1 }
            }
        }
    }

    'LOCALPW_OFF' {
        Cargar-Lg
        $name = $env:USERNAME
        $ro = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        $lu = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
        if (-not $lu) {
            Log 'FALLO' ('no se encontro la cuenta local ' + $name)
            $code = 1
        } else {
            $src = [string]$lu.PrincipalSource
            Log 'INFO' ('la cuenta ' + $name + ' es de tipo ' + $src)
            if (($src -eq 'Local') -and (Test-Blank $name)) {
                Log 'OK' 'ya estaba: la cuenta local entra con contrasena vacia'
                Say '  Tu cuenta ya entra sin contrasena, no hace falta tocar nada.' 'Yellow'
                $code = 5
            } elseif ($src -eq 'Local') {
                Quitar-Contrasena $name
            } elseif ($src -eq 'MicrosoftAccount') {
                $linea = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $script:XCarpeta 'Debloat.ps1') + '" -Consola cta'
                if (-not (Test-Path $ro)) { New-Item -Path $ro -Force | Out-Null }
                Set-ItemProperty -Path $ro -Name 'XucaCuenta' -Value $linea
                if ((Get-ItemProperty -Path $ro).XucaCuenta -eq $linea) { Log 'OK' 'programado: se reabre solo cuando vuelvas a entrar' }
                else { Log 'FALLO' 'no se pudo programar la reapertura'; $code = 1 }
                Say ''
                Say '  Tu cuenta esta vinculada a una cuenta de Microsoft y esa no puede entrar sin'
                Say '  contrasena. Hay que pasarla a cuenta local. Se abre Configuracion > Tu informacion:'
                Say '  toca "Iniciar sesion con una cuenta local en su lugar", segui los pasos y en la'
                Say '  contrasena nueva dejala en blanco.'
                Say '  Windows cierra la sesion al terminar. Cuando vuelvas a entrar, esto se abre solo.' 'Yellow'
                Start-Process 'ms-settings:yourinfo'
                $cancelo = $false
                for ($i = 1; ($i -le 3) -and ($src -eq 'MicrosoftAccount') -and (-not $cancelo); $i++) {
                    $r = Read-Host '  Enter cuando termines (o escribi CANCELAR para dejarlo)'
                    if ($r -ceq 'CANCELAR') { $cancelo = $true; break }
                    $lu = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
                    $src = [string]$lu.PrincipalSource
                }
                if ($cancelo) {
                    Remove-ItemProperty -Path $ro -Name 'XucaCuenta' -ErrorAction SilentlyContinue
                    Log 'INFO' 'el usuario cancelo el pase a cuenta local'
                    Say '  Cancelado: tu cuenta queda como estaba.' 'Yellow'
                    $code = 2
                } elseif ($src -eq 'Local') {
                    Remove-ItemProperty -Path $ro -Name 'XucaCuenta' -ErrorAction SilentlyContinue
                    Quitar-Contrasena $name
                } else {
                    Log 'INFO' 'la cuenta sigue siendo de Microsoft: queda pendiente para cuando vuelvas a entrar'
                    $code = 6
                }
            } else {
                Log 'FALLO' ('el tipo de cuenta ' + $src + ' no se puede pasar a sin contrasena con este script')
                $code = 1
            }
        }
    }

    'LOCALPW_FIN' {
        Cargar-Lg
        $name = $env:USERNAME
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'XucaCuenta' -ErrorAction SilentlyContinue
        $lu = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
        if (-not $lu) {
            Log 'FALLO' ('no se encontro la cuenta local ' + $name)
            $code = 1
        } else {
            $src = [string]$lu.PrincipalSource
            Log 'INFO' ('la cuenta ' + $name + ' es de tipo ' + $src)
            if ($src -eq 'MicrosoftAccount') {
                Log 'OMITIDO' 'la cuenta sigue siendo de Microsoft'
                Say '  Tu cuenta sigue siendo de Microsoft: en la app, Herramientas, volve a usar "Entrar sin contrasena".' 'Yellow'
                $code = 2
            } elseif (($src -eq 'Local') -and (Test-Blank $name)) {
                Log 'OK' 'ya estaba: la cuenta local entra con contrasena vacia'
                Say '  Tu cuenta ya entra sin contrasena.' 'Yellow'
                $code = 5
            } elseif ($src -eq 'Local') {
                Quitar-Contrasena $name
            } else {
                Log 'FALLO' ('el tipo de cuenta ' + $src + ' no se puede pasar a sin contrasena con este script')
                $code = 1
            }
        }
    }

    'MS_ACC_REMOVE' {
        $proteger = @([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
        try {
            $cu = [string](Get-CimInstance Win32_ComputerSystem).UserName
            if ($cu) { $proteger += ([Security.Principal.NTAccount]$cu).Translate([Security.Principal.SecurityIdentifier]).Value }
        } catch { }
        $miMail = ''
        foreach ($s in $proteger) {
            $ic = Get-ItemProperty -Path ('HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache\' + $s + '\IdentityCache\' + $s)
            if ($ic -and $ic.UserName) { $miMail = [string]$ic.UserName }
        }
        $crl = @('HKCU:\Software\Microsoft\IdentityCRL\StoredIdentities', 'HKCU:\Software\Microsoft\IdentityCRL\UserExtendedProperties')
        $tbk = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\TokenBroker\Accounts', 'HKCU:\Software\Microsoft\TokenBroker\Accounts')
        $tbf = @(($env:LOCALAPPDATA + '\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts'), ($env:LOCALAPPDATA + '\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\AC\TokenBroker\Accounts'))
        $rx = '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'

        function Get-Mails {
            $m = @()
            foreach ($rk in $crl) { if (Test-Path $rk) { $m += @(Get-ChildItem $rk | ForEach-Object { $_.PSChildName }) } }
            foreach ($rk in $tbk) {
                foreach ($k in @(Get-ChildItem $rk)) {
                    $pr = Get-ItemProperty -LiteralPath $k.PSPath
                    foreach ($v in $pr.PSObject.Properties) { if (($v.Value -is [string]) -and ($v.Value -match ('^' + $rx + '$'))) { $m += $v.Value } }
                }
            }
            foreach ($fd in $tbf) {
                foreach ($f in @(Get-ChildItem -LiteralPath $fd -File)) {
                    $b = [IO.File]::ReadAllBytes($f.FullName)
                    foreach ($txt in @([Text.Encoding]::Unicode.GetString($b), [Text.Encoding]::UTF8.GetString($b))) {
                        foreach ($mm in [regex]::Matches($txt, $rx)) { $m += $mm.Value }
                    }
                }
            }
            return @($m | Where-Object { $_ -and ($_ -like '*@*') -and ($_ -ne $miMail) } | Sort-Object -Unique)
        }

        function Borrar-Mail($mail) {
            Stop-Process -Name 'Microsoft.AAD.BrokerPlugin' -Force
            foreach ($rk in $crl) { Remove-Item -LiteralPath ($rk + '\' + $mail) -Recurse -Force }
            foreach ($rk in $tbk) {
                foreach ($k in @(Get-ChildItem $rk)) {
                    $pr = Get-ItemProperty -LiteralPath $k.PSPath
                    $esta = $false
                    foreach ($v in $pr.PSObject.Properties) { if (($v.Value -is [string]) -and ($v.Value -eq $mail)) { $esta = $true } }
                    if ($esta) { Remove-Item -LiteralPath $k.PSPath -Recurse -Force }
                }
            }
            foreach ($fd in $tbf) {
                foreach ($f in @(Get-ChildItem -LiteralPath $fd -File)) {
                    $b = [IO.File]::ReadAllBytes($f.FullName)
                    $hit = ([Text.Encoding]::Unicode.GetString($b).IndexOf($mail, [StringComparison]::OrdinalIgnoreCase) -ge 0) -or ([Text.Encoding]::UTF8.GetString($b).IndexOf($mail, [StringComparison]::OrdinalIgnoreCase) -ge 0)
                    if ($hit) { Remove-Item -LiteralPath $f.FullName -Force }
                }
            }
        }

        function Borrar-Perfil($sid) {
            $p = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid } | Select-Object -First 1
            if (-not $p) { return $true }
            $lp = [string]$p.LocalPath
            try { Remove-CimInstance -InputObject $p -ErrorAction Stop } catch { Log 'FALLO' ('no se pudo borrar el perfil: ' + $_.Exception.Message) }
            $quedaReg = [bool](Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid })
            $quedaDir = ($lp -and (Test-Path -LiteralPath $lp))
            return (-not ($quedaReg -or $quedaDir))
        }

        $hecho = 0
        $fallo = 0
        $vistas = 0
        $ocultar = @()
        $seguir = $true
        while ($seguir) {
            $items = @()
            $locales = @(Get-LocalUser | ForEach-Object { $_.SID.Value })
            foreach ($u in @(Get-LocalUser | Where-Object { ($_.SID.Value -notmatch '-(500|501|503|504)$') -and ($proteger -notcontains $_.SID.Value) -and ($ocultar -notcontains $_.SID.Value) })) {
                $items += [pscustomobject]@{ T = 'USER'; N = [string]$u.Name; S = $u.SID.Value; I = ('cuenta de Windows [' + $u.PrincipalSource + ']') }
            }
            foreach ($p in @(Get-CimInstance Win32_UserProfile | Where-Object { (-not $_.Special) -and (-not $_.Loaded) -and ($proteger -notcontains $_.SID) -and ($locales -notcontains $_.SID) -and ($ocultar -notcontains $_.SID) })) {
                $items += [pscustomobject]@{ T = 'PERFIL'; N = (Split-Path -Leaf ([string]$p.LocalPath)); S = [string]$p.SID; I = 'carpeta de usuario que quedo sin cuenta' }
            }
            foreach ($m in @(Get-Mails)) {
                if ($ocultar -notcontains $m) { $items += [pscustomobject]@{ T = 'MAIL'; N = [string]$m; S = ''; I = 'cuenta de Microsoft vinculada a Configuracion y apps' } }
            }

            if ($items.Count -eq 0) {
                if ($vistas -eq 0) { Say '  No hay otras cuentas para borrar en esta PC.' 'Yellow'; Log 'OK' 'ya estaba: no hay otras cuentas para borrar' }
                $seguir = $false
            } else {
                $vistas++
                Say ''
                Say '  Cuentas que se pueden borrar (tu cuenta actual no aparece; si ves tu propio correo, no lo elijas):'
                for ($i = 0; $i -lt $items.Count; $i++) { Say ('   ' + ($i + 1) + ') ' + $items[$i].N + '  -  ' + $items[$i].I) }
                $n = ([string](Read-Host '  Escribi el numero de la cuenta a borrar (Enter = terminar)')).Trim()
                if (-not $n) {
                    $seguir = $false
                } elseif (($n -notmatch '^\d+$') -or ([int]$n -lt 1) -or ([int]$n -gt $items.Count)) {
                    Say '  Numero invalido.' 'Yellow'
                } else {
                    $it = $items[[int]$n - 1]
                    $c = Read-Host ('  Escribi SI para borrar ' + $it.N + ' (cualquier otra cosa cancela)')
                    if ($c -cne 'SI') {
                        Log 'INFO' ('borrado cancelado: ' + $it.N)
                        $ocultar += $(if ($it.T -eq 'MAIL') { $it.N } else { $it.S })
                    } elseif ($it.T -eq 'USER') {
                        $conArch = Read-Host '  Borrar tambien su carpeta de usuario con todos sus archivos? Escribi SI (Enter = conservarla)'
                        $err = ''
                        try { Remove-LocalUser -SID ([Security.Principal.SecurityIdentifier]$it.S) -ErrorAction Stop } catch { $err = $_.Exception.Message }
                        if (Get-LocalUser | Where-Object { $_.SID.Value -eq $it.S }) { & net user $it.N /delete 2>&1 | Out-Null }
                        if (Get-LocalUser | Where-Object { $_.SID.Value -eq $it.S }) {
                            Log 'FALLO' ('la cuenta ' + $it.N + ' sigue existiendo. ' + $err)
                            Say ('  No se pudo borrar ' + $it.N + '. Reinicia la PC y proba de nuevo (puede tener la sesion abierta).') 'Red'
                            $fallo++
                            $ocultar += $it.S
                        } else {
                            Log 'OK' ('verificado: cuenta borrada ' + $it.N)
                            Say ('  Cuenta borrada: ' + $it.N) 'Green'
                            $hecho++
                            if ($conArch -ceq 'SI') {
                                if (Borrar-Perfil $it.S) { Log 'OK' ('verificado: carpeta de usuario borrada de ' + $it.N) }
                                else { Log 'FALLO' ('la carpeta de usuario de ' + $it.N + ' no se pudo borrar'); Say '  La carpeta de usuario no se pudo borrar del todo (reinicia y proba de nuevo).' 'Red'; $fallo++ }
                            } else { $ocultar += $it.S }
                        }
                    } elseif ($it.T -eq 'PERFIL') {
                        if (Borrar-Perfil $it.S) { Log 'OK' ('verificado: perfil borrado ' + $it.N); Say ('  Perfil borrado: ' + $it.N) 'Green'; $hecho++ }
                        else { Log 'FALLO' ('el perfil ' + $it.N + ' sigue existiendo'); Say '  No se pudo borrar. Reinicia la PC y proba de nuevo.' 'Red'; $fallo++; $ocultar += $it.S }
                    } else {
                        Borrar-Mail $it.N
                        if (@(Get-Mails) -contains $it.N) {
                            Log 'INFO' ('la cuenta ' + $it.N + ' sigue en el sistema tras el borrado puntual')
                            Say '  No se pudo sacar solo esa cuenta. Se puede limpiar TODO el cache de cuentas de Microsoft de este usuario:' 'Yellow'
                            Say '  se cierra la sesion en apps como Teams u Office y la tuya se vuelve a pedir una vez.' 'Yellow'
                            $t = Read-Host '  Escribi SI para limpiar todo el cache de cuentas (Enter = no)'
                            if ($t -ceq 'SI') {
                                Stop-Process -Name 'Microsoft.AAD.BrokerPlugin' -Force
                                foreach ($fd in $tbf) { Get-ChildItem -LiteralPath $fd -File | Remove-Item -Force }
                                foreach ($rk in $tbk) { Get-ChildItem $rk | Remove-Item -Recurse -Force }
                                foreach ($rk in $crl) { Get-ChildItem $rk | Where-Object { $_.PSChildName -ne $miMail } | Remove-Item -Recurse -Force }
                                Get-ChildItem -LiteralPath ($env:LOCALAPPDATA + '\Microsoft\TokenBroker\Cache') -File | Remove-Item -Force
                            }
                        }
                        if (@(Get-Mails) -contains $it.N) {
                            Log 'FALLO' ('la cuenta de Microsoft ' + $it.N + ' sigue vinculada')
                            Say '  Sigue vinculada. Reinicia la PC y corre esta opcion de nuevo.' 'Red'
                            $fallo++
                            $ocultar += $it.N
                        } else {
                            Log 'OK' ('verificado: cuenta de Microsoft desvinculada ' + $it.N)
                            Say ('  Cuenta de Microsoft quitada: ' + $it.N) 'Green'
                            $hecho++
                        }
                    }
                }
            }
        }
        if ($fallo -gt 0) { $code = 1 }
        elseif ($hecho -gt 0) { $code = 0 }
        elseif ($vistas -eq 0) { $code = 5 }
        else { $code = 2 }
    }

    'RECALL_OFF' {
        $feats = Get-FeatMap
        if (-not $feats.ContainsKey('Recall')) {
            Log 'OMITIDO' 'la caracteristica Recall no existe en esta PC (no es Copilot+)'
            $code = 2
        } elseif ([string]$feats['Recall'] -like 'Disable*') {
            Log 'OK' 'ya estaba: Recall desactivado'
            $code = 5
        } else {
            try { Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart -ErrorAction Stop | Out-Null; Log 'OK' 'caracteristica Recall desactivada' }
            catch { Log 'FALLO' ('Recall: ' + $_.Exception.Message); $code = 1 }
        }
    }

    'RECALL_ON' {
        $feats = Get-FeatMap
        if (-not $feats.ContainsKey('Recall')) {
            Log 'OMITIDO' 'la caracteristica Recall no existe en esta PC (no es Copilot+)'
            $code = 2
        } elseif ([string]$feats['Recall'] -like 'Enable*') {
            Log 'OK' 'ya estaba: Recall activado'
            $code = 5
        } else {
            try { Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart -ErrorAction Stop | Out-Null; Log 'OK' 'caracteristica Recall activada' }
            catch { Log 'FALLO' ('Recall: ' + $_.Exception.Message); $code = 1 }
        }
    }

    'SND_OFF' {
        $raiz = 'HKCU:\AppEvents\Schemes'
        $dejar = @('DeviceConnect', 'DeviceDisconnect')
        $eventos = @(Get-ChildItem -LiteralPath ($raiz + '\Apps') -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq '.Current' })
        $quitar = @($eventos | Where-Object { ($dejar -notcontains (($_.PSPath -split '\\')[-2])) -and (([string]$_.GetValue('')) -ne '') })
        $poner = @()
        foreach ($k in $eventos) {
            if (($dejar -contains (($k.PSPath -split '\\')[-2])) -and (([string]$k.GetValue('')) -eq '')) {
                $def = Get-Item -LiteralPath ($k.PSPath -replace '\\\.Current$', '\.Default') -ErrorAction SilentlyContinue
                if ($def -and (([string]$def.GetValue('')) -ne '')) {
                    $poner += [pscustomobject]@{ Clave = $k; Valor = [string]$def.GetValue('', '', 'DoNotExpandEnvironmentNames') }
                }
            }
        }
        $esquema = [string](Get-Item -LiteralPath $raiz).GetValue('')
        if ($eventos.Count -eq 0) {
            Log 'OMITIDO' 'no se encontraron eventos de sonido en el registro'
            $code = 2
        } elseif ($quitar.Count -eq 0 -and $poner.Count -eq 0 -and $esquema -eq '.None') {
            Log 'OK' 'ya estaban silenciados todos los sonidos menos conectar y desconectar dispositivos'
            $code = 5
        } else {
            foreach ($k in $quitar) { Set-ItemProperty -LiteralPath $k.PSPath -Name '(default)' -Value '' -ErrorAction SilentlyContinue }
            foreach ($c in $poner) { Set-ItemProperty -LiteralPath $c.Clave.PSPath -Name '(default)' -Value $c.Valor -Type ExpandString -ErrorAction SilentlyContinue }
            Set-ItemProperty -LiteralPath $raiz -Name '(default)' -Value '.None' -ErrorAction SilentlyContinue
            $quedan = @(Get-ChildItem -LiteralPath ($raiz + '\Apps') -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq '.Current' -and ($dejar -notcontains (($_.PSPath -split '\\')[-2])) -and (([string]$_.GetValue('')) -ne '') })
            $faltan = 0
            foreach ($c in $poner) {
                $ahora = Get-Item -LiteralPath $c.Clave.PSPath -ErrorAction SilentlyContinue
                if (-not $ahora -or (([string]$ahora.GetValue('')) -eq '')) { $faltan++ }
            }
            $esquema2 = [string](Get-Item -LiteralPath $raiz).GetValue('')
            if ($quedan.Count -eq 0 -and $faltan -eq 0 -and $esquema2 -eq '.None') {
                Log 'OK' ('verificado: ' + $quitar.Count + ' sonidos silenciados, quedan solo conectar y desconectar dispositivos')
            } else {
                Log 'FALLO' ('quedan ' + $quedan.Count + ' sonidos activos de mas y ' + $faltan + ' de dispositivos sin sonido, o la combinacion no cambio')
                $code = 1
            }
        }
    }

    'SND_ON' {
        $raiz = 'HKCU:\AppEvents\Schemes'
        $eventos = @(Get-ChildItem -LiteralPath ($raiz + '\Apps') -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq '.Current' })
        $esquema = [string](Get-Item -LiteralPath $raiz).GetValue('')
        $cambiar = @()
        foreach ($k in $eventos) {
            $def = Get-Item -LiteralPath ($k.PSPath -replace '\\\.Current$', '\.Default') -ErrorAction SilentlyContinue
            $val = ''
            if ($def) { $val = [string]$def.GetValue('', '', 'DoNotExpandEnvironmentNames') }
            $act = [string]$k.GetValue('', '', 'DoNotExpandEnvironmentNames')
            if ($act -ne $val) { $cambiar += [pscustomobject]@{ Clave = $k; Valor = $val } }
        }
        if ($eventos.Count -eq 0) {
            Log 'OMITIDO' 'no se encontraron eventos de sonido en el registro'
            $code = 2
        } elseif ($cambiar.Count -eq 0 -and $esquema -eq '.Default') {
            Log 'OK' 'ya estaba la combinacion Predeterminado de Windows'
            $code = 5
        } else {
            foreach ($c in $cambiar) { Set-ItemProperty -LiteralPath $c.Clave.PSPath -Name '(default)' -Value $c.Valor -Type ExpandString -ErrorAction SilentlyContinue }
            Set-ItemProperty -LiteralPath $raiz -Name '(default)' -Value '.Default' -ErrorAction SilentlyContinue
            $mal = 0
            foreach ($c in $cambiar) {
                $ahora = Get-Item -LiteralPath $c.Clave.PSPath -ErrorAction SilentlyContinue
                if (-not $ahora -or ([string]$ahora.GetValue('', '', 'DoNotExpandEnvironmentNames')) -ne $c.Valor) { $mal++ }
            }
            $esquema2 = [string](Get-Item -LiteralPath $raiz).GetValue('')
            if ($mal -eq 0 -and $esquema2 -eq '.Default') {
                Log 'OK' ('verificado: combinacion Predeterminado de Windows restaurada, ' + $cambiar.Count + ' sonidos devueltos')
            } else {
                Log 'FALLO' ('no se pudieron restaurar ' + $mal + ' sonidos o la combinacion no cambio')
                $code = 1
            }
        }
    }

    'EXPLORER_RESTART' {
        # Reinicia la barra de tareas para que tome el cambio. Windows la vuelve a abrir solo (sin permisos de administrador).
        Say '  Reiniciando la barra de tareas para que tome el cambio...'
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
        $vuelve = $false
        for ($i = 0; $i -lt 80; $i++) {
            Start-Sleep -Milliseconds 100
            if (Get-Process -Name explorer -ErrorAction SilentlyContinue) { $vuelve = $true; break }
        }
        if (-not $vuelve) { Start-Process -FilePath 'explorer.exe' }
        Log 'INFO' 'se reinicio el Explorador para aplicar el cambio'
    }

    'WIDGETS_OFF' {
        Quitar-Apps @('MicrosoftWindows.Client.WebExperience')
        if ($global:tocadas -eq 0) { $code = 5 }
    }

    'WIDGETS_ON' {
        if (@(Get-AppxPackage -AllUsers -Name 'MicrosoftWindows.Client.WebExperience').Count -gt 0) {
            Log 'OK' 'ya estaba: el paquete de Widgets esta instalado'
            $code = 5
        } else {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Say '  Instalando el paquete de Widgets con winget...'
                & winget install --id 9MSSGKG348SP --source msstore --accept-package-agreements --accept-source-agreements | Out-Null
                Log 'INFO' ('winget install Widgets termino con codigo ' + $LASTEXITCODE)
            } else {
                Log 'FALLO' 'winget no esta disponible en esta PC'
            }
            if (@(Get-AppxPackage -AllUsers -Name 'MicrosoftWindows.Client.WebExperience').Count -gt 0) { Log 'OK' 'verificado: el paquete de Widgets esta instalado' }
            else { Log 'FALLO' 'el paquete de Widgets no quedo instalado, buscalo en la Microsoft Store'; $code = 1 }
        }
    }

    'INICIO_OFF' {
        $lista = @(Inicio-Basura)
        if ($lista.Count -eq 0) {
            Log 'OK' 'ya estaba: no hay apps basura que arranquen solas'
            $code = 5
        } else {
            $d = Split-Path -Parent $InicioArchivo
            if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
            foreach ($e in $lista) {
                if (Inicio-Poner $e $false) {
                    # Se anota para que R vuelva a prender solo lo que apago esta opcion
                    Add-Content -LiteralPath $InicioArchivo -Value (($e.Tipo, $e.Aprob, $e.Clave, $e.Nombre) -join "`t")
                    Log 'OK' ('ya no arranca solo: ' + $e.Nombre)
                    Say ('  Apagado al inicio: ' + $e.Nombre)
                } else {
                    Log 'FALLO' ('no se pudo apagar al inicio: ' + $e.Nombre); $code = 1
                }
            }
            foreach ($e in @(Inicio-Lista | Where-Object { $_.Activo -and $_.Dejar })) { Log 'INFO' ('se deja como esta: ' + $e.Nombre) }
        }
    }

    'INICIO_ON' {
        $l = @()
        if (Test-Path -LiteralPath $InicioArchivo) { $l = @(Get-Content -LiteralPath $InicioArchivo | Where-Object { $_ }) }
        if ($l.Count -eq 0) {
            Log 'OK' 'ya estaba: no hay apps de inicio apagadas por esta opcion'
            $code = 5
        } else {
            $quedan = @()
            foreach ($x in $l) {
                $c = $x -split "`t"
                if ($c.Count -lt 4) { continue }
                $e = [pscustomobject]@{ Tipo = $c[0]; Aprob = $c[1]; Clave = $c[2]; Nombre = $c[3] }
                if (Inicio-Poner $e $true) { Log 'OK' ('vuelve a arrancar solo: ' + $e.Nombre); Say ('  Prendido al inicio: ' + $e.Nombre) }
                else { Log 'FALLO' ('no se pudo prender al inicio: ' + $e.Nombre); $quedan += $x; $code = 1 }
            }
            if ($quedan.Count -gt 0) { Set-Content -LiteralPath $InicioArchivo -Value $quedan } else { Remove-Item -LiteralPath $InicioArchivo -Force -ErrorAction SilentlyContinue }
        }
    }

    'DEBLOAT' {
        Stop-Process -Name "OneDrive", "ms-teams", "msteams" -Force -ErrorAction SilentlyContinue
        Esperar-Cierre 'OneDrive', 'ms-teams', 'msteams' 2000
        $odExes = @(($env:LOCALAPPDATA + '\Microsoft\OneDrive\OneDrive.exe'), ($env:ProgramFiles + '\Microsoft OneDrive\OneDrive.exe'), (${env:ProgramFiles(x86)} + '\Microsoft OneDrive\OneDrive.exe'))
        $odHabia = (@($odExes | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0)
        if (-not $odHabia) {
            Log 'OMITIDO' 'OneDrive no estaba instalado'
        } else {
            $odSetup = @(("$env:SystemRoot\System32\OneDriveSetup.exe"), ("$env:SystemRoot\SysWOW64\OneDriveSetup.exe")) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
            $odArgs = '/uninstall'
            if (-not $odSetup) {
                foreach ($uk in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe') {
                    $us = [string](Get-ItemProperty -Path $uk -ErrorAction SilentlyContinue).UninstallString
                    if ($us -match '^\s*"?([^"]*OneDriveSetup\.exe)"?\s*(.*)$') { $odSetup = $Matches[1]; if ($Matches[2]) { $odArgs = $Matches[2] }; break }
                }
            }
            if ($odSetup -and (Test-Path -LiteralPath $odSetup)) {
                Start-Process -FilePath $odSetup -ArgumentList $odArgs -Wait -WindowStyle Hidden
                Esperar-Cierre 'OneDrive', 'OneDriveSetup' 2000
            } else {
                Log 'INFO' 'no se encontro el desinstalador de OneDrive'
            }
            if (@($odExes | Where-Object { Test-Path -LiteralPath $_ }).Count -eq 0) {
                Log 'OK' 'verificado: OneDrive desinstalado (tus archivos de la carpeta OneDrive no se tocan)'
            } else {
                Log 'FALLO' 'OneDrive sigue instalado'
                $code = 1
            }
        }

        # >>> XUCA-APPS (la app XucaOP copia esta lista para contar cuantas apps basura se borraron y cuantas quedan)
        $AppsBasura = @('Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSearch',
                 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection',
                 'Microsoft.WindowsFeedbackHub', 'Clipchamp.Clipchamp', 'Microsoft.People', 'Microsoft.MixedReality.Portal',
                 'Microsoft.SkypeApp', 'Microsoft.Copilot', 'MSTeams', 'Microsoft.PowerAutomateDesktop',
                 '*LinkedIn*', 'Microsoft.Todos', 'MicrosoftCorporationII.MicrosoftFamily',
                 'SpotifyAB.SpotifyMusic', 'Microsoft.ZuneVideo', 'Microsoft.ZuneMusic', 'Microsoft.YourPhone', 'Microsoft.549981C3F5F10',
                 'Microsoft.MicrosoftStickyNotes', 'Microsoft.OutlookForWindows', 'Microsoft.MSPaint', 'Microsoft.Paint', 'Microsoft.WindowsCamera',
                 'Microsoft.WindowsSoundRecorder', 'Microsoft.WindowsAlarms',
                 'Microsoft.Microsoft3DViewer', 'Microsoft.3DBuilder', 'Microsoft.Print3D', 'Microsoft.Appconnector',
                 'Microsoft.BingFoodAndDrink', 'Microsoft.BingHealthAndFitness', 'Microsoft.BingTranslator', 'Microsoft.BingTravel',
                 'Microsoft.BingFinance', 'Microsoft.BingSports', 'Microsoft.Office.Sway',
                 'Microsoft.Office.Lens', 'Microsoft.Messaging', 'Microsoft.Wallet', 'Microsoft.Whiteboard',
                 'Microsoft.OneConnect', 'Microsoft.CommsPhone', 'Microsoft.WindowsPhone', 'MicrosoftCorporationII.QuickAssist',
                 'Microsoft.WindowsMaps', 'ShazamEntertainmentLtd.Shazam', 'Disney.37853FC22B2CE',
                 'MicrosoftWindows.CrossDevice', 'Microsoft.XboxSpeechToTextOverlay',
                 '4DF9E0F8.Netflix',
                 'AmazonVideo.PrimeVideo', 'HULULLC.HULUPLUS', 'king.com.CandyCrushSaga',
                 'king.com.CandyCrushSodaSaga', 'king.com.CandyCrushFriends', 'king.com.BubbleWitch3Saga', 'Duolingo-LearnLanguagesforFree',
                 'AdobeSystemsIncorporated.AdobePhotoshopExpress', 'PandoraMediaInc.29680B314EFC2')
        # <<< XUCA-APPS
        $antes = @(Get-AppxPackage -AllUsers | Where-Object { -not $_.NonRemovable } | ForEach-Object { $_.Name })
        Quitar-Apps $AppsBasura
        if ($odHabia) { $global:tocadas++ }
        # Se anota lo que se borro, para que la app muestre el contador "5/13 borradas"
        $despues = @(Get-AppxPackage -AllUsers | Where-Object { -not $_.NonRemovable } | ForEach-Object { $_.Name })
        $borradas = @(foreach ($n in $AppsBasura) { $antes | Where-Object { ($_ -like $n) -and ($despues -notcontains $_) } })
        if ($odHabia -and (@($odExes | Where-Object { Test-Path -LiteralPath $_ }).Count -eq 0)) { $borradas += 'OneDrive' }
        if ($borradas.Count -gt 0) {
            $archApps = Join-Path $env:ProgramData 'XucaScripts\apps_borradas.txt'
            try {
                $dA = Split-Path -Parent $archApps
                if (-not (Test-Path -LiteralPath $dA)) { New-Item -ItemType Directory -Path $dA -Force | Out-Null }
                $ya = @(); if (Test-Path -LiteralPath $archApps) { $ya = @(Get-Content -LiteralPath $archApps | Where-Object { $_ }) }
                Set-Content -LiteralPath $archApps -Value @(@($ya) + @($borradas) | Sort-Object -Unique)
            } catch { Log 'INFO' ('no se pudo anotar las apps borradas: ' + $_.Exception.Message) }
        }
        if (($global:tocadas -eq 0) -and ($code -eq 0)) { $code = 5 }
    }

    'NOTEPAD_CHK' {
        # La politica DisableAIFeatures la lee el Bloc de notas 11.2503.16 o mas nuevo (dato de Microsoft).
        $np = @(Get-AppxPackage -AllUsers -Name 'Microsoft.WindowsNotepad' -ErrorAction SilentlyContinue | Sort-Object { [version]$_.Version } -Descending) | Select-Object -First 1
        if (-not $np) {
            Log 'INFO' 'el Bloc de notas nuevo no esta instalado: la politica queda puesta por si lo instalas'
            $code = 2
        } elseif ([version]$np.Version -lt [version]'11.2503.16.0') {
            Log 'INFO' ('el Bloc de notas es la version ' + $np.Version + ' y la politica de IA necesita la 11.2503.16 o mas nueva')
            Say '  Tu Bloc de notas es viejo para esta opcion: actualizalo desde la Microsoft Store y la IA se apaga sola.' 'Yellow'
            $code = 6
        } else {
            Log 'OK' ('el Bloc de notas ' + $np.Version + ' toma la politica que apaga su IA')
            if (Get-Process -Name 'Notepad' -ErrorAction SilentlyContinue) { Say '  El Bloc de notas esta abierto: cerralo y abrilo de nuevo para que se vaya la IA.' 'Yellow' }
        }
    }

    'IA_PAQ' {
        Quitar-Apps @('Microsoft.Windows.Ai.Copilot.Provider', 'Microsoft.Copilot', 'Microsoft.WindowsAiFoundation', 'Microsoft.Windows.Recall')
        if ($global:tocadas -eq 0) { $code = 5 }
    }

    'IA_ARCH' {
        $rutas = @(
            (Join-Path $env:LocalAppData 'Packages\Microsoft.Copilot*'),
            (Join-Path $env:LocalAppData 'Packages\Microsoft.Windows.Ai*'),
            (Join-Path $env:ProgramFiles 'WindowsApps\Microsoft.Copilot*'),
            (Join-Path $env:ProgramFiles 'WindowsApps\Microsoft.Windows.Ai*'),
            (Join-Path $env:SystemRoot 'SystemApps\Microsoft.Windows.Copilot*')
        )
        $hizo = 0; $quedo = 0
        foreach ($r in $rutas) {
            foreach ($it in @(Get-Item -Path $r -Force -ErrorAction SilentlyContinue)) {
                $ruta = $it.FullName
                $nombre = ($it.Name -split '_')[0]
                if (@(Get-AppxPackage -AllUsers -Name $nombre -ErrorAction SilentlyContinue).Count -gt 0) {
                    Log 'OMITIDO' ('no se borra ' + $ruta + ' porque el paquete sigue instalado'); $quedo++; continue
                }
                try { Remove-Item -LiteralPath $ruta -Recurse -Force -ErrorAction Stop } catch { }
                if ((Test-Path -LiteralPath $ruta) -and (($ruta -like ($env:ProgramFiles + '\WindowsApps\*')) -or ($ruta -like ($env:SystemRoot + '\SystemApps\*')))) {
                    & icacls.exe $ruta /setowner '*S-1-5-32-544' /t /c /q | Out-Null
                    & icacls.exe $ruta /grant '*S-1-5-32-544:(OI)(CI)F' /t /c /q | Out-Null
                    try { Remove-Item -LiteralPath $ruta -Recurse -Force -ErrorAction Stop } catch { }
                }
                if (Test-Path -LiteralPath $ruta) { $quedo++; Log 'OMITIDO' ('Windows no dejo borrar ' + $ruta) }
                else { $hizo++; Log 'OK' ('borrada ' + $ruta) }
            }
        }
        if ($hizo -eq 0) { $code = 5 }
        if ($quedo -gt 0) { Say ('  Quedaron {0} carpetas que Windows no dejo borrar o que siguen en uso.' -f $quedo) 'Yellow' }
    }

    'FUN_OFF' {
        $feats = 'Internet-Explorer-Optional-amd64', 'FaxServicesClientPackage', 'WindowsMediaPlayer'
        $hay = 0; $hizo = 0; $mal = 0
        foreach ($f in $feats) {
            $x = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
            if (-not $x) { Log 'OMITIDO' ($f + ' no existe en esta version de Windows'); continue }
            $hay++
            if ([string]$x.State -eq 'Disabled') { Log 'OK' ('ya estaba desactivada ' + $f); continue }
            Disable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction SilentlyContinue | Out-Null
            $est = [string](Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue).State
            if ($est -eq 'Disabled' -or $est -eq 'DisablePending') { $hizo++; Log 'OK' ('desactivada ' + $f + ' (' + $est + ')') }
            else { $mal++; Log 'FALLO' ('no se pudo desactivar ' + $f + ', quedo ' + $est); $code = 1 }
        }
        if ($mal -eq 0) { if ($hizo -gt 0) { $code = 0 } elseif ($hay -gt 0) { $code = 5 } else { $code = 2 } }
    }

    'FUN_ON' {
        $feats = 'Internet-Explorer-Optional-amd64', 'FaxServicesClientPackage', 'WindowsMediaPlayer'
        $hay = 0; $hizo = 0; $mal = 0
        foreach ($f in $feats) {
            $x = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
            if (-not $x) { Log 'OMITIDO' ($f + ' no existe en esta version de Windows'); continue }
            $hay++
            if ([string]$x.State -eq 'Enabled') { Log 'OK' ('ya estaba activa ' + $f); continue }
            Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -All -ErrorAction SilentlyContinue | Out-Null
            $est = [string](Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue).State
            if ($est -eq 'Enabled' -or $est -eq 'EnablePending') { $hizo++; Log 'OK' ('activada ' + $f + ' (' + $est + ')') }
            else { $mal++; Log 'FALLO' ('no se pudo activar ' + $f + ', quedo ' + $est); $code = 1 }
        }
        if ($mal -eq 0) { if ($hizo -gt 0) { $code = 0 } elseif ($hay -gt 0) { $code = 5 } else { $code = 2 } }
    }

    'EDGE_REMOVE' {
        $hizo = $false
        $edgeExe = ${env:ProgramFiles(x86)} + '\Microsoft\Edge\Application\msedge.exe'
        $wvDir = ${env:ProgramFiles(x86)} + '\Microsoft\EdgeWebView\Application'
        $wvKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        $hayEdge = Test-Path -LiteralPath $edgeExe
        $hayWV = (Test-Path -LiteralPath $wvDir) -or (Test-Path -LiteralPath $wvKey)
        $hayAppx = (@(Get-AppxPackage -AllUsers *microsoftedge*).Count -gt 0)
        $wvCS = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\ClientState\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        $ebAntes = $null
        try { $ebAntes = (Get-ItemProperty -LiteralPath $wvCS -ErrorAction Stop).EBWebView } catch { }

        if ($hayEdge -or $hayAppx) {
            Say '  Quitando Edge con el Edge.bat original (puede tardar unos minutos)...'
            $full = [IO.File]::ReadAllText((Join-Path $script:XCarpeta 'Edge.txt'))
            $pfx = '::EDGE' + 'BAT::'
            $filas = New-Object System.Collections.Generic.List[string]
            foreach ($ln in ($full -split "`r?`n")) {
                if ($ln.StartsWith($pfx, [StringComparison]::Ordinal)) { $filas.Add($ln.Substring($pfx.Length)) }
            }
            if ($filas.Count -lt 100) {
                Log 'FALLO' 'No se encontro el Edge.bat en scripts\Edge.txt'
                $code = 1
            } else {
                # Archivos que el Edge.bat bajaba de GitHub: se extraen de Edge.txt a %TEMP% (sin descargar)
                $binsTmp = @()
                $arq = $env:PROCESSOR_ARCHITECTURE
                if ($env:PROCESSOR_ARCHITEW6432) { $arq = $env:PROCESSOR_ARCHITEW6432 }
                if ($arq -eq 'AMD64') {
                    $d1 = Join-Path $env:TEMP 'setup.x64.exe'
                    $d2 = Join-Path $env:TEMP 'System.Data.SQLite.x64.dll'
                    if (Extraer-Bin $full 'setup' $d1 '0950336e0d633eb645e0cf66780d2102a182caa184264d4f62146fe229f636e7') { $binsTmp += $d1 }
                    if (Extraer-Bin $full 'sqlite' $d2 '1b3742c5bd1b3051ae396c6e62d1037565ca0cbbedb35b460f7d10a70c30376f') { $binsTmp += $d2 }
                    Log 'INFO' ('archivos del Edge.bat extraidos de Edge.txt: ' + $binsTmp.Count + ' de 2 (si falta alguno, el Edge.bat lo descarga)')
                }
                $edgeBat = Join-Path $env:TEMP 'xuca_Edge.bat'
                [IO.File]::WriteAllText($edgeBat, (($filas -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)
                $pr = Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ""' + $edgeBat + '" -auto <nul"') -Wait -PassThru -WindowStyle Hidden
                Log 'INFO' ('el Edge.bat original termino con codigo ' + $pr.ExitCode)
                $dbg = Join-Path $env:TEMP 'xuca_Edge_dbg.log'
                if ((Test-Path -LiteralPath $dbg) -and $script:XLog) {
                    $dest = ($script:XLog -replace '\.txt$', '_edge.log')
                    Copy-Item -LiteralPath $dbg -Destination $dest -Force
                    Log 'INFO' ('detalle del Edge.bat guardado en ' + $dest)
                }
                Remove-Item -LiteralPath $edgeBat, $dbg -Force -ErrorAction SilentlyContinue
                if ($binsTmp.Count -gt 0) { Remove-Item -LiteralPath $binsTmp -Force -ErrorAction SilentlyContinue }
                $hizo = $true

                if (Test-Path -LiteralPath $edgeExe) {
                    Log 'FALLO' 'Edge sigue instalado: msedge.exe todavia existe'
                    Say '  Edge sigue instalado, no se pudo borrar.' 'Red'
                    $code = 1
                } else {
                    Log 'OK' 'verificado: Edge ya no esta instalado (msedge.exe no existe)'
                    $code = 0
                }
                $quedan = @(Get-AppxPackage -AllUsers *microsoftedge*)
                if ($quedan.Count -gt 0) { Log 'INFO' ('quedan paquetes appx de Edge: ' + (($quedan | ForEach-Object { $_.Name }) -join ', ')) }
                if ($ebAntes) {
                    $ebAhora = $null
                    try { $ebAhora = (Get-ItemProperty -LiteralPath $wvCS -ErrorAction Stop).EBWebView } catch { }
                    if ((-not $ebAhora) -and (Test-Path -LiteralPath $ebAntes)) {
                        try {
                            if (-not (Test-Path -LiteralPath $wvCS)) { New-Item -Path $wvCS -Force | Out-Null }
                            New-ItemProperty -LiteralPath $wvCS -Name 'EBWebView' -Value $ebAntes -PropertyType String -Force | Out-Null
                            Log 'INFO' 'se restauro el registro EBWebView de WebView2 (el Edge.bat lo habia borrado)'
                        } catch { Log 'FALLO' ('no se pudo restaurar EBWebView: ' + $_.Exception.Message) }
                    }
                }
                if ($hayWV) {
                    if ((Test-Path -LiteralPath $wvDir) -or (Test-Path -LiteralPath $wvKey)) {
                        Log 'OK' 'verificado: WebView2 Runtime sigue instalado'
                    } else {
                        Log 'FALLO' 'WebView2 Runtime ya no aparece instalado'
                        Say '  WebView2 Runtime ya no aparece instalado: reinstalalo desde microsoft.com.' 'Red'
                        $code = 1
                    }
                }
            }
        } else {
            Log 'OK' 'Edge ya no estaba instalado'
        }

        Quitar-Apps @('Microsoft.BingSearch', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.Getstarted')
        if ($global:tocadas -gt 0) { $hizo = $true }
        
        if ((-not $hizo) -and ($code -eq 0 -or $code -eq $null)) {
            Say '  Edge, Bing y Primeros pasos ya estaban quitados.' 'Yellow'
            $code = 5
        }
    }

    # Drivers recomendados: solo lo que de verdad aporta (dispositivos sin driver, placa de video, chipset de AMD,
    # programas de mouse/teclado/auriculares de marca) y aviso de BIOS vieja. Se abre la pagina oficial de cada uno.
    'DRIVERS' {
        # Desde el boton de la app corre oculto: no pregunta nada, instala lo de Windows Update y abre las paginas solo
        $desdeApp = ($env:XUCA_DRVAPP -eq '1')
        # PRUEBA (borrar despues): hace de cuenta que falta todo, para ver que paginas abre
        $prueba = ($env:XUCA_DRVPRUEBA -eq '1')
        $wg = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        $reco = New-Object System.Collections.Generic.List[object]
        function Reco([string]$que, [string]$por, $ids, [string]$link) { $reco.Add([pscustomobject]@{ Que = $que; Por = $por; Ids = @($ids); Link = $link; Id = $null; Tipo = 'perif'; Titulo = $que; Corto = $por; Sub = @(); Abrir = $true }) }
        # Lo que solo esta viejo (no falta) se muestra, pero su pagina no se abre sola (en la prueba se abre todo)
        function Sin-Abrir { $reco[$reco.Count - 1].Abrir = $false }
        # Version corta para las cajitas de la app: tipo (icono y color), titulo y una frase
        function Corto([string]$tipo, [string]$titulo, [string]$corto) { $x = $reco[$reco.Count - 1]; $x.Tipo = $tipo; $x.Titulo = $titulo; $x.Corto = $corto }
        # Estado de un programa en winget: 'no' (no instalado), 'viejo' (hay version nueva) o 'ok'
        function Wg-Estado([string]$id) {
            $out = @(& winget list --id $id -e --accept-source-agreements --disable-interactivity 2>$null)
            if ($LASTEXITCODE -ne 0) { return 'no' }
            $l = @($out | Where-Object { $_ -match [regex]::Escape($id) }) | Select-Object -First 1
            if (-not $l) { return 'no' }
            # Columnas: Nombre, Id, Version, Disponible, Origen. Con 5 columnas hay version nueva.
            if (@(($l.Trim()) -split '\s{2,}').Count -ge 5) { return 'viejo' }
            return 'ok'
        }

        Say ''
        Say '  Revisando tu PC, puede tardar un minuto...' 'Cyan'

        # 1) Dispositivos sin driver o con el driver roto (lo unico que falta de verdad, por ejemplo sonido, red o Bluetooth)
        $malos = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.ConfigManagerErrorCode -in 1, 18, 28, 31, 39 })
        $wuDrv = @()
        if ($malos.Count -gt 0) {
            Say ''
            Say ('  Dispositivos sin driver o con problemas: ' + $malos.Count) 'Yellow'
            foreach ($m in $malos) { Say ('    * ' + $(if ($m.Name) { $m.Name } else { $m.PNPDeviceID })) }
            $hw = @($malos | ForEach-Object { @($_.HardwareID) + @($_.CompatibleID) } | Where-Object { $_ } | ForEach-Object { ([string]$_).ToUpper() })
            try {
                Say '  Buscando sus drivers en Windows Update...'
                $ses = New-Object -ComObject Microsoft.Update.Session
                $bus = $ses.CreateUpdateSearcher()
                $bus.ServerSelection = 3; $bus.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
                $res = $bus.Search("IsInstalled=0 and Type='Driver'")
                foreach ($u in @($res.Updates)) {
                    # Solo los que son para un dispositivo que no anda
                    if ($hw -contains ([string]$u.DriverHardwareID).ToUpper()) { $wuDrv += $u }
                }
                Log 'INFO' ('Windows Update: ' + $wuDrv.Count + ' drivers para dispositivos que no andan')
            } catch { Log 'INFO' ('no se pudo buscar en Windows Update: ' + $_.Exception.Message) }
        }

        # 1b) Que bajar de la pagina de la placa madre: solo lo que usa el driver generico de Windows o no tiene driver
        $piezas = New-Object System.Collections.Generic.List[string]
        if ($wuDrv.Count -eq 0) {
            foreach ($m in $malos) {
                $tipo = $(switch -Regex ([string]$m.PNPClass) { '^Net$' { 'red' } 'Bluetooth' { 'Bluetooth' } 'MEDIA|AudioEndpoint' { 'audio' } 'USB' { 'USB' } default { 'chipset u otro' } })
                $piezas.Add('Sin driver (' + $tipo + '): ' + $(if ($m.Name) { $m.Name } else { 'dispositivo sin nombre' }))
            }
        }
        # Solo las placas que estan: las apagadas no cuentan, y el WiFi sin ninguna red a la vista (sin antena) tampoco
        $fis3 = @(); try { $fis3 = @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { [string]$_.Status -ne 'Disabled' }) } catch { }
        $wifiSinRed = $false
        if ((@($fis3 | Where-Object { $_.NdisPhysicalMedium -eq 9 }).Count -gt 0) -and (@($fis3 | Where-Object { ($_.NdisPhysicalMedium -eq 9) -and ([string]$_.Status -eq 'Up') }).Count -eq 0)) {
            $o = (& netsh.exe wlan show networks 2>$null | Out-String)
            $mw = [regex]::Match($o, '(\d+)\s+(networks?|redes)')
            if ($mw.Success -and ([int]$mw.Groups[1].Value -eq 0)) { $wifiSinRed = $true; Log 'INFO' 'la placa WiFi no ve ninguna red (sin antena?): no se recomienda su driver' }
        }
        foreach ($a in @($fis3 | Where-Object { $_.NdisPhysicalMedium -eq 14 })) {
            if (-not ($prueba -or ([string]$a.DriverProvider -eq 'Microsoft'))) { continue }
            if ([string]$a.InterfaceDescription -match 'Realtek') {
                # Realtek: mejor su propia pagina que la de la placa madre (es el mismo driver, mas nuevo, y se sabe que opcion bajar)
                $rtUsb = ([string]$a.PnPDeviceID -like 'USB\*')
                Reco ('Driver de red Realtek (' + $a.InterfaceDescription + ')') 'tu placa de red usa el driver generico de Windows. En la pagina de Realtek, en la parte "Windows", baja "Win10/Win11 Auto Installation Program", descomprimilo y abri setup.exe' @() $(if ($rtUsb) { 'https://www.realtek.com/Download/List?cate_id=585' } else { 'https://www.realtek.com/Download/List?cate_id=584' })
                Corto 'red' 'Red Realtek' 'Usa el driver generico de Windows: bajalo directo de Realtek'
                $reco[$reco.Count - 1].Sub = @('En la parte Windows: Win10/Win11 Auto Installation Program', 'Descomprimilo y abri setup.exe')
            }
            else { $piezas.Add('LAN: ' + $a.InterfaceDescription) }
        }
        # Antenas WiFi/Bluetooth USB: su driver lo da la marca de la antena, no la placa madre (por el VID del USB)
        $dongles = @{ '2357' = 'tp-link.com'; '0B05' = 'asus.com'; '0846' = 'netgear.com'; '2001' = 'dlink.com'; '7392' = 'edimax.com' }
        foreach ($a in @($fis3 | Where-Object { ($_.NdisPhysicalMedium -eq 9) -and (-not $wifiSinRed) })) {
            if (-not ($prueba -or ([string]$a.DriverProvider -eq 'Microsoft'))) { continue }
            if ([string]$a.PnPDeviceID -match '^USB\\VID_([0-9A-Fa-f]{4})') {
                $vidW = $Matches[1].ToUpper(); $descW = [string]$a.InterfaceDescription
                Reco ('Driver de tu antena WiFi USB (' + $descW + ')') 'usa el driver generico de Windows: con el de la marca la antena suele andar mas estable y mas rapido' @() $(if ($dongles.ContainsKey($vidW)) { 'https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky site:' + $dongles[$vidW] + ' ' + $descW + ' driver') } else { 'https://www.google.com/search?q=' + [uri]::EscapeDataString($descW + ' driver') })
                Corto 'wifi' 'Antena WiFi USB' 'Usa el driver generico: el de la marca anda mas estable'
            }
            else { $piezas.Add('WiFi: ' + $a.InterfaceDescription) }
        }
        $firmados = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { ([string]$_.DeviceClass) -in 'BLUETOOTH', 'MEDIA' })
        $btOk = @(Get-PnpDevice -PresentOnly -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { ([string]$_.Status -eq 'OK') -and ([string]$_.InstanceId -like 'USB\VID_*') }).Count -gt 0
        foreach ($d in @($firmados | Where-Object { $btOk -and ([string]$_.DeviceClass -eq 'BLUETOOTH') -and ([string]$_.HardWareID -like 'USB\VID_*') })) {
            if (-not ($prueba -or ([string]$d.DriverProviderName -eq 'Microsoft'))) { continue }
            if (([string]$d.HardWareID -match 'VID_([0-9A-Fa-f]{4})') -and $dongles.ContainsKey($Matches[1].ToUpper())) {
                Reco ('Driver de tu antena Bluetooth USB (' + $d.DeviceName + ')') 'usa el driver generico de Windows: el de la marca suele conectar mejor auriculares y joysticks' @() ('https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky site:' + $dongles[$Matches[1].ToUpper()] + ' ' + $d.DeviceName + ' bluetooth driver'))
                Corto 'bt' 'Antena Bluetooth USB' 'Usa el driver generico: el de la marca conecta mejor'
                break
            }
            $piezas.Add('Bluetooth: ' + $d.DeviceName); break
        }
        # Audio de la placa: el de Realtek solo si Windows le puso el generico (sin el, pueden fallar los conectores del frente o el microfono)
        # y solo si hay algo enchufado en sus jacks (3,5 mm): con auriculares USB o el sonido del monitor no sirve de nada.
        # Cada salida/entrada de audio esta en MMDevices: DeviceState 1 = enchufada y activa, 8 = desenchufada; la propiedad ,2 dice de que chip es.
        $rtJacks = 0; $rtEnch = 0
        foreach ($tipoA in 'Render', 'Capture') {
            foreach ($k in @(Get-ChildItem ('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\' + $tipoA) -ErrorAction SilentlyContinue)) {
                $chipA = ''; try { $chipA = [string](Get-ItemProperty -LiteralPath ($k.PSPath + '\Properties') -ErrorAction Stop).'{b3f8fa53-0004-438e-9003-51a46e139bfc},2' } catch { }
                if ($chipA -notmatch 'VEN_10EC') { continue }
                $rtJacks++
                if ((Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction SilentlyContinue).DeviceState -eq 1) { $rtEnch++ }
            }
        }
        $jackUsado = ($rtJacks -eq 0) -or ($rtEnch -gt 0)
        foreach ($d in @($firmados | Where-Object { ([string]$_.DeviceClass -eq 'MEDIA') -and ([string]$_.HardWareID -like 'HDAUDIO\FUNC_01&VEN_10EC*') })) {
            if ((-not $prueba) -and ([string]$d.DriverProviderName -eq 'Microsoft') -and (-not $jackUsado)) { Log 'INFO' 'audio Realtek con el driver generico, pero no hay nada enchufado en sus jacks: no se recomienda'; break }
            if ($prueba -or ([string]$d.DriverProviderName -eq 'Microsoft')) { $piezas.Add('Audio: Realtek'); break }
            else { Log 'OK' ('audio Realtek con su driver (' + $d.DriverVersion + '): no hace falta bajarlo') }
        }
        if ($piezas.Count -gt 0) {
            Reco 'Drivers de tu placa madre' 'baja de la pagina de tu placa solo esto (lo demas, como las utilidades, no hace falta):' @() '#placa'
            $reco[$reco.Count - 1].Sub = @($piezas)
            Corto 'placa' 'Placa madre' 'Baja solo esto de su pagina (tienen el driver generico de Windows):'
        }

        # 2) Placa de video: con el driver basico de Windows o con uno de hace mas de 4 meses
        foreach ($g in @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)) {
            $pnp = [string]$g.PNPDeviceID
            if ($pnp -notmatch 'VEN_([0-9A-Fa-f]{4})') { continue }
            $ven = $Matches[1].ToUpper()
            $basico = ([string]$g.Name -match '(?i)basic|basico') -or ([string]$g.InfFilename -match '(?i)^(basicdisplay|display)\.inf$')
            $dias = 0; try { $dias = [int]((Get-Date) - [datetime]$g.DriverDate).TotalDays } catch { }
            # Placas viejas que la marca ya casi no actualiza (AMD Vega/Polaris y anteriores, NVIDIA GTX 900/1000, Intel HD/UHD 600):
            # su ultimo driver puede tener meses y estar al dia igual, asi que se les dan 12 meses
            $vieja = ([string]$g.Name -match '(?i)Vega|RX\s*(4\d0|5\d0)\b|Radeon\s*(5\d\d|R[579])\b|\bR[579]\s|\bHD\s*[5-8]\d{3}|GTX\s*(7\d\d|9\d\d|10\d\d)\b|\bGT\s*(7\d\d|10\d\d)\b|TITAN X|\bHD Graphics|UHD Graphics 6\d\d|Iris(\(R\))?( Plus| Pro)? Graphics \d{3}')
            $limite = $(if ($vieja) { 365 } else { 120 })
            if ((-not $basico) -and ($dias -lt $limite) -and (-not $prueba)) { Log 'OK' ('driver de video al dia: ' + $g.Name + ' (' + $g.DriverVersion + ')' + $(if ($vieja) { ', placa que la marca ya casi no actualiza' } else { '' })); continue }
            $por = $(if ($basico) { 'tu placa de video usa el driver basico de Windows: sin el de la marca andas sin aceleracion' } else { 'tu driver de video tiene ' + $dias + ' dias; los nuevos traen mejoras para los juegos' })
            switch ($ven) {
                '10DE' { Reco ('Driver de NVIDIA (' + $g.Name + ')') ($por + '. La NVIDIA App instala el ultimo driver recomendado.') @('Nvidia.NVIDIAApp', 'Nvidia.GeForceExperience') 'https://www.nvidia.com/es-la/software/nvidia-app/' }
                '1002' { Reco ('Driver de AMD (' + $g.Name + ')') ($por + '. En la pagina de AMD esta el instalador que detecta tu placa.') @() 'https://www.amd.com/es/support/download/drivers.html' }
                '8086' { Reco ('Driver de Intel (' + $g.Name + ')') ($por + '. El Asistente de Intel instala el driver recomendado.') @('Intel.IntelDriverAndSupportAssistant') 'https://www.intel.com/content/www/es/es/support/detect.html' }
            }
            if ($ven -in '10DE', '1002', '8086') {
                $con = $(switch ($ven) { '10DE' { 'la NVIDIA App' } '1002' { 'AMD Adrenalin' } default { 'el Asistente de Intel' } })
                Corto $(switch ($ven) { '10DE' { 'gpu-nv' } '1002' { 'gpu-amd' } default { 'gpu-intel' } }) ([string]$g.Name) $(if ($basico) { 'Usa el driver basico de Windows: instala el de la marca con ' + $con } else { 'Driver de hace ' + $dias + ' dias: actualizalo con ' + $con })
                if (-not $basico) { Sin-Abrir }
            }
        }

        # 3) Procesador: en los Ryzen el driver de chipset de AMD trae el plan de energia y, en los X3D, el reparto de nucleos
        $cpu = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)[0]
        if ($cpu -and ([string]$cpu.Manufacturer -eq 'AuthenticAMD') -and ([string]$cpu.Name -match 'Ryzen')) {
            $chip = @(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { [string]$_.DisplayName -match '(?i)AMD Chipset' })
            if (($chip.Count -eq 0) -or $prueba) { Reco 'Driver de chipset de AMD' ('tenes un ' + ([string]$cpu.Name).Trim() + ' y no esta instalado: mejora el manejo de energia y de los nucleos (en los X3D hace falta)') @() 'https://www.amd.com/es/support/download/drivers.html'; Corto 'chipset' 'Chipset de AMD' 'No esta instalado: mejora la energia y el reparto de nucleos' }
            else { Log 'OK' ('driver de chipset de AMD instalado: ' + $chip[0].DisplayVersion) }
        }

        # 4) Mouse, teclado y auriculares de marca: el programa de la marca (DPI, macros, sonido, Sonar...)
        $usb = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { [string]$_.InstanceId -match '^(USB|HID)\\VID_([0-9A-F]{4})' })
        $nombresDe = {
            param($vid)
            @($usb | Where-Object { [string]$_.InstanceId -match ('VID_(' + $vid + ')') } | ForEach-Object {
                $d = $null; try { $d = (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction Stop).Data } catch { }
                if ($d) { [string]$d } else { [string]$_.FriendlyName }
            } | Where-Object { $_ } | Select-Object -Unique)
        }
        $marcas = @(
            @{ Vid = '046D'; Que = 'Logitech G HUB'; Ids = @('Logitech.GHUB'); Link = 'https://www.logitechg.com/innovation/g-hub.html'; Solo = '(?i)\bG\s?\d|G PRO|PRO X|LIGHTSPEED|ASTRO|Gaming' },
            @{ Vid = '1532'; Que = 'Razer Synapse'; Ids = @('RazerInc.RazerInstaller'); Link = 'https://www.razer.com/synapse-4'; Solo = '' },
            @{ Vid = '1038'; Que = 'SteelSeries GG (con Sonar)'; Ids = @('SteelSeries.GG'); Link = 'https://steelseries.com/gg'; Solo = '' },
            @{ Vid = '1B1C'; Que = 'Corsair iCUE'; Ids = @('Corsair.iCUE.5', 'Corsair.iCUE.4'); Link = 'https://www.corsair.com/icue'; Solo = '' },
            @{ Vid = '0951|03F0'; Que = 'HyperX NGENUITY'; Ids = @(); Link = 'https://hyperx.com/pages/ngenuity'; Solo = '(?i)HyperX' },
            @{ Vid = '31E3'; Que = 'Wootility'; Ids = @('Wooting.Wootility'); Link = 'https://wooting.io/wootility'; Solo = '' },
            @{ Vid = '1E7D'; Que = 'ROCCAT / Turtle Beach Swarm II'; Ids = @(); Link = 'https://www.turtlebeach.com/swarm-ii'; Solo = '' }
        )
        foreach ($mk in $marcas) {
            $nom = @(& $nombresDe $mk.Vid)
            if ($nom.Count -eq 0) { continue }
            if ($mk.Solo -and (-not ($nom -match $mk.Solo))) { Log 'INFO' ('se ve ' + ($nom -join ', ') + ' pero no es de la linea gaming: no hace falta ' + $mk.Que); continue }
            $estado = 'no'
            if ($wg -and $mk.Ids.Count -gt 0 -and (-not $prueba)) { foreach ($id in $mk.Ids) { $estado = Wg-Estado $id; if ($estado -ne 'no') { break } } }
            if ($estado -eq 'ok') { Log 'OK' ($mk.Que + ' ya esta instalado y al dia'); continue }
            $por = $(if ($estado -eq 'viejo') { 'ya lo tenes pero hay una version nueva' } else { 'para configurar ' + (($nom | Select-Object -First 2) -join ' y ') })
            Reco $mk.Que $por $mk.Ids $mk.Link
            Corto 'perif' $mk.Que $(if ($estado -eq 'viejo') { 'Hay una version nueva' } else { 'Para configurar ' + (($nom | Select-Object -First 1)) })
            if ($estado -eq 'viejo') { Sin-Abrir }
        }

        # 4b) Otros mouse y teclados de marca (Attack Shark, Ajazz, VXE, Redragon...): se busca su programa por el nombre
        # Marcas que ya se revisan arriba, y joysticks (Sony, Microsoft, Nintendo, 8BitDo, Valve): esos no necesitan programa
        $conocidos = '046D|1532|1038|1B1C|0951|03F0|31E3|1E7D|045E|054C|057E|2DC8|28DE|056A|256C|28BD|2FEB|044F|0EB7|346E|1235|19F7|14ED|1397|2708|0FD9|07CA|194F|0499|07FD|17CC|1C75|0763|0582'
        $genericos = '(?i)^(usb|hid|generic|wireless|wired|2\.4g|receiver|composite|input|device|keyboard|mouse|optical|gaming|dongle|nano|bt|bluetooth|rgb|kb|ms|and|audio|headset|headphones?|microphone|mic|speakers?|sound|card|adapter|dac|webcam|camera|hd|pnp|stereo|7\.1|virtual|[\s\-_\.\d\(\)])+$'
        $progs = (@(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.DisplayName }) -join ' | ')
        # Cada mouse, teclado, auricular o micro USB por separado (VID y PID): dos marcas distintas pueden compartir el mismo fabricante de chip
        $vps = @(Get-PnpDevice -PresentOnly -Class Keyboard, Mouse, Media -ErrorAction SilentlyContinue | ForEach-Object { if ([string]$_.InstanceId -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { $Matches[1].ToUpper() + '&' + $Matches[2].ToUpper() } } | Select-Object -Unique)
        # Modelos que se presentan con un nombre generico (tipo "Gaming Keyboard"): se reconocen por su VID y PID
        $modelosVp = @{ '3151&502F' = 'Attack Shark X82 Pro HE' }
        # Chips que usan muchas marcas gamer chinas (Ajazz, Attack Shark, VXE, Redragon...): aunque digan solo "Gaming Keyboard", tienen programa
        $chipsGamer = '3151|3554|373B|258A|1D57|320F|36B0|3434'
        $clases = @{}
        foreach ($d in @(Get-PnpDevice -PresentOnly -Class Keyboard, Mouse, Media -ErrorAction SilentlyContinue)) { if ([string]$d.InstanceId -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { $clases[$Matches[1].ToUpper() + '&' + $Matches[2].ToUpper()] = [string]$d.Class } }
        $vistos = @()
        foreach ($vp in $vps) {
            $vid = $vp.Split('&')[0]; $pid2 = $vp.Split('&')[1]
            if ($vid -match ('^(' + $conocidos + ')$')) { continue }
            # Solo el nombre que da el propio aparato (el de Windows es generico, tipo "Dispositivo de teclado HID")
            $todos = @($usb | Where-Object { [string]$_.InstanceId -match ('VID_' + $vid + '&PID_' + $pid2) } | ForEach-Object {
                try { [string](Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction Stop).Data } catch { }
            } | Where-Object { $_ } | ForEach-Object { $_.Trim() } | Select-Object -Unique)
            # Un nombre sirve si tiene al menos una palabra de 3 letras que no sea generica ("K2" solo no dice la marca) y no es un joystick
            $nom = @($todos | Where-Object { ($_ -notmatch $genericos) -and ($_ -notmatch '(?i)controller|gamepad|joystick|mando') -and (@(($_ -split '[\s\-_]+') | Where-Object { ($_.Length -ge 3) -and ($_ -notmatch $genericos) }).Count -gt 0) }) | Select-Object -First 1
            if (@($todos | Where-Object { $_ -match '(?i)controller|gamepad|joystick|mando' }).Count -gt 0) { Log 'INFO' ('joystick: ' + ($todos -join ', ') + ' - no hace falta programa'); continue }
            $busca = ''
            if ($modelosVp.ContainsKey($vp)) { $nom = $modelosVp[$vp] }
            if (-not $nom) {
                # Nombre generico: si es un aparato gamer (chip de marcas gamer o dice "Gaming"), se busca su programa por VID y PID
                $tipo = $(switch ($clases[$vp]) { 'Keyboard' { 'teclado' } 'Mouse' { 'mouse' } default { 'auricular o microfono' } })
                $gen = @($todos)[0]
                if (($vid -match ('^(' + $chipsGamer + ')$')) -or ($gen -match '(?i)gaming|rgb|8k|4k|rapid')) {
                    $nom = ($(if ($gen) { $gen } else { $tipo }) + ' (' + $tipo + ' VID ' + $vid + ' PID ' + $pid2 + ')')
                    $busca = ('"VID_' + $vid + '" "PID_' + $pid2 + '" ' + $(switch ($tipo) { 'teclado' { 'keyboard' } 'mouse' { 'mouse' } default { 'headset' } }) + ' driver software')
                } else { Log 'INFO' ('periferico sin nombre de marca (' + $vp + '): ' + $(if ($todos.Count -gt 0) { $todos -join ', ' } else { 'sin nombre' })); continue }
            }
            if ($vistos -contains $nom) { continue }
            $vistos += $nom
            Log 'INFO' ('periferico: ' + $nom + ' (' + $vp + ')')
            # Si ya hay un programa instalado con su nombre (por ejemplo "AJ159" o "Attack Shark"), no hace falta
            $clave = @(($nom -split '[\s\-_]+') | Where-Object { ($_.Length -ge 3) -and ($_ -notmatch $genericos) }) | Select-Object -First 1
            if ((-not $prueba) -and (-not $busca) -and $clave -and ($progs -match [regex]::Escape($clave))) { Log 'OK' ('ya hay un programa para ' + $nom); continue }
            if (-not $busca) { $busca = ($nom + ' driver software download') }
            # Lo que se configura depende de que aparato es
            $para = $(switch ($clases[$vp]) {
                'Mouse' { 'para configurar tu mouse (DPI, polling, botones y luces); lo da la marca' }
                'Keyboard' { 'para configurar tu teclado (rapid trigger, recorrido de teclas, macros y luces); lo da la marca' }
                default { 'para configurar tu auricular o microfono (ecualizador, microfono y sonido envolvente); lo da la marca' }
            })
            Reco ('Programa de ' + $nom) $para @() ('https://www.google.com/search?q=' + [uri]::EscapeDataString($busca))
            Corto $(switch ($clases[$vp]) { 'Mouse' { 'mouse' } 'Keyboard' { 'teclado' } default { 'audio' } }) $nom $(switch ($clases[$vp]) { 'Mouse' { 'Su programa: DPI, polling, botones y luces' } 'Keyboard' { 'Su programa: rapid trigger, macros y luces' } default { 'Su programa: ecualizador y microfono' } })
        }

        # 4c) Tabletas graficas: sin el driver de la marca no anda la presion del lapiz ni los botones
        $tabletas = @(
            @{ Vid = '056A'; Marca = 'Wacom'; Prog = 'Wacom'; Link = 'https://www.wacom.com/es-es/support/product-support/drivers' },
            @{ Vid = '256C'; Marca = 'Huion'; Prog = 'Huion'; Link = 'https://www.huion.com/download/' },
            @{ Vid = '28BD'; Marca = 'XP-Pen'; Prog = 'XP-?PEN|PenTablet'; Link = 'https://www.xp-pen.com/download/' },
            @{ Vid = '2FEB'; Marca = 'VEIKK'; Prog = 'VEIKK'; Link = 'https://www.veikk.com/download/' }
        )
        foreach ($tb in $tabletas) {
            $nom = @(& $nombresDe $tb.Vid)
            if ($nom.Count -eq 0) { continue }
            $marcaT = $tb.Marca; $progT = $tb.Prog; $linkT = $tb.Link
            # Gaomon usa el mismo chip que Huion, pero tiene su propio driver
            if ($nom -match '(?i)gaomon') { $marcaT = 'Gaomon'; $progT = 'Gaomon'; $linkT = 'https://www.gaomon.net/download/' }
            if ((-not $prueba) -and ($progs -match $progT)) { Log 'OK' ('tableta ' + $marcaT + ': su driver ya esta instalado'); continue }
            Log 'INFO' ('tableta grafica: ' + ($nom -join ', '))
            Reco ('Driver de tu tableta ' + $marcaT) 'sin el driver de la marca no anda la presion del lapiz ni los botones de la tableta' @() $linkT
            Corto 'tableta' ('Tableta ' + $marcaT) 'Su driver: presion del lapiz y botones'
        }

        # 4d) Impresoras: si Windows les puso su driver generico, el de la marca agrega el escaner, los niveles de tinta y mas opciones
        $sitiosImp = [ordered]@{ '(?i)\bHP\b|Hewlett|Samsung' = 'hp.com'; '(?i)Epson' = 'epson.com'; '(?i)Canon' = 'canon.com'; '(?i)Brother' = 'brother.com'; '(?i)Xerox' = 'xerox.com'; '(?i)Lexmark' = 'lexmark.com'; '(?i)Ricoh' = 'ricoh.com'; '(?i)Kyocera' = 'kyoceradocumentsolutions.com'; '(?i)Pantum' = 'pantum.com'; '(?i)\bOKI\b' = 'oki.com' }
        $imps = @(); try { $imps = @(Get-Printer -ErrorAction Stop) } catch { }
        $vistasImp = @()
        foreach ($im in $imps) {
            $nomI = (([string]$im.Name) -replace '\[.*?\]|\(.*?\)', '' -replace '\s+', ' ').Trim()
            # Las virtuales (PDF, XPS, OneNote, Fax) no son impresoras de verdad
            if ($nomI -match '(?i)PDF|XPS|OneNote|Fax|Send To|AnyDesk|Snagit') { continue }
            $sitioI = ''
            foreach ($rx in $sitiosImp.Keys) { if (($nomI + ' ' + [string]$im.DriverName) -match $rx) { $sitioI = $sitiosImp[$rx]; break } }
            if (-not $sitioI) { continue }
            if ($vistasImp -contains $nomI) { continue }
            $vistasImp += $nomI
            if ((-not $prueba) -and ([string]$im.DriverName -notmatch '(?i)^Microsoft|Generic|Mopria')) { Log 'OK' ('impresora ' + $nomI + ' con driver de la marca: ' + $im.DriverName); continue }
            Log 'INFO' ('impresora con el driver generico de Windows: ' + $nomI + ' (' + $im.DriverName + ')')
            Reco ('Driver de tu impresora ' + $nomI) 'usa el driver generico de Windows: el de la marca suma el escaner, los niveles de tinta y mas opciones de impresion' @() ('https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky site:' + $sitioI + ' ' + $nomI + ' driver'))
            Corto 'impresora' $nomI 'Usa el driver generico: el de la marca suma escaner y tinta'
        }

        # 4e) Otros aparatos que necesitan el programa o el driver de la marca: volantes, microfonos e interfaces de audio,
        # Stream Deck, capturadoras, webcams y joysticks 8BitDo. Solo si esta enchufado y su programa no esta instalado.
        # Nombre (opcional) filtra por el nombre que da el aparato: Elgato usa el mismo VID para todo.
        $aparatos = @(
            @{ Vid = '044F'; Que = 'Drivers de Thrustmaster'; Prog = 'Thrustmaster'; Tipo = 'volante'; Por = 'sin su driver no anda el force feedback del volante ni todos los botones'; Corto = 'Su driver: force feedback y botones' },
            @{ Vid = '0EB7'; Que = 'Fanatec Driver'; Prog = 'Fanatec'; Tipo = 'volante'; Por = 'sin su driver no anda el force feedback ni se actualiza el firmware de la base'; Corto = 'Su driver: force feedback y firmware' },
            @{ Vid = '346E'; Que = 'MOZA Pit House'; Prog = 'Pit House|MOZA'; Tipo = 'volante'; Por = 'configura el force feedback y actualiza el firmware de la base'; Corto = 'Su programa: force feedback y firmware' },
            @{ Vid = '1235'; Que = 'Focusrite Control'; Prog = 'Focusrite'; Tipo = 'audio'; Link = 'https://downloads.focusrite.com/'; Por = 'trae el driver ASIO (menos latencia) y el control de tu placa de sonido'; Corto = 'Driver ASIO y control de la placa' },
            @{ Vid = '19F7'; Que = 'RODE Central'; Prog = 'R(O|\xd8)DE'; Tipo = 'audio'; Por = 'configura tu microfono RODE (ganancia, procesado) y actualiza su firmware'; Corto = 'Ganancia, procesado y firmware' },
            @{ Vid = '14ED'; Que = 'ShurePlus MOTIV'; Prog = 'Shure|MOTIV'; Tipo = 'audio'; Por = 'configura tu microfono Shure (ganancia, ecualizador) y actualiza su firmware'; Corto = 'Ganancia, ecualizador y firmware' },
            @{ Vid = '1397'; Que = 'Driver de Behringer'; Prog = 'Behringer|UMC'; Tipo = 'audio'; Por = 'trae el driver ASIO de tu placa de sonido: mucha menos latencia que el de Windows'; Corto = 'Driver ASIO: menos latencia' },
            @{ Vid = '2708'; Que = 'Driver de Audient'; Prog = 'Audient'; Tipo = 'audio'; Por = 'trae el driver ASIO y el panel de tu placa de sonido'; Corto = 'Driver ASIO y panel de control' },
            @{ Vid = '194F'; Que = 'PreSonus Universal Control'; Prog = 'Universal Control|PreSonus'; Tipo = 'audio'; Por = 'trae el driver ASIO y el panel de tu placa de sonido PreSonus'; Corto = 'Driver ASIO y panel de control' },
            @{ Vid = '0499'; Que = 'Yamaha Steinberg USB Driver'; Prog = 'Yamaha Steinberg|Steinberg USB|Yamaha USB'; Tipo = 'audio'; Por = 'el driver ASIO de tu placa de sonido Steinberg o Yamaha: mucha menos latencia que el de Windows'; Corto = 'Driver ASIO: menos latencia' },
            @{ Vid = '07FD'; Que = 'Driver de MOTU'; Prog = 'MOTU'; Tipo = 'audio'; Por = 'trae el driver ASIO y el panel de tu placa de sonido MOTU'; Corto = 'Driver ASIO y panel de control' },
            @{ Vid = '17CC'; Que = 'Native Access (Native Instruments)'; Prog = 'Native Access|Native Instruments'; Tipo = 'audio'; Por = 'instala el driver de tu placa de sonido o controlador de Native Instruments'; Corto = 'Su driver y programa' },
            @{ Vid = '1C75'; Que = 'Arturia Software Center'; Prog = 'Arturia'; Tipo = 'audio'; Por = 'instala el driver y el firmware de tu placa de sonido o teclado Arturia'; Corto = 'Su driver y firmware' },
            @{ Vid = '0763'; Que = 'Driver de M-Audio'; Prog = 'M-Audio'; Tipo = 'audio'; Por = 'el driver ASIO de tu placa de sonido M-Audio: mucha menos latencia que el de Windows'; Corto = 'Driver ASIO: menos latencia' },
            @{ Vid = '0582'; Que = 'Driver de Roland / BOSS'; Prog = 'Roland|BOSS'; Tipo = 'audio'; Por = 'muchos aparatos Roland y BOSS no andan bien sin su driver (cada modelo tiene el suyo)'; Corto = 'El driver de tu modelo' },
            @{ Vid = '0FD9'; Nombre = 'Stream Deck'; Que = 'Elgato Stream Deck'; Prog = 'Stream Deck'; Tipo = 'stream'; Link = 'https://www.elgato.com/downloads'; Por = 'sin su programa los botones del Stream Deck no hacen nada'; Corto = 'Su programa: para configurar los botones' },
            @{ Vid = '0FD9'; Nombre = 'Wave'; Que = 'Elgato Wave Link'; Prog = 'Wave Link'; Tipo = 'audio'; Link = 'https://www.elgato.com/downloads'; Por = 'configura tu microfono Wave y mezcla el sonido para stream'; Corto = 'Microfono y mezcla de sonido' },
            @{ Vid = '0FD9'; Nombre = 'Facecam|Cam Link'; Que = 'Elgato Camera Hub'; Prog = 'Camera Hub'; Tipo = 'camara'; Link = 'https://www.elgato.com/downloads'; Por = 'configura la imagen de tu camara (exposicion, enfoque) y actualiza su firmware'; Corto = 'Imagen y firmware de la camara' },
            @{ Vid = '0FD9'; Nombre = 'HD60|4K|Game Capture'; Que = 'Elgato 4K Capture Utility'; Prog = 'Capture Utility|Game Capture'; Tipo = 'camara'; Link = 'https://www.elgato.com/downloads'; Por = 'el programa para grabar y actualizar el firmware de tu capturadora'; Corto = 'Grabar y actualizar el firmware' },
            @{ Vid = '07CA'; Que = 'AVerMedia Streaming Center'; Prog = 'AVerMedia|RECentral'; Tipo = 'camara'; Por = 'el programa y el driver de tu capturadora o camara AVerMedia'; Corto = 'Su programa y driver' },
            @{ Vid = '046D'; Nombre = 'Webcam|Brio|StreamCam|\bC\d{3}\b'; Que = 'Logi Tune'; Prog = 'Logi Tune|LogiTune|Logi Capture|G HUB'; Tipo = 'camara'; Por = 'configura la imagen de tu webcam Logitech (zoom, enfoque, exposicion) y actualiza su firmware'; Corto = 'Imagen y firmware de la webcam' },
            @{ Vid = '2DC8'; Que = '8BitDo Ultimate Software'; Prog = '8BitDo'; Tipo = 'joystick'; Por = 'actualiza el firmware de tu joystick y deja cambiar los botones y los perfiles'; Corto = 'Firmware y botones' }
        )
        $vistosAp = @()
        foreach ($ap in $aparatos) {
            $nom = @(& $nombresDe $ap.Vid)
            if ($nom.Count -eq 0) { continue }
            if ($ap.Nombre) { $nom = @($nom | Where-Object { $_ -match ('(?i)' + $ap.Nombre) }); if ($nom.Count -eq 0) { continue } }
            if ($vistosAp -contains $ap.Que) { continue }
            $vistosAp += $ap.Que
            if ((-not $prueba) -and ($progs -match ('(?i)' + $ap.Prog))) { Log 'OK' ($ap.Que + ' ya esta instalado'); continue }
            Log 'INFO' ('aparato: ' + ($nom -join ', ') + ' - falta ' + $ap.Que)
            Reco $ap.Que $ap.Por @() $(if ($ap.Link) { $ap.Link } else { 'https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky ' + $ap.Que + ' download') })
            Corto $ap.Tipo $ap.Que $ap.Corto
        }

        # 4f) Discos SSD: el programa de la marca actualiza el firmware (algunos SSD tuvieron fallas que solo se arreglaban asi) y muestra su salud
        $ssdProgs = @(
            @{ Rx = '(?i)Samsung'; Que = 'Samsung Magician'; Prog = 'Samsung Magician' },
            @{ Rx = '(?i)^WD|WDC|Western Digital'; Que = 'Western Digital Dashboard'; Prog = 'WD Dashboard|Western Digital Dashboard' },
            @{ Rx = '(?i)SanDisk'; Que = 'SanDisk Dashboard'; Prog = 'SanDisk Dashboard|WD Dashboard|Western Digital Dashboard' },
            @{ Rx = '(?i)Crucial|^CT\d'; Que = 'Crucial Storage Executive'; Prog = 'Storage Executive' },
            @{ Rx = '(?i)Kingston|^SNV|^SKC|^SA400|^SFYR'; Que = 'Kingston SSD Manager'; Prog = 'SSD Manager' }
        )
        $discosSsd = @(); try { $discosSsd = @(Get-PhysicalDisk -ErrorAction Stop | Where-Object { ([string]$_.MediaType -eq 'SSD') -or ([string]$_.BusType -eq 'NVMe') }) } catch { }
        $vistosSsd = @()
        foreach ($dsk in $discosSsd) {
            $mod = ([string]$dsk.FriendlyName).Trim()
            foreach ($sx in $ssdProgs) {
                if ($mod -notmatch $sx.Rx) { continue }
                if ($vistosSsd -contains $sx.Que) { break }
                $vistosSsd += $sx.Que
                if ((-not $prueba) -and ($progs -match ('(?i)' + $sx.Prog))) { Log 'OK' ($sx.Que + ' ya esta instalado (' + $mod + ')'); break }
                Reco $sx.Que ('para tu ' + $mod + ': actualiza el firmware del disco (arregla fallas) y te muestra su salud') @() ('https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky ' + $sx.Que + ' download'))
                Corto 'disco' $sx.Que ('Firmware y salud de tu ' + $mod)
                break
            }
        }

        # 5) BIOS de la placa madre: si tiene mas de un ano, conviene buscar la version recomendada
        $bb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
        $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        $biosVieja = $false; $biosLink = ''
        if ($bb -and $bios) {
            $marca = ([string]$bb.Manufacturer).Trim(); $modelo = ([string]$bb.Product).Trim()
            $fb = $null; try { $fb = [datetime]$bios.ReleaseDate } catch { }
            $meses = $(if ($fb) { [int](((Get-Date) - $fb).TotalDays / 30.4) } else { -1 })
            $q = [uri]::EscapeDataString($modelo)
            # Va directo a la pagina de soporte de tu placa en el sitio de la marca (el primer resultado de DuckDuckGo en ese sitio)
            $sitio = $(switch -Regex ($marca) { 'ASUS' { 'asus.com' } 'Micro-Star|MSI' { 'msi.com' } 'Gigabyte' { 'gigabyte.com' } 'ASRock' { 'asrock.com' } 'Biostar' { 'biostar.com.tw' } default { '' } })
            $biosLink = $(if ($sitio) { 'https://duckduckgo.com/?q=' + [uri]::EscapeDataString('!ducky site:' + $sitio + ' ' + $modelo + ' support BIOS') } else { 'https://www.google.com/search?q=' + [uri]::EscapeDataString($marca + ' ' + $modelo + ' BIOS') })
            Say ''
            Say ('  Placa madre: ' + $marca + ' ' + $modelo + '  -  BIOS ' + ([string]$bios.SMBIOSBIOSVersion).Trim() + $(if ($fb) { ' (' + $fb.ToString('dd/MM/yyyy') + ')' } else { '' }))
            if (($meses -ge 12) -or $prueba) {
                $biosVieja = $true
                Say ('  Tu BIOS tiene ' + $meses + ' meses: conviene buscar la version recomendada en la pagina de tu placa.') 'Yellow'
                Say '  La BIOS se actualiza a mano (desde la pagina o con la herramienta de la BIOS). No apagues la PC mientras se actualiza.' 'Yellow'
            } elseif ($meses -ge 0) { Say '  Tu BIOS es reciente.' 'Green' }
        }

        # Luces RGB de la placa: el programa de cada marca, opcional (no se abre su pagina, solo se nombra)
        if ($bb) {
            $rgb = $(switch -Regex ([string]$bb.Manufacturer) { 'ASUS' { 'Armoury Crate (Aura Sync)' } 'Micro-Star|MSI' { 'MSI Center (Mystic Light)' } 'Gigabyte' { 'RGB Fusion' } 'ASRock' { 'Polychrome Sync' } default { '' } })
            $rgbHay = ($progs -match '(?i)Armoury|Aura|MSI Center|Mystic Light|Control Center|RGB Fusion|Polychrome|OpenRGB|SignalRGB')
            $rgbLink = $(switch -Regex ([string]$bb.Manufacturer) { 'ASUS' { 'https://rog.asus.com/armoury-crate/' } 'Micro-Star|MSI' { 'https://www.msi.com/Landing/MSI-Center' } 'Gigabyte' { 'https://www.gigabyte.com/microsite/512/rgb2.html' } default { $biosLink } })
            if ($rgb -and ($prueba -or (-not $rgbHay))) { Reco ('Opcional: ' + $rgb) ('solo si tu placa tiene luces y queres cambiarles el color o apagarlas: ' + $rgbLink + ' . Si no te importan las luces, no lo instales (corre en segundo plano)') @() $rgbLink; Corto 'rgb' ('Luces RGB (opcional)') ($rgb + ': solo si te importan las luces'); Sin-Abrir }
        }

        # El link de la placa madre se arma con la marca y el modelo
        foreach ($r in $reco) { if ($r.Link -eq '#placa') { $r.Link = $biosLink } }

        # Resumen
        Say ''
        if (($reco.Count -eq 0) -and ($wuDrv.Count -eq 0)) {
            Say '  No hace falta instalar nada: tu PC ya tiene los drivers que aportan algo.' 'Green'
            Log 'OK' 'no hace falta ningun driver'
            $code = 5
        } else {
            Say '  Recomendado para tu PC:' 'Cyan'
            foreach ($w in $wuDrv) { Say ('    - ' + $w.Title + '  (Windows Update)') }
            foreach ($r in $reco) {
                Say ('    - ' + $r.Que + ': ' + $r.Por)
                foreach ($x in @($r.Sub)) { if ($x) { Say ('      + ' + $x) } }
            }
        }

        # Para la app: una linea por cajita (tipo|titulo|frase) y sus items
        if ($desdeApp) {
            if (($reco.Count -eq 0) -and ($wuDrv.Count -eq 0) -and (-not $biosVieja)) { Say 'XDRV|ok|Todo al dia|Tu PC ya tiene los drivers que aportan algo' }
            if ($wuDrv.Count -gt 0) { Say ('XDRV|wu|Windows Update|' + $wuDrv.Count + ' drivers para lo que no anda: instalalos en Actualizaciones opcionales') }
            foreach ($r in $reco) {
                Say ('XDRV|' + $r.Tipo + '|' + ($r.Titulo -replace '\|', '/') + '|' + ($r.Corto -replace '\|', '/'))
                if ([string]$r.Link -match '^https://') { Say ('XDRVLINK|' + $r.Link) }
                foreach ($x in @($r.Sub)) { if ($x) { Say ('XDRVSUB|' + ($x -replace '\|', '/')) } }
            }
            if ($biosVieja) { Say ('XDRV|bios|BIOS de tu placa|' + $(if ($meses -ge 0) { 'Tiene ' + $meses + ' meses: ' } else { '' }) + 'busca la version nueva en la pagina de tu placa'); if ([string]$biosLink -match '^https://') { Say ('XDRVLINK|' + $biosLink) } }
        }

        # Drivers de Windows Update para lo que no anda
        if ($wuDrv.Count -gt 0) {
            Say ''
            if ($desdeApp) {
                Say '  Estan en Windows Update > Opciones avanzadas > Actualizaciones opcionales: te abro esa pagina.' 'Yellow'
            } elseif ((Read-Host '  Instalo los drivers que faltan desde Windows Update? (S/N)') -match '^[sS]') {
                try {
                    $col = New-Object -ComObject Microsoft.Update.UpdateColl
                    foreach ($w in $wuDrv) { [void]$col.Add($w) }
                    $dl = $ses.CreateUpdateDownloader(); $dl.Updates = $col; [void]$dl.Download()
                    $ins = $ses.CreateUpdateInstaller(); $ins.Updates = $col; $rr = $ins.Install()
                    Log 'OK' ('Windows Update instalo los drivers (resultado ' + $rr.ResultCode + ')')
                    Say ('  Drivers de Windows Update instalados: ' + $wuDrv.Count) 'Green'
                    if ($rr.RebootRequired) { Say '  Reinicia la PC para terminar.' 'Yellow' }
                } catch { Log 'FALLO' ('Windows Update: ' + $_.Exception.Message); $code = 1 }
            }
        }

        # Se abre la pagina oficial de cada cosa recomendada (y la de la BIOS si esta vieja), ahi esta siempre la ultima version
        $paginas = @($reco | Where-Object { $_.Link -and ($prueba -or $_.Abrir) } | ForEach-Object { $_.Link } | Select-Object -Unique)
        # La BIOS vieja es para actualizar (no falta nada): su pagina se abre solo en la prueba
        if ($biosVieja -and $biosLink -and $prueba) { $paginas += $biosLink }
        if ($desdeApp -and ($wuDrv.Count -gt 0)) { $paginas += 'ms-settings:windowsupdate-optionalupdates' }
        $paginas = @($paginas | Select-Object -Unique)
        # Si hay algo para mostrar (aunque sea opcional o solo viejo) pero ninguna pagina que abrir, se abre la de tu placa madre
        if (($paginas.Count -eq 0) -and (($reco.Count -gt 0) -or $biosVieja) -and $biosLink) { $paginas = @($biosLink); Log 'INFO' 'nada falta: se abre la pagina de la placa madre igual' }
        if ($paginas.Count -gt 0) {
            Say ''
            if ($desdeApp -or ((Read-Host ('  Abro las paginas oficiales para bajar lo recomendado (' + $paginas.Count + ')? (S/N)')) -match '^[sS]')) {
                $pri = $true
                foreach ($u in $paginas) {
                    # El navegador pierde pestanas si se le mandan todas juntas (sobre todo si estaba cerrado)
                    if (-not $pri) { Start-Sleep -Milliseconds 1500 }
                    Abrir-Pagina $u; Log 'OK' ('pagina abierta: ' + $u); $pri = $false
                    if ($paginas.Count -gt 1) { Start-Sleep -Milliseconds 1000 }
                }
                Say ('  Paginas abiertas: ' + $paginas.Count) 'Green'
            }
        }
    }

    'CHROME_INSTALL' {
        $rutas = @(($env:ProgramFiles + '\Google\Chrome\Application\chrome.exe'), (${env:ProgramFiles(x86)} + '\Google\Chrome\Application\chrome.exe'), ($env:LOCALAPPDATA + '\Google\Chrome\Application\chrome.exe'))
        $chrome = $rutas | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($chrome) {
            Log 'OK' ('Chrome ya estaba instalado en ' + $chrome)
            Say '  Google Chrome ya estaba instalado.' 'Yellow'
            $code = 5
        } else {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Say '  Instalando Google Chrome con winget...'
                & winget install -e --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements | Out-Null
                Log 'INFO' ('winget install Google.Chrome termino con codigo ' + $LASTEXITCODE)
            } else {
                Log 'FALLO' 'winget no esta disponible en esta PC'
            }
            $chrome = $rutas | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
            if ($chrome) { Log 'OK' ('verificado: Chrome instalado en ' + $chrome) }
            else { Log 'FALLO' 'Chrome no quedo instalado'; $code = 1 }
        }
    }

    'EDGE_BACK' {
        if (Test-Path -LiteralPath (${env:ProgramFiles(x86)} + '\Microsoft\Edge\Application\msedge.exe')) {
            Log 'OK' 'ya estaba: Edge instalado'
            $code = 5
        } else {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                & winget install -e --id Microsoft.Edge --silent --accept-package-agreements --accept-source-agreements | Out-Null
                Log 'INFO' ('winget install Microsoft.Edge termino con codigo ' + $LASTEXITCODE)
            } else {
                Log 'FALLO' 'winget no esta disponible en esta PC'
                $code = 1
            }
            if (Test-Path -LiteralPath (${env:ProgramFiles(x86)} + '\Microsoft\Edge\Application\msedge.exe')) { Log 'OK' 'verificado: Edge instalado' }
            else { Log 'FALLO' 'Edge no quedo instalado'; $code = 1 }
        }
    }

    'WIN_UPGRADE' {
        if (-not ('XucaWin.Cpu' -as [type])) {
Add-Type -Namespace XucaWin -Name Cpu -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern bool IsProcessorFeaturePresent(uint feature);
'@
        }
        $sigo = $true
        if (-not [Environment]::Is64BitOperatingSystem) {
            Log 'FALLO' 'Windows de 32 bits: no se puede pasar a Windows 11'
            $sigo = $false
            $code = 1
        } elseif ((-not [XucaWin.Cpu]::IsProcessorFeaturePresent(38)) -or (-not [XucaWin.Cpu]::IsProcessorFeaturePresent(14))) {
            Log 'INFO' 'el CPU no declara SSE4.2 o CMPXCHG16B'
            Say '  Parece que tu CPU no tiene SSE4.2 o CMPXCHG16B. Sin eso Windows 11 24H2 o mas nuevo no arranca.'
            $f = Read-Host '  Escribi FORZAR para seguir igual (cualquier otra cosa cancela)'
            if ($f -cne 'FORZAR') { $sigo = $false; $code = 4 }
        }
        if ($sigo) {
            Say ''
            Say '  Descarga el ISO oficial de Windows 11 25H2 en:'
            Say '  https://www.microsoft.com/software-download/windows11  (Descargar imagen de disco ISO)'
            $r = ([string](Read-Host '  Pega la ruta del archivo .iso (Enter = abrir esa pagina y cancelar)')).Trim().Trim('"')
            if (-not $r) {
                Abrir-Pagina 'https://www.microsoft.com/software-download/windows11'
                Log 'INFO' 'sin ISO: se abrio la pagina de descarga'
                $code = 4
            } elseif ((-not (Test-Path -LiteralPath $r)) -or ($r -notlike '*.iso')) {
                Log 'FALLO' ('no existe o no es un .iso: ' + $r)
                $code = 1
            } else {
                $d = $null
                try {
                    $img = Mount-DiskImage -ImagePath $r -PassThru -ErrorAction Stop
                    $letra = [string](Get-Volume -DiskImage $img).DriveLetter
                    if ($letra) { $d = $letra + ':' }
                } catch {
                    Log 'FALLO' ('no se pudo montar el ISO: ' + $_.Exception.Message)
                    $code = 1
                }
                if ($d) {
                    $wim = $d + '\sources\install.wim'
                    if (-not (Test-Path -LiteralPath $wim)) { $wim = $d + '\sources\install.esd' }
                    $bld = 0
                    try { $bld = ([version](Get-WindowsImage -ImagePath $wim -Index 1 -ErrorAction Stop).Version).Build } catch { }
                    if ((-not (Test-Path -LiteralPath ($d + '\setup.exe'))) -or (-not (Test-Path -LiteralPath $wim))) {
                        Log 'FALLO' 'el ISO no parece ser un instalador de Windows'
                        $code = 1
                    } elseif (($bld -gt 0) -and ($bld -lt 26100)) {
                        Log 'FALLO' ('el ISO es de una version vieja (build ' + $bld + '), hace falta 24H2 o 25H2')
                        $code = 1
                    } else {
                        Log 'INFO' ('ISO montado en ' + $d + ' - build ' + $bld)
                        $claves = @(
                            @{ P = 'HKLM:\SYSTEM\Setup\MoSetup'; N = 'AllowUpgradesWithUnsupportedTPMOrCPU' },
                            @{ P = 'HKLM:\SYSTEM\Setup\LabConfig'; N = 'BypassTPMCheck' },
                            @{ P = 'HKLM:\SYSTEM\Setup\LabConfig'; N = 'BypassSecureBootCheck' },
                            @{ P = 'HKLM:\SYSTEM\Setup\LabConfig'; N = 'BypassRAMCheck' },
                            @{ P = 'HKLM:\SYSTEM\Setup\LabConfig'; N = 'BypassStorageCheck' },
                            @{ P = 'HKLM:\SYSTEM\Setup\LabConfig'; N = 'BypassCPUCheck' }
                        )
                        foreach ($b in $claves) {
                            if (-not (Test-Path -LiteralPath $b.P)) { New-Item -Path $b.P -Force | Out-Null }
                            Set-ItemProperty -Path $b.P -Name $b.N -Value 1 -Type DWord -ErrorAction SilentlyContinue
                            $v = (Get-ItemProperty -Path $b.P -ErrorAction SilentlyContinue).($b.N)
                            if ($v -eq 1) { Log 'OK' ('verificado: ' + $b.N + ' = 1') }
                            else { Log 'FALLO' ('no se pudo escribir ' + $b.N); $code = 1 }
                        }
                        if ($code -eq 0) {
                            Say ''
                            Say '  Ultimo aviso: hace backup de tus archivos importantes antes de seguir.'
                            $c = Read-Host '  Escribi UPGRADE para empezar (cualquier otra cosa cancela)'
                            if ($c -ceq 'UPGRADE') {
                                Start-Process -FilePath ($d + '\setup.exe') -ArgumentList '/product', 'server', '/auto', 'upgrade', '/dynamicupdate', 'disable', '/compat', 'ignorewarning', '/eula', 'accept', '/showoobe', 'none'
                                Log 'OK' 'setup.exe de Windows 11 lanzado con /product server'
                                $code = 3
                            } else {
                                Log 'INFO' 'actualizacion cancelada en la confirmacion final'
                                $code = 4
                            }
                        }
                    }
                    if ($code -ne 3) {
                        foreach ($b in $claves) { Remove-ItemProperty -Path $b.P -Name $b.N -ErrorAction SilentlyContinue }
                        Dismount-DiskImage -ImagePath $r -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            }
        }
    }

    'SPI' {
        if (-not ('SpiNative' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SpiNative {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
'@
        }
        $flags = 3
        $M = [System.Runtime.InteropServices.Marshal]
        foreach ($t in ($XDato -split ';')) {
            if (-not $t) { continue }
            $p = $t -split ':'
            $r = $false
            switch ($p[0]) {
                'P' { $r = [SpiNative]::SystemParametersInfo([Convert]::ToUInt32($p[1], 16), 0, [IntPtr][int]$p[2], $flags) }
                'U' { $r = [SpiNative]::SystemParametersInfo([Convert]::ToUInt32($p[1], 16), [uint32]$p[2], [IntPtr]::Zero, $flags) }
                'A' {
                    $buf = $M::AllocHGlobal(8)
                    $M::WriteInt32($buf, 0, 8)
                    $M::WriteInt32($buf, 4, [int]$p[1])
                    $r = [SpiNative]::SystemParametersInfo(0x49, 8, $buf, $flags)
                    $M::FreeHGlobal($buf)
                }
            }
            if ($r) { Log 'OK' ('SystemParametersInfo ' + $t) }
            else { Log 'FALLO' ('SystemParametersInfo ' + $t); $code = 1 }
        }
    }


    }
    } | Out-Null
    if ($global:XMal -and ($code -eq 0)) { $code = 1 }
    return $code
}

# Corre una accion y devuelve su codigo (si se rompe, queda como PS-ERROR en el log)
function Act([string]$a, [string]$dato = '', [bool]$chk = $false) { return (Hacer { Debloat-Act $a $dato $chk } $a) }

# ------------------------------------------------------------
# Las opciones, en el orden en que se aplican. La app arma las casillas con Id, Seccion, Q, Hace, Favor y Contra.
# Las de Herramientas (ver, rp, drv, ms_acc, al, cta) no tienen casilla: la app las corre desde sus botones.
# ------------------------------------------------------------

$ListaOpciones = @(
    @{
        Id = 'ver'; Seccion = 'VERSION DE WINDOWS'
        Q = '- Desea forzar la actualizacion a Windows 11 25H2? (Pide el ISO oficial e ignora los requisitos de hardware)'
        Hace = 'instala Windows 11 25H2 desde el ISO oficial aunque tu PC no cumpla los requisitos.'
        Favor = 'tenes la version nueva con sus mejoras y parches de seguridad.'
        Contra = 'tarda cerca de una hora, no es un camino oficial y en PCs no compatibles puede fallar.'
        Antes = {
            ''
            '  Tenes una version de Windows mas vieja que la 24H2 [build ' + $script:Build + '].'
            '  Se puede forzar la actualizacion a Windows 11 25H2 aunque tu PC no sea compatible.'
            '  - Actualiza todo Windows y conserva tus archivos y programas.'
            '  - Tarda cerca de una hora y reinicia varias veces. Hace backup antes.'
            '  - No es un camino oficial de Microsoft: puede fallar en PCs no compatibles.'
            '  - Piso que no se puede saltear: CPU de 64 bits con SSE4.2, 4 GB de RAM y 64 GB de disco.'
            '  - Necesitas el ISO oficial de Windows 11 25H2 de microsoft.com.'
            '  - Despues, la 26H2 te llega por Windows Update con un reinicio corto.'
        }
        Saltar = {
            return (-not (($script:Build -gt 0) -and ($script:Build -lt 26100)))
        }
        S = {
            Opt-Ini 'Actualizar a Windows 11 25H2'
            $c = Act 'WIN_UPGRADE'
            if ($c -ge 4) {
                Log 'INFO' 'actualizacion cancelada'
                Say '  Actualizacion cancelada, no se cambio nada.' 'Yellow'
                return
            }
            if ($c -eq 3) {
                Log 'LISTO' 'instalador de Windows 11 lanzado'
                Say ''
                Say '  El instalador de Windows 11 quedo abierto. No apagues la PC.'
                Say '  Cuando termine y vuelvas al escritorio, abri la app de nuevo para aplicar las optimizaciones.'
                $script:Parar = $true
                return
            }
            Resps $c
            Opt-Fin 'Actualizacion preparada'
        }
    },
    @{
        Id = 'ver'; Seccion = 'VERSION DE WINDOWS'
        Q = '- Desea actualizar a Windows 11 26H2? (Por Windows Update, con reinicio corto)'
        Hace = 'le pide a Windows Update la version 26H2.'
        Favor = 'es una actualizacion chica, con un solo reinicio corto, y usa menos RAM.'
        Contra = 'ninguno importante; como toda actualizacion, conviene tener backup.'
        Antes = {
            ''
            '  Tenes Windows 11 24H2 o 25H2 [build ' + $script:Build + ']. La 26H2 es una actualizacion chica que no revisa el hardware de nuevo.'
        }
        Saltar = {
            if ($script:Build -ge 26300) { Log 'INFO' ('la version de Windows ya es 26H2 o mas nueva - build ' + $script:Build); return $true }
            return ($script:Build -lt 26100)
        }
        S = {
            Opt-Ini 'Actualizar a Windows 11 26H2'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'TargetReleaseVersion' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ProductVersion' 'REG_SZ' 'Windows 11'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'TargetReleaseVersionInfo' 'REG_SZ' '26H2'
            & UsoClient.exe StartScan 2>&1 | Out-Null
            Log 'INFO' 'UsoClient StartScan lanzado'
            Abrir-Pagina 'ms-settings:windowsupdate'
            Say '  Se abrio Windows Update: instala lo que aparezca y reinicia.'
            Say '  Si todavia no te ofrece la 26H2, volve a buscar en unos dias: Microsoft la va liberando de a poco.'
            Opt-Fin 'Windows 11 26H2 pedida a Windows Update'
        }
    },
    @{
        Id = 'rpo'; Seccion = 'PUNTOS DE RESTAURACION'
        Q = '- Desea apagar los puntos de restauracion para siempre? (Libera espacio; R los vuelve a encender)'
        Hace = 'apaga para siempre los puntos de restauracion y borra los que ya tenes.'
        Favor = 'libera espacio en el disco y Windows deja de escribir copias en segundo plano.'
        Contra = 'si algo sale mal ya no vas a poder volver atras con un punto de restauracion.'
        S = {
            Opt-Ini 'Puntos de restauracion apagados'
            Resps (Act 'RP_OFF')
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' 'DisableSR' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' 'DisableConfig' 'REG_DWORD' '1'
            Opt-Fin 'Puntos de restauracion apagados para siempre'
            $script:RpApagado = $true
        }
        R = {
            Opt-Ini 'Puntos de restauracion apagados (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' 'DisableSR'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' 'DisableConfig'
            Resps (Act 'RP_ON')
            Opt-Fin 'Puntos de restauracion encendidos de nuevo'
        }
    },
    @{
        Id = 'rp'; Seccion = 'PUNTOS DE RESTAURACION'
        Q = '- Desea crear un punto de restauracion? (Para volver atras si algo sale mal)'
        Hace = 'guarda una copia del estado de Windows antes de los cambios del script.'
        Favor = 'si algo sale mal, volves atras en unos minutos.'
        Contra = 'ocupa algo de espacio en el disco.'
        Saltar = {
            # Solo si la app lo pidio (no se pregunta si recien se apagaron los puntos de restauracion)
            if ($script:RpApagado -or ((Respuesta 'rp') -ne 'S')) { return $true }
            return ((Act 'RP_CHECK') -ge 5)
        }
        S = {
            Opt-Ini 'Punto de restauracion'
            Resps (Act 'RP_CREATE')
            Opt-Fin 'Punto de restauracion creado'
        }
    },
    @{
        Id = 'av'; Seccion = 'SEGURIDAD'
        Q = '- Desea apagar TODO el antivirus? (Defender, SmartScreen y Smart App Control; la PC queda sin proteccion)'
        Hace = 'apaga Defender, SmartScreen y Smart App Control.'
        Favor = 'menos uso de CPU y disco, y ningun analisis en medio de una partida.'
        Contra = 'la PC queda sin proteccion contra virus y Smart App Control no se vuelve a encender sin reinstalar Windows.'
        Antes = {
            'AVISO: si tenes Riot Vanguard, se borra solo si una opcion de seguridad cambia algo de verdad (si ya la tenias asi, no se toca); se desinstala del todo, se cierra Riot y lo volves a instalar abriendo el cliente de Riot.'
            ''
            'AVISO: Smart App Control no se puede volver a encender sin reinstalar Windows.'
            'AVISO: la Proteccion contra alteraciones la apagas vos; el script abre la pagina.'
            'AVISO: con R, volve a activar la Proteccion contra alteraciones en Seguridad de Windows.'
        }
        S = {
            Opt-Ini 'Antivirus de Windows'
            Say '  Revisando el estado del antivirus, un momento...'
            if ((Act 'AV_OFF' '' $true) -ge 5) {
                Av-RegsOff
                $script:OptS++
                Opt-Fin 'Antivirus, SmartScreen y Smart App Control desactivados'
                return
            }
            Say ''
            Say '  Apaga ahora la Proteccion contra alteraciones: se abre la pagina de Seguridad de Windows.'
            Say '  Cuando la apagues, volve aca.'
            Av-RegsOff
            Resps (Act 'AV_OFF')
            Opt-Fin 'Antivirus, SmartScreen y Smart App Control desactivados'
            if ($script:OptF -gt 0) { Say '  Si algo fallo, casi seguro la Proteccion contra alteraciones sigue encendida: apagala y repeti.' 'Red' }
            Vanguard-Check
        }
        R = {
            Opt-Ini 'Antivirus de Windows (restaurar)'
            Av-RegsOn
            Resps (Act 'AV_ON')
            Opt-Fin 'Antivirus y SmartScreen restaurados'
        }
    },
    @{
        Id = 'bl'; Seccion = 'SEGURIDAD'
        Q = '- Desea desactivar BitLocker? (Descifra el disco; con R solo se quita el bloqueo)'
        Hace = 'descifra el disco y evita que Windows lo vuelva a cifrar solo.'
        Favor = 'un poco mas de velocidad de disco y no te bloquea el acceso si cambias hardware o la BIOS.'
        Contra = 'si te roban la PC, pueden leer tus archivos.'
        S = {
            Opt-Ini 'BitLocker'
            Resps (Act 'BL_OFF')
            # Para Vanguard solo cuenta si el disco se empezo a descifrar ahora (no el bloqueo de abajo)
            $vgt = $script:OptT
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
            Opt-Fin 'BitLocker desactivado (el descifrado sigue en segundo plano)'
            Vanguard-Check $vgt
        }
        R = {
            Opt-Ini 'BitLocker (restaurar)'
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption'
            Opt-Fin 'Se quito el bloqueo de BitLocker. Windows puede volver a cifrar el disco por su cuenta'
        }
    },
    @{
        Id = 'hib'; Seccion = 'ALMACENAMIENTO Y MEMORIA'
        Q = '- Desea desactivar la hibernacion? (Libera espacio, apaga el Inicio rapido y activa la compresion de memoria)'
        Hace = 'apaga la hibernacion y el Inicio rapido, y activa la compresion de memoria.'
        Favor = 'libera varios GB del disco y cada apagado es completo, con menos errores raros.'
        Contra = 'prender la PC desde apagada tarda unos segundos mas.'
        S = {
            Opt-Ini 'Hibernacion'
            Resps (Act 'HIB_OFF')
            Opt-Fin 'Hibernacion desactivada y compresion de memoria activa'
        }
        R = {
            Opt-Ini 'Hibernacion (restaurar)'
            Resps (Act 'HIB_ON')
            Opt-Fin 'Hibernacion restaurada'
        }
    },
    @{
        Id = 'rc'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea desactivar Recall? (Capturas de pantalla con IA; solo en PCs Copilot+)'
        Hace = 'apaga Recall, que saca capturas de lo que haces para buscarlo con IA.'
        Favor = 'mas privacidad y menos uso de disco y CPU.'
        Contra = 'perdes esa busqueda por capturas; solo existe en PCs Copilot+.'
        S = {
            Opt-Ini 'Recall'
            Say '  Revisando si Recall existe en esta PC, un momento...'
            $c = Act 'RECALL_OFF'
            if (($c -ge 2) -and ($c -lt 5)) {
                Log 'OMITIDO' 'Recall no existe en esta PC: no se toco nada'
                Say '  Recall no existe en esta PC, no se toco nada.' 'Yellow'
                return
            }
            if ($c -lt 5) { Resps $c }
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 'REG_DWORD' '1'
            Reg-Set 'HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 'REG_DWORD' '1'
            Opt-Fin 'Recall desactivado'
        }
        R = {
            Opt-Ini 'Recall (restaurar)'
            Say '  Revisando si Recall existe en esta PC, un momento...'
            $c = Act 'RECALL_ON'
            if (($c -ge 2) -and ($c -lt 5)) {
                Log 'OMITIDO' 'Recall no existe en esta PC: no se toco nada'
                Say '  Recall no existe en esta PC, no se toco nada.' 'Yellow'
                return
            }
            if ($c -lt 5) { Resps $c }
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis'
            Reg-Del 'HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis'
            Opt-Fin 'Recall restaurado'
        }
    },
    @{
        Id = 'sch'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea silenciar los sonidos de Windows? (Incluye el sonido de inicio; deja solo conectar y desconectar dispositivos, como un USB)'
        Hace = 'silencia los sonidos de Windows y el de inicio; quedan solo los de conectar y desconectar dispositivos.'
        Favor = 'no te suenan avisos en medio de una partida o un stream.'
        Contra = 'no escuchas las alertas del sistema.'
        S = {
            Opt-Ini 'Sonidos de Windows'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' 'DisableStartupSound' 'REG_DWORD' '1'
            Resps (Act 'SND_OFF')
            Opt-Fin 'Sonidos de Windows silenciados (solo quedan conectar y desconectar dispositivos)'
        }
        R = {
            Opt-Ini 'Sonidos de Windows (restaurar)'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' 'DisableStartupSound' 'REG_DWORD' '0'
            Resps (Act 'SND_ON')
            Opt-Fin 'Sonidos de Windows restaurados (Predeterminado de Windows)'
        }
    },
    @{
        Id = 'fx'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea reducir los efectos visuales? (Sin animaciones, atenuados ni transparencias)'
        Hace = 'quita animaciones, sombras, atenuados y transparencias.'
        Favor = 'Windows se siente mas rapido y usa un poco menos la placa de video.'
        Contra = 'Windows se ve mas simple.'
        S = {
            Opt-Ini 'Efectos visuales'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewAlphaSelect' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'IconsOnly' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Control Panel\Desktop\WindowMetrics' 'MinAnimate' 'REG_SZ' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\DWM' 'AlwaysHibernateThumbnails' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 'REG_DWORD' '3'
            if ($script:OptT -gt 0) { Resps (Act 'SPI' 'P:0x1043:0;P:0x1015:0;P:0x1017:0;P:0x1003:0;P:0x1007:0;A:0;P:0x1005:1;U:0x0025:1;P:0x101B:0;P:0x1025:1;U:0x004B:1;P:0x200B:2;') }
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 'REG_DWORD' '0'
            Opt-Fin 'Efectos visuales reducidos'
        }
        R = {
            Opt-Ini 'Efectos visuales (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewAlphaSelect' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'IconsOnly' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Control Panel\Desktop\WindowMetrics' 'MinAnimate' 'REG_SZ' '1'
            Reg-Del 'HKCU\Software\Microsoft\Windows\DWM' 'AlwaysHibernateThumbnails'
            Reg-Set 'HKCU\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 'REG_DWORD' '0'
            if ($script:OptT -gt 0) { Resps (Act 'SPI' 'P:0x1043:1;P:0x1015:1;P:0x1017:1;P:0x1003:1;P:0x1007:1;A:1;P:0x1005:1;U:0x0025:1;P:0x101B:1;P:0x1025:1;U:0x004B:1;P:0x200B:2;') }
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 'REG_DWORD' '1'
            Opt-Fin 'Efectos visuales restaurados'
        }
    },
    @{
        Id = 'et'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea agregar Finalizar tarea al clic derecho de la barra? (Cierra programas trabados)'
        Hace = 'agrega Finalizar tarea al clic derecho de la barra de tareas.'
        Favor = 'cerras un juego o programa trabado sin abrir el Administrador de tareas.'
        Contra = 'ninguno.'
        Saltar = {
            # Finalizar tarea en la barra existe desde Windows 11 22H2 (build 22621)
            if (($script:Build -gt 0) -and ($script:Build -lt 22621)) { Log 'SALTADO' ('Finalizar tarea: necesita Windows 11 22H2 o mas nuevo - build ' + $script:Build); return $true }
            return $false
        }
        S = {
            Opt-Ini 'Finalizar tarea'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 'REG_DWORD' '1'
            Opt-Fin 'Finalizar tarea agregado al clic derecho'
        }
        R = {
            Opt-Ini 'Finalizar tarea (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 'REG_DWORD' '0'
            Opt-Fin 'Finalizar tarea quitado del clic derecho'
        }
    },
    @{
        Id = 'cal'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea quitar el calendario del reloj? (La fecha y hora se siguen viendo, pero al tocarlas no se abre nada)'
        Hace = 'la fecha y la hora de la barra se siguen viendo, pero al tocarlas ya no se abre el calendario ni el centro de notificaciones.'
        Favor = 'no se abre el panel sin querer en medio de una partida y la barra queda igual.'
        Contra = 'no ves el calendario ni el historial de notificaciones; Win + N tampoco lo abre.'
        S = {
            Opt-Ini 'Calendario del reloj'
            if (($script:Build -gt 0) -and ($script:Build -lt 22000)) {
                Log 'OMITIDO' 'en Windows 10 el calendario del reloj no se puede quitar: no se toco nada'
                Say '  En Windows 10 el calendario del reloj no se puede quitar, no se toco nada.' 'Yellow'
                return
            }
            Reg-Set 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter' 'REG_DWORD' '1'
            if ($script:OptT -gt 0) { Act 'EXPLORER_RESTART' | Out-Null }
            Opt-Fin 'Calendario quitado del reloj: la fecha y hora se siguen viendo'
        }
        R = {
            Opt-Ini 'Calendario del reloj (restaurar)'
            Reg-Del 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableNotificationCenter'
            if ($script:OptT -gt 0) { Act 'EXPLORER_RESTART' | Out-Null }
            Opt-Fin 'Calendario del reloj restaurado'
        }
    },
    @{
        Id = 'apps'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea bloquear las apps de la Store en segundo plano? (Ahorra RAM)'
        Hace = 'no deja que las apps de la Store sigan corriendo cuando no las usas.'
        Favor = 'ahorra RAM y CPU.'
        Contra = 'algunas apps no te avisan de nada hasta que las abris.'
        S = {
            Opt-Ini 'Apps en segundo plano'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 'REG_DWORD' '2'
            Opt-Fin 'Apps de la Store bloqueadas en segundo plano'
        }
        R = {
            Opt-Ini 'Apps en segundo plano (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground'
            Opt-Fin 'Apps de la Store restauradas en segundo plano'
        }
    },
    @{
        Id = 'ini'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea apagar las apps basura de inicio? (Las que se abren solas al prender la PC; no toca drivers, perifericos ni Wallpaper Engine)'
        Hace = 'apaga los programas que se abren solos al prender la PC (Discord, Spotify, Steam, Epic, Teams, OneDrive, Edge y parecidos). No toca lo de Windows, drivers, paneles de mouse, teclado, auriculares y RGB (Logitech, Razer, SteelSeries Sonar, Corsair...), Wallpaper Engine, antivirus, VPN ni antitrampas.'
        Favor = 'la PC prende mas rapido y queda mas RAM libre.'
        Contra = 'esos programas ya no se abren solos: los abris vos cuando los necesitas.'
        S = {
            Opt-Ini 'Apps de inicio'
            Resps (Act 'INICIO_OFF')
            Opt-Fin 'Apps basura de inicio apagadas'
        }
        R = {
            Opt-Ini 'Apps de inicio (restaurar)'
            Resps (Act 'INICIO_ON')
            Opt-Fin 'Apps de inicio restauradas'
        }
    },
    @{
        Id = 'tel'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea reducir la telemetria y recibir las actualizaciones mas recientes de Windows para menor uso de ram (26H2)?'
        Hace = 'apaga el servicio que manda datos a Microsoft y sus tareas (diagnostico de discos y de energia, cola de errores, copia de MAR, medicion de inicio y mapas), y deja el nivel que Windows pide para recibir antes las versiones nuevas.'
        Favor = 'menos procesos de fondo usando disco y CPU, y recibis primero la 26H2, que usa menos RAM.'
        Contra = 'no es un apagado total de los datos: es el punto medio para seguir recibiendo lo nuevo. El Administrador de tareas deja de medir el impacto de inicio de los programas.'
        S = {
            Opt-Ini 'Telemetria'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
            Reg-Del 'HKCU\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 'REG_DWORD' '3'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 'REG_DWORD' '1'
            Svc 'DiagTrack' 'disabled' '4'
            Svc-Parar 'DiagTrack'
            foreach ($t in $TareasTelemetria) { Tarea $t 'disable' }
            # Sin gpupdate /force: las politicas van directo al registro y Windows las lee igual (gpupdate tardaba 5 a 15 s)
            Opt-Fin 'Telemetria reducida'
        }
        R = {
            Opt-Ini 'Telemetria (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications'
            Svc 'DiagTrack' 'auto' '2'
            Svc-Arrancar 'DiagTrack'
            foreach ($t in $TareasTelemetria) { Tarea $t 'enable' }
            Opt-Fin 'Telemetria restaurada'
        }
    },
    @{
        Id = 'wg'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea desactivar los Widgets? (Panel de clima y noticias; tambien oculta el boton Vista de tareas de la barra)'
        Hace = 'borra el panel de Widgets y oculta el boton Vista de tareas.'
        Favor = 'menos procesos y menos RAM, y la barra queda mas limpia.'
        Contra = 'perdes el panel de clima y noticias.'
        S = {
            Opt-Ini 'Widgets'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 'REG_DWORD' '0'
            # En Windows 10 el panel de clima y noticias se llama "Noticias e intereses" y se apaga con otra clave (no es una app aparte).
            if (($script:Build -gt 0) -and ($script:Build -lt 22000)) {
                Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 'REG_DWORD' '0'
                Reg-Soft 'HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 'REG_DWORD' '2'
                if ($script:OptT -gt 0) { Act 'EXPLORER_RESTART' | Out-Null }
                Opt-Fin 'Noticias e intereses desactivado'
                return
            }
            Reg-Soft 'HKLM\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 'REG_DWORD' '0'
            Resps (Act 'WIDGETS_OFF')
            Opt-Fin 'Widgets desactivados'
        }
        R = {
            Opt-Ini 'Widgets (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 'REG_DWORD' '1'
            if (($script:Build -gt 0) -and ($script:Build -lt 22000)) {
                Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds'
                Reg-Soft 'HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 'REG_DWORD' '0'
                if ($script:OptT -gt 0) { Act 'EXPLORER_RESTART' | Out-Null }
                Opt-Fin 'Noticias e intereses restaurado'
                return
            }
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests'
            Resps (Act 'WIDGETS_ON')
            Opt-Fin 'Widgets restaurados'
        }
    },
    @{
        Id = 'do'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea dejar de repartir actualizaciones a otras PCs? (Optimizacion de entrega)'
        Hace = 'tu PC deja de mandar actualizaciones a otras PCs por internet.'
        Favor = 'no gasta tu subida de internet y hay menos riesgo de lag en partidas.'
        Contra = 'ninguno para vos.'
        S = {
            Opt-Ini 'Optimizacion de entrega'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 'REG_DWORD' '0'
            Opt-Fin 'Tu PC ya no reparte actualizaciones a otras PCs'
        }
        R = {
            Opt-Ini 'Optimizacion de entrega (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode'
            Opt-Fin 'Optimizacion de entrega restaurada'
        }
    },
    @{
        Id = 'wud'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea que Windows Update no instale drivers? (Asi no te cambia el driver de la placa de video que elegiste; los instalas vos)'
        Hace = 'Windows Update deja de instalar drivers.'
        Favor = 'no te cambia el driver de video que elegiste ni te pone drivers viejos.'
        Contra = 'los drivers los actualizas vos, desde la app de NVIDIA, AMD o el fabricante.'
        S = {
            Opt-Ini 'Drivers por Windows Update'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' 'SearchOrderConfig' 'REG_DWORD' '0'
            Opt-Fin 'Windows Update ya no instala drivers'
        }
        R = {
            Opt-Ini 'Drivers por Windows Update (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' 'SearchOrderConfig' 'REG_DWORD' '1'
            Opt-Fin 'Windows Update vuelve a instalar drivers'
        }
    },
    @{
        Id = 'wup'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea poder pausar las actualizaciones de Windows por mucho tiempo? (Vos elegis hasta cuando, en Windows Update)'
        Hace = 'te deja elegir en Windows Update una pausa de muchos anos.'
        Favor = 'no se actualiza ni reinicia en un torneo o una partida importante.'
        Contra = 'si la dejas pausada mucho tiempo, te perdes parches de seguridad.'
        S = {
            Opt-Ini 'Pausa larga de actualizaciones'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'FlightSettingsMaxPauseDays' 'REG_DWORD' '7300'
            Say '  En Windows Update, abri la lista de Pausar actualizaciones y elegi hasta cuando. Acordate de reanudarlas cada tanto por seguridad.'
            Opt-Fin 'Ya podes pausar las actualizaciones por mucho tiempo desde Windows Update'
        }
        R = {
            Opt-Ini 'Pausa larga de actualizaciones (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'FlightSettingsMaxPauseDays'
            Opt-Fin 'Pausa de actualizaciones vuelve al maximo normal de Windows'
        }
    },
    @{
        Id = 'ad'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea quitar anuncios, sugerencias y Bing? (Inicio, bloqueo y Configuracion; el Inicio busca solo en tu PC)'
        Hace = 'quita anuncios, el ID de publicidad, apps sugeridas y las que instalan solas Microsoft y el fabricante, recomendaciones del Inicio y Bing de la busqueda.'
        Favor = 'Inicio mas limpio y la busqueda es solo de tu PC, mas rapida.'
        Contra = 'la busqueda del Inicio ya no busca en internet.'
        S = {
            Opt-Ini 'Anuncios, sugerencias y busqueda web'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
            foreach ($n in $ClavesAnuncios) { Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $n 'REG_DWORD' '0' }
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_AccountNotifications' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCloudSearch' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'ConnectedSearchUseWeb' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSACloudSearchEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsAADCloudSearchEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 'REG_DWORD' '0'
            Opt-Fin 'Anuncios, sugerencias y busqueda web quitados'
        }
        R = {
            Opt-Ini 'Anuncios, sugerencias y busqueda web (restaurar)'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '1'
            foreach ($n in $ClavesAnuncios) { Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $n 'REG_DWORD' '1' }
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_AccountNotifications' 'REG_DWORD' '1'
            Reg-Del 'HKCU\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCloudSearch'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'ConnectedSearchUseWeb'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSACloudSearchEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsAADCloudSearchEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 'REG_DWORD' '1'
            Opt-Fin 'Anuncios, sugerencias y busqueda web restaurados'
        }
    },
    @{
        Id = 'sv'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea desactivar servicios y funciones que casi nadie usa? (Fax y Escaner, Internet Explorer, Media Player viejo, Mapas y mas)'
        Hace = 'apaga servicios de Fax, Mapas, modo demo, geolocalizacion y reportes de error, y quita Internet Explorer, Fax y Escaner y el Media Player viejo.'
        Favor = 'menos servicios y funciones cargadas en Windows.'
        Contra = 'si usas el escaner de Windows o el Media Player viejo, dejan de estar.'
        S = {
            Opt-Ini 'Servicios y funciones que casi nadie usa'
            Svc 'Fax' 'disabled' '4'
            Svc 'MapsBroker' 'disabled' '4'
            Svc 'RetailDemo' 'disabled' '4'
            Svc 'lfsvc' 'disabled' '4'
            Svc 'WerSvc' 'disabled' '4'
            Say '  Revisando las funciones de Windows, un momento...'
            Resps (Act 'FUN_OFF')
            Opt-Fin 'Servicios y funciones que casi nadie usa desactivados (algunas se aplican al reiniciar)'
        }
        R = {
            Opt-Ini 'Servicios y funciones que casi nadie usa (restaurar)'
            Svc 'Fax' 'demand' '3'
            Svc 'MapsBroker' 'delayed-auto' '2'
            Svc 'RetailDemo' 'demand' '3'
            Svc 'lfsvc' 'demand' '3'
            Svc 'WerSvc' 'demand' '3'
            Say '  Reactivando las funciones de Windows, un momento...'
            Resps (Act 'FUN_ON')
            Opt-Fin 'Servicios y funciones restaurados (algunas se aplican al reiniciar)'
        }
    },
    @{
        Id = 'pv'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea apagar el rastreo y la recopilacion de datos? (Actividad, ubicacion, Wifi Sense, sincronizacion, escritura y voz en la nube)'
        Hace = 'apaga historial de actividad, ubicacion, Wifi Sense, portapapeles y ajustes en la nube, aprendizaje y sugerencias de escritura, voz en la nube y apps escuchando comandos de voz, mapas, DRM y Homegroup.'
        Favor = 'mas privacidad y menos tareas en segundo plano.'
        Contra = 'las apps que usan ubicacion, como el clima, no la detectan, y tus ajustes no se copian a otras PCs.'
        S = {
            Opt-Ini 'Rastreo y recopilacion de datos'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider' 'REG_DWORD' '1'
            Svc 'lfsvc' 'disabled' '4'
            Svc-Parar 'lfsvc'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworksettings' 'AutoConnectAllowedOEM' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'Value' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'Value' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowCrossDeviceClipboard' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSync' 'REG_DWORD' '2'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSyncUserOverride' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationLastUsed' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\input\Settings' 'InsightsEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SYSTEM\Maps' 'AutoUpdateEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AutoDownloadAndUpdateMapData' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AllowUntriggeredNetworkTrafficOnSettingsPage' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM' 'DisableOnline' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\HomeGroup' 'DisableHomeGroup' 'REG_DWORD' '1'
            Svc 'HomeGroupListener' 'disabled' '4'
            Svc 'HomeGroupProvider' 'disabled' '4'
            Opt-Fin 'Rastreo y recopilacion de datos desactivados'
        }
        R = {
            Opt-Ini 'Rastreo y recopilacion de datos (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocationScripting'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableWindowsLocationProvider'
            Svc 'lfsvc' 'demand' '3'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworksettings' 'AutoConnectAllowedOEM' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'Value' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'Value' 'REG_DWORD' '1'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowCrossDeviceClipboard'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSync'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync' 'DisableSettingSyncUserOverride'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '1'
            Reg-Del 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted'
            Reg-Set 'HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps' 'AgentActivationLastUsed' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\input\Settings' 'InsightsEnabled' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SYSTEM\Maps' 'AutoUpdateEnabled' 'REG_DWORD' '1'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AutoDownloadAndUpdateMapData'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' 'AllowUntriggeredNetworkTrafficOnSettingsPage'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM' 'DisableOnline'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\HomeGroup' 'DisableHomeGroup'
            Svc 'HomeGroupListener' 'demand' '3'
            Svc 'HomeGroupProvider' 'demand' '3'
            Opt-Fin 'Rastreo y recopilacion de datos restaurados'
        }
    },
    @{
        Id = 'ter'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea desactivar Teredo? (Tunel IPv6 que puede sumar latencia; puede afectar el chat de Xbox en PC)'
        Hace = 'apaga Teredo, un tunel de IPv6 que Windows usa por encima de IPv4.'
        Favor = 'puede sacar latencia de mas en algunas conexiones.'
        Contra = 'puede afectar el chat de grupo de Xbox y el NAT en juegos de Xbox en PC.'
        S = {
            Opt-Ini 'Teredo'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition' 'Teredo_State' 'REG_SZ' 'Disabled'
            & netsh.exe interface teredo set state disabled 2>&1 | Out-Null
            Log 'INFO' 'Teredo apagado tambien con netsh'
            Opt-Fin 'Teredo desactivado'
        }
        R = {
            Opt-Ini 'Teredo (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition' 'Teredo_State'
            & netsh.exe interface teredo set state default 2>&1 | Out-Null
            Log 'INFO' 'Teredo vuelto a su estado por defecto con netsh'
            Opt-Fin 'Teredo restaurado'
        }
    },
    @{
        Id = 'tp'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea apagar la telemetria de programas? (Office, NVIDIA y PowerShell 7; si no tenes alguno no cambia nada)'
        Hace = 'apaga la telemetria de Office, NVIDIA y PowerShell 7.'
        Favor = 'menos datos enviados y menos tareas de fondo.'
        Contra = 'ninguno en el uso normal.'
        S = {
            Opt-Ini 'Telemetria de programas'
            Reg-Set 'HKCU\Software\Policies\Microsoft\office\common\clienttelemetry' 'DisableTelemetry' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry' 'DisableTelemetry' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry' 'SendTelemetry' 'REG_DWORD' '3'
            Reg-Set 'HKCU\Software\Policies\Microsoft\office\16.0\common\feedback' 'Enabled' 'REG_DWORD' '0'
            Tarea '\Microsoft\Office\OfficeTelemetryAgentFallBack2016' 'disable'
            Tarea '\Microsoft\Office\OfficeTelemetryAgentLogOn2016' 'disable'
            Svc 'NvTelemetryContainer' 'disabled' '4'
            Svc-Parar 'NvTelemetryContainer'
            Reg-Set 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID44231' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID64640' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID66610' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'OptInOrOutPreference' 'REG_DWORD' '0'
            Tarea '\NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'disable'
            Tarea '\NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'disable'
            Tarea '\NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'disable'
            Reg-Set 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' 'POWERSHELL_TELEMETRY_OPTOUT' 'REG_SZ' '1'
            Opt-Fin 'Telemetria de Office, NVIDIA y PowerShell desactivada'
        }
        R = {
            Opt-Ini 'Telemetria de programas (restaurar)'
            Reg-Del 'HKCU\Software\Policies\Microsoft\office\common\clienttelemetry' 'DisableTelemetry'
            Reg-Del 'HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry' 'DisableTelemetry'
            Reg-Del 'HKCU\Software\Policies\Microsoft\office\16.0\common\clienttelemetry' 'SendTelemetry'
            Reg-Del 'HKCU\Software\Policies\Microsoft\office\16.0\common\feedback' 'Enabled'
            Tarea '\Microsoft\Office\OfficeTelemetryAgentFallBack2016' 'enable'
            Tarea '\Microsoft\Office\OfficeTelemetryAgentLogOn2016' 'enable'
            Svc 'NvTelemetryContainer' 'auto' '2'
            Reg-Del 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID44231'
            Reg-Del 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID64640'
            Reg-Del 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID66610'
            Reg-Del 'HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'OptInOrOutPreference'
            Tarea '\NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'enable'
            Tarea '\NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'enable'
            Tarea '\NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}' 'enable'
            Reg-Del 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' 'POWERSHELL_TELEMETRY_OPTOUT'
            Opt-Fin 'Telemetria de Office, NVIDIA y PowerShell restaurada'
        }
    },
    @{
        Id = 'hst'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea bloquear los servidores de telemetria de Microsoft? (38 entradas en el archivo hosts; Update y Store no se tocan)'
        Hace = 'anota 38 servidores de telemetria en el archivo hosts para que no respondan.'
        Favor = 'corta envios de datos aunque Windows reactive algo despues.'
        Contra = 'Defender a veces avisa por cambios en hosts y algun diagnostico de Microsoft puede fallar.'
        S = {
            Opt-Ini 'Bloqueo de servidores de telemetria'
            $h = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
            if (Hosts-Tiene $h) {
                $script:OptS++
                Log 'OK' 'el bloqueo de telemetria ya estaba en el archivo hosts'
                Opt-Fin 'Servidores de telemetria bloqueados en hosts'
                return
            }
            if (-not (Test-Path -LiteralPath ($h + '.xuca.bak'))) { Copy-Item -LiteralPath $h -Destination ($h + '.xuca.bak') -Force -ErrorAction SilentlyContinue }
            $txt = "`r`n" + (($HostsTelemetria | ForEach-Object { '0.0.0.0 ' + $_ + ' # xuca-telemetria' }) -join "`r`n") + "`r`n"
            try { [IO.File]::AppendAllText($h, $txt, [Text.Encoding]::Default) } catch { }
            Res (Hosts-Tiene $h) 'hosts: bloqueo de telemetria'
            & ipconfig.exe /flushdns 2>&1 | Out-Null
            Say '  Si Defender avisa por el archivo hosts, es por estas entradas. Dejalo pasar o usa R para quitarlas.' 'Yellow'
            Opt-Fin 'Servidores de telemetria bloqueados en hosts'
        }
        R = {
            Opt-Ini 'Bloqueo de servidores de telemetria (restaurar)'
            $h = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
            if (-not (Hosts-Tiene $h)) {
                $script:OptS++
                Log 'OK' 'no habia entradas de telemetria en hosts'
                Opt-Fin 'Archivo hosts limpio de entradas de telemetria'
                return
            }
            try {
                $l = @([IO.File]::ReadAllLines($h, [Text.Encoding]::Default) | Where-Object { -not $_.Contains('# xuca-telemetria') })
                [IO.File]::WriteAllLines($h, [string[]]$l, [Text.Encoding]::Default)
            } catch { }
            if (Hosts-Tiene $h) { $script:OptT++; $script:OptF++; Log 'FALLO' 'no se pudieron quitar las entradas de hosts' }
            else { $script:OptT++; Log 'OK' 'entradas de telemetria quitadas de hosts' }
            & ipconfig.exe /flushdns 2>&1 | Out-Null
            Opt-Fin 'Archivo hosts limpio de entradas de telemetria'
        }
    },
    @{
        Id = 'eb'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea reducir el bloat de Edge y Brave? (Sin barra lateral, compras, rewards, wallet, VPN ni IA; no los desinstala)'
        Hace = 'apaga en Edge y Brave la barra lateral, compras, rewards, wallet, VPN e IA; en Edge tambien saca Copilot (no lee tus paginas ni tu historial), la escritura con IA, los temas con IA, la IA de DevTools y la descarga de modelos de IA locales.'
        Favor = 'navegadores mas livianos y sin publicidad.'
        Contra = 'perdes esas funciones si las usabas.'
        S = {
            Opt-Ini 'Bloat de Edge y Brave'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeShoppingAssistantEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShowMicrosoftRewards' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'PersonalizationReportingEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeFollowEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShowRecommendationsEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'SpotlightExperiencesAndRecommendationsEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'PromotionalTabsEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'CopilotPageContext' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'CopilotCDPPageContext' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeEntraCopilotPageContext' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'Microsoft365CopilotChatIconEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeHistoryAISearchEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ComposeInlineEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'GenAILocalFoundationalModelSettings' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'BuiltInAIAPIsEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'AIGenThemesEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'DevToolsGenAiSettings' 'REG_DWORD' '2'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShareBrowsingHistoryWithCopilotSearchAllowed' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveRewardsDisabled' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveWalletDisabled' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveVPNDisabled' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveAIChatEnabled' 'REG_DWORD' '0'
            Opt-Fin 'Bloat de Edge y Brave reducido'
        }
        R = {
            Opt-Ini 'Bloat de Edge y Brave (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeShoppingAssistantEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShowMicrosoftRewards'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'PersonalizationReportingEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'MetricsReportingEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeFollowEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShowRecommendationsEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'SpotlightExperiencesAndRecommendationsEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'PromotionalTabsEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'CopilotPageContext'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'CopilotCDPPageContext'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeEntraCopilotPageContext'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'Microsoft365CopilotChatIconEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'EdgeHistoryAISearchEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ComposeInlineEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'GenAILocalFoundationalModelSettings'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'BuiltInAIAPIsEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'AIGenThemesEnabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'DevToolsGenAiSettings'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'ShareBrowsingHistoryWithCopilotSearchAllowed'
            Reg-Del 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveRewardsDisabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveWalletDisabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveVPNDisabled'
            Reg-Del 'HKLM\SOFTWARE\Policies\BraveSoftware\Brave' 'BraveAIChatEnabled'
            Opt-Fin 'Politicas de Edge y Brave restauradas'
        }
    },
    @{
        Id = 'su'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea frenar las actualizaciones automaticas de las apps de la Store? (Se actualizan solo cuando vos lo pidas)'
        Hace = 'las apps de la Store se actualizan solo cuando vos lo pidas.'
        Favor = 'no descargan nada en medio de una partida.'
        Contra = 'tenes que actualizarlas a mano cada tanto.'
        S = {
            Opt-Ini 'Actualizaciones de apps de la Store'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload' 'REG_DWORD' '2'
            Opt-Fin 'Actualizaciones automaticas de la Store desactivadas'
        }
        R = {
            Opt-Ini 'Actualizaciones de apps de la Store (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload'
            Opt-Fin 'Actualizaciones automaticas de la Store restauradas'
        }
    },
    @{
        Id = 'ia'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea apagar las funciones de IA de Windows? (Click to Do, Bloc de notas, Paint, Configuracion, busqueda y Copilot en Office)'
        Hace = 'apaga Click to Do, la IA del Bloc de notas y de Paint (creador de imagenes, Cocreator, relleno y borrado generativo, quitar fondo), el agente de IA de Configuracion, Copilot en la busqueda, el acceso de las apps a la IA generativa y Copilot en Word y Excel.'
        Favor = 'menos procesos de IA y mas privacidad.'
        Contra = 'perdes esas funciones.'
        S = {
            Opt-Ini 'Funciones de IA'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableClickToDo' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures' 'REG_DWORD' '1'
            Reg-Del 'HKCU\Software\Microsoft\Notepad' 'ShowRewriteButton'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableSettingsAgent' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\Shell\Copilot\BingChat' 'IsUserEligible' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\generativeAI' 'Value' 'REG_SZ' 'Deny'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableImageCreator' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableCocreator' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeFill' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeErase' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableRemoveBackground' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Office\16.0\Word\Options' 'EnableCopilot' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Office\16.0\Excel\Options' 'EnableCopilot' 'REG_DWORD' '0'
            if ((Act 'NOTEPAD_CHK') -ge 6) { $script:OptP++ }
            Opt-Fin 'Funciones de IA desactivadas'
        }
        R = {
            Opt-Ini 'Funciones de IA (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableClickToDo'
            Reg-Del 'HKLM\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableSettingsAgent'
            Reg-Del 'HKCU\Software\Microsoft\Windows\Shell\Copilot\BingChat' 'IsUserEligible'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\generativeAI' 'Value' 'REG_SZ' 'Allow'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableImageCreator'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableCocreator'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeFill'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeErase'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableRemoveBackground'
            Reg-Del 'HKCU\Software\Microsoft\Office\16.0\Word\Options' 'EnableCopilot'
            Reg-Del 'HKCU\Software\Microsoft\Office\16.0\Excel\Options' 'EnableCopilot'
            Opt-Fin 'Funciones de IA restauradas'
        }
    },
    @{
        Id = 'db'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea borrar las apps basura? (OneDrive, Copilot, IA y apps de fabrica como Spotify, Netflix, Teams u Outlook; no toca WhatsApp, Xbox ni la Store)'
        Hace = 'borra OneDrive, Copilot, los paquetes de IA y las apps que vienen de fabrica.'
        Favor = 'mas espacio, menos RAM y menos procesos.'
        Contra = 'no tiene R: si queres alguna, la reinstalas desde la Store. Tus archivos de OneDrive en la PC no se borran.'
        S = {
            Opt-Ini 'Apps basura'
            Say '  Revisando y desinstalando, un momento...'
            Reg-Set 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 'REG_DWORD' '0'
            Reg-Set 'HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' 'System.IsPinnedToNameSpaceTree' 'REG_DWORD' '0'
            Resps (Act 'DEBLOAT')
            Resps (Act 'IA_PAQ')
            Resps (Act 'IA_ARCH')
            Opt-Fin 'Apps basura quitadas'
        }
    },
    @{
        Id = 'edge'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea quitar Edge, Bing y Primeros pasos? (Conserva EdgeWebView)'
        Hace = 'desinstala Edge, Bing y Primeros pasos, pero deja WebView2, que usan otros programas.'
        Favor = 'menos procesos de fondo y Edge deja de abrirse solo.'
        Contra = 'una actualizacion grande de Windows puede traerlo de vuelta.'
        Antes = {
            'AVISO: si Windows Update trae Edge de vuelta tras una actualizacion grande, repeti esta opcion.'
        }
        S = {
            Opt-Ini 'Quitar Edge y Bing'
            Say '  Revisando Edge y las apps, un momento...'
            Resps (Act 'EDGE_REMOVE')
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate' 'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' 'REG_DWORD' '0'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 'REG_DWORD' '0'
            Reg-Set 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
            Opt-Fin 'Edge, Bing y Primeros pasos quitados (EdgeWebView conservado)'
        }
        R = {
            Opt-Ini 'Edge (restaurar)'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate' 'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
            Reg-Set 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 'REG_DWORD' '1'
            Reg-Del 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions'
            Resps (Act 'EDGE_BACK')
            Opt-Fin 'Edge reinstalado.'
        }
    },
    @{
        Id = 'chr'; Seccion = 'SISTEMA Y PRIVACIDAD'
        Q = '- Desea instalar Google Chrome?'
        Hace = 'instala Google Chrome con winget.'
        Favor = 'tenes navegador aunque hayas quitado Edge.'
        Contra = 'ninguno.'
        Saltar = {
            # Si Chrome ya esta instalado no se pregunta
            $rutas = @(($env:ProgramFiles + '\Google\Chrome\Application\chrome.exe'), (${env:ProgramFiles(x86)} + '\Google\Chrome\Application\chrome.exe'), ($env:LOCALAPPDATA + '\Google\Chrome\Application\chrome.exe'))
            if (@($rutas | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0) { Log 'SALTADO' 'Instalar Chrome: ya esta instalado'; return $true }
            return $false
        }
        S = {
            Opt-Ini 'Instalar Chrome'
            Say '  Revisando Chrome, un momento...'
            Resps (Act 'CHROME_INSTALL')
            Opt-Fin 'Google Chrome instalado'
        }
    },
    @{
        Id = 'drv'; Seccion = 'DRIVERS'
        Q = '- Desea buscar los drivers recomendados para tu PC? (Solo los necesarios; se abre la pagina oficial de cada uno)'
        Hace = 'revisa tu PC y te recomienda solo los drivers que aportan algo: lo que no tiene driver, la placa de video, el chipset de AMD el programa de tu mouse, teclado o auriculares de marca, de tu SSD y de otros aparatos (impresora, tableta grafica, volante, microfono, Stream Deck, capturadora, webcam, joystick, antena USB). Tambien te avisa si la BIOS esta vieja.'
        Favor = 'te abre la pagina oficial de cada cosa, con la ultima version, sin programas de mas.'
        Contra = 'la BIOS no se actualiza sola: se hace a mano desde la pagina de tu placa.'
        S = {
            Opt-Ini 'Drivers recomendados'
            Resps (Act 'DRIVERS')
            Opt-Fin 'Revision de drivers terminada'
        }
    },
    @{
        Id = 'ms_acc'; Seccion = 'CUENTA'
        Q = '- Desea borrar una cuenta de esta PC? (Elegis cual: usuario de Windows o cuenta de Microsoft vinculada; tu cuenta actual no se toca)'
        Hace = 'te deja elegir otra cuenta de la PC y borrarla.'
        Favor = 'limpia cuentas viejas que ya no usas.'
        Contra = 'si tambien borras su carpeta, se pierden sus archivos.'
        Antes = {
            'AVISO: despues de borrar una cuenta, reinicia la PC para que Configuracion deje de mostrarla.'
        }
        S = {
            Opt-Ini 'Borrar cuentas'
            Resps (Act 'MS_ACC_REMOVE')
            Opt-Fin 'Borrado de cuentas finalizado'
        }
    },
    @{
        Id = 'al'; Seccion = 'CUENTA'
        Q = '- Desea entrar a Windows sin contrasena? (Tu cuenta pasa a local sin contrasena: tocas Iniciar sesion y entras)'
        Hace = 'tu cuenta pasa a ser local y sin contrasena.'
        Favor = 'entras directo a Windows.'
        Contra = 'cualquiera que prenda la PC entra, y no anda el Escritorio remoto.'
        Antes = {
            'AVISO: sin contrasena entra cualquiera que prenda la PC, y no anda el Escritorio remoto.'
            'AVISO: si tu cuenta es de Microsoft, Windows cierra la sesion al terminar y esto se abre solo al volver a entrar.'
        }
        S = {
            Opt-Ini 'Entrar sin contrasena'
            Resps (Act 'LOCALPW_OFF')
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'AutoAdminLogon' 'REG_SZ' '0'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'DefaultPassword'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' 'DevicePasswordLessBuildVersion' 'REG_DWORD' '0'
            Opt-Fin 'Cuenta sin contrasena: al prender la PC tocas Iniciar sesion y entras'
        }
        R = {
            Opt-Ini 'Entrar sin contrasena (restaurar)'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'AutoAdminLogon' 'REG_SZ' '0'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'DefaultPassword'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' 'DevicePasswordLessBuildVersion' 'REG_DWORD' '2'
            Abrir-Pagina 'ms-settings:signinoptions'
            Opt-Fin 'Restos del inicio automatico borrados. Para poner contrasena nueva usa la pagina que se abrio'
        }
    },
    @{
        Id = 'cta'; Seccion = 'CONFIRMAR CAMBIO DE CUENTA'
        Q = '- Desea terminar de quitar la contrasena ahora? (Se confirma el cambio y el script se cierra)'
        Antes = {
            '  Windows cerro la sesion para pasar tu cuenta a local. Falta quitar la contrasena.'
        }
        Saltar = {
            # Solo cuando se abre sola despues de pasar la cuenta a local
            return (-not $script:ModoCuenta)
        }
        Preguntar = $true
        N = {
            Log 'INFO' 'el usuario cancelo la confirmacion de la cuenta'
            Say '  Cancelado: tu cuenta sigue como estaba. Cuando quieras, volve a usar "Entrar sin contrasena" en la app.' 'Yellow'
        }
        S = {
            Opt-Ini 'Entrar sin contrasena'
            Resps (Act 'LOCALPW_FIN')
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'AutoAdminLogon' 'REG_SZ' '0'
            Reg-Del 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'DefaultPassword'
            Reg-Set 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' 'DevicePasswordLessBuildVersion' 'REG_DWORD' '0'
            Opt-Fin 'Cuenta sin contrasena: al prender la PC tocas Iniciar sesion y entras'
        }
    }
)

# Lo que llama la app (en otro hilo, con Comun.ps1 cargado). $salida = archivo donde la app lee el progreso.
function Correr-Debloat([string]$salida, [string]$carpeta) {
    $script:RpApagado = $false; $script:ModoCuenta = $false
    Correr-Opciones -Nombre 'debloat' -Titulo 'WINDOWS DEBLOAT' -Lista @($ListaOpciones | Where-Object { $_.Id -ne 'cta' }) -Rein $ReinDebloat -Salida $salida -Carpeta $carpeta
}

# Ventana de PowerShell a la vista, para lo que te pide datos:
#   -Consola herr: las herramientas de la app (la respuesta de cada una viene en XR_<id>, como siempre)
#   -Consola cta:  se abre sola al volver a entrar a Windows, despues de pasar tu cuenta a local
function Correr-DebloatConsola([string]$modo, [string]$carpeta) {
    $script:XConsola = $true
    $script:RpApagado = $false
    $script:ModoCuenta = ($modo -eq 'cta')
    try { $Host.UI.RawUI.WindowTitle = 'Xuca OPtimizer' } catch { }
    $ids = $(if ($script:ModoCuenta) { @('cta') } else { @('rp', 'ver', 'ms_acc', 'al') })
    Correr-Opciones -Nombre 'debloat' -Titulo 'WINDOWS DEBLOAT' -Lista @($ListaOpciones | Where-Object { $ids -contains $_.Id }) -Rein $ReinDebloat -Salida '' -Carpeta $carpeta
    if ($script:ModoCuenta -and $script:Reinicio) {
        Write-Host ''
        if ((Read-Host 'Desea reiniciar ahora? [S] Si  [N] No') -match '^[sS]') {
            Write-Host 'Reiniciando en 10 segundos...'
            & shutdown.exe /r /t 10
        } else { Write-Host 'Reinicia cuando puedas.' }
    }
    Write-Host ''
    [void](Read-Host 'Listo. Presiona Enter para cerrar esta ventana')
}

if ($Consola) {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        Write-Host 'Pidiendo permisos de administrador...'
        try { Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -Consola ' + $Consola) } catch { }
        exit
    }
    . ([scriptblock]::Create([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Comun.ps1'))))
    Correr-DebloatConsola $Consola $PSScriptRoot
}
