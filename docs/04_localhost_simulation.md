# Localhost Simulation

## Ziel

Die komplette Kette soll lokal gegen `127.0.0.1` durchgespielt werden:

- Inventur sammeln
- Steckbrief erzeugen
- Ping-Test
- TCP-Test auf Port 9000
- zusammenfassende Auswertung

## Warum das sinnvoll ist

Damit kannst du den Ablauf testen, ohne schon echte Geraete anzugreifen.

## Aufbau

1. lokaler TCP-Echo-Server auf `127.0.0.1:9000`
2. `inventory_collect.ps1`
3. `R/run_localhost_simulation.R`
4. `R/run_multirun_analysis.R`
5. optional DuckDB-Ladung

## Dateien

- `configs/targets.localhost.csv`
- `configs/run.localhost.csv`
- `powershell/start_local_tcp_echo_server.ps1`
- `powershell/run_localhost_workflow.ps1`
- `R/run_localhost_simulation.R`

