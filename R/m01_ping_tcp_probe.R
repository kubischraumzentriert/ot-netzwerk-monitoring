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

sanitize_text <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("\r\n|\r|\n", " \\n ", x)
  x <- gsub("[[:cntrl:]]", " ", x)
  trimws(x)
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
  rtt_ms <- NA_real_

  if (success && .Platform$OS.type == "windows") {
    hit <- regmatches(text, regexpr("Zeit[=< ]+([0-9]+)ms", text, perl = TRUE, ignore.case = TRUE))
    if (length(hit) == 0 || !nzchar(hit)) {
      hit <- regmatches(text, regexpr("time[=< ]+([0-9.]+) ?ms", text, perl = TRUE, ignore.case = TRUE))
    }
    if (length(hit) > 0 && nzchar(hit)) {
      rtt_ms <- as.numeric(gsub("[^0-9.]", "", hit))
    }
  }

  data.frame(
    ts = Sys.time(),
    host = host,
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
  ok <- FALSE
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
    reply <- tryCatch({
      raw <- readBin(con, what = "raw", n = 4096)
      if (length(raw) > 0) rawToChar(raw) else ""
    }, error = function(e) {
      NA_character_
    })
    ok <- TRUE
  }, error = function(e) {
    err <<- conditionMessage(e)
  }, finally = {
    if (!is.null(con)) close(con)
    total_ms <<- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
  })

  data.frame(
    ts = Sys.time(),
    host = host,
    port = port,
    probe = "tcp",
    success = ok,
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
  output_dir <- run_cfg[["output_dir"]]
  if (is.na(output_dir) || !nzchar(output_dir)) output_dir <- file.path(paths$root, "data", "raw")
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
        format(Sys.time(), "%Y%m%d_%H%M%S"),
        "_",
        gsub("[^A-Za-z0-9_-]", "_", target$label),
        ".csv"
      )
    )
    ping_df <- transform(do.call(rbind, ping_rows), target_label = target$label)
    tcp_df <- transform(do.call(rbind, tcp_rows), target_label = target$label)
    combined <- bind_rows_union(ping_df, tcp_df)
    char_cols <- vapply(combined, is.character, logical(1))
    combined[char_cols] <- lapply(combined[char_cols], sanitize_text)
    write.csv(combined, out, row.names = FALSE, fileEncoding = "UTF-8")
    all_results[[target$label]] <- combined
  }

  invisible(all_results)
}
