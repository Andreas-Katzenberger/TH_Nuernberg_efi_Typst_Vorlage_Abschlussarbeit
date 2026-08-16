# =====================================================================================
#  buildFinalPDF.ps1  --  Baut die Abschlussarbeit mit Typst unter Windows (PowerShell)
# -------------------------------------------------------------------------------------
#  Aufgaben:
#    1. Stellt sicher, dass Typst gefunden wird.
#    2. Kompiliert thesis.typ zuerst als Roh-PDF.
#    3. Fuegt optional die offizielle Erklaerungs-PDF per pdftk als echte
#       PDF-Seite(n) ein (Post-Processing).
#
#  Aufruf:   ./buildFinalPDF.ps1            (einmalig bauen)
# =====================================================================================

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

$script:pdftkCommand = $null
$script:pdftkJarPath = Join-Path $root 'tools\pdftk\pdftk-all.jar'
$script:usePdftkJar = $false
$script:declarationPlaceholderMarker = 'DECLARATION_PLACEHOLDER_RUN_BUILD_PS1'

function Invoke-PdfTk {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $output = $null
    if ($script:pdftkCommand) {
        $output = & $script:pdftkCommand.Source @Arguments
    } elseif ($script:usePdftkJar) {
        $output = & java -jar $script:pdftkJarPath @Arguments
    } else {
        throw 'pdftk is not available in PATH and no local pdftk-all.jar was found.'
    }

    if ($LASTEXITCODE -ne 0) {
        throw "pdftk invocation failed: $($Arguments -join ' ')"
    }

    return $output
}

function Get-PdfPageCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath
    )

    $dump = Invoke-PdfTk $PdfPath dump_data_utf8

    $line = $dump | Where-Object { $_ -match '^NumberOfPages:\s+\d+$' } | Select-Object -First 1
    if (-not $line) {
        throw "Could not determine page count for: $PdfPath"
    }

    return [int]($line -replace '^NumberOfPages:\s+', '')
}

function Get-PlaceholderPageNumber {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath,
        [Parameter(Mandatory = $true)]
        [string]$Marker
    )

    $pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
    if (-not $pdftotext) {
        return $null
    }

    $fullText = (& $pdftotext.Source $PdfPath - | Out-String)
    if ($LASTEXITCODE -ne 0 -or -not $fullText) {
        return $null
    }

    $pages = $fullText -split [char]12
    for ($i = 0; $i -lt $pages.Count; $i++) {
        if ($pages[$i] -match [regex]::Escape($Marker)) {
            return ($i + 1)
        }
    }

    return $null
}

# --- 1. Typst finden -------------------------------------------------------
$typst = Get-Command typst -ErrorAction SilentlyContinue
if (-not $typst) {
    $local = Join-Path $env:LOCALAPPDATA 'Programs\typst\typst.exe'
    if (Test-Path $local) { $env:Path = "$env:Path;$(Split-Path $local)" }
    else { throw 'Typst wurde nicht gefunden. Bitte Typst installieren (siehe README.md).' }
}

# --- 2. Declaration PDF post-processing configuration ----------------------
$declPdf = Join-Path $root 'doc\SB_0009_FO_Pruefungsrechtliche_Erklaerung_und_Erklaerung_zur_Veroeffentlichung_der_Abschlussarbeit_public.pdf'
$script:pdftkCommand = Get-Command pdftk -ErrorAction SilentlyContinue
$java = Get-Command java -ErrorAction SilentlyContinue
if (-not $script:pdftkCommand -and (Test-Path $script:pdftkJarPath) -and $java) {
    $script:usePdftkJar = $true
    Write-Host "Using local pdftk-java jar: $script:pdftkJarPath"
}

$hasPdftk = [bool]$script:pdftkCommand -or $script:usePdftkJar
$fallbackPlaceholderPage = 4
$declPdfExists = Test-Path $declPdf

if ($declPdfExists -and -not $hasPdftk) {
    Write-Warning "Declaration PDF found, but pdftk is missing. Install pdftk or place pdftk-all.jar at $script:pdftkJarPath. Build continues without PDF insertion."
}
if (-not $declPdfExists) {
    Write-Warning 'Declaration PDF not found in doc/. Build continues without PDF insertion.'
}

# --- 3. Compile ------------------------------------------------------------
$rawPdf = Join-Path $root 'thesis.raw.pdf'
$finalPdf = Join-Path $root 'thesis.pdf'

typst compile thesis.typ $rawPdf
if ($LASTEXITCODE -ne 0) {
    throw 'typst compile failed.'
}

if ($declPdfExists -and $hasPdftk) {
    $rawPages = Get-PdfPageCount -PdfPath $rawPdf
    $placeholderPage = Get-PlaceholderPageNumber -PdfPath $rawPdf -Marker $script:declarationPlaceholderMarker
    if (-not $placeholderPage) {
        $placeholderPage = $fallbackPlaceholderPage
        Write-Warning "Placeholder marker not found. Falling back to page $fallbackPlaceholderPage for declaration replacement."
    }

    if ($placeholderPage -lt 1 -or $placeholderPage -gt $rawPages) {
        throw "placeholderPage ($placeholderPage) is outside thesis page count ($rawPages)."
    }

    $catParts = @()
    $headEnd = $placeholderPage - 1
    if ($headEnd -ge 1) {
        $catParts += "A1-$headEnd"
    }

    $catParts += 'B1-end'

    $tailStart = $placeholderPage + 1
    if ($tailStart -le $rawPages) {
        $catParts += "A$tailStart-end"
    }

    Invoke-PdfTk "A=$rawPdf" "B=$declPdf" cat @catParts output $finalPdf | Out-Null

    Remove-Item -Path $rawPdf -Force
    Write-Host "Fertig: thesis.pdf mit eingefuegter Erklaerung (Platzhalter-Seite $placeholderPage ersetzt)."
} else {
    Move-Item -Path $rawPdf -Destination $finalPdf -Force
    Write-Host 'Fertig: thesis.pdf wurde ohne PDF-Einfuegung erzeugt.'
}