source("R/00_setup.R", local = TRUE)

latest_inventory_dir <- function(root = paths$inventory) {
  if (!dir.exists(root)) return(NA_character_)
  dirs <- list.dirs(root, full.names = TRUE, recursive = FALSE)
  if (!length(dirs)) return(NA_character_)
  dirs[order(file.info(dirs)$mtime, decreasing = TRUE)][1]
}

fmt_md_table <- function(df, max_rows = 20) {
  if (!is.data.frame(df) || nrow(df) == 0) return("_keine Daten_")
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(df) > max_rows) df <- df[seq_len(max_rows), , drop = FALSE]
  cols <- names(df)
  header <- paste0("| ", paste(cols, collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

normalize_empty <- function(x, fallback = "n/a") {
  if (length(x) == 0 || all(is.na(x)) || !nzchar(as.character(x)[1])) fallback else as.character(x)[1]
}

parse_mac <- function(x) {
  m <- regmatches(x, regexpr("([0-9A-Fa-f]{2}([-:])[0-9A-Fa-f]{2}(\\2[0-9A-Fa-f]{2}){4})", x, perl = TRUE))
  if (length(m) == 0) NA_character_ else m[1]
}

parse_ipv4 <- function(x) {
  m <- regmatches(x, regexpr("([0-9]{1,3}(\\.[0-9]{1,3}){3})", x, perl = TRUE))
  if (length(m) == 0) NA_character_ else m[1]
}

parse_ipconfig_blocks <- function(text) {
  lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1]])
  lines <- lines[lines != ""]
  header_idx <- which(grepl("adapter", lines, ignore.case = TRUE) & grepl(":\\s*$", lines))
  if (!length(header_idx)) return(data.frame())

  rows <- lapply(seq_along(header_idx), function(i) {
    start <- header_idx[i]
    end <- if (i < length(header_idx)) header_idx[i + 1] - 1 else length(lines)
    block <- lines[start:end]
    body <- paste(block, collapse = "\n")
    desc_line <- block[grepl("Beschreibung|Description", block, ignore.case = TRUE)][1]
    media_line <- block[grepl("Medienstatus|Media State", block, ignore.case = TRUE)][1]
    data.frame(
      adapter = block[1],
      description = ifelse(length(desc_line) && !is.na(desc_line), sub("^.*:\\s*", "", desc_line), NA_character_),
      media_state = ifelse(length(media_line) && !is.na(media_line), sub("^.*:\\s*", "", media_line), NA_character_),
      ipv4 = parse_ipv4(body),
      mac = parse_mac(body),
      has_dhcp = grepl("DHCP", body, ignore.case = TRUE),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

parse_arp_entries <- function(text) {
  lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1]])
  lines <- lines[lines != ""]
  lines <- lines[grepl("^[0-9]{1,3}(\\.[0-9]{1,3}){3}\\s+", lines)]
  if (!length(lines)) return(data.frame())
  rows <- lapply(lines, function(line) {
    parts <- strsplit(line, "[[:space:]]+")[[1]]
    if (length(parts) < 3) return(NULL)
    data.frame(
      ip = parts[1],
      mac = parts[2],
      type = parts[3],
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}

parse_netstat_entries <- function(text) {
  lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1]])
  lines <- lines[grepl("^(TCP|UDP)\\s", toupper(lines))]
  if (!length(lines)) return(data.frame())
  rows <- lapply(lines, function(line) {
    parts <- strsplit(line, "[[:space:]]+")[[1]]
    proto <- toupper(parts[1])
    if (proto == "TCP" && length(parts) >= 5) {
      data.frame(
        protocol = proto,
        local_address = parts[2],
        foreign_address = parts[3],
        state = parts[length(parts) - 1],
        pid = parts[length(parts)],
        stringsAsFactors = FALSE
      )
    } else if (proto == "UDP" && length(parts) >= 4) {
      data.frame(
        protocol = proto,
        local_address = parts[2],
        foreign_address = parts[3],
        state = NA_character_,
        pid = parts[length(parts)],
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}

read_inventory_session <- function(session_dir) {
  ipconfig_file <- file.path(session_dir, "ipconfig_all.txt")
  netsh_file <- file.path(session_dir, "netsh_interfaces.txt")
  arp_file <- file.path(session_dir, "arp_a.txt")
  netstat_file <- file.path(session_dir, "netstat_ano.txt")

  ipconfig_text <- read_text_safe(ipconfig_file)
  netsh_text <- read_text_safe(netsh_file)
  arp_text <- read_text_safe(arp_file)
  netstat_text <- read_text_safe(netstat_file)

  list(
    host_info = read_csv_safe(file.path(session_dir, "host_info.csv")),
    net_adapters = parse_ipconfig_blocks(ipconfig_text),
    net_ip_configuration = if (nchar(netsh_text)) data.frame(raw = netsh_text, stringsAsFactors = FALSE) else data.frame(),
    arp_neighbors = parse_arp_entries(arp_text),
    tcp_connections = parse_netstat_entries(netstat_text),
    ipconfig_text = ipconfig_text,
    netsh_text = netsh_text,
    arp_text = arp_text,
    netstat_text = netstat_text
  )
}

inventory_steckbrief <- function(session_dir = latest_inventory_dir()) {
  if (is.na(session_dir) || !dir.exists(session_dir)) {
    stop("No inventory session found")
  }
  inv <- read_inventory_session(session_dir)

  host_keys <- if (nrow(inv$host_info)) trimws(tolower(inv$host_info$key)) else character()
  computer_name <- if (nrow(inv$host_info)) normalize_empty(inv$host_info$value[host_keys == "computer_name"]) else "n/a"
  collected_at <- if (nrow(inv$host_info)) normalize_empty(inv$host_info$value[host_keys == "collected_at"]) else "n/a"

  adapter_count <- nrow(inv$net_adapters)
  arp_count <- nrow(inv$arp_neighbors)
  tcp_count <- nrow(inv$tcp_connections)
  listening_count <- if (tcp_count) {
    sum(
      inv$tcp_connections$protocol == "TCP" &
        inv$tcp_connections$foreign_address %in% c("0.0.0.0:0", "[::]:0"),
      na.rm = TRUE
    )
  } else {
    0
  }

  top_adapters <- if (adapter_count) {
    inv$net_adapters[, intersect(c("adapter", "description", "media_state", "ipv4", "mac", "has_dhcp"), names(inv$net_adapters)), drop = FALSE]
  } else {
    data.frame()
  }

  arp_preview <- if (arp_count) {
    inv$arp_neighbors[, intersect(c("ip", "mac", "type"), names(inv$arp_neighbors)), drop = FALSE]
  } else {
    data.frame()
  }

  conn_preview <- if (tcp_count) {
    inv$tcp_connections[, intersect(c("protocol", "local_address", "foreign_address", "state", "pid"), names(inv$tcp_connections)), drop = FALSE]
  } else {
    data.frame()
  }

  md <- c(
    "# Netzwerk-Steckbrief",
    "",
    paste0("- Computer: `", computer_name, "`"),
    paste0("- Erfasst am: `", collected_at, "`"),
    paste0("- Session: `", session_dir, "`"),
    "",
    "## Kurzueberblick",
    "",
    paste0("- Netzwerkadapter: ", adapter_count),
    paste0("- ARP/Neighbor-Eintraege: ", arp_count),
    paste0("- TCP-Verbindungen: ", tcp_count),
    paste0("- Listening-Ports: ", listening_count),
    "",
    "## Adapter aus ipconfig",
    "",
    fmt_md_table(top_adapters, max_rows = 10),
    "",
    "## Nachbarn / ARP",
    "",
    fmt_md_table(arp_preview, max_rows = 15),
    "",
    "## TCP-Verbindungen",
    "",
    fmt_md_table(conn_preview, max_rows = 15),
    "",
    "## Hinweise",
    "",
    "- Die Rohdaten liegen im jeweiligen Inventur-Ordner.",
    "- Diese Ausgabe ist bewusst kompakt, damit du mehrere Maschinen spaeter vergleichen kannst.",
    "- Wenn DuckDB verfuegbar ist, koennen wir die Tabellen zusaetzlich in eine lokale Datenbank schreiben."
  )

  out_file <- file.path(paths$reports, paste0("steckbrief_", basename(session_dir), ".md"))
  writeLines(md, out_file, useBytes = TRUE)
  out_file
}
