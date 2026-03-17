@{
    RootModule        = 'YoloFace.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a3f7c8e1-5d2b-4a9f-b6c3-1e8d4f7a2b50'
    Author            = 'shoji'
    Description       = 'PowerShell tools for organizing media using YoloFace detection'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Find-YoloFace'
        'Sort-ImageByFace'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
}
