# -----------------------------------------------------------------------------
# Declaring S3 method the standard way, for + operator, classes A and B
# -----------------------------------------------------------------------------
#' @export
`+.A` <- function (e1, e2) {
  paste0("Called <", class(e1), "> + <", class(e2), ">")
}

#' @export
`+.B` <- `+.A`


# -----------------------------------------------------------------------------
# Using registerS3method, for - operator, classes C and D
# -----------------------------------------------------------------------------
# The +.C and +.D methods aren't declared as an S3method in NAMESPACE, but they
# are registered as S3 methods when the package is loaded, with .onLoad below.

plus <- function (e1, e2) {
  paste0("Called <", class(e1), "> + <", class(e2), ">")
}


# -----------------------------------------------------------------------------
# Using Ops for all operators, classes E and F
# -----------------------------------------------------------------------------
#' @export
Ops.E <- function(e1, e2, ...) {
  paste0("Called <", class(e1), "> ", .Generic, " <", class(e2), ">")
}

#' @export
Ops.F <- Ops.E


# -----------------------------------------------------------------------------
# Using Ops with registerS3method for all operators, classes G and H
# -----------------------------------------------------------------------------
#' @export
operators <- function(e1, e2, ...){
  paste0("Called <", class(e1), "> ", .Generic, " <", class(e2), ">")
}



# -----------------------------------------------------------------------------
# Register S3 methods via function call instead of NAMESPACE file
# -----------------------------------------------------------------------------
.onLoad <- function(...) {
  registerS3method("+", "C", plus)
  registerS3method("+", "D", plus)
  registerS3method("Ops", "G", operators)
  registerS3method("Ops", "H", operators)
}
