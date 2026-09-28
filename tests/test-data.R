# Regression checks on the generated data for the Length of Growing Season indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 6 dataset(s)", length(meta$datasets) == 6L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")

snapshot <- function(file, n_rows, first, last, min_value, max_value) {
  df <- rd(file)
  check(sprintf("%s: row count is %d", file, n_rows), nrow(df) == n_rows)
  check(sprintf("%s: first row matches", file),
        identical(as.character(unlist(df[1, ], use.names = FALSE)), first))
  check(sprintf("%s: last row matches", file),
        identical(as.character(unlist(df[nrow(df), ], use.names = FALSE)), last))
  v <- suppressWarnings(as.numeric(df$value))
  check(sprintf("%s: min value matches", file),
        identical(df$value[which.min(v)], min_value))
  check(sprintf("%s: max value matches", file),
        identical(df$value[which.max(v)], max_value))
}

snapshot(
  "length_of_growing_season_national.csv", 129,
  first = c("1895", "-3.355"), last = c("2023", "8.863333333"),
  min_value = "-8.644545455", max_value = "11.73878788"
)

snapshot(
  "length_of_growing_season_east_west.csv", 258,
  first = c("1895", "east", "-1.381666667"), last = c("2023", "west", "14.85"),
  min_value = "-14.33272727", max_value = "17.46545455"
)

snapshot(
  "length_of_growing_season_by_state.csv", 47,
  first = c("Alabama", "0"), last = c("Wyoming", "32.25"),
  min_value = "-11.34330337", max_value = "47.20083363"
)

snapshot(
  "length_of_growing_season_frost_timing.csv", 258,
  first = c("1895", "last_spring_frost", "-0.153333333"),
  last = c("2023", "first_fall_frost", "6.118333333"),
  min_value = "-5.750909091", max_value = "7.377878788"
)

snapshot(
  "last_spring_frost_by_state.csv", 47,
  first = c("Alabama", "-0.674873684"), last = c("Wyoming", "-17.36538462"),
  min_value = "-28.22107143", max_value = "7.695894657"
)

snapshot(
  "first_fall_frost_by_state.csv", 47,
  first = c("Alabama", "-0.169103197"), last = c("Wyoming", "14.95652174"),
  min_value = "-2.775661376", max_value = "17.08513287"
)

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
