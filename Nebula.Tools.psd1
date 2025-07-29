@{
    RootModule        = 'Nebula.Tools.psm1'
    ModuleVersion     = '1.0.2'
    GUID              = 'd6f6c63d-e8db-4f0c-b7f6-4b0a95f7a63e'
    Author            = 'Giovanni Solone'
    Description       = 'Functions and utilities for PowerShell.'

    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-RandomPassword',
        'Update-CSVDelimiter'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{
        PSData = @{
            Tags         = @('Tools', 'PowerShell', 'Nebula', 'Utilities')
            License      = 'MIT'
            ProjectUri   = 'https://github.com/gioxx/Nebula.Tools'
            Icon         = 'icon.png'
            Readme       = 'README.md'
            ReleaseNotes = @'
- WARNING: If you are looking for the old Nebula.Tools commands and functions, look for Nebula.Automations in PowerShell Gallery.
- Nebula.Tools now offers utility functions via PowerShell.
'@
        }
    }
}
