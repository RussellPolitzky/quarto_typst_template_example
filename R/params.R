#' Create the parameter data frame
make_params <- function() {
  data.table::data.table(
    id    = 1:10,
    alpha = 1:10,
    ratio = 2:11
  )
}
