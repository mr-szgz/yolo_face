# YoloFaceTools.psm1 — Organize media using yolo_face detection

$script:ModelDir  = $PSScriptRoot
$script:YoloFace  = 'S:\Spaces\ML-Tools\yolo_face\dist\yolo_face\yolo_face.exe'

function Find-YoloFace {
    <#
    .SYNOPSIS
        Run yolo_face on a single file and return detected labels.
    .OUTPUTS
        [string[]] Array of label strings (empty if no faces detected).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$FilePath,

        [ValidateRange(0.0, 1.0)]
        [double]$Confidence
    )

    $yoloArgs = @()
    if ($PSBoundParameters.ContainsKey('Confidence')) {
        $yoloArgs += '--conf', $Confidence
    }
    $yoloArgs += (Resolve-Path $FilePath).Path

    Push-Location $script:ModelDir
    try {
        $output = & $script:YoloFace @yoloArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "yolo_face exited with code $LASTEXITCODE for $FilePath"
        }
        if ($output) {
            return @($output | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ })
        }
        return @()
    }
    finally {
        Pop-Location
    }
}

function Sort-ImageByFace {
    <#
    .SYNOPSIS
        Scan a folder of images, detect faces with yolo_face, and move each
        image into a faces/ or no_faces/ sibling subdirectory.
    .EXAMPLE
        Sort-ImageByFace C:\Photos
    .EXAMPLE
        Sort-ImageByFace C:\Photos -Confidence 0.6 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [string]$FacesDir   = 'faces',
        [string]$NoFacesDir = 'no_faces',

        [ValidateRange(0.0, 1.0)]
        [double]$Confidence,

        [string[]]$Extensions = @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif', '.tiff')
    )

    $resolvedPath = (Resolve-Path $Path).Path
    $facesPath    = Join-Path $resolvedPath $FacesDir
    $noFacesPath  = Join-Path $resolvedPath $NoFacesDir

    $images = Get-ChildItem -Path $resolvedPath -File |
        Where-Object { $_.Extension.ToLower() -in $Extensions }

    if ($images.Count -eq 0) {
        Write-Warning "No images found in $resolvedPath"
        return
    }

    Write-Host "Found $($images.Count) image(s) to process in $resolvedPath"

    $faceCount   = 0
    $noFaceCount = 0
    $i           = 0

    foreach ($image in $images) {
        $i++
        Write-Progress -Activity 'Scanning faces' -Status $image.Name `
            -PercentComplete (($i / $images.Count) * 100)

        $invokeParams = @{ FilePath = $image.FullName }
        if ($PSBoundParameters.ContainsKey('Confidence')) {
            $invokeParams['Confidence'] = $Confidence
        }

        $labels = Find-YoloFace @invokeParams

        if ($labels.Count -gt 0) {
            $destDir = $facesPath
            $faceCount++
            Write-Verbose "$($image.Name): $($labels -join ', ')"
        }
        else {
            $destDir = $noFacesPath
            $noFaceCount++
            Write-Verbose "$($image.Name): no faces detected"
        }

        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }

        $dest = Join-Path $destDir $image.Name
        if (Test-Path $dest) {
            Write-Warning "Skipping $($image.Name) — already exists in $([System.IO.Path]::GetFileName($destDir))/"
            continue
        }

        if ($PSCmdlet.ShouldProcess($image.Name, "Move to $([System.IO.Path]::GetFileName($destDir))/")) {
            Move-Item -Path $image.FullName -Destination $dest
        }
    }

    Write-Progress -Activity 'Scanning faces' -Completed

    [PSCustomObject]@{
        TotalImages = $images.Count
        Faces       = $faceCount
        NoFaces     = $noFaceCount
    }
}
