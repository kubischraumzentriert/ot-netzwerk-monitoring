---
title: "05 duckdb lokale auswertung"
output: "html_document"
---

# Lokale DuckDB-Auswertung

Diese Auswertung sammelt die vorhandenen Rohdaten in einer lokalen DuckDB-Datei
und macht sie als SQL-basierten Analyse-Store nutzbar.

Eine detaillierte Beschreibung der Tabellen, Views und Spalten steht in
[docs/11_duckdb_datenmodell.md](11_duckdb_datenmodell.md).

## Zweck

- Inventur-Sessions vergleichbar machen
- Benchmark-LÃ¤ufe zentral auswerten
- spaetere Anlagen und Messreihen in derselben Struktur aufnehmen
- lokale, offline nutzbare Analysen ohne GitHub oder Cloud

## Datenbank

- Datei: `data/processed/network_analysis.duckdb`
- Report: `reports/network_overview_duckdb.md`
- DDL: `sql/ddl/network_analysis_schema.sql`

## Was geladen wird

- `inventory_sessions`
- `benchmark_rows`
- `benchmark_summary`
- Views fuer Basisabfragen:
  - `inventory_overview`
  - `benchmark_overview`
  - `benchmark_rows_ping`
  - `benchmark_rows_tcp`

Die Tabellen haben interne technische Schluessel wie `session_id` oder
`row_id`. Diese IDs entstehen erst beim Laden in DuckDB und muessen in den
CSV-Dateien nicht vorhanden sein.

## Start

Die empfohlene Reihenfolge ist:

```powershell
Rscript R/run_init_database.R
Rscript R/run_duckdb_analysis.R
```

Oder aus PowerShell:

```powershell
powershell\run_init_database.ps1
```

Das Skript versucht zunaechst den nativen DuckDB-Weg. Falls dieser in einer
R-Umgebung nicht verfuegbar ist, kann die JDBC-Variante genutzt werden, sofern
das JAR und die Java-Pakete vorhanden sind.

`R/run_duckdb_analysis.R` ueberfuehrt die aktuellen Inventur- und
Benchmark-Rohdaten in die DuckDB und schreibt den Uebersichtsreport.
`R/run_duckdb_overview_report.R` erzeugt nur den lesenden
Uebersichtsreport aus der bereits gefuellten DuckDB.

Wenn du einen getrennten Testlauf fahren willst, kannst du die lokale DuckDB
ueber `NETWORK_ANALYSIS_DUCKDB_PATH` oder die Wrapper-Parameter `-DbPath`
gezielt auf eine andere Datei umbiegen.

Einzelne SQL-Abfragen laufen ueber:

```powershell
Rscript R/run_duckdb_query.R "SELECT * FROM inventory_sessions LIMIT 10"
```

Oder mit SQL-Datei:

```powershell
Rscript R/run_duckdb_query.R sql\inventory_overview.sql
```

Einen kombinierten Ueberblick fuer Inventur und Benchmarks erzeugt:

```powershell
Rscript R/run_duckdb_overview_report.R
```

## Naechste Ausbaustufen

- weitere Tabellen pro Anlage
- SQL-Queries fuer Latenz- und Fehlervergleiche
- Archivierung mehrerer Testlaeufe
- Auswertung direkt aus DuckDB nach Markdown oder CSV

