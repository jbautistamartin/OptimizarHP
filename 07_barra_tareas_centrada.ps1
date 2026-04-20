# Centra los iconos de la barra de tareas (Windows 11)
# Solo toca HKCU, no requiere Administrador.

$ruta = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# TaskbarAl: 0 = izquierda, 1 = centrada
Set-ItemProperty -Path $ruta -Name "TaskbarAl" -Value 1 -Type DWord

Write-Host "Barra de tareas configurada como centrada."
