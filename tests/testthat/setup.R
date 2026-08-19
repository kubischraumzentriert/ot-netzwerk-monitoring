project_root <- Sys.getenv("OT_NETZWERK_PROJECT_ROOT", unset = "")
if (!nzchar(project_root)) {
  stop("OT_NETZWERK_PROJECT_ROOT is not set; run the suite via tests/run_tests.R from the project root.")
}

## The sourced scripts use project-relative source() calls internally
## (e.g. source("R/00_setup.R", local = TRUE)), matching how they are
## invoked in production (Push-Location $ProjectRoot). testthat runs
## setup files with the working directory set to tests/testthat, so we
## switch to the project root just for sourcing.
old_wd <- getwd()
setwd(project_root)
source(file.path(project_root, "R", "00_setup.R"))
source(file.path(project_root, "R", "01_inventory_report.R"))
source(file.path(project_root, "R", "m01_ping_tcp_probe.R"))
source(file.path(project_root, "R", "04_multirun_analysis.R"))
setwd(old_wd)
