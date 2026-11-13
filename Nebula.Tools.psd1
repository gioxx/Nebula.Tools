@{
    RootModule           = 'Nebula.Tools.psm1'
    ModuleVersion        = '1.0.8'
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
- Fix: Update-PS7 no longer reinstalls the same version on every run. It now compares against the release install-powershell.ps1 actually installs with -UseMSI (ReleaseTag in PowerShell's metadata.json, the latest LTS 7.6.x), instead of the GitHub "latest" release (7.7+), which ships no MSI.
- Update-PS7 warns when a newer stable release exists without an MSI package.
'@
        }
    }
}
