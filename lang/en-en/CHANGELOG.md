# Changes

English changelog of **Brío** (the app shows the section of your version when the language is English).

## v1.0.13

### New
- **Submenus to choose what to touch**: when you tap Apply, **Clean up startup**, **Remove apps**, **Turn off services** (and the extreme ones) and **Remove legacy / modern apps** open a list, one after another. Each item has its icon, a clear name, a short description and a tag (**Safe to remove**, **Driver or peripheral: better keep it**, **Protected by Windows**). You confirm and the app carries on with the rest by itself.
- **Remove apps** adds OneDrive (closes it, runs `OneDriveSetup.exe /uninstall` from System32 and SysWOW64 and removes it from File Explorer and startup), Adobe Express, Quick Assist, Start Experiences, Paint, Sticky Notes, Clock, Camera, Media Player and **protected** apps (Edge, Bing, Get Started), which are removed with the Windows app-retirement method and warn you first because they are not easy to revert.
- **Clean up startup** reads `Run` in HKCU and HKLM, `StartupApproved`, the Startup folders and Store apps, and tags what is safe to remove (OneDrive, Discord, the Defender icon...) and what belongs to drivers or peripherals (Realtek, AMD, Logitech G HUB...).
- **System detection**: Brío knows whether it is a laptop or a desktop, the brand and model of the computer and motherboard, and whether Windows already comes trimmed (Tiny10/Tiny11, AtlasOS, ReviOS, Lite editions). On laptops it does not turn off Wi-Fi, sensors, biometrics, Bluetooth or power saving; on trimmed Windows it does not remove apps again.
- **Complete English texts**: profiles (name, what it does, ideal for, careful, what it does not touch and estimated use), the Competitive and Competitive - Laptop warnings, the add-profiles, delete-parts-of-Windows and local-account prompts and the counters showed in Spanish in English mode. The **Minimum RAM** profile no longer has "(extremo)" in its name. New `tests\Verificar-Textos.ps1` warns if Spanish text is left untranslated.
- **"N/M off" counter** on **Turn off services** and **Turn off extreme services** (and "N/M removed from startup" on **Clean up startup**): it counts only the services that exist on your Windows and are disabled, or manual and stopped; it refreshes by itself after applying or restoring and is read in the background, so the window never freezes.
- **3-button dialogs** (Cancel / Everything except this / Apply) on the Xbox, Game Pass and Minecraft warning, the no-way-back warning and the protected apps warning: **Cancel** (or Esc) applies nothing and goes back to the screen, **Everything except this** applies everything else and unchecks only those settings, **Apply** applies them with the rest. With a one-click profile, Cancel stops the whole profile and leaves the screen with nothing checked.
- **Connected devices warning**: before applying, Brío reads what you have plugged in (USB and PCIe audio interfaces, ASIO drivers, MIDI, Bluetooth, printers, joysticks, biometrics, cameras and scanners, card readers) and, if something you selected may cause problems with it, shows "Detected: <name>" with the 3-button dialog. It covers Priority for games, System timer, processor idle states, PCIe and USB power saving, Bluetooth, printing, sensors and biometrics, smart cards and Delete unused drivers. If nothing is detected, no dialog is shown; the Priority for games, Timer, Turn off services and Delete drivers cards add a "May cause problems" line.
- **Gamer zone, Keyboard**: **Unstick keyboard** (a background program releases Alt, Ctrl, Shift and Windows if they stay pressed for 30 seconds with no input, and keeps the **Ctrl + Alt + K** shortcut always on) and **Focus mode** (ignores the Windows key while a game is in full screen; **Ctrl + Alt + F** blocks it always and goes back to automatic). Both start when you sign in, reset from the app and drop their keyboard hook when turned off. Focus mode warns that some anti-cheats distrust programs that watch the keyboard.
- **Tools**: **Scan and repair Windows** (DISM + SFC, with your permission), and **Local account without Microsoft** (creates a local administrator with no password or email; it is locked if you are already on a local account and warns about files, saves and BitLocker first).
- **Update to Windows 11 26H2** no longer opens a black window: from Windows 10 (any version) or an old Windows 11 it uses the official ISO, and from 24H2/25H2 Windows Update. First it checks and fixes what blocks the update (damaged Windows, Windows Update off or paused, options that block it, low space, pending restart).
- **Favorites with ⭐**: Nitro Mode (aka QuickCPU), System timer (aka TimerResolution), Turn off the antivirus, Disable memory integrity and Disable VBS.
- Gaming helper programs (BrioAfinidad, BrioRAM, BrioTimer) left by an old version **update themselves** when the app opens.
- The final summary after applying is more complete: how many settings, what was applied, space freed (from 1 MB; before, only from 50 MB), apps removed, what no longer starts with Windows and the chosen DNS.
- **Collapsible categories** in Debloat and Gamer zone: tap a category title (or use Tab and Space/Enter) to fold or unfold it. Each title has an arrow, says how many options it has and, in light blue, how many you ticked (visible even when folded: folding only hides, what is ticked is still applied). The app remembers what you left folded (app_config.txt, key `plegadas`; if it is missing or a name no longer exists, everything starts unfolded). The search bar unfolds the categories with results while you search and, when you clear it, they go back to how you left them. Not added to Clean cache and Tools: they have few options, and in Clean cache folding could hide something ticked that deletes files (Downloads, app leftovers).
- **Order by impact**: inside each page, what gives the most real performance goes on top and the marginal stuff at the bottom. Criteria (no percentages, it depends on each PC): 1) what changes FPS, stutter or frametime in Gamer zone, and what frees RAM, CPU and disk all the time in Debloat; 2) latency and responsiveness (timer, network, mouse, DNS); 3) comfort, interface and privacy (grey titles). At the same level, the safe stuff first and then what carries risk; what cannot be undone always goes last. The list is written and commented in Brio.ps1 (`$OrdenSec` for categories and `$OrdenOpc` for options). The order in which things are applied did not change.
  - Gamer zone: Graphics, Game Mode and Game Bar, CPU and priority, Processor, Power plan, RAM cleanup, Security (most performance); then Timer, Power and network, Mouse, DNS; at the end Keyboard, Sound, Search/storage/Explorer and Extra settings. "Prefer IPv4" moved to Power and network.
  - Debloat: the giant "System and privacy" category was split into Background apps and processes, Visual effects and smoothness, Updates and Store, Services and features almost nobody uses, Apps, browsers and AI, Privacy and telemetry and Interface and comfort. Order: background, effects, storage and memory, updates, services, security, apps/browsers/AI, privacy, interface, restore points and removing parts of Windows.
