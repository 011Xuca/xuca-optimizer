# Cambios

Todo lo que cambió en cada versión de **Brío**. La más nueva va arriba.

## v1.0.13

### Nuevo
- **Zona gamer, Teclado: Modo foco sin programa (compatible con antitrampas)** (nueva, no está en ningún perfil): apaga las dos teclas Windows desde el registro (`Scancode Map` de `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout`), sin ningún programa ni gancho de teclado, así Vanguard, FACEIT y otros antitrampas no ven nada. Respeta el mapa que ya tengas (por ejemplo Bloq Mayús → Ctrl): solo agrega las dos entradas que falten, anota en `ProgramData\Brio\scancode_orig.txt` cómo estaba y Restablecer quita solo lo que agregó Brío (si no queda nada, borra el valor). Las teclas Windows quedan apagadas siempre y para todos los usuarios, y pide reiniciar. Choca con **Modo foco** (la app pregunta cuál dejar), y el aviso de Modo foco ahora sugiere esta opción para juegos con antitrampas.
- **Apps del Sistema: Microsoft Edge WebView2 Runtime** (protegida, sin marcar): se quita con su propio desinstalador (`setup.exe --uninstall --msedgewebview --system-level --force-uninstall`, con límite de 3 minutos), se verifica que ya no esté y se pone la política de Edge Update que evita que se reinstale solo. El cartel de apps protegidas avisa fuerte: Teams nuevo, Office, los Widgets, el inicio de sesión con cuenta Microsoft de algunas apps y muchos programas de escritorio lo usan y pueden fallar o no abrir. Quitar solo Edge lo sigue conservando.
- **Servicios del Sistema junta los servicios sueltos**: el contenedor de NVIDIA, el inventario de compatibilidad y Salud de Windows, la red local y transmitir (8 servicios), Escritorio remoto (3), Temas y la IA de Windows (AI Fabric) dejan de ser opciones aparte y pasan a la lista como **Extremos** (nunca marcados de entrada). Se apagan y se restablecen igual que antes; **RAM mínima** sigue apagando la red local y Escritorio remoto, y "Escanear y reparar" vuelve a prender el inventario antes de actualizar. Cada servicio y cada app de **Apps del Sistema** dice en una línea qué es y qué ganás (+) y perdés (-) al apagarlo o quitarlo.
- **Copilot se respeta**: si al aplicar un perfil decís que usás Copilot y la IA, Apps del Sistema ya no borra Copilot ni los paquetes de IA; y si en la lista dejás Copilot sin marcar, no se borra.
- **Renombres**: **Borrar apps** ahora es **Apps del Sistema** y **Apagar servicios** ahora es **Servicios del Sistema** (tarjeta, ventana, cartel y resumen); las ids internas no cambian. Borrar apps antiguas / modernas quedan con su nombre.
- **Un solo ícono de alerta en las tarjetas**: el ⚠ del título ya no se repite al principio de "Puede dar problemas", "Sin vuelta atrás" o "Ojo", y va pegado a la última palabra, así que si el título baja de renglón el ícono baja con ella y no queda solo en otra línea.
- **Riot Vanguard se borra más a fondo**: deja los servicios `vgc` y `vgk` en Deshabilitado, los para y los borra comprobando cada paso, quita el driver `vgk` del almacén de Windows (`pnputil`), borra las tareas programadas de Vanguard, las claves de sus servicios, el inicio de la bandeja y sus carpetas, y el resumen dice qué se quitó y qué quedó. No toca el cliente de Riot ni los juegos. Pide reiniciar siempre y lo dice fuerte, en el cartel y en las advertencias de las opciones: **reiniciá la PC sin falta antes de volver a instalar Vanguard (o abrir VALORANT o LoL)**, si no pueden salir errores y bucles de instalación.
- **Resumen final solo con lo que se hizo**: la lista "Qué se aplicó" muestra únicamente las opciones que cambiaron algo (las que ya estaban así o no aplican quedan en el log), muestra aparte las que fallaron y, si no se cambió nada, dice una sola línea: "No hizo falta cambiar nada: ya estaba todo así."
- **Novedades en la pantalla de inicio: la última versión y un enlace al resto**: muestra solo la última versión, con los títulos en negrita y en el idioma de la app. Si es muy larga (más de 2000 caracteres) se corta en el último límite de viñeta que entra, nunca a mitad de una viñeta ni de una palabra, y dice "El resto de esta versión y el historial completo están en GitHub"; si entra entera, dice "Las versiones anteriores están en GitHub". Siempre hay un enlace al CHANGELOG del repositorio (el de tu idioma). Se lee del archivo que ya está en la carpeta, así que funciona sin internet.
- **OneDrive se limpia aunque el programa ya no esté**: antes, si `OneDrive.exe` ya no existía (por una corrida vieja o a medias), no se limpiaba nada más. Ahora, si elegís OneDrive en **Apps del Sistema**, además de desinstalarlo quita sus restos: el paquete `Microsoft.OneDriveSync`, las carpetas técnicas `%LOCALAPPDATA%\Microsoft\OneDrive` y `%ProgramData%\Microsoft OneDrive` (solo si no tienen accesos directos ni están dentro de tu carpeta de archivos), las tareas programadas de OneDrive y el acceso del menú Inicio, y la entrada del panel del Explorador también si solo existe en HKCU. También detecta el `OneDrive.App.exe` de las versiones nuevas. En la lista aparece como **Quedan restos** y se puede marcar para limpiarlos. **Nunca toca tu carpeta de archivos**, y si tu Escritorio, Documentos o Imágenes están dentro de OneDrive no desinstala ni limpia nada: el cartel final lo explica y dice cómo moverlas de vuelta (clic derecho en la carpeta > Propiedades > Ubicación > Restaurar valores predeterminados > Mover). El log y el resumen dicen qué se limpió y qué quedó. No agrega la política que impide reinstalarlo, para no bloquearte OneDrive si lo querés usar después.
- **Apagar el antivirus cuando la Protección contra alteraciones está encendida**: la detección ahora usa dos señales (`Get-MpComputerStatus` y el registro `TamperProtection`) y, si no se puede saber cómo está, cuenta como encendida y te pide que la apagues (abre Seguridad de Windows en la página correcta) en vez de seguir en silencio. Si igual el antivirus no se apaga, el resumen dice claramente que **SIGUE ENCENDIDO**, por qué y cómo apagar la Protección contra alteraciones; los contadores coinciden con las líneas FALLO del log (3 fallos ya no se informan como 1) y no se avisa de reiniciar antes de jugar Valorant ni se toca Vanguard si el antivirus no se apagó.
- **Contadores celestes más legibles**: "N/M apagados" y "N/M fuera de tu PC" ahora usan letra celeste muy clara sobre celeste saturado en el tema oscuro (contraste 7:1) y letra azul oscura sobre celeste claro en el tema claro.
- **Mover carpetas de OneDrive ya no confunde las carpetas de la nube con enlaces**: la revisión previa tomaba como "enlace" cualquier carpeta con el atributo de reparse point, y las carpetas de OneDrive con Files On-Demand lo tienen. Ahora lee la etiqueta real: solo los junctions y los enlaces simbólicos bloquean; las etiquetas de la nube (`0x9000X01A`) se recorren como carpetas normales. Siguen bloqueando los archivos que están solo en la nube (te dice cuáles y cuántos, y que uses "Mantener siempre en este dispositivo"). Si origen y destino están en el mismo disco, mueve por renombrado (cambio de metadatos: no copia, no descarga nada y no necesita espacio); en otro disco usa robocopy. El cartel final dice la causa real de cada bloqueo (en la nube, enlaces, archivos abiertos, espacio, rutas largas).
- **Los logs se escriben en UTF-8 con BOM**: antes se guardaban en ANSI y un lector UTF-8 fallaba con las tildes ("Imágenes"). Si ya existe un log viejo en ANSI se sigue en ANSI para no mezclar.
- **OneDrive devuelve tus carpetas antes de desinstalarse**: si tu Escritorio, Documentos o Imágenes (y Música, Vídeos o Descargas) están dentro de OneDrive, al elegir OneDrive en **Apps del Sistema** Brío te muestra qué carpetas, de dónde a dónde, cuántos archivos y GB, y pide confirmación (**sin vuelta automática**: Restablecer no lo deshace, y las rutas de repos git, proyectos, accesos directos y saves de juegos cambian; cerrá antes editores, terminales, Claude Code, git y juegos). Si confirmás, revisa todo antes de mover: nada solo en la nube, espacio libre, rutas largas, enlaces y archivos abiertos; si algo falla no se mueve nada. Mueve con `robocopy /E /MOVE` sin `/PURGE` ni `/MIR` (no borra nada del destino; si ya hay un archivo con el mismo nombre, el de OneDrive queda como "nombre (desde OneDrive)"), verifica por conteo y tamaño y recién entonces apunta la carpeta a `%USERPROFILE%\...` y reinicia el Explorador. Si algo no se movió, esa carpeta queda como estaba y OneDrive no se desinstala; ahí quedan los pasos manuales. Nunca toca `C:\Users\<usuario>\OneDrive` ni otros archivos.
- **Opción nueva "Escala según la resolución"** (Gaming, sección Mouse): elegís una resolución base (por ejemplo 1920x1080) y, cuando usás una resolución mayor, Brío sube la escala de Windows de ese monitor (125 %, 150 %...) para que iconos, textos, carpetas y cursor se vean del mismo tamaño que en la base. Solo sube: no pasa del máximo que Windows ofrece para el monitor, no baja de lo que ya tenías y con una resolución igual o menor no toca nada. Espera a que la resolución esté estable y no cambia nada con un juego en pantalla completa; si falla, vuelve a la escala anterior. Los programas que ya estaban abiertos pueden no cambiar de tamaño hasta que los reabras, y Windows puede pedir cerrar sesión (Brío no la cierra). Restablecer devuelve la escala y el cursor que tenías.
- **Submenús para elegir qué tocar**: al tocar Aplicar, **Limpiar arranque**, **Apps del Sistema**, **Servicios del Sistema** y **Borrar apps antiguas / modernas** abren una lista, una detrás de la otra. Cada cosa tiene su icono, un nombre claro, una descripción corta y una etiqueta (**Seguro de quitar**, **Driver o periférico: mejor dejarlo**, **Protegida por Windows**). Confirmás y la app sigue sola con el resto.
- **Apps del Sistema** suma OneDrive (lo cierra, corre `OneDriveSetup.exe /uninstall` de System32 y SysWOW64 y lo saca del Explorador y del inicio), Adobe Express, Asistencia rápida, Start Experiences, Paint, Notas rápidas, Reloj, Cámara, el Reproductor multimedia y las apps **protegidas** (Edge, Bing, Primeros pasos), que se quitan con el método de Windows para retirar apps y avisan antes porque no se revierten fácil.
- **Limpiar arranque** lee `Run` de HKCU y HKLM, `StartupApproved`, las carpetas de Inicio y las apps de la Store, y marca qué es seguro de quitar (OneDrive, Discord, el icono de Defender...) y qué es de drivers o periféricos (Realtek, AMD, Logitech G HUB...).
- **Detección del sistema**: Brío sabe si es notebook o PC de escritorio, la marca y el modelo del equipo y de la placa, y si el Windows ya viene recortado (Tiny10/Tiny11, AtlasOS, ReviOS, ediciones Lite). En notebooks no apaga wifi, sensores, biometría, Bluetooth ni el ahorro de energía; en Windows recortado no vuelve a borrar apps.
- **Textos en inglés completos**: los perfiles (nombre, qué hace, ideal para, ojo, qué no toca y consumo estimado), los avisos de Competitivo y Competitivo - Notebook, los carteles de sumar perfiles, de borrar partes de Windows y de cuenta local y los contadores salían en español en modo inglés. El perfil **RAM mínima** ya no lleva "(extremo)" en el nombre. Nuevo `tests\Verificar-Textos.ps1`: avisa si queda texto en español sin traducir.
- **Apps del Sistema: lo que queda "pendiente de reinicio" ya no es un fallo**: al quitar una app protegida (por ejemplo Control con la mirada, Controles parentales o Navegador de exámenes), Windows a veces la marca como "pendiente de quitar" para el sistema y la termina de sacar al reiniciar. Brío ahora lo cuenta como hecho, lo anota en el log como "se completa al reiniciar", la lista y el contador la muestran como borrada con la etiqueta "Se quita al reiniciar" (no se vuelve a ofrecer) y el resumen final avisa "Reiniciá para terminar de quitar: …". Solo es fallo si no quedó marcada de ninguna forma.
- **Apps del Sistema: lista en secciones con su total**: Pendientes, Protegidas por Windows, Ya borradas (incluye "Se quita al reiniciar") y Ya no están en tu PC. Las apps de la lista de Brío que ya no están instaladas (LinkedIn, Adobe Express, Solitario de Microsoft, Teams, Spotify, Netflix...) salen siempre, en gris con "Ya no está en tu PC", y **sí cuentan** para el N/M. Lo que Windows necesita para arrancar no se muestra ni se ofrece. Lo que sí se puede borrar con cuidado (Diálogo de impresión, Contactos, Cola de impresión, Expulsar placa externa, Anclar a Inicio, Selector de captura, Contenido de Windows, Herramientas de Edge, Ventanas de juegos de Xbox) sale entre las protegidas.
- **Submenú de Apps del Sistema más grande y en columnas**: abre en una ventana de 80 a 90 % del área de trabajo (se adapta a pantallas chicas como 1366x768) con la lista en columnas que se llenan de arriba hacia abajo, ítems del mismo tamaño con el texto cortado con "…" y el detalle completo en el tooltip, y los botones siempre visibles abajo. Servicios del Sistema y Limpiar arranque quedan como estaban.
- **Apps del Sistema: lista y contador coinciden siempre**: el contador de la tarjeta ("N/M fuera de tu PC", con el aviso "Incluye las que ya no estaban instaladas") y la lista del submenú salen ahora de la misma fuente (lo que realmente está instalado), así que ya no puede decir "2/2" con 3 apps en la lista. Las apps que Brío ya borró aparecen también en la lista, en gris, con la etiqueta "Ya borrada" y sin poder marcarse; si reinstalás una, vuelve a figurar como pendiente. **Cambio de criterio:** cuenta como hecha toda app conocida por Brío que ya no está en tu PC, la haya borrado Brío (aunque una versión vieja no lo anotara), vos o Windows, sin afirmar quién la quitó; el total es todo lo que Brío sabe quitar.
- **Apps del Sistema: protegidas por Windows también se pueden borrar**: Edge, Bing, Primeros pasos, Cross-device experience, Widgets, Copilot y otras opcionales (Narrador guía, Controles parentales, Control con la mirada, Modo quiosco, navegador de exámenes) aparecen con un icono de alerta y la etiqueta "Protegida por Windows: no se revierte fácil"; al marcarlas sale el cartel de 3 botones (Cancelar / Todo menos esto / Aplicar). Es una lista blanca: lo que Windows necesita para arrancar, el Inicio, la búsqueda, Configuración, la cuenta, los frameworks y runtimes no se ofrece y nunca se toca, y el borrado se niega también a nivel del script. Corregido: el seguro del script bloqueaba por error a Modo quiosco (`LockApp`) y a Bing (`Search`); ahora la lista blanca manda y el seguro solo frena nombres críticos que no estén en ella. Si una app se omite por ser necesaria, el resumen lo dice ("No se pudo quitar (la necesita Windows)") en vez de contarla como hecha.
- **Reducir bloat del navegador**: las opciones "Reducir el bloat de Edge" y "Reducir el bloat de Brave" ahora son una sola (id `eb`). Detecta qué navegadores hay instalados (App Paths y carpetas de instalación) y aplica solo lo de cada uno: Edge, Brave o los dos; si no hay ninguno, la tarjeta dice "No hace falta". Conserva todos los ajustes y el restablecer de cada navegador (restablecer quita los dos). Si ya tenías aplicada alguna de las dos, se reconoce igual porque usa las mismas políticas, y los perfiles usan la opción única.
- **Contador "N/M apagados"** en **Servicios del Sistema** (y "N/M quitadas del arranque" en **Limpiar arranque**): cuenta solo los servicios que existen en tu Windows y están **deshabilitados** (uno en Manual o Activo no cuenta como apagado, corra o no); se actualiza solo después de aplicar o restablecer y se lee en segundo plano, sin trabar la ventana.
- **Apagar servicios y Servicios extremos son ahora UNA sola opción, "Servicios del Sistema"**, con una ventana grande en columnas: **Seguros de apagar** (marcados de entrada), **Extremos** (con alerta, desmarcados, cada uno dice qué se pierde) y **Apagados** (según el estado real de cada servicio, así que se ve bien aunque ya hubieras aplicado cualquiera de las dos viejas). Cada servicio muestra su estado real (**Activo**, **Manual** o **Apagado**): solo cuenta como apagado el que está **deshabilitado**, y uno en Manual o Activo se apaga recién cuando lo marcás. Los **Apagados** se pueden marcar para **volver a prenderlos uno por uno** (vuelven a su inicio original anotado, o al de Windows, y Brío avisa en el log si no lo había anotado; antes de aplicar muestra el resumen de cuántos se prenden y cuántos se apagan) (se quitó la sección "Ya apagados en Manual": la versión anterior contaba un servicio en Manual y detenido como apagado y confundía). Sumó 13 servicios nuevos (Archivos sin conexión, Administración remota, Router AllJoyn, Recolector de diagnósticos, Escáneres y cámaras, Cámara compartida, Compartir carpetas, Hyper-V y Realidad Mixta, entre otros); no se repite nada que ya apaguen otras opciones (telemetría, ubicación, mapas, errores, impresión, Bluetooth, Xbox, búsqueda). **Restablecer** devuelve cada servicio al inicio que tenía antes de apagarlo (se guarda en `ProgramData\Brio`) y sigue levantando la biometría que apagaban versiones anteriores. **Windows Hello y el PIN quedan fuera de la lista** (Biometría, Passport, claves, Credential Manager, Bluetooth y Web Account Manager no se ofrecen aquí). Los servicios que tocan tarjetas inteligentes y llaves de seguridad, la cámara de Windows Hello con la cara o Vincular con el teléfono salen como Extremos con una etiqueta en rojo y, si los marcás, un cartel de 3 botones que explica qué deja de andar y cómo revertirlo. El contador de la tarjeta es apagados / todos los servicios que ofrece la lista en tu PC, contando solo los deshabilitados (por ejemplo "29/37 apagados"); queda verde ("Ya aplicada") cuando están deshabilitados todos los Seguros. **Cambio de criterio:** antes un servicio en Manual y detenido contaba como apagado, ahora no. Si una versión anterior de Brío dejó deshabilitada la biometría (Windows Hello con huella o cara), la ventana lo avisa y **Restablecer** la devuelve a Manual. El perfil **RAM mínima** aplica los Seguros y los Extremos que no tocan el inicio de sesión; los demás perfiles aplican solo los Seguros. Ningún servicio de la lista afecta a Recortes (Win+Shift+S).
- **Carteles de 3 botones** (Cancelar / Todo menos esto / Aplicar) en los avisos de Xbox, Game Pass y Minecraft, de lo que no tiene vuelta atrás y de las apps protegidas: **Cancelar** (o Esc) no aplica nada y vuelve a la pantalla, **Todo menos esto** aplica todo lo demás y desmarca solo esos ajustes, **Aplicar** los aplica con el resto. Con un perfil de 1 clic, Cancelar corta todo el perfil y deja la pantalla sin marcas.
- **Aviso por dispositivos conectados**: antes de aplicar, Brío lee qué tenés conectado (interfaces de audio USB y PCIe, drivers ASIO, MIDI, Bluetooth, impresoras, joysticks, biometría, cámaras y escáneres, lectores de tarjetas) y, si algo marcado puede dar problemas con eso, muestra "Se detectó: <nombre>" con el cartel de 3 botones. Cubre Prioridad para juegos, Temporizador del sistema, estados de reposo del procesador, ahorro de energía de PCIe y de USB, Bluetooth, impresión, sensores y biometría, tarjetas inteligentes y Borrar drivers sin uso. Si no detecta nada, no muestra el cartel; las tarjetas de Prioridad para juegos, Temporizador, Servicios del Sistema y Borrar drivers suman una línea de "Puede dar problemas".
- **Zona gamer, Teclado**: **Destrabar teclado** (un programa de fondo suelta Alt, Ctrl, Shift y Windows si quedan apretados 30 segundos sin que toques nada, y deja siempre activo el atajo **Ctrl + Alt + K**) y **Modo foco** (ignora la tecla Windows con un juego en pantalla completa; **Ctrl + Alt + F** la bloquea siempre y vuelve a lo automático). Los dos arrancan al iniciar sesión, se restablecen desde la app y cierran su gancho de teclado al apagarse. Modo foco avisa que algunos antitrampas desconfían de los programas que miran el teclado.
- **Zona gamer, Mouse: Velocidad del puntero fija** (nueva, no está en ningún perfil): un programa de fondo (`BrioPuntero`, mismo mecanismo que BrioTeclado y BrioFoco: tarea al iniciar sesión, se actualiza solo y se quita con Restablecer) cambia la velocidad del puntero de Windows cuando cambiás de resolución, sin cerrar sesión. Elegís una velocidad base de 1 a 20 (10 = la de Windows) para la resolución nativa del monitor principal (la más grande que ofrece, se guarda en `ProgramData\Brio`) y, al bajarla, la velocidad se ajusta al paso más cercano de la tabla de Windows (por ejemplo, 2560 a 1920 con base 10 da 8, y a 1280 da 6). Apaga la aceleración (la compensación asume curva lineal) y guarda tu velocidad y aceleración anteriores para devolverlas al restablecer. Los juegos con entrada directa (raw input) no se tocan. **Choca con Mouse competitivo**: al marcar una con la otra, Brío pregunta cuál dejar. Tiene un autotest del cálculo en `tests\Verificar-Opciones.ps1`.
- **Optimizaciones para juegos en ventana**: la descripción suma un consejo para la pantalla negra al hacer Alt+Tab desde un juego en pantalla completa (probar el modo ventana sin bordes).
- **Herramientas**: **Escanear y reparar Windows** (DISM + SFC, con tu permiso) y **Cuenta local sin Microsoft** (crea un administrador local sin contraseña ni correo; se bloquea si ya estás en una cuenta local y avisa de archivos, partidas y BitLocker antes).
- **Actualizar a Windows 11 26H2** ya no abre una ventana negra: desde Windows 10 (cualquier versión) o Windows 11 viejo usa el ISO oficial, y desde 24H2/25H2 Windows Update. Antes revisa y arregla lo que impide actualizar (Windows dañado, Windows Update apagado o en pausa, opciones que la frenan, poco espacio, reinicio pendiente).
- **Favoritas con ⭐**: Modo Nitro (aka QuickCPU), Temporizador del sistema (aka TimerResolution), Apagar el antivirus, Desactivar integridad de memoria y Desactivar VBS.
- Los programas de Gaming (BrioAfinidad, BrioRAM, BrioTimer) que quedaron de una versión vieja se **actualizan solos** al abrir la app.
- El cartel final después de aplicar es más completo: cuántos ajustes, qué se aplicó, espacio liberado (desde 1 MB; antes solo desde 50 MB), apps borradas, lo que ya no arranca con Windows y el DNS elegido.
- **Categorias que se pliegan** en Debloat y Zona gamer: tocando el titulo de una categoria (o con Tab y Espacio/Enter) se pliega o se despliega. Cada titulo tiene una flecha, dice cuantas opciones tiene y, en celeste, cuantas marcaste (se ve aunque este plegada: plegar solo esconde, lo marcado se aplica igual). La app se acuerda de lo que dejaste plegado (app_config.txt, clave `plegadas`; si no esta o un nombre ya no existe, todo arranca desplegado). La barra de busqueda despliega las categorias con resultados mientras buscas y, al borrar la busqueda, vuelven a como las dejaste. En Limpiar cache y Herramientas no se agrego: tienen pocas opciones, y en Limpiar cache plegar podia esconder algo marcado que borra archivos (Descargas, restos de apps).
- **Orden por impacto**: dentro de cada pagina, arriba va lo que mas rendimiento real da y abajo lo marginal. Criterio (sin porcentajes, depende de cada PC): 1) lo que cambia FPS, tirones o frametime en Zona gamer, y lo que deja RAM, CPU y disco libres todo el tiempo en Debloat; 2) latencia y respuesta (temporizador, red, mouse, DNS); 3) comodidad, interfaz y privacidad (titulos en gris). A igual nivel, primero lo seguro y despues lo que tiene riesgo; lo que no tiene vuelta atras siempre al final. La lista esta escrita y comentada en Brio.ps1 (`$OrdenSec` para las categorias y `$OrdenOpc` para las opciones). El orden en que se aplican no cambio.
  - Zona gamer: Graficos, Modo juego y Game Bar, CPU y prioridad, Procesador, Plan de energia, Limpieza de RAM, Seguridad (mas rendimiento); despues Temporizador, Energia y red, Mouse, DNS; al final Teclado, Sonido, Busqueda/almacenamiento/Explorador y Ajustes extra. "Preferir IPv4" paso a Energia y red.
  - Debloat: la categoria gigante "Sistema y privacidad" se separo en Apps y procesos en segundo plano, Efectos visuales y fluidez, Actualizaciones y Store, Servicios y funciones que casi nadie usa, Apps, navegadores e IA, Privacidad y telemetria e Interfaz y comodidad. Orden: segundo plano, efectos, almacenamiento y memoria, actualizaciones, servicios, seguridad, apps/navegadores/IA, privacidad, interfaz, puntos de restauracion y borrar partes de Windows.
