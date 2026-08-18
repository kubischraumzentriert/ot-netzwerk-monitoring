---
title: "Betriebsmanual NetzwerkAnalyse Workflow"
version: "1.0"
date: "2026-08-17"
project: "NetzwerkAnalyse"
purpose: "Vor-Ort-Workflow fuer Inventur, konfigurierbare TCP-Port-Tests auf einem oder mehreren Ports pro Zielhost, Direkt-vs-Switch-Vergleich und Auswertung"
---

# Betriebsmanual Workflow

## Zweck

Dieses Manual beschreibt den lokalen Ablauf fuer einen Laptop an einer Anlage
oder an drei vernetzten Geraeten. Ziel ist:

- den Ist-Zustand der Kommunikation zu erfassen
- einen konfigurierbaren TCP-Port gegen die Geraete zu messen, Standard ist 9000, wobei jeder Zielhost einen eigenen Port haben kann
- einen Vergleich zwischen direkter Verbindung und Switch zu erzeugen
- die Ergebnisse als Markdown und optional in DuckDB abzulegen

Fuer die schnelle Abarbeitung vor Ort nutze zusaetzlich die
[Vor-Ort-Checkliste](07_vor_ort_checkliste_scan_auswerte_workflow.md).

## Kann ich den Laptop an die Anlage haengen?

Ja, das ist der vorgesehene Arbeitsmodus, wenn du es kontrolliert aufbaust.

Wichtig ist dabei:

- nur einen aktiven Netzwerkpfad verwenden
- Wi-Fi, VPN und andere nicht benoetigte Adapter vor dem Test deaktivieren
- keine Bruecke zum Firmennetz offen lassen, wenn du ein isoliertes Testnetz willst
- vor dem Test mit dem Betreiber bzw. Netzwerker klaeren, dass der Test erlaubt ist
- bei produktionsnahen Geraeten zuerst mit einer kurzen, vorsichtigen Laufzeit starten

Wenn du den Test gegen die reale Anlage machst, wuerde ich ihn zuerst ohne Nmap
und ohne Suricata starten und nur die Inventur plus TCP-Port-Benchmark auf mehreren Ports pro Zielhost laufen
lassen. Die passiven Werkzeuge kannst du danach dazunehmen.

## Ablaufdiagramm

```mermaid
flowchart TD
  A["powershell/run_localhost_workflow.ps1"] --> B["powershell/run_init_database.ps1"]
  B --> C["R/run_init_database.R"]
  C --> D["sql/ddl/network_analysis_schema.sql"]
  D --> E["data/processed/network_analysis.duckdb"]
  A --> F["inventory_collect.ps1"]
  F --> G["R/run_localhost_simulation.R"]
  G --> H["R/run_benchmark.R"]
  H --> I["R/run_multirun_analysis.R"]
  I --> J["R/run_duckdb_analysis.R"]
  J --> K["reports/network_overview_duckdb.md"]
```

Der lokale Trockenlauf ruft also zuerst die Datenbank-Initialisierung auf und
laedt danach die Mess- und Inventurdaten in dieselbe lokale DuckDB-Datei.
Fuer einen kompakten reinen Trockenlauf sieh auch
[docs/04_localhost_simulation.md](04_localhost_simulation.md).

## Vorbereitung

### 1. Projektpfad

Arbeite aus dem Projektordner:

`C:\Users\Andre\Documents\ChatGPT\NetzwerkAnalyse`

### 2. R-Pfad

In diesem Projekt wird R direkt aus
`C:\Program Files\R\R-4.5.3\bin\Rscript.exe`
aufgerufen.

### 3. Inventur

Es gibt keine Pflichtkonfiguration fuer die Inventur.
Der Wrapper schreibt automatisch:

- `ipconfig /all`
- `netsh interface show interface`
- `arp -a`
- `netstat -ano`
- `route print`

### 4. Benchmark-Konfiguration

Die relevanten Dateien sind:

