# Configura Microsoft Edge via politicas de grupo (Group Policy registry)
# - Pagina de inicio: Google
# - Nueva pestana: Google
# - Buscador predeterminado: Google
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $policyPath -Force | Out-Null

# Pagina de inicio
Set-ItemProperty -Path $policyPath -Name "HomepageLocation"    -Value "https://www.google.com" -Force
Set-ItemProperty -Path $policyPath -Name "HomepageIsNewTabPage" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "ShowHomeButton"       -Value 1 -Type DWord -Force

# Nueva pestana
Set-ItemProperty -Path $policyPath -Name "NewTabPageLocation" -Value "https://www.google.com" -Force

# Buscador predeterminado
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderEnabled"    -Value 1 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderName"       -Value "Google" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderKeyword"    -Value "google.com" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSearchURL"  -Value "https://www.google.com/search?q={searchTerms}" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSuggestURL" -Value "https://clients1.google.com/complete/search?client=chrome&q={searchTerms}" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderIconURL"    -Value "https://www.google.com/favicon.ico" -Force

# Cierra Edge para que aplique la politica al reabrir
Write-Host "Cerrando Edge para aplicar cambios..."
Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Edge configurado. Vuelve a abrir Edge para comprobar los cambios."
