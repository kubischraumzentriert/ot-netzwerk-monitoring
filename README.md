---
title: "README"
output: "html"
---

# NetzwerkAnalyse

Lokales Git-Repository fuer eine Analyse- und Monitoring-Infrastruktur rund um OT-Netze, Anlagen und Maschinen.

## Oeffentliche Kurzfassung

Dieses Repository sammelt Werkzeuge, Doku und Auswertungen fuer lokale
Netzwerk-Inventuren, konfigurierbare TCP-Port-Messungen auf einem oder mehreren Ports pro Zielhost und Vergleiche
zwischen direkter Verbindung und Switch.

Die Repo-Contents sind bewusst so aufgebaut, dass keine Rohdaten, Scans oder
Ergebnisartefakte ins Repository gehoeren. Alles Laufzeitbezogene landet lokal
unter `data/` oder `reports/` und ist in `.gitignore` ausgeschlossen.

## Einstieg

Bevor du am Projekt arbeitest, lies bitte:

1. [AGENTS.md](AGENTS.md)
2. [SECURITY.md](SECURITY.md)
3. [Statusanker.md](Statusanker.md)
4. die Checkliste in [docs/07_vor_ort_checkliste_scan_auswerte_workflow.md](docs/07_vor_ort_checkliste_scan_auswerte_workflow.md)
5. das Betriebsmanual in [docs/06_betriebsmanual_workflow.md](docs/06_betriebsmanual_workflow.md)
6. die Konfigurationsreferenz in [docs/08_konfigurationsreferenz.md](docs/08_konfigurationsreferenz.md)
7. den Konfigurations-Spickzettel in [docs/09_konfigurations_spickzettel.md](docs/09_konfigurations_spickzettel.md)

## Zielbild

- Netzwerke und Assets inventarisieren
- Anlagen und Maschinen scannen und pruefen
- Monitoring und Performance-Analysen aufbauen
- Netzwerkzugriffe und Auffaelligkeiten auswerten
- Ergebnisse reproduzierbar dokumentieren

## Bevorzugte Werkzeuge

1. R
2. Python
3. PowerShell

## Erste Struktur

- `R/` fuer Auswertungen, Reports und Visualisierungen
- `python/` fuer Automatisierung, Parser und Analyse-Skripte
- `powershell/` fuer Windows-nahe Orchestrierung und Datensammlung
- `sql/` fuer wiederverwendbare Abfragen
- `templates/` fuer Vorlagen und wiederverwendbare Markdown-Strukturen
- `data/raw/` fuer Rohdaten, Exporte und Scans
- `data/processed/` fuer bereinigte oder aggregierte Daten
- `docs/` fuer Konzepte, Doku und Entscheidungen
- `configs/` fuer Konfigurationen und Workflows
- `reports/` fuer erzeugte Berichte
- `AGENTS.md` fuer agentenbezogene Arbeitsregeln
- `SECURITY.md` fuer Publikations- und Sicherheitsregeln

## Mogliche Analyse-Bausteine

- `inventory` fuer Asset-Erfassung
- `scan` fuer Nmap-Workflows
- `traffic` fuer Wireshark- oder PCAP-Auswertung
- `alerts` fuer Auffaelligkeiten und Checks

## Inventur und Auswertung

- lokale Inventur mit `arp`, `netstat` und Schnittstellen-Informationen
- Steckbrief als Markdown aus R
- optional DuckDB als lokale Auswertungsbasis
- spaeterer Vergleich mehrerer Anlagen und Messlaeufe

## Konfigurations-Spickzettel

