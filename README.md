
<!-- README.md is generated from README.Rmd. Please edit that file -->

# jlme

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/jlme)](https://CRAN.R-project.org/package=jlme)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/yjunechoe/jlme/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yjunechoe/jlme/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/yjunechoe/jlme/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/yjunechoe/jlme/actions/workflows/test-coverage.yaml)
<!-- badges: end -->

Julia (mixed-effects) regression modelling from R

## Installation

You can install the development version of jlme from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("yjunechoe/jlme")
```

## Setup

``` r
library(jlme)
jlme_setup()
```

`{jlme}` uses `{JuliaConnectoR}` to connect to a Julia session. See
[JuliaConnectoR package
documentation](https://github.com/stefan-m-lenz/JuliaConnectoR) for
troubleshooting related to Julia installation and configuration.

## Using `{jlme}`

Once set up, `(g)lm()` and `(g)lmer` complements in Julia are available
via `jlm()` and `jlmer()`, respectively.

### Fixed effects models

`jlm()` with `lm()`/`glm()` syntax:

``` r
# lm(mpg ~ hp, mtcars)
jlm(mpg ~ hp, mtcars)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + hp
#> 
#> ────────────────────────────────────────────────────────────────────────────
#>                   Coef.  Std. Error      z  Pr(>|z|)   Lower 95%   Upper 95%
#> ────────────────────────────────────────────────────────────────────────────
#> (Intercept)  30.0989      1.63392    18.42    <1e-75  26.8964     33.3013
#> hp           -0.0682283   0.0101193  -6.74    <1e-10  -0.0880617  -0.0483948
#> ────────────────────────────────────────────────────────────────────────────
```

Contrasts in factor columns are preserved:

``` r
x <- mtcars

# Sum code `am`
x$am_sum <- factor(x$am)
contrasts(x$am_sum) <- contr.sum(2)
# Helmert code `cyl`
x$cyl_helm <- factor(x$cyl)
contrasts(x$cyl_helm) <- contr.helmert(3)
colnames(contrasts(x$cyl_helm)) <- c("4vs6", "4&6vs8")

jlm(mpg ~ am_sum + cyl_helm, x)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + am_sum + cyl_helm
#> 
#> ───────────────────────────────────────────────────────────────────────────────
#>                      Coef.  Std. Error      z  Pr(>|z|)  Lower 95%    Upper 95%
#> ───────────────────────────────────────────────────────────────────────────────
#> (Intercept)       20.6739     0.572633  36.10    <1e-99   19.5516   21.7963
#> am_sum: 1         -1.27998    0.648789  -1.97    0.0485   -2.55158  -0.00837293
#> cyl_helm: 4vs6    -3.07806    0.767861  -4.01    <1e-04   -4.58304  -1.57308
#> cyl_helm: 4&6vs8  -2.32983    0.414392  -5.62    <1e-07   -3.14203  -1.51764
#> ───────────────────────────────────────────────────────────────────────────────
```

### Mixed effects models

`jlmer()` with `lmer()`/`glmer()` syntax:

``` r
# lme4::lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
jlmer(Reaction ~ Days + (Days | Subject), lme4::sleepstudy, REML = TRUE)
#> <Julia object of type LinearMixedModel>
#> 
#> Reaction ~ 1 + Days + (1 + Days | Subject)
#> 
#> Variance components:
#>             Column    Variance Std.Dev.   Corr.
#> Subject  (Intercept)  612.10016 24.74066
#>          Days          35.07171  5.92214 +0.07
#> Residual              654.94001 25.59180
#> ──────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)
#> ──────────────────────────────────────────────────
#> (Intercept)  251.405      6.8246   36.84    <1e-99
#> Days          10.4673     1.54579   6.77    <1e-10
#> ──────────────────────────────────────────────────
```

``` r
# lme4::glmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
jlmer(r2 ~ Anger + Gender + (1 | id), lme4::VerbAgg, family = "binomial")
#> <Julia object of type GeneralizedLinearMixedModel>
#> 
#> r2 ~ 1 + Anger + Gender + (1 | id)
#> 
#> Variance components:
#>       Column   VarianceStd.Dev.
#> id (Intercept)  1.12074 1.05865
#> ────────────────────────────────────────────────────
#>                   Coef.  Std. Error      z  Pr(>|z|)
#> ────────────────────────────────────────────────────
#> (Intercept)  -1.10115     0.280681   -3.92    <1e-04
#> Anger         0.0462741   0.0134906   3.43    0.0006
#> Gender: M     0.260057    0.153847    1.69    0.0910
#> ────────────────────────────────────────────────────
```

### Inspect model objects

`{broom}`-style `tidy()` and `glance()` methods for Julia regression
models:

``` r
jmod <- jlmer(Reaction ~ Days + (Days | Subject), lme4::sleepstudy, REML = TRUE)
tidy(jmod)
#>      effect    group                  term     estimate std.error statistic
#> 1     fixed     <NA>           (Intercept) 251.40510485  6.824597 36.838090
#> 2     fixed     <NA>                  Days  10.46728596  1.545790  6.771481
#> 12 ran_pars  Subject       sd__(Intercept)  24.74065797        NA        NA
#> 3  ran_pars  Subject cor__(Intercept).Days   0.06555124        NA        NA
#> 21 ran_pars  Subject              sd__Days   5.92213766        NA        NA
#> 11 ran_pars Residual       sd__Observation  25.59179572        NA        NA
#>          p.value
#> 1  4.537101e-297
#> 2   1.274703e-11
#> 12            NA
#> 3             NA
#> 21            NA
#> 11            NA
```

``` r
glance(jmod)
#>   nobs df   sigma logLik AIC BIC deviance df.residual
#> 1  180  6 25.5918     NA  NA  NA 1743.628         174
```

### Parametric bootstrap

Experimental support for
[`MixedModels.parametricbootstrap`](https://juliastats.org/MixedModels.jl/stable/bootstrap/)
via `parametricbootstrap()`:

``` r
samp <- parametricbootstrap(jmod, nsim = 100L, seed = 42L)
samp
#> <Julia object of type MixedModelBootstrap{Float64}>
#> MixedModelBootstrap with 100 samples
#>      parameter  min        q25         median     mean        q75        ⋯
#>    ┌──────────────────────────────────────────────────────────────────────
#>  1 │ β1         227.464    246.465     250.903    250.985     256.233    ⋯
#>  2 │ β2         6.58801    9.89368     10.8208    10.6993     11.6945    ⋯
#>  3 │ σ          21.6863    24.654      25.6209    25.8437     26.7414    ⋯
#>  4 │ σ1         3.88389    19.505      24.0727    23.4107     27.6445    ⋯
#>  5 │ σ2         1.94609    4.90984     5.7615     5.87748     6.78987    ⋯
#>  6 │ ρ1         -0.731457  -0.244892   0.0860377  0.0721117   0.345471   ⋯
#>  7 │ θ1         0.158103   0.742165    0.916954   0.910481    1.10115    ⋯
#>  8 │ θ2         -0.192962  -0.0589699  0.0187681  0.00944012  0.0653042  ⋯
#>  9 │ θ3         0.0        0.170524    0.21086    0.205921    0.255305   ⋯
```

``` r
tidy(samp)
#>     effect    group                  term     estimate    conf.low   conf.high
#> 1    fixed     <NA>           (Intercept) 251.40510485 240.6380312 263.5578907
#> 2    fixed     <NA>                  Days  10.46728596   7.6356537  13.6199271
#> 5 ran_pars  Subject       sd__(Intercept)  24.74065797  14.0417274  34.0473785
#> 4 ran_pars  Subject cor__(Intercept).Days   0.06555124  -0.6985657   0.8871578
#> 6 ran_pars  Subject              sd__Days   5.92213766   3.6415708   8.2434993
#> 3 ran_pars Residual       sd__Observation  25.59179572  22.4973967  29.1232267
```

### Inspect model objects

``` r
# Check singular fit
issingular(jmod)
#> [1] FALSE
```

``` r

# List all properties of a MixedModel object
# - Properties are accessible via `$`
propertynames(jmod)
#>  [1] "A"         "b"         "beta"      "betas"     "corr"      "dims"     
#>  [7] "feterm"    "formula"   "L"         "lambda"    "lowerbd"   "objective"
#> [13] "optsum"    "parmap"    "PCA"       "pvalues"   "rePCA"     "reterms"  
#> [19] "sigma"     "sigmarhos" "sigmas"    "sqrtwts"   "stderror"  "theta"    
#> [25] "u"         "vcov"      "X"         "Xymat"     "y"         "β"        
#> [31] "βs"        "θ"         "λ"         "σ"         "σs"        "σρs"
```

### Misc.

See information about the running Julia environment (e.g., the list of
loaded Julia libraries) with `jlme_status()`:

``` r
jlme_status()
#> Julia Version 1.10.3
#> Commit 0b4590a550 (2024-04-30 10:59 UTC)
#> Build Info:
#>   Official https://julialang.org/ release
#> Platform Info:
#>   OS: Windows (x86_64-w64-mingw32)
#>   CPU: 8 × 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
#>   WORD_SIZE: 64
#>   LIBM: libopenlibm
#>   LLVM: libLLVM-15.0.7 (ORCJIT, tigerlake)
#> Threads: 1 default, 0 interactive, 1 GC (on 8 virtual cores)
#> 
#> Status `C:\Users\jchoe\AppData\Local\Temp\jl_XRahvB\Project.toml`
#>   [38e38edf] GLM v1.9.0
#>   [98e50ef6] JuliaFormatter v1.0.60
#>   [ff71e718] MixedModels v4.25.3
#>   [3eaba693] StatsModels v0.7.4
#>   [9a3f8284] Random
```

## Full interop control with `{JuliaConnectoR}`

``` r
library(JuliaConnectoR)
```

### Bring Julia objects into R

Extract PCA of random effects as an R list:

``` r
juliaGet(jmod$rePCA)
#> $Subject
#> [1] 0.5327756 1.0000000
#> 
#> attr(,"JLTYPE")
#> [1] "@NamedTuple{Subject::Vector{Float64}}"
```

### Access functions straight from MixedModels.jl

Use Julia(-esque) model-fitting syntax from R:

``` r
MixedModels <- juliaImport("MixedModels")

# Long-form construction of `jmod`
jmod2 <- MixedModels$fit(
  MixedModels$LinearMixedModel,
  juliaEval("@formula(Reaction ~ Days + (Days | Subject))"),
  juliaPut(lme4::sleepstudy)
)

# In complete Julia syntax, using the sleepstudy dataset from MixedModels.jl
jmod3 <- juliaEval("
  fit(
    LinearMixedModel,
    @formula(reaction ~ days + (days | subj)),
    MixedModels.dataset(:sleepstudy)
  )
")
```

## Tips

### Data type conversion

Be sure to pass integers to functions that expect Integer type, (e.g.,
the `MixedModels.parametricbootstrap()` example above):

``` r
# library(JuliaConnectoR)
juliaPut(1)
#> <Julia object of type Float64>
#> 1.0
```

``` r
juliaPut(1L)
#> <Julia object of type Int64>
#> 1
```

### Performance (linear algebra backend)

Using [`MKL.jl`](https://github.com/JuliaLinearAlgebra/MKL.jl) or
[`AppleAccelerate.jl`](https://github.com/JuliaLinearAlgebra/AppleAccelerate.jl)
may improve model fitting performance (but see the system requirements
first).

``` r
# Not run
jlme_setup(add = "MKL", restart = TRUE)
jlme_status() # Should see MKL loaded here
```

### Performance (data transfer)

In practice, most of the overhead will come from transferring the data
from R to Julia. If you are looking to fit many models to the same data,
you should first filter to keep only used columns and then use
`jl_data()` to send the data to Julia. The Julia data frame object can
then be used to fit Julia models.

``` r
data_r <- mtcars

# Keep only columns you need + convert with `jl_data()`
data_julia <- jl_data(data_r[, c("mpg", "am")])

jlm(mpg ~ am, data_julia)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + am
#> 
#> ────────────────────────────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)  Lower 95%  Upper 95%
#> ────────────────────────────────────────────────────────────────────────
#> (Intercept)  17.1474      1.1246   15.25    <1e-51   14.9432     19.3515
#> am            7.24494     1.76442   4.11    <1e-04    3.78674    10.7031
#> ────────────────────────────────────────────────────────────────────────
```

If your data has custom contrasts, you can use `jl_contrasts()` to also
convert that to Julia first before passing it to the model.

``` r
data_r$am <- as.factor(data_r$am)
contrasts(data_r$am) <- contr.sum(2)

data_julia <- jl_data(data_r[, c("mpg", "am")])
contrasts_julia <- jl_contrasts(data_r)

jlm(mpg ~ am, data_julia, contrasts = contrasts_julia)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + am
#> 
#> ────────────────────────────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)  Lower 95%  Upper 95%
#> ────────────────────────────────────────────────────────────────────────
#> (Intercept)  20.7698     0.882211  23.54    <1e-99   19.0407    22.4989
#> am: 1        -3.62247    0.882211  -4.11    <1e-04   -5.35157   -1.89337
#> ────────────────────────────────────────────────────────────────────────
```

### Just learn Julia

If you spend non-negligible time fitting regression models for your
work, please just [learn Julia](https://julialang.org/learning/)! It’s a
great high-level language that feels close to R in syntax and its
REPL-based workflow.

## Acknowledgments

- The [JuliaConnectoR](https://github.com/stefan-m-lenz/JuliaConnectoR)
  R package for powering the R interface to Julia.

- The [Julia](https://julialang.org/) packages
  [GLM.jl](https://github.com/JuliaStats/GLM.jl) and
  [MixedModels.jl](https://github.com/JuliaStats/MixedModels.jl) for
  fast implementations of (mixed effects) regression models.
