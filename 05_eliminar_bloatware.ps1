# Elimina bloatware, deshabilita servicios innecesarios y tareas programadas.
# Desactiva telemetria, IA de Microsoft y elementos de inicio innecesarios.
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

function Ensure-RegistryKey($path) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
}


# ==================================================
# 1. DESINSTALAR APPS (BLOATWARE + IA)
# ==================================================
# Comenta cualquier linea para conservar esa app.

$appsEliminar = @(
    # Xbox
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"       # Xbox Game Bar
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.GamingApp"

    # Redes sociales / entretenimiento OEM
    "SpotifyAB.SpotifyMusic"
    "BytedancePte.Ltd.TikTok"
    "Disney.37853D22215B2"
    "AmazonVideo.PrimeVideo"
    "Facebook.Facebook"
    "Facebook.Instagram"

    # Microsoft innecesarias
    "Microsoft.MicrosoftTeams"          # Teams personal (consumer)
    "Microsoft.SkypeApp"
    "Microsoft.549981C3F5F10"           # Cortana
    "Microsoft.BingNews"                # Noticias
    "Microsoft.BingWeather"             # Tiempo
    "Microsoft.WindowsMaps"
    "Microsoft.People"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Microsoft3DViewer"
    #"Microsoft.MSPaint"                 # Paint 3D
    "Microsoft.Getstarted"              # Tips
    "Microsoft.GetHelp"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.MicrosoftOfficeHub"      # Get Office
    #"Microsoft.YourPhone"               # Phone Link (opcional)
    "Microsoft.Todos"                   # Microsoft To Do
    "Microsoft.ZuneMusic"               # Groove Music
    "Microsoft.ZuneVideo"               # Peliculas y TV
    "Microsoft.Clipchamp"
    "MicrosoftCorporationII.MicrosoftFamily"  # Family Safety
    "Microsoft.WindowsCommunicationsApps"     # Correo y Calendario

    # Widgets (panel de noticias y tiempo de la barra de tareas)
    "MicrosoftWindows.Client.WebExperience"   # Panel Widgets: noticias, tiempo, bolsa, etc.

    # IA de Microsoft
    "Microsoft.Copilot"                       # App Copilot
    "Microsoft.Windows.Copilot"               # Copilot integrado (22H2-23H2)
    "MicrosoftWindows.Client.CoPilot"         # Copilot integrado (24H2)
    "Microsoft.Windows.Ai.Copilot.Provider"   # Proveedor Copilot
    "MicrosoftWindows.Client.AIX"             # Windows AI eXperience: Recall y Click to Do (24H2)
)

Write-Host ""
Write-Host "[1/7] Desinstalando apps..." -ForegroundColor Cyan

# Obtenemos todos los paquetes provisionados de una sola vez para no repetir la consulta en cada iteracion
$provisionados = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

