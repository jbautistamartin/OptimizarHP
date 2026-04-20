# Script principal de optimizacion de Windows 11
# Ejecuta todos los pasos en orden. Requiere Administrador.
#
# Uso:
#   .\00_ejecutar_todo.ps1                    -> modo Personal (por defecto)
#   .\00_ejecutar_todo.ps1 -Modo Empresarial

param(
    [ValidateSet("Personal", "Empresarial")]
    [string]$Modo = "Personal"
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Opciones globales ----
$global:ReiniciarExplorer = $false  # Reinicia el Explorador tras cambios que lo requieran
$global:Modo = $Modo                # Disponible para los scripts individuales

$pasos = @(
    @{ Numero = "01"; Nombre = "Menu clic derecho clasico";              Archivo = "01_menu_clic_derecho_clasico.ps1"; Modos = @("Personal", "Empresarial") },
    @{ Numero = "02"; Nombre = "Integrar terminales en menu";            Archivo = "02_integrar_terminales.ps1";       Modos = @("Personal", "Empresarial") },
    @{ Numero = "03"; Nombre = "Configurar Edge";                        Archivo = "03_configurar_edge.ps1";           Modos = @("Personal", "Empresarial") },
    @{ Numero = "04"; Nombre = "Explorador: ocultos y extensiones";      Archivo = "04_explorador_archivos.ps1";       Modos = @("Personal", "Empresarial") },
    @{ Numero = "05"; Nombre = "Eliminar bloatware y optimizar servicios"; Archivo = "05_eliminar_bloatware.ps1";      Modos = @("Personal", "Empresarial") },
    @{ Numero = "06"; Nombre = "Privacidad de aplicaciones";             Archivo = "06_privacidad_apps.ps1";           Modos = @("Personal", "Empresarial") },
    @{ Numero = "07"; Nombre = "Energia y rendimiento";                  Archivo = "07_energia_rendimiento.ps1";       Modos = @("Personal", "Empresarial") }
)

$errores = @()

Write-Host ""
Write-Host "Modo: $Modo" -ForegroundColor Magenta

foreach ($paso in $pasos) {
    if ($Modo -notin $paso.Modos) { continue }

    $ruta = Join-Path $scriptDir $paso.Archivo
    Write-Host ""
    Write-Host "[$($paso.Numero)] $($paso.Nombre)..." -ForegroundColor Cyan

    if (-not (Test-Path $ruta)) {
        Write-Host "     OMITIDO - archivo no encontrado: $($paso.Archivo)" -ForegroundColor Yellow
        continue
    }

    try {
        & $ruta
        Write-Host "     OK" -ForegroundColor Green
    } catch {
        Write-Host "     ERROR: $_" -ForegroundColor Red
        $errores += $paso.Nombre
    }
}

Write-Host ""
if ($errores.Count -eq 0) {
    Write-Host "Todos los pasos completados correctamente." -ForegroundColor Green
} else {
    Write-Host "Completado con errores en: $($errores -join ', ')" -ForegroundColor Red
}

Write-Host ""
Write-Host "Reinicia el equipo para asegurarte de que todos los cambios surtan efecto."
