CREATE TABLE IF NOT EXISTS schema_metadata (
  schema_name VARCHAR,
  schema_version VARCHAR,
  created_at TIMESTAMP,
  note VARCHAR
);

CREATE TABLE IF NOT EXISTS inventory_sessions (
  session_dir VARCHAR,
  computer_name VARCHAR,
  collected_at VARCHAR,
  adapter_count INTEGER,
  arp_count INTEGER,
  tcp_count INTEGER,
  listening_count INTEGER,
  primary_ipv4 VARCHAR,
  primary_mac VARCHAR
);

CREATE TABLE IF NOT EXISTS benchmark_rows (
  ts TIMESTAMP,
  host VARCHAR,
  probe VARCHAR,
  success BOOLEAN,
  metric_ms DOUBLE,
  elapsed_ms DOUBLE,
  detail VARCHAR,
  port INTEGER,
  connect_ms DOUBLE,
  total_ms DOUBLE,
  request VARCHAR,
  reply VARCHAR,
  error VARCHAR,
  target_label VARCHAR,
  session_tag VARCHAR,
  target_host VARCHAR,
  target_port INTEGER,
  source_file VARCHAR
);

CREATE TABLE IF NOT EXISTS benchmark_summary (
  session_tag VARCHAR,
  target_label VARCHAR,
  probe VARCHAR,
  rows INTEGER,
  success_rate DOUBLE,
  metric_ms_mean DOUBLE,
  metric_ms_median DOUBLE,
  metric_ms_p95 DOUBLE,
  connect_ms_mean DOUBLE,
  total_ms_mean DOUBLE
);