foreach ($app in $appsEliminar) {
    $paquete = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    if ($paquete) {
        try {
            Remove-AppxPackage -Package $paquete.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "  OK  $app" -ForegroundColor Green
        } catch {
            Write-Host "  ERR $app - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  --  $app (no instalada)" -ForegroundColor DarkGray
    }

    # Evita que Windows vuelva a instalarla en nuevos usuarios
    $provision = $provisionados | Where-Object { $_.DisplayName -eq $app }
    if ($provision) {
        Remove-AppxProvisionedPackage -Online -PackageName $provision.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}


# ==================================================
# 2. DESHABILITAR SERVICIOS
# ==================================================
# Cambia -StartupType a "Manual" si prefieres no deshabilitar del todo.

$servicios = @(
    @{ Nombre = "DiagTrack";             Motivo = "Telemetria a Microsoft" }
    @{ Nombre = "dmwappushservice";      Motivo = "Telemetria WAP Push" }
    @{ Nombre = "XblAuthManager";        Motivo = "Xbox Live Auth" }
    @{ Nombre = "XblGameSave";           Motivo = "Xbox Live Game Save" }
    @{ Nombre = "XboxNetApiSvc";         Motivo = "Xbox Live Networking" }
    @{ Nombre = "XboxGipSvc";            Motivo = "Xbox Accessory Management" }
    @{ Nombre = "lfsvc";                 Motivo = "Geolocalizacion" }
    @{ Nombre = "MapsBroker";            Motivo = "Mapas offline" }
    @{ Nombre = "RetailDemo";            Motivo = "Modo demo de tienda" }
    @{ Nombre = "Fax";                   Motivo = "Servicio de Fax" }
    @{ Nombre = "wisvc";                 Motivo = "Windows Insider" }
    @{ Nombre = "WMPNetworkSvc";         Motivo = "Compartir media DLNA" }
    @{ Nombre = "MixedRealityOpenXRSvc"; Motivo = "Mixed Reality / VR" }
    @{ Nombre = "WSearch";               Motivo = "Indexacion de busqueda de Windows" }
    @{ Nombre = "Spooler";               Motivo = "Cola de impresion" }
    @{ Nombre = "SysMain";               Motivo = "Superfetch: precarga apps en RAM (util en HDD, innecesario en SSD)" }
    @{ Nombre = "WerSvc";                Motivo = "Windows Error Reporting: envia volcados de error a Microsoft" }
    @{ Nombre = "WbioSrvc";              Motivo = "Biometria de Windows: huella dactilar y Windows Hello facial" }
)

Write-Host ""
Write-Host "[2/7] Deshabilitando servicios..." -ForegroundColor Cyan

foreach ($svc in $servicios) {
    $servicio = Get-Service -Name $svc.Nombre -ErrorAction SilentlyContinue
    if ($servicio) {
        try {
            Stop-Service -Name $svc.Nombre -Force -ErrorAction SilentlyContinue
            Set-Service  -Name $svc.Nombre -StartupType Disabled -ErrorAction Stop
            Write-Host "  OK  $($svc.Nombre) - $($svc.Motivo)" -ForegroundColor Green
        } catch {
            Write-Host "  ERR $($svc.Nombre) - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  --  $($svc.Nombre) (no existe)" -ForegroundColor DarkGray
    }
}


# ==================================================
# 3. DESHABILITAR TAREAS PROGRAMADAS
# ==================================================

$tareas = @(
    # --- Telemetria y diagnostico ---
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "\Microsoft\Windows\PI\Sqm-Tasks"                                 # Recopilacion calidad de servicio

    # --- Xbox y juegos ---
    "\Microsoft\XblGameSave\XblGameSaveTask"

    # --- Mapas y familia ---
    "\Microsoft\Windows\Maps\MapsToastTask"
    "\Microsoft\Windows\Maps\MapsUpdateTask"
    "\Microsoft\Windows\Shell\FamilySafetyMonitor"
    "\Microsoft\Windows\Shell\FamilySafetyRefresh"

    # --- Sincronizacion de configuracion con la nube ---
    "\Microsoft\Windows\SettingSync\BackgroundUploadTask"
    "\Microsoft\Windows\SettingSync\NetworkStateChangeTask"

    # --- Experiencia en la nube / OOBE ---
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"

    # --- Tareas de inicio innecesarias ---
    "\Microsoft\Windows\Application Experience\StartupAppTask"        # Analiza apps instaladas al inicio

    # --- Auto-actualizacion (el usuario actualiza manualmente) ---
    "\Microsoft\Windows\WindowsUpdate\Automatic App Update"           # Tienda Microsoft: actualiza apps automaticamente
    "\MicrosoftEdgeUpdateTaskMachineCore"                              # Edge: comprueba actualizacion al iniciar sesion
    "\MicrosoftEdgeUpdateTaskMachineUA"                                # Edge: comprueba actualizacion periodicamente

    # --- IA de Microsoft (Recall) ---
    "\Microsoft\Windows\WindowsAI\RetrieveIndexTask"                  # Recall: indexacion de pantalla
    "\Microsoft\Windows\WindowsAI\RetrieveStorageSpaceTask"           # Recall: gestion de espacio
    "\Microsoft\Windows\WindowsAI\ThrottledRetrieveTask"              # Recall: procesado en segundo plano

    # --- Tienda: busqueda de actualizaciones e instalacion al iniciar sesion ---
    "\Microsoft\Windows\InstallService\ScanForUpdates"                # Busca actualizaciones de apps de Tienda al arrancar
    "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"          # Lo mismo, ejecutado como el usuario actual
    "\Microsoft\Windows\PushToInstall\LoginCheck"                     # Comprueba apps empujadas por la Tienda al hacer login
    "\Microsoft\Windows\PushToInstall\Registration"                   # Registra el equipo para recibir apps remotas de la Tienda

    # --- Corporativo (irrelevante en uso domestico) ---
    "\Microsoft\Windows\Work Folders\Work Folders Logon Synchronization"  # Sincroniza Work Folders al iniciar sesion

    # --- Mantenimiento automatico nocturno ---
    "\Microsoft\Windows\TaskScheduler\Regular Maintenance"                # Despierta el PC a las 2am para mantenimiento
    "\Microsoft\Windows\TaskScheduler\Maintenance Configurator"           # Configura el mantenimiento automatico nocturno
)

Write-Host ""
Write-Host "[3/7] Deshabilitando tareas programadas..." -ForegroundColor Cyan

foreach ($tarea in $tareas) {
    try {
        $taskPath = Split-Path $tarea
        $taskName = Split-Path $tarea -Leaf
        $t = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
        if ($t) {
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
            Write-Host "  OK  $tarea" -ForegroundColor Green
        } else {
            Write-Host "  --  $tarea (no existe)" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  ERR $tarea - $_" -ForegroundColor Red
    }
}


# ==================================================
# 4. TELEMETRIA (REGISTRO)
# ==================================================

Write-Host ""
Write-Host "[4/7] Desactivando telemetria por registro..." -ForegroundColor Cyan

# Nivel de telemetria a minimo
# (0=Seguridad solo en Enterprise/Education; en Home/Pro queda en 1=Basico, que es el minimo permitido)
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Ensure-RegistryKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
    -Name "AllowTelemetry" -Value 0 -Type DWord -Force

# Desactivar ID de publicidad personalizada
Ensure-RegistryKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
    -Name "Enabled" -Value 0 -Type DWord -Force

# Desactivar historial de actividad (Timeline)
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name "EnableActivityFeed"    -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name "UploadUserActivities"  -Value 0 -Type DWord -Force

# Desactivar informe de errores de Windows
Ensure-RegistryKey "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" `
    -Name "Disabled" -Value 1 -Type DWord -Force

# Desactivar datos de escritura y mecanografia enviados a Microsoft
Ensure-RegistryKey "HKCU:\Software\Microsoft\Input\TIPC"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Input\TIPC" `
    -Name "Enabled" -Value 0 -Type DWord -Force

# Desactivar encuestas de retroalimentacion
Ensure-RegistryKey "HKCU:\Software\Microsoft\Siuf\Rules"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" `
    -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord -Force

# Desactivar inventario y telemetria de compatibilidad de aplicaciones
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" `
    -Name "AITEnable"        -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" `
    -Name "DisableInventory" -Value 1 -Type DWord -Force

# Windows Update: no reiniciar automaticamente si hay una sesion abierta
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force

# No instalar drivers automaticamente desde Windows Update (el usuario los instala manualmente)
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force

# Windows Defender: no enviar muestras de archivos sospechosos a Microsoft automaticamente
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" `
    -Name "SubmitSamplesConsent" -Value 2 -Type DWord -Force  # 0=Pedir, 1=Solo seguros, 2=Nunca, 3=Todo

Write-Host "  OK  Telemetria desactivada" -ForegroundColor Green


# ==================================================
# 5. IA DE MICROSOFT (COPILOT Y RECALL)
# ==================================================

Write-Host ""
Write-Host "[5/7] Desactivando IA de Microsoft..." -ForegroundColor Cyan

# Deshabilitar Windows Copilot via politica de grupo (usuario y maquina)
Ensure-RegistryKey "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
    -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
    -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force

# Deshabilitar Windows Recall y analisis de IA en pantalla (Windows 11 24H2+)
Ensure-RegistryKey "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" `
    -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" `
    -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force

# Ocultar boton Copilot en la barra de tareas
Ensure-RegistryKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowCopilotButton" -Value 0 -Type DWord -Force

# Desactivar Copilot y barra lateral en Edge (refuerzo al script 03)
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "HubsSidebarEnabled"    -Value 0 -Type DWord -Force  # Barra lateral con Copilot
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "CopilotCDPPageContext" -Value 0 -Type DWord -Force  # Copilot no lee el contenido de la pagina

Write-Host "  OK  Copilot y Recall desactivados" -ForegroundColor Green


# ==================================================
# 6. INICIO DE WINDOWS (STARTUP)
# ==================================================

Write-Host ""
Write-Host "[6/7] Limpiando inicio de Windows..." -ForegroundColor Cyan

# Quitar OneDrive del inicio automatico
$runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
foreach ($entrada in @("OneDrive", "OneDriveSetup")) {
    if (Get-ItemProperty -Path $runPath -Name $entrada -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $runPath -Name $entrada -ErrorAction SilentlyContinue
        Write-Host "  OK  Quitado del inicio: $entrada" -ForegroundColor Green
    } else {
        Write-Host "  --  $entrada (no estaba en el inicio)" -ForegroundColor DarkGray
    }
}

# Desactivar Edge Startup Boost: se lanza en segundo plano al arrancar Windows
Ensure-RegistryKey "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "StartupBoostEnabled"   -Value 0 -Type DWord -Force  # Precarga Edge al iniciar Windows
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force  # Edge se mantiene activo al cerrarlo

# Quitar entradas MicrosoftEdgeAutoLaunch_* del inicio (complemento al StartupBoost)
Get-Item $runPath | Select-Object -ExpandProperty Property |
    Where-Object { $_ -like "MicrosoftEdgeAutoLaunch*" } |
    ForEach-Object {
        Remove-ItemProperty -Path $runPath -Name $_ -ErrorAction SilentlyContinue
        Write-Host "  OK  Quitado del inicio: $_" -ForegroundColor Green
    }

# Desactivar Fast Startup (inicio rapido): Windows guarda un hibernado parcial al apagar.
# Puede impedir que las actualizaciones se apliquen y da problemas en dual-boot.
Ensure-RegistryKey "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
    -Name "HiberbootEnabled" -Value 0 -Type DWord -Force

# Desactivar apps en segundo plano globalmente (apps de Tienda no reciben datos al estar cerradas)
Ensure-RegistryKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
    -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force

# Desactivar Windows Spotlight en la pantalla de bloqueo (descarga imagenes y anuncios de internet)
# y sugerencias y tips de Windows que aparecen al iniciar sesion
$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Ensure-RegistryKey $cdmPath
Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenEnabled"         -Value 0 -Type DWord -Force  # Spotlight
Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenOverlayEnabled"  -Value 0 -Type DWord -Force  # Info sobre Spotlight
Set-ItemProperty -Path $cdmPath -Name "SoftLandingEnabled"                -Value 0 -Type DWord -Force  # Tips tras actualizaciones
Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled"   -Value 0 -Type DWord -Force  # "Consejos y sugerencias al usar Windows"
Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338389Enabled"   -Value 0 -Type DWord -Force  # Consejos en la pantalla de bloqueo
Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-353698Enabled"   -Value 0 -Type DWord -Force  # Sugerencias en Timeline
Set-ItemProperty -Path $cdmPath -Name "SystemPaneSuggestionsEnabled"      -Value 0 -Type DWord -Force  # Apps sugeridas en el menu Inicio
Set-ItemProperty -Path $cdmPath -Name "PreInstalledAppsEnabled"           -Value 0 -Type DWord -Force  # No reinstala apps preinstaladas de fabrica
Set-ItemProperty -Path $cdmPath -Name "OemPreInstalledAppsEnabled"        -Value 0 -Type DWord -Force  # No reinstala apps OEM preinstaladas
Set-ItemProperty -Path $cdmPath -Name "ContentDeliveryAllowed"            -Value 0 -Type DWord -Force  # Bloquea toda entrega de contenido de Microsoft

Write-Host "  OK  Inicio de Windows optimizado" -ForegroundColor Green


# ==================================================
# 7. SEGURIDAD
# ==================================================

Write-Host ""
Write-Host "[7/7] Aplicando configuracion de seguridad..." -ForegroundColor Cyan

# Deshabilitar SMBv1: protocolo de red obsoleto, vector comun de ransomware (WannaCry, etc.)
try {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop
    Write-Host "  OK  SMBv1 deshabilitado" -ForegroundColor Green
} catch {
    Write-Host "  ERR SMBv1 - $_" -ForegroundColor Red
}

# Deshabilitar AutoRun y AutoPlay en todos los tipos de unidad
# (evita ejecucion automatica de malware desde USB, CD, etc.)
Ensure-RegistryKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord -Force   # 255 = desactivar en todos los tipos
Ensure-RegistryKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord -Force

Write-Host "  OK  AutoRun/AutoPlay deshabilitado en todas las unidades" -ForegroundColor Green

# Deshabilitar Wi-Fi Sense: Windows no se conecta automaticamente a hotspots sugeridos por contactos
Ensure-RegistryKey "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" `
    -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord -Force
Write-Host "  OK  Wi-Fi Sense deshabilitado" -ForegroundColor Green

# Deshabilitar Escritorio Remoto (RDP): permite conexiones remotas al escritorio
Ensure-RegistryKey "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 1 -Type DWord -Force
Write-Host "  OK  Escritorio Remoto (RDP) deshabilitado" -ForegroundColor Green

# Deshabilitar Asistencia Remota: permite que terceros se conecten al escritorio para dar ayuda
Ensure-RegistryKey "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" `
    -Name "fAllowToGetHelp" -Value 0 -Type DWord -Force
Write-Host "  OK  Asistencia Remota deshabilitada" -ForegroundColor Green

Write-Host ""
Write-Host "Listo. Se recomienda reiniciar el equipo." -ForegroundColor Green
