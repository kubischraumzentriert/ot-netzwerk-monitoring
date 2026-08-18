source("R/00_setup.R", local = TRUE)
source("R/03_duckdb_jdbc.R", local = TRUE)

duckdb_schema_sql_path <- function() {
  file.path(paths$root, "sql", "ddl", "network_analysis_schema.sql")
}

duckdb_default_db_path <- function() {
  env_db_path <- Sys.getenv("NETWORK_ANALYSIS_DUCKDB_PATH")
  if (nzchar(env_db_path)) {
    return(env_db_path)
  }
  file.path(paths$data_processed, "network_analysis.duckdb")
}

read_sql_file <- function(path) {
  if (!file.exists(path)) {
    stop("SQL file not found: ", path)
  }
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

duckdb_write_or_replace_table <- function(con, name, df) {
  if (!is.data.frame(df) || !nrow(df)) {
    return(invisible(FALSE))
  }

  if (DBI::dbExistsTable(con, name)) {
    DBI::dbExecute(con, paste0('DELETE FROM "', name, '"'))
    DBI::dbAppendTable(con, name, df)
  } else {
    DBI::dbWriteTable(con, name, df, overwrite = FALSE)
  }

  invisible(TRUE)
}

duckdb_init_database <- function(
  db_path = duckdb_default_db_path(),
  schema_sql_path = duckdb_schema_sql_path(),
  schema_name = "network_analysis",
  schema_version = "1.0"
) {
  if (!file.exists(schema_sql_path)) {
    stop("DuckDB schema SQL not found: ", schema_sql_path)
  }

  dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)
  if (requireNamespace("duckdb", quietly = TRUE) && requireNamespace("DBI", quietly = TRUE)) {
    con <- open_duckdb(db_path)
    disconnect_fun <- function(connection) DBI::dbDisconnect(connection, shutdown = TRUE)
  } else if (duckdb_jdbc_available()) {
    con <- duckdb_jdbc_connect(db_path = db_path)
    disconnect_fun <- function(connection) DBI::dbDisconnect(connection)
  } else {
    stop("DBI/duckdb or RJDBC/rJava are not available")
  }

  on.exit(disconnect_fun(con), add = TRUE)

  DBI::dbExecute(con, paste(read_sql_file(schema_sql_path), collapse = "\n"))
  DBI::dbExecute(con, 'DELETE FROM "schema_metadata"')
  DBI::dbExecute(
    con,
    sprintf(
      'INSERT INTO "schema_metadata" (schema_name, schema_version, created_at, note) VALUES (\'%s\', \'%s\', current_timestamp, \'Created by init-database\')',
      gsub("'", "''", schema_name),
      gsub("'", "''", schema_version)
    )
  )

  message("Initialized DuckDB schema: ", db_path)
  invisible(db_path)
}
