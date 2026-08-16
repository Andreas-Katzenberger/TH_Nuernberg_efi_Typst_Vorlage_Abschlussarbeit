#!/usr/bin/env bash

# =====================================================================================
#  buildFinalPDF.sh  --  Baut die Abschlussarbeit mit Typst unter Linux (bash)
# -------------------------------------------------------------------------------------
#  Aufgaben:
#    1. Stellt sicher, dass Typst gefunden wird.
#    2. Kompiliert thesis.typ zuerst als Roh-PDF.
#    3. Fuegt optional die offizielle Erklaerungs-PDF per pdftk als echte
#       PDF-Seite(n) ein (Post-Processing).
#
#  Aufruf:   .\buildFinalPDF.sh            (einmalig bauen)
# =====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DECL_PDF="doc/SB_0009_FO_Pruefungsrechtliche_Erklaerung_und_Erklaerung_zur_Veroeffentlichung_der_Abschlussarbeit_public.pdf"
PDFTK_JAR="tools/pdftk/pdftk-all.jar"
MARKER="DECLARATION_PLACEHOLDER_RUN_BUILD_PS1"
FALLBACK_PLACEHOLDER_PAGE=4

RAW_PDF="thesis.raw.pdf"
FINAL_PDF="thesis.pdf"

invoke_pdftk() {
    if command -v pdftk &>/dev/null; then
        pdftk "$@"
    elif [[ -f "$PDFTK_JAR" ]] && command -v java &>/dev/null; then
        java -jar "$PDFTK_JAR" "$@"
    else
        echo "Fehler: pdftk ist nicht verfügbar." >&2
        return 1
    fi
}

get_pdf_page_count() {
    local pdf="$1"
    local count
    count=$(invoke_pdftk "$pdf" dump_data_utf8 | awk '/^NumberOfPages:/ {print $2}')
    if [[ -z "$count" ]]; then
        echo "Fehler: Seitenzahl konnte nicht ermittelt werden für $pdf" >&2
        return 1
    fi
    echo "$count"
}

get_placeholder_page_number() {
    local pdf="$1"
    local total_pages="$2"

    if ! command -v pdftotext &>/dev/null; then
        echo "pdftotext is not installed. Cannot extract page with warning."
        return 0
    fi

    for (( p=1; p<=total_pages; p++ )); do
        if pdftotext -f "$p" -l "$p" "$pdf" - 2>/dev/null | grep -q "$MARKER"; then
            echo "$p"
            return 0
        fi
    done
}

# --- 1. Typst prüfen ---
if ! command -v typst &>/dev/null; then
    echo "Fehler: Typst wurde nicht gefunden. Bitte via 'sudo pacman -S typst' installieren." >&2
    exit 1
fi

# --- 2. pdftk & Erklärungs-PDF prüfen ---
HAS_PDFTK=false
if command -v pdftk &>/dev/null || ([[ -f "$PDFTK_JAR" ]] && command -v java &>/dev/null); then
    HAS_PDFTK=true
fi

DECL_EXISTS=false
if [[ -f "$DECL_PDF" ]]; then
    DECL_EXISTS=true
fi

if $DECL_EXISTS && ! $HAS_PDFTK; then
    echo "Warnung: Erklärung-PDF gefunden, aber pdftk fehlt. Build läuft ohne PDF-Einfügung." >&2
fi

if ! $DECL_EXISTS; then
    echo "Warnung: Erklärung-PDF unter doc/ nicht gefunden. Build läuft ohne PDF-Einfügung." >&2
fi

# --- 3. Kompilieren ---
typst compile thesis.typ "$RAW_PDF"

if $DECL_EXISTS && $HAS_PDFTK; then
    RAW_PAGES=$(get_pdf_page_count "$RAW_PDF")
    PLACEHOLDER_PAGE=$(get_placeholder_page_number "$RAW_PDF" "$RAW_PAGES")
    if [[ -z "$PLACEHOLDER_PAGE" ]]; then
        PLACEHOLDER_PAGE=$FALLBACK_PLACEHOLDER_PAGE
        echo "Warnung: Platzhalter-Marker nicht gefunden. Verwende Seite $FALLBACK_PLACEHOLDER_PAGE als Fallback." >&2
    fi

    if [[ -z "$PLACEHOLDER_PAGE" ]]; then
        PLACEHOLDER_PAGE=$FALLBACK_PLACEHOLDER_PAGE
        echo "Warnung: Platzhalter-Marker nicht gefunden. Verwende Seite $FALLBACK_PLACEHOLDER_PAGE als Fallback." >&2
    fi

    if (( PLACEHOLDER_PAGE < 1 || PLACEHOLDER_PAGE > RAW_PAGES )); then
        echo "Fehler: Platzhalter-Seite ($PLACEHOLDER_PAGE) liegt außerhalb der Gesamtseiten ($RAW_PAGES)." >&2
        exit 1
    fi

    CAT_PARTS=()
    HEAD_END=$(( PLACEHOLDER_PAGE - 1 ))
    if (( HEAD_END >= 1 )); then
        CAT_PARTS+=("A1-${HEAD_END}")
    fi

    CAT_PARTS+=("B1-end")

    TAIL_START=$(( PLACEHOLDER_PAGE + 1 ))
    if (( TAIL_START <= RAW_PAGES )); then
        CAT_PARTS+=("A${TAIL_START}-end")
    fi

    invoke_pdftk A="$RAW_PDF" B="$DECL_PDF" cat "${CAT_PARTS[@]}" output "$FINAL_PDF" >/dev/null

    rm -f "$RAW_PDF"
    echo "Fertig: thesis.pdf mit eingefügter Erklärung (Platzhalter-Seite $PLACEHOLDER_PAGE ersetzt)."
else
    mv -f "$RAW_PDF" "$FINAL_PDF"
    echo "Fertig: thesis.pdf wurde ohne PDF-Einfügung erzeugt."
fi