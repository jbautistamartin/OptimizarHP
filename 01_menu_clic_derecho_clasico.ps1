# Restaura el menú contextual clásico de Windows 10 en Windows 11
# (elimina el "Mostrar más opciones" y muestra todas las opciones directamente)

$registryPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

New-Item -Path $registryPath -Force | Out-Null
Set-ItemProperty -Path $registryPath -Name "(Default)" -Value "" -Force

Write-Host "Menú clásico activado. Reinicia el Explorador de Windows para aplicar el cambio."

# Reinicia el Explorador sin cerrar ventanas abiertas
Stop-Process -Name explorer -Force
