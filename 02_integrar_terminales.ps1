# Agrega al menú contextual opciones para abrir terminales en carpetas
# y ejecutar scripts .ps1 y .cmd como administrador.
# Requiere ejecutarse como Administrador.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}

function Set-RegEntry {
    param([string]$Path, [string]$Value)
    New-Item -Path $Path -Force | Out-Null
    Set-ItemProperty -Path $Path -Name "(Default)" -Value $Value -Force
}

# ==================================================
# SOBRE CARPETAS (clic derecho en la carpeta)
# ==================================================

# CMD normal
Set-RegEntry "HKCR:\Directory\shell\CmdHere" "Abrir CMD aqui"
Set-ItemProperty "HKCR:\Directory\shell\CmdHere" -Name "Icon" -Value "cmd.exe" -Force
Set-RegEntry "HKCR:\Directory\shell\CmdHere\command" 'cmd.exe /k cd /d "%1"'

# CMD administrador
Set-RegEntry "HKCR:\Directory\shell\CmdHereAdmin" "Abrir CMD aqui (Administrador)"
Set-ItemProperty "HKCR:\Directory\shell\CmdHereAdmin" -Name "Icon"        -Value "cmd.exe" -Force
Set-ItemProperty "HKCR:\Directory\shell\CmdHereAdmin" -Name "HasLUAShield" -Value ""       -Force
Set-RegEntry "HKCR:\Directory\shell\CmdHereAdmin\command" `
    'powershell.exe -Command "Start-Process cmd.exe -ArgumentList ''/k cd /d \"%1\"'' -Verb RunAs"'

# PowerShell normal
Set-RegEntry "HKCR:\Directory\shell\PSHere" "Abrir PowerShell aqui"
Set-ItemProperty "HKCR:\Directory\shell\PSHere" -Name "Icon" -Value "powershell.exe" -Force
Set-RegEntry "HKCR:\Directory\shell\PSHere\command" `
    'powershell.exe -NoExit -Command "Set-Location -LiteralPath ''%1''"'

# PowerShell administrador
Set-RegEntry "HKCR:\Directory\shell\PSHereAdmin" "Abrir PowerShell aqui (Administrador)"
Set-ItemProperty "HKCR:\Directory\shell\PSHereAdmin" -Name "Icon"        -Value "powershell.exe" -Force
Set-ItemProperty "HKCR:\Directory\shell\PSHereAdmin" -Name "HasLUAShield" -Value ""              -Force
Set-RegEntry "HKCR:\Directory\shell\PSHereAdmin\command" `
    'powershell.exe -NoProfile -Command "Start-Process PowerShell -ArgumentList ''-NoExit -Command Set-Location -LiteralPath \"%1\"'' -Verb RunAs"'


# ==================================================
# FONDO DE CARPETA (clic derecho en espacio vacío)
# ==================================================

# CMD normal
Set-RegEntry "HKCR:\Directory\Background\shell\CmdHere" "Abrir CMD aqui"
Set-ItemProperty "HKCR:\Directory\Background\shell\CmdHere" -Name "Icon" -Value "cmd.exe" -Force
Set-RegEntry "HKCR:\Directory\Background\shell\CmdHere\command" 'cmd.exe /k cd /d "%V"'

# CMD administrador
Set-RegEntry "HKCR:\Directory\Background\shell\CmdHereAdmin" "Abrir CMD aqui (Administrador)"
Set-ItemProperty "HKCR:\Directory\Background\shell\CmdHereAdmin" -Name "Icon"        -Value "cmd.exe" -Force
Set-ItemProperty "HKCR:\Directory\Background\shell\CmdHereAdmin" -Name "HasLUAShield" -Value ""       -Force
Set-RegEntry "HKCR:\Directory\Background\shell\CmdHereAdmin\command" `
    'powershell.exe -Command "Start-Process cmd.exe -ArgumentList ''/k cd /d \"%V\"'' -Verb RunAs"'

# PowerShell normal
Set-RegEntry "HKCR:\Directory\Background\shell\PSHere" "Abrir PowerShell aqui"
Set-ItemProperty "HKCR:\Directory\Background\shell\PSHere" -Name "Icon" -Value "powershell.exe" -Force
Set-RegEntry "HKCR:\Directory\Background\shell\PSHere\command" `
    'powershell.exe -NoExit -Command "Set-Location -LiteralPath ''%V''"'

# PowerShell administrador
Set-RegEntry "HKCR:\Directory\Background\shell\PSHereAdmin" "Abrir PowerShell aqui (Administrador)"
Set-ItemProperty "HKCR:\Directory\Background\shell\PSHereAdmin" -Name "Icon"        -Value "powershell.exe" -Force
Set-ItemProperty "HKCR:\Directory\Background\shell\PSHereAdmin" -Name "HasLUAShield" -Value ""              -Force
Set-RegEntry "HKCR:\Directory\Background\shell\PSHereAdmin\command" `
    'powershell.exe -NoProfile -Command "Start-Process PowerShell -ArgumentList ''-NoExit -Command Set-Location -LiteralPath \"%V\"'' -Verb RunAs"'


# ==================================================
# ARCHIVOS .PS1 — ejecutar como administrador
# ==================================================

Set-RegEntry "HKCR:\Microsoft.PowerShellScript.1\Shell\RunAs" "Ejecutar en PowerShell como administrador"
Set-ItemProperty "HKCR:\Microsoft.PowerShellScript.1\Shell\RunAs" -Name "HasLUAShield" -Value "" -Force
Set-RegEntry "HKCR:\Microsoft.PowerShellScript.1\Shell\RunAs\Command" `
    'powershell.exe -NoExit -Command "Start-Process PowerShell -ArgumentList ''-ExecutionPolicy Bypass -File \"%1\"'' -Verb RunAs"'

Set-RegEntry "HKCR:\SystemFileAssociations\.ps1\shell\runas" "Ejecutar en PowerShell como administrador"
Set-ItemProperty "HKCR:\SystemFileAssociations\.ps1\shell\runas" -Name "HasLUAShield" -Value "" -Force
Set-RegEntry "HKCR:\SystemFileAssociations\.ps1\shell\runas\command" `
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList ''-NoExit -File \"%1\"'' -Verb RunAs"'


# ==================================================
# ARCHIVOS .CMD / .BAT — ejecutar como administrador
# ==================================================

Set-RegEntry "HKCR:\cmdfile\shell\runas" "Ejecutar como administrador"
Set-ItemProperty "HKCR:\cmdfile\shell\runas" -Name "HasLUAShield" -Value "" -Force
Set-RegEntry "HKCR:\cmdfile\shell\runas\command" 'cmd.exe /k "%1"'


Write-Host "Terminales integradas correctamente en el menu contextual."
