source("R/01_inventory_report.R", local = TRUE)

markdown_yaml_header <- function(title) {
  c(
    "---",
    paste0("title: \"", gsub("\"", "\\\\\"", title, fixed = TRUE), "\""),
    "output: \"html_document\"",
    "---",
    ""
  )
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

safe_max <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  max(x)
}

read_key_value_config <- function(path, fallback_path) {
  if (!file.exists(path)) {
    path <- fallback_path
  }
  if (!file.exists(path)) {
    stop("Config file not found: ", fallback_path)
  }
  cfg <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  keys <- trimws(as.character(cfg[[1]]))
  values <- as.character(cfg[[2]])
  names(values) <- keys
  values
}

read_webapp_run_config <- function(path = file.path(paths$configs, "run.webapp.csv")) {
  private_path <- file.path(paths$configs, "run.webapp.private.csv")
  fallback_path <- file.path(paths$configs, "run.webapp.example.csv")
  if (identical(path, file.path(paths$configs, "run.webapp.csv")) && file.exists(private_path)) {
    path <- private_path
  }
  read_key_value_config(path, fallback_path)
}

read_webapp_targets <- function(path = file.path(paths$configs, "webapp_targets.csv")) {
  private_path <- file.path(paths$configs, "webapp_targets.private.csv")
  fallback_path <- file.path(paths$configs, "webapp_targets.example.csv")
  if (identical(path, file.path(paths$configs, "webapp_targets.csv")) && file.exists(private_path)) {
    path <- private_path
  }
  if (!file.exists(path)) {
    path <- fallback_path
  }
  if (!file.exists(path)) {
    stop("Config file not found: ", fallback_path)
  }

  targets <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  expected <- c("label", "url", "method", "interval_sec", "timeout_sec")
  if (ncol(targets) > 0) {
    names(targets)[seq_len(min(length(expected), ncol(targets)))] <- expected[seq_len(min(length(expected), ncol(targets)))]
  }
  if (!"label" %in% names(targets)) targets$label <- "webapp"
  if (!"url" %in% names(targets)) targets$url <- NA_character_
  if (!"method" %in% names(targets)) targets$method <- NA_character_
  if (!"interval_sec" %in% names(targets)) targets$interval_sec <- NA_character_
  if (!"timeout_sec" %in% names(targets)) targets$timeout_sec <- NA_character_

  targets$label <- trimws(as.character(targets$label))
  targets$url <- trimws(as.character(targets$url))
  targets$method <- trimws(as.character(targets$method))
  targets$interval_sec <- suppressWarnings(as.numeric(targets$interval_sec))
  targets$timeout_sec <- suppressWarnings(as.numeric(targets$timeout_sec))
  targets
}

resolve_webapp_session_tag <- function(run_cfg, fallback = "webapp") {
  tag <- if (!is.null(run_cfg) && "session_tag" %in% names(run_cfg)) run_cfg[["session_tag"]] else NULL
  if (is.null(tag) || is.na(tag) || !nzchar(tag)) {
    tag <- fallback
  }
  safe_component(tag, fallback = fallback)
}

resolve_webapp_output_dir <- function(run_cfg) {
  output_dir <- if (!is.null(run_cfg) && "output_dir" %in% names(run_cfg)) run_cfg[["output_dir"]] else NA_character_
  if (is.na(output_dir) || !nzchar(output_dir)) {
    output_dir <- file.path(paths$data_raw, "webapp")
  }
  output_dir
}

