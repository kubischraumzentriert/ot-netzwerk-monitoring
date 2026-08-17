source("R/04_multirun_analysis.R", local = TRUE)
source("R/02_duckdb.R", local = TRUE)
source("R/03_duckdb_jdbc.R", local = TRUE)

duckdb_native_available <- function() {
  requireNamespace("duckdb", quietly = TRUE) && requireNamespace("DBI", quietly = TRUE)
}

load_multirun_bundle_into_duckdb_native <- function(
  bundle = build_multirun_bundle(),
  db_path = file.path(paths$data_processed, "network_analysis.duckdb")
) {
  if (!duckdb_native_available()) {
    message("duckdb/DBI not available; skipping native DuckDB load.")
    return(invisible(FALSE))
  }

  con <- open_duckdb(db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  write_table <- function(name, df) {
    if (!is.data.frame(df) || !nrow(df)) return(invisible(NULL))
    DBI::dbWriteTable(con, name, df, overwrite = TRUE)
    invisible(TRUE)
  }

  write_table("inventory_sessions", bundle$inventory_sessions)
  write_table("benchmark_rows", bundle$benchmark_rows)
  write_table("benchmark_summary", bundle$benchmark_summary)

  message("Loaded multirun bundle into DuckDB: ", db_path)
  invisible(TRUE)
}

load_multirun_bundle_into_duckdb_jdbc <- function(
  bundle = build_multirun_bundle(),
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  if (!duckdb_jdbc_available()) {
    message("DBI/RJDBC/rJava not available; skipping DuckDB JDBC load.")
    return(invisible(FALSE))
  }

  con <- duckdb_jdbc_connect(db_path = db_path, jar_path = jar_path, driver_class = driver_class)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  write_table <- function(name, df) {
    if (!is.data.frame(df) || !nrow(df)) return(invisible(NULL))
    DBI::dbWriteTable(con, name, df, overwrite = TRUE)
    invisible(TRUE)
  }

  write_table("inventory_sessions", bundle$inventory_sessions)
  write_table("benchmark_rows", bundle$benchmark_rows)
  write_table("benchmark_summary", bundle$benchmark_summary)

  message("Loaded multirun bundle into DuckDB via JDBC: ", db_path)
  invisible(TRUE)
}

load_multirun_bundle_into_duckdb <- function(
  bundle = build_multirun_bundle(),
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  if (duckdb_native_available()) {
    return(load_multirun_bundle_into_duckdb_native(bundle = bundle, db_path = db_path))
  }
  if (duckdb_jdbc_available()) {
    return(load_multirun_bundle_into_duckdb_jdbc(bundle = bundle, db_path = db_path, jar_path = jar_path, driver_class = driver_class))
  }
  message("No DuckDB client available in this R session.")
  invisible(FALSE)
}