| Datei | Zweck | Typische Schluessel |
| --- | --- | --- |
| `configs/targets.csv` | Ziele fuer echte Geraete | `label`, `host`, `port`, `request` |
| `configs/run.direct.csv` | Direktlauf | `ping_count`, `tcp_count`, `tcp_port`, `session_tag`, `output_dir` |
| `configs/run.switch.csv` | Switchlauf | `ping_count`, `tcp_count`, `tcp_port`, `session_tag`, `output_dir` |
| `configs/run.localhost.csv` | Trockenlauf | `ping_count`, `tcp_count`, `tcp_port`, `session_tag`, `output_dir` |
| `configs/scan_targets.csv` | Nmap-Ziele | `label`, `host`, `ports` |
| `configs/duckdb_jdbc.example.csv` | optionale JDBC-Anbindung | `jar_path`, `db_path`, `driver_class` |
| `sql/ddl/network_analysis_schema.sql` | DuckDB-DDL fuer die Basisstruktur | `schema_metadata`, `inventory_sessions`, `benchmark_rows`, `benchmark_summary` |

## Workflow Werkzeuge

- `powershell/run_init_database.ps1` fuer den ersten Datenbank-Initialisierungsschritt
- `powershell/inventory_collect.ps1` fuer die lokale Inventur
- `powershell/run_inventory_steckbrief.ps1` fuer den Inventur-Steckbrief
- `powershell/run_benchmark.ps1` fuer TCP-Port-Messungen, Standard ist 9000, je Zielhost kann ein eigener Port gesetzt werden
- `powershell/run_benchmark_comparison.ps1` fuer Direkt-vs-Switch-Vergleiche
- `powershell/run_localhost_workflow.ps1` fuer den lokalen Trockenlauf
- `powershell/run_nmap_scan.ps1` fuer konservative Nmap-Scans auf freigegebenen Ports
- `powershell/list_capture_interfaces.ps1` fuer `tshark -D`
- `powershell/start_wireshark_capture.ps1` fuer paketbasierten Mitschnitt
- `powershell/start_suricata_capture.ps1` fuer passives Logging
- `R/run_init_database.R` fuer die lokale DuckDB-Initialisierung
- `R/run_inventory_steckbrief.R` fuer den Markdown-Steckbrief
- `R/run_benchmark.R` fuer die Messlaeufe
- `R/run_benchmark_comparison.R` fuer den Direkt-vs-Switch-Vergleich
- `R/run_multirun_analysis.R` fuer die gemeinsame Analyse mehrerer Sessions
- `R/run_duckdb_analysis.R` fuer die lokale DuckDB-Datei und den DuckDB-Report
- `R/run_duckdb_query.R` fuer einzelne SQL-Abfragen gegen die DuckDB-Datei
- `R/run_duckdb_overview_report.R` fuer den kombinierten DuckDB-Analyse-Report

## Betriebsmanual

- `docs/06_betriebsmanual_workflow.md` fuer die Reihenfolge vor Ort und die
  notwendigen Einstellungen
- `docs/07_vor_ort_checkliste_scan_auswerte_workflow.md` fuer die kompakte
  Vor-Ort-Checkliste
- `docs/08_konfigurationsreferenz.md` fuer die komplette Config-Referenz
- `docs/09_konfigurations_spickzettel.md` fuer den schnellen Vor-Ort-Ueberblick

## GitHub Hinweis

- Beispiel-IPs in `configs/*.csv` sind absichtlich Platzhalter
- echte Anlagenadressen gehoeren nicht ins Repo
- Rohdaten, Scans und Reports bleiben lokal und werden nicht versioniert
- TCP-Ports sind konfigurierbar; `9000` ist nur der Standardwert und pro Zielhost kann ein eigener Port gesetzt werden

## Public Repo Hinweis

Ein public GitHub-Repository ist fuer alle lesbar, aber nicht fuer alle
beschreibbar.

- Push-Rechte haben nur Besitzer, Admins oder explizit berechtigte
  Collaborators
- andere koennen das Repo forken oder per Pull Request beitragen, wenn du das
  erlaubst
- ohne Schreibrechte kann niemand direkt auf dieses Repo pushen

Wenn du das Repo oeffentlich lassen willst, halte die Beispielkonfigurationen
generisch und pruefe vor jedem Push `SECURITY.md` und `.gitignore`.
