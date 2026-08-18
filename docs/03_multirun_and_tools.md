---
title: "03 multirun and tools"
output: "html"
---

# Mehrlaeufige Auswertung und Tool-Workflow

## Reihenfolge

1. Inventur sammeln
2. Inventur als Markdown zusammenfassen
3. mehrere Sessions und Benchmarks gemeinsam auswerten
4. Direkt-vs-Switch-Benchmarks getrennt vergleichen
5. auffaellige Faelle mit Nmap, Wireshark und Suricata vertiefen
6. Datenbank initialisieren und Ergebnisse in DuckDB laden

## Nmap

Der Nmap-Workflow ist in diesem Projekt bewusst konservativ:

- feste Zielhosts aus `configs/targets.csv`
- Port 9000 als Standard
- langsamerer Scan mit wenigen Retries
- Ausgabe pro Ziel als `-oA` Satz

## Wireshark / tshark

Fuer Mitschnitte nutzen wir `tshark`, weil es sich gut skripten laesst.

- erst Interface anzeigen
- dann auf den relevanten Port filtern
- Mitschnitt als `pcapng` speichern

## Suricata

Suricata ist fuer passives Logging gedacht.

- nur auf einer freigegebenen Testumgebung einsetzen
- Logverzeichnis pro Lauf trennen
- die Laufzeit begrenzen

## DuckDB

DuckDB ist die gemeinsame lokale Analyse-Datei fuer:

- Inventur-Sessions
- Benchmark-Rohdaten
- zusammengefasste Kennzahlen

Der native Weg ist `duckdb` als R-Paket.
Als Alternative kann das JDBC-JAR verwendet werden.

Der Einstieg ist `R/run_init_database.R`, danach `R/run_duckdb_analysis.R`.
Zusammen erzeugen sie die Datenbank `data/processed/network_analysis.duckdb`
und den Report `reports/network_overview_duckdb.md`.

Einzelne Abfragen laufen ueber `R/run_duckdb_query.R`, zum Beispiel mit
`sql/inventory_overview.sql`.

Der kombinierte Ueberblick fuer Inventur und Benchmark heisst
`R/run_duckdb_overview_report.R`.

Der Direkt-vs-Switch-Vergleich laeuft ueber `R/run_benchmark_comparison.R`.
Die passenden Beispielkonfigurationen sind `configs/run.direct.example.csv`
und `configs/run.switch.example.csv`.
