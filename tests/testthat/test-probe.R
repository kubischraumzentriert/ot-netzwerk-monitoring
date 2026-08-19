test_that("windows_oem_encoding returns a codepage label with a safe fallback", {
  # On non-Windows this exercises the fallback path (readRegistry is not
  # available), on Windows it should reflect the real OEM codepage.
  enc <- windows_oem_encoding()
  expect_type(enc, "character")
  expect_true(grepl("^CP[0-9]+$", enc))
})

test_that("run_ping_command decodes ping.exe's OEM-codepage output as valid UTF-8", {
  # Regression test: ping.exe writes console output in the OEM codepage
  # (e.g. CP850 on German Windows), not UTF-8. Capturing it as-is produced
  # mojibake and "invalid UTF-8" warnings from grepl()/regexec() downstream.
  skip_on_os(c("mac", "linux", "solaris"))
  res <- run_ping_command("127.0.0.1", timeout_sec = 1)
  expect_true(all(validUTF8(res)))
  expect_true(any(grepl("TTL=", res, ignore.case = TRUE)))
})

test_that("combine_probe_rows attaches the shared columns to non-empty rows", {
  rows_list <- list(
    data.frame(metric_ms = 1, stringsAsFactors = FALSE),
    data.frame(metric_ms = 2, stringsAsFactors = FALSE)
  )
  df <- combine_probe_rows(rows_list, "Geraet1", "direct", "UTC", "192.0.2.11", 9000L)
  expect_equal(nrow(df), 2)
  expect_equal(df$target_label, c("Geraet1", "Geraet1"))
  expect_equal(df$session_tag, c("direct", "direct"))
  expect_equal(df$target_port, c(9000L, 9000L))
})

test_that("combine_probe_rows returns an empty data frame for zero probes instead of erroring", {
  # Regression test: an empty rows_list previously reached
  # transform(do.call(rbind, list()), ...), which errored because
  # do.call(rbind, list()) is NULL, not a data frame.
  df <- combine_probe_rows(list(), "Geraet1", "direct", "UTC", "192.0.2.11", 9000L)
  expect_true(is.data.frame(df))
  expect_equal(nrow(df), 0)
})

test_that("bind_rows_union combines a populated probe data frame with an empty one", {
  # Regression test: combine_probe_rows(list(), ...) returns a truly empty
  # (0-row, 0-col) data.frame(). Filling in the missing columns for that
  # frame previously assigned a length-1 NA to a 0-row data frame, which
  # errors ("replacement has 1 row, data has 0").
  ping_df <- combine_probe_rows(
    list(data.frame(probe = "ping", metric_ms = 5, stringsAsFactors = FALSE)),
    "Geraet1", "direct", "UTC", "192.0.2.11", NA_integer_
  )
  tcp_df <- combine_probe_rows(list(), "Geraet1", "direct", "UTC", "192.0.2.11", 9000L)

  combined <- bind_rows_union(ping_df, tcp_df)
  expect_equal(nrow(combined), 1)
  expect_equal(combined$probe, "ping")
})

test_that("run_benchmark tolerates ping_count=0 and tcp_count=0 without erroring", {
  # Fully zero counts skip both probe loops entirely, so this does not
  # depend on real network/ping availability and stays portable across CI.
  targets <- data.frame(label = "Loopback", host = "127.0.0.1", port = 9000L, request = "HELLO", stringsAsFactors = FALSE)
  run_cfg <- c(
    ping_count = "0", ping_interval_sec = "0", tcp_count = "0", tcp_interval_sec = "0",
    tcp_timeout_sec = "1", tcp_port = "9000", session_tag = "zero-both", output_dir = tempfile("bench_zero_")
  )
  res <- run_benchmark(targets = targets, run_cfg = run_cfg)
  expect_true(is.data.frame(res[["Loopback"]]))
  expect_equal(nrow(res[["Loopback"]]), 0)
})

test_that("resolve_port uses a valid target port and falls back otherwise", {
  expect_equal(resolve_port("8080", 9000), 8080L)
  expect_equal(resolve_port(NA, 9000), 9000L)
  expect_equal(resolve_port("", 9000), 9000L)
  expect_equal(resolve_port("0", 9000), 9000L)
  expect_equal(resolve_port("-1", 9000), 9000L)
  expect_equal(resolve_port(NA, NA), 9000L)
})

test_that("extract_ping_rtt_ms parses German and English ping output", {
  german <- c("Antwort von 192.0.2.11: Bytes=32 Zeit=15ms TTL=64")
  english <- c("Reply from 192.0.2.11: bytes=32 time=23ms TTL=64")
  expect_equal(extract_ping_rtt_ms(german), 15)
  expect_equal(extract_ping_rtt_ms(english), 23)
})

test_that("extract_ping_rtt_ms picks the minimum RTT across multiple lines", {
  lines <- c(
    "Antwort von 192.0.2.11: Bytes=32 Zeit=30ms TTL=64",
    "Antwort von 192.0.2.11: Bytes=32 Zeit=12ms TTL=64"
  )
  expect_equal(extract_ping_rtt_ms(lines), 12)
})

test_that("extract_ping_rtt_ms returns NA when no RTT can be found", {
  expect_true(is.na(extract_ping_rtt_ms(character())))
  expect_true(is.na(extract_ping_rtt_ms(c("Zeitueberschreitung der Anforderung."))))
})

test_that("sanitize_text strips control characters and collapses onto one line", {
  x <- sanitize_text("line1\r\nline2\tend")
  expect_false(grepl("[[:cntrl:]]", x))
  expect_equal(length(strsplit(x, "\n", fixed = TRUE)[[1]]), 1)
})

test_that("sanitize_text marks removed newlines with a literal '\\n' placeholder", {
  # Regression test: the gsub() replacement previously used an
  # under-escaped "\\n" that perl=TRUE interpreted as a real newline
  # escape instead of the literal two-character placeholder, which the
  # following control-character cleanup then silently swallowed again.
  x <- sanitize_text("line1\r\nline2")
  expect_equal(x, "line1 \\n line2")
})

test_that("sanitize_text turns NA/empty input into an empty string", {
  expect_equal(sanitize_text(NA), "")
})

test_that("bind_rows_union aligns differing columns and fills missing values with NA", {
  a <- data.frame(x = 1, y = "a", stringsAsFactors = FALSE)
  b <- data.frame(x = 2, z = "b", stringsAsFactors = FALSE)
  out <- bind_rows_union(a, b)
  expect_equal(nrow(out), 2)
  expect_setequal(names(out), c("x", "y", "z"))
  expect_true(is.na(out$z[1]))
  expect_true(is.na(out$y[2]))
})

test_that("bind_rows_union returns an empty data frame for no input", {
  expect_equal(nrow(bind_rows_union()), 0)
})
