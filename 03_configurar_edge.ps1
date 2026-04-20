# Configura Microsoft Edge via politicas de grupo (Group Policy registry):
# - Pagina de inicio y de arranque: Google
# - Nueva pestana: Google (sin feed de noticias de Microsoft)
# - Buscador predeterminado: Google
# - Desactiva sugerencias Bing en la barra de direcciones
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $policyPath -Force | Out-Null

# --- Pagina de inicio (boton Home) ---
Set-ItemProperty -Path $policyPath -Name "HomepageLocation"     -Value "https://www.google.com" -Force
Set-ItemProperty -Path $policyPath -Name "HomepageIsNewTabPage" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "ShowHomeButton"       -Value 1 -Type DWord -Force

# --- Pagina al arrancar Edge ---
# 4 = abrir las URLs de RestoreOnStartupURLs
Set-ItemProperty -Path $policyPath -Name "RestoreOnStartup" -Value 4 -Type DWord -Force
$startupUrlsPath = "$policyPath\RestoreOnStartupURLs"
New-Item -Path $startupUrlsPath -Force | Out-Null
Set-ItemProperty -Path $startupUrlsPath -Name "1" -Value "https://www.google.com" -Force

# --- Nueva pestana ---
Set-ItemProperty -Path $policyPath -Name "NewTabPageLocation"            -Value "https://www.google.com" -Force
Set-ItemProperty -Path $policyPath -Name "NewTabPageContentEnabled"      -Value 0 -Type DWord -Force  # Desactiva el feed de noticias/tiempo de Microsoft
Set-ItemProperty -Path $policyPath -Name "NewTabPageHideDefaultTopSites" -Value 1 -Type DWord -Force  # Oculta los sitios sugeridos por Microsoft

# --- Buscador predeterminado ---
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderEnabled"    -Value 1 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderName"       -Value "Google" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderKeyword"    -Value "google.com" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSearchURL"  -Value "https://www.google.com/search?q={searchTerms}" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderSuggestURL" -Value "https://clients1.google.com/complete/search?client=chrome&q={searchTerms}" -Force
Set-ItemProperty -Path $policyPath -Name "DefaultSearchProviderIconURL"    -Value "https://www.google.com/favicon.ico" -Force

# Desactiva las sugerencias de busqueda de Bing en la barra de direcciones
Set-ItemProperty -Path $policyPath -Name "AddressBarMicrosoftSearchInBingProviderEnabled" -Value 0 -Type DWord -Force

# --- Cierra Edge para que aplique la politica al reabrir ---
Write-Host "Cerrando Edge para aplicar cambios..."
Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Edge configurado. Vuelve a abrir Edge para comprobar los cambios."
