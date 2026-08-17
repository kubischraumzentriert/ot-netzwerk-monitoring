source("R/05_duckdb_analysis.R", local = TRUE)

read_sql_file <- function(path) {
  if (!file.exists(path)) {
    stop("SQL file not found: ", path)
  }
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

write_duckdb_overview_report <- function(
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  output_file = file.path(paths$reports, "duckdb_analysis_overview.md"),
  inventory_sql = file.path(paths$root, "sql", "inventory_overview.sql"),
  benchmark_sql = file.path(paths$root, "sql", "benchmark_overview.sql")
) {
  if (!dbi_available() || !file.exists(db_path)) {
    md <- c(
      "# DuckDB Analyse-Overview",
      "",
      "Keine DuckDB-Datenbank oder keine DuckDB-Pakete in dieser R-Sitzung verfuegbar."
    )
    dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
    writeLines(md, output_file, useBytes = TRUE)
    message("Wrote placeholder DuckDB overview report: ", output_file)
    return(invisible(output_file))
  }

  inventory <- duckdb_query(read_sql_file(inventory_sql), db_path = db_path)
  benchmark <- duckdb_query(read_sql_file(benchmark_sql), db_path = db_path)
  counts <- duckdb_table_counts(db_path)

  md <- c(
    "# DuckDB Analyse-Overview",
    "",
    paste0("- Datenbank: ", db_path),
    paste0("- Tabellen: ", nrow(counts)),
    "",
    "## Tabellen",
    "",
    fmt_md_table(counts, max_rows = 50),
    "",
    "## Inventur-Overview",
    "",
    fmt_md_table(inventory, max_rows = 20),
    "",
    "## Benchmark-Overview",
    "",
    fmt_md_table(benchmark, max_rows = 20)
  )

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(md, output_file, useBytes = TRUE)
  message("Wrote DuckDB overview report: ", output_file)
  invisible(output_file)
}

write_duckdb_overview_report()
