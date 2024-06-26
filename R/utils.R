`%||%` <- function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}



`%|NA|%` <- function(lhs, rhs) {
  if (is.na(lhs)) rhs else lhs
}



#' Temporarily attach a namespace
#'
#' This function is primarily for managing attaching of namespaces needed for
#' testing internally. It is exported only because it is needed in code
#' generated within `Rd` files, but is otherwise unlikely to be needed.
#'
#' @param ns A namespace or namespace name to attach
#' @param expr An expression to evaluate while the namespace is attached
#'
#' @return The result of evaluating `expr`
#'
#' @export
with_attached <- function(ns, expr) {
  nsname <- if (isNamespace(ns)) getNamespaceName(ns) else ns
  if (paste0("package:", nsname) %in% search()) {
    return(eval(expr))
  }

  if (is.character(ns)) {
    requireNamespace(ns)
  }

  try(silent = TRUE, {
    attached <- attachNamespace(ns)
    on.exit(detach(attr(attached, "name"), character.only = TRUE))
  })

  expr <- substitute(expr)
  eval(expr)
}



#' Test whether currently executing R checks
#'
#' @return A logical indicating whether `R CMD check` is currently running
#'
#' @keywords internal
is_r_cmd_check <- function() {
  !is.na(Sys.getenv("_R_CHECK_PACKAGE_NAME_", unset = NA_character_))
}



#' Package source file helpers
#'
#' Discover specific package related file paths
#'
#' @param path A path within a package source or install directory
#' @param quiet Whether to suppress output
#'
#' @return NULL, invisibly
#'
#' @name package-file-helpers
#' @keywords internal
#'
find_package_root <- function(path = ".", quiet = FALSE) {
  if (path == ".") path <- getwd()
  while (dirname(path) != path) {
    if (file.exists(file.path(path, "DESCRIPTION"))) {
      # package source directory
      return(path)
    } else if (endsWith(basename(path), ".Rcheck")) {
      # installed package, as during R CMD check
      file <- basename(path)
      package <- substring(file, 1, nchar(file) - nchar(".Rcheck"))
      return(file.path(path, package))
    }
    path <- dirname(path)
  }

  if (!quiet) stop("Unable to find package root")
  invisible(NULL)
}



#' Find and return a package's Rd db
#'
#' @param package A package name
#' @param path A file path within a package's source code or installation
#'   directory. Only considered if `package` is missing.
#'
#' @return A list of package Rd objects, as returned by [`tools::Rd_db()`]
#'
#' @name package-file-helpers
find_package_rds <- function(package, path = getwd()) {
  if (!missing(package)) {
    package_path <- find.package(package, quiet = TRUE)
  } else {
    package_path <- find_package_root(path)
  }

  desc <- file.path(package_path, "DESCRIPTION")
  package <- read.dcf(desc, fields = "Package")[[1L]]

  has_r_dir <- isTRUE(dir.exists(file.path(package_path, "R")))
  has_meta_dir <- isTRUE(dir.exists(file.path(package_path, "Meta")))

  if (has_r_dir && !has_meta_dir) {
    return(tools::Rd_db(dir = package_path))
  }

  if (has_meta_dir) {
    return(tools::Rd_db(package = package, lib.loc = dirname(package_path)))
  }

  tools::Rd_db(package)
}



#' @name package-file-helpers
package_desc <- function(path = getwd()) {
  x <- Sys.getenv("_R_CHECK_PACKAGE_NAME_", unset = NA_character_)
  if (!is.na(x)) {
    return(file.path(find.package(x), "DESCRIPTION"))
  }

  x <- find_package_root(path, quiet = TRUE)
  if (!is.null(x)) {
    return(file.path(x, "DESCRIPTION"))
  }

  invisible(NULL)
}



#' `vapply` shorthand alternatives
#'
#' Simple wrappers around `vapply` for common data types
#'
#' @param ... Arguments passed to [`vapply`]
#' @param FUN.VALUE A preset signature for the flavor of [`vapply`]. This is
#'   exposed for transparency, but modifying it would break the implicit
#'   contract in the function name about the return type.
#'
#' @return The result of [`vapply`]
#'
#' @rdname vapplys
#' @keywords internal
vlapply <- function(..., FUN.VALUE = logical(1L)) { # nolint
  vapply(..., FUN.VALUE = FUN.VALUE)
}

#' @rdname vapplys
vcapply <- function(..., FUN.VALUE = character(1L)) { # nolint
  vapply(..., FUN.VALUE = FUN.VALUE)
}

#' @rdname vapplys
vnapply <- function(..., FUN.VALUE = numeric(1L)) { # nolint
  vapply(..., FUN.VALUE = FUN.VALUE)
}



#' Deparse pretty
#'
#' Deparse to a single string with two spaces of indentation
#'
#' @param expr An expression to deparse
#'
#' @return A pretty-formatted string representation of `expr`.
#'
#' @keywords internal
deparse_pretty <- function(expr) {
  lines <- deparse(expr, width.cutoff = 120L)
  paste0(gsub("^(  +)\\1", "\\1", lines), collapse = "\n")
}



#' Deparse an expression and indent for pretty-printing
#'
#' @param x A `code` object
#' @param indent An `integer` number of spaces or a string to prefix each
#'   line of the deparsed output.
#'
#' @return An indented version of the deparsed string from `x`.
#'
#' @keywords internal
deparse_indent <- function(x, indent = 0L) {
  if (is.numeric(indent)) indent <- strrep(" ", indent)
  paste0(indent, deparse(unclass(x)), collapse = "\n")
}



#' Get String Line Count
#'
#' @param x A character value
#'
#' @return The number of newline characters in a multiline string
#'
#' @keywords internal
string_newline_count <- function(x) {
  nchar(gsub("[^\n]", "", x))
}



#' Return the number of characters in a line of a file
#'
#' @param file A file to use as reference
#' @param line A line number to retrieve the length of
#'
#' @return The number of characters in line `line`.
#'
#' @keywords internal
file_line_nchar <- function(file, line) {
  bn <- basename(file)
  if (!file.exists(file) || (startsWith(bn, "<") && endsWith(bn, ">"))) {
    return(10000)
  }
  nchar(scan(file, what = character(), skip = line - 1, n = 1, sep = "\n", quiet = TRUE))
}



#' Checks for use of `roxygen2`
#'
#' @param path A file path to a package source code directory
#' @return A logical value indicating whether a package takes `roxygen2` as
#'   a dependency.
#'
#' @export
uses_roxygen2 <- function(path) {
  x <- find_package_root(path, quiet = TRUE)
  desc <- file.path(x, "DESCRIPTION")
  deps <- read.dcf(desc, fields = c("Depends", "Imports", "Suggests"))
  deps <- trimws(unlist(strsplit(deps, ",")))
  isTRUE(any(grepl("^roxygen2( |$)", deps)))
}
