source("R/04_multirun_analysis.R", local = TRUE)
source("R/02_duckdb.R", local = TRUE)
source("R/03_duckdb_jdbc.R", local = TRUE)
source("R/06_duckdb_schema.R", local = TRUE)

duckdb_native_available <- function() {
  requireNamespace("duckdb", quietly = TRUE) && requireNamespace("DBI", quietly = TRUE)
}

load_multirun_bundle_into_duckdb_native <- function(
  bundle = build_multirun_bundle(),
  db_path = duckdb_default_db_path()
) {
  if (!duckdb_native_available()) {
    message("duckdb/DBI not available; skipping native DuckDB load.")
    return(invisible(FALSE))
  }

  duckdb_init_database(db_path = db_path)
  con <- open_duckdb(db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  duckdb_write_or_replace_table(con, "inventory_sessions", bundle$inventory_sessions)
  duckdb_write_or_replace_table(con, "benchmark_rows", bundle$benchmark_rows)
  duckdb_write_or_replace_table(con, "benchmark_summary", bundle$benchmark_summary)

  message("Loaded multirun bundle into DuckDB: ", db_path)
  invisible(TRUE)
}

load_multirun_bundle_into_duckdb_jdbc <- function(
  bundle = build_multirun_bundle(),
  db_path = duckdb_default_db_path(),
  jar_path = duckdb_jdbc_default_jar(),
  driver_class = "org.duckdb.DuckDBDriver"
) {
  if (!duckdb_jdbc_available()) {
    message("DBI/RJDBC/rJava not available; skipping DuckDB JDBC load.")
    return(invisible(FALSE))
  }

  duckdb_init_database(db_path = db_path)
  con <- duckdb_jdbc_connect(db_path = db_path, jar_path = jar_path, driver_class = driver_class)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  duckdb_write_or_replace_table(con, "inventory_sessions", bundle$inventory_sessions)
  duckdb_write_or_replace_table(con, "benchmark_rows", bundle$benchmark_rows)
  duckdb_write_or_replace_table(con, "benchmark_summary", bundle$benchmark_summary)

  message("Loaded multirun bundle into DuckDB via JDBC: ", db_path)
  invisible(TRUE)
}

load_multirun_bundle_into_duckdb <- function(
  bundle = build_multirun_bundle(),
  db_path = duckdb_default_db_path(),
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
  db_path = duckdb_default_db_path()
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
  db_path = duckdb_default_db_path(),
  bundle = build_multirun_bundle(),
  output_file = file.path(paths$reports, "network_overview_duckdb.md")
) {
  counts <- duckdb_table_counts(db_path)
  if (!nrow(counts)) {
    md <- c(
      markdown_yaml_header("DuckDB Analyse Uebersicht"),
      "# DuckDB Analyse Uebersicht",
      "",
      "Keine DuckDB-Datei oder keine Tabellen gefunden."
    )
    writeLines(md, output_file, useBytes = TRUE)
    return(output_file)
  }

  inventory_overview <- if (is.list(bundle) && "inventory_sessions" %in% names(bundle)) bundle$inventory_sessions else data.frame()
  benchmark_rows <- if (is.list(bundle) && "benchmark_rows" %in% names(bundle)) bundle$benchmark_rows else data.frame()
  benchmark_summary <- if (is.list(bundle) && "benchmark_summary" %in% names(bundle)) bundle$benchmark_summary else data.frame()
  benchmark_files <- benchmark_file_overview()
  probe_overview <- benchmark_probe_overview(benchmark_rows)
  session_overview <- benchmark_session_overview(benchmark_summary)
  target_overview <- benchmark_target_overview(benchmark_summary)

  counts <- counts[order(counts$table_name), , drop = FALSE]
  total_rows <- sum(counts$rows, na.rm = TRUE)
  table_count <- nrow(counts)
  benchmark_row_count <- if (nrow(benchmark_rows)) nrow(benchmark_rows) else 0
  inventory_row_count <- if (nrow(inventory_overview)) nrow(inventory_overview) else 0
  benchmark_file_count <- if (nrow(benchmark_files)) nrow(benchmark_files) else 0
  session_tags <- if (nrow(benchmark_rows) && "session_tag" %in% names(benchmark_rows)) sort(unique(benchmark_rows$session_tag[!is.na(benchmark_rows$session_tag) & nzchar(benchmark_rows$session_tag)])) else character()
  target_labels <- if (nrow(benchmark_rows) && "target_label" %in% names(benchmark_rows)) sort(unique(benchmark_rows$target_label[!is.na(benchmark_rows$target_label) & nzchar(benchmark_rows$target_label)])) else character()
  probe_labels <- if (nrow(benchmark_rows) && "probe" %in% names(benchmark_rows)) sort(unique(benchmark_rows$probe[!is.na(benchmark_rows$probe) & nzchar(benchmark_rows$probe)])) else character()
  raw_session_note <- if (length(session_tags) && any(session_tags %in% c("raw", "legacy"))) {
    "Hinweis: `raw` oder `legacy` bedeutet, dass die Laufkonfiguration noch keinen expliziten `session_tag` gesetzt hat."
  } else {
    ""
  }
  ping_metric_note <- if (nrow(benchmark_rows) && "probe" %in% names(benchmark_rows) && "metric_ms" %in% names(benchmark_rows)) {
    "Hinweis: `metric_ms` bei `ping` ist die echte RTT aus der Ping-Ausgabe (`Zeit=...ms` bzw. `time=...ms`). Aeltere Laeufe vor dem Parser-Fix koennen hier noch die Laufzeit des Prozesses enthalten."
  } else {
    ""
  }
  tcp_total_note <- if (nrow(benchmark_rows) && "probe" %in% names(benchmark_rows) && "total_ms" %in% names(benchmark_rows)) {
    tcp_rows <- benchmark_rows$probe == "tcp"
    if (any(tcp_rows, na.rm = TRUE) && all(is.na(benchmark_rows$total_ms[tcp_rows]))) {
      "Hinweis: `total_ms` ist in den bestehenden TCP-Rohdaten noch nicht befuellt; dieser Wert wird erst mit dem aktualisierten Probe-Code fuer neue Laeufe geschrieben."
    } else {
      ""
    }
  } else {
    ""
  }

  md <- c(
    markdown_yaml_header("DuckDB Analyse Uebersicht"),
    "# DuckDB Analyse Uebersicht",
    "",
    "## Kurzueberblick",
    "",
    paste0("- Datenbank: ", db_path),
    paste0("- Tabellen: ", table_count),
    paste0("- Zeilen gesamt: ", total_rows),
    paste0("- Inventur-Sessionen: ", inventory_row_count),
    paste0("- Benchmark-Dateien: ", benchmark_file_count),
    paste0("- Benchmark-Rows: ", benchmark_row_count),
    paste0("- Session-Tags: ", if (length(session_tags)) paste(session_tags, collapse = ", ") else "keine"),
    paste0("- Zielsysteme: ", if (length(target_labels)) length(target_labels) else 0),
    paste0("- Probe-Typen: ", if (length(probe_labels)) paste(probe_labels, collapse = ", ") else "keine"),
    "",
    "## DuckDB-Tabellen",
    "",
    fmt_md_table(counts, max_rows = 100),
    "",
    "## Inventur-Sessionen",
    "",
    if (nrow(inventory_overview)) fmt_md_table(inventory_overview, max_rows = 20) else "Keine Inventur-Sessions gefunden.",
    "",
    "## Benchmark-Dateien",
    "",
    if (nrow(benchmark_files)) fmt_md_table(benchmark_files, max_rows = 20) else "Keine Benchmark-Dateien gefunden.",
    "",
    "## Probe-Uebersicht",
    "",
    if (nrow(probe_overview)) fmt_md_table(probe_overview, max_rows = 20) else "Keine Probe-Uebersicht verfuegbar.",
    if (nzchar(ping_metric_note)) "",
    if (nzchar(ping_metric_note)) ping_metric_note,
    if (nzchar(tcp_total_note)) "",
    if (nzchar(tcp_total_note)) tcp_total_note,
    "",
    "## Session-Uebersicht",
    "",
    if (nrow(session_overview)) fmt_md_table(session_overview, max_rows = 20) else "Keine Session-Tags gefunden.",
    if (nzchar(raw_session_note)) "",
    if (nzchar(raw_session_note)) raw_session_note,
    "",
    "## Ziel-Uebersicht",
    "",
    if (nrow(target_overview)) fmt_md_table(target_overview, max_rows = 20) else "Keine Zielauswertung verfuegbar.",
    "",
    "## Naechste Schritte",
    "",
    "- einen echten Direkt-vs-Switch-Lauf mit getrennten `session_tag`-Werten fahren",
    "- bei Bedarf weitere Rohdaten oder Varianten als Tabellen aufnehmen",
    "- gezielte SQL-Abfragen fuer eine tiefere Analyse anlegen",
    "- daraus spaeter Vergleiche pro Ziel, Probe und Session ableiten"
  )

  writeLines(md, output_file, useBytes = TRUE)
  output_file
}

refresh_duckdb_analysis <- function(
  bundle = build_multirun_bundle(),
  db_path = duckdb_default_db_path(),
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
  write_duckdb_report(db_path = db_path, bundle = bundle, output_file = output_file)
  message("Wrote DuckDB analysis report: ", output_file)
  invisible(TRUE)
}

duckdb_query <- function(
  sql,
  db_path = duckdb_default_db_path()
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
  db_path = duckdb_default_db_path()
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
