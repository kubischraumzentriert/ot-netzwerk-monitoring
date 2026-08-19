source("R/00_setup.R", local = TRUE)

resolve_port <- function(target_port, default_port = 9000) {
  port <- suppressWarnings(as.integer(target_port))
  if (is.na(port) || port <= 0L) {
    port <- suppressWarnings(as.integer(default_port))
  }
  if (is.na(port) || port <= 0L) {
    port <- 9000L
  }
  port
}

resolve_session_tag <- function(run_cfg, output_dir, fallback = "session") {
  tag <- if (!is.null(run_cfg) && "session_tag" %in% names(run_cfg)) {
    run_cfg[["session_tag"]]
  } else {
    NULL
  }

  if (is.null(tag) || is.na(tag) || !nzchar(tag)) {
    if (!is.null(output_dir) && nzchar(output_dir)) {
      tag <- basename(output_dir)
    } else {
      tag <- fallback
    }
  }

  safe_component(tag, fallback = fallback)
}

sanitize_text <- function(x) {
  x <- as.character(x)
  x <- vapply(x, function(value) {
    value <- tryCatch(
      iconv(value, from = "", to = "UTF-8", sub = "byte"),
      error = function(e) NA_character_
    )
    if (is.na(value) || !nzchar(value)) {
      value <- ""
    }
    value <- gsub("\r\n|\r|\n", " \\\\n ", value, perl = TRUE)
    value <- gsub("[[:cntrl:]]", " ", value, perl = TRUE)
    trimws(value)
  }, character(1), USE.NAMES = FALSE)
  x
}

extract_ping_rtt_ms <- function(lines) {
  if (!length(lines)) return(NA_real_)

  patterns <- c(
    "Zeit\\s*[=<]\\s*([0-9]+(?:[.,][0-9]+)?)\\s*ms",
    "time\\s*[=<]\\s*([0-9]+(?:[.,][0-9]+)?)\\s*ms"
  )

  candidates <- numeric()
  for (line in lines) {
    if (is.na(line) || !nzchar(line)) next
    for (pattern in patterns) {
      match <- regexec(pattern, line, perl = TRUE, ignore.case = TRUE)
      parts <- regmatches(line, match)[[1]]
      if (length(parts) >= 2 && nzchar(parts[2])) {
        candidate <- suppressWarnings(as.numeric(gsub(",", ".", parts[2], fixed = TRUE)))
        if (!is.na(candidate)) {
          candidates <- c(candidates, candidate)
        }
      }
    }
  }

  if (!length(candidates)) return(NA_real_)
  min(candidates, na.rm = TRUE)
}

ping_once <- function(host, timeout_sec = 1) {
  if (.Platform$OS.type != "windows") {
    cmd <- "ping"
    args <- c("-c", "1", "-W", as.character(timeout_sec), host)
  } else {
    cmd <- "ping"
    args <- c("-n", "1", "-w", as.character(timeout_sec * 1000), host)
  }

  start <- Sys.time()
  res <- suppressWarnings(system2(cmd, args = args, stdout = TRUE, stderr = TRUE))
  elapsed_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000

  text <- paste(res, collapse = "\n")
  success <- any(grepl("TTL=", res, ignore.case = TRUE)) || any(grepl("ttl=", res, ignore.case = TRUE))
  rtt_ms <- extract_ping_rtt_ms(res)

  data.frame(
    ts = timestamp_text(Sys.time()),
    host = host,
    port = NA_integer_,
    probe = "ping",
    success = success,
    metric_ms = ifelse(is.na(rtt_ms), elapsed_ms, rtt_ms),
    elapsed_ms = elapsed_ms,
    detail = text,
    stringsAsFactors = FALSE
  )
}

