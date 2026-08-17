# Security and Publication Notes

This repository is intended to stay free of sensitive operational data.

## Do not commit

- real IP addresses or hostnames from production or customer networks
- packet captures, logs, scans, or exports from real systems
- secrets, credentials, tokens, API keys, or certificates
- local analysis outputs under `data/` or `reports/`

## Public repo rules

- keep `configs/*.csv` generic and example-based
- use placeholder addresses such as TEST-NET documentation ranges
- store raw data only on the local workstation
- review `.gitignore` before adding new tooling or output folders

## If in doubt

Assume the artifact is local-only unless it is clearly a reusable script,
template, or document.
