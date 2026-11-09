# Cambios

Todo lo que cambió en cada versión de **Xuca OPtimizer**. La más nueva va arriba.

## v1.0.11

### Nuevo
- **Sacar el icono de NVIDIA de la bandeja** (en Debloat, Almacenamiento y memoria): evita que el icono de NVIDIA (el del click derecho con "Abrir NVIDIA App" y "Panel de control") se abra solo al iniciar sesión. El driver, el Panel de control y la NVIDIA App siguen andando desde Inicio. Se nota al reiniciar. Traducido al inglés.
- **Sacar la caja de búsqueda de la barra de tareas** (en Debloat, Almacenamiento y memoria): oculta la caja y apaga los destacados de búsqueda, para que Windows no deje abierto el grupo "Search" con sus procesos WebView2. Seguís buscando con la tecla Windows. Traducido al inglés.
- **Quitar anuncios, sugerencias y Bing** ahora también apaga lo de Privacidad y seguridad > Recomendaciones y ofertas: los resultados sugeridos de la búsqueda (Búsquedas web y Microsoft Store), las ofertas personalizadas, que los sitios lean tu lista de idiomas y "Mejorar Inicio y resultados de búsqueda". **Apagar el rastreo y la recopilación de datos** suma "Mejorar escritura a mano y teclado" (diagnóstico).
- **Aviso de Xbox antes de aplicar**: las opciones que tocan Xbox, la Game Bar, Game Pass o Minecraft (servicios de Xbox, Teredo, actualizaciones de la Store, borrar la Game Bar y Modo Xbox) muestran el aviso en su tarjeta, "Marcar solo seguras" ya no las marca y, antes de aplicarlas (a mano o con un perfil), la app pregunta. Con **Sin Xbox** (o Esc) se aplica todo lo demás sin ellas. Traducido al inglés.
- **Apagar los servicios de Xbox** (en Debloat) ⚠: los servicios de Xbox Live salieron de "Más servicios apagados para liberar RAM" y ahora son una opción aparte, que no está en ningún perfil. Esta opción no toca Gaming Services.
- **Si aplicaste "Más servicios apagados para liberar RAM" con la v1.0.11** y Game Pass o Minecraft no andan: restablecé "Apagar los servicios de Xbox" (aparece como aplicada), o restablecé "Más servicios apagados": ahora también devuelve a Manual los servicios de Xbox que hayan quedado deshabilitados (si ya están bien, no los toca).
- **Servicios de diagnóstico en manual** (en Debloat): pone en manual el servicio DPS. Ahorra algunas decenas de MB; Windows deja de buscar problemas solo y el uso de batería y de datos por app deja de actualizarse.
- **Compresión de memoria** (en Debloat, Almacenamiento y memoria): la vuelve a prender si algún optimizador la apagó. Ayuda con 4 a 8 GB de RAM; necesita SysMain.
- **Inicio rápido de Office** (en Debloat, Almacenamiento y memoria): apaga las tareas "Office Startup Boost", que precargan Word, Excel y PowerPoint en la RAM al iniciar sesión.
- **Quitar Xbox completo** (en Optimización gaming, Modo Juego y Game Bar) ⚠: lo máximo para sacar Xbox. Apaga los servicios de Xbox y de Gaming Services, borra y desprovisiona la app de Xbox, Gaming Services, Xbox Identity Provider, Xbox TCUI, la transcripción del chat y la Game Bar, y apaga GameDVR, el atajo del joystick, el Modo Xbox y la tarea de guardado en la nube. Game Pass, Minecraft Bedrock y su Launcher y los juegos de la Store dejan de funcionar. No está en ningún perfil, "Marcar solo seguras" no la marca y la app pregunta antes. En los Ryzen X3D de dos bloques deja la Game Bar. Restablecer reinstala la app de Xbox, Gaming Services, Xbox Identity Provider y la Game Bar con winget; lo que no se puede reinstalar solo queda anotado en el log.
- Los perfiles **RAM liviana** y **RAM mínima** suman estas tres opciones y ya no apagan los servicios de Xbox.
- **Perfiles RAM liviana y RAM mínima** (en Perfiles): bajan el uso de RAM de Windows. *RAM liviana* no toca la seguridad: saca publicidad, telemetría, Widgets e IA, borra las apps basura, apaga las apps de inicio y en segundo plano, los efectos visuales y SysMain, y suma las dos opciones nuevas de abajo. *RAM mínima* suma además apagar hibernación, Windows Search, antivirus, BitLocker, integridad de memoria y VBS. Rondan 2,5–3 GB y 2–2,5 GB en reposo (estimado, no medido); para 1–2 GB hace falta una ISO recortada (tiny11 o NTLite). Traducido al inglés.

