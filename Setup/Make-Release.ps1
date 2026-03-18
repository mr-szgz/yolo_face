#requires -Version 7.4

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')]
    [string]$Version,

    [ValidateNotNullOrEmpty()]
    [string]$Platform = "windows",

    [ValidateNotNullOrEmpty()]
    [string]$Arch = "amd64",

    [ValidateNotNullOrEmpty()]
    [string]$Abi = "cu128",

    [ValidateNotNullOrEmpty()]
    [string]$Bucket = "mr-szgz/yolo_face",

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not $Force.IsPresent) {
    if (-not $PSCmdlet.ShouldContinue(
        "Proceed with rebuild, fetch/rebase, push, Hugging Face upload to '$Bucket', and GitHub release creation for v$Version on branch '$((git branch --show-current).Trim())'?",
        "Publish v$Version"
    )) {
        return
    }
}

$storedBinaries = @()
$githubRelease = $null

if ($PSCmdlet.ShouldProcess("release", "Install Torch? (~ 3GB file size)")) {
    python -m pip install ".[cuda,dev]"
}

if ($PSCmdlet.ShouldProcess("release", "Publish release for $Version")) {
    & (Join-Path $PSScriptRoot "Make-Binary.ps1") -Version $Version -Platform $Platform -Arch $Arch -Abi $Abi

    git fetch origin main
    git rebase origin/main
    git push origin ((git branch --show-current).Trim())

    $storedBinaries = @(
        & (Join-Path $PSScriptRoot "Store-Binary.ps1") -Bucket $Bucket -Force -Confirm:$false |
            Where-Object { $_.PSObject.Properties.Name -contains "PublicUrl" }
    )
}

if ($storedBinaries.Count -gt 0 -and $PSCmdlet.ShouldProcess("release", "Create GitHub release for v$Version")) {
    $githubRelease = & (Join-Path $PSScriptRoot "Make-GitHubRelease.ps1") `
        -Version $Version `
        -Bucket $Bucket `
        -StoredBinaries $storedBinaries `
        -Force `
        -Confirm:$false
}

[pscustomobject]@{
    Version = $Version
    Tag = "v$Version"
    Bucket = $Bucket
    StoredBinaries = $storedBinaries
    GitHubRelease = $githubRelease
    Changelog = (Resolve-Path "CHANGELOG.md").Path
}
