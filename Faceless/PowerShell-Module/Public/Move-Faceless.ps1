function Move-Faceless {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [string]$Directory = "noface"
    )

    $dest = Join-Path $Path $Directory
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $count = 0

    Get-ChildItem $Path -File | ForEach-Object {
        yolo_face --check-not $_.FullName
        if ($?) {
            $_ | Move-Item -Destination $dest -Force
            $count++
        }
    }

    [PSCustomObject]@{
        Path      = $Path
        Count     = $count
        Directory = $dest
    }
}
