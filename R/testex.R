#' A syntactic helper for writing quick and easy example tests
#'
#' A wrapper around `stopifnot` that allows you to use `.` to refer to
#' `.Last.value` and preserve the last non-test output from an example.
#'
#' @section Documenting with `testex`:
#'
#' `testex` is a simple wrapper around execution that propagates the
#' `.Last.value` returned before running, allowing you to chain tests
#' more easily.
#'
#' ## Use in `Rd` files:
#'
#' \preformatted{
#' \examples{
#'   f <- function(a, b) a + b
#'   f(3, 4)
#'   \testonly{
#'     testex::testex(
#'       is.numeric(.),
#'       identical(., 7)
#'     )
#'   }
#' }
#' }
#'
#' But `Rd` files are generally regarded as being a bit cumbersome to author
#' directly. Instead, `testex` provide helpers that generate this style of
#' documentation, which use this function internally.
#'
#' ## Use with `roxygen2`
#'
#' Within a `roxygen2` `@examples` block you can instead use the `@test` tag
#' which will generate Rd code as shown above.
#'
#' \preformatted{
#' #' @examples
#' #' f <- function(a, b) a + b
#' #' f(3, 4)
#' #' @test is.numeric(.)
#' #' @test identical(., 7)
#' }
#'
#' @param ... Expressions to evaluated. `.` will be replaced with the
#'   expression passed to `val`, and may be used as a shorthand for the
#'   last example result.
#' @param value A value to test against. By default, this will use the example's
#'   `.Last.value`.
#' @param example_srcref An option `srcref_key` string used to indicate where
#'   the relevant example code originated from.
#' @param srcref An option `srcref_key` string used to indicate where the
#'   relevant test code originated from.
#' @param envir An environment in which tests should be evaluated. By default
#'   the parent environment where tests are evaluated.
#' @param style A syntactic style used by the test. Defaults to `"standalone"`,
#'   which expects `TRUE` and uses a `.`-notation. Accepts one of
#'   `"standalone"` or `"testthat"`. By default, styles will be implicitly
#'   converted to accommodate known testing frameworks, though this can be
#'   disabled by passing the style `"AsIs"` with [I()].
#'
#' @return Invisibly returns the `.Last.value` as it existed prior to evaluating
#'   the test.
#'
#' @export
testex <- function(
    ...,
    srcref = NULL,
    example_srcref = NULL,
    value = get_example_value(),
    envir = parent.frame(),
    style = "standalone") {
  opts <- testex_options()
  if (is_r_cmd_check() && isFALSE(opts$check)) {
    return(invisible(.Last.value))
  }

  if (!missing(value)) {
    value <- substitute(value)
  }

  is_testthat_running <- requireNamespace("testthat", quietly = TRUE) &&
    testthat::is_testing()

  exprs <- substitute(...())
  expr <- if (is_testthat_running && identical(style, "standalone")) {
    testex_standalone_as_testthat(exprs, srcref, value)
  } else if (identical(style, "testthat")) {
    testex_testthat(exprs, srcref, value)
  } else {
    testex_standalone(exprs, srcref, value)
  }

  eval(expr, envir = envir)
}

testex_standalone_as_testthat <- function(exprs, ...) {
  # wrap @test tests in expect_true when running with `testthat`
  exprs <- lapply(exprs, function(expr) bquote(testthat::expect_true(.(expr))))
  testex_testthat(exprs, ...)
}

testex_testthat <- function(exprs, srcref, value) {
  # bind srcref if provided
  if (!is.null(srcref)) {
    exprs <- lapply(exprs, function(expr) {
      bquote(testex::with_srcref(.(srcref), .(expr)))
    })
  }

  # build block, handling last output, example execution
  expr <- exprs_as_call(exprs)
  bquote(local(testex::with_attached("testthat", {
    . <- .(value)
    skip_if(inherits(., "error"), "previous example produced an error")
    .(expr)
    invisible(.)
  })))
}

testex_standalone <- function(exprs, srcref, value) {
  expr <- bquote({
    . <- .(value)
    .(as.call(append(list(as.name("stopifnot")), exprs)))
    invisible(.)
  })
}

exprs_as_call <- function(exprs) {
  if (length(exprs) > 1) {
    as.call(append(list(as.name("{")), exprs))
  } else {
    exprs[[1]]
  }
}
