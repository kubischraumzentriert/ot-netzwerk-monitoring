source("R/06_duckdb_schema.R", local = TRUE)

parse_init_database_args <- function(args) {
  opts <- list(
    db_path = duckdb_default_db_path(),
    schema_sql = duckdb_schema_sql_path()
  )

  for (arg in args) {
    if (startsWith(arg, "--db=")) {
      opts$db_path <- sub("^--db=", "", arg)
    } else if (startsWith(arg, "--schema=")) {
      opts$schema_sql <- sub("^--schema=", "", arg)
    }
  }

  opts
}

main <- function() {
  opts <- parse_init_database_args(commandArgs(trailingOnly = TRUE))
  duckdb_init_database(db_path = opts$db_path, schema_sql_path = opts$schema_sql)
  invisible(TRUE)
}

invisible(main())
