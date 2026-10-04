# Run from PowerShell: .\build.ps1
# Intermediate files stay in .latexmk-build; the last good PDF stays in place.
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$buildDirectory = Join-Path $Root ".latexmk-build"

# Share the watcher's lock to prevent concurrent builds and publications.
$hasher = [Security.Cryptography.SHA256]::Create()
try {
    $rootHash = [BitConverter]::ToString($hasher.ComputeHash(
        [Text.Encoding]::UTF8.GetBytes($Root.ToUpperInvariant()))).Replace("-", "")
}
finally { $hasher.Dispose() }
$mutex = [Threading.Mutex]::new($false, "Local\LaTeXWatch-$rootHash")
$ownsMutex = $false
$locationPushed = $false
$savedEnvironment = @{}

function Publish-Artifact([string]$Name) {
    $source = Join-Path $buildDirectory $Name
    $destination = Join-Path $Root $Name
    $temporary = Join-Path $Root ".latexmk-publish-$PID-$Name.tmp"
    try {
        [IO.File]::Copy($source, $temporary, $true)
        if ([IO.File]::Exists($destination)) {
            [IO.File]::Replace($temporary, $destination,
                [System.Management.Automation.Language.NullString]::Value, $true)
        }
        else {
            [IO.File]::Move($temporary, $destination)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    try { $ownsMutex = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) {
        throw "A LaTeX watcher or build is already running. Stop it before running build.ps1."
    }

    foreach ($name in @("Path", "MIKTEX_DISABLEWELCOME", "LC_ALL", "LC_CTYPE", "LANG")) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
    }
    $miktex = Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64"
    if (Test-Path -LiteralPath $miktex) {
        $env:Path = "$miktex;$env:Path"
    }
    $env:MIKTEX_DISABLEWELCOME = "1"
    # Perl on Windows does not support the C.UTF-8 locale inherited by some shells.
    $env:LC_ALL = "C"
    $env:LC_CTYPE = "C"
    $env:LANG = "C"
    $latexmk = (Get-Command latexmk -CommandType Application -ErrorAction Stop).Source

    Push-Location -LiteralPath $Root
    $locationPushed = $true
    New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
    & $latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error `
        -synctex=1 "-outdir=$buildDirectory" "fresh_rewrite.tex"
    if ($LASTEXITCODE -ne 0) {
        throw "LaTeX build failed (exit $LASTEXITCODE). The published PDF was kept."
    }
    foreach ($name in @("fresh_rewrite.pdf", "fresh_rewrite.synctex.gz")) {
        if (-not (Test-Path -LiteralPath (Join-Path $buildDirectory $name) -PathType Leaf)) {
            throw "LaTeX did not produce $name. The published PDF was kept."
        }
    }

    # Publish matching SyncTeX data before the PDF viewer sees the updated PDF.
    Publish-Artifact "fresh_rewrite.synctex.gz"
    Publish-Artifact "fresh_rewrite.pdf"
    Write-Host "Built and published fresh_rewrite.pdf."
}
finally {
    if ($locationPushed) { Pop-Location }
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], "Process")
    }
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
