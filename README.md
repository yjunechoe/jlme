
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

Julia (mixed-effects) regression modelling from R. Powered by the
[`{JuliaConnectoR}`](https://github.com/stefan-m-lenz/JuliaConnectoR) R
package and Julia libraries [GLM](https://github.com/JuliaStats/GLM.jl),
[StatsModels](https://github.com/JuliaStats/StatsModels.jl), and
[MixedModels](https://github.com/JuliaStats/MixedModels.jl).

## Installation

You can install the development version of `{jlme}` from
[GitHub](https://github.com/yjunechoe/jlme) with:

``` r
# install.packages("remotes")
remotes::install_github("yjunechoe/jlme")
```

`{jlme}` is experimental: see
[NEWS.md](https://github.com/yjunechoe/jlme/blob/main/NEWS.md#jlme-development-version)
for active updates.

## Setup

``` r
library(jlme)
jlme_setup()
```

`{jlme}` uses `{JuliaConnectoR}` to connect to a Julia session. Jump
down to the [Julia troubleshooting](#julia-troubleshooting) section for
issues related to Julia installation and configuration.

## Usage (table of contents)

- [Fit models](#fit-models)
- [Diagnose models](#diagnose-models)
- [Assess uncertainty](#assess-uncertainty)
- [Julia interoperability](#julia-interoperability)
- [Tips and tricks](#tips-and-tricks)
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

Supports `{broom}`-style `tidy()` and `glance()` methods for Julia
regression models.

### Summarize model fit

Get information about model components with `tidy()`

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

Get goodness-of-fit measures of a model with `glance()`

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

Check optimization summary

``` r
jmod$optsum
#> <Julia object of type OptSummary{Float64}>
#> Initial parameter vector: [1.0, 0.0, 1.0]
#> Initial objective value:  1773.6803306160236
#> 
#> Optimizer (from NLopt):   LN_BOBYQA
#> Lower bounds:             [0.0, -Inf, 0.0]
#> ftol_rel:                 1.0e-12
#> ftol_abs:                 1.0e-8
#> xtol_rel:                 0.0
#> xtol_abs:                 [1.0e-10, 1.0e-10, 1.0e-10]
#> initial_step:             [0.75, 1.0, 0.75]
#> maxfeval:                 -1
#> maxtime:                  -1.0
#> 
#> Function evaluations:     43
#> Final parameter vector:   [0.9667417730750263, 0.015169059007472414, 0.23090995314561083]
#> Final objective value:    1743.6282719599653
#> Return code:              FTOL_REACHED
```

## Assess uncertainty

[↑Back to table of contents](#usage-table-of-contents)

Functions `parametricbootstrap()` and `profilelikelihood()` can be used
to assess the variability of parameter estimates.

### Parametric bootstrap

Experimental support for
[`MixedModels.parametricbootstrap`](https://juliastats.org/MixedModels.jl/stable/bootstrap/)
via `parametricbootstrap()`:

``` r
samp <- parametricbootstrap(jmod, nsim = 100L, seed = 42L)
samp
#> <Julia object of type MixedModelBootstrap{Float64}>
#> MixedModelBootstrap with 100 samples
#>      parameter  min        q25         median     mean        q75       max
#>    ┌────────────────────────────────────────────────────────────────────────────
#>  1 │ β1         227.464    246.465     250.903    250.985     256.233   264.878
#>  2 │ β2         6.58801    9.89368     10.8208    10.6993     11.6945   13.8613
#>  3 │ σ          21.6868    24.6505     25.6221    25.8474     26.7382   30.599
#>  4 │ σ1         3.8862     19.5019     24.0707    23.3628     27.4161   34.0508
#>  5 │ σ2         1.95071    4.90943     5.76106    5.87793     6.79344   8.91558
#>  6 │ ρ1         -0.731594  -0.237908   0.0869573  0.0721882   0.345545  1.0
#>  7 │ θ1         0.158198   0.742099    0.909455   0.90867     1.10008   1.37666
#>  8 │ θ2         -0.193011  -0.0589132  0.0187871  0.00940508  0.065209  0.213878
#>  9 │ θ3         0.0        0.170507    0.211006   0.206231    0.255929  0.357972
```

``` r
tidy(samp)
#>     effect    group                  term     estimate   conf.low   conf.high
#> 1    fixed     <NA>           (Intercept) 251.40510485 240.638031 263.5578907
#> 2    fixed     <NA>                  Days  10.46728596   7.635654  13.6199271
#> 5 ran_pars  Subject       sd__(Intercept)  24.74065797  14.054638  34.0507880
#> 4 ran_pars  Subject cor__(Intercept).Days   0.06555124  -0.697758   0.8805016
#> 6 ran_pars  Subject              sd__Days   5.92213766   3.643931   8.2409621
#> 3 ran_pars Residual       sd__Observation  25.59179572  22.497355  29.2889311
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

Functions `jl_get()` and `jl_put()` transfers data between R and Julia.

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

<img src="man/figures/README-unnamed-chunk-18-1.png" width="100%" />

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
#> Status `C:\Users\jchoe\AppData\Local\Temp\jl_7U2Img\Project.toml`
#>   [38e38edf] GLM v1.9.0
#>   [ff71e718] MixedModels v4.26.0
#>   [3eaba693] StatsModels v0.7.4
#>   [9a3f8284] Random
```

On setup, `{jlme}` loads [GLM](https://github.com/JuliaStats/GLM.jl),
[StatsModels](https://github.com/JuliaStats/StatsModels.jl), and
[MixedModels](https://github.com/JuliaStats/MixedModels.jl), as well as
those specified in `jlme_setup(add)`. Other libraries such as `Random`
(required for `parametricbootstrap()`) are loaded on an as-needed basis.

### More with `{JuliaConnectoR}`

While `{jlme}` users will typically not need to interact with
`{JuliaConnectoR}` directly, it may be useful for extending `{jlme}`
features with other packages in the Julia modelling ecosystem. A simple
way to do that is to use `juliaImport()`, which creates makeshift
bindings to Julia libraries.

For example, to replicate a workflow using
[`Effects.empairs`](https://beacon-biosignals.github.io/Effects.jl/dev/emmeans/)
for post-hoc pairwise comparisons:

``` r
# New model: 2 (M/F) by 3 (curse/scold/shout) factorial
jmod2 <- jlmer(
  r2 ~ Gender * btype + (1 | id),
  data = lme4::VerbAgg,
  family = "binomial"
)
jmod2
#> <Julia object of type GeneralizedLinearMixedModel>
#> 
#> r2 ~ 1 + Gender + btype + Gender & btype + (1 | id)
#> 
#> Variance components:
#>       Column   VarianceStd.Dev.
#> id (Intercept)  1.52160 1.23353
#> ─────────────────────────────────────────────────────────────────
#>                               Coef.  Std. Error       z  Pr(>|z|)
#> ─────────────────────────────────────────────────────────────────
#> (Intercept)                0.738396   0.0956957    7.72    <1e-13
#> Gender: M                  0.404282   0.201612     2.01    0.0449
#> btype: scold              -1.01214    0.0742669  -13.63    <1e-41
#> btype: shout              -1.77376    0.0782721  -22.66    <1e-99
#> Gender: M & btype: scold   0.130832   0.156315     0.84    0.4026
#> Gender: M & btype: shout  -0.533658   0.168832    -3.16    0.0016
#> ─────────────────────────────────────────────────────────────────
```

``` r
library(JuliaConnectoR)
# First call downloads the library (takes a minute)
Effects <- juliaImport("Effects")
# Call `Effects.empairs` using R syntax `Effects$empairs()`
pairwise <- Effects$empairs(jmod2, dof = glance(jmod2)$df.residual)
pairwise
#> <Julia object of type DataFrames.DataFrame>
#> 15×7 DataFrame
#>  Row │ Gender  btype          r2: Y      err       dof    t          Pr(>|t|)  ⋯
#>      │ String  String         Float64    Float64   Int64  Float64    Float64   ⋯
#> ─────┼──────────────────────────────────────────────────────────────────────────
#>    1 │ F > M   curse          -0.404282  0.201612   7577  -2.00524   0.0449725 ⋯
#>    2 │ F       curse > scold   1.01214   0.13461    7577   7.51901   6.15243e-
#>    3 │ F > M   curse > scold   0.477022  0.196994   7577   2.4215    0.0154799
#>    4 │ F       curse > shout   1.77376   0.136284   7577  13.0152    2.57693e-
#>    5 │ F > M   curse > shout   1.90314   0.202352   7577   9.4051    6.75459e- ⋯
#>    6 │ M > F   curse > scold   1.41642   0.201127   7577   7.0424    2.05522e-
#>    7 │ M       curse > scold   0.881304  0.247263   7577   3.56424   0.0003671
#>    8 │ M > F   curse > shout   2.17805   0.202251   7577  10.769     7.53779e-
#>    9 │ M       curse > shout   2.30742   0.251552   7577   9.17273   5.84715e- ⋯
#>   10 │ F > M   scold          -0.535114  0.196498   7577  -2.72326   0.0064789
#>   11 │ F       scold > shout   0.761627  0.135565   7577   5.61817   1.99834e-
#>   12 │ F > M   scold > shout   0.891002  0.201868   7577   4.41378   1.02988e-
#>   13 │ M > F   scold > shout   1.29674   0.197648   7577   6.56086   5.70179e- ⋯
#>   14 │ M       scold > shout   1.42612   0.247866   7577   5.75357   9.07797e-
#>   15 │ F > M   shout           0.129376  0.202988   7577   0.637355  0.523913
#>                                                                 1 column omitted
```

Note that Julia `DataFrame` objects such as the one above can be
collected into an R data frame using `as.data.frame()`. This lets you,
for example, apply p-value corrections using the familiar `p.adjust()`
function in R, though the [option to do
that](https://beacon-biosignals.github.io/Effects.jl/dev/emmeans/#Multiple-Comparisons-Correction)
exists in Julia as well.

``` r
pairwise_df <- as.data.frame(pairwise)
cbind(
  pairwise_df[, 1:2],
  round(pairwise_df[, 3:4], 2),
  pvalue = format.pval(p.adjust(pairwise_df[, 7], "bonferroni"), 1)
)
#>    Gender         btype r2..Y  err pvalue
#> 1   F > M         curse -0.40 0.20  0.675
#> 2       F curse > scold  1.01 0.13  9e-13
#> 3   F > M curse > scold  0.48 0.20  0.232
#> 4       F curse > shout  1.77 0.14 <2e-16
#> 5   F > M curse > shout  1.90 0.20 <2e-16
#> 6   M > F curse > scold  1.42 0.20  3e-11
#> 7       M curse > scold  0.88 0.25  0.006
#> 8   M > F curse > shout  2.18 0.20 <2e-16
#> 9       M curse > shout  2.31 0.25 <2e-16
#> 10  F > M         scold -0.54 0.20  0.097
#> 11      F scold > shout  0.76 0.14  3e-07
#> 12  F > M scold > shout  0.89 0.20  2e-04
#> 13  M > F scold > shout  1.30 0.20  9e-10
#> 14      M scold > shout  1.43 0.25  1e-07
#> 15  F > M         shout  0.13 0.20  1.000
```

## Tips and tricks

[↑Back to table of contents](#usage-table-of-contents)

### Displaying MixedModels

MixedModels.jl supports various [display
formats](https://juliastats.org/MixedModels.jl/stable/mime) for
mixed-effects models which are available in `{jlme}` via the `format`
argument of `print()`:

``` r
# Rendered via {knitr} with chunk option `results="asis"`
print(jmod, format = "markdown")
```

|             |     Est. |     SE |     z |       p | σ_Subject |
|:------------|---------:|-------:|------:|--------:|----------:|
| (Intercept) | 251.4051 | 6.8246 | 36.84 | \<1e-99 |   24.7407 |
| Days        |  10.4673 | 1.5458 |  6.77 | \<1e-10 |    5.9221 |
| Residual    |  25.5918 |        |       |         |           |

### Data type conversion

Be sure to pass integers (vs. doubles) to Julia functions that expect
Integer type, (e.g., the `parametricbootstrap()` example above):

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
jlme_status() # Should now see MKL loaded here
```

### Performance (data transfer)

In practice, most of the overhead will come from transferring the data
from R to Julia. If you are looking to fit many models to the same data,
you should first filter to keep only the columns you need and then use
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

`{jlme}` is powered by
[`{JuliaConnectoR}`](https://github.com/stefan-m-lenz/JuliaConnectoR).
Instructions below are adapted from `{JuliaConnectoR}`.

### Locating the executable

`{jlme}` requires that [Julia (version ≥ 1.8) is
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
  [GLM.jl](https://github.com/JuliaStats/GLM.jl),
  [StatsModels](https://github.com/JuliaStats/StatsModels.jl), and
  [MixedModels.jl](https://github.com/JuliaStats/MixedModels.jl) for
  interfaces to and implementations of (mixed effects) regression
  models.
