---
title: "11 duckdb datenmodell"
output: "html_document"
---

# DuckDB-Datenmodell

Dieses Dokument beschreibt den Inhalt der lokalen DuckDB-Datei
`data/processed/network_analysis.duckdb`.

## Zweck

Die DuckDB ist der lokale Analyse-Store fuer:

- Inventur-Sessions
- Ping- und TCP-Benchmark-Rohdaten
- zusammengefasste Kennzahlen pro Session, Ziel und Probe
- wiederverwendbare Basisabfragen per View

## Tabellen

### `schema_metadata`

Metadaten zur Initialisierung des Schemas.

| Spalte | Bedeutung |
| --- | --- |
| `schema_name` | Name des Schemas |
| `schema_version` | Versionsstand des Schemas |
| `created_at` | Zeitpunkt der Initialisierung |
| `note` | Freitext zur Herkunft |

### `inventory_sessions`

Verdichtete Inventur je Lauf.

| Spalte | Bedeutung |
| --- | --- |
| `session_id` | Interner Schluessel |
| `session_dir` | Verzeichnis der Rohinventur |
| `computer_name` | Name des erfassten Rechners |
| `collected_at` | Zeitpunkt der Inventur |
| `adapter_count` | Anzahl gefundener Netzwerkadapter |
| `arp_count` | Anzahl gefundener ARP-Eintraege |
| `tcp_count` | Anzahl gefundener TCP-Verbindungen |
| `listening_count` | Anzahl lauschender Verbindungen |
| `primary_ipv4` | wichtigste IPv4-Adresse |
| `primary_mac` | wichtigste MAC-Adresse |

### `benchmark_rows`

Rohdaten aller Messungen, also die einzelnen Ping- und TCP-Zeilen.

| Spalte | Bedeutung |
| --- | --- |
| `row_id` | Interner Schluessel |
| `ts` | Zeitstempel der Messung |
| `host` | Zielhost der Probe |
| `probe` | `ping` oder `tcp` |
| `success` | Erfolg oder Fehlschlag |
| `metric_ms` | eigentliche Messgroesse der Probe |
| `elapsed_ms` | reale Laufzeit des Probe-Prozesses |
| `detail` | Ausgabedetail der Probe |
| `port` | Zielport der Probe, bei Ping `NA` |
| `connect_ms` | Verbindungszeit bei TCP, sonst `NA` |
| `total_ms` | Gesamtlaufzeit der TCP-Probe |
| `request` | gesendete TCP-Nachricht |
| `reply` | Antwort des Zielsystems |
| `error` | Fehlermeldung bei TCP-Fehlern |
| `target_label` | Anzeigename des Ziels |
| `session_tag` | frei waehlbare Laufbezeichnung, z. B. `localhost`, `direct`, `switch` |
| `target_host` | Ziel-IP oder Zielname aus der Konfiguration |
| `target_port` | Zielport aus der Konfiguration |
| `source_file` | Quell-CSV der Rohdaten |

Wichtige Semantik:

- Bei `ping` ist `metric_ms` die aus der Ping-Ausgabe gelesene RTT.
- Bei `ping` ist `elapsed_ms` nur die Laufzeit des gesamten Ping-Befehls.
- Bei `tcp` ist `connect_ms` die Zeit bis zum Verbindungsaufbau.
- Bei `tcp` ist `total_ms` die Gesamtzeit der TCP-Probe inklusive Senden und Lesen.

### `benchmark_summary`

Verdichtete Kennzahlen je Session, Ziel und Probe.

| Spalte | Bedeutung |
| --- | --- |
| `summary_id` | Interner Schluessel |
| `session_tag` | Laufbezeichnung |
| `target_label` | Zielbezeichnung |
| `probe` | `ping` oder `tcp` |
| `rows` | Anzahl Rohzeilen in dieser Gruppe |
| `success_rate` | Erfolgsquote |
| `metric_ms_mean` | Mittelwert von `metric_ms` |
| `metric_ms_median` | Median von `metric_ms` |
| `metric_ms_p95` | 95. Perzentil von `metric_ms` |
| `connect_ms_mean` | Mittelwert von `connect_ms` |
| `total_ms_mean` | Mittelwert von `total_ms` |

## Views

Die DDL legt zusaetzlich folgende Views an:

| View | Bedeutung |
| --- | --- |
| `inventory_overview` | Lesbare Ansicht auf `inventory_sessions` |
| `benchmark_overview` | Lesbare Ansicht auf `benchmark_summary` |
| `benchmark_rows_ping` | Alle Ping-Rohzeilen |
| `benchmark_rows_tcp` | Alle TCP-Rohzeilen |

## Datenfluss

1. `R/run_init_database.R` legt Schema und Views an
2. `R/run_duckdb_analysis.R` laedt die aktuellen Rohdaten in die DuckDB
3. `R/run_duckdb_overview_report.R` erzeugt nur den Bericht aus der DB
4. `R/run_duckdb_query.R` fuehrt einzelne SQL-Abfragen aus

## Dokumentierte Stellen im Projekt

- [docs/05_duckdb_lokale_auswertung.md](05_duckdb_lokale_auswertung.md)
- [docs/06_betriebsmanual_workflow.md](06_betriebsmanual_workflow.md)
- [docs/08_konfigurationsreferenz.md](08_konfigurationsreferenz.md)
- [sql/ddl/network_analysis_schema.sql](../sql/ddl/network_analysis_schema.sql)

