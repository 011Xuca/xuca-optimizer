$Usuario = '011Xuca'
$Repo    = 'xuca-optimizer'
$Rama    = 'main'
$Destino = Join-Path $env:LOCALAPPDATA 'Xuca OPtimizer'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tmp = Join-Path $env:TEMP ('xucaop_' + [guid]::NewGuid().ToString('N'))

try {
    Write-Host 'Descargando Xuca OPtimizer...' -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp 'app.zip'
    Invoke-WebRequest -Uri ('https://github.com/' + $Usuario + '/' + $Repo + '/archive/refs/heads/' + $Rama + '.zip') -OutFile $zip -UseBasicParsing -ErrorAction Stop

    Write-Host 'Instalando...' -ForegroundColor Cyan
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    $src = Join-Path $tmp ($Repo + '-' + $Rama)
    if (-not (Test-Path -LiteralPath (Join-Path $src 'XucaOP.bat'))) { throw 'lo que se descargo no tiene XucaOP.bat.' }

    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    Copy-Item -Path (Join-Path $src '*') -Destination $Destino -Recurse -Force -ErrorAction Stop
    Get-ChildItem -LiteralPath $Destino -File -Recurse | Unblock-File -ErrorAction SilentlyContinue

    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Xuca OPtimizer.lnk'
    $ws = New-Object -ComObject WScript.Shell
    $acc = $ws.CreateShortcut($lnk)
    $acc.TargetPath = Join-Path $Destino 'XucaOP.bat'
    $acc.WorkingDirectory = $Destino
    # Icono: el del Administrador de tareas
    $ico = Join-Path $env:SystemRoot 'System32\Taskmgr.exe'
    if (Test-Path -LiteralPath $ico) { $acc.IconLocation = $ico + ',0' }
    $acc.Save()

    Write-Host ('Listo: instalado en ' + $Destino) -ForegroundColor Green
    Write-Host 'Tambien quedo un acceso directo "Xuca OPtimizer" en el escritorio.' -ForegroundColor Green
    Start-Process -FilePath (Join-Path $Destino 'XucaOP.bat') -WorkingDirectory $Destino
} catch {
    Write-Host ('No se pudo instalar: ' + $_.Exception.Message) -ForegroundColor Red
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
