#' QTS Distance Matrix Computation
#'
#' This function massages an input sample of quaternion time series to turn it
#' into a pairwise distance matrix.
#'
#' @param x A numeric matrix, data frame, [stats::dist] object or object of
#'   class [qts_sample] specifying the sample on which to compute the pairwise
#'   distance matrix.
#' @param metric A character string specifying the distance measure to be used.
#'   This must be one of `"euclidean"`, `"maximum"`, `"manhattan"`,
#'   `"canberra"`, `"binary"` or `"minkowski"` if `x` is not a QTS sample.
#'   Otherwise, it must be one of `"l2"`, `"pearson"` or `"dtw"`.
#' @inheritParams stats::dist
#' @inheritParams fdacluster::fdadist
#' @param rotation_invariance A boolean value specifying whether the distance
#'   should be invariant to rotation. This is only relevant when
#'   `is_domain_interval` is `TRUE` and `transformation` is `"srvf"` and
#'   `warped_class` is `"bpd"`. Defaults to `FALSE`.
#' @param ncores An integer value specifying the number of cores to use for
#'   parallel computation. Defaults to `1`.
#'
#' @param ... not used.
#'
#' @return An object of class [stats::dist].
#'
#' @export
#' @examples
#' D <- dist(vespa64$igp[1:5])
dist <- function(x, metric, ...) {
  UseMethod("dist")
}

#' @export
#' @rdname dist
dist.default <- function(
  x,
  metric = c(
    "euclidean",
    "maximum",
    "manhattan",
    "canberra",
    "binary",
    "minkowski"
  ),
  diag = FALSE,
  upper = FALSE,
  p = 2,
  ...
) {
  metric <- match.arg(
    metric,
    choices = c(
      "euclidean",
      "maximum",
      "manhattan",
      "canberra",
      "binary",
      "minkowski"
    )
  )
  stats::dist(
    x = x,
    method = metric,
    diag = diag,
    upper = upper,
    p = p
  )
}

#' @export
#' @rdname dist
dist.qts_sample <- function(
  x,
  metric = c("l2", "normalized_l2", "pearson", "dtw"),
  is_domain_interval = FALSE,
  transformation = c("identity", "srvf"),
  warping_class = c("none", "shift", "dilation", "affine", "bpd"),
  rotation_invariance = FALSE,
  cluster_on_phase = FALSE,
  labels = NULL,
  ncores = 1L,
  ...
) {
  transformation <- rlang::arg_match(transformation)
  metric <- rlang::arg_match(metric)
  warping_class <- rlang::arg_match(warping_class)

  if (is_domain_interval && transformation == "srvf") {
    if (!(warping_class %in% c("none", "bpd")))
      cli::cli_abort(
        "The warping class {.arg warping_class} is not compatible with the transformation {.arg transformation}."
      )
    logx <- log(x)
    L <- 3L
    M <- nrow(logx[[1]])
    N <- length(logx)
    beta <- array(dim = c(L, M, N))
    for (n in 1:N) {
      beta[1, , n] <- logx[[n]]$x
      beta[2, , n] <- logx[[n]]$y
      beta[3, , n] <- logx[[n]]$z
    }
    out <- fdasrvf::curve_dist(
      beta,
      alignment = (warping_class == "bpd"),
      rotation = rotation_invariance,
      ncores = ncores
    )
    if (cluster_on_phase) return(out$Dp) else return(out$Da)
  }

  if (metric == "dtw") {
    return(distDTW(
      qts_list = x,
      normalize_distance = TRUE,
      labels = labels,
      resample = FALSE,
      disable_normalization = TRUE,
      step_pattern = dtw::symmetric2
    ))
  }

  l <- prep_data(x)

  fdacluster::fdadist(
    x = l$grid,
    y = l$values,
    is_domain_interval = is_domain_interval,
    transformation = transformation,
    warping_class = warping_class,
    metric = metric,
    cluster_on_phase = cluster_on_phase,
    labels = labels
  )
}

distDTW <- function(
  qts_list,
  normalize_distance = TRUE,
  labels = NULL,
  resample = TRUE,
  disable_normalization = FALSE,
  step_pattern = dtw::symmetric2
) {
  if (!is_qts_sample(qts_list))
    cli::cli_abort(
      "The input argument {.arg qts_list} should be of class {.cls qts_sample}. You can try {.fn as_qts_sample()}."
    )

  if (normalize_distance && is.na(attr(step_pattern, "norm")))
    stop("The provided step pattern is not normalizable.")

  if (!disable_normalization) {
    qts_list <- lapply(qts_list, normalize_qts)
  }

  if (resample) {
    qts_list <- lapply(qts_list, resample_qts, disable_normalization = TRUE)
  }

  n <- length(qts_list)
  if (is.null(labels)) labels <- 1:n

  indices <- linear_index(n)

  .pairwise_distances <- function(linear_indices) {
    pb <- progressr::progressor(along = linear_indices)
    future.apply::future_sapply(
      linear_indices,
      \(.x) {
        pb()
        i <- indices$i[.x]
        j <- indices$j[.x]
        dtw_data <- DTW(
          qts1 = qts_list[[i]],
          qts2 = qts_list[[j]],
          resample = FALSE,
          disable_normalization = TRUE,
          distance_only = TRUE,
          step_pattern = step_pattern
        )
        if (normalize_distance) dtw_data$normalizedDistance else
          dtw_data$distance
      }
    )
  }

  d <- .pairwise_distances(indices$k)

  attributes(d) <- NULL
  attr(d, "Labels") <- labels
  attr(d, "Size") <- n
  attr(d, "call") <- match.call()
  class(d) <- "dist"
  d
}

linear_index <- function(n) {
  res <- tidyr::expand_grid(i = 1:n, j = 1:n)
  res <- subset(res, res$j > res$i)
  res$k <- n * (res$i - 1) - res$i * (res$i - 1) / 2 + res$j - res$i
  res
}
