# Cambios

Todo lo que cambió en cada versión de **Xuca OPtimizer**. La más nueva va arriba.

## v1.0.7

### Nuevo
- **Medir FPS antes y después** (en Herramientas): medí tu juego antes de aplicar cambios y después, y la app te muestra la diferencia en FPS promedio, 1% low y 0.1% low (en número y en %). Elegís cuánto medir (30, 60 o 120 segundos) y qué juego, o dejás que tome el que está en pantalla completa. Usa **PresentMon** de Intel, que lee el tiempo de cada cuadro desde Windows sin overlay y sin meterse en el juego: no viene con la app, se baja de su GitHub oficial la primera vez y se verifica antes de usarlo. Si algún cambio pide reiniciar, la app se acuerda de la medición de antes y te avisa que midas después de reiniciar. Cada medición queda en la carpeta de logs como `benchmark_` con la fecha, en CSV y en texto.
- **Desactivar los estados de reposo del procesador (C-states)** en Optimización gaming ⚠: los núcleos dejan de dormirse, a cambio de mucho más consumo y calor. Lo que gana en FPS depende del juego: medilo con el benchmark antes de decidir. Guarda tus valores para poder volver atrás.
- **Desactivar las protecciones contra Spectre y Meltdown** en Optimización gaming ⚠: en algunos juegos puede dar más FPS, pero baja mucho la seguridad de la PC. Medilo con el benchmark antes de decidir. Solo aparece si tu procesador tiene esas protecciones activas, pide reiniciar y se puede restablecer.

## v1.0.6

### Nuevo
- **Pantalla completa**: apretá **F11** para ver la app en pantalla completa. F11 o Esc la sacan.
- **Ajustes de la BIOS** (en Herramientas): revisa qué opciones útiles de la BIOS tenés activadas (Resizable BAR, Above 4G, perfil XMP/EXPO de la RAM, virtualización, Secure Boot, TPM, modo UEFI y la memoria del gráfico integrado) y te dice dónde activar las que te faltan según la marca de tu placa y tu procesador. Si tu placa o tu procesador no soportan algo, te lo avisa, y si hace falta una BIOS nueva, te abre la página de tu placa.

### Cambios
- En **Optimización gaming**, el "Con tu procesador:" de **Afinidad de CPU** y de la **Game Bar** ahora es rosa, para que no se confunda con "Qué hace:".

## v1.0.5

### Nuevo
- **Undervolt y overclock de la placa de video** (en Herramientas): lee tu placa, puede medirla mientras jugás un minuto (NVIDIA) y te recomienda valores según lo que busques: más fresca y silenciosa, equilibrada o más FPS. Tenés dos formas: la **opción completa** con MSI Afterburner, paso a paso, o la **versión lite**, que la app pone sola en placas NVIDIA de escritorio.
- **MSI Afterburner** en Apps recomendadas.
- La pantalla de Inicio muestra las **novedades de la versión**.
- **Buscar drivers** recomienda más cosas: el driver de red directo de Realtek, tabletas de dibujo, impresoras, volantes, placas de sonido y micrófonos, capturadoras, webcams, joysticks, el programa de tu SSD y antenas WiFi o Bluetooth USB.
- En **Borrar las apps basura** y **Apagar apps de inicio**, si pasás el mouse por el contador te dice cuáles quedan.
- **Scroll suave** con la rueda del mouse: la página se desliza en vez de saltar, y se ve fluida en monitores de muchos Hz.
- La intro dice **Cargando** con una barrita, para que se note que la app está abriendo.

### Cambios
- La app **abre más rápido**: la intro se va apenas está todo listo.
- Leer tu Windows al entrar a Perfiles, Debloat o Gaming tarda **menos de la mitad** que antes (se lee solo la primera vez que entrás a una de esas).
- **Aplicar también es más rápido**: sin esperas fijas, sin `gpupdate` en Telemetría (tardaba hasta 15 segundos) y sin volver a compilar los programitas de Gaming si ya están al día. **Desactivar BitLocker** ya no tarda varios segundos si no tenés ningún disco cifrado.
- Gaming, Debloat y Limpieza ahora corren **dentro de la app**, sin ventanas de cmd. Solo las herramientas que te piden datos abren una ventana de PowerShell.
- Los logs tienen nombres nuevos: `debloat_`, `gaming_` y `limpieza_` con la fecha.
- Si cerrás la app mientras aplica algo, primero termina y después se cierra sola.
- Si la limpieza no llega al final, te avisa con un cartel de error.
- El contador de **Apagar apps de inicio** ya no cuenta como prendidas las que apagaste desde el Administrador de tareas ni restos de apps desinstaladas.
- Herramientas: **Borrar una cuenta** se bloquea si tenés una sola cuenta, y la contraseña tiene un solo botón (Quitar o Volver a usar).
- **Actualizar Windows** se bloquea si ya tenés la 26H2.
- El **punto de restauración** no se ofrece si los tenés apagados.
- El driver de audio de Realtek se recomienda solo si tenés algo enchufado en sus conectores.
- La traducción al inglés es más fácil de mantener: las opciones se traducen por su nombre interno, así que cambiar un texto en español ya no la rompe.

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
