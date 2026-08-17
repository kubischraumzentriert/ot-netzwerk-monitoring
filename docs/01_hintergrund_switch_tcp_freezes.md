---
title: "01 hintergrund switch tcp freezes"
output: "html"
---

# Hintergrund: Freeze, Switch und TCP

## Worum es wahrscheinlich ging

Wenn ein PC mit drei Geraeten spricht und ein Programm dabei immer wieder einfriert, kann die Ursache im Netzwerk liegen, muss es aber nicht. Typische Netzwerkthemen sind:

- Paketverlust
- hohe Latenz
- kurzfristige Ueberlastung eines Switch-Ports oder einer Queue
- Duplex- oder Speed-Mismatch
- fehlerhafte Kabel, Stecker oder Ports
- Probleme auf der Gegenseite, etwa langsam antwortende Geraete oder ein ueberlasteter Server

## Was der Netzwerker vermutlich meinte

### Unterschiedliche Geschwindigkeiten

Wenn zwei Endpunkte oder ein Switch-Port unterschiedlich schnell arbeiten, kann der langsamere Teil zum Flaschenhals werden. Dann entstehen Warteschlangen im Switch oder im Endgeraet. Wenn diese Warteschlangen ueberlaufen, koennen Frames verworfen werden.

Ja, bei vielen Switches kann man die Geschwindigkeit und oft auch den Duplex-Modus pro Port einstellen. Typische Werte sind zum Beispiel:

- 10 Mbit/s
- 100 Mbit/s
- 1 Gbit/s
- manchmal 2.5/5/10 Gbit/s

Wichtig ist aber: In den meisten Faellen laeuft die Erkennung automatisch ueber `Auto-Negotiation`. Das ist normalerweise die beste Einstellung, solange beide Seiten sauber mitspielen.

### Speed und Duplex

Bei Ethernet gibt es zwei eng zusammenhaengende Themen:

- `Speed`: wie schnell der Port Daten uebertraegt
- `Duplex`: ob gleichzeitig gesendet und empfangen werden kann

Wenn Speed oder Duplex nicht sauber zusammenpassen, kann es zu massivem Fehlverhalten kommen. Ein klassischer Fehler ist ein Duplex-Mismatch. Dann siehst du oft:

- Kollisionen oder Fehlzaehlungen
- viele Retransmits
- schlechte Performance trotz scheinbar "aktiver" Verbindung
- Hänger, Zeitueberschreitungen oder sehr langsame Antwortzeiten

Deshalb ist es plausibel, dass ein falsch eingestellter Port oder ein falscher Aushandlungszustand in deinem Fall Probleme gemacht hat.

Wichtig: Ein Switch verliert nicht "TCP-Pakete" im TCP-Sinn. Auf Layer 2 gehen zuerst Ethernet-Frames verloren oder werden verworfen. TCP merkt das spaeter ueber:

- fehlende ACKs
- Retransmits
- steigende Latenz
- reduzierte Uebertragungsrate

### "Stack voll"

Mit "Stack voll" ist oft gemeint, dass Puffer im Netzwerkgeraet oder im Betriebssystem ueberlaufen. Das kann passieren bei:

- zu vielen Paketen in kurzer Zeit
- langsamer Verarbeitung auf einem Geraet
- Fehlern im Treiber oder in der Netzwerkkarte
- Mikrobursts, also sehr kurze Datenstoesse

## Was man am Switch konkret einstellen kann

Je nach Modell kannst du meist pro Port einstellen:

- `Auto-Negotiation` an oder aus
- feste Geschwindigkeit
- festen Duplex-Modus
- Flow Control
- manchmal Queue- oder QoS-Parameter

Fuer eine Fehlersuche ist wichtig:

- Wenn moeglich, beide Seiten gleich konfigurieren
- Nicht eine Seite auf fest und die andere auf Auto lassen, wenn es sich vermeiden laesst
- Nach Aenderungen die Port-Statistiken pruefen, zum Beispiel auf Errors, Drops oder CRC-Fehler

## Wie ich den Switch-Hinweis fachlich einschaetze

