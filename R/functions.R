#' Create the parameter data frame
make_params <- function() {
  data.table::data.table(
    id    = 1:10,
    alpha = 1:10,
    ratio = 2:11
  )
}

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

#' Create a plot for a given parameter row
#' @param params_df The full parameters data.table
#' @param row_id Which row to use
#' @return A ggplot object
make_chart <- function(params_df, row_id) {
  row <- params_df[id == row_id]

  set.seed(row$alpha)
  n <- 50
  plot_data <- data.table::data.table(
    step = 1:n,
    x    = cumsum(rnorm(n, mean = 0, sd = row$ratio / 5)),
    y    = cumsum(rnorm(n, mean = 0, sd = row$alpha / 3))
  )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = step, y = y, color = x)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 1.5, alpha = 0.7) +
    ggplot2::scale_color_viridis_c() +
    ggplot2::labs(
      title = paste0("Random Walk (alpha=", row$alpha, ", ratio=", row$ratio, ")"),
      x = "Step",
      y = "Cumulative Value",
      color = "X drift"
    ) +
    ggplot2::theme_minimal()
}
