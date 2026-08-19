test_that("safe_mean/safe_median/safe_p95 ignore NA and handle empty input", {
  expect_equal(safe_mean(c(1, 2, 3, NA)), 2)
  expect_equal(safe_median(c(1, 2, 3, NA)), 2)
  expect_equal(safe_p95(1:100), 95, tolerance = 1)
  expect_true(is.na(safe_mean(c(NA, NA))))
  expect_true(is.na(safe_median(numeric(0))))
  expect_true(is.na(safe_p95(numeric(0))))
})

test_that("benchmark_target_overview recomputes median/p95 from raw rows instead of weighted-averaging group medians", {
  rows <- data.frame(
    session_tag = c(rep("s1", 5), "s2"),
    target_label = "T1",
    probe = "ping",
    metric_ms = c(1, 1, 1, 1, 1, 100),
    success = TRUE,
    stringsAsFactors = FALSE
  )
  summary_tbl <- benchmark_run_summary(rows)
  out <- benchmark_target_overview(summary_tbl, rows)

  true_median <- safe_median(rows$metric_ms)
  expect_equal(out$metric_ms_median[out$target_label == "T1"], true_median)

  # A weighted mean of the two group medians is a very different (wrong)
  # number here -- this pins down that the fix actually changed behavior,
  # not just that it returns *some* number.
  naive_weighted_mean_of_medians <- weighted.mean(summary_tbl$metric_ms_median, w = summary_tbl$rows)
  expect_gt(abs(naive_weighted_mean_of_medians - true_median), 10)
})

test_that("benchmark_target_overview returns NA median/p95 when raw benchmark_rows are not supplied", {
  rows <- data.frame(
    session_tag = c("s1", "s2"),
    target_label = "T1",
    probe = "ping",
    metric_ms = c(1, 100),
    success = TRUE,
    stringsAsFactors = FALSE
  )
  summary_tbl <- benchmark_run_summary(rows)
  out <- benchmark_target_overview(summary_tbl)

  expect_true(is.na(out$metric_ms_median))
  expect_true(is.na(out$metric_ms_p95))
})

test_that("benchmark_plot_group_key keeps different sessions of the same target/probe apart", {
  bench <- data.frame(
    target_label = c("Geraet1", "Geraet1", "Geraet1"),
    probe = c("tcp", "tcp", "tcp"),
    session_tag = c("direct", "switch", "switch"),
    stringsAsFactors = FALSE
  )
  grp <- benchmark_plot_group_key(bench)

  # Before the fix, target_label + probe alone would have merged "direct"
  # and "switch" into a single boxplot group even though they are two
  # different measurement runs.
  expect_length(unique(grp), 2)
  expect_setequal(levels(grp), c("Geraet1.tcp.direct", "Geraet1.tcp.switch"))
})

test_that("benchmark_plot_group_key tolerates a missing session_tag column", {
  bench <- data.frame(target_label = "Geraet1", probe = "ping", stringsAsFactors = FALSE)
  grp <- benchmark_plot_group_key(bench)
  expect_equal(as.character(grp), "Geraet1.ping.n/a")
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
