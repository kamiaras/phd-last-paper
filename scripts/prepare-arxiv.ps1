param()

$ErrorActionPreference = 'Stop'
$arxivRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$arxivBuild = Join-Path $arxivRoot '.latexmk-build'
$arxivOutput = Join-Path $arxivRoot 'output'
$arxivMiktex = Join-Path $env:LOCALAPPDATA 'Programs\MiKTeX\miktex\bin\x64'
if (Test-Path -LiteralPath $arxivMiktex) {
    $env:Path = $arxivMiktex + [IO.Path]::PathSeparator + $env:Path
}
$env:MIKTEX_DISABLEWELCOME = '1'

$arxivLatexmk = (Get-Command latexmk -CommandType Application -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $arxivBuild -Force | Out-Null
New-Item -ItemType Directory -Path $arxivOutput -Force | Out-Null

Push-Location $arxivRoot
try {
    # Force a fresh bibliography and PDF; never package a stale root .bbl.
    & $arxivLatexmk -gg -pdf -interaction=nonstopmode -halt-on-error -file-line-error '-outdir=.latexmk-build' fresh_rewrite.tex
    if ($LASTEXITCODE -ne 0) { throw 'The manuscript build failed.' }

    $arxivLog = Get-Content -LiteralPath (Join-Path $arxivBuild 'fresh_rewrite.log') -Raw
    if ($arxivLog -match '(?im)^!|undefined references|undefined citations|Citation .+ undefined|Reference .+ undefined|Label\(s\) may have changed|multiply defined') {
        throw 'The final build has unresolved errors, citations, or cross-references.'
    }

    Copy-Item -LiteralPath (Join-Path $arxivBuild 'fresh_rewrite.pdf') -Destination (Join-Path $arxivRoot 'fresh_rewrite.pdf') -Force
    $arxivZipPath = Join-Path $arxivOutput 'arxiv-source.zip'
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $arxivZipStream = [IO.File]::Open($arxivZipPath, [IO.FileMode]::Create)
    $arxivZip = $null
    try {
        $arxivZip = [IO.Compression.ZipArchive]::new($arxivZipStream, [IO.Compression.ZipArchiveMode]::Create)
        foreach ($arxivFile in @('fresh_rewrite.tex', 'ref.bib', '.latexmk-build/fresh_rewrite.bbl')) {
            $arxivSource = Join-Path $arxivRoot $arxivFile
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arxivZip, $arxivSource, [IO.Path]::GetFileName($arxivFile)) | Out-Null
        }
    }
    finally {
        if ($null -ne $arxivZip) { $arxivZip.Dispose() }
        $arxivZipStream.Dispose()
    }

    # Compile the extracted archive alone to check that no local files are needed.
    $arxivVerify = Join-Path $arxivBuild ('arxiv-verify-' + [Guid]::NewGuid().ToString('N'))
    [IO.Compression.ZipFile]::ExtractToDirectory($arxivZipPath, $arxivVerify)
    Push-Location $arxivVerify
    try {
        $arxivPdflatex = (Get-Command pdflatex -CommandType Application -ErrorAction Stop).Source
        for ($arxivPass = 1; $arxivPass -le 3; $arxivPass++) {
            & $arxivPdflatex -no-shell-escape -interaction=nonstopmode -halt-on-error -file-line-error fresh_rewrite.tex > ('compile-' + $arxivPass + '.txt')
            if ($LASTEXITCODE -ne 0) { throw 'The extracted arXiv ZIP did not compile.' }
        }
        $arxivVerifyLog = Get-Content -LiteralPath 'fresh_rewrite.log' -Raw
        if ($arxivVerifyLog -match '(?im)^!|undefined references|undefined citations|Citation .+ undefined|Reference .+ undefined|Label\(s\) may have changed|multiply defined') {
            throw 'The extracted arXiv ZIP has unresolved errors, citations, or cross-references.'
        }
    }
    finally {
        Pop-Location
    }
    Write-Output 'Verified: the extracted source ZIP compiles independently.'
    Write-Output ('PDF: ' + (Join-Path $arxivRoot 'fresh_rewrite.pdf'))
    Write-Output ('arXiv source ZIP: ' + $arxivZipPath)
}
finally {
    Pop-Location
}
