[CmdletBinding()]
param()
$VerbosePreference = 'Continue'
$InformationPreference = 'Continue'

# Check if CUDA 12 is installed
if ($env:CUDA_PATH) {
    Write-Verbose "CUDA Path: $env:CUDA_PATH"
} else {
    $cudaBasePath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
    if (Test-Path $cudaBasePath) {
        $v12Dirs = Get-ChildItem -Path $cudaBasePath -Directory -Name -Filter "v12*" | Sort-Object -Descending | Select-Object -First 1
        if ($v12Dirs) {
            $cudaPath = Join-Path $cudaBasePath $v12Dirs
            Write-Verbose "CUDA Path: $cudaPath"
        } else {
            Write-Warning "CUDA 12 is not installed"
        }
    } else {
        Write-Warning "CUDA 12 is not installed"
    }
}

# Check CUDA using nvidia-smi
try {
    $nvidiaInfo = & nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader 2>$null
    if ($nvidiaInfo) {
        Write-Verbose $nvidiaInfo
    } else {
        Write-Warning "NVIDIA GPU not found"
    }
} catch {
    Write-Error "nvidia-smi command failed. Ensure NVIDIA drivers are installed and accessible in PATH."
}

# Check torch version and CUDA availability
$pythonPath = Join-Path (Get-Location) "portable_python\python.exe"
if (Test-Path $pythonPath) {
    try {
        $torchInfo = & $pythonPath -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())" 2>$null
        Write-Verbose $torchInfo
    } catch {
        Write-Error "Failed to check PyTorch. Ensure torch is installed in portable_python."
    }
} else {
    Write-Error "portable_python/python.exe not found at: $pythonPath"
}
