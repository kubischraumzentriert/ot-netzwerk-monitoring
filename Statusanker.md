---
title: "Statusanker NetzwerkAnalyse"
version: "2026-08-19"
last_reviewed: "2026-08-19"
project: "NetzwerkAnalyse"
branch: "main"
status: "active"
---

# Statusanker

Dieser Statusanker beschreibt den aktuellen Arbeitsstand des Projekts und ist
der schnelle Einstiegspunkt fuer Uebersicht, Arbeitsfokus und letzte
Validierungen.

## Aktueller Stand

- Public GitHub-Repository ist aktiv auf `main`
- AGENTS- und Security-Regeln sind im Repo verankert
- Workflow fuer Inventur, konfigurierbaren TCP-Port-Benchmark, Session-
  Vergleich und DuckDB ist dokumentiert
- `direct`/`switch` sind kein Sonderfall mehr im Code: eine generische
  `configs/run.csv` fuer beliebige Messlaeufe, `session_tag` frei waehlbar
- `R/run_benchmark_comparison.R` / `powershell/run_benchmark_comparison.ps1`
  verlangen jetzt explizit `--base=`/`--compare=` bzw. `-BaseTag`/
  `-CompareTag` -- kein stilles Erraten der ersten zwei Session-Tags mehr
- TCP-Probe unterscheidet `transport_ok` (Verbindung) und `reply_ok`
  (Antwort erhalten); `success` verlangt beides
- `renv` isoliert die Projekt-Library korrekt (globale Library nur noch
  Fallback), `testthat` ist reguraer im Lockfile erfasst
- automatisierte Testsuite (`tests/run_tests.R`, 111 Tests) plus
  GitHub-Actions-CI (`.github/workflows/r-tests.yml`, laeuft bei jedem
  Push/PR auf `main`)
- Ziel-Uebersicht berechnet Median/P95 korrekt aus den Rohdaten statt aus
  einem gewichteten Mittel von Gruppen-Medianen
- Boxplots und Erfolgsrate-Balken trennen nach `session_tag`
- Ping- (R) und netstat/arp-Erfassung (PowerShell) dekodieren die
  OEM-Codepage-Ausgabe von Windows-Konsolentools korrekt nach UTF-8
- `parse_arp_entries()` behaelt den Interface-Kontext, damit gleiche
  Eintraege auf verschiedenen Interfaces nicht wie Duplikate aussehen
- Optionaler ARP-Cache-Refresh fuer lokale `/24`-Inventuren ist als
  PowerShell-Wrapper ergaenzt
- Tool-Pfade fuer Rscript, Nmap, tshark und Suricata werden zentral ueber
  Parameter, lokale Config und automatische Suche aufgeloest
- Beispielkonfigurationen sind auf Platzhalter umgestellt

## Letzte verifizierte Bausteine

- `powershell/inventory_collect.ps1`
- `powershell/refresh_arp_cache.ps1`
- `powershell/run_init_database.ps1`
- `powershell/run_inventory_steckbrief.ps1`
- `powershell/run_benchmark.ps1`
- `powershell/run_benchmark_comparison.ps1` (Pflicht: `-BaseTag`/`-CompareTag`)
- `powershell/run_localhost_workflow.ps1`
- `R/run_init_database.R`
- `R/run_inventory_steckbrief.R`
- `R/run_localhost_simulation.R`
- `R/run_benchmark.R`
- `R/run_benchmark_comparison.R` (Pflicht: `--base=`/`--compare=`)
- `R/run_duckdb_analysis.R`
- `R/run_duckdb_query.R`
- `R/run_duckdb_overview_report.R`
- `tests/run_tests.R` (111/111 gruen)

Zuletzt end-to-end per lokalem Simulationslauf (`run_localhost_workflow.ps1`
+ alle Report-/Plot-/Vergleichs-Generatoren + direkte DuckDB-Abfragen)
gegengeprueft am 2026-08-19, zweimal wiederholt zur Absicherung.

## Wo anfangen?

1. [`README.md`](README.md) lesen
2. [`AGENTS.md`](AGENTS.md) lesen
3. [`SECURITY.md`](SECURITY.md) lesen
4. [`docs/07_vor_ort_checkliste_scan_auswerte_workflow.md`](docs/07_vor_ort_checkliste_scan_auswerte_workflow.md) lesen
5. [`docs/06_betriebsmanual_workflow.md`](docs/06_betriebsmanual_workflow.md) lesen
6. je nach Ziel die passende Konfiguration in `configs/` anpassen
   (`configs/run.csv` fuer den jeweiligen Messlauf, `session_tag`/
   `output_dir` pro Lauf setzen)
7. vor Aenderungen `Rscript tests/run_tests.R` laufen lassen, siehe
   [docs/14_renv_und_abhaengigkeiten.md](docs/14_renv_und_abhaengigkeiten.md)

## Wichtige Regeln

- keine realen Anlagendaten ins Repo
- Rohdaten, Scans und Reports bleiben lokal
- vor jedem Public-Push `SECURITY.md` und `.gitignore` pruefen

## Naechster sinnvoller Fokus

- echte Messlaeufe (z. B. Direktverbindung vs. Switch) mit realen Geraeten
  ausfuehren und `--base=`/`--compare=` gegeneinander auswerten
- Vor-Ort-Checkliste weiter verdichten
- ARP-Refresh im freigegebenen Testnetz pruefen und MAC-Liste plausibilisieren
- bekannte, noch offene Kleinfunde:
  - `powershell/refresh_arp_cache.ps1`s `Convert-ArpTextToRows` erkennt nur
    die englische `Interface:`-Kopfzeile, nicht das deutsche
    `Schnittstelle:` -- auf deutschem Windows bleibt das Interface-Feld
    dadurch leer (R-seitiger Parser wurde bereits fuer beide Sprachen
    gefixt, PowerShell-Seite noch nicht)
  - DuckDB-Schema ist noch flach (`benchmark_rows`/`benchmark_summary`);
    ein Messmodell mit `measurement_run`/`asset`/`endpoint` waere der
    naechste groessere Schritt fuer echtes Langzeit-Monitoring
  - kein `LICENSE`-File im oeffentlichen Repo
