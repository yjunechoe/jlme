
<!-- README.md is generated from README.Rmd. Please edit that file -->

# jlme

<!-- badges: start -->
<!-- badges: end -->

The goal of jlme is to …

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
#> Starting Julia with 7 thread(s).
```

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
x$cyl_sum <- factor(x$cyl)
contrasts(x$cyl_sum) <- contr.sum(3)
lm(mpg ~ cyl_sum, x)
#> 
#> Call:
#> lm(formula = mpg ~ cyl_sum, data = x)
#> 
#> Coefficients:
#> (Intercept)     cyl_sum1     cyl_sum2  
#>     20.5022       6.1615      -0.7593
jlm(mpg ~ cyl_sum, x)
#> <Julia object of type StatsModels.TableRegressionModel>
#> 
#> mpg ~ 1 + cyl_sum
#> 
#> ─────────────────────────────────────────────────────────────────────────
#>                  Coef.  Std. Error      z  Pr(>|z|)  Lower 95%  Upper 95%
#> ─────────────────────────────────────────────────────────────────────────
#> (Intercept)  20.5022      0.593528  34.54    <1e-99   19.3389    21.6655
#> cyl_sum: 6    6.16147     0.816746   7.54    <1e-13    4.56068    7.76226
#> cyl_sum: 8   -0.759307    0.920304  -0.83    0.4093   -2.56307    1.04445
#> ─────────────────────────────────────────────────────────────────────────

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
#> Subject  (Intercept)  565.51066 23.78047
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
#> id (Intercept)  1.12072 1.05864
#> ───────────────────────────────────────────────────
#>                  Coef.  Std. Error      z  Pr(>|z|)
#> ───────────────────────────────────────────────────
#> (Intercept)  -1.10108    0.280679   -3.92    <1e-04
#> Anger         0.046271   0.0134905   3.43    0.0006
#> Gender: M     0.260067   0.153846    1.69    0.0909
#> ───────────────────────────────────────────────────
```