- **Servicios de Windows en menos procesos** (en Debloat): junta los servicios en pocos `svchost` (`SvcHostSplitThresholdInKB`) y ahorra varios cientos de MB de RAM. Se aplica al reiniciar. Traducido al inglés.

- **Más servicios apagados para liberar RAM** (en Debloat): apaga los servicios de Xbox, Teléfono, Billetera, NFC, zona wifi móvil, control parental, tarjetas inteligentes e Insider. Xbox Game Pass y la zona wifi móvil dejan de andar. Traducido al inglés.

- **Cámara en varias apps** (en Debloat): activa "Permitir que varias aplicaciones usen la cámara al mismo tiempo" de Windows, para usarla en OBS, Discord, Teams, etc. a la vez. Traducido al inglés.

- **Nuevas opciones de RAM y servicios** (en Debloat) ⚠: impresión, red y Escritorio remoto; servicios y tareas extra de NVIDIA (sigue andando el Panel de control); actualizadores de Edge, Chrome y Brave en manual; tareas de mantenimiento y diagnóstico; sincronización entre dispositivos y portapapeles; disco sin anotar el último acceso; apagado y arranque rápidos; más servicios que casi nadie usa; Bluetooth (no deja aplicar si hay un dispositivo conectado); servicios de la Store; Windows Update; miniaturas; funciones heredadas; servicios de usuario; y quitar la Microsoft Store.
- **Borrar partes de Windows (sin vuelta atrás)**: apps modernas, copias de seguridad de las actualizaciones (ResetBase), drivers sin usar, entorno de recuperación, paquetes de idioma y ayudas de accesibilidad y voz. Todas piden confirmación, y una vez aplicadas quedan en gris y bloqueadas; si el estado vuelve atrás (por ejemplo reinstalás un idioma) se habilitan de nuevo.
- **Apps antiguas o modernas** (excluyentes, no se pueden marcar juntas): cada una instala lo que le falte de su lado y recorta el espacio que ya no se usa. Quitar componentes viejos (Internet Explorer, WordPad, SMBv1, PowerShell 2, Telnet, XPS y más).
- **Optimización gaming**: grabación de juegos en segundo plano (Game DVR) y prioridad al programa en primer plano.
- **Limpiar caché por categorías y en 2 columnas**, con opciones nuevas que explican qué borran: Windows.old, caché de Discord/Steam/Epic/Store, caché de navegadores, Visor de Eventos, componentes viejos (DISM), restos de apps desinstaladas (conserva carpetas con partidas guardadas) y la carpeta Descargas.
- **Perfiles** ordenados en grupos y de a 2 por fila, con estimación de RAM; sin opciones de seguridad en los competitivos y sin las que solo sumaban calor. **Apps extras, Opciones y Configs recomendadas** también en 2 columnas, con categorías de colores ordenadas por importancia.
- **Perfiles apilables**: si ya tenés opciones marcadas de otro perfil (o a mano) y elegís otro, la app pregunta si querés **Sumar** la lista del nuevo perfil a lo marcado o **Cambiar** lo marcado por ese perfil. Lo que ya está aplicado en Windows siempre se mantiene.
- Todas las opciones muestran **Ya aplicado / Sin aplicar**, incluso cuando el programa a tocar no existe en tu PC (por ejemplo, sin Brave).
- **Modo Nitro** dice "(aka. QuickCPU)" y el temporizador "(aka. Timer Resolution)".

### Perfiles sin Xbox
- **Seguro, Optimizado, Competitivo + Optimizado, RAM liviana, RAM mínima y Debloat - Notebook** ya no frenan las actualizaciones de la Store (rompían las de Game Pass, Minecraft y Gaming Services).
- **RAM mínima** ya no apaga Teredo (no ahorra RAM y rompe el chat de Xbox).
- **Competitivo, Competitivo + Optimizado y Competitivo - Notebook** ya no apagan el Modo Xbox (no cambia los FPS). Siguen borrando la Game Bar, pero la app pregunta antes y con **Sin Xbox** la dejás.
- Solo **Full Optimizado** y **Full Optimizado + Competitivo** (que son "todo") siguen incluyendo opciones que tocan Xbox, y la app también pregunta antes. Ningún perfil apaga los servicios de Xbox ni quita Xbox completo.