- **Split options**: those that did several things in one checkbox are now separate options, each with its own explanation, status reading, Apply and Restore. The original id stayed for the main part. If you already had the big option applied, each new part reads its own status and shows as applied.
  - Data tracking and collection -> activity history, location, Wi-Fi Sense, cloud settings sync, typing learning, cloud speech, automatic map downloads and online DRM (with HomeGroup, which no longer exists).
  - Ads, suggestions and Bing -> ads and suggestions / Bing and web search in Start.
  - Windows sounds -> sounds / startup sound. Visual effects -> effects / transparency. Widgets -> Widgets / Task View button.
  - Printing, local network and Remote Desktop -> printing / network discovery and casting / Remote Desktop.
  - Connected devices and clipboard -> shared experiences / clipboard history. Fast shutdown and startup -> fast shutdown / startup programs wait.
  - Legacy features -> Remote Assistance / AutoPlay / error reporting. Program telemetry -> Office / NVIDIA / PowerShell 7.
  - Edge and Brave bloat -> Edge / Brave. AI features -> Windows AI / Notepad and Paint / Copilot in Word and Excel.
  - Gamer zone: hardware GPU and windowed games -> hardware-accelerated GPU / windowed game optimizations (Windows 11 only). Extensions and hidden files -> extensions / hidden files. USB, PCIe and disk power saving -> USB / PCI Express / disks.
  - Not split (and why): lists that are one thing (junk apps, extreme services, old components, telemetry tasks, hosts servers), the competitive mouse (speed and trail stay at the Windows value both when applying and restoring), Windows telemetry (lowering the service and leaving the level to receive new versions go together), each game's fullscreen and DPI (same registry value) and "Services and features almost nobody uses" (its Windows features cannot be read quickly without DISM).
- Profiles (Safe, Optimized, Competitive, Light RAM, Minimum RAM, laptop and Full) include the new parts of each option they already had: they apply exactly the same as before. The parts keep the original option's warnings (so "Tick only safe ones" does not tick anything new), the restart request (except windowed games, which take effect when you reopen the game) and the Windows version requirements.
- **Count bubble in each section** of the left menu, same as the one in Recommended configs (same style, in the corner). It counts by itself from what the app loaded: Profiles = profiles; Debloat and Gamer zone = options you can use on your PC (greyed-out ones for your Windows version, Windows 10/11 ones on Windows 7 and 8, and ones not needed for your hardware are not counted; it is recalculated after reading Windows and with "Re-read settings"); Clean cache = options to tick; Tools = tools; Recommended apps = apps. Home has none.
- `tests\Verificar-Opciones.ps1`: automatic check that fails if there are repeated ids, if a translation, a status check or the place in the impact order is missing, or if a split option is not in the profiles that had the original.

