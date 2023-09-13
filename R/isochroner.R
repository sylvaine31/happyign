#' transforme lse objets sf pour pouvoir les envoyer dans la requête
#'
#' @param sf_object une objet sf avec une géométrie de type POINT
#'
#'@return une liste de points dans le bon format pour la requête

transform_sf <- function(sf_object){

  sf_geometry <- as.data.frame(sf::st_transform(sf_object, 4326)["geometry"])

  list_sf <- as.list(gsub( "[c|(|)|\\s]", "", sf_geometry$geometry, perl = TRUE))

  return(list_sf)
}

#' envoyer la requete
#'
#' @param entry un point dont les coordonnées sont exprimées dans le crs 4326
#' sous la forme "x,y" (transformé avec transform_sf)
#' @param q Une quantité de temps ou de distance (10 par défaut).
#' @param costType  Précise le type de calcul qui est fait : "time" pour les isochrone
#' ou "distance" pour les isodistance (isochrones par défaut)
#' @param profile  Type du coût utilisé pour le calcul : "pedestrian" pour les
#' piétons et "car" pour les voitures (Piéton par défaut).
#' @param timeUnit Permet de préciser l’unité dans laquelle les durées sont
#' exprimées dans la réponse : "hour", "minute" ou "second" (minutes par défaut)
#' @param distanceUnit Permet de préciser l’unité dans laquelle les distances
#' sont exprimées dans la réponse : "meter" ou "kilometer" (meter par défaut)
#' @param  direction  Sens du parcours. Soit on définit un point de départ
#' ("departure") et on obtient les points d'arrivée potentiels.
#' Soit on définit un point d'arrivée ("arrival") et on obtient les points de
#' départ potentiels (departure par défaut)
#' @param resource 	Ce paramètre permet de préciser quelle ressource sera utilisée
#' pour le calcul. Actuellement, les ressources de type " ISO " et " PGR "
#' sont disponibles pour l’isochrone(par défaut "bdtopo-iso"). Voir section `RESOURCE`
#' @param constraints Permet d’exprimer des contraintes sur les caractéristiques
#' du réseau routier pour le calcul d’isochrones/isodistances. Voir section `CONSTRAINTS`.
#'
#' @return les résultats d'une requête

get_query <- function(entry, q, costType, profile , timeUnit, distanceUnit,
                      direction, resource, constraints){
  request <- httr::GET("https://wxs.ign.fr/calcul/geoportail/isochrone/rest/1.0.0/isochrone?",
                       query = list(
                         point= entry,
                         costValue=q,
                         geometryFormat="geojson",
                         costType=costType,
                         timeUnit=timeUnit,
                         distanceUnit = distanceUnit,
                         profile=profile,
                         crs = "EPSG:4326",
                         direction = "departure",
                         resource=resource,
                         constraints=constraints
                       ))
  return(request)
}



