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

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
$InformationPreference = "Continue"

$pyProjectPath = Join-Path $PSScriptRoot "pyproject.toml"
$pythonExe = Join-Path $PSScriptRoot "portable_python\python.exe"
$makeBinaryPath = Join-Path $PSScriptRoot "Make-Binary.ps1"
$changelogPath = (Resolve-Path (Join-Path $PSScriptRoot "CHANGELOG.md")).Path
$assetPath = Join-Path $PSScriptRoot "dist\yolo_face-$Version-$Platform-$Arch-$Abi.zip"
$tag = "v$Version"
$branch = (git branch --show-current).Trim()
$headSha = $null

$activity = "Make release $tag"
$step = 0
$steps = 6

function Write-ReleaseStage {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:step++
    $percentComplete = [int](($script:step / $script:steps) * 100)
    Write-Progress -Activity $script:activity -Status $Status -PercentComplete $percentComplete
    Write-Information $Message
}

Set-Location $PSScriptRoot

Write-Verbose "Branch: $branch"
Write-Verbose "Version: $Version"
Write-Verbose "Tag: $tag"
Write-Verbose "Asset: $assetPath"
Write-Verbose "Changelog: $changelogPath"

if (-not $Force.IsPresent) {
    $caption = "Publish $tag"
    $question = "Proceed with version update, rebuild, fetch/rebase, push, and GitHub release creation for $tag on branch '$branch'?"
    if (-not $PSCmdlet.ShouldContinue($question, $caption)) {
        return
    }
}

$pyProject = Get-Content -Raw $pyProjectPath
$currentVersion = ([regex]::Match($pyProject, '(?m)^version\s*=\s*"([^"]+)"\s*$')).Groups[1].Value
$updatedPyProject = [regex]::Replace($pyProject, '(?m)^version\s*=\s*"[^"]+"\s*$', "version = `"$Version`"", 1)

if ($currentVersion -ne $Version -and $PSCmdlet.ShouldProcess($pyProjectPath, "Set package version to $Version")) {
    Write-ReleaseStage -Status "Updating version" -Message "Updating pyproject.toml from $currentVersion to $Version."
    Set-Content -Path $pyProjectPath -Value $updatedPyProject -NoNewline
} else {
    Write-Verbose "pyproject.toml already reports version $Version."
}

if ($PSCmdlet.ShouldProcess($pythonExe, "Install release environment for $tag")) {
    Write-ReleaseStage -Status "Installing" -Message "Installing package and build dependencies into portable_python."
    & $pythonExe -m pip install ".[cuda,dev]"
}

if ($PSCmdlet.ShouldProcess($makeBinaryPath, "Build $assetPath")) {
    Write-ReleaseStage -Status "Building" -Message "Building release asset $assetPath."
    & $makeBinaryPath -Version $Version -Platform $Platform -Arch $Arch -Abi $Abi
}

if ($currentVersion -ne $Version -and $PSCmdlet.ShouldProcess("git index", "Commit release version $tag")) {
    Write-ReleaseStage -Status "Committing" -Message "Committing pyproject.toml for $tag."
    git add pyproject.toml
    git commit -m "chore: release $tag"
}

if ($PSCmdlet.ShouldProcess($branch, "Fetch origin/main, rebase, and push")) {
    Write-ReleaseStage -Status "Syncing git" -Message "Fetching origin/main, rebasing $branch, and pushing to origin."
    git fetch origin main
    git rebase origin/main
    git push origin $branch
}

$headSha = (git rev-parse HEAD).Trim()
$assetItem = Get-Item $assetPath

if ($PSCmdlet.ShouldProcess($tag, "Create GitHub release from $($assetItem.Name)")) {
    Write-ReleaseStage -Status "Publishing" -Message "Creating GitHub release $tag from commit $headSha."
    gh release create $tag $assetItem.FullName --title $tag --target $headSha --notes-file $changelogPath
}

Write-Progress -Activity $activity -Completed

[pscustomobject]@{
    Version = $Version
    Tag = $tag
    Branch = $branch
    Commit = $headSha
    Asset = $assetItem.FullName
    Changelog = $changelogPath
}
