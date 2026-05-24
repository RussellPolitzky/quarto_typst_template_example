#' Create a plot for a given parameter row
#' @param params_df The full parameters data.table
#' @param row_id Which row to use
#' @return A ggplot object
make_chart <- function(params_df, row_id) {
  id <- x <- y <- NULL
  row <- params_df[id == row_id]

  set.seed(row$alpha)
  n <- 50
  plot_data <- data.table::data.table(
    step = 1:n,
    x    = cumsum(rnorm(n, mean = 0, sd = row$ratio / 5)),
    y    = cumsum(rnorm(n, mean = 0, sd = row$alpha / 3))
  )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = step, y = y)) +
    ggplot2::geom_line(
      ggplot2::aes(group = 1),
      linewidth = 0.8, color = "grey40"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(color = x),
      size = 1.5, alpha = 0.7
    ) +
    ggplot2::scale_color_viridis_c() +
    ggplot2::labs(
      title = paste0(
        "Random Walk (alpha=", row$alpha,
        ", ratio=", row$ratio, ")"
      ),
      x = "Step",
      y = "Cumulative Value",
      color = "X drift"
    ) +
    ggplot2::theme_minimal()
}

#' Create an interactive dygraph for a given parameter row
#' @param params_df The full parameters data.table
#' @param row_id Which row to use
#' @return A dygraph htmlwidget
make_dygraph <- function(params_df, row_id) {
  id <- NULL
  row <- params_df[id == row_id]

  set.seed(row$alpha)
  n <- 50
  # Use a date sequence so dygraphs has a proper time axis
  dates <- seq(as.Date("2024-01-01"), by = "day", length.out = n)
  ts_data <- xts::xts(
    data.frame(
      Y = cumsum(rnorm(n, mean = 0, sd = row$alpha / 3)),
      X = cumsum(rnorm(n, mean = 0, sd = row$ratio / 5))
    ),
    order.by = dates
  )

  dygraphs::dygraph(
    ts_data,
    main = paste0("Random Walk (alpha=", row$alpha, ", ratio=", row$ratio, ")")
  ) |>
    dygraphs::dyRangeSelector() |>
    dygraphs::dyOptions(colors = c("#2c7fb8", "#7fcdbb"))
}
