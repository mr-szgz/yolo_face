[CmdletBinding()]
param (
    [string]$Version,
    [string]$Platform = "windows",
    [string]$Arch = "amd64",
    [string]$Abi = "cu128"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
Set-Location (Split-Path -Parent $PSScriptRoot)

# isolate environment to portable python
$env:PATH = "$(Join-Path (Get-Location) 'portable_python');$(Join-Path (Get-Location) 'portable_python\Scripts');$env:PATH;"
$env:PYTHONNOUSERSITE = 1
$env:PYTHONPATH = ""

if (Test-Path "dist\yolo_face") {
    Remove-Item -Recurse -Force "dist\yolo_face"
}

& python -m pip install pyinstaller
& python -m PyInstaller --noconfirm (Join-Path $PSScriptRoot "yolo_face.spec")

if ($Version) {
    if (Test-Path "dist\yolo_face-$Version-$Platform-$Arch-$Abi.zip") {
        Remove-Item -Force "dist\yolo_face-$Version-$Platform-$Arch-$Abi.zip"
    }
    Compress-Archive -Path "dist\yolo_face" -DestinationPath "dist\yolo_face-$Version-$Platform-$Arch-$Abi.zip"
}
