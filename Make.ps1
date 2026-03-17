# isolate environment to portable python
$Prefix = Join-Path $PSScriptRoot "portable_python"
$env:PATH = "$Prefix;$env:PATH;"
$env:PYTHONNOUSERSITE = 1
$env:PYTHONPATH = ""

& (Join-Path $Prefix "python.exe") -m PyInstaller .\yolo_face.spec
