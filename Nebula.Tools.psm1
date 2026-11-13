# Nebula.Tools.psm1
$script:ModuleRoot = $PSScriptRoot

function Update-PS7 {
    <#
    .SYNOPSIS
        Updates PowerShell 7 using the official installer script.
    .DESCRIPTION
        Invokes the Microsoft install script with -UseMSI. With -UseMSI the script installs
        the release named by ReleaseTag in PowerShell's tools/metadata.json (the latest LTS
        7.6.x, since PowerShell 7.7+ ships no MSI packages), so Update-PS7 reads the same
        metadata to decide whether an update is needed. Skips the install entirely, with a
        warning, when the running version already matches that release, and points out when
        a newer non-MSI stable release exists.
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

    # Same metadata install-powershell.ps1 reads: with -UseMSI it installs ReleaseTag (LTS),
    # not StableReleaseTag, because 7.7+ has no MSI. Comparing against GitHub "latest"
    # made every run reinstall the same LTS build.
    $latestVersion = $null
    try {
        $metadata = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json' -ErrorAction Stop
        $latestVersion = [version]($metadata.ReleaseTag -replace '^v' -replace '-.*$')
        $stableVersion = [version]($metadata.StableReleaseTag -replace '^v' -replace '-.*$')
        if ($stableVersion -gt $latestVersion -and $currentVersion -lt $stableVersion) {
            Write-Warning "PowerShell $stableVersion is available but has no MSI package; Update-PS7 tracks the latest MSI release ($latestVersion). Install $stableVersion manually (zip/winget/Store) if you need it."
        }
    } catch {
        Write-Warning "Unable to read PowerShell release metadata, falling back to the Microsoft installer's own version resolution. $($_.Exception.Message)"
    }

    if ($latestVersion -and -not $Force.IsPresent -and $currentVersion -ge $latestVersion) {
        Write-Warning "PowerShell is already up to date (installed: $currentVersion, latest MSI release: $latestVersion). Skipping install. Use -Force to reinstall anyway."
        return
    }

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
