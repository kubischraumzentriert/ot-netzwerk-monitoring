source("R/04_multirun_analysis.R", local = TRUE)

parse_comparison_args <- function(args) {
  opts <- list(
    out = file.path(paths$reports, "network_session_comparison.md"),
    base = NULL,
    compare = NULL
  )

  for (arg in args) {
    if (startsWith(arg, "--out=")) {
      opts$out <- sub("^--out=", "", arg)
    } else if (startsWith(arg, "--base=")) {
      opts$base <- sub("^--base=", "", arg)
    } else if (startsWith(arg, "--compare=")) {
      opts$compare <- sub("^--compare=", "", arg)
    }
  }

  opts
}

main <- function() {
  opts <- parse_comparison_args(commandArgs(trailingOnly = TRUE))

  if (is.null(opts$base) || !nzchar(opts$base) || is.null(opts$compare) || !nzchar(opts$compare)) {
    bundle <- build_multirun_bundle()
    available_tags <- character()
    if (is.data.frame(bundle$benchmark_rows) && nrow(bundle$benchmark_rows) && "session_tag" %in% names(bundle$benchmark_rows)) {
      available_tags <- sort(unique(bundle$benchmark_rows$session_tag[!is.na(bundle$benchmark_rows$session_tag) & nzchar(bundle$benchmark_rows$session_tag)]))
    }
    tag_hint <- if (length(available_tags)) {
      paste0("Vorhandene Session-Tags: ", paste(available_tags, collapse = ", "), ".")
    } else {
      "Es wurden keine beschrifteten Benchmark-Daten gefunden."
    }
    stop(
      "--base= und --compare= sind erforderlich, es wird kein Session-Tag-Paar automatisch geraten. ",
      tag_hint,
      call. = FALSE
    )
  }

  write_benchmark_comparison_report(
    output_file = opts$out,
    base_tag = opts$base,
    compare_tag = opts$compare
  )
}

invisible(main())
