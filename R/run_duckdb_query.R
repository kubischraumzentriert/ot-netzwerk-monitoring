source("R/05_duckdb_analysis.R", local = TRUE)

parse_duckdb_query_args <- function(args) {
  opts <- list(
    db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
    output_file = NULL,
    query_parts = character()
  )

  for (arg in args) {
    if (startsWith(arg, "--db=")) {
      opts$db_path <- sub("^--db=", "", arg)
    } else if (startsWith(arg, "--out=")) {
      opts$output_file <- sub("^--out=", "", arg)
    } else {
      opts$query_parts <- c(opts$query_parts, arg)
    }
  }

  opts
}

run_duckdb_query_main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  opts <- parse_duckdb_query_args(args)

  if (!length(opts$query_parts)) {
    message("No SQL provided. Showing DuckDB table counts instead.")
    counts <- duckdb_table_counts(db_path = opts$db_path)
    if (nrow(counts)) {
      print(counts)
    } else {
      message("No DuckDB database or tables found yet.")
    }
    message("Usage: Rscript R/run_duckdb_query.R --db=path/to/network_analysis.duckdb --out=reports/result.md <sql or sql-file>")
    invisible(TRUE)
    return()
  }

  if (length(opts$query_parts) == 1 && file.exists(opts$query_parts[1])) {
    sql <- readLines(opts$query_parts[1], warn = FALSE, encoding = "UTF-8")
  } else {
    sql <- opts$query_parts
  }

  if (is.null(opts$output_file)) {
    result <- duckdb_query(sql = sql, db_path = opts$db_path)
    print(result)
    invisible(result)
  } else {
    result <- duckdb_write_query_result(sql = sql, output_file = opts$output_file, db_path = opts$db_path)
    message("Wrote DuckDB query result: ", opts$output_file)
    invisible(result)
  }
}

invisible(run_duckdb_query_main())