### Cambios
- **Apps en segundo plano**: la app de Xbox, la Game Bar, Gaming Services y Minecraft quedan como excepción y siguen pudiendo correr de fondo. Si ya la tenías aplicada, aparece como sin aplicar para que la apliques de nuevo.
- **Apps de inicio**: ya no apaga la app de Xbox, la Game Bar, Gaming Services ni Minecraft.
- **Borrar apps basura**: ya no borra `Microsoft.XboxSpeechToTextOverlay` (la transcripción del chat de Xbox).
- **Borrar la app Xbox Game Bar**: ahora también borra el paquete viejo (`Microsoft.XboxGameOverlay`) y desprovisiona los dos, para que no vuelvan en cuentas nuevas ni con actualizaciones de Windows. En los Ryzen X3D de dos bloques sigue sin borrarla.
- **Modo Juego** ya no toca la Game Bar: lo de que el botón Xbox del joystick no abra la Game Bar pasó a "Borrar la app Xbox Game Bar".
- **Apps en segundo plano**: la excepción de Xbox suma Accesorios de Xbox (`Microsoft.XboxDevices`) y la transcripción del chat. **Apps de inicio** tampoco apaga el Launcher de Minecraft de la Store (`Microsoft.4297127D64EC6`).
- **Borrar una cuenta** y **Entrar sin contraseña** avisan que se cierra la sesión de Xbox y de la Store (en el primero, solo si hay que limpiar todo el caché de cuentas). **Desactivar las notificaciones** avisa que no se ven las invitaciones de Xbox.
- **Actualizaciones de la Store**: el "En contra" avisa que también frena las de Game Pass, Minecraft y Gaming Services.
- **Auditoría de seguridad de datos**: "Borrar apps basura" ya no borra Paint, Cámara, Reloj, Notas adhesivas ni Asistencia rápida; "Desinstalar OneDrive" se saltea si tu Escritorio, Documentos o Imágenes están en OneDrive o hay archivos solo en la nube; "Borrar apps modernas" conserva códecs de video e imagen, la captura de pantalla y los paneles de audio y video del fabricante; el Bloc de notas y Paint clásicos solo se quitan si ya está el moderno.
- **Modo MSI** no se fuerza en dispositivos cuyo driver lo apagó a propósito, y salió de los perfiles competitivos y de Full. **Velocidad del cable** no fuerza 1 Gbps si el cable hoy negocia menos. **Limpieza** ya no borra `$WINDOWS.~BT` y `$WINDOWS.~WS` salvo que marques borrar Windows.old y no haya una instalación en curso.
- **Apagado rápido** ya no cierra programas a la fuerza. **Restaurar la Store** espera hasta 2 minutos. **Servicios protegidos**: si Windows rechaza el cambio, se prueba por el registro. Se quitó "Apagar el Centro de seguridad" porque Windows lo protege y nunca se podía aplicar.
- **Textos de las opciones reescritos en lenguaje simple**, con su traducción al inglés.

## v1.0.10

### Nuevo
- **Estado de la PC** (en Herramientas): un botón que muestra la RAM libre, el espacio libre del disco, cuántos programas arrancan con Windows, el plan de energía y hace cuánto está encendida la PC. Sirve para comparar antes y después de aplicar. Traducido al inglés (el resumen que muestra sale en español).

### Cambios
- **Menos falsas alarmas del antivirus**: `scripts\Edge.txt` ya no trae programas (`setup.exe` y `SQLite.dll`) escondidos en base64. "Quitar Edge" ahora los descarga de ShadowWhisperer/Remove-MS-Edge en el momento y verifica su huella SHA-256 antes de usarlos; si no coincide, los baja el propio `Edge.bat`.
- **Abrir la app**: `XucaOP.bat` y `install.ps1` ya no quitan la marca de "descargado de internet" (`Unblock-File`), que es una técnica que los antivirus miran con desconfianza. Con `-ExecutionPolicy Bypass` no hacía falta. La ventana de PowerShell ahora queda minimizada en la barra de tareas en vez de oculta.

