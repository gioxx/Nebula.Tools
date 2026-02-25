@{
    RootModule           = 'Nebula.Tools.psm1'
    ModuleVersion        = '1.0.5'
    GUID                 = 'd6f6c63d-e8db-4f0c-b7f6-4b0a95f7a63e'
    Author               = 'Giovanni Solone'
    Description          = 'Everyday functions and utilities for PowerShell.'

    # Minimum required PowerShell (PS 5.1 works; better with PS 7+)
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    RequiredAssemblies   = @()
    FunctionsToExport    = @(
        'Find-ADAccountExpirations',
        'Find-ModulesUpdates',
        'Join-ClipboardLines',
        'New-RandomPassword',
        'Remove-OldModuleVersions',
        'Update-CSVDelimiter',
        'Update-Modules',
        'Update-PS7'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @('Get-RandomPassword')

    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'Active-Directory',
                'AD',
                'CSV',
                'Nebula',
                'Password',
                'PowerShell',
                'Security',
                'Tools',
                'Utilities'
            )
            ProjectUri   = 'https://github.com/gioxx/Nebula.Tools'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            IconUri      = 'https://raw.githubusercontent.com/gioxx/Nebula.Tools/main/icon.png'
ReleaseNotes = @'
- Fix: Find-ADAccountExpirations ignores invalid/zero accountExpires values to avoid FileTime errors.
- Fix: Remove-OldModuleVersions handles PSResourceGet without -AllVersions.
- Improve: Added .LINK entries in comment-based help so Get-Help shows kb.gioxx.org documentation for exported commands.
- Improve: Find-ADAccountExpirations now supports -AsTable for formatted output (object-based default; Department/Company only with -ExportCsv).
- Improve: Find-ADAccountExpirations now supports -ExactDate for exact expiration matches and -IncludeDisabled to include disabled accounts.
- Improve: New-RandomPassword now warns when clipboard is unavailable and still returns output.
- Improve: Update-PS7 enforces TLS 1.2 on Windows PowerShell 5.1.
- New: Join-ClipboardLines to join clipboard lines into a PowerShell-ready string (copies to clipboard by default; use -NoClipboard to disable).
'@
        }
    }
}
