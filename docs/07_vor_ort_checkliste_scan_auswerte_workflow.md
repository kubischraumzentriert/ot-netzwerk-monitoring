---
title: "Vor-Ort-Checkliste Scan-Auswerte-Workflow"
version: "1.0"
date: "2026-08-17"
project: "NetzwerkAnalyse"
purpose: "Kompakte Checkliste fuer Vor-Ort-Tests, Scans und Auswertung"
---

# Vor-Ort-Checkliste

Diese Checkliste ist fuer den Scan-Auswerte-Workflow gedacht:

- Anlage oder Testnetz vor Ort
- Inventur und Benchmark auf einem konfigurierbaren TCP-Port, Standard ist 9000, je Zielhost ist ein eigener Port moeglich
- optional Nmap, Wireshark, Suricata
- anschliessende Auswertung in R oder DuckDB

## Vor dem Anschluss

- [ ] Freigabe fuer den Test liegt vor
- [ ] Ziel ist klar: welche zwei Messlaeufe verglichen werden sollen (z. B.
  direkt vs. ueber Switch) oder lokaler Trockenlauf
- [ ] Relevante IPs und Hostnamen sind dokumentiert
- [ ] `configs/targets.csv` ist vorbereitet
- [ ] falls gebraucht: `configs/run.csv` ist fuer den jeweiligen Messlauf mit
  eigenem `session_tag` und `output_dir` angepasst
- [ ] unnoetige Netzwerkadapter sind identifiziert
- [ ] VPN, Wi-Fi und sonstige Fremdverbindungen sind ausgeschaltet
- [ ] nur der fuer den Test benoetigte Adapter ist aktiv
- [ ] `SECURITY.md` und `AGENTS.md` sind im Kopf

## Beim Aufbau

- [ ] Laptop mit dem Testnetz oder der Anlage verbinden
- [ ] korrekte IP-/Port-Kombination je Zielhost pruefen
- [ ] Gateway- und Routing-Situation kurz kontrollieren
- [ ] wenn ein Switch getestet wird, gleiche Geraete und je Zielhost die gleichen Ports behalten
- [ ] Laufzeitfenster festlegen
- [ ] Notizen zur Verkabelung und Reihenfolge machen

## Inventur

- [ ] optional: ARP-Cache fuer den freigegebenen lokalen `/24`-Bereich aktualisieren
- [ ] `powershell/inventory_collect.ps1` ausfuehren
- [ ] bei Bedarf `powershell/inventory_collect.ps1 -RefreshArpCidr 192.0.2.0/24`
  verwenden
- [ ] `powershell/run_inventory_steckbrief.ps1` ausfuehren
- [ ] Steckbrief auf Plausibilitaet pruefen
- [ ] Adapter, ARP, TCP und Route kurz ueberfliegen
- [ ] auffaellige offene Verbindungen notieren

## TCP-Port-Benchmark

- [ ] `powershell/run_benchmark.ps1` fuer den ersten Messlauf ausfuehren
- [ ] fuer den zweiten Messlauf `session_tag` und `output_dir` in
  `configs/run.csv` aendern und erneut ausfuehren, sonst gleiche
  Konfiguration
- [ ] fuer jeden Zielhost auf Erfolg, Latenz und Ausreisser achten
- [ ] die Session-Tags in `configs/run.localhost.csv` und `configs/run.csv`
  sauber und je Lauf unterschiedlich setzen
- [ ] Ergebnisse unter dem jeweiligen `output_dir`, z. B. `data/raw/direct/`
  und `data/raw/switch/`, ablegen

## Optionaler Netzwerkscan

- [ ] `powershell/run_nmap_scan.ps1` nur gegen die freigegebenen Ziele ausfuehren
- [ ] den jeweils freigegebenen Port je Zielhost und nur die benoetigten Hosts scannen
- [ ] Scan-Fenster kurz halten
- [ ] keine aggressiven Defaults verwenden

## Optionaler Mitschnitt

- [ ] vor dem Mitschnitt Interface mit `powershell/list_capture_interfaces.ps1`
  pruefen
- [ ] `powershell/start_wireshark_capture.ps1` nur im Testfenster starten
- [ ] `powershell/start_suricata_capture.ps1` nur passiv und freigegeben nutzen
- [ ] Mitschnitt auf den jeweils freigegebenen Port je Zielhost oder die drei Ziele begrenzen

## Nach dem Lauf

- [ ] Rohdaten liegen an den erwarteten Stellen
- [ ] Reports wurden geschrieben
- [ ] `R/run_benchmark_comparison.R --base=<tag1> --compare=<tag2>` mit den
  beiden verwendeten Session-Tags ausfuehren
- [ ] optional `R/run_duckdb_analysis.R` ausfuehren
- [ ] optional `R/run_duckdb_overview_report.R` ausfuehren
- [ ] Ergebnisse kurz gegen die Fragestellung pruefen
- [ ] wichtige Beobachtungen notieren
- [ ] keine Rohdaten ins Repo kopieren

## Kurzreihenfolge

1. Freigabe und Vorbereitung
2. Verbindung und Inventur
3. erster Messlauf
4. zweiter Messlauf
5. Vergleich
6. optional Scans und Mitschnitt
7. Auswertung und Ablage
