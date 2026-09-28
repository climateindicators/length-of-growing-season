# Build tidy long-format data for the Length of Growing Season indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Length of Growing Season",
  slug                    = "length-of-growing-season",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-length-growing-season/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/growing-season_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Length of Growing Season in the Contiguous 48 States, 1895-2023 ----

f1_path <- file.path(raw_dir, "growing-season_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = character(),
  expected_headers = c("Year", "Deviation from average length of growing season"),
  what             = "growing-season_fig-1.csv"
)

f1 <- f1_raw |>
  dplyr::transmute(
    year  = Year,
    value = `Deviation from average length of growing season`
  )

write_csv_stable(f1, file.path(out_dir, "length_of_growing_season_national.csv"))

# ---- Figure 2: Length of Growing Season in the Contiguous 48 States, 1895-2023: West Versus East ----

f2_path <- file.path(raw_dir, "growing-season_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f2_raw,
  id_cols          = character(),
  expected_headers = c("Year", "Eastern United States deviation from average length of growing season", "Western United States deviation from average length of growing season"),
  what             = "growing-season_fig-2.csv"
)

f2 <- f2_raw |>
  dplyr::rename(year = Year) |>
  tidyr::pivot_longer(cols = -year, names_to = "region", values_to = "value") |>
  dplyr::mutate(
    region = dplyr::case_when(
      region == "Eastern United States deviation from average length of growing season" ~ "east",
      region == "Western United States deviation from average length of growing season" ~ "west"
    )
  )
assert_conservation(f2_raw, c(
  "Eastern United States deviation from average length of growing season",
  "Western United States deviation from average length of growing season"
), nrow(f2), "growing-season_fig-2.csv")

write_csv_stable(f2, file.path(out_dir, "length_of_growing_season_east_west.csv"))

# ---- Figure 3: Change in Length of Growing Season by State, 1895-2023 ----

f3_path <- file.path(raw_dir, "growing-season_fig-3.csv")
f3_meta <- read_epa_preamble(f3_path)
f3_raw  <- read_epa_csv(f3_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f3_raw,
  id_cols          = character(),
  expected_headers = c("State", "Change in length of growing season"),
  what             = "growing-season_fig-3.csv"
)

f3 <- f3_raw |>
  dplyr::transmute(
    state = State,
    value = `Change in length of growing season`
  )

write_csv_stable(f3, file.path(out_dir, "length_of_growing_season_by_state.csv"))

# ---- Figure 4: Timing of the Last Spring Frost and First Fall Frost in the Contiguous 48 States, 1895-2023 ----

f4_path <- file.path(raw_dir, "growing-season_fig-4.csv")
f4_meta <- read_epa_preamble(f4_path)
f4_raw  <- read_epa_csv(f4_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f4_raw,
  id_cols          = character(),
  expected_headers = c("Year", "Deviation from average date of last spring frost", "Deviation from average date of first fall frost"),
  what             = "growing-season_fig-4.csv"
)

f4 <- f4_raw |>
  dplyr::rename(year = Year) |>
  tidyr::pivot_longer(cols = -year, names_to = "event", values_to = "value") |>
  dplyr::mutate(
    event = dplyr::case_when(
      event == "Deviation from average date of last spring frost" ~ "last_spring_frost",
      event == "Deviation from average date of first fall frost" ~ "first_fall_frost"
    )
  )
assert_conservation(f4_raw, c(
  "Deviation from average date of last spring frost",
  "Deviation from average date of first fall frost"
), nrow(f4), "growing-season_fig-4.csv")

write_csv_stable(f4, file.path(out_dir, "length_of_growing_season_frost_timing.csv"))

# ---- Figure 5: Change in Timing of Last Spring Frost by State, 1895-2023 ----

f5_path <- file.path(raw_dir, "growing-season_fig-5.csv")
f5_meta <- read_epa_preamble(f5_path)
f5_raw  <- read_epa_csv(f5_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f5_raw,
  id_cols          = character(),
  expected_headers = c("State", "Change in timing of last spring frost date"),
  what             = "growing-season_fig-5.csv"
)

