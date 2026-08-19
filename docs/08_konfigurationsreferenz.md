---
title: "08 konfigurationsreferenz"
output: "html_document"
---

# Konfigurationsreferenz

Diese Seite beschreibt die CSV-Dateien unter `configs/` und die Bedeutung
aller verwendeten Spalten und Schluessel.

## Grundregel fuer private Dateien

Dateien mit dem Suffix `*.private.csv` sind in diesem Projekt als lokale
Arbeitsdateien gedacht:

- sie enthalten reale Anlagenadressen oder lokale Tool-Pfade
- sie bleiben ueber `.gitignore` lokal
- sie werden nicht ins GitHub-Repo gepusht

Beispiele:

- `configs/targets.private.csv`
- `configs/tools.private.csv`

## Uebersicht

- `configs/targets.csv` oder `configs/targets.example.csv`
- `configs/targets.private.csv`
- `configs/targets.production.example.csv`
- `configs/targets.localhost.csv`
- `configs/run.csv` oder `configs/run.example.csv`
- `configs/run.webapp.csv` oder `configs/run.webapp.example.csv`
- `configs/run.localhost.csv`
- `configs/scan_targets.csv` oder `configs/scan_targets.example.csv`
- `configs/webapp_targets.example.csv`, optional lokal `configs/webapp_targets.private.csv`
- `configs/tools.example.csv`, optional lokal `configs/tools.csv` oder
  `configs/tools.private.csv`
- `configs/duckdb_jdbc.example.csv`
- `sql/ddl/network_analysis_schema.sql`

## `configs/targets.csv`

Diese Datei ist die generische Zielvorlage fuer Ping- und TCP-Tests.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer Reports, CSVs und Dateinamen | `Geraet1` | ja |
| `host` | IP-Adresse oder DNS-Name des Ziels | `192.0.2.11` | ja |
| `port` | TCP-Port fuer dieses Ziel; faellt bei leerem oder ungueltigem Wert auf `tcp_port` aus der Run-Config zurueck | `9000` | nein |
| `request` | Text, der beim TCP-Test an den Dienst gesendet wird | `HELLO` | nein |

Hinweise:

- Wenn `port` fehlt, verwendet der Benchmark den Default aus der Run-Config.
- Wenn `request` fehlt, wird `HELLO` gesendet.
- `target_port` wird fuer die TCP-Messung gesetzt; bei Ping-Zeilen bleibt
  dieser Wert `NA`.
- Diese Datei ist die normale Arbeitsdatei fuer generische Vorlagen.

## `configs/targets.private.csv`

Diese Datei ist die lokale, ignorierte Arbeitsdatei fuer reale Zieladressen.
Wenn sie existiert, verwenden die Run-Skripte und R-Defaults sie bevorzugt.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer Reports, CSVs und Dateinamen | `Geraet#1` | ja |
| `host` | IP-Adresse oder DNS-Name des Ziels | `172.18.181.140` | ja |
| `port` | TCP-Port pro Zielhost | `9000` | nein |
| `request` | Text, der beim TCP-Test an den Dienst gesendet wird | `HELLO` | nein |

Hinweise:

- Diese Datei gehoert in `.gitignore`.
- Sie ist fuer reale Zielsysteme gedacht, die nicht ins Repo sollen.

## `configs/targets.production.example.csv`

Diese Datei ist die generische Vorlage fuer reale Anlagenziele.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer Reports, CSVs und Dateinamen | `PLC_1` | ja |
| `host` | IP-Adresse oder DNS-Name des Ziels | `192.0.2.21` | ja |
| `port` | TCP-Port pro Zielhost | `9000` | nein |
| `request` | Text, der beim TCP-Test an den Dienst gesendet wird | `HELLO` | nein |

Hinweise:

- Die Datei ist nur eine Vorlage und sollte fuer echte Anlagen vor dem Einsatz
  nach `configs/targets.csv` oder in eine projektspezifische Arbeitsdatei
  uebertragen werden.
- Platzhalter-Adressen aus dem Dokumentationsnetz bleiben bewusst generisch.

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
| `timezone` | optionale Zeitzone fuer Lauf und Rohdaten; empfohlen `UTC` | `UTC` | nein |
| `output_dir` | Basisordner fuer Rohdaten | `data/raw` | ja |
| `session_tag` | Laufbezeichnung; optional, wird bei Bedarf aus dem Ausgabeordner oder als `session` abgeleitet | `direct` | nein |

Hinweise:

- `tcp_port` ist der Rueckfallwert fuer Ziele ohne eigenen Port.
- `output_dir` ist nur der Basisordner; der Lauf kann darunter noch einen
  `session_tag`-Unterordner anlegen.
