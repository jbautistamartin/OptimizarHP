# Configura el Explorador de Windows:
# - Muestra archivos y carpetas ocultos
# - Muestra extensiones de archivo
# - Muestra archivos protegidos del sistema

$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

Set-ItemProperty -Path $explorerPath -Name "Hidden"      -Value 1 -Type DWord -Force  # Mostrar ocultos
Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord -Force  # Mostrar extensiones
Set-ItemProperty -Path $explorerPath -Name "ShowSuperHidden" -Value 1 -Type DWord -Force  # Mostrar archivos de sistema

Write-Host "Explorador configurado correctamente."

if ($global:ReiniciarExplorer) {
    Stop-Process -Name explorer -Force
    Write-Host "Explorador reiniciado."
} else {
    Write-Host "Reinicia el Explorador manualmente para aplicar el cambio."
}
