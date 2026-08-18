WITH benchmark_context AS (
  SELECT
    session_tag,
    target_label,
    probe,
    MIN(target_host) AS target_host,
    MIN(target_port) AS target_port,
    COUNT(DISTINCT target_port) FILTER (WHERE target_port IS NOT NULL) AS target_port_count
  FROM benchmark_rows
  GROUP BY session_tag, target_label, probe
)
SELECT
  overview.session_tag,
  overview.target_label,
  context.target_host,
  overview.probe,
  CASE
    WHEN overview.probe <> 'tcp' THEN 'n/a'
    WHEN context.target_port_count IS NULL OR context.target_port_count = 0 THEN 'n/a'
    WHEN context.target_port_count = 1 THEN CAST(context.target_port AS VARCHAR)
    ELSE CONCAT(CAST(context.target_port AS VARCHAR), ' (+', CAST(context.target_port_count - 1 AS VARCHAR), ' weitere)')
  END AS target_port,
  overview.rows,
  overview.success_rate,
  overview.metric_ms_mean,
  overview.metric_ms_median,
  overview.metric_ms_p95,
  overview.connect_ms_mean,
  overview.total_ms_mean
FROM benchmark_overview AS overview
LEFT JOIN benchmark_context AS context
  ON context.session_tag = overview.session_tag
 AND context.target_label = overview.target_label
 AND context.probe = overview.probe
ORDER BY overview.session_tag, overview.target_label, overview.probe;
