source("R/04_multirun_analysis.R", local = TRUE)

bundle <- build_multirun_bundle()
write_multirun_outputs(bundle)
write_multirun_report(bundle)

