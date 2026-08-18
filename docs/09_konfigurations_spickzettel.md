---
title: "09 konfigurations spickzettel"
output: "html"
---

# Konfigurations-Spickzettel

Die kurze Referenz fuer den Vor-Ort-Einsatz.

## Welche Datei wofuer?

- `configs/targets.csv`: echte Ziele fuer Ping und TCP
- `configs/targets.localhost.csv`: lokaler Trockenlauf auf `127.0.0.1`
- `configs/run.direct.csv`: Direktlauf
- `configs/run.switch.csv`: Switchlauf
- `configs/run.localhost.csv`: Trockenlauf
- `configs/scan_targets.csv`: Nmap-Ziele
- `configs/duckdb_jdbc.example.csv`: optionale JDBC-Anbindung
- `sql/ddl/network_analysis_schema.sql`: DuckDB-Basisstruktur

## Wichtige Felder

### `targets.csv`

- `label`: Name des Geraets
- `host`: IP oder Hostname
- `port`: Port pro Zielhost, optional
- `request`: TCP-Payload, optional

### `run.*.csv`

- `ping_count`: Anzahl Ping-Proben
- `ping_interval_sec`: Pause zwischen Pings
- `tcp_count`: Anzahl TCP-Proben
- `tcp_interval_sec`: Pause zwischen TCP-Proben
- `tcp_timeout_sec`: TCP-Timeout
- `tcp_port`: Default-Port, wenn `targets.csv` keinen gueltigen Port hat
- `session_tag`: Laufname wie `direct`, `switch` oder `localhost`
- `output_dir`: Zielordner fuer Rohdaten

### `scan_targets.csv`

- `label`: Anzeigename
- `host`: Zielhost
- `ports`: Port oder Portliste fuer `nmap -p`

### `duckdb_jdbc.example.csv`

- `jar_path`: Pfad zum DuckDB-JDBC-JAR
- `db_path`: Pfad zur lokalen DuckDB-Datei
- `driver_class`: JDBC-Treiberklasse

### `network_analysis_schema.sql`

- `schema_metadata`: Schema-Metadaten
- `inventory_sessions`: verdichtete Inventur
- `benchmark_rows`: Rohmessungen
- `benchmark_summary`: Kennzahlen pro Session

## Typische Werte

- Direktlauf: `session_tag=direct`, `output_dir=data/raw/direct`
- Switchlauf: `session_tag=switch`, `output_dir=data/raw/switch`
- Trockenlauf: `session_tag=localhost`, `output_dir=data/raw/sim`
- Standardport: `tcp_port=9000`
- Schema-Start: `Rscript R/run_init_database.R`

## Wichtig

- `session_tag` ist nur ein Lauf-Label
- der Port kann pro Zielhost gesetzt werden
- `ports` in Nmap kann auch eine Liste sein, zum Beispiel `80,443,9000-9100`
