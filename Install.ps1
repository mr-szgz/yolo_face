# isolate environment to portable python
$Prefix = Join-Path $PSScriptRoot "\portable_python"
$env:PATH = "$Prefix;$env:PATH;"
$env:PYTHONNOUSERSITE=1;
$env:PYTHONPATH=""

# download portable python if missing
if (-not (Test-Path $Prefix)) {
    $Arch = switch ($[System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
        "X64" { "amd64" }
        "X86" { "win32" }
        "Arm64" { "arm64" }
        default { "amd64" }
    }

    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.14.3/python-3.14.3-embed-$Arch.zip" -OutFile "python-3.14.3-embed-$Arch.zip"
    Expand-Archive -Path "python-3.14.3-embed-$Arch.zip" -DestinationPath $Prefix
}

$pyExe = Join-Path $Prefix "python.exe"

# install pip if missing
if (-not (& $pyExe -m pip --version 2>&1)) {
    Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile get-pip.py
    & $pyExe get-pip.py
    & $pyExe -m pip install pip --upgrade
}

# install torch cuda 12.8+
& $pyExe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 --upgrade --no-warn-script-location

# installs ultralytics
& $pyExe -m pip install ultralytics --upgrade --no-warn-script-location
