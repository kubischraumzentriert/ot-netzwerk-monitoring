source("R/04_multirun_analysis.R", local = TRUE)

main <- function() {
  output_file <- file.path(paths$reports, "network_direct_vs_switch.md")
  write_benchmark_comparison_report(output_file = output_file)
}

invisible(main())
