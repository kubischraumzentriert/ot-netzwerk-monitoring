---
title: "14 renv und abhaengigkeiten"
output: "html_document"
---

# `renv` und Abhaengigkeiten

## Zweck

Dieses Projekt nutzt `renv`, um die R-Abhaengigkeiten fuer Git nachvollziehbar
und reproduzierbar zu halten.

Die Idee ist einfach:

- `renv.lock` wird versioniert
- die lokale Paketbibliothek und der Cache bleiben unversioniert
- auf einem neuen Rechner kann das Projekt mit `renv::restore()` wieder in
  denselben Paketstand gebracht werden

## Was ins Git gehoert

- `renv.lock`
- `renv/activate.R`
- `renv/settings.json`
- `.Rprofile`

## Was lokal bleibt

- `renv/library/`
- `renv/cache/`

Diese Ordner sind in `.gitignore` ausgeschlossen.

## Wozu ist das gut?

Ohne `renv` koennen sich Abhaengigkeiten still veraendern, zum Beispiel durch:

- neue Paketversionen
- andere Installationen auf einem zweiten Rechner
- gemischte R-Umgebungen mit mehreren Libraries

Mit `renv` sieht das Projekt auf jedem Rechner klarer aus:

- dieselben Paketversionen
- nachvollziehbare Lockfile
- einfacherer Wiederaufbau auf einem Stick oder im Git-Clone

## Aktueller Stand

Die wichtigsten Pakete des Projekts sind in der Lockfile erfasst, darunter
unter anderem:

- `DBI`
- `duckdb`
- `readr`
- `rJava`
- `RJDBC`

Fuer die neue Webapp-Zeitmessung sind aktuell keine zusaetzlichen R-Pakete
noetig, weil sie auf Basis-R-Funktionen aufsetzt.

## Tuer-auf-Tuer-Workflow

### Auf einem frischen Rechner

```r
renv::restore()
```

### Wenn bewusst neue Pakete hinzugekommen sind

```r
renv::snapshot(prompt = FALSE)
```

## Praktische Hinweise

- Die Lockfile sollte nach Aenderungen am R-Code mitgepflegt werden
- Der Cache gehoert nicht ins Repo
- Wenn du spaeter die portable Webapp-Variante ausbaust, bleibt `renv` der
  gemeinsame Nenner fuer die Paketversionen

## Einordnung fuer dieses Projekt

- fuer die Webapp-Messung reicht Base-R
- fuer die DuckDB- und Auswertungswege sind Paketabhaengigkeiten relevant
- deshalb ist `renv` im Hauptrepo sinnvoller als nur im Stick-Ordner

