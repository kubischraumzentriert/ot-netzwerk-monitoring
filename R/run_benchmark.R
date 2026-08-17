source("R/00_setup.R", local = TRUE)
source("R/m01_ping_tcp_probe.R", local = TRUE)

parse_benchmark_args <- function(args) {
  opts <- list(
    targets = file.path(paths$configs, "targets.csv"),
    run = file.path(paths$configs, "run.csv")
  )

  for (arg in args) {
    if (startsWith(arg, "--targets=")) {
      opts$targets <- sub("^--targets=", "", arg)
    } else if (startsWith(arg, "--run=")) {
      opts$run <- sub("^--run=", "", arg)
    }
  }

  opts
}

main <- function() {
  opts <- parse_benchmark_args(commandArgs(trailingOnly = TRUE))
  targets <- read_targets(opts$targets)
  run_cfg <- read_run_config(opts$run)
  run_benchmark(targets = targets, run_cfg = run_cfg)
}

invisible(main())
