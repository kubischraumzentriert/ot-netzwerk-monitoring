test_that("safe_mean/safe_median/safe_p95 ignore NA and handle empty input", {
  expect_equal(safe_mean(c(1, 2, 3, NA)), 2)
  expect_equal(safe_median(c(1, 2, 3, NA)), 2)
  expect_equal(safe_p95(1:100), 95, tolerance = 1)
  expect_true(is.na(safe_mean(c(NA, NA))))
  expect_true(is.na(safe_median(numeric(0))))
  expect_true(is.na(safe_p95(numeric(0))))
})

test_that("list_benchmark_files excludes inventory, webapp, scans, pcap and suricata folders", {
  root <- tempfile("raw_")
  dir.create(file.path(root, "direct"), recursive = TRUE)
  dir.create(file.path(root, "switch"), recursive = TRUE)
  dir.create(file.path(root, "inventory", "20260101"), recursive = TRUE)
  dir.create(file.path(root, "webapp"), recursive = TRUE)
  dir.create(file.path(root, "scans", "nmap"), recursive = TRUE)
  dir.create(file.path(root, "pcap"), recursive = TRUE)
  dir.create(file.path(root, "suricata"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE))

  write.csv(data.frame(x = 1), file.path(root, "direct", "run1.csv"), row.names = FALSE)
  write.csv(data.frame(x = 1), file.path(root, "switch", "run1.csv"), row.names = FALSE)
  write.csv(data.frame(x = 1), file.path(root, "inventory", "20260101", "host_info.csv"), row.names = FALSE)
  write.csv(data.frame(x = 1), file.path(root, "webapp", "run1.csv"), row.names = FALSE)
  write.csv(data.frame(x = 1), file.path(root, "scans", "nmap", "scan1.csv"), row.names = FALSE)

  files <- list_benchmark_files(root)
  basenames <- basename(dirname(files))

  expect_setequal(basenames, c("direct", "switch"))
  expect_false(any(grepl("inventory|webapp|scans|pcap|suricata", files)))
})

test_that("list_benchmark_files returns character(0) for a missing root", {
  expect_equal(list_benchmark_files(tempfile("does-not-exist_")), character(0))
})

test_that("benchmark_session_compare requires both base_tag and compare_tag", {
  rows <- data.frame(
    session_tag = c("a", "a", "b", "b"),
    target_label = c("Geraet1", "Geraet1", "Geraet1", "Geraet1"),
    probe = c("ping", "tcp", "ping", "tcp"),
    metric_ms = c(1, NA, 2, NA),
    connect_ms = c(NA, 3, NA, 4),
    total_ms = c(NA, 5, NA, 6),
    success = c(TRUE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  expect_equal(nrow(benchmark_session_compare(rows)), 0)
  expect_equal(nrow(benchmark_session_compare(rows, base_tag = "a")), 0)
  expect_equal(nrow(benchmark_session_compare(rows, base_tag = "", compare_tag = "b")), 0)
})

test_that("benchmark_session_compare compares exactly the two requested tags", {
  rows <- data.frame(
    session_tag = c("a", "a", "b", "b", "c", "c"),
    target_label = rep("Geraet1", 6),
    probe = rep(c("ping", "tcp"), 3),
    metric_ms = c(1, NA, 2, NA, 99, NA),
    connect_ms = c(NA, 3, NA, 4, NA, 99),
    total_ms = c(NA, 5, NA, 6, NA, 99),
    success = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  out <- benchmark_session_compare(rows, base_tag = "a", compare_tag = "b")
  expect_equal(nrow(out), 2)
  expect_true(all(out$base_tag == "a"))
  expect_true(all(out$compare_tag == "b"))
  # session "c" (metric_ms/connect_ms/total_ms == 99) must never leak into the comparison
  expect_false(99 %in% c(out$base_metric_ms_mean, out$compare_metric_ms_mean, out$base_connect_ms_mean, out$compare_connect_ms_mean, out$base_total_ms_mean, out$compare_total_ms_mean))
})

test_that("benchmark_session_compare returns empty for an unknown tag", {
  rows <- data.frame(
    session_tag = c("a", "b"),
    target_label = c("Geraet1", "Geraet1"),
    probe = c("ping", "ping"),
    success = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )
  expect_equal(nrow(benchmark_session_compare(rows, base_tag = "a", compare_tag = "does-not-exist")), 0)
})
