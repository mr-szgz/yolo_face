Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
Set-Location (Split-Path -Parent $PSScriptRoot)
$env:PATH = "$(Join-Path (Get-Location) 'portable_python');$(Join-Path (Get-Location) 'portable_python\Scripts');$env:PATH;"

if (-not (Test-Path "portable_python\python.exe")) {
    throw "portable_python not found. Run Install.ps1 first."
}

$pyVer = (& python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')" 2>$null).Trim()
$cuVer = (& python -c "import torch; print((torch.version.cuda or 'cpu').replace('.', ''))" 2>$null).Trim()
$arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
    "X64" { "amd64" }
    "X86" { "win32" }
    "Arm64" { "arm64" }
    default { "amd64" }
}

$platform = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'windows' } else { 'linux' }
$archive = "portable_python-$pyVer-$platform-$arch-cu$cuVer.7z"

if (Test-Path $archive) {
    Remove-Item -Force $archive
}

& 7z a -t7z -mx=9 $archive portable_python

[pscustomobject]@{
    Archive = (Join-Path (Get-Location) $archive)
    PythonVersion = $pyVer
    Platform = $platform
    Arch = $arch
    Cuda = $cuVer
}
