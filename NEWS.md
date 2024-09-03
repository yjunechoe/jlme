# jlme (development version)

* Bugfix passing `ftol_rel` to Julia in `parametricbootstrap()`

# jlme 0.2.0

* Experimental support for `MixedModels.parametricbootstrap()` via `parametricbootstrap()` with a `tidy()` method.

* `jlme_setup()` gains an `add` argument which accepts a character vector of additional Julia libraries to install and load on initializing the session.

* Some common workflows in MixedModels.jl have been re-exported as functions: `propertynames()`, `issingular()`

# jlme 0.1.0

* CRAN release
