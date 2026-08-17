# NetzwerkAnalyse

Lokales Git-Repository fuer eine Analyse- und Monitoring-Infrastruktur rund um OT-Netze, Anlagen und Maschinen.

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
- `data/raw/` fuer Rohdaten, Exporte und Scans
- `data/processed/` fuer bereinigte oder aggregierte Daten
- `docs/` fuer Konzepte, Doku und Entscheidungen
- `configs/` fuer Konfigurationen und Workflows
- `reports/` fuer erzeugte Berichte

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

## Workflow Werkzeuge

- `powershell/run_nmap_scan.ps1` fuer konservative Nmap-Scans auf Port 9000
- `powershell/list_capture_interfaces.ps1` fuer `tshark -D`
- `powershell/start_wireshark_capture.ps1` fuer paketbasierten Mitschnitt
- `powershell/start_suricata_capture.ps1` fuer passives Logging
- `R/run_multirun_analysis.R` fuer die gemeinsame Analyse mehrerer Sessions
- `R/run_duckdb_analysis.R` fuer die lokale DuckDB-Datei und den DuckDB-Report
- `R/run_duckdb_query.R` fuer einzelne SQL-Abfragen gegen die DuckDB-Datei
- `R/run_duckdb_overview_report.R` fuer den kombinierten DuckDB-Analyse-Report

## Naechster Schritt

Wenn du willst, baue ich als Naechstes ein kleines Grundgeruest mit:

- Ordnern und Platzhaltern
- einer ersten R-Analyse
- einer Python-Hilfsstruktur
- PowerShell-Skripten fuer Scans und Exporte
