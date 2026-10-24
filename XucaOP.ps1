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

$Root = Split-Path -Parent $PSCommandPath
$Redes = 'https://linktr.ee/011xuca'
$Scripts = Join-Path $Root 'scripts'
$Rutas = [ordered]@{
    Debloat  = Join-Path $Scripts 'windows_debloat.bat'
    Gaming   = Join-Path $Scripts 'optimizacion_gaming.bat'
    Limpieza = Join-Path $Scripts 'limpiar_cache.bat'
}
$faltan = @($Rutas.Values | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($faltan.Count -gt 0) {
    Mostrar-Error ("Faltan estos archivos al lado de la app:`n`n" + ($faltan -join "`n") + "`n`nPone los tres .bat en la misma carpeta que XucaApp.ps1.")
    exit
}

# Opciones que te piden datos en la consola: van en la pagina Herramientas, no como casillas.
$SoloScript = @('ver', 'ms_acc', 'al', 'cta')

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
        if ($l -match '^set "Q=- Desea (.+)"$') {
            $q = $Matches[1]
            $conR = ($i + 1 -lt $lineas.Count) -and ($lineas[$i + 1] -match 'call :askR')
            $titulo = (($q -replace '\s*\(.*$', '') -replace '\?\s*$', '').Trim()
            if ($titulo.Length -gt 0) { $titulo = $titulo.Substring(0, 1).ToUpper() + $titulo.Substring(1) }
            if ($qid -and ($SoloScript -notcontains $qid)) {
                $items.Add([pscustomobject]@{ Id = $qid; Titulo = $titulo; Hace = $h; Favor = $a; Contra = $c; ConR = $conR; Seccion = $sec })
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
# Leer como esta Windows (para marcar "Ya aplicado")
# Cada chequeo devuelve $true (aplicado), $false (sin aplicar) o $null (no se sabe).
# ------------------------------------------------------------
function Leer-Reg([string]$path, [string]$name) {
    try { return (Get-ItemProperty -LiteralPath $path -Name $name -ErrorAction Stop).$name } catch { return $null }
}
function Leer-Svc([string]$svc) { return (Leer-Reg ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $svc) 'Start') }
function HasAppx([string]$n) { return ($script:Appx -contains $n) }
function Prio-Actuales {
    $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
    return @(Get-ChildItem -LiteralPath $ifeo -ErrorAction SilentlyContinue |
        Where-Object { (Leer-Reg ($_.PSPath + '\PerfOptions') 'XucaPrioridad') -eq 1 } |
        ForEach-Object { $_.PSChildName -replace '(?i)\.exe$', '' })
}
# Catalogos de la opcion de afinidad (juegos y programas de fondo): se leen del .bat para no tenerlos repetidos
$AfiJuegosCat = ''; $AfiFondoCat = ''
try {
    $tg = [IO.File]::ReadAllText($Rutas.Gaming)
    $AfiJuegosCat = [regex]::Match($tg, "(?m)^\`$afiJuegosCat = '([^']*)'").Groups[1].Value
    $AfiFondoCat = [regex]::Match($tg, "(?m)^\`$afiFondoCat = '([^']*)'").Groups[1].Value
} catch { }
# Lo que dejo guardado la opcion de afinidad (juegos, programas de fondo y nucleos elegidos)
function Afi-Config {
    $c = @{}
    $f = Join-Path $env:ProgramData 'XucaScripts\afinidad.txt'
    if (-not (Test-Path -LiteralPath $f)) { return $c }
    foreach ($l in @(Get-Content -LiteralPath $f -ErrorAction SilentlyContinue)) { $i = $l.IndexOf('='); if ($i -gt 0) { $c[$l.Substring(0, $i)] = $l.Substring($i + 1) } }
    return $c
}
# Arma la lista para elegir: el catalogo y, al final, los que agregaste vos.
# Si ya se aplico antes, viene marcado lo que elegiste esa vez; si no, todo el catalogo.
function Afi-Items([string]$cat, [string]$clave) {
    $c = Afi-Config
    $actual = $null
    if ($c.ContainsKey('apps')) {
        $t = $(if ($clave -eq 'juegos') { ([string]$c['juegos']) + ',' + ([string]$c['livianos']) } else { [string]$c['apps'] })
        $actual = @($t -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
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
    'Gaming|pw'     = { $script:Plan -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
    'Gaming|cpu'    = { if (-not $script:Plan) { return $null }; Test-Path -LiteralPath (Join-Path $env:ProgramData ('XucaScripts\cpu_' + $script:Plan + '.txt')) }
    'Gaming|gm'     = { ((Leer-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled') -eq 1) -and ((Leer-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled') -eq 0) }
    'Gaming|xb'     = { -not (HasAppx 'Microsoft.XboxGamingOverlay') }
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
    'Gaming|pe'     = { if (-not $script:Plan) { return $null }; (Leer-Reg ('HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $script:Plan + '\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226') 'ACSettingIndex') -eq 0 }
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
    'Gaming|dns'    = { @(Get-ChildItem -LiteralPath (Join-Path $env:ProgramData 'XucaScripts') -Filter 'dns_*.txt' -ErrorAction SilentlyContinue).Count -gt 0 }
    'Gaming|mi'     = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled') -eq 0 }
    'Gaming|avl'    = { (Get-MpPreference -ErrorAction Stop).ScanAvgCPULoadFactor -eq 5 }
    'Gaming|ex'     = { ([string](Get-ProcessMitigation -System -ErrorAction Stop).DEP.Enable) -eq 'OFF' }
    'Gaming|vbs'    = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity') -eq 0 }
    'Gaming|wsr'    = { (Leer-Svc 'WSearch') -eq 4 }
    'Gaming|stg'    = { (Leer-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense' 'AllowStorageSenseGlobal') -eq 0 }
    'Gaming|ext'    = { (Leer-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt') -eq 0 }
    'Gaming|md'     = { (Leer-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay') -eq '0' }
    'Gaming|v4'     = { (Leer-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' 'DisabledComponents') -eq 32 }
}

# ------------------------------------------------------------
# Ventana
# ------------------------------------------------------------
[xml]$xaml = @'
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
  </Window.Resources>
  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="230"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="#0E1014" Padding="16,22">
      <DockPanel LastChildFill="False">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Text="Xuca OPtimizer" Foreground="White" FontSize="22" FontWeight="SemiBold"/>
          <Button x:Name="NavDebloat" Style="{StaticResource Nav}" Content="Debloat y privacidad"/>
          <Button x:Name="NavGaming" Style="{StaticResource Nav}" Content="Optimizacion gaming"/>
          <Button x:Name="NavLimpieza" Style="{StaticResource Nav}" Content="Limpiar cache"/>
          <Button x:Name="NavHerr" Style="{StaticResource Nav}" Content="Herramientas"/>
          <Button x:Name="NavRestaurar" Style="{StaticResource Nav}" Content="Restaurar todo"/>
        </StackPanel>
        <StackPanel DockPanel.Dock="Bottom">
          <Button x:Name="BtnRefrescar" Style="{StaticResource Nav}" Content="Volver a leer Windows"/>
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
        <TextBlock x:Name="Titulo" Foreground="White" FontSize="24" FontWeight="SemiBold"/>
        <TextBlock x:Name="Descripcion" Foreground="#9AA0A6" FontSize="13" TextWrapping="Wrap" Margin="0,4,0,0"/>
      </StackPanel>
      <ScrollViewer x:Name="Scroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,8,0"/>
      <DockPanel Grid.Row="2" Margin="0,14,0,0">
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
          <Button x:Name="BtnTodo" Style="{StaticResource Accion}" Content="Marcar todo"/>
          <Button x:Name="BtnNada" Style="{StaticResource Accion}" Content="Desmarcar todo"/>
          <Button x:Name="BtnAplicar" Style="{StaticResource Accion}" Background="#3D6FD9" Content="Aplicar seleccionadas"/>
        </StackPanel>
        <TextBlock x:Name="Estado" Foreground="#9AA0A6" FontSize="12.5" VerticalAlignment="Center" TextWrapping="Wrap"/>
      </DockPanel>
    </Grid>
  </Grid>
</Window>
'@

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'NavDebloat', 'NavGaming', 'NavLimpieza', 'NavHerr', 'NavRestaurar', 'BtnRefrescar', 'BtnLogs', 'BtnRedes', 'Titulo', 'Descripcion', 'Scroll', 'BtnTodo', 'BtnNada', 'BtnAplicar', 'Estado') { $ui[$n] = $win.FindName($n) }

$bc = New-Object Windows.Media.BrushConverter
function Pincel([string]$hex) { return $bc.ConvertFromString($hex) }

function Nuevo-Texto([string]$t, [double]$tam, [string]$color, [bool]$negrita) {
    $tb = New-Object Windows.Controls.TextBlock
    $tb.Text = $t; $tb.FontSize = $tam; $tb.Foreground = (Pincel $color); $tb.TextWrapping = 'Wrap'
    if ($negrita) { $tb.FontWeight = 'SemiBold' }
    return $tb
}

function Agregar-Linea($tb, [string]$etiqueta, [string]$color, [string]$texto) {
    if (-not $texto) { return }
    if ($tb.Inlines.Count -gt 0) { $tb.Inlines.Add((New-Object Windows.Documents.LineBreak)) }
    $r1 = New-Object Windows.Documents.Run($etiqueta); $r1.Foreground = (Pincel $color); $r1.FontWeight = 'SemiBold'
    $r2 = New-Object Windows.Documents.Run($texto)
    $tb.Inlines.Add($r1); $tb.Inlines.Add($r2)
}

function Nueva-Caja {
    $card = New-Object Windows.Controls.Border
    $card.CornerRadius = 10; $card.Background = (Pincel '#1C2027'); $card.Padding = '16,12'; $card.Margin = '0,0,0,10'
    return $card
}

function Nuevo-Boton([string]$texto, [string]$color) {
    $b = New-Object Windows.Controls.Button
    $b.Style = $win.FindResource('Accion'); $b.Content = $texto; $b.Margin = '0,10,8,0'
    if ($color) { $b.Background = (Pincel $color) }
    return $b
}

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
    if ($estado) { $pb.Background = (Pincel '#1E3A2B'); $pb.Child.Foreground = (Pincel '#81C995'); $pb.Child.Text = 'Ya aplicado' }
    else { $pb.Background = (Pincel '#262B34'); $pb.Child.Foreground = (Pincel '#9AA0A6'); $pb.Child.Text = 'Sin aplicar' }
}

# Una tarjeta con casilla, estado actual y explicacion
$script:PrioTexto = $null
$script:AfiTexto = $null
function Nueva-Tarjeta($it, $casillas, [bool]$marcada, [string]$pagina) {
    $card = Nueva-Caja
    $sp = New-Object Windows.Controls.StackPanel
    $head = New-Object Windows.Controls.DockPanel
    $pb = Nueva-Pill
    [Windows.Controls.DockPanel]::SetDock($pb, 'Right')
    $head.Children.Add($pb) | Out-Null
    $cb = New-Object Windows.Controls.CheckBox
    $cb.Content = (Nuevo-Texto $it.Titulo 15 '#FFFFFF' $true); $cb.VerticalContentAlignment = 'Center'; $cb.IsChecked = $marcada
    $cb.Tag = $it.Id
    $cb.Add_Click({ Actualizar-Contador })
    $head.Children.Add($cb) | Out-Null
    $sp.Children.Add($head) | Out-Null
    $d = New-Object Windows.Controls.TextBlock
    $d.TextWrapping = 'Wrap'; $d.FontSize = 12.5; $d.Foreground = (Pincel '#C3C8D0'); $d.Margin = '24,6,0,0'; $d.LineHeight = 19
    Agregar-Linea $d 'Que hace: ' '#8AB4F8' $it.Hace
    Agregar-Linea $d 'A favor: ' '#81C995' $it.Favor
    Agregar-Linea $d 'En contra: ' '#F28B82' $it.Contra
    $sp.Children.Add($d) | Out-Null
    if (-not $it.ConR) {
        $n = Nuevo-Texto 'No tiene R: lo que haga no se deshace desde "Restaurar todo".' 12 '#E5B567' $false
        $n.Margin = '24,6,0,0'
        $sp.Children.Add($n) | Out-Null
    }
    if ($it.Id -eq 'pri') {
        $n = Nuevo-Texto 'Al tocar Aplicar te pide los procesos de tus juegos.' 12 '#8AB4F8' $false
        $n.Margin = '24,6,0,0'
        $sp.Children.Add($n) | Out-Null
        $script:PrioTexto = Nuevo-Texto '' 12 '#81C995' $false
        $script:PrioTexto.Margin = '24,4,0,0'
        $sp.Children.Add($script:PrioTexto) | Out-Null
    }
    if ($it.Id -eq 'afi') {
        $n = Nuevo-Texto 'Al tocar Aplicar te pide los procesos de tus juegos y los programas de fondo. Tu procesador se detecta solo.' 12 '#8AB4F8' $false
        $n.Margin = '24,6,0,0'
        $sp.Children.Add($n) | Out-Null
        $script:AfiTexto = Nuevo-Texto '' 12 '#81C995' $false
        $script:AfiTexto.Margin = '24,4,0,0'
        $sp.Children.Add($script:AfiTexto) | Out-Null
    }
    $card.Child = $sp
    $casillas[$it.Id] = $cb
    if ($pagina) { $script:Pills[$pagina + '|' + $it.Id] = $pb }
    return $card
}

function Nueva-Seccion([string]$t) {
    $tb = Nuevo-Texto ($t.ToUpper()) 12 '#7D8590' $true
    $tb.Margin = '2,12,0,8'
    return $tb
}

# --- Paginas de opciones (Debloat y Gaming) ---
$Casillas = @{ Debloat = @{}; Gaming = @{} }
$Paginas = @{}
foreach ($k in 'Debloat', 'Gaming') {
    $sp = New-Object Windows.Controls.StackPanel
    $secAct = ''
    foreach ($it in $Opciones[$k]) {
        if ($it.Seccion -ne $secAct) { $secAct = $it.Seccion; $sp.Children.Add((Nueva-Seccion $secAct)) | Out-Null }
        $sp.Children.Add((Nueva-Tarjeta $it $Casillas[$k] ($it.Id -eq 'rp') $k)) | Out-Null
    }
    $Paginas[$k] = $sp
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

$script:BtnVer = Nuevo-Boton 'Actualizar a 25H2' '#3D6FD9'
$script:BtnVer.Tag = 'ver=S'
$script:VerTexto = Nuevo-Texto '' 12 '#81C995' $false
$script:VerTexto.Margin = '0,8,0,0'
$cardVer = Nueva-Herramienta 'Actualizar a Windows 11 25H2' 'si tenes 24H2, la pide por Windows Update; si tenes una version mas vieja, la instala desde el ISO oficial aunque tu PC no cumpla los requisitos.' 'tenes la version nueva con sus mejoras y parches.' 'desde una version vieja tarda cerca de una hora y en PCs no compatibles puede fallar. Hace backup antes.' @($script:BtnVer)
$cardVer.Child.Children.Add($script:VerTexto) | Out-Null
$spH.Children.Add($cardVer) | Out-Null

$bAcc = Nuevo-Boton 'Elegir cuenta para borrar' '#B3412F'; $bAcc.Tag = 'ms_acc=S'
$spH.Children.Add((Nueva-Herramienta 'Borrar una cuenta de esta PC' 'te muestra las otras cuentas de la PC (usuarios de Windows y cuentas de Microsoft vinculadas) y borras la que elijas. Tu cuenta actual no aparece.' 'limpia cuentas viejas que ya no usas.' 'si tambien borras su carpeta, se pierden sus archivos.' @($bAcc))) | Out-Null

$bSin = Nuevo-Boton 'Quitar la contrasena' '#3D6FD9'; $bSin.Tag = 'al=S'
$bCon = Nuevo-Boton 'Volver a usar contrasena'; $bCon.Tag = 'al=R'
$spH.Children.Add((Nueva-Herramienta 'Entrar a Windows sin contrasena' 'tu cuenta pasa a ser local y sin contrasena. Si es una cuenta de Microsoft, te guia para pasarla a local.' 'entras directo a Windows.' 'cualquiera que prenda la PC entra, y no anda el Escritorio remoto.' @($bSin, $bCon))) | Out-Null
$bWin = Nuevo-Boton 'Activacion de Windows' '#3D6FD9'
$bWin.Add_Click({
    $r = [Windows.MessageBox]::Show('Se abre PowerShell y corre el comando oficial de Massgrave:' + "`n`n" + 'irm https://get.activated.win | iex' + "`n`n", 'Xuca OPtimizer', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"'
})
$spH.Children.Add((Nueva-Herramienta 'Activar Windows' 'ejecuta el comando oficial de Massgrave para activar Windows de manera segura.' '' '' @($bWin))) | Out-Null
$Paginas.Herr = $spH

# --- Pagina de restaurar todo ---
$spR = New-Object Windows.Controls.StackPanel
$avisoR = Nueva-Caja
$tR = New-Object Windows.Controls.TextBlock
$tR.TextWrapping = 'Wrap'; $tR.FontSize = 13; $tR.Foreground = (Pincel '#C3C8D0'); $tR.LineHeight = 21
Agregar-Linea $tR 'Que hace: ' '#8AB4F8' 'aprieta R en todas las opciones que tienen R, en los dos scripts: todo vuelve al valor que trae Windows.'
Agregar-Linea $tR 'Tene en cuenta: ' '#E5B567' 'las apps borradas no vuelven (se reinstalan desde la Store). Edge y los Widgets se reinstalan. El antivirus vuelve, pero la Proteccion contra alteraciones la encendes vos y Smart App Control no vuelve sin reinstalar Windows. BitLocker solo deja de estar bloqueado, no vuelve a cifrar el disco. Lo de Herramientas se deshace desde su pagina.'
Agregar-Linea $tR 'Despues: ' '#81C995' 'reinicia la PC para que todo quede aplicado.'
$avisoR.Child = $tR
$spR.Children.Add($avisoR) | Out-Null
$Casillas.Restaurar = @{}
foreach ($par in @(@('Gaming', 'Optimizacion gaming'), @('Debloat', 'Debloat y privacidad'))) {
    $cbR = New-Object Windows.Controls.CheckBox
    $cbR.Content = (Nuevo-Texto ('Restaurar ' + $par[1] + '  (' + @($Opciones[$par[0]] | Where-Object { $_.ConR }).Count + ' opciones)') 15 '#FFFFFF' $true)
    $cbR.IsChecked = $true; $cbR.Margin = '4,8,0,4'; $cbR.Tag = $par[0]
    $Casillas.Restaurar[$par[0]] = $cbR
    $spR.Children.Add($cbR) | Out-Null
}
$Paginas.Restaurar = $spR

$Textos = @{
    Debloat   = @('Debloat y privacidad', 'Lo que se puede sacar o apagar de Windows. Lo que marques aca y en Gaming se aplica junto con un solo Aplicar.')
    Gaming    = @('Optimizacion gaming', 'Ajustes para mas FPS y menos latencia. Lo que marques aca y en Debloat se aplica junto con un solo Aplicar.')
    Limpieza  = @('Limpiar cache', 'Libera espacio. Lo de arriba se limpia siempre; lo de abajo solo si lo marcas.')
    Herr      = @('Herramientas', 'Opciones que te piden datos en la ventana del script.')
    Restaurar = @('Restaurar todo', 'Deja todo como viene Windows, como si tocaras R en cada opcion.')
}
$Nav = @{ Debloat = $ui.NavDebloat; Gaming = $ui.NavGaming; Limpieza = $ui.NavLimpieza; Herr = $ui.NavHerr; Restaurar = $ui.NavRestaurar }
$script:Pagina = 'Debloat'
$script:Ocupado = $false

function Elegidas([string]$p) {
    return @($Casillas[$p].Keys | Where-Object { $Casillas[$p][$_].IsChecked -eq $true })
}

function Actualizar-Contador {
    if ($script:Ocupado) { return }
    $d = (Elegidas 'Debloat').Count; $g = (Elegidas 'Gaming').Count
    if (($d + $g) -eq 0) { $ui.Estado.Text = 'No hay opciones marcadas.' }
    else { $ui.Estado.Text = ('Marcadas: ' + $d + ' en Debloat y ' + $g + ' en Gaming. Se guardan aunque cambies de pagina.') }
}

function Ir-A([string]$p) {
    $script:Pagina = $p
    foreach ($k in $Nav.Keys) { $Nav[$k].Background = (Pincel $(if ($k -eq $p) { '#232833' } else { '#00000000' })) }
    $ui.Titulo.Text = $Textos[$p][0]
    $ui.Descripcion.Text = $Textos[$p][1]
    $ui.Scroll.Content = $Paginas[$p]
    $ui.Scroll.ScrollToTop()
    $vis = $(if ($p -in 'Restaurar', 'Herr') { 'Collapsed' } else { 'Visible' })
    $ui.BtnTodo.Visibility = $vis; $ui.BtnNada.Visibility = $vis
    $ui.BtnAplicar.Visibility = $(if ($p -eq 'Herr') { 'Collapsed' } else { 'Visible' })
    $ui.BtnAplicar.Content = $(switch ($p) { 'Limpieza' { 'Limpiar ahora' } 'Restaurar' { 'Restaurar todo' } default { 'Aplicar seleccionadas' } })
    $ui.BtnAplicar.Background = (Pincel $(if ($p -eq 'Restaurar') { '#B3412F' } else { '#3D6FD9' }))
}

# ------------------------------------------------------------
# Leer el estado de Windows y actualizar las etiquetas
# ------------------------------------------------------------
function Refrescar-Estado {
    $ui.Estado.Text = 'Leyendo como esta tu Windows...'
    $win.Dispatcher.Invoke([Action] {}, [Windows.Threading.DispatcherPriority]::Background)
    $script:Appx = @()
    try { $script:Appx = @(Get-AppxPackage -AllUsers -ErrorAction Stop | ForEach-Object { $_.Name }) } catch { }
    $script:Plan = ([regex]::Match((& powercfg.exe /getactivescheme | Out-String), '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value).ToLower()
    $apl = 0; $tot = 0
    foreach ($k in @($script:Pills.Keys)) {
        $est = $null
        if ($Chequeos.ContainsKey($k)) {
            try { $r = & $Chequeos[$k]; if ($null -ne $r) { $est = [bool](@($r)[-1]) } } catch { $est = $null }
        }
        Poner-Pill $script:Pills[$k] $est
        if ($null -ne $est) { $tot++; if ($est) { $apl++ } }
    }
    if ($script:PrioTexto) {
        $pr = Prio-Actuales
        $script:PrioTexto.Text = $(if ($pr.Count -gt 0) { 'Con prioridad alta ahora: ' + ($pr -join ', ') } else { '' })
    }
    if ($script:AfiTexto) {
        $ac = Afi-Config
        $script:AfiTexto.Text = $(if ($ac['desc'] -and (Get-ScheduledTask -TaskName 'XucaAfinidad' -ErrorAction SilentlyContinue)) { 'Activa: ' + $ac['desc'] } else { '' })
    }
    $bld = 0
    try { $bld = [int](Leer-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'CurrentBuildNumber') } catch { }
    if ($bld -ge 26200) { $script:VerTexto.Text = ('Ya tenes la 25H2 o build mas nueva (build ' + $bld + ').'); $script:BtnVer.IsEnabled = $false }
    else { $script:VerTexto.Text = ('Tu build es ' + $bld + '.'); $script:BtnVer.IsEnabled = $true }
    $ui.Estado.Text = ('Windows leido: ' + $apl + ' de ' + $tot + ' opciones ya estan aplicadas.')
}

# ------------------------------------------------------------
# Correr scripts en modo app (uno atras de otro)
# ------------------------------------------------------------
$script:Cola = New-Object System.Collections.Generic.Queue[object]
$script:Proc = $null
$script:PedirReinicio = $true
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)

function Bloquear([bool]$si) {
    $script:Ocupado = $si
    foreach ($b in @($ui.NavDebloat, $ui.NavGaming, $ui.NavLimpieza, $ui.NavHerr, $ui.NavRestaurar, $ui.BtnRefrescar, $ui.BtnTodo, $ui.BtnNada, $ui.BtnAplicar)) { $b.IsEnabled = -not $si }
    $ui.Scroll.IsEnabled = -not $si
}

function Limpiar-Variables {
    foreach ($v in @(Get-ChildItem Env: | Where-Object { $_.Name -like 'XR_*' })) { Remove-Item -LiteralPath ('Env:' + $v.Name) -ErrorAction SilentlyContinue }
    foreach ($n in 'XUCA_AUTO', 'PRIOJ', 'AFIAPP', 'AFIJ', 'AFIF', 'AFIJX', 'AFIFX', 'AFIJT', 'AFIFT', 'CLEAN_BIN', 'CLEAN_GPU', 'CLEAN_RP') { Remove-Item -LiteralPath ('Env:' + $n) -ErrorAction SilentlyContinue }
}

function Siguiente {
    if ($script:Cola.Count -eq 0) {
        $timer.Stop()
        Limpiar-Variables
        Bloquear $false
        foreach ($p in 'Debloat', 'Gaming') { foreach ($cb in $Casillas[$p].Values) { $cb.IsChecked = $false } }
        if ($Casillas.Debloat.ContainsKey('rp')) { $Casillas.Debloat['rp'].IsChecked = $true }
        Refrescar-Estado
        $ui.Estado.Text = ($ui.Estado.Text + ' Los detalles de cada cambio quedaron en la carpeta de logs.')
        if ($script:PedirReinicio) {
            $r = [Windows.MessageBox]::Show('Termino. Algunos cambios necesitan reiniciar la PC.' + "`n`n" + 'Reiniciar ahora?', 'Xuca OPtimizer', 'YesNo', 'Question')
            if ($r -eq 'Yes') { & shutdown.exe /r /t 10 }
        }
        return
    }
    $t = $script:Cola.Dequeue()
    Limpiar-Variables
    $env:XUCA_AUTO = '1'
    foreach ($k in $t.Vars.Keys) { Set-Item -LiteralPath ('Env:' + $k) -Value ([string]$t.Vars[$k]) }
    $ui.Estado.Text = ($t.Nombre + ': aplicando... Mira la ventana negra para ver el detalle. No la cierres.')
    $script:Proc = Start-Process -FilePath $env:ComSpec -ArgumentList ('/c ""' + $t.Ruta + '""') -WorkingDirectory $Root -PassThru
}

$timer.Add_Tick({
    if ($script:Proc -and $script:Proc.HasExited) { $script:Proc = $null; Siguiente }
})

function Correr($tareas, [bool]$reinicio) {
    $script:PedirReinicio = $reinicio
    $script:Cola.Clear()
    foreach ($t in $tareas) { $script:Cola.Enqueue($t) }
    Bloquear $true
    Siguiente
    $timer.Start()
}

function Titulo-De([string]$p, [string]$id) {
    return (@($Opciones[$p] | Where-Object { $_.Id -eq $id })[0]).Titulo
}

# Ventanita para escribir texto (procesos de los juegos)
function Pedir-Texto([string]$titulo, [string]$mensaje, [string]$inicial) {
    $w = New-Object Windows.Window
    $w.Title = $titulo; $w.Width = 520; $w.SizeToContent = 'Height'; $w.ResizeMode = 'NoResize'
    $w.WindowStartupLocation = 'CenterOwner'; $w.Owner = $win; $w.Background = (Pincel '#14161B'); $w.FontFamily = 'Segoe UI'
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Margin = '20,18,20,18'
    $sp.Children.Add((Nuevo-Texto $mensaje 13 '#C3C8D0' $false)) | Out-Null
    $tx = New-Object Windows.Controls.TextBox
    $tx.Margin = '0,12,0,0'; $tx.Padding = '6,5'; $tx.FontSize = 14; $tx.Text = $inicial
    $tx.Background = (Pincel '#0E1014'); $tx.Foreground = (Pincel '#FFFFFF'); $tx.BorderBrush = (Pincel '#3A404C'); $tx.CaretBrush = (Pincel '#FFFFFF')
    $sp.Children.Add($tx) | Out-Null
    $fila = New-Object Windows.Controls.StackPanel
    $fila.Orientation = 'Horizontal'; $fila.HorizontalAlignment = 'Right'; $fila.Margin = '0,14,0,0'
    $bc1 = Nuevo-Boton 'Cancelar'; $bc1.IsCancel = $true
    $bok = Nuevo-Boton 'Aceptar' '#3D6FD9'; $bok.IsDefault = $true
    $bok.Add_Click({ $w.DialogResult = $true }.GetNewClosure())
    $fila.Children.Add($bc1) | Out-Null
    $fila.Children.Add($bok) | Out-Null
    $sp.Children.Add($fila) | Out-Null
    $w.Content = $sp
    $w.Add_ContentRendered({ $tx.Focus() | Out-Null; $tx.SelectAll() }.GetNewClosure())
    if ($w.ShowDialog()) { return $tx.Text.Trim() }
    return $null
}

# Ventana con casillas para elegir juegos o programas, y un campo para agregar otros.
# Devuelve los procesos elegidos separados por comas ('' si no elegiste ninguno) o $null si cancelas.
function Elegir-Lista([string]$titulo, [string]$mensaje, $items, [string]$ayudaExtra) {
    $w = New-Object Windows.Window
    $w.Title = $titulo; $w.Width = 640; $w.Height = 660; $w.MinWidth = 520; $w.MinHeight = 420
    $w.WindowStartupLocation = 'CenterOwner'; $w.Owner = $win; $w.Background = (Pincel '#14161B'); $w.FontFamily = 'Segoe UI'
    $dock = New-Object Windows.Controls.DockPanel
    $dock.Margin = '20,18,20,16'
    $msg = Nuevo-Texto $mensaje 13 '#C3C8D0' $false
    $msg.Margin = '0,0,0,10'
    [Windows.Controls.DockPanel]::SetDock($msg, 'Top')
    $dock.Children.Add($msg) | Out-Null

    $abajo = New-Object Windows.Controls.StackPanel
    [Windows.Controls.DockPanel]::SetDock($abajo, 'Bottom')
    $lx = Nuevo-Texto $ayudaExtra 12.5 '#9AA0A6' $false
    $lx.Margin = '0,12,0,4'
    $abajo.Children.Add($lx) | Out-Null
    $tx = New-Object Windows.Controls.TextBox
    $tx.Padding = '6,5'; $tx.FontSize = 13.5
    $tx.Background = (Pincel '#0E1014'); $tx.Foreground = (Pincel '#FFFFFF'); $tx.BorderBrush = (Pincel '#3A404C'); $tx.CaretBrush = (Pincel '#FFFFFF')
    $abajo.Children.Add($tx) | Out-Null
    $fila = New-Object Windows.Controls.DockPanel
    $fila.Margin = '0,6,0,0'
    $der = New-Object Windows.Controls.StackPanel
    $der.Orientation = 'Horizontal'
    [Windows.Controls.DockPanel]::SetDock($der, 'Right')
    $bc1 = Nuevo-Boton 'Cancelar'; $bc1.IsCancel = $true
    $bok = Nuevo-Boton 'Aceptar' '#3D6FD9'; $bok.IsDefault = $true
    $der.Children.Add($bc1) | Out-Null
    $der.Children.Add($bok) | Out-Null
    $fila.Children.Add($der) | Out-Null
    $izq = New-Object Windows.Controls.StackPanel
    $izq.Orientation = 'Horizontal'
    $bTodo = Nuevo-Boton 'Marcar todo'; $bNada = Nuevo-Boton 'Desmarcar todo'
    $izq.Children.Add($bTodo) | Out-Null
    $izq.Children.Add($bNada) | Out-Null
    $fila.Children.Add($izq) | Out-Null
    $abajo.Children.Add($fila) | Out-Null
    $dock.Children.Add($abajo) | Out-Null

    $grilla = New-Object Windows.Controls.Primitives.UniformGrid
    $grilla.Columns = 2
    $cbs = New-Object System.Collections.Generic.List[object]
    foreach ($it in $items) {
        $cb = New-Object Windows.Controls.CheckBox
        $cb.Margin = '2,4,8,4'; $cb.VerticalContentAlignment = 'Center'; $cb.IsChecked = [bool]$it.Marcado
        $cb.Tag = ($it.Procs -join ',')
        $cb.ToolTip = ('Proceso: ' + ($it.Procs -join ', '))
        $t = New-Object Windows.Controls.TextBlock
        $t.TextWrapping = 'Wrap'
        $r1 = New-Object Windows.Documents.Run($it.Nombre); $r1.Foreground = (Pincel '#FFFFFF'); $r1.FontSize = 13.5
        $t.Inlines.Add($r1)
        if ($it.Nombre -ne ($it.Procs -join ', ')) {
            $t.Inlines.Add((New-Object Windows.Documents.LineBreak))
            $r2 = New-Object Windows.Documents.Run(($it.Procs -join ', ')); $r2.Foreground = (Pincel '#7D8590'); $r2.FontSize = 11
            $t.Inlines.Add($r2)
        }
        $cb.Content = $t
        $grilla.Children.Add($cb) | Out-Null
        $cbs.Add($cb)
    }
    $caja = New-Object Windows.Controls.Border
    $caja.CornerRadius = 10; $caja.Background = (Pincel '#1C2027'); $caja.Padding = '12,8'
    $sv = New-Object Windows.Controls.ScrollViewer
    $sv.VerticalScrollBarVisibility = 'Auto'
    $sv.Content = $grilla
    $caja.Child = $sv
    $dock.Children.Add($caja) | Out-Null

    $bTodo.Add_Click({ foreach ($c in $cbs) { $c.IsChecked = $true } }.GetNewClosure())
    $bNada.Add_Click({ foreach ($c in $cbs) { $c.IsChecked = $false } }.GetNewClosure())
    $bok.Add_Click({ $w.DialogResult = $true }.GetNewClosure())
    $w.Content = $dock
    if (-not $w.ShowDialog()) { return $null }
    $sel = @($cbs | Where-Object { $_.IsChecked -eq $true } | ForEach-Object { [string]$_.Tag })
    $extra = $tx.Text.Trim()
    if ($extra) { $sel += $extra }
    return ($sel -join ',')
}

# ------------------------------------------------------------
# Botones
# ------------------------------------------------------------
$ui.NavDebloat.Add_Click({ Ir-A 'Debloat' })
$ui.NavGaming.Add_Click({ Ir-A 'Gaming' })
$ui.NavLimpieza.Add_Click({ Ir-A 'Limpieza' })
$ui.NavHerr.Add_Click({ Ir-A 'Herr' })
$ui.NavRestaurar.Add_Click({ Ir-A 'Restaurar' })
$ui.BtnRefrescar.Add_Click({ Refrescar-Estado })
$ui.BtnRedes.Add_Click({ Start-Process $Redes })

$ui.BtnLogs.Add_Click({
    $d = Join-Path $Scripts 'logs'
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $d + '"')
})

$ui.BtnTodo.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $true }; Actualizar-Contador })
$ui.BtnNada.Add_Click({ foreach ($cb in $Casillas[$script:Pagina].Values) { $cb.IsChecked = $false }; Actualizar-Contador })

# Botones de Herramientas: cada uno corre el debloat con una sola opcion respondida
$accionHerr = {
    $par = ([string]$this.Tag) -split '='
    $nombres = @{ ver = 'Actualizar a Windows 11 25H2'; ms_acc = 'Borrar una cuenta'; al = 'Entrar sin contrasena' }
    $txt = $nombres[$par[0]]
    if ($par[1] -eq 'R') { $txt = 'Volver a usar contrasena' }
    $r = [Windows.MessageBox]::Show(($txt + ': se abre la ventana negra del script y ahi te va pidiendo lo que necesita.' + "`n`n" + 'Seguir?'), 'Xuca OPtimizer', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }
    $v = @{}; $v['XR_' + $par[0]] = $par[1]
    Correr @([pscustomobject]@{ Nombre = $txt; Ruta = $Rutas.Debloat; Vars = $v }) $false
}
foreach ($b in @($script:BtnVer, $bAcc, $bSin, $bCon)) { $b.Add_Click($accionHerr) }

$ui.BtnAplicar.Add_Click({
    $p = $script:Pagina

    if ($p -eq 'Limpieza') {
        $v = @{}
        foreach ($k in $Casillas.Limpieza.Keys) { $v[$k] = $(if ($Casillas.Limpieza[$k].IsChecked) { '1' } else { '0' }) }
        $r = [Windows.MessageBox]::Show('Se va a limpiar la cache. Cerra los juegos y programas abiertos antes de seguir.' + "`n`n" + 'Seguir?', 'Xuca OPtimizer', 'YesNo', 'Question')
        if ($r -ne 'Yes') { return }
        Correr @([pscustomobject]@{ Nombre = 'Limpieza'; Ruta = $Rutas.Limpieza; Vars = $v }) $false
        return
    }

    if ($p -eq 'Restaurar') {
        $tareas = @()
        foreach ($k in 'Debloat', 'Gaming') {
            if ($Casillas.Restaurar[$k].IsChecked -ne $true) { continue }
            $v = @{}
            foreach ($it in $Opciones[$k]) { if ($it.ConR) { $v['XR_' + $it.Id] = 'R' } }
            $tareas += [pscustomobject]@{ Nombre = ('Restaurar ' + $k); Ruta = $Rutas[$k]; Vars = $v }
        }
        if ($tareas.Count -eq 0) { [Windows.MessageBox]::Show('Marca al menos un script para restaurar.', 'Xuca OPtimizer') | Out-Null; return }
        $r = [Windows.MessageBox]::Show('Todo va a volver a como viene Windows (lee los avisos de la pagina).' + "`n`n" + 'Seguir?', 'Xuca OPtimizer', 'YesNo', 'Warning')
        if ($r -ne 'Yes') { return }
        Correr $tareas $true
        return
    }

    # Debloat y Gaming: se aplica lo marcado en las dos paginas, en una sola pasada
    $selD = Elegidas 'Debloat'
    $selG = Elegidas 'Gaming'
    if (($selD.Count + $selG.Count) -eq 0) { [Windows.MessageBox]::Show('No marcaste ninguna opcion.', 'Xuca OPtimizer') | Out-Null; return }

    $vG = @{}
    foreach ($id in $selG) { $vG['XR_' + $id] = 'S' }
    if ($selG -contains 'pri') {
        $j = Pedir-Texto 'Prioridad alta para tus juegos' ('Escribi el proceso de cada juego, sin el .exe y separados por comas.' + "`n" + 'Lo ves con el juego abierto: Administrador de tareas, pestana Detalles.') ((Prio-Actuales) -join ', ')
        if ($null -eq $j) { return }
        if (-not $j) { [Windows.MessageBox]::Show('No escribiste ningun proceso. Desmarca "Dar prioridad alta a tus juegos" o escribi al menos uno.', 'Xuca OPtimizer') | Out-Null; return }
        $vG['PRIOJ'] = $j
    }
    if ($selG -contains 'afi') {
        $j = Elegir-Lista 'Afinidad: tus juegos' ('Marca los juegos que quieras en los mejores nucleos. Vienen los mas comunes; si ya lo usaste, te muestra lo que elegiste la vez pasada.' + "`n" + 'Si un juego no tiene antitrampas que lo bloquee, se aplica a los 2 segundos de abrirlo.') (Afi-Items $AfiJuegosCat 'juegos') 'Agregar otros juegos: escribi su proceso sin .exe, separados por comas. Lo ves con el juego abierto: Administrador de tareas, pestana Detalles.'
        if ($null -eq $j) { return }
        if (-not $j) { [Windows.MessageBox]::Show('No elegiste ningun juego. Desmarca "Usar afinidad de CPU para tus juegos" o elegi al menos uno.', 'Xuca OPtimizer') | Out-Null; return }
        $f = Elegir-Lista 'Afinidad: programas de fondo' ('Marca los programas que se van a otros nucleos mientras jugas. Cuando cerras el juego vuelven a usar todos.' + "`n" + 'OBS, Visual Studio, Unreal, Godot, el sistema y los antitrampas nunca se tocan aunque los escribas.') (Afi-Items $AfiFondoCat 'apps') 'Agregar otros programas, separados por comas. No pongas launchers (Steam, Epic, Battle.net): los juegos que abren heredarian esos nucleos.'
        if ($null -eq $f) { return }
        $vG['AFIAPP'] = '1'
        $vG['AFIJ'] = $j
        if ($f) { $vG['AFIF'] = $f }
    }

    $vD = @{}
    foreach ($id in $selD) { $vD['XR_' + $id] = 'S' }
    if ($selD -contains 'av') {
        $m = 'Para apagar el antivirus del todo, primero apaga vos la "Proteccion contra alteraciones" (Windows no deja que un programa la apague).' + "`n`n" + 'Se va a abrir Seguridad de Windows. Apagala y despues toca Aceptar aca.'
        Start-Process 'windowsdefender://threatsettings'
        $r = [Windows.MessageBox]::Show($m, 'Antivirus', 'OKCancel', 'Information')
        if ($r -ne 'OK') { return }
    }

    $lista = ''
    if ($selD.Count -gt 0) { $lista += 'Debloat:' + "`n" + (($selD | ForEach-Object { '- ' + (Titulo-De 'Debloat' $_) }) -join "`n") + "`n`n" }
    if ($selG.Count -gt 0) { $lista += 'Gaming:' + "`n" + (($selG | ForEach-Object { '- ' + (Titulo-De 'Gaming' $_) }) -join "`n") + "`n`n" }
    if (($selD -notcontains 'rp') -and ($selD -notcontains 'rpo')) { $lista += 'Ojo: no marcaste crear un punto de restauracion.' + "`n`n" }
    $r = [Windows.MessageBox]::Show(('Se va a aplicar:' + "`n`n" + $lista + 'Seguir?'), 'Xuca OPtimizer', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }

    $tareas = @()
    if ($selD.Count -gt 0) { $tareas += [pscustomobject]@{ Nombre = 'Debloat y privacidad'; Ruta = $Rutas.Debloat; Vars = $vD } }
    if ($selG.Count -gt 0) { $tareas += [pscustomobject]@{ Nombre = 'Optimizacion gaming'; Ruta = $Rutas.Gaming; Vars = $vG } }
    Correr $tareas $true
})

$win.Add_Closing({
    if ($script:Proc -and -not $script:Proc.HasExited) {
        $r = [Windows.MessageBox]::Show('Todavia se esta aplicando un script. Si cerras la app, el script sigue solo en su ventana.' + "`n`n" + 'Cerrar igual?', 'Xuca OPtimizer', 'YesNo', 'Warning')
        if ($r -ne 'Yes') { $_.Cancel = $true }
    }
})

$win.Add_ContentRendered({ Refrescar-Estado })

Ir-A 'Debloat'
$ui.Estado.Text = 'Abriendo...'
$win.ShowDialog() | Out-Null

} catch {
    Mostrar-Error ('La app tuvo un error y se cerro:' + "`n`n" + $_.Exception.Message + "`n`n" + 'Linea: ' + $_.InvocationInfo.ScriptLineNumber)
}
