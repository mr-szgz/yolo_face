[CmdletBinding()]
param (
    [switch]$Gpu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$env:PATH = "$(Join-Path $PSScriptRoot 'portable_python');$(Join-Path $PSScriptRoot 'portable_python\Scripts');$env:PATH;"
$env:PYTHONNOUSERSITE = 1
$env:PYTHONPATH = ""
$env:PIP_NO_WARN_SCRIPT_LOCATION = 1

if (-not (Test-Path (Join-Path $PSScriptRoot "portable_python\python.exe"))) {
    $Arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
        "X64" { "amd64" }
        "X86" { "win32" }
        "Arm64" { "arm64" }
        default { "amd64" }
    }

    if (-not (Test-Path (Join-Path $PSScriptRoot "python-3.13.12-embed-$Arch.zip"))) {
        Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.13.12/python-3.13.12-embed-$Arch.zip" -OutFile (Join-Path $PSScriptRoot "python-3.13.12-embed-$Arch.zip")
    }

    New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot "portable_python") -Force | Out-Null
    Expand-Archive -Path (Join-Path $PSScriptRoot "python-3.13.12-embed-$Arch.zip") -DestinationPath (Join-Path $PSScriptRoot "portable_python") -Force
}

New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot "portable_python\Scripts") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot "portable_python\Lib\site-packages") -Force | Out-Null
Copy-Item (Join-Path $PSScriptRoot "Setup\python313._pth") (Join-Path $PSScriptRoot "portable_python\python313._pth") -Force
Copy-Item (Join-Path $PSScriptRoot "Setup\yolo_face.pth") (Join-Path $PSScriptRoot "portable_python\Lib\site-packages\yolo_face.pth") -Force

$hasPip = $false

try {
    & python -m pip --version 2>$null | Out-Null
    $hasPip = ($LASTEXITCODE -eq 0)
}
catch {
    $hasPip = $false
}

if (-not $hasPip) {
    & python -m ensurepip --upgrade
}

& python -m pip install --upgrade pip "setuptools>=70" wheel

if ($Gpu) {
    & python -m pip uninstall torch torchvision torchaudio --yes
    & python -m pip install torch torchvision torchaudio --upgrade --index-url=https://download.pytorch.org/whl/cu128
}

& python -m pip install --upgrade .
