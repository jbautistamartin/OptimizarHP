# Configura permisos de privacidad de aplicaciones.
# Deniega el acceso global de las apps al microfono, camara, localizacion,
# contactos, calendario, correo, mensajes, historial de llamadas y otros recursos.
#
# Para permitir el acceso a una app concreta tras ejecutar este script:
#   Configuracion > Privacidad y seguridad > [nombre del recurso] > [app]

# No requiere Administrador: modifica solo claves HKCU.

$consentBase = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"

$recursos = @(
    @{ Clave = "location";               Nombre = "Localizacion GPS" }
    @{ Clave = "microphone";             Nombre = "Microfono" }
    @{ Clave = "webcam";                 Nombre = "Camara" }
    @{ Clave = "contacts";               Nombre = "Contactos" }
    @{ Clave = "appointments";           Nombre = "Calendario" }
    @{ Clave = "userAccountInformation"; Nombre = "Informacion de cuenta de usuario" }
    @{ Clave = "email";                  Nombre = "Correo electronico" }
    @{ Clave = "chat";                   Nombre = "Mensajes" }
    @{ Clave = "phoneCallHistory";       Nombre = "Historial de llamadas" }
    @{ Clave = "radios";                 Nombre = "Control de radios (Bluetooth/WiFi)" }
    @{ Clave = "activity";               Nombre = "Actividad fisica (sensor de movimiento)" }
    @{ Clave = "bluetoothSync";          Nombre = "Sincronizacion Bluetooth" }
    @{ Clave = "gazeInput";              Nombre = "Seguimiento ocular" }
)

Write-Host ""
Write-Host "Configurando privacidad de aplicaciones..." -ForegroundColor Cyan

foreach ($recurso in $recursos) {
    $ruta = "$consentBase\$($recurso.Clave)"
    if (-not (Test-Path $ruta)) { New-Item -Path $ruta -Force | Out-Null }
    Set-ItemProperty -Path $ruta -Name "Value" -Value "Deny" -Type String -Force
    Write-Host "  OK  $($recurso.Nombre)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Privacidad de aplicaciones configurada correctamente." -ForegroundColor Green
Write-Host "Para dar acceso a una app concreta: Configuracion > Privacidad y seguridad > [recurso]" -ForegroundColor Yellow