- **Opciones separadas**: las que hacian varias cosas en una sola casilla ahora son opciones sueltas, cada una con su explicacion, su lectura de estado, Aplicar y Restablecer. El id original quedo para la parte principal. Si ya tenias aplicada la opcion grande, cada parte nueva lee su estado por su cuenta y sale como aplicada.
  - Rastreo y recopilacion de datos -> historial de actividad, ubicacion, Wifi Sense, sincronizacion de ajustes en la nube, aprendizaje de escritura, voz en la nube, descarga automatica de mapas y DRM en linea (con el Grupo Hogar, que ya no existe).
  - Anuncios, sugerencias y Bing -> anuncios y sugerencias / Bing y busqueda web del Inicio.
  - Sonidos de Windows -> sonidos / sonido de inicio. Efectos visuales -> efectos / transparencias. Widgets -> Widgets / boton Vista de tareas.
  - Impresion, red local y Escritorio remoto -> impresion / descubrimiento de red y transmitir / Escritorio remoto.
  - Dispositivos conectados y portapapeles -> experiencias compartidas / historial del portapapeles. Apagado y arranque rapidos -> apagado rapido / espera de los programas de inicio.
  - Funciones heredadas -> Asistencia remota / Reproduccion automatica / reporte de errores. Telemetria de programas -> Office / NVIDIA / PowerShell 7.
  - Bloat de Edge y Brave -> Edge / Brave. Funciones de IA -> IA de Windows / Bloc de notas y Paint / Copilot en Word y Excel.
  - Zona gamer: GPU por hardware y juegos en ventana -> GPU acelerada por hardware / optimizaciones para juegos en ventana (solo Windows 11). Extensiones y ocultos -> extensiones / archivos ocultos. Ahorro de energia de USB, PCIe y discos -> USB / PCI Express / discos.
  - No se separaron (y por que): las listas que son una sola cosa (apps basura, componentes viejos, tareas de telemetria, servidores en hosts), el mouse competitivo (velocidad y rastro quedan en el valor de Windows tanto al aplicar como al restablecer), la telemetria de Windows (bajar el servicio y dejar el nivel para recibir versiones nuevas van juntos), pantalla completa y DPI de cada juego (es el mismo valor del registro) y "Servicios y funciones que casi nadie usa" (sus funciones de Windows no se pueden leer rapido sin DISM).
