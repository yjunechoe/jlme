
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

## Usage (table of contents)

- [Fit models](#fit-models)
- [Diagnose models](#diagnose-models)
- [Embrace uncertainty](#embrace-uncertainty)
- [Julia interoperability](#julia-interoperability)
- [Tips](#tips)
- [Julia troubleshooting](#julia-troubleshooting)
- [Acknowledgments](#acknowledgments)

## Fit models

[↑Back to table of contents](#usage-table-of-contents)

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

## Diagnose models

[↑Back to table of contents](#usage-table-of-contents)

### Summarize model fit

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

### Inspect model objects

Check singular fit

``` r
issingular(jmod)
#> [1] FALSE
```

List all properties of a MixedModel object (properties are accessible
via `$`)

``` r
propertynames(jmod)
#>  [1] "A"         "b"         "beta"      "betas"     "corr"      "dims"     
#>  [7] "feterm"    "formula"   "L"         "lambda"    "lowerbd"   "objective"
#> [13] "optsum"    "parmap"    "PCA"       "pvalues"   "rePCA"     "reterms"  
#> [19] "sigma"     "sigmarhos" "sigmas"    "sqrtwts"   "stderror"  "theta"    
#> [25] "u"         "vcov"      "X"         "Xymat"     "y"         "β"        
#> [31] "βs"        "θ"         "λ"         "σ"         "σs"        "σρs"
```

## Embrace uncertainty

[↑Back to table of contents](#usage-table-of-contents)

### Parametric bootstrap

Experimental support for
[`MixedModels.parametricbootstrap`](https://juliastats.org/MixedModels.jl/stable/bootstrap/)
via `parametricbootstrap()`:

``` r
samp <- parametricbootstrap(jmod, nsim = 1000L, seed = 42L)
samp
#> <Julia object of type MixedModelBootstrap{Float64}>
#> MixedModelBootstrap with 1000 samples
#>      parameter  min        q25         median     mean       q75       max
#>    ┌───────────────────────────────────────────────────────────────────────────
#>  1 │ β1         227.464    246.884     251.608    251.655    256.229   275.687
#>  2 │ β2         4.99683    9.40303     10.4795    10.4522    11.5543   15.2264
#>  3 │ σ          21.0629    24.5779     25.5858    25.6024    26.5579   30.8176
#>  4 │ σ1         3.8862     19.8341     23.9517    23.8161    27.9909   40.7842
#>  5 │ σ2         1.65066    4.94152     5.77701    5.78757    6.61858   9.80011
#>  6 │ ρ1         -0.79257   -0.147053   0.0914976  0.111537   0.346284  1.0
#>  7 │ θ1         0.158198   0.762462    0.939845   0.935398   1.10182   1.72955
#>  8 │ θ2         -0.259593  -0.0358002  0.0185442  0.0197924  0.07347   0.333435
#>  9 │ θ3         0.0        0.175387    0.213763   0.207584   0.24721   0.402354
```

``` r
tidy(samp)
#>     effect    group                  term     estimate    conf.low  conf.high
#> 1    fixed     <NA>           (Intercept) 251.40510485 238.6573824 265.430084
#> 2    fixed     <NA>                  Days  10.46728596   7.3121974  13.523381
#> 5 ran_pars  Subject       sd__(Intercept)  24.74065797  12.8464132  35.011690
#> 4 ran_pars  Subject cor__(Intercept).Days   0.06555124  -0.4501055   1.000000
#> 6 ran_pars  Subject              sd__Days   5.92213766   3.3869360   8.310897
#> 3 ran_pars Residual       sd__Observation  25.59179572  22.6637109  28.465550
```

### Profiling

Experimental support for
[`MixedModels.profile`](https://juliastats.org/MixedModels.jl/stable/api/#MixedModels.profile-Tuple%7BLinearMixedModel%7D)
via `profilelikelihood()`:

``` r
prof <- profilelikelihood(jmod)
prof
#> <Julia object of type MixedModelProfile{Float64}>
#> MixedModelProfile -- Table with 11 columns and 161 rows:
#>       p  ζ          β1       β2       σ        σ1       σ2       ρ1           ⋯
#>     ┌──────────────────────────────────────────────────────────────────────────
#>  1  │ σ  -4.36538   251.405  10.4673  20.1929  26.4095  6.16993  -0.0238061   ⋯
#>  2  │ σ  -3.77934   251.405  10.4673  20.7999  26.2464  6.14557  -0.0156245   ⋯
#>  3  │ σ  -3.20553   251.405  10.4673  21.4252  26.0716  6.11928  -0.00675932  ⋯
#>  4  │ σ  -2.64359   251.405  10.4673  22.0692  25.8859  6.0915   0.00286329   ⋯
#>  5  │ σ  -2.09316   251.405  10.4673  22.7326  25.6871  6.06188  0.0132691    ⋯
#>  6  │ σ  -1.55392   251.405  10.4673  23.416   25.4744  6.03027  0.0246523    ⋯
#>  7  │ σ  -1.02552   251.405  10.4673  24.1199  25.2448  5.99673  0.0371101    ⋯
#>  8  │ σ  -0.507654  251.405  10.4673  24.8449  25.0016  5.9606   0.0505964    ⋯
#>  9  │ σ  0.0        251.405  10.4673  25.5918  24.7407  5.92214  0.0655512    ⋯
#>  10 │ σ  0.497702   251.405  10.4673  26.3611  24.4599  5.88109  0.0819128    ⋯
#>  11 │ σ  0.985782   251.405  10.4673  27.1535  24.1585  5.83716  0.0999603    ⋯
#>  12 │ σ  1.46451    251.405  10.4673  27.9698  23.8346  5.79033  0.119931     ⋯
#>  13 │ σ  1.93415    251.405  10.4673  28.8106  23.4862  5.74019  0.142062     ⋯
#>  14 │ σ  2.39497    251.405  10.4673  29.6766  23.111   5.68632  0.166822     ⋯
#>  15 │ σ  2.84722    251.405  10.4673  30.5687  22.7061  5.62889  0.194353     ⋯
#>  16 │ σ  3.29116    251.405  10.4673  31.4877  22.267   5.5671   0.225568     ⋯
#>  17 │ σ  3.72701    251.405  10.4673  32.4342  21.7928  5.50064  0.260712     ⋯
#>  ⋮  │ ⋮      ⋮         ⋮        ⋮        ⋮        ⋮        ⋮          ⋮       ⋱
```

``` r
tidy(prof)
#>      effect    group            term   estimate   conf.low  conf.high
#> 1     fixed     <NA>     (Intercept) 251.405105 239.501474 263.308736
#> 2     fixed     <NA>            Days  10.467286   7.771047  13.163525
#> 12 ran_pars  Subject sd__(Intercept)  24.740658  15.032045  39.512036
#> 21 ran_pars  Subject        sd__Days   5.922138   0.000000   9.151901
#> 11 ran_pars Residual sd__Observation  25.591796  22.898262  28.858000
```

## Julia interoperability

[↑Back to table of contents](#usage-table-of-contents)

### Bring Julia objects into R

Example 1: extract PCA of random effects and return as an R list:

``` r
jmod$rePCA
#> <Julia object of type @NamedTuple{Subject::Vector{Float64}}>
#> (Subject = [0.5327756193675971, 1.0],)
```

``` r
jl_get(jmod$rePCA)
#> $Subject
#> [1] 0.5327756 1.0000000
```

Example 2: extract fitlog and plot

``` r
fitlog <- jl_get(jl("refit!(x; thin=1)", x = jmod)$optsum$fitlog)
thetas <- t(sapply(fitlog, `[[`, 1))
head(thetas)
#>      [,1] [,2] [,3]
#> [1,] 1.00    0 1.00
#> [2,] 1.75    0 1.00
#> [3,] 1.00    1 1.00
#> [4,] 1.00    0 1.75
#> [5,] 0.25    0 1.00
#> [6,] 1.00   -1 1.00
```

``` r
matplot(thetas, type = "o", xlab = "iterations")
```

<img src="man/figures/README-unnamed-chunk-17-1.png" width="100%" />

### Julia session

See information about the running Julia environment (e.g., the list of
loaded Julia libraries) with `jlme_status()`:

``` r
jlme_status()
#> jlme 0.3.0 
#> R version 4.4.1 (2024-06-14 ucrt) 
#> Julia Version 1.10.5
#> Commit 6f3fdf7b36 (2024-08-27 14:19 UTC)
#> Build Info:
#>   Official https://julialang.org/ release
#> Platform Info:
#>   OS: Windows (x86_64-w64-mingw32)
#>   CPU: 8 × 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
#>   WORD_SIZE: 64
#>   LIBM: libopenlibm
#>   LLVM: libLLVM-15.0.7 (ORCJIT, tigerlake)
#> Threads: 1 default, 0 interactive, 1 GC (on 8 virtual cores)
#> Status `C:\Users\jchoe\AppData\Local\Temp\jl_AIvVeE\Project.toml`
#>   [38e38edf] GLM v1.9.0
#>   [98e50ef6] JuliaFormatter v1.0.60
#>   [ff71e718] MixedModels v4.26.0
#>   [3eaba693] StatsModels v0.7.4
#>   [9a3f8284] Random
```

## Tips

[↑Back to table of contents](#usage-table-of-contents)

### Data type conversion

Be sure to pass integers to functions that expect Integer type, (e.g.,
the `MixedModels.parametricbootstrap()` example above):

``` r
jl_put(1)
#> <Julia object of type Float64>
#> 1.0
```

``` r
jl_put(1L)
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

## Julia troubleshooting

[↑Back to table of contents](#usage-table-of-contents)

The package requires that [Julia (version ≥ 1.8) is
installed](https://julialang.org/downloads/) and that the Julia
executable is in the system search `PATH` or that the `JULIA_BINDIR`
environment variable is set to the `/bin` directory of the Julia
installation. The Julia version specified via the `JULIA_BINDIR`
variable will take precedence over the one on the system `PATH`.

After you have installed Julia, execute the command `julia` on the
command line. Ensure that this launches Julia.

On **Linux** and **Windows**, the `JuliaConnectoR` package should now be
able to use the Julia installation, as the Julia installation is on the
`PATH`. There should be no need to set the `JULIA_BINDIR` environment
variable. But if `JuliaConnectoR` still cannot find Julia, consult the
instructions below.

On **Mac**, Julia might not be on the `PATH` when using e.g. RStudio. In
this case, you may need to manually set the `JULIA_BINDIR` variable. To
get the proper value of the `JULIA_BINDIR` variable, execute
`Sys.BINDIR` from Julia. Then, set the environment variable in R via
`Sys.setenv("JULIA_BINDIR" = "/your/path/to/Julia/bin")` (or by editing
the `.Renviron` file). Afterwards, `JuliaConnectoR` should be able to
discover the specified Julia installation.

### Note about `juliaup`

If you manage Julia installations via
[Juliaup](https://github.com/JuliaLang/juliaup), the `JULIA_BINDIR`
variable must point to the actual installation directory of Julia. This
is different from the directory that is returned when executing
`which julia` on the command line (that will be a *link* to the default
Julia executable created by Juliaup). To get the path to a Julia
installation managed by Juliaup, run `juliaup api getconfig1` in
terminal and find the path to the Julia version you would like to use
with `JuliaConnectoR`. Then, follow the same process as above to set the
`JULIA_BINDIR` environment variable to the `/bin` directory of the Julia
executable.

## Acknowledgments

[↑Back to table of contents](#usage-table-of-contents)

- The [JuliaConnectoR](https://github.com/stefan-m-lenz/JuliaConnectoR)
  R package for powering the R interface to Julia.

- The [Julia](https://julialang.org/) packages
  [GLM.jl](https://github.com/JuliaStats/GLM.jl) and
  [MixedModels.jl](https://github.com/JuliaStats/MixedModels.jl) for
  fast implementations of (mixed effects) regression models.
