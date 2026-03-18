#requires -Version 7.4

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')]
    [string]$Version,

    [ValidateNotNullOrEmpty()]
    [string]$Bucket = "mr-szgz/yolo_face",

    [AllowEmptyCollection()]
    [object[]]$StoredBinaries = @(),

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

Set-Location (Split-Path -Parent $PSScriptRoot)

$tag = "v$Version"
$currentBranch = (git branch --show-current).Trim()

if (-not $Force.IsPresent) {
    if (-not $PSCmdlet.ShouldContinue(
        "Proceed with GitHub tag/release creation for $tag on branch '$currentBranch'?",
        "Create GitHub release"
    )) {
        return
    }
}

if ($StoredBinaries.Count -eq 0) {
    $StoredBinaries = @(
        foreach ($zipFile in Get-ChildItem -Path dist -File -Filter "yolo_face-$Version-*.zip") {
            $match = [regex]::Match($zipFile.Name, '^yolo_face-(?<Version>.+)-(?<Platform>[^-]+)-(?<Arch>[^-]+)-(?<Abi>[^.]+)\.zip$')

            if (-not $match.Success -or $match.Groups["Version"].Value -ne $Version) {
                continue
            }

            $platform = $match.Groups["Platform"].Value
            $arch = $match.Groups["Arch"].Value
            $abi = $match.Groups["Abi"].Value
            $key = "$Version/$platform/$($zipFile.Name)"

            [pscustomobject]@{
                Version = $Version
                Platform = $platform
                Arch = $arch
                Abi = $abi
                Key = $key
                Size = $zipFile.Length
                PublicUrl = "https://huggingface.co/buckets/$Bucket/$key"
            }
        }
    )
}

$StoredBinaries = @(
    $StoredBinaries | Where-Object { $_.PSObject.Properties.Name -contains "PublicUrl" }
)

if ($StoredBinaries.Count -eq 0) {
    throw "No stored binaries were provided and no matching 'dist/yolo_face-$Version-*.zip' archives were found."
}

function Format-ByteSize {
    param (
        [Parameter(Mandatory)]
        [double]$Bytes
    )

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }

    if ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }

    if ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }

    return "{0:N0} B" -f $Bytes
}

$installSnippetPath = Join-Path $PSScriptRoot "Release-InstallSnippet.md"
$installSnippet = ""

if (Test-Path $installSnippetPath) {
    $installSnippet = ((Get-Content -Path $installSnippetPath -Raw).Trim()) -replace '<version>', $Version
}

$releaseNotes = @(
    "**Download from HuggingFace Bucket**"
    ""
    ($StoredBinaries | ForEach-Object {
        $sizeLabel = if ($_.PSObject.Properties.Name -contains "Size") {
            Format-ByteSize -Bytes $_.Size
        }
        else {
            "size unknown"
        }

        "- [$($_.Platform) $($_.Arch) $($_.Abi)]($($_.PublicUrl)) ($sizeLabel)"
    })
    ""
    $installSnippet
) -join "`n"

if ($PSCmdlet.ShouldProcess($tag, "Ensure git tag exists on origin")) {
    $localTagExists = $true
    try {
        git rev-parse -q --verify "refs/tags/$tag" | Out-Null
    }
    catch {
        $localTagExists = $false
    }

    if (-not $localTagExists) {
        git tag $tag
    }

    git push origin "refs/tags/$tag"
}

$releaseExists = $false
try {
    gh release view $tag | Out-Null
    $releaseExists = $true
}
catch {
    $releaseExists = $false
}

if ($releaseExists) {
    if ($PSCmdlet.ShouldProcess($tag, "Update GitHub release")) {
        gh release edit $tag `
            --title $tag `
            --notes $releaseNotes
    }
}
elseif ($PSCmdlet.ShouldProcess($tag, "Create GitHub release")) {
    gh release create $tag `
        --title $tag `
        --notes $releaseNotes
}

[pscustomobject]@{
    Version = $Version
    Tag = $tag
    Bucket = $Bucket
    StoredBinaries = $StoredBinaries
}
