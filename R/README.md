---
title: "README"
output: "html_document"
---

# R-Skripte

## Einstieg

- `00_setup.R` laedt Pfade und Konfiguration
- `run_inventory_report.R` erzeugt den Markdown-Steckbrief fuer eine Session
- `m01_ping_tcp_probe.R` fuehrt Ping- und TCP-Messungen durch
- `run_multirun_analysis.R` fasst mehrere Inventur- und Benchmark-Laufe zusammen
- `run_duckdb_analysis.R` laedt die Sammeldaten in DuckDB

## Verwendung

1. `configs/targets.csv` aus `configs/targets.example.csv` ableiten
2. `configs/run.csv` aus `configs/run.example.csv` ableiten
3. `powershell/run_benchmark.ps1` ausfuehren

## Hinweis

Die TCP-Messung ist generisch. Wenn dein Dienst auf Port 9000 ein bestimmtes Protokoll erwartet, muessen wir das Request-Format ggf. noch anpassen.

## Port-Konfiguration

- `configs/run.csv` enthaelt den Default-Port unter `tcp_port`
- `configs/targets.csv` kann pro Geraet einen eigenen Port setzen
- Wenn ein Ziel keinen gueltigen Port hat, faellt der Lauf auf `tcp_port` zurueck

## DuckDB-Anbindung

- `R/02_duckdb.R` ist der native Weg ueber das `duckdb`-Paket
- `R/03_duckdb_jdbc.R` ist der JDBC-Weg ueber `RJDBC`, `rJava` und das JAR
- Lokale JAR-Pfade gehoeren in `configs/duckdb_jdbc.csv` oder eine lokale
  Arbeitskopie der Beispielkonfiguration und werden nicht versioniert.

