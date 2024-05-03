
<!-- README.md is generated from README.Rmd. Please edit that file -->

# jlme

<!-- badges: start -->
<!-- badges: end -->

Julia (mixed-effects) regression modelling from R

## Installation

You can install the development version of jlme from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("yjunechoe/jlme")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(jlme)
jlme_setup()
```

## Use `{jlme}`

### Fixed effects models

``` r
lm(mpg ~ hp, mtcars)
#> 
#> Call:
#> lm(formula = mpg ~ hp, data = mtcars)
#> 
#> Coefficients:
#> (Intercept)           hp  
#>    30.09886     -0.06823
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

x <- mtcars
x$am_sum <- factor(x$am)
contrasts(x$am_sum) <- contr.sum(2)
lm(mpg ~ am_sum, x)
#> 
#> Call:
#> lm(formula = mpg ~ am_sum, data = x)
#> 
#> Coefficients:
#> (Intercept)      am_sum1  
#>      20.770       -3.622
jlm(mpg ~ am_sum, x)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + am_sum
#> 
#> ────────────────────────────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)  Lower 95%  Upper 95%
#> ────────────────────────────────────────────────────────────────────────
#> (Intercept)  20.7698     0.882211  23.54    <1e-99   19.0407    22.4989
#> am_sum: 1    -3.62247    0.882211  -4.11    <1e-04   -5.35157   -1.89337
#> ────────────────────────────────────────────────────────────────────────

x$cyl_helm <- factor(x$cyl)
contrasts(x$cyl_helm) <- contr.helmert(3)
colnames(contrasts(x$cyl_helm)) <- c("4vs6", "4&6vs8")
lm(mpg ~ cyl_helm, x)
#> 
#> Call:
#> lm(formula = mpg ~ cyl_helm, data = x)
#> 
#> Coefficients:
#>    (Intercept)    cyl_helm4vs6  cyl_helm4&6vs8  
#>         20.502          -3.460          -2.701
jlm(mpg ~ cyl_helm, x)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + cyl_helm
#> 
#> ─────────────────────────────────────────────────────────────────────────────
#>                      Coef.  Std. Error      z  Pr(>|z|)  Lower 95%  Upper 95%
#> ─────────────────────────────────────────────────────────────────────────────
#> (Intercept)       20.5022     0.593528  34.54    <1e-99   19.3389    21.6655
#> cyl_helm: 4vs6    -3.46039    0.779174  -4.44    <1e-05   -4.98754   -1.93324
#> cyl_helm: 4&6vs8  -2.70108    0.387175  -6.98    <1e-11   -3.45993   -1.94223
#> ─────────────────────────────────────────────────────────────────────────────
```

### Mixed effects models

``` r
library(lme4)
#> Loading required package: Matrix

lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#> Linear mixed model fit by REML ['lmerMod']
#> Formula: Reaction ~ Days + (Days | Subject)
#>    Data: sleepstudy
#> REML criterion at convergence: 1743.628
#> Random effects:
#>  Groups   Name        Std.Dev. Corr
#>  Subject  (Intercept) 24.741       
#>           Days         5.922   0.07
#>  Residual             25.592       
#> Number of obs: 180, groups:  Subject, 18
#> Fixed Effects:
#> (Intercept)         Days  
#>      251.41        10.47
jlmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#> <Julia object of type LinearMixedModel>
#> 
#> Reaction ~ 1 + Days + (1 + Days | Subject)
#> 
#> Variance components:
#>             Column    Variance Std.Dev.   Corr.
#> Subject  (Intercept)  565.51065 23.78047
#>          Days          32.68212  5.71683 +0.08
#> Residual              654.94145 25.59182
#> ──────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)
#> ──────────────────────────────────────────────────
#> (Intercept)  251.405      6.63226  37.91    <1e-99
#> Days          10.4673     1.50224   6.97    <1e-11
#> ──────────────────────────────────────────────────
jlmer(Reaction ~ Days + (Days | Subject), sleepstudy, REML = TRUE)
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

glmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
#> Generalized linear mixed model fit by maximum likelihood (Laplace
#>   Approximation) [glmerMod]
#>  Family: binomial  ( logit )
#> Formula: r2 ~ Anger + Gender + (1 | id)
#>    Data: VerbAgg
#>       AIC       BIC    logLik  deviance  df.resid 
#>  9504.505  9532.240 -4748.253  9496.505      7580 
#> Random effects:
#>  Groups Name        Std.Dev.
#>  id     (Intercept) 1.059   
#> Number of obs: 7584, groups:  id, 316
#> Fixed Effects:
#> (Intercept)        Anger      GenderM  
#>    -1.10090      0.04626      0.26002
jlmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
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

