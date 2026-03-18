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

    [switch]$InstallDependencies,

    [switch]$BuildBinary,

    [switch]$SyncBranch,

    [switch]$StoreBinary,

    [switch]$GitHubRelease,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

Set-Location (Split-Path -Parent $PSScriptRoot)

$runAllStages = -not (
    $InstallDependencies.IsPresent -or
    $BuildBinary.IsPresent -or
    $SyncBranch.IsPresent -or
    $StoreBinary.IsPresent -or
    $GitHubRelease.IsPresent
)

$runInstallDependencies = $runAllStages -or $InstallDependencies.IsPresent
$runBuildBinary = $runAllStages -or $BuildBinary.IsPresent
$runSyncBranch = $runAllStages -or $SyncBranch.IsPresent
$runStoreBinary = $runAllStages -or $StoreBinary.IsPresent
$runGitHubRelease = $runAllStages -or $GitHubRelease.IsPresent

$selectedStages = @()
if ($runInstallDependencies) { $selectedStages += "install dependencies" }
if ($runBuildBinary) { $selectedStages += "build binary" }
if ($runSyncBranch) { $selectedStages += "sync branch" }
if ($runStoreBinary) { $selectedStages += "store binaries" }
if ($runGitHubRelease) { $selectedStages += "create or update GitHub release" }

if (-not $Force.IsPresent) {
    if (-not $PSCmdlet.ShouldContinue(
        "Proceed with $($selectedStages -join ', ') for v$Version on branch '$((git branch --show-current).Trim())'?",
        "Publish v$Version"
    )) {
        return
    }
}

$storedBinaries = @()
$githubRelease = $null

if ($runInstallDependencies -and $PSCmdlet.ShouldProcess("release", "Install Torch? (~ 3GB file size)")) {
    python -m pip install ".[cuda,dev]"
}

if ($runBuildBinary -and $PSCmdlet.ShouldProcess("release", "Build binary for $Version")) {
    & (Join-Path $PSScriptRoot "Make-Binary.ps1") -Version $Version -Platform $Platform -Arch $Arch -Abi $Abi
}

if ($runSyncBranch -and $PSCmdlet.ShouldProcess("release", "Sync branch before release")) {
    & (Join-Path $PSScriptRoot "Sync-ReleaseBranch.ps1") -Force -Confirm:$false | Out-Null
}

if ($runStoreBinary -and $PSCmdlet.ShouldProcess("release", "Upload release archives to Hugging Face bucket")) {
    $storedBinaries = @(
        & (Join-Path $PSScriptRoot "Store-Binary.ps1") `
            -Bucket $Bucket `
            -Version $Version `
            -Platform $Platform `
            -Arch $Arch `
            -Abi $Abi `
            -Force `
            -Confirm:$false |
            Where-Object { $_.PSObject.Properties.Name -contains "PublicUrl" }
    )
}

if ($runGitHubRelease -and $PSCmdlet.ShouldProcess("release", "Create or update GitHub release for v$Version")) {
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