f5 <- f5_raw |>
  dplyr::transmute(
    state = State,
    value = `Change in timing of last spring frost date`
  )

write_csv_stable(f5, file.path(out_dir, "last_spring_frost_by_state.csv"))

# ---- Figure 6: Change in Timing of First Fall Frost by State, 1895-2023 ----

f6_path <- file.path(raw_dir, "growing-season_fig-6.csv")
f6_meta <- read_epa_preamble(f6_path)
f6_raw  <- read_epa_csv(f6_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f6_raw,
  id_cols          = character(),
  expected_headers = c("State", "Change in timing of first fall frost"),
  what             = "growing-season_fig-6.csv"
)

f6 <- f6_raw |>
  dplyr::transmute(
    state = State,
    value = `Change in timing of first fall frost`
  )

write_csv_stable(f6, file.path(out_dir, "first_fall_frost_by_state.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "length_of_growing_season_national.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "growing-season_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = list(
        col("year", "integer", "Calendar year, 1895-2023."),
        col("value", "number", "Deviation of national growing season length from the 1895-2023 average, in days.")
      )
    ),
    list(
      file            = "length_of_growing_season_east_west.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "growing-season_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "UTF-8",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2),
      columns         = list(
        col("year", "integer", "Calendar year, 1895-2023."),
        col("region", "character", "'east' or 'west', the two US regions compared in this figure."),
        col("value", "number", "Deviation of regional growing season length from the 1895-2023 average, in days.")
      )
    ),
    list(
      file            = "length_of_growing_season_by_state.csv",
      figure          = "Figure 3",
      figure_title    = f3_meta$title,
      source_file     = "growing-season_fig-3.csv",
      source_sha256   = file_sha256(f3_path),
      source_encoding = "UTF-8",
      data_source     = f3_meta$data_source,
      web_update      = f3_meta$web_update,
      unit            = f3_meta$units,
      rows            = nrow(f3),
      columns         = list(
        col("state", "character", "US state name (contiguous 48 states)."),
        col("value", "number", "Total change in growing season length from 1895 to 2023, in days.")
      )
    ),
    list(
      file            = "length_of_growing_season_frost_timing.csv",
      figure          = "Figure 4",
      figure_title    = f4_meta$title,
      source_file     = "growing-season_fig-4.csv",
      source_sha256   = file_sha256(f4_path),
      source_encoding = "UTF-8",
      data_source     = f4_meta$data_source,
      web_update      = f4_meta$web_update,
      unit            = f4_meta$units,
      rows            = nrow(f4),
      columns         = list(
        col("year", "integer", "Calendar year, 1895-2023."),
        col("event", "character", "'last_spring_frost' or 'first_fall_frost', the two frost timing series shown in this figure."),
        col("value", "number", "Deviation of national frost date from the 1895-2023 average, in days; positive values indicate a later frost date.")
      )
    ),
    list(
      file            = "last_spring_frost_by_state.csv",
      figure          = "Figure 5",
      figure_title    = f5_meta$title,
      source_file     = "growing-season_fig-5.csv",
      source_sha256   = file_sha256(f5_path),
      source_encoding = "UTF-8",
      data_source     = f5_meta$data_source,
      web_update      = f5_meta$web_update,
      unit            = f5_meta$units,
      rows            = nrow(f5),
      columns         = list(
        col("state", "character", "US state name (contiguous 48 states)."),
        col("value", "number", "Total change in last spring frost date from 1895 to 2023, in days; negative values indicate an earlier frost date.")
      )
    ),
    list(
      file            = "first_fall_frost_by_state.csv",
      figure          = "Figure 6",
      figure_title    = f6_meta$title,
      source_file     = "growing-season_fig-6.csv",
      source_sha256   = file_sha256(f6_path),
      source_encoding = "UTF-8",
      data_source     = f6_meta$data_source,
      web_update      = f6_meta$web_update,
      unit            = f6_meta$units,
      rows            = nrow(f6),
      columns         = list(
        col("state", "character", "US state name (contiguous 48 states)."),
        col("value", "number", "Total change in first fall frost date from 1895 to 2023, in days; positive values indicate a later frost date.")
      )
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
