# Verify host system meets portable_python runtime requirements
# Asserts: nvidia-smi present, driver CUDA >= bundled CUDA, torch sees GPU
$ErrorActionPreference = 'Stop'

$Prefix = Join-Path $PSScriptRoot "portable_python"
$pyExe  = Join-Path $Prefix "python.exe"

function Write-Found  { param([string]$key, [string]$val) Write-Host ("-- {0,-20} {1}" -f $key, $val) }
function Write-Fatal  { param([string]$msg) Write-Host "-- FATAL: $msg" -ForegroundColor Red; throw $msg }

if (-not (Test-Path $pyExe)) { Write-Fatal "portable_python not found — run Install.ps1 first" }

# --- gather facts ---
$torchVer = & $pyExe -c "import torch; print(torch.__version__)" 2>&1
$cuVer    = & $pyExe -c "import torch; print(torch.version.cuda)" 2>&1
if (-not $cuVer -or $cuVer -match 'Error|None') { Write-Fatal "torch reports no CUDA build" }

$rows = & nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader 2>&1
if ($LASTEXITCODE -ne 0) { Write-Fatal "nvidia-smi failed: $rows" }

$smiHeader = (& nvidia-smi 2>&1) -join "`n"
if ($smiHeader -notmatch 'CUDA Version:\s*([\d.]+)') { Write-Fatal "could not parse driver CUDA version" }
$driverCuda = $Matches[1]

# --- report ---
Write-Host ""
Write-Found "Torch:" $torchVer
foreach ($row in $rows) {
    $name, $driver, $cc = ($row -split ',\s*')
    Write-Found "GPU:" "$name  compute $cc"
}
Write-Found "CUDA:" "$cuVer (driver $driverCuda)"

# --- assert ---
if ([version]$driverCuda -lt [version]$cuVer) {
    Write-Fatal "driver CUDA $driverCuda < bundled $cuVer — update NVIDIA driver"
}
$torchCuda = & $pyExe -c "import torch; assert torch.cuda.is_available(), 'torch cannot see GPU'" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Fatal "torch GPU check failed: $torchCuda" }

Write-Host "-- OK" -ForegroundColor Green
Write-Host ""
