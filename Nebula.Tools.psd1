@{
    RootModule           = 'Nebula.Tools.psm1'
    ModuleVersion        = '1.0.3'
    GUID                 = 'd6f6c63d-e8db-4f0c-b7f6-4b0a95f7a63e'
    Author               = 'Giovanni Solone'
    Description          = 'Functions and utilities for PowerShell.'

    # Minimum required PowerShell (PS 5.1 works; better with PS 7+)
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    RequiredAssemblies   = @()
    FunctionsToExport    = @(
        'Get-RandomPassword',
        'Update-CSVDelimiter'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags         = @('Tools', 'PowerShell', 'Nebula', 'Utilities')
            ProjectUri   = 'https://github.com/gioxx/Nebula.Tools'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            IconUri      = 'https://raw.githubusercontent.com/gioxx/Nebula.Tools/main/icon.png'
            ReleaseNotes = @'
- Improved: Now compatible with PowerShell 5.1 and later.
- Improved: Refactored module structure for better maintainability.
- Improved: Added -Clipboard parameter to Get-RandomPassword function.
'@
        }
    }
}