tcp_probe <- function(host, port = 9000, request = "HELLO", timeout_sec = 3) {
  start <- Sys.time()
  con <- NULL
  transport_ok <- FALSE
  reply_ok <- FALSE
  reply <- NA_character_
  connect_ms <- NA_real_
  total_ms <- NA_real_
  err <- NA_character_

  tryCatch({
    con <- socketConnection(
      host = host,
      port = port,
      open = "r+b",
      blocking = TRUE,
      timeout = timeout_sec
    )
    connect_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
    writeBin(charToRaw(paste0(request, "\n")), con)
    flush(con)
    transport_ok <- TRUE
    reply <- tryCatch({
      raw <- readBin(con, what = "raw", n = 4096)
      if (length(raw) > 0) rawToChar(raw) else ""
    }, error = function(e) {
      NA_character_
    })
    reply_ok <- !is.na(reply) && nzchar(reply)
  }, error = function(e) {
    err <<- conditionMessage(e)
  }, finally = {
    if (!is.null(con)) close(con)
  })

  total_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000

  data.frame(
    ts = timestamp_text(Sys.time()),
    host = host,
    port = port,
    probe = "tcp",
    success = transport_ok && reply_ok,
    transport_ok = transport_ok,
    reply_ok = reply_ok,
    connect_ms = connect_ms,
    total_ms = total_ms,
    request = request,
    reply = reply,
    error = err,
    stringsAsFactors = FALSE
  )
}

run_benchmark <- function(targets = read_targets(), run_cfg = read_run_config()) {
  ping_count <- as.integer(as_num(run_cfg[["ping_count"]], 20))
  ping_interval_sec <- as_num(run_cfg[["ping_interval_sec"]], 1)
  tcp_count <- as.integer(as_num(run_cfg[["tcp_count"]], 20))
  tcp_interval_sec <- as_num(run_cfg[["tcp_interval_sec"]], 1)
  tcp_timeout_sec <- as_num(run_cfg[["tcp_timeout_sec"]], 3)
  tcp_default_port <- as.integer(as_num(run_cfg[["tcp_port"]], 9000))
  run_timezone <- normalize_timezone(if ("timezone" %in% names(run_cfg)) run_cfg[["timezone"]] else "UTC")
  output_dir <- run_cfg[["output_dir"]]
  if (is.na(output_dir) || !nzchar(output_dir)) output_dir <- file.path(paths$root, "data", "raw")
  session_tag <- resolve_session_tag(run_cfg, output_dir, fallback = "session")
  if (tolower(basename(output_dir)) != tolower(session_tag)) {
    output_dir <- file.path(output_dir, session_tag)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  all_results <- list()

  for (i in seq_len(nrow(targets))) {
    target <- targets[i, ]
    port <- resolve_port(target$port, tcp_default_port)
    message("Target: ", target$label, " (", target$host, ": ", port, ")")

    ping_rows <- vector("list", ping_count)
    tcp_rows <- vector("list", tcp_count)

    for (n in seq_len(ping_count)) {
      ping_rows[[n]] <- ping_once(target$host)
      if (n < ping_count) Sys.sleep(ping_interval_sec)
    }

    for (n in seq_len(tcp_count)) {
      tcp_rows[[n]] <- tcp_probe(
        host = target$host,
        port = port,
        request = if (is.na(target$request) || !nzchar(target$request)) "HELLO" else target$request,
        timeout_sec = tcp_timeout_sec
      )
      if (n < tcp_count) Sys.sleep(tcp_interval_sec)
    }

    out <- file.path(
      output_dir,
      paste0(
        compact_timestamp(Sys.time(), tz = run_timezone),
        "_",
        gsub("[^A-Za-z0-9_-]", "_", target$label),
        ".csv"
      )
    )
    ping_df <- transform(do.call(rbind, ping_rows), target_label = target$label)
    tcp_df <- transform(do.call(rbind, tcp_rows), target_label = target$label)
    ping_df$session_tag <- session_tag
    tcp_df$session_tag <- session_tag
    ping_df$timezone <- run_timezone
    tcp_df$timezone <- run_timezone
    ping_df$target_host <- target$host
    tcp_df$target_host <- target$host
    ping_df$target_port <- NA_integer_
    tcp_df$target_port <- port
    combined <- bind_rows_union(ping_df, tcp_df)
    char_cols <- vapply(combined, is.character, logical(1))
    combined[char_cols] <- lapply(combined[char_cols], sanitize_text)
    write.csv(combined, out, row.names = FALSE, fileEncoding = "UTF-8")
    all_results[[target$label]] <- combined
  }

  invisible(all_results)
}
