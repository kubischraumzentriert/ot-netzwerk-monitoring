# Inventur, Auswertung und Werkzeuge

## Ziel

Am Anfang soll der PC lokal eine erste Netzwerkinventur machen. Die Ergebnisse werden als Rohdaten gespeichert und anschliessend in einen Markdown-Steckbrief ueberfuehrt.

## Was erfasst wird

- `arp` bzw. Neighbor-Tabelle
- `netstat` bzw. TCP-Verbindungen und Listeners
- Netzwerkschnittstellen
- IP-Konfiguration
- Host- und OS-Informationen

## Warum das hilfreich ist

Damit bekommst du einen schnellen Ist-Zustand:

- Welche Adapter sind aktiv?
- Welche Nachbarn sind sichtbar?
- Welche Prozesse halten welche Verbindungen?
- Gibt es unerwartete offene Ports?

## DuckDB als Auswertungsschicht

Ja, DuckDB ist dafuer sehr gut geeignet.

### Vorteile

- lokale Datei statt Serverbetrieb
- sehr gut fuer CSV- und Parquet-Auswertung
- einfach fuer spaetere Benchmarks und Zeitvergleiche
- mehrere Anlagen, mehrere Sessions, ein gemeinsames Schema

### Sinnvolle Nutzung

Rohdaten bleiben als CSVs erhalten.
DuckDB wird dann fuer Auswertungen benutzt, zum Beispiel:

- Inventuren pro Anlage
- Zeitreihen von Ping- und TCP-Messungen
- Vergleich zwischen direkter Verbindung und Switch
- Vergleich verschiedener Geraete oder Anlagen

### Praktische Empfehlung

Wir bauen es so auf:

1. Rohdaten als CSV sammeln
2. R schreibt daraus einen Steckbrief als Markdown
3. optional: Daten in DuckDB laden
4. spaeter Benchmarks und Vergleiche in R oder SQL auswerten

### Zwei moegliche R-Wege

- Nativer DuckDB-R-Client ueber das `duckdb`-Paket
- JDBC ueber `RJDBC`, `rJava` und das JAR `duckdb_jdbc-1.5.5.0.jar`

Wenn du bereits das JDBC-JAR heruntergeladen hast, koennen wir den JDBC-Weg direkt nutzen.
Der Standard-Flow fuer das Projekt bleibt trotzdem: CSV sammeln, Markdown erzeugen, dann optional in DuckDB laden.

## Wie du Wireshark, Nmap, ZAP und Suricata sinnvoll nutzt

### Nmap

Sehr sinnvoll fuer:

- Host-Discovery
- Port-Scans
- Service-Erkennung
- Vergleich vor und nach Switch-Wechsel

Gut fuer OT-Umgebungen:

- vorsichtige Scans mit klarer Zielauswahl
- keine aggressiven Defaults
- kleine, kontrollierte Testfenster

### Wireshark

Sehr sinnvoll fuer:

- echte Paketaufzeichnung
- Analyse von Retransmits, Latenz, ACKs
- Vergleich der Kommunikation direkt vs. ueber Switch
- Sicht auf Port 9000, TCP-Retransmits und Antwortmuster

Gut als Naechstes:

- kurze Mitschnitte waehrend eines Freezes
- Filter auf die drei Geraete und Port 9000

### Suricata

Sinnvoll fuer:

- passives IDS/IPS-Logging
- Erkennung auffaelliger Muster
- Langzeitbeobachtung waehrend Tests

Wichtig:

- erst passiv einsetzen
- in OT-Umgebungen nur mit Vorsicht und klarer Freigabe

### ZAP

ZAP ist eher fuer Webanwendungen sinnvoll.

Wenn dein Programm oder eine zugehoerige Bedienoberflaeche HTTP oder HTTPS nutzt, kann ZAP helfen bei:

- Web-Requests
- API-Calls
- Schwachstellen in Webschnittstellen

Wenn dein Port 9000 kein Webdienst ist, ist ZAP eher zweitrangig.

## Empfohlene Reihenfolge

1. lokale Inventur
2. Ping- und TCP-Benchmark
3. Wireshark-Mitschnitt bei Auffaelligkeiten
4. Nmap fuer strukturierte Port- und Host-Pruefung
5. Suricata fuer passives Dauer-Monitoring
6. ZAP nur, wenn eine Weboberflaeche beteiligt ist
