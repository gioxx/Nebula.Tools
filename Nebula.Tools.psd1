@{
    RootModule        = 'Nebula.Tools.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = 'd6f6c63d-e8db-4f0c-b7f6-4b0a95f7a63e'
    Author            = 'Giovanni Solone'
    Description       = 'Common utilities for PowerShell scripting: mail, Graph connectivity, and more.'

    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Send-Mail',
        'CheckMGGraphConnection'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{
        PSData = @{
            Tags         = @('Tools', 'PowerShell', 'Graph', 'Mail', 'Nebula', 'Utilities')
            License      = 'MIT'
            ProjectUri   = 'https://github.com/gioxx/Nebula.Tools'
            Icon         = 'icon.png'
            Readme       = 'README.md'
            ReleaseNotes = @'
Initial release of Nebula.Tools:
- Send-Mail: fixed $config variable in the example and description of the Send-Mail function (typos, I don't use a config file).
- Set mandatory parameters for the Send-Mail function.
'@
        }
    }
}
