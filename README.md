<img src="XucaOP.ico" width="96" alt="Icono de Xuca OPtimizer">

# Xuca OPtimizer

Optimizador gratis para **Windows 10 y 11**. Es una app con casillas: marcás lo que querés y tocás **Aplicar**. Antes de tocar nada lee tu PC: te muestra lo que ya tenés aplicado y deja en gris lo que no es compatible. Cada opción te explica qué hace, qué ganás y qué perdés.

## Instalar

Abrí **PowerShell** y pegá esto:

```powershell
irm https://raw.githubusercontent.com/011Xuca/xuca-optimizer/main/install.ps1 | iex
```

Se instala en `%LOCALAPPDATA%\Xuca OPtimizer` y te deja el acceso directo **Xuca OPtimizer** en el escritorio. La app pide permisos de administrador al abrirse.

También podés bajar el repo como ZIP y abrir `XucaOP.bat`.

## Cómo se usa

1. Al abrir la app ves la **bienvenida**, con un resumen de todo. Elegí una sección en la barra de la izquierda (si no sabés por dónde empezar, andá a **Perfiles**).
2. Marcá lo que quieras: tocá cualquier parte de una opción para marcarla. Lo que marques en Debloat y en Gaming se aplica junto.
3. Tocá **Aplicar**. Antes te ofrece crear un **punto de restauración** (una sola vez, y podés pedirle que no vuelva a preguntar).

## Qué trae

| Sección | Para qué sirve |
|---|---|
| **Perfiles** | Combos listos (Seguro, Competitivo, Full Optimizado...) que se aplican con un toque. Competitivo está pensado para Valorant, CS2, Fortnite, Warzone, Marvel Rivals, LoL y Deadlock, sin tocar la seguridad. |
| **Debloat y privacidad** | Saca publicidad, telemetría, IA de Windows, apps basura y apps de inicio que no hacen falta. |
| **Optimización gaming** | Mouse sin aceleración, prioridad y afinidad para tus juegos, plan de energía, red, DNS y más. |
| **Limpiar caché** | Borra temporales, caché de Windows Update, shaders y otras cosas que ocupan espacio. |
| **Herramientas** | Drivers recomendados, actualizar Windows, entrar sin contraseña y otras opciones que te piden datos. |
| **Apps recomendadas** | Programas gratis para revisar, cuidar y limpiar tu PC (CrystalDiskInfo, HWiNFO, DDU, WizTree y más). Cada uno se baja de su página oficial. |
| **Configs recomendadas** | Configs de juegos y apps que subo a GitHub. Se bajan al escritorio con sus instrucciones. El circulito verde dice cuántas hay. |

- El botón verde **Marcar solo seguras** marca solo las opciones sin ⚠.
- Cada opción dice si ya está aplicada en tu PC.
- Lo que no es compatible con tu Windows aparece en gris.

## Drivers

- Las opciones con borde **violeta** necesitan un driver. Si te falta, la app no te deja marcarla: te avisa cuál falta y te lleva a **Herramientas > Buscar drivers**. Los perfiles también te avisan antes de seguir.
- **Buscar drivers** revisa tu PC y te muestra qué conviene bajar (placa de video, chipset, lo que falta de tu placa madre, el programa de tu mouse, teclado o auriculares y si la BIOS está vieja). **No instala nada**: solo te abre la página oficial de lo que falta.

## Antes de usarlo

- **Las opciones con ⚠ (borde amarillo) pueden dar problemas en algunas PCs.** Si pasás el mouse por encima, te dice por qué.
- Casi todo se puede deshacer: marcalo y tocá **Restablecer seleccionadas**. Si una opción no se puede deshacer, te lo avisa.
- Los perfiles **Full Optimizado** apagan el antivirus: la app te lo avisa antes de aplicarlos.

## Más cosas

- **Actualizaciones:** al abrirse, la app revisa si hay una versión nueva en GitHub y te avisa con un cartel amarillo.
- **Idioma:** español o inglés, con el botón de abajo a la izquierda.
- **Logs:** con "Abrir carpeta de logs" ves todo lo que se cambió.
- **Zoom:** Ctrl + rueda del mouse (o Ctrl + / Ctrl -) agranda o achica la app. Ctrl + 0 la vuelve al tamaño normal.
- La optimización para gaming (`scripts/Gaming.ps1`), el debloat (`scripts/Debloat.ps1`) y la limpieza (`scripts/Limpieza.ps1`) corren dentro de la app, sin abrir ventanas de consola. Solo las herramientas que te piden datos (actualizar Windows, borrar una cuenta, entrar sin contraseña) abren una ventana de PowerShell.

## Créditos

Hecho por **011Xuca**. Redes: https://linktr.ee/011xuca
Si te sirvió, podés apoyarme en Ko-fi: https://ko-fi.com/011xuca