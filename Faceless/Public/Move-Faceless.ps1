function Move-Faceless {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [string]$Directory = "faceless"
    )

    $dest = Join-Path $Path $Directory
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Get-ChildItem $Path -File | ForEach-Object {
        $Filename = $_.Name
        Write-Progress -Activity "Scanning" -Status $Filename
        yolo_face --check-not $_.FullName
        if ($?) {
            Write-Progress -Activity "Moving ($Directory)" -Status $Filename
            $_ | Move-Item -Destination $dest -Force
        }
    }

    Write-Progress -Activity "Scan" -Completed
    [PSCustomObject]@{
        Path      = $Path
        Count     = $Count
        Directory = $dest
    }
}