- `configs/targets.csv`
- `configs/run.localhost.csv` fuer den Trockenlauf
- `configs/run.direct.example.csv`
- `configs/run.switch.example.csv`

Fuer echte Tests kannst du die Beispieldateien nach
`configs/run.direct.csv` und `configs/run.switch.csv`
kopieren oder direkt die Beispiel-Dateien uebergeben.

`session_tag` traegst du in der jeweiligen Run-Config ein:

- `configs/run.localhost.csv` fuer den Trockenlauf, zum Beispiel `localhost`
- `configs/run.direct.csv` oder `configs/run.direct.example.csv`, zum Beispiel `direct`
- `configs/run.switch.csv` oder `configs/run.switch.example.csv`, zum Beispiel `switch`

Die vollstaendige Beschreibung aller CSV-Spalten steht in
[docs/08_konfigurationsreferenz.md](08_konfigurationsreferenz.md).
Fuer einen schnellen Vor-Ort-Ueberblick nutze
[docs/09_konfigurations_spickzettel.md](09_konfigurations_spickzettel.md).

### 5. Nmap-Konfiguration

Fuer Nmap kannst du die Ziele in
`configs/scan_targets.example.csv`
anpassen und spaeter als `configs/scan_targets.csv`
verwenden.
Eine fachliche Einordnung der wichtigsten Nmap-Optionen fuer OT-Netze steht in
[docs/10_nmap_optionen_ot.md](10_nmap_optionen_ot.md).

## Empfohlene Reihenfolge

### Phase A: Trockenlauf

1. `powershell/run_localhost_workflow.ps1`
2. `R/run_duckdb_overview_report.R`
3. `R/run_benchmark_comparison.R`

Damit pruefst du, ob der komplette Werkzeugpfad lokal funktioniert. Der
Workflow-Wrapper ruft dabei zuerst `powershell/run_init_database.ps1` auf, das
seinerseits `R/run_init_database.R` startet.

### Phase B: Vor-Ort-Inventur

1. Laptop an das Testnetz oder an die Anlage anschliessen
2. nicht benoetigte Netzwerkadapter deaktivieren
3. `powershell/inventory_collect.ps1`
4. `powershell/run_inventory_steckbrief.ps1`

Ergebnis:

- Rohdaten in `data/raw/inventory/<timestamp>/`
- Markdown-Steckbrief in `reports/`

### Phase C: Direktlauf ohne Switch

1. Geraete direkt nacheinander mit dem Laptop verbinden
2. `configs/run.direct.csv` oder `configs/run.direct.example.csv` verwenden
3. `powershell/run_benchmark.ps1`

Ergebnis:

- Ping- und TCP-Rohdaten in `data/raw/direct/<timestamp>_*.csv`
- spaeter auswertbar in R und DuckDB

### Phase D: Lauf mit Switch

1. Switch zwischenschalten
2. dieselben Zieladressen und bei Bedarf pro Zielhost unterschiedliche TCP-Ports verwenden
3. `configs/run.switch.csv` oder `configs/run.switch.example.csv` verwenden
4. erneut `powershell/run_benchmark.ps1`

Ergebnis:

- Ping- und TCP-Rohdaten in `data/raw/switch/<timestamp>_*.csv`

### Phase E: Vergleich

1. `powershell/run_benchmark_comparison.ps1`
2. optional `R/run_multirun_analysis.R`
3. optional `R/run_duckdb_analysis.R`
4. optional `R/run_duckdb_overview_report.R`

Ergebnis:

- `reports/network_direct_vs_switch.md`
- `reports/network_overview.md`
- `reports/network_overview_duckdb.md`
- `reports/duckdb_analysis_overview.md`

## Was du in den Dateien einstellen musst

### `configs/targets.csv`

Hier trägst du die drei Geraete ein:

- `label`
- `host`
- `port`
- optional `request`

### `configs/targets.production.example.csv`

