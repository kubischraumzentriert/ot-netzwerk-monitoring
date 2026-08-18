---
title: "Statusanker NetzwerkAnalyse"
version: "2026-08-18"
last_reviewed: "2026-08-18"
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
- Workflow fuer Inventur, Port-9000-Benchmark, Vergleich und DuckDB ist
  dokumentiert
- Beispielkonfigurationen sind auf Platzhalter umgestellt

## Letzte verifizierte Bausteine

- `powershell/inventory_collect.ps1`
- `powershell/run_init_database.ps1`
- `powershell/run_inventory_steckbrief.ps1`
- `powershell/run_benchmark.ps1`
- `powershell/run_benchmark_comparison.ps1`
- `powershell/run_localhost_workflow.ps1`
- `R/run_init_database.R`
- `R/run_inventory_steckbrief.R`
- `R/run_localhost_simulation.R`
- `R/run_benchmark.R`
- `R/run_benchmark_comparison.R`
- `R/run_duckdb_analysis.R`
- `R/run_duckdb_query.R`
- `R/run_duckdb_overview_report.R`

## Wo anfangen?

1. [`README.md`](README.md) lesen
2. [`AGENTS.md`](AGENTS.md) lesen
3. [`SECURITY.md`](SECURITY.md) lesen
4. [`docs/07_vor_ort_checkliste_scan_auswerte_workflow.md`](docs/07_vor_ort_checkliste_scan_auswerte_workflow.md) lesen
5. [`docs/06_betriebsmanual_workflow.md`](docs/06_betriebsmanual_workflow.md) lesen
6. je nach Ziel die passende Konfiguration in `configs/` anpassen

## Wichtige Regeln

- keine realen Anlagendaten ins Repo
- Rohdaten, Scans und Reports bleiben lokal
- vor jedem Public-Push `SECURITY.md` und `.gitignore` pruefen

## Naechster sinnvoller Fokus

- Vor-Ort-Checkliste weiter verdichten
- echte `direct`- und `switch`-Testlaeufe ausfuehren
- Vergleichsreport mit realen Messwerten fuellen
