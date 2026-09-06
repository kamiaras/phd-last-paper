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
$buildDirectory = Join-Path $Root ".latexmk-build"
$publishedPdf = Join-Path $Root "fresh_rewrite.pdf"

function Write-WatcherLog([string]$Message) {
    Write-Host "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] $Message"
}

function Clear-CorruptAux {
    foreach ($name in @("fresh_rewrite.aux", "fresh_rewrite.out")) {
        $path = Join-Path $buildDirectory $name
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        if ($bytes -contains 0) {
            Write-WatcherLog "Removing corrupt build file $name"
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Publish-Artifact([string]$Name) {
    $source = Join-Path $buildDirectory $Name
    $destination = Join-Path $Root $Name
    $temporary = Join-Path $Root ".latexmk-publish-$PID-$Name.tmp"
    try {
        [IO.File]::Copy($source, $temporary, $true)
        if ([IO.File]::Exists($destination)) {
            # Replace an existing file without a delete/recreate gap. The PDF
            # viewer must keep its file watch even when compilation fails.
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

function Invoke-Latex {
    $process = $null
    try {
        New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
        Clear-CorruptAux
        $latexmk = Join-Path $miktex "latexmk.exe"
        if (-not (Test-Path -LiteralPath $latexmk)) {
            $latexmk = (Get-Command latexmk -CommandType Application -ErrorAction Stop).Source
        }
        $stdoutLog = Join-Path $buildDirectory "latexmk.stdout.log"
        $stderrLog = Join-Path $buildDirectory "latexmk.stderr.log"
        $sourcePath = Join-Path $Root "fresh_rewrite.tex"
        Write-WatcherLog "Building fresh_rewrite.tex in .latexmk-build."
        $process = Start-Process -FilePath $latexmk -ArgumentList @(
            "-pdf", "-interaction=nonstopmode", "-synctex=1", "-file-line-error",
            ('-outdir="' + $buildDirectory + '"'), ('"' + $sourcePath + '"')
        ) -WorkingDirectory $Root -WindowStyle Hidden -Wait -PassThru `
            -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $exitCode = $process.ExitCode
        # Native output is captured independently of the launching terminal.
        # Echo it through PowerShell so the transcript retains every build.
        foreach ($logPath in @($stdoutLog, $stderrLog)) {
            Get-Content -LiteralPath $logPath -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Host $_ }
        }
        if ($exitCode -ne 0) {
            Write-WatcherLog "LaTeX build failed (exit $exitCode). Keeping the published PDF; waiting for the next saved change."
            return "buildFailed"
        }
        $builtPdf = Join-Path $buildDirectory "fresh_rewrite.pdf"
        if (-not (Test-Path -LiteralPath $builtPdf)) {
            Write-WatcherLog "LaTeX produced no PDF. Keeping the published PDF."
            return "buildFailed"
        }
        try {
            # Publish the matching SyncTeX data before notifying the PDF viewer.
            if (Test-Path -LiteralPath (Join-Path $buildDirectory "fresh_rewrite.synctex.gz")) {
                Publish-Artifact "fresh_rewrite.synctex.gz"
            }
            Publish-Artifact "fresh_rewrite.pdf"
        }
        catch {
            Write-WatcherLog "Could not publish the build: $($_.Exception.Message). Retrying in 30 seconds or after the next saved change."
            return "publishFailed"
        }
        Write-WatcherLog "Published fresh_rewrite.pdf successfully."
        return "success"
    }
    catch {
        Write-WatcherLog "LaTeX build could not finish: $($_.Exception.Message). Keeping the published PDF."
        return "buildFailed"
    }
    finally {
        if ($process) { $process.Dispose() }
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
        else { Write-WatcherLog "LaTeX watcher already running." }
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
    Write-WatcherLog "LaTeX watcher started (pid $PID)."
    $state = Get-InputState
    $buildResult = Invoke-Latex
    $retryAt = if ($buildResult -eq "success") { [DateTime]::UtcNow } else { [DateTime]::UtcNow.AddSeconds(30) }
    Write-WatcherLog "=== Watching for updated files. Use Ctrl+C to stop ==="

    while ($true) {
        Start-Sleep -Milliseconds 1000
        $inputChanged = (Get-InputState) -ne $state
        $needsRetry = ($buildResult -eq "publishFailed") -or
            (-not (Test-Path -LiteralPath $publishedPdf))
        if (-not $inputChanged -and
            (-not $needsRetry -or [DateTime]::UtcNow -lt $retryAt)) { continue }
        if ($inputChanged) {
            do {
                $current = Get-InputState
                Start-Sleep -Milliseconds 2500
                $settled = Get-InputState
            } while ($current -ne $settled)
            # Record the state before building so edits during a build trigger
            # another pass. Both manuscript and bibliography are included.
            $state = $settled
            Write-WatcherLog "Input changed - rebuilding fresh_rewrite.pdf."
        }
        else {
            Write-WatcherLog "Retrying publication or restoring a missing PDF."
        }
        $buildResult = Invoke-Latex
        $retryAt = if ($buildResult -eq "success") { [DateTime]::UtcNow } else { [DateTime]::UtcNow.AddSeconds(30) }
        Write-WatcherLog "=== Watching for updated files. Use Ctrl+C to stop ==="
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
