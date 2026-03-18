#requires -Version 7.4

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param (
    [ValidateNotNullOrEmpty()]
    [string]$BaseBranch = "main",

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

Set-Location (Split-Path -Parent $PSScriptRoot)

$currentBranch = (git branch --show-current).Trim()

if (-not $Force.IsPresent) {
    if (-not $PSCmdlet.ShouldContinue(
        "Proceed with fetch/rebase against '$BaseBranch' and push branch '$currentBranch'?",
        "Sync release branch"
    )) {
        return
    }
}

if ($PSCmdlet.ShouldProcess($currentBranch, "Fetch, rebase, and push")) {
    git fetch origin $BaseBranch
    git rebase "origin/$BaseBranch"
    git push origin $currentBranch
}

[pscustomobject]@{
    Branch = $currentBranch
    BaseBranch = $BaseBranch
}