``` r
jmod <- jlmer(Reaction ~ Days + (Days | Subject), sleepstudy)

tidy(jmod)
#>     effect    group                  term     estimate std.error statistic
#> 1    fixed     <NA>           (Intercept) 251.40510485  6.632258 37.906414
#> 2    fixed     <NA>                  Days  10.46728596  1.502236  6.967806
#> 3 ran_pars  Subject       sd__(Intercept)  23.78046792        NA        NA
#> 4 ran_pars  Subject              sd__Days   5.71682816        NA        NA
#> 5 ran_pars  Subject cor__(Intercept).Days   0.08133207        NA        NA
#> 6 ran_pars Residual       sd__Observation  25.59182388        NA        NA
#>         p.value
#> 1 2.017794e-314
#> 2  3.219214e-12
#> 3            NA
#> 4            NA
#> 5            NA
#> 6            NA
glance(jmod)
#>   nobs df    sigma    logLik      AIC      BIC deviance df.residual
#> 1  180  6 25.59182 -875.9697 1763.939 1783.097 1751.939         174
```

## With `{JuliaConnectoR}`

### Inspect model objects with Julia code

``` r
library(JuliaConnectoR)
juliaCall("propertynames", jmod)
#> <Julia object of type NTuple{36, Symbol}>
#> (:formula, :reterms, :Xymat, :feterm, :sqrtwts, :parmap, :dims, :A, :L, :optsum, :θ, :theta, :β, :beta, :βs, :betas, :λ, :lambda, :stderror, :σ, :sigma, :σs, :sigmas, :σρs, :sigmarhos, :b, :u, :lowerbd, :X, :y, :corr, :vcov, :PCA, :rePCA, :objective, :pvalues)
juliaLet("x.rePCA", x = jmod)
#> <Julia object of type @NamedTuple{Subject::Vector{Float64}}>
#> (Subject = [0.5406660352881864, 1.0],)
```

### Create bindings to Julia libs to access more features

``` r
MixedModels <- juliaImport("MixedModels")

# Long-form construction of the `jmod` sleepstudy model
jmod <- MixedModels$fit(
  MixedModels$LinearMixedModel,
  juliaEval("@formula(Reaction ~ Days + (Days | Subject))"),
  juliaPut(sleepstudy)
)
MixedModels$issingular(jmod)
#> [1] FALSE

# Same as above in complete Julia syntax, using the julia `sleepstudy` dataset
juliaEval("
  fit(
    LinearMixedModel,
    @formula(reaction ~ days + (days | subj)),
    MixedModels.dataset(:sleepstudy)
  )
")
#> <Julia object of type LinearMixedModel{Float64}>
#> Linear mixed model fit by maximum likelihood
#>  reaction ~ 1 + days + (1 + days | subj)
#>    logLik   -2 logLik     AIC       AICc        BIC    
#>   -875.9697  1751.9393  1763.9393  1764.4249  1783.0971
#> 
#> Variance components:
#>             Column    Variance Std.Dev.   Corr.
#> subj     (Intercept)  565.51065 23.78047
#>          days          32.68212  5.71683 +0.08
#> Residual              654.94145 25.59182
#>  Number of obs: 180; levels of grouping factors: 18
#> 
#>   Fixed-effects parameters:
#> ──────────────────────────────────────────────────
#>                 Coef.  Std. Error      z  Pr(>|z|)
#> ──────────────────────────────────────────────────
#> (Intercept)  251.405      6.63226  37.91    <1e-99
#> days          10.4673     1.50224   6.97    <1e-11
#> ──────────────────────────────────────────────────

# Use other features from MixedModels.jl
Random <- juliaImport("Random") # juliaEval('Pkg.add("Random")')
samp <- MixedModels$parametricbootstrap(
  Random$MersenneTwister(42L), # RNG
  1000L, # Number of simulations
  jmod # Model
)
samp
#> <Julia object of type MixedModelBootstrap{Float64}>
#> MixedModelBootstrap with 1000 samples
#>      parameter  min        q25         median     mean       q75        max
#>    ┌────────────────────────────────────────────────────────────────────────────
#>  1 │ β1         228.0      246.971     251.622    251.649    256.147    274.999
#>  2 │ β2         5.15834    9.43217     10.473     10.4527    11.5204    15.0879
#>  3 │ σ          21.0633    24.5771     25.5805    25.5978    26.5555    30.8172
#>  4 │ σ1         3.58918    17.9978     22.0802    21.926     25.9619    38.2521
#>  5 │ σ2         1.22321    4.57415     5.37824    5.38544    6.16644    9.19974
#>  6 │ ρ1         -0.810069  -0.128084   0.129044   0.153811   0.400835   1.0
#>  7 │ θ1         0.138296   0.692396    0.862739   0.861444   1.02355    1.62481
#>  8 │ θ2         -0.247944  -0.0280442  0.0257952  0.0265357  0.0789672  0.316962
#>  9 │ θ3         0.0        0.158461    0.197059   0.189155   0.230015   0.376857
```