Diese Datei ist die generische Vorlage fuer reale Zielgeraete, wenn du eine
saubere Startbasis fuer eine Anlage anlegen willst.

- dieselben Spalten wie `targets.csv`
- nur Platzhalter-Adressen aus dem Dokumentationsnetz
- gedacht zum Kopieren nach `configs/targets.csv` oder als Referenz fuer neue Projekte

### `configs/run.direct.csv` oder `configs/run.switch.csv`

Hier stellst du die Messlaenge ein:

- `ping_count`
- `tcp_count`
- `ping_interval_sec`
- `tcp_interval_sec`
- `tcp_timeout_sec`
- `tcp_port`
- `session_tag`
- `output_dir`

Empfehlung fuer den Start:

- `ping_count = 20`
- `tcp_count = 20`
- `tcp_port = 9000` als Standardwert, aber jeder freigegebene Port pro Zielhost ist moeglich
- `session_tag = direct`, `switch` oder `localhost`

### `configs/scan_targets.csv`

Hier bestimmst du, ob und welche Hosts mit Nmap gescannt werden.

## Startskripte

### Inventur

```powershell
powershell\inventory_collect.ps1
powershell\run_inventory_steckbrief.ps1
```

### Benchmark

```powershell
powershell\run_benchmark.ps1
powershell\run_benchmark_comparison.ps1
```

### Nmap

```powershell
powershell\run_nmap_scan.ps1
```

### Mitschnitt

```powershell
powershell\list_capture_interfaces.ps1
powershell\start_wireshark_capture.ps1
powershell\start_suricata_capture.ps1
```

### DuckDB

```powershell
Rscript R/run_init_database.R
Rscript R/run_duckdb_analysis.R
Rscript R/run_duckdb_query.R sql\inventory_overview.sql
Rscript R/run_duckdb_overview_report.R
```

### Archivieren und Zuruecksetzen

```powershell
powershell\archive_data_backup.ps1
powershell\restore_data_backup.ps1
```

Das legt einen Zeitstempel-Ordner unter `data/backups/` an, sichert `data/raw/`,
`data/processed/` und `reports/` und leert danach den Arbeitsbestand.
`powershell\archive_data_backup.ps1 -WhatIf` zeigt die geplanten Aktionen,
ohne etwas zu veraendern. Mit `powershell\restore_data_backup.ps1` kannst du
das letzte oder ein explizites Backup wiederherstellen.

## Praktischer Ablauf vor Ort

Wenn du nur wenig Zeit hast, dann wuerde ich so vorgehen:

1. Inventur sammeln
2. Steckbrief schreiben
3. Direktlauf messen
4. Switch-Lauf messen
5. Vergleichsreport erzeugen
6. erst danach Nmap oder Mitschnitt aktivieren

## Optionaler Feinschliff

Wenn das Programm auf einem bestimmten Port besonders kritisch ist, kannst du den Test
so weiter schärfen:

- laengere Messreihe, aber niedrige Frequenz
- einen kurzen Mitschnitt mit Wireshark waehrend der TCP-Probe
- Nmap nur fuer die drei bekannten Ziele
- Suricata nur passiv und nur im Testfenster

## Ergebnisdateien

Typische Ausgaben sind:

- `data/raw/inventory/<timestamp>/`
- `data/raw/direct/<timestamp>_*.csv`
- `data/raw/switch/<timestamp>_*.csv`
- `reports/steckbrief_*.md`
- `reports/network_overview.md`
- `reports/network_direct_vs_switch.md`
- `reports/network_overview_duckdb.md`
- `reports/duckdb_analysis_overview.md`

## Kurzfazit

Ja, du kannst den Laptop an die Anlage anschliessen und den Workflow
durchlaufen lassen, wenn du ihn kontrolliert und isoliert aufbaust.
Der empfohlene Start ist:

1. Inventur
2. Steckbrief
3. Direktlauf
4. Switchlauf
5. Vergleich
