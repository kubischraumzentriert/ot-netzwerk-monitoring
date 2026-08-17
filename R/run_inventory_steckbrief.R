source("R/01_inventory_report.R", local = TRUE)

parse_inventory_args <- function(args) {
  opts <- list(
    session = NA_character_,
    out = NA_character_
  )

  for (arg in args) {
    if (startsWith(arg, "--session=")) {
      opts$session <- sub("^--session=", "", arg)
    } else if (startsWith(arg, "--out=")) {
      opts$out <- sub("^--out=", "", arg)
    }
  }

  opts
}

main <- function() {
  opts <- parse_inventory_args(commandArgs(trailingOnly = TRUE))
  session_dir <- if (!is.na(opts$session) && nzchar(opts$session)) opts$session else latest_inventory_dir()
  output_file <- if (!is.na(opts$out) && nzchar(opts$out)) opts$out else NULL
  out <- inventory_steckbrief(session_dir = session_dir, output_file = output_file)
  message("Wrote inventory steckbrief: ", out)
  invisible(out)
}

invisible(main())
