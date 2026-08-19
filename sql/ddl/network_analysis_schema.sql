CREATE TABLE IF NOT EXISTS schema_metadata (
  schema_name VARCHAR,
  schema_version VARCHAR,
  created_at TIMESTAMP,
  note VARCHAR
);

CREATE SEQUENCE IF NOT EXISTS inventory_sessions_seq START 1;
CREATE TABLE IF NOT EXISTS inventory_sessions (
  session_id BIGINT PRIMARY KEY DEFAULT nextval('inventory_sessions_seq'),
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

CREATE SEQUENCE IF NOT EXISTS benchmark_rows_seq START 1;
CREATE TABLE IF NOT EXISTS benchmark_rows (
  row_id BIGINT PRIMARY KEY DEFAULT nextval('benchmark_rows_seq'),
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
  transport_ok BOOLEAN,
  reply_ok BOOLEAN,
  request VARCHAR,
  reply VARCHAR,
  error VARCHAR,
  target_label VARCHAR,
  session_tag VARCHAR,
  timezone VARCHAR,
  target_host VARCHAR,
  target_port INTEGER,
  source_file VARCHAR
);

CREATE SEQUENCE IF NOT EXISTS benchmark_summary_seq START 1;
CREATE TABLE IF NOT EXISTS benchmark_summary (
  summary_id BIGINT PRIMARY KEY DEFAULT nextval('benchmark_summary_seq'),
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

CREATE OR REPLACE VIEW inventory_overview AS
SELECT
  session_id,
  session_dir,
  computer_name,
  collected_at,
  adapter_count,
  arp_count,
  tcp_count,
  listening_count,
  primary_ipv4,
  primary_mac
FROM inventory_sessions;

CREATE OR REPLACE VIEW benchmark_overview AS
SELECT
  summary_id,
  session_tag,
  target_label,
  probe,
  rows,
  success_rate,
  metric_ms_mean,
  metric_ms_median,
  metric_ms_p95,
  connect_ms_mean,
  total_ms_mean
FROM benchmark_summary;

CREATE OR REPLACE VIEW benchmark_rows_ping AS
SELECT *
FROM benchmark_rows
WHERE probe = 'ping';

CREATE OR REPLACE VIEW benchmark_rows_tcp AS
SELECT *
FROM benchmark_rows
WHERE probe = 'tcp';
