# isolate environment to portable python
$Prefix = Join-Path $PSScriptRoot "portable_python"
$env:PATH = "$Prefix;$Prefix\Scripts;$env:PATH;"
$env:PYTHONNOUSERSITE = 1
$env:PYTHONPATH = ""

$DistDir = Join-Path $PSScriptRoot "dist\yolo_face"
if (Test-Path $DistDir) {
    Write-Host "Removing old dist directory: $DistDir"
    Remove-Item -Recurse -Force $DistDir
}

& (Join-Path $Prefix "python.exe") -m PyInstaller --noconfirm .\yolo_face.spec
