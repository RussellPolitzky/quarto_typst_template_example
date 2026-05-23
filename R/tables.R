#' Create a summary table for a given parameter row
#' @param params_df The full parameters data.table
#' @param row_id Which row to use
#' @return A data.table summary table
make_table <- function(params_df, row_id) {
  row <- params_df[id == row_id]

  # Build a small summary table with derived values
  data.table::data.table(
    Parameter = c("Alpha", "Ratio", "Product", "Sum", "Difference"),
    Value     = c(row$alpha, row$ratio, row$alpha * row$ratio,
                  row$alpha + row$ratio, row$ratio - row$alpha)
  )
}
