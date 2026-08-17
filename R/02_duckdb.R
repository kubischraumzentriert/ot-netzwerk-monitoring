source("R/01_inventory_report.R", local = TRUE)
source("R/00_setup.R", local = TRUE)

duckdb_is_ready <- function() {
  dbi_available()
}

load_inventory_into_duckdb <- function(session_dir = latest_inventory_dir(), db_path = file.path(paths$data_processed, "network_analysis.duckdb")) {
  if (!dbi_available()) {
    message("DuckDB/DBI packages are not installed; skipping database load.")
    return(invisible(FALSE))
  }

  if (is.na(session_dir) || !dir.exists(session_dir)) {
    stop("No inventory session found")
  }

  inv <- read_inventory_session(session_dir)
  con <- open_duckdb(db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

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

  message("Loaded inventory session into DuckDB: ", db_path)
  invisible(TRUE)
}