### Changes
- **One-click profiles**: "Apply profile" applies directly, without clash prompts or lists. If the profile needs missing drivers it **is not applied** until you install them (the button takes you to Tools). Performance profiles also remove OneDrive and the Defender icon from startup.
- **Clashes**: a single prompt with the current option against the new one to choose which stays; it no longer repeats when applying (it looked like a loop). If you fully turn off Windows Update, Xbox or the Microsoft Store, their child options are greyed out.
- Short, clear names (Clean up startup, Remove apps, Turn off services...), an emoji on each category and double dividers at the start and end of each one.
- The changelog and loading texts show up in your language.
- **Measure FPS before and after** was removed. BIOS settings are still in Tools.
- Options that can **block updating to 26H2** are flagged (compatibility inventory, diagnostic tasks, telemetry in hosts, Windows Update off or paused).
- Xuca OPtimizer was renamed **Brío** (repo github.com/011Xuca/brio).
- Own color: sky blue (#60A5FA in dark, #1D4ED8 in light) in buttons, borders, selection and the icon (border and drawing). The app background becomes the icon's dark grey.
- App data (preferences, reading logs, Gaming helper programs and their tasks) moves to ProgramData\Brio. The first time it opens they move on their own, losing nothing, and the helper programs that were running are turned on again.
- Recommended apps: the PC monitor card is now **Pulso** (github.com/011Xuca/pulso).
- If you had Xuca OPtimizer, it updates itself to Brío from the update prompt: it downloads the new app and the desktop shortcut is renamed Brío.

### Fixed
- **Windows "not activated" or "not genuine" on a local account**: "Turn off Store installs" turned off LicenseManager, which activation uses. It is no longer turned off, no option can turn off `sppsvc`, `ClipSVC`, `LicenseManager`, `wlidsvc` or `KeyIso` or the license tasks, the hosts file never blocks activation servers, and if any was left off by an old version it is fixed automatically.
- **Snipping Tool and Win+Shift+S stopped working** without warning: "Turn off per-user services" turned off the clipboard (`cbdhsvc`). It no longer touches it and turns it back on if it was off.
- **Turning off Windows Update completely did not last**: the Windows Update Medic and the Orchestrator tasks turned it back on, and on Windows 11 `UsoSvc` could not be changed. Now they are turned off too, as SYSTEM when needed.
- The 3 errors of "Delete accessibility and speech" (`raiz de registro desconocida: HKCU:`): the registry accepts both ways of writing the path.
- The pause to turn off **Tamper Protection** before turning off Defender checks that it is really off and waits for you to confirm.
- "Reduce telemetry" no longer turns off the compatibility appraiser (without it Windows Update does not offer 26H2).
- The final Debloat summary now also counts PowerShell errors (PS-ERROR) and pending items, not only FALLO. Before, it said "all good" even when options failed.
- When it finishes it shows "All went well" or the list of what failed or is pending.
- Fixed "Item not found" when removing or reading Windows components (old apps, languages, accessibility): it is now noted as a warning and continues.
- Fixed pnputil and dism not being recognized on PCs with System32 outside the PATH (unused drivers, component cleanup).
- Updater: if a file could not be replaced (open in another program or the antivirus), the app was left half new and half old. Now it saves a copy of each file before overwriting it and, if something fails, puts everything back as it was.
- Updater: if a file is locked for a moment (for example, the antivirus scanning it) it retries, and if another window of the app has it (another open copy or a tool in its console) it closes it by itself before replacing it. Then, as always, it closes and opens the new version.
- Updater: read-only files no longer make the update fail.
- Updater: the app kept its icon locked while open and the update could not replace it. Now it reads it into memory.
- Restoring the antivirus now also removes Edge's SmartScreen policies (before, Edge stayed without SmartScreen and said "managed by your organization").
- Updater: on Wi-Fi with a login page (hotel, cafe) a false "new version" no longer appears.
- Updater: if the network hangs while looking for new versions, the app opens anyway after 8 seconds.
- If you tap "No" on the Windows permission prompt, the app closes without showing an error.
- Windows tools (sc, reg, powercfg, icacls, DISM...) are found even if the PC lacks System32 in the PATH.
- Hiber text in Recommended apps: "tabs" showed odd characters.
- In English, the Recommended apps descriptions, the Profiles description, the fixed Cleanup text and several section titles (Profiles, Debloat and Cleanup) showed in Spanish or mixed.
- Light theme: "Already applied", the networks button and the Releases link were hard to read (light green and blue on white).

### Windows 7 and 8.1
- Brio.bat checks that PowerShell 5.1 is there and, if missing (Windows 7 ships 2.0), says what to install instead of closing without explanation. install.ps1 does the same.
- Options that use commands Windows 7 and 8 lack (Store apps, Defender, BitLocker, new scheduled tasks, per-adapter DNS, devices, local accounts) show greyed out as unsupported and the scripts skip them with a warning.
- On Windows 7, Debloat, Gamer zone and Cleanup no longer cut off halfway when looking for Store apps; component cleanup (DISM) is skipped because that Windows does not have it.
- README: how to install on Windows 7 SP1 and 8.1 (WMF 5.1 and TLS 1.2).
