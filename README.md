S3 dispatch on operators
========================

## The problem

Implementing a package with S3 dispatch for operators in R can be very challenging. Oftentimes, you'll get a confusing `non-numeric argument to binary operator` error, with an accompanying `Incompatible methods` warning. This warning happens because R tries to dispatch on both arguments when an operator is used.

For example:

```R
`+.X` <- function(e1, e2) {
  paste0("Called <", class(e1), "> + <", class(e2), ">")
}

`+.Y` <- function(e1, e2) {
  paste0("Called <", class(e1), "> + <", class(e2), ">")
}

# Define some objects with class attributes
X <- structure("X", class = "X")
Y <- structure("Y", class = "Y")


# When calling `+` without a competing method, it works fine:
X + 1
# [1] "Called <X> + <numeric>"

1 + X
# [1] "Called <numeric> + <X>"

X + structure(NA, class = "Z")
# [1] "Called <X> + <Z>"

# When calling `+` with a competing method:
X + Y
# Error in X + Y : non-numeric argument to binary operator
# In addition: Warning message:
# Incompatible methods ("+.X", "+.Y") for "+" 
```

## A solution

This problem goes away if both methods are the same, identical object. Even though the previous definitions of `+.X` and `+.Y` were the same, the variables didn't point to the exact same object in memory.

We can make them refer to the same object, and when that's done, the "Incompatible methods" problem goes away:

```R
`+.Y` <- `+.X`

X + Y
# [1] "Called <X> + <Y>"
```


## The problem returns in packages

Surprisingly, the solution above doesn't work if you do it in a package! In this package, **s3ops**, the functions `+.A` and `+.B` are defined the same way as `+.X` and `+.Y` are in the immediately preceding example, but using them to add objects of class `A` and `B` result in the error and "Incompatible methods" warning.


```R
devtools::install_github('wch/s3ops')
library(s3ops)

# Objects A and B already are defined:
str(A)
# Class 'A'  chr "A"
str(B)
# Class 'B'  chr "B"

A + A
# [1] "Called <A> + <A>"

B + B
# [1] "Called <B> + <B>"

A + B
# Error in A + B : non-numeric argument to binary operator
# In addition: Warning message:
# Incompatible methods ("+.A", "+.B") for "+" 
```

It looks like they're competing methods! Strange, because R says they're identical:

```R
plusA <- getS3method("+", "A")
plusB <- getS3method("+", "B")

identical(plusA, plusB)
# [1] TRUE

# Same result even when using identical's pickiest settings
identical(plusA, plusB, FALSE, FALSE, FALSE, FALSE)
# [1] TRUE
```

But if we dig even deeper, we see that they're not one and the same object. They have a different memory address:

```R
pryr::address(plusA)
# [1] "0x103b80148"
pryr::address(plusB)
# [1] "0x103919940"
```

It seems that in R's package building or loading process, these two methods, which should point to one and the same object (with the same memory address), somehow point to two separate objects, albeit with very similar properties.


## A solution for packages

It is possible to work around the problem. In the previous example, the variables `+.A` and `+.B` are defined in the package namespace, and they're declared as S3 methods in the `NAMESPACE` file. This is the standard way of doing it, but it is possible to do things a different way.

Instead of defining two variables, the package defines a single variable with our function, which doesn't need to be declared in `NAMESPACE`. 

```R
# (You shouldn't run this code; it's in the package.)
plus <- function (e1, e2) {
  paste0("Called <", class(e1), "> + <", class(e2), ">")
}
```

Instead of declaring the S3 methods in the `NAMESPACE` file, we'll register the S3 methods when the package is loaded, using `registerS3method()` :

```R
# (You shouldn't run this code; it's in the package.)
.onLoad <- function(...) {
  registerS3method("+", "C", plus)
  registerS3method("+", "D", plus)
}
```

We can see what this code does, by loading the package and testing it out on `C` and `D` objects.

```R
library(s3ops)

C + C
# [1] "Called <C> + <C>"

D + D
# [1] "Called <D> + <D>"

C + D
# [1] "Called <C> + <D>"
```

The last one worked, so there's not a competing method problem anymore.

We can see also that they occupy the same memory address, so they're truly identical:

```R
plusC <- getS3method("+", "C")
plusD <- getS3method("+", "D")

pryr::address(plusC)
# [1] "0x1061b1bb8"
pryr::address(plusD)
# [1] "0x1061b1bb8"
```



## Using Ops

The same problem can happen if you define group generics like `Ops.E` and `Ops.F` and declare them as S3 methods in `NAMESPACE`. In fact, this package does just that.

```R
library(s3ops)

E + E
# [1] "Called <E> + <E>"

F + F
# [1] "Called <F> + <F>"

E + F
# Error in E + F : non-numeric argument to binary operator
# In addition: Warning message:
# Incompatible methods ("Ops.E", "Ops.F") for "+" 
```


Fortunately, the solution is also the same. This package defines `Ops` methods for `G` and `H` by using the same `registerS3method()` trick that we used above for `C` and `D`, and it fixes the problem:

```R
G + G
# [1] "Called <G> + <G>"

H + H
# [1] "Called <H> + <H>"

G + H
# [1] "Called <G> + <H>"
```
