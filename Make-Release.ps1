[CmdletBinding()]
param (
    # TODO: make $Version required
    [string]$Version,
    [string]$Platform = "windows",
    [string]$Arch = "amd64",
    [string]$Abi = "cu128"
)

# TODO: update the version in pyproject.toml in the simplest best practice most common way

.\Make-Binary.ps1 -Version $Version -Platform $Platform -Arch $Arch -Abi $Abi
.\portable_python\python.exe -m pip install ".[cuda,dev]"
# TODO: use gh command to create new release including tag (eg. v0.2.1) for $Version (eg. 0.2.1) including CHANGELOG.md
# TODO: git fetch && git rebase origin/main and then git push
