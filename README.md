# Nebula.Tools

**Nebula.Tools** provides functions and utilities for PowerShell.

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Nebula.Tools?label=PowerShell%20Gallery)
![Downloads](https://img.shields.io/powershellgallery/dt/Nebula.Tools?color=blue)

> [!NOTE]  
> If you're looking for automations for linking to Microsoft Graph or sending e-mail, I suggest you take a look at **Nebula.Automations** (https://github.com/gioxx/Nebula.Automations).

---

## ✨ Included Functions

| Function Name            | Description |
|------------------------|------------------------------------------------------------------|
| `Get-RandomPassword`  | Generates a random password with specified length and complexity. |
| `Update-CSVDelimiter`  | Update the delimiter of a CSV file between comma and semicolon. |

More functions will be added over time.

---

## 📦 Installation

Install from PowerShell Gallery:

```powershell
Install-Module -Name Nebula.Tools -Scope CurrentUser
```

---

## 🚀 Usage

Example to generate passwords:

```powershell
Get-RandomPassword -PasswordLength 12
Get-RandomPassword -PasswordLength 12 -Simple
Get-RandomPassword -PasswordLength 12 -Count 5
Get-RandomPassword -PasswordLength 12 -Simple -Count 3
```

Example to change delimiter in a CSV file:

```powershell
Update-CSVDelimiter -FilePath "C:\path\to\file.csv" -ToComma
```

---

## 🧽 How to clean up old module versions (optional)

When updating from previous versions, old files (such as unused `.psm1`, `.yml`, or `LICENSE` files) are not automatically deleted.  
If you want a completely clean setup, you can remove all previous versions manually:

```powershell
# Remove all installed versions of the module
Uninstall-Module -Name Nebula.Tools -AllVersions -Force

# Reinstall the latest clean version
Install-Module -Name Nebula.Tools -Scope CurrentUser -Force
```

ℹ️ This is entirely optional — PowerShell always uses the most recent version installed.

---

## 📄 License

All scripts in this repository are licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 🔧 Development

This module is part of the [Nebula](https://github.com/gioxx?tab=repositories&q=Nebula) PowerShell tools family.

Feel free to fork, improve and submit pull requests.

---

## 📬 Feedback and Contributions

Feedback, suggestions, and pull requests are welcome!  
Feel free to [open an issue](https://github.com/gioxx/Nebula.Tools/issues) or contribute directly.
