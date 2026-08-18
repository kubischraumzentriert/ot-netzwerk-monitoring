---
title: "08 konfigurationsreferenz"
output: "html"
---

# Konfigurationsreferenz

Diese Seite beschreibt die CSV-Dateien unter `configs/` und die Bedeutung
aller verwendeten Spalten und Schluessel.

## Uebersicht

- `configs/targets.csv` oder `configs/targets.example.csv`
- `configs/targets.localhost.csv`
- `configs/run.csv` oder `configs/run.example.csv`
- `configs/run.direct.csv` oder `configs/run.direct.example.csv`
- `configs/run.switch.csv` oder `configs/run.switch.example.csv`
- `configs/run.localhost.csv`
- `configs/scan_targets.csv` oder `configs/scan_targets.example.csv`
- `configs/duckdb_jdbc.example.csv`
- `sql/ddl/network_analysis_schema.sql`

## `configs/targets.csv`

Diese Datei beschreibt die Zielsysteme fuer Ping- und TCP-Tests.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer Reports, CSVs und Dateinamen | `Geraet1` | ja |
| `host` | IP-Adresse oder DNS-Name des Ziels | `192.0.2.11` | ja |
| `port` | TCP-Port fuer dieses Ziel; faellt bei leerem oder ungueltigem Wert auf `tcp_port` aus der Run-Config zurueck | `9000` | nein |
| `request` | Text, der beim TCP-Test an den Dienst gesendet wird | `HELLO` | nein |

Hinweise:

- Wenn `port` fehlt, verwendet der Benchmark den Default aus der Run-Config.
- Wenn `request` fehlt, wird `HELLO` gesendet.
- Diese Datei ist die normale Arbeitsdatei fuer reale Geraete.

## `configs/targets.localhost.csv`

Diese Datei ist die Trockenlauf-Variante fuer `127.0.0.1`.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer den Loopback-Test | `Loopback` | ja |
| `host` | Zielhost fuer die Simulation | `127.0.0.1` | ja |
| `port` | TCP-Port fuer den lokalen Echo-Server | `9000` | ja |
| `request` | Simulationspayload | `HELLO` | nein |

## `configs/run.csv` und `configs/run.example.csv`

Diese Datei enthaelt die allgemeinen Standardwerte fuer einen Benchmark-Lauf.
Sie wird verwendet, wenn kein anderer Run-Pfad uebergeben wird.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `ping_count` | Anzahl der Ping-Proben je Zielhost | `20` | ja |
| `ping_interval_sec` | Pause zwischen zwei Ping-Proben | `1` | ja |
| `tcp_count` | Anzahl der TCP-Proben je Zielhost | `20` | ja |
| `tcp_interval_sec` | Pause zwischen zwei TCP-Proben | `1` | ja |
| `tcp_timeout_sec` | Socket-Timeout fuer den TCP-Test | `3` | ja |
| `tcp_port` | Default-Port fuer Ziele ohne gueltige `port`-Angabe | `9000` | ja |
| `output_dir` | Basisordner fuer Rohdaten | `data/raw` | ja |
| `session_tag` | Laufbezeichnung; optional, wird bei Bedarf aus dem Ausgabeordner oder als `session` abgeleitet | `direct` | nein |

Hinweise:

- `tcp_port` ist der Rueckfallwert fuer Ziele ohne eigenen Port.
- `output_dir` ist nur der Basisordner; der Lauf kann darunter noch einen
  `session_tag`-Unterordner anlegen.
- `session_tag` ist fuer Vergleichslaeufe sehr hilfreich, aber nicht zwingend.

## `configs/run.direct.csv`

Diese Datei ist die Laufkonfiguration fuer den Direktlauf.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `ping_count` | Anzahl der Ping-Proben | `20` | ja |
| `ping_interval_sec` | Pause zwischen den Ping-Proben | `1` | ja |
| `tcp_count` | Anzahl der TCP-Proben | `20` | ja |
| `tcp_interval_sec` | Pause zwischen den TCP-Proben | `1` | ja |
| `tcp_timeout_sec` | TCP-Timeout | `3` | ja |
| `tcp_port` | Default-Port, wenn ein Ziel keinen eigenen Port hat | `9000` | ja |
| `session_tag` | Laufname fuer Auswertung und Ordnerstruktur | `direct` | ja |
| `output_dir` | Zielordner fuer Rohdaten | `data/raw/direct` | ja |

