# _targets.R
library(targets)
library(tarchetypes)
library(data.table)

tar_option_set(
  packages = c("data.table", "ggplot2", "xts", "dygraphs")
)

tar_source()

list(

  tar_target( #tgt params
    name    = params_df,
    command = make_params()
  ),

  tar_target( ##tgt row_ids
    name    = row_ids,
    command = params_df$id
  ),

  tar_target( #tgt tables
    name      = tables,
    command   = make_table(params_df, row_ids),
    pattern   = map(row_ids),
    iteration = "list"
  ),

  tar_target( #tgt charts
    name      = charts,
    command   = make_chart(params_df, row_ids),
    pattern   = map(row_ids),
    iteration = "list"
  ),

  tar_target( ##tgt dygraphs
    name      = dygraphs,
    command   = make_dygraph(params_df, row_ids),
    pattern   = map(row_ids),
    iteration = "list"
  ),

  # tar_quarto() can't detect tar_read() calls in knit_child templates,
  # so we use tar_file() with explicit dependencies on upstream targets.
  tarchetypes::tar_file( #tgt report
    name    = report,
    command = {
      force(tables)
      force(charts)
      force(dygraphs)
      quarto::quarto_render("main_doc.qmd", output_format = "all")
      c("main_doc.pdf", "main_doc.html")
    }
  )

)
