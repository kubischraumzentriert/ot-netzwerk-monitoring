source("R/00_setup.R", local = TRUE)
source("R/01_inventory_report.R", local = TRUE)

bind_rows_union <- function(...) {
  dfs <- list(...)
  dfs <- Filter(function(x) is.data.frame(x) && nrow(x) >= 0, dfs)
  if (!length(dfs)) return(data.frame())
  all_names <- unique(unlist(lapply(dfs, names), use.names = FALSE))
  aligned <- lapply(dfs, function(df) {
    missing <- setdiff(all_names, names(df))
    for (nm in missing) df[[nm]] <- NA
    df <- df[, all_names, drop = FALSE]
    rownames(df) <- NULL
    df
  })
  do.call(rbind, aligned)
}

list_inventory_sessions <- function(root = paths$inventory) {
  if (!dir.exists(root)) return(character())
  dirs <- list.dirs(root, full.names = TRUE, recursive = FALSE)
  dirs[dir.exists(dirs)]
}

list_benchmark_files <- function(root = paths$data_raw) {
  if (!dir.exists(root)) return(character())
  files <- list.files(root, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  files[!grepl("[\\\\/]inventory[\\\\/]", files, ignore.case = TRUE)]
}

safe_mean <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (!length(x) || all(is.na(x))) return(NA_real_)
  mean(x, na.rm = TRUE)
}

safe_median <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (!length(x) || all(is.na(x))) return(NA_real_)
  stats::median(x, na.rm = TRUE)
}

safe_p95 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(stats::quantile(x, 0.95, names = FALSE, type = 7))
}

inventory_session_summary <- function(session_dir) {
  inv <- read_inventory_session(session_dir)
  host_keys <- if (nrow(inv$host_info)) trimws(tolower(inv$host_info$key)) else character()
  computer_name <- if (nrow(inv$host_info)) normalize_empty(inv$host_info$value[host_keys == "computer_name"]) else "n/a"
  collected_at <- if (nrow(inv$host_info)) normalize_empty(inv$host_info$value[host_keys == "collected_at"]) else "n/a"
  primary_ip <- if (nrow(inv$net_adapters)) normalize_empty(inv$net_adapters$ipv4[!is.na(inv$net_adapters$ipv4)][1], "n/a") else "n/a"
  primary_mac <- if (nrow(inv$net_adapters)) normalize_empty(inv$net_adapters$mac[!is.na(inv$net_adapters$mac)][1], "n/a") else "n/a"

  data.frame(
    session_dir = session_dir,
    computer_name = computer_name,
    collected_at = collected_at,
    adapter_count = nrow(inv$net_adapters),
    arp_count = nrow(inv$arp_neighbors),
    tcp_count = nrow(inv$tcp_connections),
    listening_count = if (nrow(inv$tcp_connections)) sum(inv$tcp_connections$protocol == "TCP" & inv$tcp_connections$foreign_address %in% c("0.0.0.0:0", "[::]:0"), na.rm = TRUE) else 0,
    primary_ipv4 = primary_ip,
    primary_mac = primary_mac,
    stringsAsFactors = FALSE
  )
}

benchmark_file_summary <- function(path) {
  if (!file.exists(path)) return(data.frame())
  df <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  if (!nrow(df)) return(data.frame())

  if (!"target_label" %in% names(df)) {
    df$target_label <- sub("_[^_]+\\.csv$", "", basename(path))
  }
  if (!"probe" %in% names(df)) {
    df$probe <- "unknown"
  }
  if (!"session_tag" %in% names(df)) {
    parent_dir <- basename(dirname(path))
    df$session_tag <- if (nzchar(parent_dir) && !identical(parent_dir, "raw")) parent_dir else "legacy"
  }
  df$source_file <- path
  df
}

