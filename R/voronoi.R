#' Voronoi tesselation and delaunay triangulation
#'
#' This set of geoms and stats allows you to display voronoi tesselation and
#' delaunay triangulation, both as polygons and as line segments. Furthermore
#' it lets you augment your point data with related summary statistics. The
#' computations are based on the \code{\link[deldir]{deldir}} package.
#'
#' @section Aesthetics:
#' geom_voronoi_tile and geom_delaunay_tile understand the following aesthetics
#' (required aesthetics are in bold):
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{alpha}
#'  \item{color}
#'  \item{fill}
#'  \item{linetype}
#'  \item{size}
#' }
#' geom_voronoi_segment, geom_delaunay_segment, and geom_delaunay_segment2
#' understand the following aesthetics (required aesthetics are in bold):
#' \itemize{
#'  \item{\strong{x}}
#'  \item{\strong{y}}
#'  \item{alpha}
#'  \item{color}
#'  \item{linetype}
#'  \item{size}
#' }
#'
#' @section Computed variables:
#' stat_delvor_summary computes the following variables:
#' \describe{
#'  \item{x, y}{If \code{switch.centroid = TRUE} this will be the coordinates for
#'  the voronoi tile centroid, otherwise it is the original point}
#'  \item{xcent, ycent}{If \code{switch.centroid = FALSE} this will be the
#'  coordinates for the voronoi tile centroid, otherwise it will be \code{NULL}}
#'  \item{xorig, yorig}{If \code{switch.centroid = TRUE} this will be the
#'  coordinates for the original point, otherwise it will be \code{NULL}}
#'  \item{ntri}{Number of triangles emanating from the point}
#'  \item{triarea}{The total area of triangles emanating from the point divided
#'  by 3}
#'  \item{triprop}{\code{triarea} divided by the sum of the area of all
#'  triangles}
#'  \item{nsides}{Number of sides on the voronoi tile associated with the point}
#'  \item{nedges}{Number of sides of the associated voronoi tile that is part of
#'  the bounding box}
#'  \item{vorarea}{The area of the voronoi tile associated with the point}
#'  \item{vorprop}{\code{vorarea} divided by the sum of all voronoi tiles}
#' }
#'
#' @inheritParams ggplot2::geom_polygon
#' @inheritParams ggplot2::geom_segment
#' @inheritParams geom_link
#'
#' @param bound The bounding rectangle for the tesselation. Defaults to
#' \code{NULL} which creates a rectangle expanded 10\% in all directions. If
#' supplied it should be a vector giving the bounds in the following order:
#' xmin, xmax, ymin, ymax.
#'
#' @param eps A value of epsilon used in testing whether a quantity is zero,
#' mainly in the context of whether points are collinear. If anomalous errors
#' arise, it is possible that these may averted by adjusting the value of eps
#' upward or downward.
#'
#' @param normalize Should coordinates be normalized prior to calculations. If
#' \code{x} and \code{y} are in wildly different ranges it can lead to
#' tesselation and triangulation that seems off when plotted without
#' \code{\link[ggplot2]{coord_fixed}}. Normalization of coordinates solves this.
#' The coordinates are transformed back after calculations.
#'
#' @author Thomas Lin Pedersen
#'
#' @name geom_voronoi
#' @aliases geom_delaunay
#' @rdname geom_delvor
#'
#' @examples
#' # Voronoi
#' ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'   geom_voronoi_tile(aes(fill = Species)) +
#'   geom_voronoi_segment() +
#'   geom_text(aes(label = ..nsides.., size = ..vorarea..),
#'             stat = 'delvor_summary', switch.centroid = TRUE)
#'
#' # Difference of normalize = TRUE
#' ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'   geom_voronoi_tile(aes(fill = Species), normalize = TRUE) +
#'   geom_voronoi_segment(normalize = TRUE) +
#'   geom_text(aes(label = ..nsides.., size = ..vorarea..),
#'             stat = 'delvor_summary', switch.centroid = TRUE, normalize = TRUE)
#'
#' # Delaunay triangles - interpolation of species
#' ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'   geom_delaunay_tile(alpha = 0.3) +
#'   geom_delaunay_segment2(aes(colour = Species, group = -1))
#'
NULL

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
StatVoronoiTile <- ggproto('StatVoronoiTile', Stat,
    compute_panel = function(data, scales, bound = NULL, eps = 1e-9, normalize = FALSE) {
        data$group <- seq_len(nrow(data))
        if (any(duplicated(data[, c('x', 'y')]))) {
            warning('stat_voronoi_tile: dropping duplicated points', call. = FALSE)
        }
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        vor <- deldir(data$x, data$y, rw = bound, eps = eps, suppressMsge = TRUE)
        tiles <- to_tile(vor)
        tiles$group <- vor$ind.orig[tiles$group]
        data$x <- NULL
        data$y <- NULL
        data <- merge(data, tiles, all = TRUE)
        if (normalize) {
            data$x <- rescale(data$x, to = x_range, from = c(0, 1))
            data$y <- rescale(data$y, to = y_range, from = c(0, 1))
        }
        data
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomPolygon
#' @export
geom_voronoi_tile <- function(mapping = NULL, data = NULL, stat = "voronoi_tile",
                        position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = FALSE,
                        show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = stat, geom = GeomPolygon,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm, ...))
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
StatVoronoiSegment <- ggproto('StatVoronoiSegment', Stat,
    compute_panel = function(data, scales, bound = NULL, eps = 1e-9, normalize = FALSE) {
        if (any(duplicated(data[, c('x', 'y')]))) {
            warning('stat_voronoi_segment: dropping duplicated points', call. = FALSE)
        }
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        vor <- deldir(data$x, data$y, rw = bound, eps = eps, suppressMsge = TRUE)
        segments <- vor$dirsgs[, 1:5]
        names(segments) <- c('x', 'y', 'xend', 'yend', 'group')
        segments$group <- vor$ind.orig[segments$group]
        data <- cbind(segments[, 1:4], data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE])
        if (normalize) {
            data$x <- rescale(data$x, to = x_range, from = c(0, 1))
            data$xend <- rescale(data$xend, to = x_range, from = c(0, 1))
            data$y <- rescale(data$y, to = y_range, from = c(0, 1))
            data$yend <- rescale(data$yend, to = y_range, from = c(0, 1))
        }
        data
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomSegment
#' @export
geom_voronoi_segment <- function(mapping = NULL, data = NULL, stat = "voronoi_segment",
                              position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = FALSE,
                              show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = stat, geom = GeomSegment,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm, ...))
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
StatDelaunayTile <- ggproto('StatDelaunayTile', Stat,
    compute_panel = function(data, scales, bound = NULL, eps = 1e-9, normalize = FALSE) {
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        data <- lapply(split(data, data$group), function(d) {
            if (any(duplicated(d[, c('x', 'y')]))) {
                warning('stat_delaunay_tile: dropping duplicated points', call. = FALSE)
            }
            vor <- deldir(d$x, d$y, rw = bound, eps = eps, suppressMsge = TRUE)
            d <- to_triangle(vor)
            d$group <- match(d$group, unique(d$group))
            d
        })
        for (i in seq_len(length(data) - 1) + 1) {
            max_group <- max(data[[i - 1]]$group)
            data[[i]]$group <- data[[i]]$group + max_group
        }
        data <- do.call(rbind, data)
        if (normalize) {
            data$x <- rescale(data$x, to = x_range, from = c(0, 1))
            data$y <- rescale(data$y, to = y_range, from = c(0, 1))
        }
        data
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomPolygon
#' @export
geom_delaunay_tile <- function(mapping = NULL, data = NULL, stat = "delaunay_tile",
                              position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = FALSE,
                              show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = stat, geom = GeomPolygon,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm, ...))
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
StatDelaunaySegment <- ggproto('StatDelaunaySegment', Stat,
    compute_group = function(data, scales, bound = NULL, eps = 1e-9, normalize = FALSE) {
        if (any(duplicated(data[, c('x', 'y')]))) {
            warning('stat_delaunay_segment: dropping duplicated points', call. = FALSE)
        }
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        vor <- deldir(data$x, data$y, rw = bound, eps = eps, suppressMsge = TRUE)
        segments <- vor$delsgs[, 1:5]
        names(segments) <- c('x', 'y', 'xend', 'yend', 'group')
        segments$group <- vor$ind.orig[segments$group]
        data <- cbind(segments[, 1:4], data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE])
        if (normalize) {
            data$x <- rescale(data$x, to = x_range, from = c(0, 1))
            data$xend <- rescale(data$xend, to = x_range, from = c(0, 1))
            data$y <- rescale(data$y, to = y_range, from = c(0, 1))
            data$yend <- rescale(data$yend, to = y_range, from = c(0, 1))
        }
        data
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomSegment
#' @export
geom_delaunay_segment <- function(mapping = NULL, data = NULL, stat = "delaunay_segment",
                                 position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = normalize,
                                 show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = stat, geom = GeomSegment,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm, ...))
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
StatDelaunaySegment2 <- ggproto('StatDelaunaySegment2', Stat,
    compute_group = function(data, scales, bound = NULL, eps = 1e-9, n = 100, normalize = FALSE) {
        if (any(duplicated(data[, c('x', 'y')]))) {
            warning('stat_delaunay_segment2: dropping duplicated points', call. = FALSE)
        }
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        vor <- deldir(data$x, data$y, rw = bound, eps = eps, suppressMsge = TRUE)
        segments <- rbind(structure(vor$delsgs[, c(1:2, 5)], names = c('x', 'y', 'group')),
                          structure(vor$delsgs[, c(3:4, 6)], names = c('x', 'y', 'group')))
        segments$group <- vor$ind.orig[segments$group]
        segments <- cbind(segments[, 1:2], data[segments$group, !names(data) %in% c('x', 'y'), drop = FALSE])
        segments$group <- rep(seq_len(nrow(vor$delsgs)), 2)
        segments <- segments[order(segments$group), ]
        if (normalize) {
            segments$x <- rescale(segments$x, to = x_range, from = c(0, 1))
            segments$y <- rescale(segments$y, to = y_range, from = c(0, 1))
        }
        StatLink2$compute_panel(segments, scales, n)
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomSegment
#' @export
geom_delaunay_segment2 <- function(mapping = NULL, data = NULL, stat = "delaunay_segment2",
                                  position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = FALSE, n = 100,
                                  show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = stat, geom = GeomPathInterpolate,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, n = n, na.rm = na.rm, ...))
}

#' @rdname ggforce-extensions
#' @format NULL
#' @usage NULL
#' @importFrom scales rescale
#' @importFrom deldir deldir
#' @importFrom ggplot2 ggproto Stat
#' @export
StatDelvorSummary <- ggproto('StatDelvorSummary', Stat,
    compute_group = function(data, scales, bound = NULL, eps = 1e-9, switch.centroid = FALSE, normalize = FALSE) {
        if (any(duplicated(data[, c('x', 'y')]))) {
            warning('stat_delaunay_segment2: dropping duplicated points', call. = FALSE)
        }
        if (normalize) {
            x_range <- range(data$x, na.rm = TRUE, finite = TRUE)
            y_range <- range(data$y, na.rm = TRUE, finite = TRUE)
            data$x <- rescale(data$x, from = x_range)
            data$y <- rescale(data$y, from = y_range)
            if (!is.null(bound)) {
                bound[1:2] <- rescale(bound[1:2], from = x_range)
                bound[3:4] <- rescale(bound[3:4], from = x_range)
            }
        }
        vor <- deldir(data$x, data$y, rw = bound, eps = eps, suppressMsge = TRUE)
        names(vor$summary) <- c('x', 'y', 'ntri', 'triarea', 'triprop', 'nsides', 'nedges', 'vorarea', 'vorprop')
        tiles <- to_tile(vor)
        vor$summary$xcent <- sapply(split(tiles$x, tiles$group), mean)
        vor$summary$ycent <- sapply(split(tiles$y, tiles$group), mean)
        data <- cbind(data[vor$ind.orig, , drop = FALSE], vor$summary[, !names(vor$summary) %in% c('x', 'y'), drop = FALSE])
        if (normalize) {
            data$x <- rescale(data$x, to = x_range, from = c(0, 1))
            data$xcent <- rescale(data$xcent, to = x_range, from = c(0, 1))
            data$y <- rescale(data$y, to = y_range, from = c(0, 1))
            data$ycent <- rescale(data$ycent, to = y_range, from = c(0, 1))
        }
        if (switch.centroid) {
            names(data)[match(c('xcent', 'ycent', 'x', 'y'), names(data))] <- c('x', 'y', 'xorig', 'yorig')
        }
        data
    },
    required_aes = c('x', 'y')
)

#' @rdname geom_delvor
#' @importFrom ggplot2 layer GeomSegment
#' @export
stat_delvor_summary <- function(mapping = NULL, data = NULL, geom = "point",
                                   position = "identity", na.rm = FALSE, bound = NULL, eps = 1e-9, normalize = FALSE,
                                   show.legend = NA, inherit.aes = TRUE, ...) {
    layer(data = data, mapping = mapping, stat = StatDelvorSummary, geom = geom,
          position = position, show.legend = show.legend, inherit.aes = inherit.aes,
          params = list(bound = bound, eps = eps, normalize = normalize, na.rm = na.rm, ...))
}


# HELPERS -----------------------------------------------------------------


#' @importFrom deldir get.cnrind
to_tile <- function(object) {
    tiles <- rbind(structure(object$dirsgs[, c(1:2, 5)], names = c('x', 'y', 'group')),
                   structure(object$dirsgs[, c(1:2, 6)], names = c('x', 'y', 'group')),
                   structure(object$dirsgs[, c(3:5)], names = c('x', 'y', 'group')),
                   structure(object$dirsgs[, c(3:4, 6)], names = c('x', 'y', 'group')))
    tiles <- unique(tiles)
    tiles <- rbind(tiles,
                   data.frame(x = object$rw[c(1, 2, 2, 1)],
                              y = object$rw[c(3, 3, 4, 4)],
                              group = get.cnrind(object$summary$x,
                                                 object$summary$y,
                                                 object$rw)
                   )
    )
    tiles$theta <- atan2(tiles$y - object$summary$y[tiles$group],
                         tiles$x - object$summary$x[tiles$group])
    tiles$theta <- ifelse(tiles$theta > 0, tiles$theta, tiles$theta + 2 * pi)
    tiles[order(tiles$group, tiles$theta), ]
}
to_triangle <- function(object) {
    tiles <- rbind(structure(object$dirsgs[, c(1:2, 5)], names = c('x', 'y', 'point')),
                   structure(object$dirsgs[, c(3:4, 6)], names = c('x', 'y', 'point')))
    tiles$group <- as.integer(factor(paste0(signif(tiles$x, 5), '_', signif(tiles$y, 5))))
    #tiles <- tiles[tiles$tri %in% unique(tiles$tri[duplicated(tiles$tri)]),]
    unconform <- table(tiles$group)
    unconform <- as.integer(names(unconform[unconform != 3]))
    unconform_point <- tiles$point[tiles$group %in% unconform]
    tiles <- tiles[!tiles$group %in% unconform, , drop = FALSE]
    unconform_seg <- object$delsgs$ind1 %in% unconform_point & object$delsgs$ind2 %in% unconform_point
    object$delsgs <- object$delsgs[unconform_seg, , drop = FALSE]
    last_points <- tri_mat(object)
    last_points <- data.frame(point = as.vector(last_points), group = rep(seq(max(tiles$group) + 1, length.out = ncol(last_points)), each = 3))
    triangles <- rbind(tiles[, c('point', 'group'), drop = FALSE], last_points)
    triangles$x <- object$summary$x[triangles$point]
    triangles$y <- object$summary$y[triangles$point]
    triangles <- triangles[order(triangles$group, triangles$point), ]
    triangles$group <- match(triangles$group, unique(triangles$group))
    dup_tri <- which(duplicated(matrix(triangles$point, ncol = 3, byrow = TRUE)))
    triangles <- triangles[!triangles$group %in% dup_tri, , drop = FALSE]
    triangles
}
tri_mat <- function(object) {
    a <- object$delsgs[, 5]
    b <- object$delsgs[, 6]
    tlist <- matrix(integer(0), 3, 0)
    for (i in union(a, b)) {
        jj <- c(b[a == i], a[b == i])
        jj <- sort(unique(jj))
        jj <- jj[jj > i]
        if (length(jj) > 0)
            for (j in jj) {
                kk <- c(b[a == j], a[b == j])
                kk <- kk[(kk %in% jj) & (kk > j)]
                if (length(kk) > 0)
                    for (k in kk) tlist <- cbind(tlist, c(i, j,
                                                          k))
            }
    }
    tlist
}
