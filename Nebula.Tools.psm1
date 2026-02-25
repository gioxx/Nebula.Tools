# Nebula.Tools.psm1
$script:ModuleRoot = $PSScriptRoot

function Update-PS7 {
    <#
    .SYNOPSIS
        Updates PowerShell 7 using the official installer script.
    .DESCRIPTION
        Downloads and executes the Microsoft install script to update PowerShell 7 with MSI.
        On Windows PowerShell 5.1 it enforces TLS 1.2 before download.
    .EXAMPLE
        Update-PS7
    .LINK
        https://kb.gioxx.org/Nebula/Tools/usage/utilities#update-ps7
    #>
    # Ensure TLS 1.2 for Windows PowerShell 5.1 environments
    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    } catch {}

    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
}

# --- Load Private helpers first (NOT exported) ---
# $privateDir = Join-Path $PSScriptRoot 'Private'
# if (Test-Path $privateDir) {
#     Get-ChildItem -Path $privateDir -Filter '*.ps1' -File | ForEach-Object {
#         try {
#             . $_.FullName  # dot-source
#         } catch {
#             throw "Failed to load Private script '$($_.Name)': $($_.Exception.Message)"
#         }
#     }
# }

# --- Load Public entry points (will be exported) ---
$publicDir = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter '*.ps1' -File | ForEach-Object {
        try {
            . $_.FullName  # dot-source
        } catch {
            throw "Failed to load Public script '$($_.Name)': $($_.Exception.Message)"
        }
    }
}

# --- Aliases & Exports -------------------------------------------------------
$existing = Get-Alias -Name 'Get-RandomPassword' -ErrorAction SilentlyContinue
if (-not $existing -or $existing.ResolvedCommandName -ne 'New-RandomPassword') {
    Set-Alias -Name Get-RandomPassword -Value New-RandomPassword -Force
}