benchmark_run_summary <- function(df) {
  if (!is.data.frame(df) || !nrow(df)) return(data.frame())
  key_cols <- intersect(c("session_tag", "target_label", "probe"), names(df))
  if (!length(key_cols)) return(data.frame())

  split_key <- interaction(df[, key_cols, drop = FALSE], drop = TRUE, lex.order = TRUE)
  groups <- split(df, split_key)

  rows <- lapply(groups, function(g) {
    data.frame(
      session_tag = if ("session_tag" %in% names(g)) normalize_empty(g$session_tag) else "legacy",
      target_label = normalize_empty(g$target_label),
      probe = normalize_empty(g$probe),
      rows = nrow(g),
      success_rate = if ("success" %in% names(g)) mean(as.logical(g$success), na.rm = TRUE) else NA_real_,
      metric_ms_mean = if ("metric_ms" %in% names(g)) safe_mean(g$metric_ms) else NA_real_,
      metric_ms_median = if ("metric_ms" %in% names(g)) safe_median(g$metric_ms) else NA_real_,
      metric_ms_p95 = if ("metric_ms" %in% names(g)) safe_p95(g$metric_ms) else NA_real_,
      connect_ms_mean = if ("connect_ms" %in% names(g)) safe_mean(g$connect_ms) else NA_real_,
      total_ms_mean = if ("total_ms" %in% names(g)) safe_mean(g$total_ms) else NA_real_,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

build_multirun_bundle <- function(
  inventory_dirs = list_inventory_sessions(),
  benchmark_files = list_benchmark_files()
) {
  inventory_sessions <- if (length(inventory_dirs)) {
    bind_rows_union(lapply(inventory_dirs, inventory_session_summary))
  } else {
    data.frame()
  }

  benchmark_rows <- if (length(benchmark_files)) {
    bind_rows_union(lapply(benchmark_files, benchmark_file_summary))
  } else {
    data.frame()
  }

  benchmark_summary <- benchmark_run_summary(benchmark_rows)

  list(
    inventory_sessions = inventory_sessions,
    benchmark_rows = benchmark_rows,
    benchmark_summary = benchmark_summary
  )
}

benchmark_session_compare <- function(benchmark_rows) {
  if (!is.data.frame(benchmark_rows) || !nrow(benchmark_rows)) return(data.frame())
  if (!"session_tag" %in% names(benchmark_rows)) return(data.frame())
  tags <- sort(unique(benchmark_rows$session_tag[!is.na(benchmark_rows$session_tag) & nzchar(benchmark_rows$session_tag)]))
  if (length(tags) < 2) return(data.frame())

  base_tag <- tags[1]
  compare_tag <- tags[2]

  subset_cols <- intersect(
    c("session_tag", "target_label", "probe", "metric_ms", "connect_ms", "total_ms", "success"),
    names(benchmark_rows)
  )
  df <- benchmark_rows[, subset_cols, drop = FALSE]
  df <- df[df$session_tag %in% c(base_tag, compare_tag), , drop = FALSE]
  if (!nrow(df)) return(data.frame())

  group_key <- interaction(df$target_label, df$probe, drop = TRUE, lex.order = TRUE)
  groups <- split(df, group_key)

  rows <- lapply(groups, function(g) {
    base <- g[g$session_tag == base_tag, , drop = FALSE]
    compare <- g[g$session_tag == compare_tag, , drop = FALSE]
    data.frame(
      target_label = normalize_empty(g$target_label),
      probe = normalize_empty(g$probe),
      base_tag = base_tag,
      compare_tag = compare_tag,
      base_rows = nrow(base),
      compare_rows = nrow(compare),
      base_success_rate = if (nrow(base) && "success" %in% names(base)) mean(as.logical(base$success), na.rm = TRUE) else NA_real_,
      compare_success_rate = if (nrow(compare) && "success" %in% names(compare)) mean(as.logical(compare$success), na.rm = TRUE) else NA_real_,
      delta_success_rate = if (nrow(base) && nrow(compare)) {
        (if ("success" %in% names(compare)) mean(as.logical(compare$success), na.rm = TRUE) else NA_real_) -
          (if ("success" %in% names(base)) mean(as.logical(base$success), na.rm = TRUE) else NA_real_)
      } else NA_real_,
      base_metric_ms_mean = if (nrow(base) && "metric_ms" %in% names(base)) safe_mean(base$metric_ms) else NA_real_,
      compare_metric_ms_mean = if (nrow(compare) && "metric_ms" %in% names(compare)) safe_mean(compare$metric_ms) else NA_real_,
      delta_metric_ms_mean = if (nrow(base) && nrow(compare)) safe_mean(compare$metric_ms) - safe_mean(base$metric_ms) else NA_real_,
      base_connect_ms_mean = if (nrow(base) && "connect_ms" %in% names(base)) safe_mean(base$connect_ms) else NA_real_,
      compare_connect_ms_mean = if (nrow(compare) && "connect_ms" %in% names(compare)) safe_mean(compare$connect_ms) else NA_real_,
      delta_connect_ms_mean = if (nrow(base) && nrow(compare)) safe_mean(compare$connect_ms) - safe_mean(base$connect_ms) else NA_real_,
      base_total_ms_mean = if (nrow(base) && "total_ms" %in% names(base)) safe_mean(base$total_ms) else NA_real_,
      compare_total_ms_mean = if (nrow(compare) && "total_ms" %in% names(compare)) safe_mean(compare$total_ms) else NA_real_,
      delta_total_ms_mean = if (nrow(base) && nrow(compare)) safe_mean(compare$total_ms) - safe_mean(base$total_ms) else NA_real_,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

write_benchmark_comparison_report <- function(
  bundle = build_multirun_bundle(),
  output_file = file.path(paths$reports, "network_direct_vs_switch.md")
) {
  compare_tbl <- benchmark_session_compare(bundle$benchmark_rows)
  sum_tbl <- bundle$benchmark_summary
  if (!nrow(compare_tbl)) {
    md <- c(
      "# Benchmark Vergleich",
      "",
      "Keine zwei beschrifteten Benchmark-Sessions gefunden.",
      "",
      "Tipp: setze `session_tag` in der Benchmark-Konfiguration, zum Beispiel `direct` und `switch`."
    )
    writeLines(md, output_file, useBytes = TRUE)
    return(output_file)
  }

  md <- c(
    "# Benchmark Vergleich",
    "",
    "## Zusammenfassung",
    "",
    fmt_md_table(sum_tbl, max_rows = 20),
    "",
    "## Direkt vs. Switch",
    "",
    fmt_md_table(compare_tbl, max_rows = 40),
    "",
    "## Hinweis",
    "",
    "- base_tag und compare_tag werden aus den ersten beiden Session-Tags gebildet.",
    "- Fuer einen echten Direkt-vs-Switch-Vergleich sollten die Laufnamen `direct` und `switch` enthalten.",
    "- Die Kennzahlen sind Mittelwerte ueber die jeweiligen CSV-Rows."
  )

  writeLines(md, output_file, useBytes = TRUE)
  output_file
}

write_multirun_outputs <- function(bundle = build_multirun_bundle(), output_dir = file.path(paths$data_processed, "analysis")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (nrow(bundle$inventory_sessions)) {
    write.csv(bundle$inventory_sessions, file.path(output_dir, "inventory_sessions.csv"), row.names = FALSE)
  }
  if (nrow(bundle$benchmark_rows)) {
    write.csv(bundle$benchmark_rows, file.path(output_dir, "benchmark_rows.csv"), row.names = FALSE)
  }
  if (nrow(bundle$benchmark_summary)) {
    write.csv(bundle$benchmark_summary, file.path(output_dir, "benchmark_summary.csv"), row.names = FALSE)
  }
  invisible(output_dir)
}

make_safe_name <- function(x) {
  x <- ifelse(is.na(x), "unknown", x)
  gsub("[^A-Za-z0-9_-]", "_", x)
}

plot_svg <- function(path, width = 10, height = 7, expr) {
  svg(path, width = width, height = height)
  old_par <- par(no.readonly = TRUE)
  on.exit({
    par(old_par)
    dev.off()
  }, add = FALSE)
  force(expr)
}

write_multirun_plots <- function(
  bundle = build_multirun_bundle(),
  output_dir = file.path(paths$reports, "figures")
) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  old_figs <- list.files(output_dir, pattern = "^benchmark_.*\\.(png|svg)$", full.names = TRUE)
  if (length(old_figs)) file.remove(old_figs)

  bench <- bundle$benchmark_rows
  sum_tbl <- bundle$benchmark_summary

  if (!nrow(bench)) {
    return(invisible(character()))
  }

  created <- character()

  if (nrow(sum_tbl)) {
    plot_file <- file.path(output_dir, "benchmark_success_rate.svg")
    plot_svg(plot_file, expr = {
      labels <- paste(sum_tbl$target_label, sum_tbl$probe, sep = " / ")
      values <- suppressWarnings(as.numeric(sum_tbl$success_rate))
      barplot(
        height = values,
        names.arg = labels,
        las = 2,
        col = "#2E86AB",
        ylim = c(0, 1),
        ylab = "Erfolgsrate",
        main = "Benchmark Erfolgsrate"
      )
      abline(h = c(0.5, 1), lty = c(3, 2), col = c("grey70", "grey50"))
    })
    created <- c(created, plot_file)
  }

  numeric_cols <- intersect(c("metric_ms", "connect_ms", "total_ms"), names(bench))
  for (col in numeric_cols) {
    values <- suppressWarnings(as.numeric(bench[[col]]))
    keep <- !is.na(values)
    if (!any(keep)) next

    plot_file <- file.path(output_dir, paste0("benchmark_", col, "_boxplot.png"))
    plot_file <- file.path(output_dir, paste0("benchmark_", col, "_boxplot.svg"))
    plot_svg(plot_file, expr = {
      grp <- interaction(bench$target_label, bench$probe, drop = TRUE, lex.order = TRUE)
      boxplot(
        values[keep] ~ grp[keep],
        las = 2,
        col = "#F18F01",
        ylab = paste(col, "ms"),
        main = paste("Benchmark", col, "nach Ziel / Probe")
      )
    })
    created <- c(created, plot_file)
  }

  if (nrow(sum_tbl) && "target_label" %in% names(sum_tbl)) {
    plot_file <- file.path(output_dir, "benchmark_summary_scatter.svg")
    plot_svg(plot_file, expr = {
      x <- suppressWarnings(as.numeric(sum_tbl$metric_ms_mean))
      y <- suppressWarnings(as.numeric(sum_tbl$connect_ms_mean))
      keep <- is.finite(x) & is.finite(y)
      if (any(keep)) {
        plot(
          x[keep], y[keep],
          pch = 19,
          col = "#6A4C93",
          xlab = "metric_ms_mean",
          ylab = "connect_ms_mean",
          main = "Zusammenfassung der Benchmarks"
        )
        text(x[keep], y[keep], labels = paste(sum_tbl$target_label[keep], sum_tbl$probe[keep], sep = " / "), pos = 3, cex = 0.8)
      } else {
        plot.new()
        title(main = "Zusammenfassung der Benchmarks")
        text(0.5, 0.5, "Keine gemeinsamen numerischen Kennzahlen verfuegbar")
      }
    })
    created <- c(created, plot_file)
  }

  invisible(created)
}

write_multirun_report <- function(bundle = build_multirun_bundle(), output_file = file.path(paths$reports, "network_overview.md")) {
  inv_tbl <- if (nrow(bundle$inventory_sessions)) bundle$inventory_sessions[, intersect(c("computer_name", "collected_at", "adapter_count", "arp_count", "tcp_count", "listening_count", "primary_ipv4"), names(bundle$inventory_sessions)), drop = FALSE] else data.frame()
  bench_tbl <- if (nrow(bundle$benchmark_summary)) bundle$benchmark_summary[, intersect(c("session_tag", "target_label", "probe", "rows", "success_rate", "metric_ms_mean", "metric_ms_median", "metric_ms_p95", "connect_ms_mean", "total_ms_mean"), names(bundle$benchmark_summary)), drop = FALSE] else data.frame()
  figure_dir <- file.path(paths$reports, "figures")
  figure_links <- if (dir.exists(figure_dir)) {
    figs <- list.files(figure_dir, pattern = "\\.(png|svg)$", full.names = FALSE)
    if (length(figs)) paste0("- [", figs, "](figures/", figs, ")", collapse = "\n") else ""
  } else {
    ""
  }

  md <- c(
    "# Netzwerk Analyse Uebersicht",
    "",
    "## Inventur Sessions",
    "",
    fmt_md_table(inv_tbl, max_rows = 20),
    "",
    "## Benchmark Summary",
    "",
    fmt_md_table(bench_tbl, max_rows = 20),
    "",
    "## Dateien",
    "",
    paste0("- Inventur-Sessions: ", if (nrow(bundle$inventory_sessions)) nrow(bundle$inventory_sessions) else 0),
    paste0("- Benchmark-Rows: ", if (nrow(bundle$benchmark_rows)) nrow(bundle$benchmark_rows) else 0),
    paste0("- Benchmark-Gruppen: ", if (nrow(bundle$benchmark_summary)) nrow(bundle$benchmark_summary) else 0),
    "",
    "## Figuren",
    "",
    if (length(figure_links) && nzchar(figure_links[1])) figure_links else "_keine Figuren erzeugt_",
    "",
    "## Naechste Auswertungsschritte",
    "",
    "- Direkt vs. Switch als getrennte Sessions markieren",
    "- Port 9000 Messungen pro Geraet vergleichen",
    "- auffaellige Hosts mit Wireshark oder Suricata nachverfolgen",
    "- Ergebnisse bei Bedarf in DuckDB laden"
  )

  writeLines(md, output_file, useBytes = TRUE)
  output_file
}
