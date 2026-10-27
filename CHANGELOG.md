# Cambios

Todo lo que cambió en cada versión de **Xuca OPtimizer**. La más nueva va arriba.

## v1.0.4

### Nuevo
- Opción Gaming **Limitar el cable a 1 Gbps**: para placas de red de 2.5 Gbps (como las Realtek 2.5GbE) que se cortan solas. Se puede restablecer y pide reiniciar.
- Perfil nuevo **Optimizado**: todo lo de Seguro y además Windows más liviano (sin hibernación, efectos visuales ni apps de inicio basura), sin tocar la seguridad ni los ajustes de juego.
- **Limpiar caché** ahora también borra restos de instalaciones: instaladores de drivers de NVIDIA y AMD ya usados, temporales de OneDrive y descargas viejas de Windows Update.
- **Xuca Monitor** en Apps recomendadas.
- Ícono propio (`XucaOP.ico`) en la app, el acceso directo y el README.

### Cambios
- **Seguro** ahora también borra las apps basura y apaga los servicios que casi nadie usa.
- **Competitivo** y **Competitivo + Optimizado** ya no apagan el ahorro de energía de USB, PCIe y red ni el algoritmo de Nagle (podían causar cortes). Tienen un ícono ⚠ que explica sus riesgos.
- **Competitivo + Optimizado** ahora es exactamente Competitivo más Optimizado.
- **Debloat - Notebook** ahora también borra las apps basura.
- Si tocás un perfil antes de que la app termine de leer Windows, te pide que esperes.
- Avisos más claros en el ahorro de energía de USB/PCIe y en las notebooks.

## v1.0.3

### Nuevo
- **Borrar las apps basura** y **Apagar apps de inicio** muestran cuántas quedan ("50/62 borradas") en vez de solo "Ya aplicado".
- Las opciones que instaló una versión vieja aparecen como **Desactualizada**. Al aplicarlas se pone la versión nueva.
- **Instalar Chrome** no aparece si ya tenés Chrome.
- Apps basura nuevas en la lista: Dispositivos móviles y Game Speech Window.

### Cambios
- La app lee Windows **mucho más rápido** (hace varias cosas a la vez).
- **Aplicar** también es más rápido, porque los scripts usan lo que la app ya leyó.
- **Buscar drivers** no marca como viejas a las placas de video que la marca casi no actualiza (AMD Vega/Polaris, NVIDIA GTX 900/1000, Intel HD/UHD 600) hasta que pasa un año.
- Al bajar una config se abre su carpeta.

## v1.0.2

La versión más grande: casi toda la app nueva.

### Nuevo
- Pantalla de **Inicio** que explica cómo se usa y qué hay en cada sección.
- **Buscar drivers** (en Herramientas): revisa tu PC y te abre la página oficial de lo que falta (placa madre, video, chipset, programa de tu mouse o teclado, BIOS vieja). No instala nada.
- Las opciones que necesitan un driver tienen borde **violeta** y te avisan cuál falta.
- Las opciones que no son compatibles con tu PC aparecen en **gris con borde rojo** y te dicen por qué.
- Sección **Apps recomendadas**: programas gratis desde su página oficial.
- Sección **Configs recomendadas**: configs de juegos que se bajan al escritorio.
- **Barra de búsqueda** (Ctrl + F).
- **Tema claro, oscuro o el del sistema**.
- Botón verde **Marcar solo seguras**.
- El **punto de restauración** se ofrece una sola vez al tocar Aplicar.
- Opciones nuevas:
  - **Apagar el Modo Xbox**.
  - **WiFi y cable a la vez** sin cortes.
  - **Apagar apps de inicio basura**.
  - **Priorizar la batería de la notebook**.
- Perfiles **Debloat - Notebook** y **Competitivo - Notebook**.
- **Competitivo** suma Baja latencia y Modo Xbox apagado.
- Quitar Vanguard también borra sus restos.
- Limpiar caché borra **Windows.old** con más cuidado y te muestra cuántos GB liberaste.

### Cambios
- Animaciones nuevas: la intro, los carteles y los botones.
- Más seguridad: la carpeta de la app solo la pueden cambiar los administradores, y los links se abren sin permisos de administrador.
- Si algo falla al tocar un botón, la app avisa sin cerrarse.
- La actualización baja todos los archivos y avisa solo si hay una versión distinta.
- Opciones que se adaptan a Windows 10.

## v1.0.1

### Nuevo
- Opción **Desactivar el ahorro de energía de la red** (menos picos de ping).
- La lista de juegos para prioridad y afinidad se arma con **los juegos que tenés instalados** (Steam, Epic, EA, Battle.net, Ubisoft, Riot, Xbox, GOG, Rockstar y Minecraft). Los juegos nuevos se suman solos.
- La opción de DNS prueba cuál anda más rápido en tu conexión y te lo muestra.
- **Zoom**: Ctrl + rueda del mouse, o Ctrl + / Ctrl -.

## v1.0.0

Primera versión: la app con casillas para Debloat, Gaming, Limpiar caché y Herramientas, en español e inglés.
