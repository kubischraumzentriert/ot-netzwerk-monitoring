user_lib <- Sys.getenv("R_LIBS_USER")
if (!nzchar(user_lib)) {
  user_lib <- file.path(
    Sys.getenv("USERPROFILE"),
    "AppData",
    "Local",
    "R",
    "win-library",
    paste0(R.version$major, ".", strsplit(R.version$minor, "\\.", fixed = FALSE)[[1]][1])
  )
}

if (dir.exists(user_lib)) {
  .libPaths(c(user_lib, .libPaths()))
}

