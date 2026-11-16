$Usuario = '011Xuca'
$Repo    = 'brio'
$Rama    = 'main'
$Destino = Join-Path $env:LOCALAPPDATA 'Brio'
# La i con tilde con [char]: el archivo va en ASCII
$Nombre  = 'Br' + [string][char]0xED + 'o'

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host ($Nombre + ' necesita PowerShell 5.1. En Windows 7 SP1 instala WMF 5.1 (https://aka.ms/wmf51download) y volve a probar.') -ForegroundColor Red
    return
}
# 3072 = TLS 1.2 (GitHub no acepta menos; Windows 7 no lo usa solo)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072
$tmp = Join-Path $env:TEMP ('brio_' + [guid]::NewGuid().ToString('N'))

try {
    Write-Host ('Descargando ' + $Nombre + '...') -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp 'app.zip'
    Invoke-WebRequest -Uri ('https://github.com/' + $Usuario + '/' + $Repo + '/archive/refs/heads/' + $Rama + '.zip') -OutFile $zip -UseBasicParsing -ErrorAction Stop

    Write-Host 'Instalando...' -ForegroundColor Cyan
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    $src = Join-Path $tmp ($Repo + '-' + $Rama)
    if (-not (Test-Path -LiteralPath (Join-Path $src 'Brio.bat'))) { throw 'lo que se descargo no tiene Brio.bat.' }

    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    Copy-Item -Path (Join-Path $src '*') -Destination $Destino -Recurse -Force -ErrorAction Stop

    $esc = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell
    $acc = $ws.CreateShortcut((Join-Path $esc ($Nombre + '.lnk')))
    $acc.TargetPath = Join-Path $Destino 'Brio.bat'
    $acc.WorkingDirectory = $Destino
    # Icono propio de la app (si no esta, el del Administrador de tareas)
    $ico = Join-Path $Destino 'Brio.ico'
    if (-not (Test-Path -LiteralPath $ico)) { $ico = Join-Path $env:SystemRoot 'System32\Taskmgr.exe' }
    if (Test-Path -LiteralPath $ico) { $acc.IconLocation = $ico + ',0' }
    $acc.Save()

    # Contador de instalaciones (solo suma 1, no manda ningun dato). Si falla, no pasa nada.
    try { Invoke-RestMethod -Uri 'https://abacus.jasoncameron.dev/hit/011xuca/xuca-optimizer-instalaciones' -TimeoutSec 4 -UseBasicParsing | Out-Null } catch {}

    Write-Host ('Listo: instalado en ' + $Destino) -ForegroundColor Green
    Write-Host 'Tambien quedo un acceso directo en el escritorio.' -ForegroundColor Green
    Start-Process -FilePath (Join-Path $Destino 'Brio.bat') -WorkingDirectory $Destino
} catch {
    Write-Host ('No se pudo instalar: ' + $_.Exception.Message) -ForegroundColor Red
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
