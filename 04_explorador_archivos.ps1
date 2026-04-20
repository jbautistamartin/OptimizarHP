# Configura el Explorador de Windows y la barra de tareas:
# - Muestra archivos y carpetas ocultos, extensiones y archivos de sistema
# - Abre "Este equipo" al iniciar el Explorador, con vista compacta
# - Muestra la ruta completa en la barra de titulo
# - Centra los iconos de la barra de tareas
# - Deshabilita el servicio de Widgets (panel del tiempo/noticias) por directiva
# - Oculta barra de busqueda, Widgets, Chat y Task View de la barra de tareas
# - Oculta icono "Descubre mas sobre esta imagen" del escritorio
# - Quita la seccion "Recomendados" del menu Inicio
# - Muestra segundos en el reloj de la barra de tareas
# - Oculta OneDrive del panel de navegacion
# - Desancla Escritorio, Imagenes, Musica y Videos de la seccion Anclados
# - Ancla la carpeta personal del usuario actual
# Requiere ejecutarse como Administrador (modifica claves HKLM).

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# --- Explorador de archivos ---
Set-ItemProperty -Path $explorerPath -Name "Hidden"               -Value 1 -Type DWord -Force  # Mostrar ocultos
Set-ItemProperty -Path $explorerPath -Name "HideFileExt"          -Value 0 -Type DWord -Force  # Mostrar extensiones
Set-ItemProperty -Path $explorerPath -Name "ShowSuperHidden"      -Value 1 -Type DWord -Force  # Mostrar archivos de sistema
Set-ItemProperty -Path $explorerPath -Name "LaunchTo"             -Value 1 -Type DWord -Force  # Abrir "Este equipo" en vez de Inicio
Set-ItemProperty -Path $explorerPath -Name "UseCompactMode"       -Value 1 -Type DWord -Force  # Vista compacta: menos espacio entre elementos

# Ruta completa en la barra de titulo del Explorador
$cabinetPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"
if (-not (Test-Path $cabinetPath)) { New-Item -Path $cabinetPath -Force | Out-Null }
Set-ItemProperty -Path $cabinetPath -Name "FullPath" -Value 1 -Type DWord -Force

# --- Barra de tareas y escritorio ---
# Algunas de estas claves pueden estar protegidas en Windows 11 24H2+; se continua si fallan.
$taskbarProps = @(
    @{ Name = "TaskbarAl";                Value = 1; Desc = "Centrar iconos de la barra de tareas" },
    @{ Name = "TaskbarDa";                Value = 0; Desc = "Ocultar boton Widgets" },
    @{ Name = "TaskbarMn";                Value = 0; Desc = "Ocultar boton Chat (Teams)" },
    @{ Name = "ShowTaskViewButton";       Value = 0; Desc = "Ocultar boton Task View" },
    @{ Name = "ShowSecondsInSystemClock"; Value = 1; Desc = "Mostrar segundos en el reloj" },
    @{ Name = "ShowSpotlightDesktop";     Value = 0; Desc = "Ocultar icono 'Descubre mas sobre esta imagen'" }
)
foreach ($prop in $taskbarProps) {
    try {
        Set-ItemProperty -Path $explorerPath -Name $prop.Name -Value $prop.Value -Type DWord -Force -ErrorAction Stop
    } catch {
        Write-Warning "No se pudo aplicar '$($prop.Desc)': $_"
    }
}

# Ocultar barra de busqueda de la barra de tareas (0=oculto, 1=icono, 2=caja completa)
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
        -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force -ErrorAction Stop
} catch {
    Write-Warning "No se pudo ocultar la barra de busqueda: $_"
}

# Deshabilitar completamente el servicio de Widgets (panel del tiempo/noticias)
# AllowNewsAndInterests=0 via Group Policy impide que el proceso arranque
$dshPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $dshPath)) { New-Item -Path $dshPath -Force | Out-Null }
Set-ItemProperty -Path $dshPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force

# --- Menu Inicio ---
# Quitar seccion "Recomendados" (archivos recientes) del menu Inicio (Windows 11 23H2+)
$explorerPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $explorerPolicyPath)) { New-Item -Path $explorerPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $explorerPolicyPath -Name "HideRecommendedSection" -Value 1 -Type DWord -Force

# --- Panel de navegacion ---
# Ocultar OneDrive del panel de navegacion del Explorador
$clsidOneDrive = "{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$regOneDrive = "HKCU:\Software\Classes\CLSID\$clsidOneDrive"
if (-not (Test-Path $regOneDrive)) { New-Item -Path $regOneDrive -Force | Out-Null }
Set-ItemProperty -Path $regOneDrive -Name "System.IsPinnedToNamespaceTree" -Value 0 -Type DWord -Force

# --- Elementos anclados (seccion Anclados / Acceso rapido) ---
$shell = New-Object -ComObject Shell.Application
$carpetasQuitar = @(
    [System.Environment]::GetFolderPath("Desktop"),
    [System.Environment]::GetFolderPath("MyPictures"),
    [System.Environment]::GetFolderPath("MyMusic"),
    [System.Environment]::GetFolderPath("MyVideos")
)
foreach ($carpeta in $carpetasQuitar) {
    $ns = $shell.Namespace($carpeta)
    if ($ns) { $ns.Self.InvokeVerb("unpinfromhome") }
}

# Anclar carpeta personal del usuario actual
$carpetaUsuario = [System.Environment]::GetFolderPath("UserProfile")
$shell.Namespace($carpetaUsuario).Self.InvokeVerb("pintohome")

Write-Host "Explorador configurado correctamente."

if ($global:ReiniciarExplorer) {
    Stop-Process -Name explorer -Force
    Write-Host "Explorador reiniciado."
} else {
    Write-Host "Reinicia el Explorador manualmente para aplicar el cambio."
}
