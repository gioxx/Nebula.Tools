@{
    RootModule           = 'Nebula.Tools.psm1'
    ModuleVersion        = '1.0.7'
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
- Fix: Update-PS7 no longer passes -Version to install-powershell.ps1, since Microsoft removed that parameter from the upstream script; the installer always fetches the latest stable release.
'@
        }
    }
}
