# Elimina bloatware, deshabilita servicios innecesarios y tareas programadas.
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

# ==================================================
# 1. DESINSTALAR APPS (BLOATWARE)
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
    "Microsoft.Todos"                   # Microsoft To Do         <- comenta si lo usas
    "Microsoft.ZuneMusic"               # Groove Music
    "Microsoft.ZuneVideo"               # Peliculas y TV
    "Microsoft.Clipchamp"
    "MicrosoftCorporationII.MicrosoftFamily"  # Family Safety
    "Microsoft.WindowsCommunicationsApps"     # Correo y Calendario
)

Write-Host ""
Write-Host "[1/3] Desinstalando apps..." -ForegroundColor Cyan

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
    $provision = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -eq $app }
    if ($provision) {
        Remove-AppxProvisionedPackage -Online -PackageName $provision.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}


# ==================================================
# 2. DESHABILITAR SERVICIOS
# ==================================================
# Formato: @{ Nombre = "..."; Motivo = "..." }
# Cambia el valor de -StartupType a "Manual" si prefieres no deshabilitar del todo.

$servicios = @(
    @{ Nombre = "DiagTrack";            Motivo = "Telemetria a Microsoft" }
    @{ Nombre = "dmwappushservice";     Motivo = "Telemetria WAP Push" }
    @{ Nombre = "XblAuthManager";       Motivo = "Xbox Live Auth" }
    @{ Nombre = "XblGameSave";          Motivo = "Xbox Live Game Save" }
    @{ Nombre = "XboxNetApiSvc";        Motivo = "Xbox Live Networking" }
    @{ Nombre = "XboxGipSvc";           Motivo = "Xbox Accessory Management" }
    @{ Nombre = "lfsvc";                Motivo = "Geolocalizacion" }
    @{ Nombre = "MapsBroker";           Motivo = "Mapas offline" }
    @{ Nombre = "RetailDemo";           Motivo = "Modo demo de tienda" }
    # @{ Nombre = "RemoteRegistry";       Motivo = "Registro remoto (seguridad)" }
    @{ Nombre = "Fax";                  Motivo = "Servicio de Fax" }
    @{ Nombre = "wisvc";                Motivo = "Windows Insider" }
    @{ Nombre = "WMPNetworkSvc";        Motivo = "Compartir media DLNA" }
    @{ Nombre = "MixedRealityOpenXRSvc"; Motivo = "Mixed Reality / VR" }
    @{ Nombre = "WSearch";              Motivo = "Indexacion de busqueda de Windows" }
    @{ Nombre = "Spooler";              Motivo = "Cola de impresion" }
)

Write-Host ""
Write-Host "[2/3] Deshabilitando servicios..." -ForegroundColor Cyan

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
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "\Microsoft\Windows\Application Experience\StartupAppTask"
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "\Microsoft\Windows\Maps\MapsToastTask"
    "\Microsoft\Windows\Maps\MapsUpdateTask"
    "\Microsoft\Windows\Shell\FamilySafetyMonitor"
    "\Microsoft\Windows\Shell\FamilySafetyRefresh"
    "\Microsoft\XblGameSave\XblGameSaveTask"
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

Write-Host ""
Write-Host "[3/3] Deshabilitando tareas programadas..." -ForegroundColor Cyan

foreach ($tarea in $tareas) {
    try {
        $t = Get-ScheduledTask -TaskPath (Split-Path $tarea) -TaskName (Split-Path $tarea -Leaf) -ErrorAction SilentlyContinue
        if ($t) {
            Disable-ScheduledTask -TaskPath (Split-Path $tarea) -TaskName (Split-Path $tarea -Leaf) -ErrorAction Stop | Out-Null
            Write-Host "  OK  $tarea" -ForegroundColor Green
        } else {
            Write-Host "  --  $tarea (no existe)" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  ERR $tarea - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Bloatware eliminado. Se recomienda reiniciar el equipo." -ForegroundColor Green
