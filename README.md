# Nebula.Tools

**Nebula.Tools** provides functions and utilities for PowerShell.

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Nebula.Tools?label=PowerShell%20Gallery)
![Downloads](https://img.shields.io/powershellgallery/dt/Nebula.Tools?color=blue)

> [!NOTE]  
> If you are looking for automations that connect to Microsoft Graph or send e-mail, check out **Nebula.Automations** (https://github.com/gioxx/Nebula.Automations).

---

## Highlights in v1.0.3

- Adds `Update-PS7`, which invokes the official Microsoft installer to bring PowerShell 7 up to date.
- Migrates the ToyBox maintenance helpers (`Find-ModulesUpdates`, `Update-Modules`, `Remove-OldModuleVersions`) into this module.
- Renames `Get-RandomPassword` to `New-RandomPassword` (alias retained) and adds the `-Clipboard` switch.
- Refactors the module layout for PowerShell 5.1+ compatibility and easier long-term maintenance.

---

## Included Functions

| Function | Category | Description |
| --- | --- | --- |
| `New-RandomPassword` | Security | Generate complex or simplified passwords, optionally in bulk, and copy them to the clipboard (`Get-RandomPassword` remains as an alias). |
| `Update-CSVDelimiter` | Files | Switch CSV delimiters between comma and semicolon with a configurable encoding (defaults to `ISO-8859-15`). |
| `Find-ModulesUpdates` | Module maintenance | List installed modules that have a newer version available via PSResourceGet or PowerShellGet, filtered by scope and provider. |
| `Update-Modules` | Module maintenance | Update installed modules using PSResourceGet or PowerShellGet with preview support, scope awareness, and optional cleanup of older copies. |
| `Remove-OldModuleVersions` | Module maintenance | Remove stale module versions by keeping the most recent *N* releases (works with PSResourceGet, PowerShellGet, and unmanaged folders). |
| `Update-PS7` | Platform | Run the official PowerShell 7 MSI update script from Microsoft (`aka.ms/install-powershell`). |

---

## Installation

Nebula.Tools targets Windows PowerShell 5.1 and PowerShell 7+. Install (or update) it from the PowerShell Gallery:

```powershell
Install-Module -Name Nebula.Tools -Scope CurrentUser
# Update-Module -Name Nebula.Tools
```

Using PSResourceGet? You can also run:

```powershell
Install-PSResource -Name Nebula.Tools -Scope CurrentUser
```

---

## Usage

### Generate secure passwords

```powershell
New-RandomPassword -PasswordLength 12
New-RandomPassword -Simple -Count 3 -Clipboard   # Copies to the Windows clipboard
```

### Rewrite CSV delimiters

```powershell
# Convert semicolons to commas (default encoding ISO-8859-15)
Update-CSVDelimiter -FilePath 'C:\path\to\file.csv' -ToComma

# Convert commas to semicolons with explicit encoding
Update-CSVDelimiter -FilePath 'C:\path\to\file.csv' -Encoding 'UTF8' -ToSemicolon
```

### Inspect module updates

```powershell
Find-ModulesUpdates -Scope User -Provider Auto |
    Sort-Object Name |
    Format-Table Name, InstalledVersion, LatestVersion, Scope
```

- `Scope` supports `User`, `System`, `All`, or `Unknown` so you can target only the locations you care about.
- `Provider` defaults to `Auto` (try PSResourceGet v3 first, fallback to PowerShellGet v2).
- Use `-IncludePrerelease` when you want preview builds.

### Update modules safely

```powershell
# Dry run (nothing is installed)
Update-Modules -Scope User -Provider Auto -IncludePrerelease -Preview

# Apply updates and remove older copies afterwards
Update-Modules -Scope User -CleanupOld
```

- System-scope updates require an elevated PowerShell session; non-admin runs automatically skip them with a warning.
- `CleanupOld` removes superseded versions via the same provider (PSResourceGet or PowerShellGet).
- All update actions respect `ShouldProcess`, so `-WhatIf` works end-to-end.

### Remove stale module versions

```powershell
# Keep the latest release and clean everything else (supports -WhatIf/-Confirm)
Remove-OldModuleVersions -Name 'PSAppDeployToolkit' -Keep 1 -WhatIf
```

The function inspects PSResourceGet, PowerShellGet, and orphaned folders, preferring provider-aware uninstall commands before falling back to deleting directories.

### Update to the latest PowerShell 7 via MSI

```powershell
Update-PS7
```

This downloads and runs the official `aka.ms/install-powershell.ps1` helper with the `-UseMSI` switch, so expect the standard MSI UI. Run from an elevated session when upgrading system-wide.

---

## License

All scripts in this repository are licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## Development

Nebula.Tools is part of the broader [Nebula](https://github.com/gioxx?tab=repositories&q=Nebula) PowerShell family. Feel free to fork the repository, file issues, or send pull requests.

---

## Feedback and Contributions

Issues, feature requests, and contributions are always welcome. Open an issue at https://github.com/gioxx/Nebula.Tools/issues or start a discussion with a pull request.