- Los perfiles (Seguro, Optimizado, Competitivo, RAM liviana, RAM minima, notebook y Full) incluyen las partes nuevas de cada opcion que ya tenian: aplican exactamente lo mismo que antes. Las partes conservan los avisos de la opcion original (asi "Marcar solo seguras" no marca nada nuevo), el pedido de reiniciar (salvo juegos en ventana, que se toma al volver a abrir el juego) y los requisitos de version de Windows.
- **Circulito con la cantidad en cada seccion** del menu de la izquierda, igual al de Configs recomendadas (mismo estilo, en la esquina). Se cuenta solo, con lo que la app cargo: Perfiles = perfiles; Debloat y Zona gamer = opciones que podes usar en tu PC (no cuentan las que salen en gris por tu version de Windows, las de Windows 10/11 en Windows 7 y 8, ni las que no hacen falta por tu hardware; se recalcula al terminar de leer Windows y con "Volver a leer los ajustes"); Limpiar cache = opciones para marcar; Herramientas = herramientas; Apps recomendadas = apps. Inicio no lleva.
- `tests\Verificar-Opciones.ps1`: verificacion automatica que falla si hay ids repetidos, si falta una traduccion, un chequeo de estado o el lugar en el orden por impacto, o si una opcion separada no esta en los perfiles que tenian la original.

