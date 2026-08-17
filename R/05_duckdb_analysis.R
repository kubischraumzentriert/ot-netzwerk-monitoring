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

duckdb_table_counts <- function(
  db_path = file.path(paths$data_processed, "network_analysis.duckdb")
) {
  if (!dbi_available()) {
    return(data.frame())
  }
  if (!file.exists(db_path)) {
    return(data.frame())
  }

  con <- open_duckdb(db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  tables <- DBI::dbListTables(con)
  if (!length(tables)) {
    return(data.frame())
  }

  rows <- lapply(tables, function(tbl) {
    count_sql <- paste0('SELECT COUNT(*) AS n_rows FROM "', tbl, '"')
    n_rows <- tryCatch(
      as.integer(DBI::dbGetQuery(con, count_sql)$n_rows[1]),
      error = function(e) NA_integer_
    )
    data.frame(table_name = tbl, rows = n_rows, stringsAsFactors = FALSE)
  })

  do.call(rbind, rows)
}

write_duckdb_report <- function(
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  output_file = file.path(paths$reports, "network_overview_duckdb.md")
) {
  counts <- duckdb_table_counts(db_path)
  if (!nrow(counts)) {
    md <- c(
      "# DuckDB Analyse Uebersicht",
      "",
      "Keine DuckDB-Datei oder keine Tabellen gefunden."
    )
    writeLines(md, output_file, useBytes = TRUE)
    return(output_file)
  }

  counts <- counts[order(counts$table_name), , drop = FALSE]
  total_rows <- sum(counts$rows, na.rm = TRUE)

  md <- c(
    "# DuckDB Analyse Uebersicht",
    "",
    paste0("- Datenbank: ", db_path),
    paste0("- Tabellen: ", nrow(counts)),
    paste0("- Zeilen gesamt: ", total_rows),
    "",
    "## Tabellen",
    "",
    fmt_md_table(counts, max_rows = 100),
    "",
    "## Naechste Schritte",
    "",
    "- bei Bedarf weitere Rohdaten als Tabellen aufnehmen",
    "- SQL-Abfragen fuer Vergleichswerte anlegen",
    "- DuckDB als lokales Archiv fuer mehrere Anlagen nutzen"
  )

  writeLines(md, output_file, useBytes = TRUE)
  output_file
}

refresh_duckdb_analysis <- function(
  bundle = build_multirun_bundle(),
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  output_file = file.path(paths$reports, "network_overview_duckdb.md"),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  loaded <- load_multirun_bundle_into_duckdb(
    bundle = bundle,
    db_path = db_path,
    jar_path = jar_path,
    driver_class = driver_class
  )
  if (!isTRUE(loaded)) {
    return(invisible(FALSE))
  }
  write_duckdb_report(db_path = db_path, output_file = output_file)
  message("Wrote DuckDB analysis report: ", output_file)
  invisible(TRUE)
}

duckdb_query <- function(
  sql,
  db_path = file.path(paths$data_processed, "network_analysis.duckdb")
) {
  sql <- paste(sql, collapse = "\n")
  if (!nzchar(trimws(sql))) {
    stop("SQL statement is empty")
  }

  if (!dbi_available() || !file.exists(db_path)) {
    stop("DuckDB database not available: ", db_path)
  }

  con <- open_duckdb(db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbGetQuery(con, sql)
}

duckdb_write_query_result <- function(
  sql,
  output_file,
  db_path = file.path(paths$data_processed, "network_analysis.duckdb")
) {
  result <- duckdb_query(sql = sql, db_path = db_path)
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

  if (grepl("\\.csv$", output_file, ignore.case = TRUE)) {
    write.csv(result, output_file, row.names = FALSE)
  } else {
    writeLines(c(
      "# DuckDB Query Result",
      "",
      fmt_md_table(result, max_rows = 200)
    ), output_file, useBytes = TRUE)
  }

  invisible(result)
}
