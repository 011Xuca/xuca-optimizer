<img src="Brio.ico" width="96" alt="Icono de Brío">

# Brío

Optimizador gratis para **Windows 10 y 11**. Es una app con casillas: marcás lo que querés y tocás **Aplicar**. Antes de tocar nada lee tu PC: te muestra lo que ya tenés aplicado y deja en gris lo que no es compatible. Cada opción te explica qué hace, qué ganás y qué perdés.

## Instalar

Abrí **PowerShell** y pegá esto:

```powershell
irm https://raw.githubusercontent.com/011Xuca/brio/main/install.ps1 | iex
```

Se instala en `%LOCALAPPDATA%\Brio` y te deja el acceso directo **Brío** en el escritorio. La app pide permisos de administrador al abrirse.

También podés bajar el repo como ZIP y abrir `Brio.bat`.

**Windows 7 SP1 y 8.1:** primero instalá [WMF 5.1](https://aka.ms/wmf51download) (trae PowerShell 5.1) y usá este comando, que activa TLS 1.2 para poder bajar de GitHub:

```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://raw.githubusercontent.com/011Xuca/brio/main/install.ps1 | iex
```

Ahí las opciones que necesitan Windows 10 u 11 aparecen en gris y no se aplican.

## Cómo se usa

1. Al abrir la app ves la **bienvenida**, con un resumen de todo. Elegí una sección en la barra de la izquierda (si no sabés por dónde empezar, andá a **Perfiles**).
2. Marcá lo que quieras: tocá cualquier parte de una opción para marcarla. Lo que marques en Debloat y en Gaming se aplica junto.
3. Tocá **Aplicar**. Antes te ofrece crear un **punto de restauración** (una sola vez, y podés pedirle que no vuelva a preguntar).

## Qué trae

| Sección | Para qué sirve |
|---|---|
| **Perfiles** | Combos listos (Seguro, Competitivo, Full Optimizado...) que se aplican con un toque. Competitivo está pensado para Valorant, CS2, Fortnite, Warzone, Marvel Rivals, LoL y Deadlock, sin tocar la seguridad. |
| **Debloat y privacidad** | Saca publicidad, telemetría, IA de Windows, apps basura y apps de inicio que no hacen falta. |
| **Zona gamer** | Mouse sin aceleración, prioridad y afinidad para tus juegos, plan de energía, red, DNS y más. |
| **Limpiar caché** | Borra temporales, caché de Windows Update, shaders y otras cosas que ocupan espacio. |
| **Herramientas** | Drivers recomendados, ajustes de la BIOS, actualizar a Windows 11 26H2 (sin ventanas negras: revisa y arregla lo que impide actualizar), escanear y reparar Windows (DISM + SFC), cuenta local sin Microsoft, entrar sin contraseña y más. |
| **Apps recomendadas** | Programas gratis para revisar, cuidar y limpiar tu PC (CrystalDiskInfo, HWiNFO, DDU, WizTree y más). Cada uno se baja de su página oficial. |
| **Configs recomendadas** | Configs de juegos y apps que subo a GitHub. Se bajan al escritorio con sus instrucciones. El circulito azul dice cuántas hay. |

- En Debloat y Gaming las opciones van agrupadas en categorías ordenadas por impacto: arriba lo que más rendimiento da, abajo la comodidad y la privacidad. Cada categoría se **pliega** con un toque (o con el teclado), muestra cuántas opciones tiene y cuántas marcaste, y la app se acuerda de lo que dejaste plegado. Buscar despliega las categorías con resultados.
- Las opciones que juntaban cosas distintas están separadas (por ejemplo, la ubicación y el historial de actividad son casillas aparte), así elegís exactamente qué tocar.
- El botón verde **Marcar solo seguras** marca solo las opciones sin ⚠.
- Cada opción dice si ya está aplicada en tu PC.
- Lo que no es compatible con tu Windows aparece en gris.

## Drivers

- Las opciones con borde **violeta** necesitan un driver. Si te falta, la app no te deja marcarla: te avisa cuál falta y te lleva a **Herramientas > Buscar drivers**. Un perfil que necesita drivers que te faltan no se aplica hasta que los instales.
- **Buscar drivers** revisa tu PC y te muestra qué conviene bajar (placa de video, chipset, lo que falta de tu placa madre, el programa de tu mouse, teclado o auriculares y si la BIOS está vieja). **No instala nada**: solo te abre la página oficial de lo que falta.

## Antes de usarlo

- **Las opciones con ⚠ (borde amarillo) pueden dar problemas en algunas PCs.** Si pasás el mouse por encima, te dice por qué.
- **Xbox, Game Pass y Minecraft:** lo que toca Xbox o la Game Bar avisa en su tarjeta, no lo marca "Marcar solo seguras" y, antes de aplicarlo, la app te pregunta (con **Sin Xbox** se aplica todo lo demás sin eso). Gaming Services solo lo borra **Quitar Xbox completo**, que no está en ningún perfil. Los perfiles Seguro, Optimizado y RAM no tocan Xbox; los Competitivo solo borran la Game Bar (preguntando antes).
- Casi todo se puede deshacer: marcalo y tocá **Restablecer seleccionadas**. Si una opción no se puede deshacer, te lo avisa.
- Los perfiles **Full Optimizado** apagan el antivirus: la app te lo avisa antes de aplicarlos.

## Más cosas

- **Actualizaciones:** al abrirse, la app revisa si hay una versión nueva en GitHub y te avisa con un cartel azul.
- **Idioma:** español o inglés, con el botón de abajo a la izquierda.
- **Logs:** con "Abrir carpeta de logs" ves todo lo que se cambió.
- **Zoom:** Ctrl + rueda del mouse (o Ctrl + / Ctrl -) agranda o achica la app. Ctrl + 0 la vuelve al tamaño normal.
- La optimización para gaming (`scripts/Gaming.ps1`), el debloat (`scripts/Debloat.ps1`) y la limpieza (`scripts/Limpieza.ps1`) corren dentro de la app, sin abrir ventanas de consola. Solo borrar una cuenta y entrar sin contraseña abren una ventana de PowerShell para pedirte datos.

## Créditos

Hecho por **011Xuca**. Redes: https://011xuca.github.io/links/
Si te sirvió, podés apoyarme en Ko-fi: https://ko-fi.com/011xuca