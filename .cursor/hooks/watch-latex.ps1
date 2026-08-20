$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$miktex = Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64"
if (Test-Path $miktex) {
    $env:Path = "$miktex;$env:Path"
}

$pidFile = Join-Path $Root ".latexmk-watch.pid"
if (Test-Path $pidFile) {
    $old = 0
    [void][int]::TryParse(((Get-Content $pidFile -Raw).Trim()), [ref]$old)
    if ($old -gt 0) {
        $alive = Get-Process -Id $old -ErrorAction SilentlyContinue
        if ($alive) {
            Write-Host "LaTeX watcher already running (pid $old)"
            exit 0
        }
    }
}
Set-Content -Path $pidFile -Value $PID -Encoding ascii

function Clear-CorruptAux {
    foreach ($name in @("fresh_rewrite.aux", "fresh_rewrite.out")) {
        $path = Join-Path $Root $name
        if (-not (Test-Path $path)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        if ($bytes -contains 0) {
            Write-Host "Removing corrupt $name"
            Remove-Item $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Latex {
    Clear-CorruptAux
    & latexmk -pdf -interaction=nonstopmode -synctex=1 -file-line-error fresh_rewrite.tex
}

try {
    Invoke-Latex
    Write-Host "=== Watching for updated files. Use Ctrl+C to stop ==="

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Root
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $false
    $watcher.NotifyFilter = [IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::Size -bor [IO.NotifyFilters]::FileName
    $watcher.EnableRaisingEvents = $true

    $watched = @("fresh_rewrite.tex", "ref.bib")
    while ($true) {
        $evt = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed -bor [System.IO.WatcherChangeTypes]::Renamed, 2000)
        if ($evt.TimedOut) { continue }
        if ($watched -notcontains $evt.Name) { continue }
        Start-Sleep -Milliseconds 2500
        Write-Host "Latexmk: changed $($evt.Name) - rebuilding fresh_rewrite.pdf"
        do {
            $stamp = (Get-Item "fresh_rewrite.tex").LastWriteTimeUtc
            Invoke-Latex
        } while ((Get-Item "fresh_rewrite.tex").LastWriteTimeUtc -gt $stamp)
        Write-Host "=== Watching for updated files. Use Ctrl+C to stop ==="
    }
}
finally {
    $current = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($current -eq [string]$PID) {
        Remove-Item $pidFile -ErrorAction SilentlyContinue
    }
}
