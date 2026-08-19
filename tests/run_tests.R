if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Package 'testthat' is required to run the test suite. Install it via renv::install('testthat') or install.packages('testthat').")
}

Sys.setenv(OT_NETZWERK_PROJECT_ROOT = normalizePath(getwd(), winslash = "/", mustWork = TRUE))

results <- testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
