# Configura el equipo en modo Personal.
# Ejecutar como Administrador.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\00_ejecutar_todo.ps1" -Modo Personal
