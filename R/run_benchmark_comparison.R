source("R/04_multirun_analysis.R", local = TRUE)

parse_comparison_args <- function(args) {
  opts <- list(
    out = file.path(paths$reports, "network_direct_vs_switch.md"),
    base = NULL,
    compare = NULL
  )

  for (arg in args) {
    if (startsWith(arg, "--out=")) {
      opts$out <- sub("^--out=", "", arg)
    } else if (startsWith(arg, "--base=")) {
      opts$base <- sub("^--base=", "", arg)
    } else if (startsWith(arg, "--compare=")) {
      opts$compare <- sub("^--compare=", "", arg)
    }
  }

  opts
}

main <- function() {
  opts <- parse_comparison_args(commandArgs(trailingOnly = TRUE))
  write_benchmark_comparison_report(
    output_file = opts$out,
    base_tag = opts$base,
    compare_tag = opts$compare
  )
}

invisible(main())
