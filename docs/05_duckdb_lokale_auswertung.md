# Lokale DuckDB-Auswertung

Diese Auswertung sammelt die vorhandenen Rohdaten in einer lokalen DuckDB-Datei
und macht sie als SQL-basierten Analyse-Store nutzbar.

## Zweck

- Inventur-Sessions vergleichbar machen
- Benchmark-Läufe zentral auswerten
- spaetere Anlagen und Messreihen in derselben Struktur aufnehmen
- lokale, offline nutzbare Analysen ohne GitHub oder Cloud

## Datenbank

- Datei: `data/processed/network_analysis.duckdb`
- Report: `reports/network_overview_duckdb.md`

## Was geladen wird

- `inventory_sessions`
- `benchmark_rows`
- `benchmark_summary`

## Start

```powershell
Rscript R/run_duckdb_analysis.R
```

Das Skript versucht zunaechst den nativen DuckDB-Weg. Falls dieser in einer
R-Umgebung nicht verfuegbar ist, kann die JDBC-Variante genutzt werden, sofern
das JAR und die Java-Pakete vorhanden sind.

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
