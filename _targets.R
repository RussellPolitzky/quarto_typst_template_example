# _targets.R
library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("data.table", "ggplot2")
)

tar_source()

list(
  # Step 1: Create the parameter grid
  tar_target(params_df, make_params()),

  # Step 2: Vector of row IDs for branching
  tar_target(row_ids, params_df$id),

  # Step 3: Dynamic branching — one table per parameter row
  tar_target(
    tables,
    make_table(params_df, row_ids),
    pattern = map(row_ids),
    iteration = "list"
  ),

  # Step 4: Dynamic branching — one chart per parameter row
  tar_target(
    charts,
    make_chart(params_df, row_ids),
    pattern = map(row_ids),
    iteration = "list"
  ),

  # Step 5: Render the main document
  # tar_quarto() can't detect tar_read() calls in knit_child templates,

  # so we use tar_file() with explicit dependencies on tables and charts.
  tarchetypes::tar_file(
    report,
    {
      force(tables)
      force(charts)
      quarto::quarto_render("main_doc.qmd")
      "main_doc.pdf"
    }
  )
)
