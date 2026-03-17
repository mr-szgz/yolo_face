# isolate environment to portable python
$Prefix = Join-Path $PSScriptRoot "\portable_python"
$env:PATH = "$Prefix;$Prefix\Scripts;$env:PATH;"
$env:PYTHONNOUSERSITE=1;
$env:PYTHONPATH=""
$env:PIP_NO_WARN_SCRIPT_LOCATION=1

# download portable python if missing
if (-not (Test-Path $Prefix)) {
    $Arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
        "X64" { "amd64" }
        "X86" { "win32" }
        "Arm64" { "arm64" }
        default { "amd64" }
    }
 
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.13.12/python-3.13.12-embed-$Arch.zip" -OutFile "python-3.13.12-embed-$Arch.zip"
    Expand-Archive -Path "python-3.13.12-embed-$Arch.zip" -DestinationPath $Prefix
}

# configure embedded python: enable site, add project root to sys.path
Copy-Item (Join-Path $PSScriptRoot "python313._pth") (Join-Path $Prefix "python313._pth")
Copy-Item (Join-Path $PSScriptRoot "yolo_face.pth") (Join-Path $Prefix "Lib\site-packages\yolo_face.pth")

$pyExe = Join-Path $Prefix "python.exe"

# bootstrap pip (embedded Python ships without it)
& $pyExe -m pip --version 2>$null
if ($LASTEXITCODE -ne 0) {
    $getPip = Join-Path $PSScriptRoot "get-pip.py"
    & $pyExe $getPip
}
# install #1 is for sys packges
& $pyExe -m pip install pip --upgrade

# install #2 is torch for cuda
& $pyExe -m pip install ".[cuda,dev]"

# install #3 is app depdencies
& $pyExe -m pip install . --upgrade
