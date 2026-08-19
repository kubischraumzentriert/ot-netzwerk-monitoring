---
title: "09 konfigurations spickzettel"
output: "html_document"
---

# Konfigurations-Spickzettel

Die kurze Referenz fuer den Vor-Ort-Einsatz.

## Welche Datei wofuer?

- `configs/targets.csv`: generische Zielvorlage fuer Ping und TCP
- `configs/targets.private.csv`: lokale, ignorierte Zieladressen
- `configs/targets.production.example.csv`: Vorlage fuer reale Zielgeraete
- `configs/targets.localhost.csv`: lokaler Trockenlauf auf `127.0.0.1`
- `configs/run.direct.csv`: Direktlauf
- `configs/run.switch.csv`: Switchlauf
- `configs/run.webapp.csv`: Webapp-Zeitmessung
- `configs/run.localhost.csv`: Trockenlauf
- `configs/scan_targets.csv`: Nmap-Ziele
- `configs/webapp_targets.example.csv`: Webapp-Zielvorlage
- `configs/tools.example.csv`: Vorlage fuer lokale Tool-Pfade
- `configs/duckdb_jdbc.example.csv`: optionale JDBC-Anbindung
- `sql/ddl/network_analysis_schema.sql`: DuckDB-Basisstruktur
- `docs/11_duckdb_datenmodell.md`: Tabellen, Views und Spalten im Detail

Hinweis:

- `*.private.csv` bleibt lokal und wird durch `.gitignore` nicht versioniert
- `*.example.csv` bleibt im Repo und dient als Vorlage

## Wichtige Felder

### `targets.csv`

- generische Zielvorlage
- gleiche Spalten wie unten

### `targets.private.csv`

- lokale Arbeitsdatei fuer reale Zielgeraete
- gleiche Spalten wie `targets.csv`
- wird bevorzugt genutzt, wenn vorhanden

### `targets.production.example.csv`

- Vorlage fuer reale Zielgeraete
- gleiche Spalten wie `targets.csv`
- nur Platzhalter-Adressen

### `run.*.csv`

- `ping_count`: Anzahl Ping-Proben
- `ping_interval_sec`: Pause zwischen Pings
- `tcp_count`: Anzahl TCP-Proben
- `tcp_interval_sec`: Pause zwischen TCP-Proben
- `tcp_timeout_sec`: TCP-Timeout
- `tcp_port`: Default-Port, wenn `targets.csv` oder `targets.private.csv` keinen gueltigen Port hat
- `session_tag`: Laufname wie `direct`, `switch` oder `localhost`
- `output_dir`: Zielordner fuer Rohdaten

### `run.webapp.csv`

- `sample_count`: Anzahl der Webapp-Samples
- `interval_sec`: Sekunden zwischen den Samples
- `timeout_sec`: HTTP-Timeout
- `method`: `HEAD` oder `GET`
- `session_tag`: Laufname wie `webapp`
- `output_dir`: Zielordner fuer Rohdaten

### `webapp_targets.example.csv`

- `label`: Anzeigename
- `url`: komplette Ziel-URL
- `method`: HTTP-Methode, empfohlen `HEAD`
- `interval_sec`: optionaler Ziel-Override fuer das Intervall
- `timeout_sec`: optionaler Ziel-Override fuer den Timeout

### `scan_targets.csv`

- `label`: Anzeigename
- `host`: Zielhost
- `ports`: Port oder Portliste fuer `nmap -p`

### Nmap-Katalog

- wichtigste Nmap-Optionen fuer OT-Netze: [docs/10_nmap_optionen_ot.md](10_nmap_optionen_ot.md)

### `tools.csv` / `tools.private.csv`

- optionale lokale Pfade fuer `rscript`, `nmap`, `tshark`, `suricata`
- wird vor `PATH` und bekannten Windows-Installationspfaden ausgewertet
- echte lokale Pfade bleiben ignoriert und werden nicht versioniert

### `duckdb_jdbc.example.csv`

- `jar_path`: Pfad zum DuckDB-JDBC-JAR
- `db_path`: Pfad zur lokalen DuckDB-Datei
- `driver_class`: JDBC-Treiberklasse

### `network_analysis_schema.sql`

- `schema_metadata`: Schema-Metadaten
- `inventory_sessions`: verdichtete Inventur
- `benchmark_rows`: Rohmessungen
- `benchmark_summary`: Kennzahlen pro Session

### DuckDB-Datenmodell

- `elapsed_ms`: Laufzeit der Probe selbst, also Prozesszeit
- `metric_ms`: eigentliche Messgroesse, bei Ping die RTT
- Views:
  - `inventory_overview`
  - `benchmark_overview`
  - `benchmark_rows_ping`
  - `benchmark_rows_tcp`

## Typische Werte

- Direktlauf: `session_tag=direct`, `output_dir=data/raw/direct`
- Switchlauf: `session_tag=switch`, `output_dir=data/raw/switch`
- Trockenlauf: `session_tag=localhost`, `output_dir=data/raw/sim`
- Webapp-Timing: `session_tag=webapp`, `output_dir=data/raw/webapp`
- Standardport: `tcp_port=9000`
- Schema-Start: `powershell\run_init_database.ps1`

## Wichtig

- `session_tag` ist nur ein Lauf-Label
- der Port kann pro Zielhost gesetzt werden
- `ports` in Nmap kann auch eine Liste sein, zum Beispiel `80,443,9000-9100`

