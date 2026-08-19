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
