source("R/00_setup.R", local = TRUE)
source("R/01_inventory_report.R", local = TRUE)

duckdb_jdbc_available <- function() {
  requireNamespace("DBI", quietly = TRUE) &&
    requireNamespace("RJDBC", quietly = TRUE) &&
    requireNamespace("rJava", quietly = TRUE)
}

duckdb_jdbc_default_jar <- function() {
  file.path(Sys.getenv("USERPROFILE"), "Downloads", "duckdb_jdbc-1.5.5.0.jar")
}

duckdb_jdbc_connect <- function(
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  if (!duckdb_jdbc_available()) {
    stop("DBI, RJDBC and rJava must be available in this R session")
  }
  if (!file.exists(jar_path)) {
    stop("DuckDB JDBC jar not found: ", jar_path)
  }

  db_path <- normalizePath(db_path, winslash = "/", mustWork = FALSE)
  drv <- RJDBC::JDBC(driverClass = driver_class, classPath = jar_path)
  RJDBC::dbConnect(drv, url = sprintf("jdbc:duckdb:%s", db_path))
}

load_inventory_into_duckdb_jdbc <- function(
  session_dir = latest_inventory_dir(),
  db_path = file.path(paths$data_processed, "network_analysis.duckdb"),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  if (is.na(session_dir) || !dir.exists(session_dir)) {
    stop("No inventory session found")
  }

  inv <- read_inventory_session(session_dir)
  con <- duckdb_jdbc_connect(db_path = db_path, jar_path = jar_path, driver_class = driver_class)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  write_table <- function(name, df) {
    if (!is.data.frame(df) || !nrow(df)) return(invisible(NULL))
    DBI::dbWriteTable(con, name, df, overwrite = TRUE)
    invisible(TRUE)
  }

  write_table("inventory_host_info", inv$host_info)
  write_table("inventory_net_adapters", inv$net_adapters)
  write_table("inventory_net_ip_configuration", inv$net_ip_configuration)
  write_table("inventory_arp_neighbors", inv$arp_neighbors)
  write_table("inventory_tcp_connections", inv$tcp_connections)

  message("Loaded inventory session into DuckDB via JDBC: ", db_path)
  invisible(TRUE)
}

