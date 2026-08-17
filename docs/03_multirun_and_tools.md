# Mehrlaeufige Auswertung und Tool-Workflow

## Reihenfolge

1. Inventur sammeln
2. Inventur als Markdown zusammenfassen
3. mehrere Sessions und Benchmarks gemeinsam auswerten
4. auffaellige Faelle mit Nmap, Wireshark und Suricata vertiefen
5. Ergebnisse optional in DuckDB laden

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