parse_http_url <- function(url) {
  url <- trimws(as.character(url))
  if (!nzchar(url)) stop("Empty URL")
  if (!grepl("^[a-zA-Z][a-zA-Z0-9+.-]*://", url)) {
    url <- paste0("http://", url)
  }

  match <- regexec(
    "^([a-zA-Z][a-zA-Z0-9+.-]*)://(\\[[^\\]]+\\]|[^/:?#]+)(?::([0-9]+))?([^?#]*)(\\?[^#]*)?(#.*)?$",
    url,
    perl = TRUE
  )
  parts <- regmatches(url, match)[[1]]
  if (length(parts) < 5) {
    stop("Could not parse URL: ", url)
  }

  scheme <- tolower(parts[2])
  host <- parts[3]
  host <- gsub("^\\[|\\]$", "", host)
  port <- parts[4]
  path <- parts[5]
  query <- if (length(parts) >= 6) parts[6] else ""
  if (!nzchar(path)) path <- "/"
  if (!nzchar(query)) query <- ""

  default_port <- if (scheme == "http") 80L else if (scheme == "https") 443L else NA_integer_
  if (is.na(default_port)) {
    stop("Unsupported URL scheme: ", scheme, ". This first version supports http:// URLs.")
  }
  port <- suppressWarnings(as.integer(port))
  if (is.na(port) || port <= 0L) port <- default_port

  list(
    scheme = scheme,
    host = host,
    port = port,
    path = paste0(path, query)
  )
}

parse_http_status <- function(status_line) {
  if (length(status_line) == 0 || is.na(status_line) || !nzchar(status_line)) {
    return(list(code = NA_integer_, text = NA_character_))
  }
  match <- regexec("^HTTP/\\d+(?:\\.\\d+)?\\s+([0-9]{3})\\s*(.*)$", status_line, perl = TRUE)
  parts <- regmatches(status_line, match)[[1]]
  if (length(parts) >= 2) {
    code <- suppressWarnings(as.integer(parts[2]))
    text <- if (length(parts) >= 3) parts[3] else ""
    return(list(code = code, text = text))
  }
  list(code = NA_integer_, text = status_line)
}

webapp_probe_once <- function(label, url, method = "HEAD", timeout_sec = 5) {
  start <- Sys.time()
  parsed <- parse_http_url(url)
  method <- toupper(trimws(as.character(method)))
  if (!nzchar(method)) method <- "HEAD"
  if (!method %in% c("HEAD", "GET")) {
    method <- "HEAD"
  }

  con <- NULL
  status_line <- NA_character_
  status_code <- NA_integer_
  status_text <- NA_character_
  err <- NA_character_
  transport_ok <- FALSE
  http_ok <- FALSE
  connect_ms <- NA_real_
  first_byte_ms <- NA_real_
  total_ms <- NA_real_

  tryCatch({
    con <- socketConnection(
      host = parsed$host,
      port = parsed$port,
      open = "r+b",
      blocking = TRUE,
      timeout = timeout_sec
    )
    connect_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000

    request <- paste0(
      method, " ", parsed$path, " HTTP/1.1\r\n",
      "Host: ", parsed$host, if (!is.na(parsed$port) && parsed$port > 0L) paste0(":", parsed$port) else "", "\r\n",
      "User-Agent: NetzwerkAnalyse-WebappTimer/1.0\r\n",
      "Accept: */*\r\n",
      "Connection: close\r\n",
      "\r\n"
    )
    writeBin(charToRaw(request), con)
    flush(con)

    status_line <- readLines(con, n = 1, warn = FALSE)
    first_byte_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
    if (!length(status_line)) {
      stop("Empty HTTP response")
    }

    repeat {
      header_line <- readLines(con, n = 1, warn = FALSE)
      if (!length(header_line) || !nzchar(header_line[[1]])) {
        break
      }
    }

    parsed_status <- parse_http_status(status_line[[1]])
    status_code <- parsed_status$code
    status_text <- parsed_status$text
    transport_ok <- TRUE
    http_ok <- !is.na(status_code) && status_code >= 200L && status_code < 400L
  }, error = function(e) {
    err <<- conditionMessage(e)
  }, finally = {
    if (!is.null(con)) close(con)
  })

  total_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000

  data.frame(
    ts = Sys.time(),
    session_tag = NA_character_,
    target_label = label,
    url = url,
    scheme = parsed$scheme,
    host = parsed$host,
    port = parsed$port,
    path = parsed$path,
    method = method,
    success = http_ok,
    transport_ok = transport_ok,
    status_code = status_code,
    status_text = status_text,
    connect_ms = connect_ms,
    first_byte_ms = first_byte_ms,
    total_ms = total_ms,
    timeout_sec = timeout_sec,
    error = err,
    stringsAsFactors = FALSE
  )
}

