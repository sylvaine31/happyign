
# happyign

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![License:MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CRAN status](https://www.r-pkg.org/badges/version/happyign)](https://cran.r-project.org/package=happyign)
<!-- badges: end -->

Le _package_ `happyign` permet de requêter facilement l'API de l'IGN pour le calcul des isochrones et/ou des isodistances. 

## Installation

Pour installer le package :

``` r
# install.packages("remotes")
remotes::install_github("sylvaine31/happyign")
```
## Format des données

Les données en entrées doivent être au format `sf` avec des géométries de type `POINT`. 

En sortie, on obtient un objet au format `sf` avec des géométries de type `POLYGON`

Il peut y avoir plusieurs points en entrée. Dans ce cas l'objet `sf` en sortie comprendra autant de `POLYGON` qu'il y a de `POINT` en entrées.

## Exemple


``` r
library(happyign)

# Données en entrée
donnees <- tibble::tibble(x = c(1.3,1.4,1.5), y = c(43.5, 43.4, 43.6))

# Transformation au format sf

donnees_sf <-  sf::st_as_sf(donnees, coords = c("x","y"), crs = 4326)
                
# requête API de l'IGN pour calcul des isochrones par défaut (piéton, 10 minutes)
                
isochrones <- isochroner(donnees_sf)

# requête API de l'IGN pour des isodistances

isodistances <- isochroner(donnees_sf, q = 1, crs = 4326, costType = "distance",
                       profile = "pedestrian", distanceUnit = "kilometer")

```

Ce package est une ébauche et pourra être complété par des fonctions permettant d'utiliser les autres services API de l'IGN (calculs d'itinéraires, recherches d'adresses...).
