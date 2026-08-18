user_r_lib <- Sys.getenv("R_LIBS_USER")
fallback_user_lib <- file.path(
  Sys.getenv("USERPROFILE"),
  "AppData",
  "Local",
  "R",
  "win-library",
  paste0(R.version$major, ".", strsplit(R.version$minor, "\\.", fixed = FALSE)[[1]][1])
)

candidate_libs <- unique(c(
  if (nzchar(user_r_lib)) user_r_lib else character(),
  fallback_user_lib
))
candidate_libs <- candidate_libs[nzchar(candidate_libs)]

if (length(candidate_libs)) {
  .libPaths(c(candidate_libs, .libPaths()))
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

paths <- list(
  root = project_root,
  configs = file.path(project_root, "configs"),
  data_raw = file.path(project_root, "data", "raw"),
  data_processed = file.path(project_root, "data", "processed"),
  inventory = file.path(project_root, "data", "raw", "inventory"),
  docs = file.path(project_root, "docs"),
  reports = file.path(project_root, "reports")
)

dir.create(paths$data_raw, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$data_processed, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$inventory, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$reports, recursive = TRUE, showWarnings = FALSE)

read_run_config <- function(path = file.path(paths$configs, "run.csv")) {
  if (!file.exists(path)) {
    path <- file.path(paths$configs, "run.example.csv")
  }
  cfg <- read.csv(path, stringsAsFactors = FALSE)
  stats::setNames(cfg$value, cfg$key)
}

read_targets <- function(path = file.path(paths$configs, "targets.csv")) {
  private_path <- file.path(paths$configs, "targets.private.csv")
  if (identical(path, file.path(paths$configs, "targets.csv")) && file.exists(private_path)) {
    path <- private_path
  }
  if (!file.exists(path)) {
    path <- file.path(paths$configs, "targets.example.csv")
  }
  targets <- read.csv(path, stringsAsFactors = FALSE)
  targets$port <- as.integer(targets$port)
  targets
}

default_targets_path <- function() {
  private_path <- file.path(paths$configs, "targets.private.csv")
  if (file.exists(private_path)) {
    private_path
  } else {
    file.path(paths$configs, "targets.csv")
  }
}

as_num <- function(x, default = NA_real_) {
  if (length(x) == 0 || is.na(x) || !nzchar(x)) return(default)
  suppressWarnings(as.numeric(x))
}

safe_component <- function(x, fallback = "default") {
  x <- ifelse(is.na(x) || !nzchar(x), fallback, x)
  gsub("[^A-Za-z0-9_-]", "_", x)
}

read_csv_safe <- function(path) {
  if (!file.exists(path)) return(data.frame())
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
}

read_text_safe <- function(path) {
  if (!file.exists(path)) return("")
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

dbi_available <- function() {
  requireNamespace("DBI", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)
}

open_duckdb <- function(db_path = file.path(paths$data_processed, "network_analysis.duckdb")) {
  if (!dbi_available()) {
    stop("DBI/duckdb packages are not installed")
  }
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)
  con
}
