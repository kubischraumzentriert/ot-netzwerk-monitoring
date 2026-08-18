---
title: "inventory steckbrief"
output: "html_document"
---

# Netzwerk-Steckbrief Vorlage

## Kopf

- Computer:
- Erfasst am:
- Session:

## Kurzueberblick

- Netzwerkadapter:
- ARP/Neighbor-Eintraege:
- TCP-Verbindungen:
- Listening-Ports:

## Adapter aus ipconfig

| adapter | description | media_state | ipv4 | mac | has_dhcp |
| --- | --- | --- | --- | --- | --- |

## Nachbarn / ARP

| ip | mac | type |
| --- | --- | --- |

## TCP-Verbindungen

| protocol | local_address | foreign_address | state | pid |
| --- | --- | --- | --- | --- |

## Hinweis

Diese Vorlage wird durch `R/run_inventory_steckbrief.R` automatisch aus der
zuletzt erfassten Session oder aus einer angegebenen Session erzeugt.

