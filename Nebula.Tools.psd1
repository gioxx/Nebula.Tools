@{
    RootModule           = 'Nebula.Tools.psm1'
    ModuleVersion        = '1.0.3'
    GUID                 = 'd6f6c63d-e8db-4f0c-b7f6-4b0a95f7a63e'
    Author               = 'Giovanni Solone'
    Description          = 'Everyday functions and utilities for PowerShell.'

    # Minimum required PowerShell (PS 5.1 works; better with PS 7+)
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    RequiredAssemblies   = @()
    FunctionsToExport    = @(
        'Find-ModulesUpdates',
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
            Tags         = @('Tools', 'PowerShell', 'Nebula', 'Utilities')
            ProjectUri   = 'https://github.com/gioxx/Nebula.Tools'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            IconUri      = 'https://raw.githubusercontent.com/gioxx/Nebula.Tools/main/icon.png'
            ReleaseNotes = @'
- Added: migrated PowerShell 7 MSI update function from ToyBox.
- Added: migrated all modules maintenance functions from ToyBox.
- Changed: Function name from Get-RandomPassword to New-RandomPassword for consistency with PowerShell naming conventions. Maintained backward compatibility via alias.
- Improved: Now compatible with PowerShell 5.1 and later.
- Improved: Refactored module structure for better maintainability.
- Improved: Added -Clipboard parameter to Get-RandomPassword function.
'@
        }
    }
}