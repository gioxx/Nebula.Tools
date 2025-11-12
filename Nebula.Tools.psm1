# Nebula.Tools.psm1
$script:ModuleRoot = $PSScriptRoot

function Update-PS7 {
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