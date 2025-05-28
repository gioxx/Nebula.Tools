# Nebula.Tools

**Nebula.Tools** provides reusable PowerShell functions for scripting, automation and cloud integration.

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Nebula.Tools?label=PowerShell%20Gallery)
![Downloads](https://img.shields.io/powershellgallery/dt/Nebula.Tools?color=blue)

---

## ✨ Included Functions

- `Send-Mail`  
  Send emails via SMTP with support for:
  - Attachments
  - CC / BCC
  - Custom SMTP server and port

- `CheckMGGraphConnection`  
  Connect to Microsoft Graph using application credentials:
  - Automatically handles module install
  - Authenticates with client ID/secret
  - Logs connection status

---

## 📦 Installation

Install from PowerShell Gallery:

```powershell
Install-Module -Name Nebula.Tools -Scope CurrentUser
```

---

## 🚀 Usage

Example to send an email:

```powershell
Send-Mail -SMTPServer "smtp.example.com" -From "me@example.com" -To "you@example.com" -Subject "Hello" -Body "Test message"
```

Example to connect to Microsoft Graph:

```powershell
$Graph = CheckMGGraphConnection -tenantId "<tenant>" -clientId "<client>" -clientSecret "<secret>"
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
