# =============================================================================
# Expose the current R session as an MCP server for use with Kiro/btw.
#
# Usage:
#   source("~/expose_session_as_mcp.R")
#
#   This must be sourced after Kiro has been started and the r-btw MCP
#   server is active in the Kiro MCP panel.
#
# This will:
#   1. Install mcptools and btw if not already present.
#   2. Start (or restart) an MCP session.
#   3. Apply a monkey-patch to fix S7 serialization errors when
#      btw_tool_run_r returns plots (ContentImageInline).
#   4. Start a local HTTP server for plotly widget rendering.
#      Use show_plotly(p) to display a plotly plot as a static PNG
#      via the Playwright MCP server.
#
# Upstream issue: https://github.com/posit-dev/mcptools/issues/96
# =============================================================================

expose_mcp_session <- function() {

  ensure_dependencies <- function() {
    if (!requireNamespace("mcptools", quietly = TRUE)) {
      message("Installing mcptools...")
      install.packages("mcptools")
    }
    if (!requireNamespace("btw", quietly = TRUE)) {
      message("Installing btw...")
      install.packages("btw")
    }
    if (!requireNamespace("servr", quietly = TRUE)) {
      message("Installing servr...")
      install.packages("servr")
    }
    if (!requireNamespace("png", quietly = TRUE)) {
      message("Installing png...")
      install.packages("png")
    }
  }

  start_mcp_session <- function() {
    tryCatch(close(mcptools:::the$session_socket), error = function(e) NULL)
    mcptools::mcp_session()
  }

  fix_plot_serialization <- function() {
    patched_as_tool_call_result <- function(data, result) {
      is_error <- FALSE

      if (inherits(result, "ellmer::ContentToolResult")) {
        is_error <- !is.null(result@error)

        content_list <- lapply(result@value, function(item) {
          if (inherits(item, "ellmer::ContentImageInline")) {
            list(type = "image", mimeType = item@type, data = item@data)
          } else if (inherits(item, "ellmer::ContentText")) {
            list(type = "text", text = item@text)
          } else if (is.character(item)) {
            list(type = "text", text = paste(item, collapse = "\n"))
          } else {
            list(type = "text", text = format(item))
          }
        })

        mcptools:::jsonrpc_response(
          data$id,
          list(content = content_list, isError = is_error)
        )
      } else {
        mcptools:::jsonrpc_response(
          data$id,
          list(
            content = list(list(type = "text", text = paste(result, collapse = "\n"))),
            isError = is_error
          )
        )
      }
    }

    assignInNamespace(
      "as_tool_call_result",
      patched_as_tool_call_result,
      ns = "mcptools"
    )
  }

  start_plotly_server <- function() {
    plotly_dir <- file.path(tempdir(), "plotly_mcp")
    dir.create(plotly_dir, showWarnings = FALSE, recursive = TRUE)

    port <- httpuv::randomPort()
    servr::httd(dir = plotly_dir, port = port, browser = FALSE, daemon = TRUE)

    assign(".plotly_mcp_dir",  plotly_dir, envir = .GlobalEnv)
    assign(".plotly_mcp_port", port,       envir = .GlobalEnv)

    message("Plotly server running at http://127.0.0.1:", port)
  }

  ensure_dependencies()
  start_mcp_session()
  fix_plot_serialization()
  start_plotly_server()

  message("MCP session started with plot serialization fix and plotly server.")
  invisible(TRUE)
}


#' Display a plotly plot as a static PNG via the Playwright MCP server.
#'
#' Saves the plotly widget as HTML, serves it locally, and returns the URL
#' for Playwright to screenshot. Call this from btw_tool_run_r, then use
#' Playwright's browser_navigate + browser_take_screenshot tools.
#'
#' @param p A plotly object.
#' @param filename Optional filename (without path). Defaults to "plotly_widget.html".
#' @return The local URL to navigate to with Playwright.
show_plotly <- function(p, filename = "plotly_widget.html") {
  htmlwidgets::saveWidget(p, file.path(.plotly_mcp_dir, filename), selfcontained = TRUE)
  url <- paste0("http://127.0.0.1:", .plotly_mcp_port, "/", filename)
  message("Plotly saved. Navigate Playwright to: ", url)
  url
}


expose_mcp_session()
