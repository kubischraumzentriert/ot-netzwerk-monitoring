test_that("as_num parses valid numbers and falls back on invalid input", {
  expect_equal(as_num("42"), 42)
  expect_equal(as_num("3.5"), 3.5)
  expect_equal(as_num("", 9), 9)
  expect_equal(as_num(NA, 9), 9)
  expect_equal(as_num("not-a-number", 7), NA_real_)
})

test_that("safe_component sanitizes to a filesystem-safe token", {
  expect_equal(safe_component("direct"), "direct")
  expect_equal(safe_component("switch 22 (host)"), "switch_22__host_")
  expect_equal(safe_component(NA, fallback = "session"), "session")
  expect_equal(safe_component("", fallback = "session"), "session")
})

test_that("normalize_timezone accepts valid Olson names and falls back otherwise", {
  expect_equal(normalize_timezone("UTC"), "UTC")
  expect_equal(normalize_timezone("Europe/Berlin"), "Europe/Berlin")
  expect_equal(normalize_timezone("Not/AZone"), "UTC")
  expect_equal(normalize_timezone(NA), "UTC")
  expect_equal(normalize_timezone(""), "UTC")
})

test_that("compact_timestamp and timestamp_text produce parseable output", {
  t <- as.POSIXct("2026-08-19 12:34:56", tz = "UTC")
  expect_equal(compact_timestamp(t, tz = "UTC"), "20260819_123456")
  expect_true(grepl("^2026-08-19T12:34:56", timestamp_text(t, tz = "UTC")))
})

test_that("read_run_config reads key/value pairs from a run config CSV", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  writeLines(c(
    "key,value",
    "ping_count,20",
    "session_tag,test-session",
    "output_dir,data/raw/test"
  ), tmp)

  cfg <- read_run_config(tmp)
  expect_equal(cfg[["ping_count"]], "20")
  expect_equal(cfg[["session_tag"]], "test-session")
  expect_equal(cfg[["output_dir"]], "data/raw/test")
})

test_that("read_run_config falls back to run.example.csv when the path is missing", {
  cfg <- read_run_config(file.path(paths$configs, "does-not-exist.csv"))
  expect_true("session_tag" %in% names(cfg) || "tcp_port" %in% names(cfg))
})

test_that("read_targets normalizes label/host/port/request columns", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  writeLines(c(
    "label,host,port,request",
    "Geraet1, 192.0.2.11 ,9000,HELLO",
    "Geraet2,192.0.2.12,,"
  ), tmp)

  targets <- read_targets(tmp)
  expect_equal(targets$label, c("Geraet1", "Geraet2"))
  expect_equal(targets$host, c("192.0.2.11", "192.0.2.12"))
  expect_equal(targets$port, c(9000L, NA_integer_))
})
