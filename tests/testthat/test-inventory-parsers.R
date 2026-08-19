test_that("parse_mac extracts a MAC address in either separator style", {
  expect_equal(parse_mac("Physikalische Adresse: B0-5C-DA-F1-41-E1"), "B0-5C-DA-F1-41-E1")
  expect_equal(parse_mac("mac: aa:bb:cc:dd:ee:ff done"), "aa:bb:cc:dd:ee:ff")
  expect_true(is.na(parse_mac("no mac here")))
})

test_that("parse_ipv4 extracts the first IPv4 address", {
  expect_equal(parse_ipv4("IPv4-Adresse. . . . . . . . . . : 192.168.56.1"), "192.168.56.1")
  expect_true(is.na(parse_ipv4("no address here")))
})

test_that("parse_arp_entries parses standard arp -a output lines", {
  text <- paste(
    "Schnittstelle: 192.168.56.1 --- 0xb",
    "  Internetadresse      Physische Adresse     Typ",
    "  192.168.56.254       aa-bb-cc-dd-ee-ff     dynamisch",
    "  192.168.56.255       ff-ff-ff-ff-ff-ff     statisch",
    sep = "\n"
  )
  out <- parse_arp_entries(text)
  expect_equal(nrow(out), 2)
  expect_equal(out$interface, c("192.168.56.1", "192.168.56.1"))
  expect_equal(out$ip, c("192.168.56.254", "192.168.56.255"))
  expect_equal(out$type, c("dynamisch", "statisch"))
})

test_that("parse_arp_entries keeps entries from different interfaces apart instead of merging them", {
  # Regression test: the same multicast address legitimately appears once
  # per interface. Before tracking the interface header, these looked like
  # accidental duplicate rows with no way to tell them apart.
  text <- paste(
    "Schnittstelle: 192.168.42.155 --- 0x6",
    "  Internetadresse       Physische Adresse     Typ",
    "  224.0.0.22            01-00-5e-00-00-16     statisch",
    "",
    "Schnittstelle: 192.168.56.1 --- 0x23",
    "  Internetadresse       Physische Adresse     Typ",
    "  224.0.0.22            01-00-5e-00-00-16     statisch",
    sep = "\n"
  )
  out <- parse_arp_entries(text)
  expect_equal(nrow(out), 2)
  expect_setequal(out$interface, c("192.168.42.155", "192.168.56.1"))
  expect_true(all(out$ip == "224.0.0.22"))
})

test_that("parse_arp_entries also understands the English 'Interface:' header", {
  text <- paste(
    "Interface: 192.0.2.1 --- 0x4",
    "  Internet Address      Physical Address      Type",
    "  192.0.2.254           aa-bb-cc-dd-ee-ff     dynamic",
    sep = "\n"
  )
  out <- parse_arp_entries(text)
  expect_equal(nrow(out), 1)
  expect_equal(out$interface, "192.0.2.1")
})

test_that("parse_arp_entries returns an empty data frame when nothing matches", {
  expect_equal(nrow(parse_arp_entries("no relevant lines here")), 0)
})

test_that("parse_arp_entries tolerates IP lines with no preceding interface header", {
  out <- parse_arp_entries("192.0.2.254           aa-bb-cc-dd-ee-ff     dynamisch")
  expect_equal(nrow(out), 1)
  expect_true(is.na(out$interface))
})

test_that("parse_netstat_entries parses TCP and UDP rows and skips headers", {
  text <- paste(
    "Aktive Verbindungen",
    "",
    "  Proto  Lokale Adresse        Remoteadresse          Status",
    "  TCP    192.0.2.11:9000       0.0.0.0:0              ABHOEREN       1234",
    "  UDP    192.0.2.11:53         *:*                                    5678",
    sep = "\n"
  )
  out <- parse_netstat_entries(text)
  expect_equal(nrow(out), 2)
  expect_equal(out$protocol, c("TCP", "UDP"))
  expect_equal(out$pid, c("1234", "5678"))
  expect_true(is.na(out$state[out$protocol == "UDP"]))
})

test_that("normalize_empty falls back for empty, NA or zero-length input", {
  expect_equal(normalize_empty(NA), "n/a")
  expect_equal(normalize_empty(""), "n/a")
  expect_equal(normalize_empty(character(0)), "n/a")
  expect_equal(normalize_empty("value"), "value")
  expect_equal(normalize_empty(NA, fallback = "unknown"), "unknown")
})

test_that("fmt_md_table renders a markdown table with header and separator", {
  df <- data.frame(a = 1:2, b = c("x", "y"), stringsAsFactors = FALSE)
  out <- fmt_md_table(df)
  lines <- strsplit(out, "\n", fixed = TRUE)[[1]]
  expect_equal(lines[1], "| a | b |")
  expect_equal(lines[2], "| --- | --- |")
  expect_equal(length(lines), 4)
})

test_that("fmt_md_table reports missing data for an empty data frame", {
  expect_equal(fmt_md_table(data.frame()), "_keine Daten_")
})