webapp_target_summary <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows)) return(data.frame())
  keys <- interaction(rows$target_label, rows$url, rows$method, drop = TRUE, lex.order = TRUE)
  groups <- split(rows, keys)
  out <- lapply(groups, function(g) {
    data.frame(
      target_label = normalize_empty(g$target_label),
      url = normalize_empty(g$url),
      method = normalize_empty(g$method),
      rows = nrow(g),
      success_rate = mean(as.logical(g$success), na.rm = TRUE),
      transport_ok_rate = mean(as.logical(g$transport_ok), na.rm = TRUE),
      status_codes = if ("status_code" %in% names(g)) paste(sort(unique(g$status_code[!is.na(g$status_code)])), collapse = ", ") else "n/a",
      connect_ms_mean = safe_mean(g$connect_ms),
      connect_ms_median = safe_median(g$connect_ms),
      first_byte_ms_mean = safe_mean(g$first_byte_ms),
      total_ms_mean = safe_mean(g$total_ms),
      total_ms_median = safe_median(g$total_ms),
      total_ms_p95 = safe_p95(g$total_ms),
      total_ms_max = safe_max(g$total_ms),
      timeout_count = if ("error" %in% names(g)) sum(grepl("timeout", g$error, ignore.case = TRUE), na.rm = TRUE) else NA_integer_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

write_webapp_timing_report <- function(rows, run_cfg, targets, output_file) {
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  if (!is.data.frame(rows) || !nrow(rows)) {
    md <- c(
      markdown_yaml_header("Webapp Timing Uebersicht"),
      "# Webapp Timing Uebersicht",
      "",
      "Keine Webapp-Messungen vorhanden."
    )
    writeLines(md, output_file, useBytes = TRUE)
    return(invisible(output_file))
  }

  summary_tbl <- webapp_target_summary(rows)
  session_tag <- if ("session_tag" %in% names(rows)) normalize_empty(rows$session_tag) else "n/a"
  md <- c(
    markdown_yaml_header("Webapp Timing Uebersicht"),
    "# Webapp Timing Uebersicht",
    "",
    "## Zweck",
    "",
    "Dieser Lauf misst die Antwortzeit einer Webanwendung ueber einen laengeren Zeitraum mit wenig Last.",
    "Er eignet sich fuer periodische Checks, wenn du vermutest, dass die Anwendung in Timeout-Zustaende laeuft oder der Netzwerkpfad instabil ist.",
    "",
    "## Laufkonfiguration",
    "",
    paste0("- session_tag: `", session_tag, "`"),
    paste0("- sample_count: `", if ("sample_count" %in% names(run_cfg)) run_cfg[["sample_count"]] else "n/a", "`"),
    paste0("- interval_sec: `", if ("interval_sec" %in% names(run_cfg)) run_cfg[["interval_sec"]] else "n/a", "`"),
    paste0("- timeout_sec: `", if ("timeout_sec" %in% names(run_cfg)) run_cfg[["timeout_sec"]] else "n/a", "`"),
    paste0("- output_dir: `", if ("output_dir" %in% names(run_cfg)) run_cfg[["output_dir"]] else "n/a", "`"),
    "",
    "## Zielsysteme",
    "",
    if (nrow(targets)) fmt_md_table(targets, max_rows = 20) else "Keine Ziele gefunden.",
    "",
    "## Zusammenfassung je Ziel",
    "",
    if (nrow(summary_tbl)) fmt_md_table(summary_tbl, max_rows = 30) else "Keine Zielzusammenfassung verfuegbar.",
    "",
    "## Rohdaten",
    "",
    fmt_md_table(head(rows, 20), max_rows = 20),
    "",
    "## Einordnung",
    "",
    "- Die Messung ist bewusst leichtgewichtig und sendet pro Probe nur einen einzelnen HTTP-Request.",
    "- Standard ist `HEAD`; wenn die Anwendung das nicht sauber kann, kannst du auf `GET` umstellen.",
    "- Fuer HTTPS koennen wir spaeter eine erweiterte Variante auf Basis von `curl` oder `httr2` ergänzen."
  )

  writeLines(md, output_file, useBytes = TRUE)
  invisible(output_file)
}

parse_webapp_args <- function(args) {
  opts <- list(
    targets = file.path(paths$configs, "webapp_targets.csv"),
    run = file.path(paths$configs, "run.webapp.csv"),
    out = file.path(paths$reports, "webapp_timing_overview.md")
  )

  for (arg in args) {
    if (startsWith(arg, "--targets=")) {
      opts$targets <- sub("^--targets=", "", arg)
    } else if (startsWith(arg, "--run=")) {
      opts$run <- sub("^--run=", "", arg)
    } else if (startsWith(arg, "--out=")) {
      opts$out <- sub("^--out=", "", arg)
    }
  }

  opts
}

run_webapp_timing <- function(targets = read_webapp_targets(), run_cfg = read_webapp_run_config(), output_file = file.path(paths$reports, "webapp_timing_overview.md")) {
  sample_count <- as.integer(as_num(run_cfg[["sample_count"]], 60))
  interval_sec <- as_num(run_cfg[["interval_sec"]], 60)
  default_timeout_sec <- as_num(run_cfg[["timeout_sec"]], 5)
  default_method <- if ("method" %in% names(run_cfg)) run_cfg[["method"]] else "HEAD"
  session_tag <- resolve_webapp_session_tag(run_cfg)
  output_dir <- resolve_webapp_output_dir(run_cfg)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  if (!is.data.frame(targets) || !nrow(targets)) {
    stop("No webapp targets configured")
  }

  run_started_at <- Sys.time()
  all_rows <- list()

  for (i in seq_len(nrow(targets))) {
    target <- targets[i, ]
    target_label <- if ("label" %in% names(target) && nzchar(target$label)) target$label else paste0("target_", i)
    target_url <- if ("url" %in% names(target)) target$url else NA_character_
    if (is.na(target_url) || !nzchar(target_url)) {
      next
    }

    target_method <- if ("method" %in% names(target) && nzchar(target$method)) target$method else default_method
    target_timeout <- if ("timeout_sec" %in% names(target) && !is.na(target$timeout_sec)) target$timeout_sec else default_timeout_sec
    target_interval <- if ("interval_sec" %in% names(target) && !is.na(target$interval_sec)) target$interval_sec else interval_sec

    message("Webapp target: ", target_label, " (", target_url, ", ", toupper(target_method), ")")

    rows <- vector("list", sample_count)
    for (n in seq_len(sample_count)) {
      probe <- webapp_probe_once(
        label = target_label,
        url = target_url,
        method = target_method,
        timeout_sec = target_timeout
      )
      probe$session_tag <- session_tag
      probe$sample_no <- n
      probe$interval_sec <- target_interval
      probe$timeout_sec <- target_timeout
      rows[[n]] <- probe
      if (n < sample_count) Sys.sleep(target_interval)
    }

    out_file <- file.path(
      output_dir,
      paste0(
        format(Sys.time(), "%Y%m%d_%H%M%S"),
        "_",
        safe_component(session_tag, fallback = "webapp"),
        "_",
        safe_component(target_label, fallback = "target"),
        ".csv"
      )
    )
    target_rows <- do.call(rbind, rows)
    write.csv(target_rows, out_file, row.names = FALSE, fileEncoding = "UTF-8")
    all_rows[[length(all_rows) + 1]] <- target_rows
  }

  combined <- do.call(rbind, all_rows)
  if (!is.data.frame(combined) || !nrow(combined)) {
    stop("No webapp timing rows were written.")
  }

  combined$run_started_at <- as.character(run_started_at)
  combined$run_finished_at <- as.character(Sys.time())
  write_webapp_timing_report(
    rows = combined,
    run_cfg = run_cfg,
    targets = targets,
    output_file = output_file
  )
  write.csv(
    combined,
    file.path(output_dir, paste0(format(run_started_at, "%Y%m%d_%H%M%S"), "_", safe_component(session_tag, fallback = "webapp"), "_combined.csv")),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )

  invisible(combined)
}

run_webapp_timing_main <- function() {
  args <- parse_webapp_args(commandArgs(trailingOnly = TRUE))
  targets <- read_webapp_targets(args$targets)
  run_cfg <- read_webapp_run_config(args$run)
  run_webapp_timing(targets = targets, run_cfg = run_cfg, output_file = args$out)
}

invisible(run_webapp_timing_main())
