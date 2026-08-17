source("R/05_duckdb_analysis.R", local = TRUE)

bundle <- build_multirun_bundle()
load_multirun_bundle_into_duckdb(bundle)
