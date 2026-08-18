SELECT
  computer_name,
  collected_at,
  adapter_count,
  arp_count,
  tcp_count,
  listening_count,
  primary_ipv4
FROM inventory_overview
ORDER BY collected_at DESC, computer_name
LIMIT 20;
