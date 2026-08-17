source("R/00_setup.R", local = TRUE)
source("R/01_inventory_report.R", local = TRUE)
source("R/m01_ping_tcp_probe.R", local = TRUE)
source("R/04_multirun_analysis.R", local = TRUE)

targets <- read_targets(file.path(paths$configs, "targets.localhost.csv"))
run_cfg <- read_run_config(file.path(paths$configs, "run.localhost.csv"))

message("Using localhost simulation target(s)")
run_benchmark(targets = targets, run_cfg = run_cfg)

bundle <- build_multirun_bundle()
write_multirun_outputs(bundle)
write_multirun_report(bundle, output_file = file.path(paths$reports, "network_overview_localhost.md"))

