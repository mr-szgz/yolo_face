#requires -Version 7.4

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param (
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
        "Proceed with uploading $(@(Get-ChildItem -Path dist -File -Filter 'yolo_face-*.zip').Count) release archive(s) from 'dist' to Hugging Face bucket '$Bucket'?",
        "Upload release archives"
    )) {
        return
    }
}

foreach ($zipFile in Get-ChildItem -Path dist -File -Filter "yolo_face-*.zip") {
    $match = [regex]::Match($zipFile.Name, '^yolo_face-(?<Version>.+)-(?<Platform>[^-]+)-(?<Arch>[^-]+)-(?<Abi>[^.]+)\.zip$')

    $version = $match.Groups["Version"].Value
    $platform = $match.Groups["Platform"].Value
    $arch = $match.Groups["Arch"].Value
    $abi = $match.Groups["Abi"].Value
    $key = "$version/$platform/$($zipFile.Name)"
    $bucketUri = "hf://buckets/$Bucket/$key"

    if ($PSCmdlet.ShouldProcess($bucketUri, "hf buckets cp $($zipFile.FullName)")) {
        hf buckets cp $zipFile.FullName $bucketUri
    }

    [pscustomobject]@{
        Version = $version
        Platform = $platform
        Arch = $arch
        Abi = $abi
        Key = $key
        Size = $zipFile.Length
        BucketUri = $bucketUri
        PublicUrl = "https://huggingface.co/buckets/$Bucket/$key"
    }
}