Ja, die Aussage des Netzwerkers ist fachlich sinnvoll, aber leicht verkuerzt:

- Nicht der Switch "verliert TCP-Pakete" direkt.
- Der Switch oder ein Port kann Frames droppen, puffern oder durch Fehlkonfiguration Probleme verursachen.
- TCP auf dem PC reagiert dann mit Wiederholungen und langsamerem Durchsatz.

Das heisst: Der Switch ist eine reale Ursache, aber nicht die einzige moegliche.

## Warum der Switch-Tausch nicht alles erklaert

Wenn nach der Anpassung der Geschwindigkeiten das Problem trotzdem wieder auftaucht, ist der Switch zwar weiterhin verdaechtig, aber nicht automatisch die Hauptursache. Dann kommen auch infrage:

- die drei Geraete selbst
- die Anwendung auf dem PC
- das Datenbanksystem
- die TCP-Anwendung auf Port 9000
- Kabel, Patchfeld, Netzwerkkarte, Treiber
- Broadcast-Stoerungen oder Last im Firmennetz

## Deine Idee fachlich bewertet

Dein Vorgehen ist gut, weil du es schrittweise und reproduzierbar machen willst:

1. direkt verbunden testen
2. dieselben Geraete nacheinander pruefen
3. Ping und TCP-Latenz messen
4. danach denselben Test mit Switch wiederholen
5. Ergebnisse vergleichen

Das ist genau die richtige Richtung, um zwischen Netzproblem und Applikationsproblem zu unterscheiden.

## Was ich daran verbessern wuerde

### 1. Nicht nur Ping messen

Ping ist gut fuer grobe Netzwerklatenz, aber nicht ausreichend. Du solltest mindestens erfassen:

- Antwortzeit pro Ping
- Paketverlust
- TCP-Verbindungsaufbauzeit auf Port 9000
- Antwortzeit einer echten Anfrage, falls das Protokoll bekannt ist

### 2. Test in einer sauberen Umgebung

Wenn moeglich:

- PC direkt mit einem einzelnen Geraet verbinden
- IP-Konfiguration statisch und eindeutig setzen
- kein Zugriff auf das Firmennetz waehrend des Tests

### 3. Messung wiederholen

Nicht nur einmal, sondern:

- mindestens mehrere Minuten pro Geraet
- mehrere Zyklen
- nach Moeglichkeit zu unterschiedlichen Lastzeiten

### 4. Ereignisse mitloggen

Zusatzlich zu Zeiten solltest du notieren:

- wann der Freeze auftrat
- ob die Anwendung hing oder nur langsam wurde
- ob Ping bereits Auffaelligkeiten zeigte
- ob TCP-Connects oder Datenantworten aussetzten

## Sinnvolle Hypothesen

Du kannst den Test so lesen:

- Wenn Ping stabil ist, aber die Anwendung einfriert, liegt es eher an Anwendung, Datenbank oder Protokoll.
- Wenn Ping schon Aussetzer oder hohe Jitter zeigt, liegt es eher im Netz oder am Geraet.
- Wenn nur Port 9000 schlecht reagiert, aber Ping stabil ist, liegt es vermutlich in der Anwendung oder im Dienst auf Port 9000.
- Wenn das Problem nur ueber den Switch auftritt, aber nicht direkt, ist der Switch oder dessen Konfiguration weiterhin sehr relevant.

## Meine Einschaetzung

Ja, dein Plan ist sinnvoll und gut als erster Diagnosepfad. Ich wuerde ihn aber erweitern um:

- strukturierte Messprotokolle
- direkte Gegenprobe ohne Switch
- TCP-Latenz und Antwortverhalten auf Port 9000
- Logging der Ergebnisse in CSV oder RDS
- Pruefung der Switch-Ports auf Speed, Duplex, Error-Counter und Drops

## Praktischer naechster Schritt

Im Repository liegt jetzt die erste R-Basis mit:

- Konfigurationsdateien fuer die drei Geraete
- Messskript fuer Ping und TCP
- Ausgabe nach CSV
- einfacher Ablauf fuer Direktverbindung und Switch-Vergleich
