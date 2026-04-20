# Configura el plan de energia y ajustes de rendimiento:
# - Activa el plan Alto Rendimiento
# - Desactiva la suspension selectiva de USB
# - Desactiva el apagado automatico del disco duro por inactividad
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

# GUID del plan Alto Rendimiento (estandar en Windows)
$planAltoRendimiento = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# Subgrupo USB y su ajuste de suspension selectiva
$subgrupoUSB        = "2a737441-1930-4402-8d77-b2bebba308a3"
$ajusteUSBSuspend   = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"

# Subgrupo disco duro y su ajuste de apagado por inactividad
$subgrupoDisco      = "0012ee47-9041-4b5d-9b77-535fba8b1442"
$ajusteDiscoPowerOff = "6738e2c4-e8a5-4a42-b16a-e040e769756e"


# --- 1. Activar plan Alto Rendimiento ---
# Si no existe en el equipo (algunos OEM lo ocultan), lo duplica primero.
$planExiste = powercfg /list | Select-String $planAltoRendimiento
if (-not $planExiste) {
    powercfg /duplicatescheme $planAltoRendimiento | Out-Null
    Write-Host "  OK  Plan Alto Rendimiento creado" -ForegroundColor Green
}
powercfg /setactive $planAltoRendimiento
Write-Host "  OK  Plan de energia: Alto Rendimiento activado" -ForegroundColor Green


# --- 2. Desactivar suspension selectiva de USB ---
# Con corriente alterna (CA) y bateria (CC)
powercfg /setacvalueindex $planAltoRendimiento $subgrupoUSB $ajusteUSBSuspend 0
powercfg /setdcvalueindex $planAltoRendimiento $subgrupoUSB $ajusteUSBSuspend 0
Write-Host "  OK  Suspension selectiva de USB desactivada" -ForegroundColor Green


# --- 3. Nunca apagar el disco duro por inactividad ---
# Valor 0 = nunca apagar
powercfg /setacvalueindex $planAltoRendimiento $subgrupoDisco $ajusteDiscoPowerOff 0
powercfg /setdcvalueindex $planAltoRendimiento $subgrupoDisco $ajusteDiscoPowerOff 0
Write-Host "  OK  Apagado de disco duro por inactividad desactivado" -ForegroundColor Green


# Aplicar todos los cambios al plan activo
powercfg /setactive $planAltoRendimiento


# --- 4. Desactivar Power Throttling ---
# Windows limita la CPU de procesos en segundo plano para ahorrar energia.
# Con el plan Alto Rendimiento activo en escritorio, no tiene sentido.
$powerThrottlingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
if (-not (Test-Path $powerThrottlingPath)) { New-Item -Path $powerThrottlingPath -Force | Out-Null }
Set-ItemProperty -Path $powerThrottlingPath -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force
Write-Host "  OK  Power Throttling desactivado" -ForegroundColor Green


# --- 5. Efectos visuales: mejor rendimiento ---
# Desactiva animaciones y efectos graficos innecesarios.
# (2 = Ajustar para obtener el mejor rendimiento)
$visualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $visualFXPath)) { New-Item -Path $visualFXPath -Force | Out-Null }
Set-ItemProperty -Path $visualFXPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force
Write-Host "  OK  Efectos visuales: mejor rendimiento" -ForegroundColor Green


# --- 6. Desactivar Game Mode y Game DVR ---
# Game Mode puede causar stuttering en apps normales al priorizar erroneamente la GPU.
# Game DVR graba la pantalla en segundo plano consumiendo recursos.
$gameBarPath = "HKCU:\Software\Microsoft\GameBar"
if (-not (Test-Path $gameBarPath)) { New-Item -Path $gameBarPath -Force | Out-Null }
Set-ItemProperty -Path $gameBarPath -Name "AutoGameModeEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gameBarPath -Name "AllowAutoGameMode"   -Value 0 -Type DWord -Force
$gameConfigPath = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $gameConfigPath)) { New-Item -Path $gameConfigPath -Force | Out-Null }
Set-ItemProperty -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
Write-Host "  OK  Game Mode y Game DVR desactivados" -ForegroundColor Green


# --- 7. Eliminar archivo de hibernacion ---
# hiberfil.sys ocupa tantos GB como RAM tiene el equipo y no es necesario
# si el Fast Startup ya esta desactivado (script 05).
powercfg -h off
Write-Host "  OK  Archivo de hibernacion eliminado (hiberfil.sys)" -ForegroundColor Green

Write-Host ""
Write-Host "Energia y rendimiento configurados correctamente." -ForegroundColor Green