### Cambios
- **Camara compartida (cam)**: en Windows 11 reciente cada camara tiene su propio interruptor "Permitir que varias aplicaciones usen la camara al mismo tiempo" y Brio no lo puede cambiar solo. Ahora la opcion activa el modo general de Windows y abre la pagina de Camaras de Configuracion para que lo actives a mano (antes decia que lo activaba y en algunas PCs no pasaba nada). Los textos lo explican.
- **Aviso para los Ryzen X3D de dos bloques** (7900X3D, 7950X3D, 9900X3D, 9950X3D) en **Plan Alto rendimiento**, **Modo Nitro** y **Nucleos siempre despiertos**: el driver de AMD necesita el plan Equilibrado para estacionar el bloque sin V-Cache, asi que conviene dejarlas sin marcar. Es solo un aviso, no se saltean.
- **Los perfiles tambien ofrecen mover las carpetas de OneDrive**: si el perfil saca OneDrive (y no elegiste dejarlo) y tu Escritorio, Documentos o Imagenes estan dentro de OneDrive, sale el mismo cartel de siempre antes de desinstalarlo. Si no confirmas, OneDrive no se desinstala.
- **OneDrive limpia mas restos al desinstalarse**: ademas de `%LOCALAPPDATA%\Microsoft\OneDrive` y `%ProgramData%\Microsoft OneDrive`, ahora borra `%LOCALAPPDATA%\OneDrive`, `%APPDATA%\Microsoft\OneDrive` y `C:\OneDriveTemp` (si existen y no son accesos directos), y cierra OneDrive si seguia abierto. La carpeta `%USERPROFILE%\OneDrive` solo se borra si esta completamente vacia; si tiene algo adentro no se toca.
- Las pruebas (`tests\`) ya no se suben al repositorio: quedan solo en tu copia local.
- **Perfiles en un clic**: "Aplicar perfil" aplica directo, sin carteles de choques ni listas. Si al perfil le faltan drivers **no se aplica** hasta instalarlos (el botón te lleva a Herramientas). Los perfiles de rendimiento también sacan OneDrive y el icono de Defender del arranque.
- **Choques**: un solo cartel con la opción actual contra la nueva para elegir cuál queda; ya no se repite al aplicar (parecía un bucle). Si apagás del todo Windows Update, Xbox o la Microsoft Store, sus opciones hijas quedan en gris.
- Nombres cortos y claros (Limpiar arranque, Borrar apps, Apagar servicios...), emojis en cada categoría y un recuadro por categoría (con un tinte leve de su color) que se reduce al encabezado cuando la plegás.
- El changelog y los textos de carga salen en tu idioma.
- Se quitó **Medir FPS antes y después**. Los ajustes de la BIOS siguen en Herramientas.
- Se marcan las opciones que pueden **impedir actualizar a 26H2** (inventario de compatibilidad, tareas de diagnóstico, telemetría en hosts, Windows Update apagado o en pausa).
- Xuca OPtimizer se renombró a **Brío** (repo github.com/011Xuca/brio).
- Color propio: azul cielo (#60A5FA en oscuro, #1D4ED8 en claro) en botones, bordes, selección y en el icono (borde y dibujo). El fondo de la app pasa al gris oscuro del icono.
- Los datos de la app (preferencias, logs de lectura, programitas de Gaming y sus tareas) pasan a ProgramData\Brio. La primera vez que abre se mudan solos, sin perder nada, y los programitas que estaban andando se vuelven a prender.
- Apps recomendadas: la tarjeta del monitor de la PC ahora es **Pulso** (github.com/011Xuca/pulso).
- Si tenías Xuca OPtimizer, se actualiza solo a Brío desde el cartel de actualización: baja la app nueva y el acceso directo del escritorio pasa a llamarse Brío.

### Arreglado
- **Windows "no activado" o "no original" con cuenta local**: "Apagar instalaciones de la Store" apagaba LicenseManager, que usa la activación. Ya no se apaga, ninguna opción puede apagar `sppsvc`, `ClipSVC`, `LicenseManager`, `wlidsvc` ni `KeyIso` ni las tareas de licencia, el archivo hosts nunca bloquea los servidores de activación, y si alguno quedó apagado por una versión vieja se arregla solo.
- **Recortes y Win+Shift+S dejaban de andar** sin avisar: "Apagar servicios de usuario" apagaba el portapapeles (`cbdhsvc`). Ya no lo toca y lo vuelve a prender si estaba apagado.
- **Apagar Windows Update por completo no duraba**: el Médico de Windows Update y las tareas del Orquestador lo volvían a prender, y en Windows 11 `UsoSvc` no se dejaba cambiar. Ahora se apagan también, como SYSTEM cuando hace falta.
- Los 3 errores de "Borrar accesibilidad y voz" (`raiz de registro desconocida: HKCU:`): el registro acepta las dos formas de escribir la ruta.
- La pausa para apagar la **Protección contra alteraciones** antes de apagar Defender revisa que de verdad esté apagada y espera a que confirmes.
- "Reducir la telemetría" ya no apaga el evaluador de compatibilidad (sin él Windows Update no ofrece la 26H2).
- El resumen final del debloat ahora cuenta tambien los errores de PowerShell (PS-ERROR) y las cosas pendientes, no solo los FALLO. Antes decia "todo bien" aunque fallaran opciones.
- Al terminar muestra "Todo salio bien" o la lista de lo que fallo o quedo pendiente.
- Arreglado "No se ha encontrado el elemento" al quitar o leer componentes de Windows (apps antiguas, idiomas, accesibilidad): ahora se anota como atencion y sigue.
- Arreglado que pnputil y dism no se reconocian en PCs con System32 fuera del PATH (drivers sin uso, limpieza de componentes).
- Actualizador: si un archivo no se podia reemplazar (abierto por otro programa o el antivirus), la app quedaba mitad nueva y mitad vieja. Ahora guarda una copia de cada archivo antes de pisarlo y, si algo falla, vuelve todo a como estaba.
- Actualizador: si un archivo esta bloqueado un momento (por ejemplo, el antivirus revisandolo) reintenta, y si lo tiene otra ventana de la app (otra copia abierta o una herramienta en su consola) la cierra sola antes de reemplazarlo. Despues, como siempre, se cierra y se abre la version nueva.
- Actualizador: los archivos de solo lectura ya no hacen fallar la actualizacion.
- Actualizador: la app dejaba su icono bloqueado mientras estaba abierta y la actualizacion no lo podia reemplazar. Ahora lo lee a memoria.
- Restablecer el antivirus ahora tambien quita las politicas de SmartScreen de Edge (antes Edge seguia sin SmartScreen y decia "administrado por tu organizacion").
- Actualizador: en un wifi con pagina de inicio de sesion (hotel, bar) ya no aparece una "version nueva" falsa.
- Actualizador: si la red se cuelga al buscar versiones nuevas, la app abre igual a los 8 segundos.
- Si en el cartel de permisos de Windows tocas "No", la app se cierra sin mostrar un error.
- Las herramientas de Windows (sc, reg, powercfg, icacls, DISM...) se encuentran aunque a la PC le falte System32 en el PATH.
- Texto de Hiber en Apps recomendadas: "pestañas" salia con letras raras.
- En ingles, las descripciones de Apps recomendadas, la descripcion de Perfiles, el texto fijo de Limpieza y varios titulos de seccion (Perfiles, Debloat y Limpieza) salian en espanol o mezclados.
- Tema claro: "Ya aplicado", el boton de redes y el enlace a las Releases se leian poco (verde y azul claros sobre fondo blanco).

### Windows 7 y 8.1
- Brio.bat revisa que este PowerShell 5.1 y, si falta (Windows 7 trae el 2.0), dice que instalar en vez de cerrarse sin explicar nada. install.ps1 hace lo mismo.
- Las opciones que usan comandos que Windows 7 y 8 no tienen (apps de la Store, Defender, BitLocker, tareas programadas nuevas, DNS por placa, dispositivos, cuentas locales) aparecen en gris como no compatibles y los scripts las saltean con un aviso.
- En Windows 7 el Debloat, la Zona gamer y la Limpieza ya no se cortan a la mitad por buscar apps de la Store; la limpieza de componentes (DISM) se saltea porque ese Windows no la tiene.
- README: como instalar en Windows 7 SP1 y 8.1 (WMF 5.1 y TLS 1.2).

## v1.0.12

### Nuevo
- **Cartel de opciones que chocan**: si marcás dos opciones que se pisan (compresión de memoria con SysMain, antivirus apagado con antivirus más liviano, plan Alto rendimiento o Modo Nitro con batería, Windows Update apagado con pausar actualizaciones o con sus drivers, Store quitada con sus servicios y actualizaciones, Xbox completo con sus servicios y Modo Xbox, grabación de juegos con borrar la Game Bar), la app explica el choque y pregunta cuál dejar. Cerrar el cartel deja la que ya tenías. En los pares que se contradicen también avisa si la otra opción ya está aplicada. Pasa al tocar la casilla, con "Todo" y al marcar o aplicar un perfil. Traducido al inglés.
- **Ajustes extremos sueltos** (en Debloat, Sistema y privacidad y Almacenamiento y memoria) ⚠: no están en ningún perfil y cada uno avisa qué se rompe y se restablece desde la app. **Apagar el servicio de Temas**, **Entrada de texto moderna** (puede que no puedas escribir en el Inicio ni en Configuración: probá Win+L antes de reiniciar), **Administrador de cuentas web** (sin iniciar sesión con Microsoft en las apps), **Servicio de IA de Windows**, **Dispositivos conectados** (sin Vincular con el teléfono ni Compartir cerca), **Contenedor de pantalla de NVIDIA** (el Panel de control de NVIDIA no abre) e **Inventario de compatibilidad y Salud de Windows**. Si tu Windows no tiene el servicio, la opción aparece como "no hace falta". Traducidos al inglés.
- **Los perfiles ya no se bloquean**: aplican lo que tu PC puede y saltean lo no compatible, lo ya aplicado y lo que necesita drivers. Si faltan drivers, antes de marcar o aplicar el perfil la app avisa y te lleva a Herramientas a instalarlos, o seguís sin esos ajustes (cerrar el cartel cancela). La lista de cada perfil cuenta cuántos ajustes necesitan drivers.
- **Los perfiles se adaptan a tu PC**: la limpieza automática de RAM se saltea con menos de 12 GB; la hibernación no se marca en notebooks (se pierde lo abierto si se agota la batería) ni con Windows en un HDD (el arranque tarda mucho más), y Windows Search tampoco con un HDD. Siguen disponibles a mano.
- **El perfil RAM mínima (extremo)** pide confirmación y lista todo lo que va a apagar o quitar (antivirus, BitLocker, Windows Update, la Store y más) y avisa que BitLocker deja la PC más lenta hasta terminar de descifrar.

### Cambios
- **Compresión de memoria** ahora prende SysMain antes de activarse (la compresión lo necesita) y deja de figurar como aplicada si SysMain está apagado. **Desactivar la hibernación** ya no toca la compresión de memoria. **Desactivar SysMain y Prefetch** avisa que deja sin efecto la compresión.
- **Efectos visuales**: se sacó "Efectos visuales en rendimiento" de Gaming: solo cambiaba un valor que la otra opción ya cambia, y se pisaban. Queda "Reducir los efectos visuales" (Debloat), que ahora usa también el perfil Competitivo.
- **Perfiles competitivos** (Competitivo y Competitivo - Notebook) ya no incluyen lo que puede afectar el stream en OBS o TikTok LIVE Studio: prioridad alta de juegos, limpieza de RAM, GPU acelerada por hardware ni optimizaciones de pantalla completa (se pueden marcar a mano). Para stream conviene NVENC o AMF. Se borró el perfil **Competitivo + Optimizado**: marcá Optimizado y Competitivo juntos con "Sumar".
- **RAM mínima (extremo)**: ya no incluye Windows Update sin drivers ni los servicios de instalación de la Store. La estimación de RAM pasó a "alrededor de 3 GB" (medido en una PC real) en vez de 1,3 a 1,8 GB.
- **Más rápido**: la lectura de ajustes pide solo el nombre del procesador (antes ~1 s por consulta) y lee las tareas programadas por COM (de ~860 ms a ~56 ms). Cada script también arranca más rápido.

### Arreglado
- "SysMain y Prefetch" y "Temporizador" aparecían como omitidos aunque no los hubieras marcado, y restablecer SysMain nunca corría en PCs con menos de 16 GB o con HDD.
- El aviso del perfil Full decía que apaga la integridad de memoria y VBS; solo apaga el antivirus y BitLocker.
- Restablecer la hibernación decidía "ya estaba" mirando otra cosa que el chequeo de estado.
- Restablecer "Inventario y Salud de Windows" devuelve el inicio retrasado original.
- Restablecer "Más servicios apagados" ahora arranca el servicio de Windows Hello (huella o cara), así vuelve a andar sin reiniciar.

## v1.0.11

### Nuevo
- **Sacar el icono de NVIDIA de la bandeja** (en Debloat, Almacenamiento y memoria): evita que el icono de NVIDIA (el del click derecho con "Abrir NVIDIA App" y "Panel de control") se abra solo al iniciar sesión. El driver, el Panel de control y la NVIDIA App siguen andando desde Inicio. Se nota al reiniciar. Traducido al inglés.
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

### Cambios
- **Menos falsas alarmas del antivirus**: `scripts\Edge.txt` ya no trae programas (`setup.exe` y `SQLite.dll`) escondidos en base64. "Quitar Edge" ahora los descarga de ShadowWhisperer/Remove-MS-Edge en el momento y verifica su huella SHA-256 antes de usarlos; si no coincide, los baja el propio `Edge.bat`.
- **Abrir la app**: `Brio.bat` y `install.ps1` ya no quitan la marca de "descargado de internet" (`Unblock-File`), que es una técnica que los antivirus miran con desconfianza. Con `-ExecutionPolicy Bypass` no hacía falta. La ventana de PowerShell ahora queda minimizada en la barra de tareas en vez de oculta.

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
- **Pulso** en Apps recomendadas.
- Ícono propio (`Brio.ico`) en la app, el acceso directo y el README.

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
