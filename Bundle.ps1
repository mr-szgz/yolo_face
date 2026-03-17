# Bundle portable_python into a versioned 7z archive
# Output: portable_python-{pyver}-{os}-{arch}-cu{cuda}.7z

$Prefix = Join-Path $PSScriptRoot "portable_python"
$pyExe  = Join-Path $Prefix "python.exe"

if (-not (Test-Path $pyExe)) {
    Write-Error "portable_python not found — run Install.ps1 first"
    exit 1
}

# detect python version
$pyVer = & $pyExe -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')" 2>$null

# detect torch CUDA variant
$cuVer = & $pyExe -c "import torch; v=torch.version.cuda or 'cpu'; print(v.replace('.',''))" 2>$null

# detect platform
$os = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'windows' } else { 'linux' }
$arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
    "X64"   { "amd64" }
    "X86"   { "win32" }
    "Arm64" { "arm64" }
    default { "amd64" }
}

$name = "portable_python-$pyVer-$os-$arch-cu$cuVer.7z"
Write-Host "Creating $name ..."

# Run 7z with -bsp1 to get progress on stdout; parse for Write-Progress + ETA
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$exitCode = 0
$proc = Start-Process 7z -ArgumentList "a -t7z -mx=9 -bsp1 $name portable_python" `
    -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\7z_out.log"
$reader = $null
try {
    # wait briefly for the file to be created
    Start-Sleep -Milliseconds 200
    $stream = [System.IO.FileStream]::new("$env:TEMP\7z_out.log",
        [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite)
    $reader = [System.IO.StreamReader]::new($stream)
    while (-not $proc.HasExited) {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line -match '(\d+)%') {
                $pct = [int]$Matches[1]
                $elapsed = $sw.Elapsed.TotalSeconds
                $secRemain = if ($pct -gt 0) {
                    [int](($elapsed / $pct) * (100 - $pct))
                } else { -1 }
                Write-Progress -Activity "Compressing $name" `
                    -Status "$pct% complete" `
                    -PercentComplete $pct `
                    -SecondsRemaining $secRemain
            }
        }
        Start-Sleep -Milliseconds 250
    }
    # drain remaining output
    while ($null -ne ($line = $reader.ReadLine())) {
        if ($line -match '(\d+)%') {
            Write-Progress -Activity "Compressing $name" -Status "100%" -PercentComplete 100 -SecondsRemaining 0
        }
    }
    $exitCode = $proc.ExitCode
} finally {
    if ($reader) { $reader.Close() }
    Write-Progress -Activity "Compressing $name" -Completed
    Remove-Item "$env:TEMP\7z_out.log" -ErrorAction SilentlyContinue
}

if ($exitCode -eq 0) {
    $elapsed = $sw.Elapsed
    $size = (Get-Item $name).Length / 1MB
    Write-Host "$name ($([math]::Round($size, 1)) MB) in $("{0:mm\:ss}" -f $elapsed)"
} else {
    Write-Error "7z failed with exit code $exitCode"
    exit $exitCode
}
