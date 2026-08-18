SELECT
  target_label,
  probe,
  rows,
  success_rate,
  metric_ms_mean,
  metric_ms_median,
  metric_ms_p95,
  connect_ms_mean,
  total_ms_mean
FROM benchmark_overview
ORDER BY target_label, probe;
