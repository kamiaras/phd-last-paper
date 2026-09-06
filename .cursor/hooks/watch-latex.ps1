param([switch]$Background)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$miktex = Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64"
if (Test-Path -LiteralPath $miktex) {
    $env:Path = "$miktex;$env:Path"
}
$env:MIKTEX_DISABLEWELCOME = "1"

# The task and Cursor hooks may start together. A mutex prevents duplicate
# compilers and is released by Windows even if a watcher is terminated.
$hasher = [Security.Cryptography.SHA256]::Create()
try {
    $rootHash = [BitConverter]::ToString($hasher.ComputeHash(
        [Text.Encoding]::UTF8.GetBytes($Root.ToUpperInvariant()))).Replace("-", "")
}
finally { $hasher.Dispose() }
$mutex = [Threading.Mutex]::new($false, "Local\LaTeXWatch-$rootHash")
$ownsMutex = $false
$transcribing = $false
$pidFile = Join-Path $Root ".latexmk-watch.pid"

function Clear-CorruptAux {
    foreach ($name in @("fresh_rewrite.aux", "fresh_rewrite.out")) {
        $path = Join-Path $Root $name
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        if ($bytes -contains 0) {
            Write-Host "Removing corrupt $name"
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Latex {
    Clear-CorruptAux
    & latexmk -pdf -interaction=nonstopmode -synctex=1 -file-line-error fresh_rewrite.tex
    if ($LASTEXITCODE -ne 0) {
        Write-Host "LaTeX build failed (exit $LASTEXITCODE). Waiting for the next saved change."
    }
}

function Get-InputState {
    # Poll both inputs so atomic saves and changes during a build are not lost.
    $states = foreach ($name in @("fresh_rewrite.tex", "ref.bib")) {
        $item = Get-Item -LiteralPath (Join-Path $Root $name) -ErrorAction SilentlyContinue
        if ($item) { "$name|$($item.LastWriteTimeUtc.Ticks)|$($item.Length)" }
        else { "$name|missing" }
    }
    return ($states -join ";")
}

try {
    try { $ownsMutex = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) {
        if ($Background) { Write-Output "{}" }
        else { Write-Host "LaTeX watcher already running." }
        exit 0
    }

    if ($Background) {
        # The child acquires the mutex itself; it does not depend on the hook's
        # lifetime or on which editor tab currently has focus.
        $mutex.ReleaseMutex()
        $ownsMutex = $false
        $powershell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        Start-Process -FilePath $powershell -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ('"' + $PSCommandPath + '"')
        ) -WorkingDirectory $Root -WindowStyle Hidden
        Write-Output "{}"
        exit 0
    }

    Set-Content -LiteralPath $pidFile -Value $PID -Encoding ascii
    Start-Transcript -LiteralPath (Join-Path $Root ".latexmk-watch.log") -Append | Out-Null
    $transcribing = $true
    $state = Get-InputState
    Invoke-Latex
    Write-Host "=== Watching for updated files. Use Ctrl+C to stop ==="

    while ($true) {
        Start-Sleep -Milliseconds 1000
        if ((Get-InputState) -eq $state) { continue }
        do {
            $current = Get-InputState
            Start-Sleep -Milliseconds 2500
            $settled = Get-InputState
        } while ($current -ne $settled)
        $state = $settled
        Write-Host "Latexmk: input changed - rebuilding fresh_rewrite.pdf"
        Invoke-Latex
        Write-Host "=== Watching for updated files. Use Ctrl+C to stop ==="
    }
}
finally {
    if ($transcribing) { Stop-Transcript | Out-Null }
    if ($ownsMutex) {
        $currentPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
        if ($currentPid -eq [string]$PID) {
            Remove-Item -LiteralPath $pidFile -ErrorAction SilentlyContinue
        }
        $mutex.ReleaseMutex()
    }
    $mutex.Dispose()
}