#' Calcul isochrones/isodistances
#'
#' Calcule les isochrones ou isodistances en France à partir d'un objet sf à l'aide de l'API de l'IGN
#' de la plateforme Géoportail. Les données de référence proviennent de la base de données
#' IGN BD TOPO®. Pour plus d'informations : https://geoservices.ign.fr/documentation/services/api-et-services-ogc/isochrone/api
#'
#' @section RESOURCE:
#'
#' Le calcul d’isochrones s’appuie sur les mêmes ressources que celles du calcul d’itinéraire.
#' Les ressources de type "PGR" et "ISO" sont utilisées, à savoir "bdtopo-iso" et "bdtopo-pgr".
#'
#' - "bdtopo-pgr" se base uniquement sur le nouveau moteur, mais manque de performance sur de grandes isochrones.
#' Elle est en revanche fonctionelle pour de petites isochrones.
#'
#' - "bdtopo-iso" se base sur les anciens services à partir d'une certaine distance pour régler les soucis de performance.
#' Nous vous conseillons son utilisation pour les isochrones larges.
#'
#' Les ressources PGR sont les ressources qui utilisent le moteur PGRouting pour calculer les isochrones.
#' Les ressources ISO sont des ressources plus génériques.
#' Le moteur utilisé pour les calculs varie en fonction de plusieurs paramètres.
#' À l'heure actuelle, le paramètre concerné est costValue, il s'agit du temps demandé ou de la distance demandée.
#'
#' @section CONSTRAINTS:
#'
#' Une contrainte s’exprime ainsi :
#' - la caractéristique (" key ") du réseau routier sur laquelle elle s’applique.
#'
#' - son type : actuellement, un seul : " banned " (exclusion)
#'
#' - un opérateur de comparaison
#'
#' - une valeur permettant d’exprimer la contrainte associée à la caractéristique
#'
#' Exemple : exclure d’emprunter les tronçons de route passant par des tunnels :
#' - " key " = " wayType "
#'
#' - type " = " banned "
#'
#' - Opérateur de comparaison = " = "
#'
#' - Valeur = " tunnel "
#'
#' Donne la requête suivante :
#'
#' constraints={"constraintType":"banned","key":"wayType","operator":"=","value":"tunnel"}
#'
#' L’éventail des contraintes possibles varie selon les ressources. Il est indiqué dans les capacités du service.
#'
#' @param sf_object Un objet sf avec une géométrie de type POINT, dont la colonne de geometry s'appelle "geometry".
#' Il peut y avoir plusieurs points dans l'objet. Dans ce cas, la sortie comprendra autant de polygones que de points.
#' @param q Une quantité de temps ou de distance (10 par défaut).
#' @param crs Le crs souhaité en sortie (EPSG:4326 par défaut).
#' @param costType  Précise le type de calcul qui est fait : "time" pour les isochrone
#' ou "distance" pour les isodistance (isochrones par défaut)
#' @param profile  Type du coût utilisé pour le calcul : "pedestrian" pour les
#' piétons et "car" pour les voitures (Piéton par défaut).
#' @param timeUnit Permet de préciser l’unité dans laquelle les durées sont
#' exprimées dans la réponse : "hour", "minute" ou "second" (minutes par défaut)
#' @param distanceUnit Permet de préciser l’unité dans laquelle les distances
#' sont exprimées dans la réponse : "meter" ou "kilometer" (meter par défaut)
#' @param  direction  Sens du parcours. Soit on définit un point de départ
#' ("departure") et on obtient les points d'arrivée potentiels.
#' Soit on définit un point d'arrivée ("arrival") et on obtient les points de
#' départ potentiels (departure par défaut)
#' @param resource 	Ce paramètre permet de préciser quelle ressource sera utilisée
#' pour le calcul. Actuellement, les ressources de type " ISO " et " PGR "
#' sont disponibles pour l’isochrone(par défaut "bdtopo-iso"). Voir section `RESOURCE`
#' @param constraints Permet d’exprimer des contraintes sur les caractéristiques
#' du réseau routier pour le calcul d’isochrones/isodistances. Voir section `CONSTRAINTS`.
#'
#' @return Un objet sf de type POLYGON
#'
#' @import httr
#' @import sf
#'
#' @examples
#' points <- data.frame(x = c(1.3,1.4,1.5), y = c(43.5, 43.4, 43.6))
#' points_sf <- sf::st_as_sf(points, coords = c("x","y"), crs = 4326)
#' isochroner(points_sf, crs = 3943)
#'
#' @export
#'

isochroner <- function(sf_object, q = 10, crs = 4326, costType = "time",
                       profile = "pedestrian", timeUnit="minute", distanceUnit = "kilometer",
                       direction = "departure", resource = "bdtopo-iso", constraints = NULL){

# verification
  stopifnot( "sf_object doit \\u00eatre un objet de classe sf avec une g\\u00e9om\\u00e9trie de type POINT" = "sf" %in% class(sf_object))
  stopifnot( "sf_object doit \\u00eatre un objet de classe sf avec une g\\u00e9om\\u00e9trie de type POINT" = sf::st_is(sf_object, "POINT"))


  list_oject <- transform_sf(sf_object)

  list_result <- lapply(list_oject, get_query,  q = q, costType = costType,
                        profile = profile, timeUnit=timeUnit, distanceUnit = distanceUnit,
                        direction = direction, resource = resource, constraints = constraints )

  list_content <- lapply(list_result, httr::content,as = "text", encoding = "UTF-8")

  list_content_sf <- lapply(list_content, sf::st_read)

  result <- do.call(rbind, lapply(list_content_sf, sf::st_transform, crs = crs))

  return(result)

}