- `session_tag` ist fuer Vergleichslaeufe sehr hilfreich, aber nicht zwingend.
- Fuer einen Vergleich zweier Messlaeufe (z. B. Direktverbindung gegen
  Switch) fuehrst du `configs/run.csv` zweimal mit unterschiedlichem
  `session_tag` und `output_dir` aus, zum Beispiel `session_tag=direct` /
  `output_dir=data/raw/direct` und danach `session_tag=switch` /
  `output_dir=data/raw/switch`. Es gibt keine dedizierten Config-Dateien pro
  Szenario mehr, `configs/run.example.csv` ist die einzige Vorlage.

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

## `configs/run.webapp.csv` und `configs/run.webapp.example.csv`

Diese Datei ist die Laufkonfiguration fuer die Webapp-Zeitmessung.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `sample_count` | Anzahl der Messungen pro Ziel | `60` | ja |
| `interval_sec` | Pause zwischen zwei Webapp-Samples | `60` | ja |
| `timeout_sec` | Socket-Timeout fuer den HTTP-Request | `5` | ja |
| `method` | HTTP-Methode, standardmaessig `HEAD` | `HEAD` | nein |
| `timezone` | optionale Zeitzone fuer Lauf und Rohdaten; empfohlen `UTC` | `UTC` | nein |
| `session_tag` | Laufname fuer Auswertung und Ordnerstruktur | `webapp` | ja |
| `output_dir` | Zielordner fuer Rohdaten | `data/raw/webapp` | ja |

Hinweise:

- `interval_sec` ist die Standardpause fuer alle Ziele.
- Ein Ziel kann `interval_sec` und `timeout_sec` auf Zeilenebene ueberschreiben.
- Die erste Version arbeitet absichtlich leichtgewichtig und sendet nur einen
  HTTP-Request pro Probe.

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

## `configs/tools.example.csv`

Diese Datei dokumentiert die lokale Tool-Aufloesung fuer die PowerShell-Wrapper.
Versioniert wird nur die Beispiel-Datei; echte lokale Pfade gehoeren in
`configs/tools.csv` oder `configs/tools.private.csv` und bleiben ignoriert.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `tool` | Tool-Schluessel fuer den Wrapper | `rscript`, `nmap`, `tshark`, `suricata` | ja |
| `path` | optionaler lokaler Pfad zur EXE | `%USERPROFILE%\Programme\R\R-4.5.2\bin\Rscript.exe` | nein |
| `note` | kurzer Hinweis fuer Menschen | `lokale R-Installation` | nein |

Suchreihenfolge:

1. expliziter Script-Parameter
2. `configs/tools.private.csv`, dann `configs/tools.csv`, dann `configs/tools.example.csv`
3. `PATH` ueber `Get-Command`
4. bekannte Windows-Installationspfade

## `configs/webapp_targets.example.csv`

Diese Datei beschreibt die Webapp-Ziele fuer die Zeitmessung.

| Spalte | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `label` | Anzeigename fuer den Report | `WebApp` | ja |
| `url` | komplette Ziel-URL | `http://127.0.0.1:8080/health` | ja |
| `method` | HTTP-Methode, empfohlen `HEAD` | `HEAD` | nein |
| `interval_sec` | optionaler Ziel-Override fuer das Intervall | `60` | nein |
| `timeout_sec` | optionaler Ziel-Override fuer den Timeout | `5` | nein |

Hinweise:

- reale Ziel-URLs gehoeren in `configs/webapp_targets.private.csv`
- die Messung ist fuer `http://`-Ziele ausgelegt
- wenn du nur eine Webapp beobachten willst, reicht ein einzelner Eintrag

## `configs/duckdb_jdbc.example.csv`

Diese Datei dokumentiert die JDBC-Variante fuer DuckDB.
Sie ist nur relevant, wenn der native DuckDB-R-Weg nicht verwendet wird und du
die JDBC-Route mit `RJDBC` und `rJava` gehen willst.

| Schluessel | Bedeutung | Beispiel | Pflicht |
| --- | --- | --- | --- |
| `jar_path` | Pfad zum DuckDB-JDBC-JAR | `C:/Pfad/zu/duckdb_jdbc-1.5.5.0.jar` | ja |
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

- `targets.csv` beschreibt die generische Zielvorlage.
- `targets.private.csv` beschreibt lokale reale Zielsysteme.
- `targets.production.example.csv` ist die Vorlage fuer reale Zielsysteme.
- `run.*.csv` beschreibt Lauflaenge, Timeout, Default-Port und Session-Namen.
- `scan_targets.csv` beschreibt Nmap-Ziele und Ports.
- `tools.example.csv` beschreibt die optionale lokale Tool-Pfad-Konfiguration.
- `duckdb_jdbc.example.csv` dokumentiert die optionale JDBC-Anbindung.

