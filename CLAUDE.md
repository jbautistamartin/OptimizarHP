# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project purpose

Collection of PowerShell scripts to automate the setup of a fresh Windows 11 installation. Scripts are built incrementally as the user adds new steps.

## Running scripts

All scripts require an elevated PowerShell session (Run as Administrator):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\00_ejecutar_todo.ps1        # Run all steps in order
.\04_explorador_archivos.ps1  # Run a single step
```

## Architecture

### Entry point: `00_ejecutar_todo.ps1`

Defines global options and calls each numbered script in sequence. When adding a new script, register it in the `$pasos` array in this file.

**Global variables** (set here, read by individual scripts):

| Variable | Default | Effect |
|---|---|---|
| `$global:ReiniciarExplorer` | `$false` | Controls whether scripts restart `explorer.exe` after applying changes |

### Numbered scripts (`01_` … `NN_`)

Each script is self-contained and can run standalone or via the main script. They check for admin rights independently.

Current steps:
- `01` — Restores Windows 10 classic right-click context menu (registry `HKCU`)
- `02` — Adds CMD/PowerShell terminal entries to Explorer context menu (registry `HKCR`, requires admin)
- `03` — Configures Edge via Group Policy registry keys (`HKLM\SOFTWARE\Policies\Microsoft\Edge`): homepage, new tab, and default search engine set to Google
- `04` — Shows hidden files, file extensions, and system-protected files in Explorer (registry `HKCU`)

## Conventions

- **Encoding**: All `.ps1` files must be saved as **UTF-8 with BOM**. After creating or editing a file with a tool that doesn't guarantee BOM, re-encode with:
  ```powershell
  $content = Get-Content .\script.ps1 -Raw -Encoding UTF8
  [System.IO.File]::WriteAllText((Resolve-Path .\script.ps1), $content, (New-Object System.Text.UTF8Encoding $true))
  ```
- **No accented characters in registry values** — only in PowerShell strings/comments, where UTF-8 BOM handles them correctly.
- **Naming**: `NN_descripcion_corta.ps1` where `NN` is a zero-padded sequence number.
- **Admin check**: Every script that touches `HKLM` or `HKCR` must include the elevation guard at the top.
