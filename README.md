# Vorlage Abschlussarbeit TH Nürnberg (efi)

Dies ist eine Typst-Vorlage zur Erstellung von Abschlussarbeiten innerhalb der Fakultät efi der [Technische Hochschule Nürnberg Georg Simon Ohm](https://www.th-nuernberg.de/). Sie beinhaltet Seiten-Einstellungen gemäß des efi-Leitfadens für wissenschaftliche Arbeiten. Zudem gibt es ein paar vorgefertigte Inhalte, die Tipps zur Einfügung von Grafiken, Tabellen, Code-Schnippseln und Links anhand von kleinen Beispielen geben. Nach Fertigstellung des Inhaltes kann die resultierende pdf-Datei vollständig gedruckt und gebunden werden, wobei die vorderste Seite bereits das Deckblatt darstellt.


## Vorteile von Typst ggü. LaTeX:

- Typst kompiliert in Bruchteilen einer Sekunde (statt mehrerer Sekunden bei LaTeX)
- benötigt keine Paketverwaltung wie MiKTeX
- meldet Fehler verständlicher
- einfachere Installation, verbraucht deutlich weniger Speicherplatz


## Hilfe bei der Einrichtung einer Entwicklungsumgebung für Typst:

Ich empfehle die Verwendung von [Visual Studio Code](https://code.visualstudio.com/docs/setup/windows) (mit der Erweiterung Tinymist Typst sowie vscode-pdf), [Git](https://git-scm.com/downloads/win), Typst (winget install Typst.Typst) und pdftk unter Windows. Bei anderen Betriebssystemen können kleine Abweichungen von Nöten sein.

Unter Linux (Arch) kann Typst einfach über `sudo pacman -S typst` installiert werden, pdftk einfach über `sudo pacman -S pdftk`.

Generell können bei nicht vorhandenen Admin-Rechten die Releases von GitHub/GitLab heruntergeladen werden:
- Typst: Binary von <https://github.com/typst/typst/releases> herunterladen und den Ordner zur `Path`-Umgebungsvariable hinzufügen
- pdftk: jar-Datei von https://gitlab.com/pdftk-java/pdftk/-/releases herunterladen und in diesem Repository im Ordner tools/pdftk/ abspeichern.

Durch `make` oder `typst watch thesis.typ thesis.pdf` wird ermöglicht, dass bei jeder Speicherung (Strg+S) in VS Code automatisch eine neue Version der PDF-Datei erstellt wird und diese innerhalb von VS Code betrachtet werden kann.
Durch die Extension Tinymist Typst ist rechts oben in VS Code ein Button "Show exported PDF" vorhanden, über den in der IDE das PDF live betrachtet werden kann (sofern der vorherige Befehl läuft).
Alternativ kann mit `make compile` bzw. `typst compile thesis.typ thesis.pdf` das PDF einmalig kompiliert werden.
Eine Löschung der erstellten Datei ist über `make clean` möglich. Für diese Befehle muss allerdings eine Version von make installiert sein, die unter `bash` läuft.

Ich empfehle, dass sehr regelmäßig Änderungen mittels Git (über Commits) gespeichert werden, um ggf. leicht wieder zu einem älteren Stand zurückkehren zu können. Definitiv lohnt sich die Erstellung eines privaten Repositories auf z.B. GitHub, um an mehreren PCs Zugriff auf die Dateien zu haben und weiter arbeiten zu können. Es ist empfehlenswert, jeden Satz in eine eigene Zeile zu packen, damit Änderungen in Git schöner gespeichert werden können (im PDF ergibt das keine Zeilenumbrüche).

Außerdem musst du vor Abgabe das offizielle und aktuelle Dokument der TH Nürnberg zur prüfungsrechtlichen Erklärung und Erklärung zur Veröffentlichung der Abschlussarbeit aus dem Intranet herunterladen im Ordner `doc` unter dem Dateinamen `SB_0009_FO_Pruefungsrechtliche_Erklaerung_und_Erklaerung_zur_Veroeffentlichung_der_Abschlussarbeit_public.pdf` speichern und ausfüllen. Da Typst leider keine PDF-Seiten unverändert einbinden kann, bedienen wir uns einem kleinen Skript, welches zunächst mit Typst kompiliert und anschließend mit pdftk die Seite einbindet. Da diese zwei Schritte wesentlich länger dauern als das reine Kompilieren, empfehle ich die Arbeit mit make / typst watch / typst compile. Bei diesen Befehlen wird ein auffälliger Warnhinweis anstelle des offiziellen Dokumentes angezeigt, um eindeutig zu zeigen, dass hier noch etwas fehlt. Erst vor Abgabe sollte dann das Skript mal durchlaufen werden. 
Dadurch wird es in der Datei `thesis.pdf` an der korrekten Stelle eingebunden.

Zur Einbindung des Abrufdatums im Literaturverzeichnis wurden kleine Änderungen in der IEEE-Konfigurationsdatei von Typst vorgenommen (siehe styles/ieee-typst.csl).


## Generelle Tipps zum Schreiben der Abschlussarbeit:

- Lese den Leitfaden der Fakultät efi.
- Frage bei Unklarheiten bei deinen Betreuern nach. Bitte diese auch um ein Review des Inhaltsverzeichnisses oder einer ausformulierten Seite.
- Halte deine Literaturliste (`refs.bib`) immer aktuell. Tipp: Nutze Zotero zur Verwaltung der Literatur. Diese kann auch Informationen nach ISBN-Eintrag recherchieren und lässt Konvertierungen für BiBTeX zu. Kontrolliere dennoch, ob alle wichtigen Einträge korrekt und vorhanden sind.
- Nutze die Angebote des Schreibzentrums.