## v1.0.9

### Nuevo
- **Pantalla completa y DPI en tus juegos** (en Optimización gaming, Gráficos): a cada juego detectado le marca "Deshabilitar optimizaciones de pantalla completa" e "Invalidar el escalado de DPI alto: Aplicación". Conserva las otras marcas de compatibilidad que ya tuviera y R deja cada juego como estaba.

### Cambios
- **Desactivar las notificaciones de Windows**: el "Contra" ahora aclara que no frena las ventanas que una app abre sola (una actualización o un cuadro de Discord, Brave o Spotify), porque eso no es un aviso. Traducido al inglés.

### Corregido
- **Modo Nitro salía "Sin aplicar"**: ahora, si no hay copia de tus valores (porque ya estaban así), también se lee el plan de energía para marcarlo como aplicado.

## v1.0.8

### Nuevo
- **Efectos visuales en modo rendimiento** (en Optimización gaming, Gráficos): pone las animaciones, sombras y transparencias de Windows en modo rendimiento. Ayuda sobre todo en PCs con poca potencia; en una PC potente casi no cambia los FPS. R lo vuelve a los efectos de Windows.
- **Interfaz más cercana a Windows 11**: fondos en grises neutros, azul de Windows como color de acento, esquinas más chicas, y sin los degradados azul-rosa ni las sombras del logo y del título de cada página. Funciona igual en tema claro y oscuro.
- **Extensiones y elementos ocultos**: la opción de mostrar las extensiones de los archivos ahora también muestra las carpetas y archivos ocultos, y avisa al Explorador para que las ventanas abiertas se actualicen sin reiniciarlo. R lo deja como Windows.

### Corregido
- **Opción en español con la app en inglés**: "Poner los efectos visuales de Windows en rendimiento" ahora tiene su traducción al inglés.
- **Baja latencia: el CPU seguía subiendo al 100%**: al restaurar, la función se borraba y Windows decidía solo, y en las builds nuevas puede venir prendida de fábrica. Ahora restaurar la apaga explícitamente (equivale a `vivetool /disable /id:58989092`). Si la tenías "apagada" y notabas picos de CPU, volvé a aplicarla y reiniciá.
- **Aviso "Get an app to open 'ms-gamingoverlay'"**: al borrar la Xbox Game Bar, los protocolos se redirigían antes de desinstalar la app, y Windows los volvía a sacar. Ahora se redirigen después.
- **Recomendados de la Microsoft Store al buscar**: "Quitar anuncios, sugerencias y Bing" ahora también apaga las sugerencias de la caja de búsqueda por política, el contenido destacado y el historial de búsqueda del dispositivo. Si ya la habías aplicado, aparece como sin aplicar para que la apliques de nuevo.
- **Borrar apps basura ya no toca Películas y TV ni el Reproductor de música**: `Microsoft.ZuneVideo` y `Microsoft.ZuneMusic` salieron de la lista. WhatsApp nunca estuvo en la lista de apps a borrar.
- **Afinidad de CPU: navegadores y Discord/Spotify laggeados**: los navegadores (Chrome, Edge, Firefox, Opera, Brave) y los lanzadores web de Steam y Epic ya no se mandan a los núcleos de fondo por defecto. Abren muchos procesos y, apretados en uno o dos núcleos, quedaban muy lentos y se colgaban. Para que tome efecto, volvé a aplicar la afinidad; si tenías una lista de fondo guardada, revisá que no incluya el navegador.
- **Error al cerrar la app con la ventana minimizada**: ya no aparece el error de WPF al cerrar y la app se cierra normalmente.
- **Modo Nitro: restauración**: al restaurar, cada ajuste que no tiene copia de tu valor anterior vuelve al valor de fábrica de Windows, en vez de quedarse como Nitro. Si no hay copia, la restauración igual se hace con esos valores.

### Problemas conocidos
- **Modo Nitro, "modo del turbo (agresivo)"**: Windows no tiene un valor de fábrica para ese ajuste en el plan de energía activo, así que al restaurar queda como está (la app lo avisa en el log de Optimización gaming). Si lo querés volver atrás a mano, hacelo desde las opciones avanzadas de energía.

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