## `configs/run.switch.csv`

Diese Datei ist die Laufkonfiguration fuer den Switchlauf.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `ping_count` | Anzahl der Ping-Proben | `20` | ja |
| `ping_interval_sec` | Pause zwischen den Ping-Proben | `1` | ja |
| `tcp_count` | Anzahl der TCP-Proben | `20` | ja |
| `tcp_interval_sec` | Pause zwischen den TCP-Proben | `1` | ja |
| `tcp_timeout_sec` | TCP-Timeout | `3` | ja |
| `tcp_port` | Default-Port, wenn ein Ziel keinen eigenen Port hat | `9000` | ja |
| `session_tag` | Laufname fuer Auswertung und Ordnerstruktur | `switch` | ja |
| `output_dir` | Zielordner fuer Rohdaten | `data/raw/switch` | ja |

## `configs/run.localhost.csv`

Diese Datei ist die Laufkonfiguration fuer den lokalen Trockenlauf.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `ping_count` | Anzahl der Ping-Proben | `10` | ja |
| `ping_interval_sec` | Pause zwischen den Ping-Proben | `1` | ja |
| `tcp_count` | Anzahl der TCP-Proben | `10` | ja |
| `tcp_interval_sec` | Pause zwischen den TCP-Proben | `1` | ja |
| `tcp_timeout_sec` | TCP-Timeout | `3` | ja |
| `tcp_port` | Default-Port fuer die Simulation | `9000` | ja |
| `session_tag` | Laufname fuer den Trockenlauf | `localhost` | ja |
| `output_dir` | Zielordner fuer Rohdaten | `data/raw/sim` | ja |

## `configs/scan_targets.csv`

Diese Datei steuert die Nmap-Ziele.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer den Scan | `Geraet1` | ja |
| `host` | Zielhost fuer Nmap | `192.0.2.11` | ja |
| `ports` | Port oder Portliste, die an `nmap -p` uebergeben wird | `9000` oder `80,443,9000-9100` | nein |

Hinweise:

- Wenn `ports` leer ist, verwendet der Wrapper die Standardports aus dem Skript.
- Portlisten und Bereiche sind moeglich, weil der Wert direkt an Nmap uebergeben wird.

## `configs/duckdb_jdbc.example.csv`

Diese Datei dokumentiert die JDBC-Variante fuer DuckDB.
Sie ist nur relevant, wenn der native DuckDB-R-Weg nicht verwendet wird und du
die JDBC-Route mit `RJDBC` und `rJava` gehen willst.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `jar_path` | Pfad zum DuckDB-JDBC-JAR | `C:/Users/Andre/Downloads/duckdb_jdbc-1.5.5.0.jar` | ja |
| `db_path` | Lokale DuckDB-Datei | `data/processed/network_analysis.duckdb` | ja |
| `driver_class` | JDBC-Treiberklasse | `org.duckdb.DuckDBDriver` | ja |

## `sql/ddl/network_analysis_schema.sql`

Diese Datei beschreibt die DuckDB-Basisstruktur.

| Objekt | Bedeutung |
| --- | --- |
| `schema_metadata` | Metadaten zum Schema und zur Initialisierung |
| `inventory_sessions` | Verdichtete Inventur-Sessions mit interner `session_id` |
| `benchmark_rows` | Rohdaten der Ping- und TCP-Messungen mit interner `row_id` |
| `benchmark_summary` | Zusammenfassungen pro Session, Ziel und Probe mit interner `summary_id` |

Hinweise:

- Die Datei wird vom `init-database`-Schritt ausgefuehrt.
- Sie ist die referenzielle Wahrheit fuer die lokale DuckDB-Struktur.

## Typische Zuordnung

- `targets.csv` beschreibt die Kommunikationsziele.
- `run.*.csv` beschreibt Lauflaenge, Timeout, Default-Port und Session-Namen.
- `scan_targets.csv` beschreibt Nmap-Ziele und Ports.
- `duckdb_jdbc.example.csv` dokumentiert die optionale JDBC-Anbindung.
