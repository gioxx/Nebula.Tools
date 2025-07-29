# Nebula.Tools

**Nebula.Tools** provides functions and utilities for PowerShell.

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Nebula.Tools?label=PowerShell%20Gallery)
![Downloads](https://img.shields.io/powershellgallery/dt/Nebula.Tools?color=blue)

> [!NOTE]  
> I want this module to remain specifically designed and developed to be an integral part of other scripts and automations that have little to do instead with everyday use tools. Nebula.Tools will return in another form, with different functions related to everyday use via PowerShell.  
> I apologize if this is confusing, I realize I could have thought of this long before!  
> The old GUID was invalidated and I removed the old versions from the GitHub releases. It's starting from scratch. I recommend you do the same with any installations on your machine!

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

## 🔧 Development

This module is part of the [Nebula](https://github.com/gioxx?tab=repositories&q=Nebula) PowerShell tools family.

Feel free to fork, improve and submit pull requests.

---

## 📄 License

Licensed under the [MIT License](https://opensource.org/licenses/MIT).
