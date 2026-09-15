# Nebula.Tools.psm1
$script:ModuleRoot = $PSScriptRoot

function Update-PS7 {
    <#
    .SYNOPSIS
        Updates PowerShell 7 using the official installer script.
    .DESCRIPTION
        Resolves the latest PowerShell release from the GitHub Releases API (the aka.ms
        install-powershell.ps1 buildinfo endpoint can lag behind actual GitHub releases) to
        decide whether an update is needed, then invokes the Microsoft install script with
        -UseMSI (which always installs the latest stable release; it has no -Version switch).
        Skips the install entirely, with a warning, when the running version already matches
        the latest.
        On Windows PowerShell 5.1 it enforces TLS 1.2 before download.
    .PARAMETER Force
        Runs the installer even if the installed version already matches the latest release.
    .EXAMPLE
        Update-PS7
    .LINK
        https://kb.gioxx.org/Nebula/Tools/usage/utilities#update-ps7
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    # Ensure TLS 1.2 for Windows PowerShell 5.1 environments
    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    } catch {}

    $currentVersion = $PSVersionTable.PSVersion

    $latestVersion = $null
    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -Headers @{ 'User-Agent' = 'Nebula.Tools' } -ErrorAction Stop
        $latestVersion = [version]($release.tag_name -replace '^v', '')
    } catch {
        Write-Warning "Unable to query GitHub for the latest PowerShell release, falling back to the Microsoft installer's own version resolution. $($_.Exception.Message)"
    }

    if ($latestVersion -and -not $Force.IsPresent -and $currentVersion -ge $latestVersion) {
        Write-Warning "PowerShell is already up to date (installed: $currentVersion, latest: $latestVersion). Skipping install. Use -Force to reinstall anyway."
        return
    }

    # install-powershell.ps1 no longer accepts -Version; it always installs the
    # latest stable release unless -Preview/-Daily is passed.
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
