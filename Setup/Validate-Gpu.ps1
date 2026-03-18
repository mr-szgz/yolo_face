Set-Location (Split-Path -Parent $PSScriptRoot)
$env:PATH = "$(Join-Path (Get-Location) 'portable_python');$(Join-Path (Get-Location) 'portable_python\Scripts');$env:PATH;"

$torchVer = (& python -c "import torch; print(torch.__version__)" | Out-String).Trim()
$cuVer = (& python -c "import torch; print(torch.version.cuda)" | Out-String).Trim()

$rows = @(& nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader)

@(& nvidia-smi) -join "`n" | % { if ($_ -match 'CUDA Version:\s*([\d.]+)') { $driverCuda = $Matches[1] } }

& python -c "import torch; torch.cuda.is_available()"

[pscustomobject]@{
    Torch = $torchVer
    Cuda = $cuVer
    DriverCuda = $driverCuda
    Gpus = @(
        foreach ($row in $rows) {
            $name, $driver, $cc = ($row -split ',\s*')
            [pscustomobject]@{
                Name = $name
                Driver = $driver
                ComputeCapability = $cc
            }
        }
    )
}
