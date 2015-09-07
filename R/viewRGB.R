#' Red-Green-Blue map view of a multi-layered Raster object
#'
#' @description
#' Make a Red-Green-Blue plot based on three layers (in a RasterBrick or RasterStack).
#' Three layers (sometimes referred to as "bands" because they may represent
#' different bandwidths in the electromagnetic spectrum) are combined such
#' that they represent the red, green and blue channel. This function can
#' be used to make 'true (or false) color images' from Landsat and other
#' multi-band satellite images. Note, this text is plagirized, i.e. copied
#' from \code{\link{plotRGB}}.
#'
#' @param x a RasterBrick or RasterStack
#' @param r integer. Index of the Red channel, between 1 and nlayers(x)
#' @param g integer. Index of the Green channel, between 1 and nlayers(x)
#' @param b integer. Index of the Blue channel, between 1 and nlayers(x)
#' @param quantiles the upper and lower quantiles used for streching
#' @param map the map to which the layer should be added
#' @param maxpixels integer > 0. Maximum number of cells to use for the plot.
#' If maxpixels < \code{ncell(x)}, sampleRegular is used before plotting.
#' @param map.types character spcifications for the base maps.
#' see \url{http://leaflet-extras.github.io/leaflet-providers/preview/}
#' for available options.
#' @param na.color the color to be used for NA pixels
#' @param ... additional arguments passed on to \code{\link{mapView}}
#'
#' @author
#' Tim Appelhans
#'
#' @examples
#' ### raster data ###
#' library(sp)
#' library(raster)
#'
#' data(meuse.grid)
#' coordinates(meuse.grid) = ~x+y
#' proj4string(meuse.grid) <- CRS("+init=epsg:28992")
#' gridded(meuse.grid) = TRUE
#' meuse_rst <- stack(meuse.grid)
#'
#' viewRGB(meuse_rst)
#' viewRGB(meuse_rst, 5, 4, 3)
#'
#' @export viewRGB
#' @name viewRGB
#' @rdname viewRGB
#' @aliases viewRGB
NULL

viewRGB <- function(x, r = 3, g = 2, b = 1,
                    quantiles = c(0.02, 0.98),
                    map = NULL,
                    maxpixels = 500000,
                    map.types = c("OpenStreetMap",
                                  "Esri.WorldImagery"),
                    na.color = "#00000000",
                    ...) {

  x <- rasterCheckAdjustProjection(x, maxpixels)

  mat <- cbind(x[[r]][],
               x[[g]][],
               x[[b]][])

  for(i in seq(ncol(mat))){
    z <- mat[, i]
    lwr <- stats::quantile(z, quantiles[1], na.rm = TRUE)
    upr <- stats::quantile(z, quantiles[2], na.rm = TRUE)
    z <- (z - lwr) / (upr - lwr)
    z[z < 0] <- 0
    z[z > 1] <- 1
    mat[, i] <- z
  }

  na_indx <- apply(mat, 1, anyNA)
  cols <- mat[, 1]
  cols[na_indx] <- na.color
  cols[!na_indx] <- grDevices::rgb(mat[!na_indx, ], alpha = 1)
  p <- function(x) cols

  grp <- layerName()
  grp <- paste(grp, r, g, b, sep = ".")

  m <- initMap(map, map.types, projection(x))
  m <- leaflet::addRasterImage(map = m, x = x[[r]], colors = p,
                               group = grp)
  m <- mapViewLayersControl(map = m,
                            map.types = map.types,
                            names = grp)

  out <- new('mapview', object = x, map = m)

  return(out)

}