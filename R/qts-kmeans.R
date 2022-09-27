#' QTS K-Means Alignment Algorithm
#'
#' This function massages the input quaternion time series to feed them into the
#' k-means alignment algorithm for jointly clustering and aligning the input
#' QTS.
#'
#' @param x An object of class [qts_sample].
#' @param k An integer specifying the number of clusters to be formed. Defaults
#'   to `1L`.
#' @param centroid A string specifying which type of centroid should be used.
#'   Choices are `mean` and `medoid`. Defaults to `mean`.
#' @param dissimilarity A string specifying which type of dissimilarity should
#'   be used. Choices are `l2` and `pearson`. Defaults to `l2`.
#' @param warping A string specifying which class of warping functions should be
#'   used. Choices are `none`, `shift`, `dilation` and `affine`. Defaults to
#'   `affine`.
#' @param iter_max An integer specifying the maximum number of iterations for
#'   terminating the k-mean algorithm. Defaults to `20L`.
#' @param nstart An integer specifying the number of random restart for making
#'   the k-mean results more robust. Defaults to `1000L`.
#' @param ncores An integer specifying the number of cores to run the multiple
#'   restarts of the k-mean algorithm in parallel. Defaults to `1L`.
#'
#' @return An object of class `kma_qts` which is effectively a list with three
#'   components:
#' - `qts_aligned`: An object of class [qts_sample] storing the sample of
#' aligned QTS;
#' - `qts_centers`: A list of objects of class [qts] representing the centers of
#' the clusters;
#' - `best_kma_result`: An object of class [fdacluster::kma] storing the results
#' of the best k-mean alignment result among all initialization that were tried.
#' @export
#'
#' @examples
#' res_kma <- kmeans_qts(vespa64$igp, k = 2, nstart = 1)
kmeans_qts <-function(x,
                      k = 1,
                      centroid = "mean",
                      dissimilarity = "l2",
                      warping = "affine",
                      iter_max = 20,
                      nstart = 1000,
                      ncores = 1L) {
  if (!is_qts_sample(x))
    cli::cli_abort("The input argument {.arg x} should be of class {.cls qts_sample}.")

  q_list <- purrr::map(x, log_qts)
  q_list <- purrr::map(q_list, ~ rbind(.x$x, .x$y, .x$z))
  t_list <- purrr::map(x, "time")

  # Prep data
  n <- length(q_list)
  d <- dim(q_list[[1]])[1]
  p <- dim(q_list[[1]])[2]

  if (is.null(t_list))
    grid <- 0:(p-1)
  else
    grid <- matrix(nrow = n, ncol = p)

  values <- array(dim = c(n, d, p))
  for (i in 1:n) {
    values[i, , ] <- q_list[[i]]
    if (!is.null(t_list)) {
      grid[i, ] <- t_list[[i]]
    }
  }

  cl <- NULL
  if (ncores > 1L)
    cl <- parallel::makeCluster(ncores)

  B <- choose(n, k)

  if (nstart > B)
    init <- utils::combn(n, k, simplify = FALSE)
  else
    init <- replicate(nstart, sample.int(n, k), simplify = FALSE)

  solutions <- pbapply::pblapply(
    X = init,
    FUN = function(.init) {
      fdacluster::kma(
        grid,
        values,
        seeds = .init,
        n_clust = k,
        center_method = centroid,
        warping_method = warping,
        dissimilarity_method = dissimilarity,
        use_verbose = FALSE,
        warping_options = c(0.1, 0.1),
        use_fence = FALSE
      )
    },
    cl = cl
  )

  if (!is.null(cl))
    parallel::stopCluster(cl)

  wss_vector <- purrr::map_dbl(solutions, ~ sum(.x$final_dissimilarity))

  opt <- solutions[[which.min(wss_vector)]]

  centers <- purrr::map(1:opt$n_clust_final, ~ {
    exp_qts(as_qts(tibble::tibble(
      time = opt$x_centers_final[.x, ],
      w    = 0,
      x    = opt$y_centers_final[.x, 1, ],
      y    = opt$y_centers_final[.x, 2, ],
      z    = opt$y_centers_final[.x, 3, ]
    )))
  })

  res <- list(
    qts_aligned = as_qts_sample(purrr::imap(x, ~ {
      .x$time <- opt$x_final[.y, ]
      .x
    })),
    qts_centers = centers,
    best_kma_result = opt
  )

  class(res) <- "kma_qts"
  res
}

#' QTS K-Means Visualization
#'
#' @param x An object of class `kmeans_qts` as produced by the [kmeans_qts()]
#'   function.
#' @param ... Further arguments to be passed to other methods.
#'
#' @return The [plot.kma_qts()] method does not return anything while the
#'   [autoplot.kma_qts()] method returns a [ggplot2::ggplot] object.
#'
#' @importFrom graphics plot
#' @export
#'
#' @examples
#' res_kma <- kmeans_qts(vespa64$igp, k = 2, nstart = 1)
#' plot(res_kma)
#' ggplot2::autoplot(res_kma)
plot.kma_qts <- function(x, ...) {
  print(autoplot(x, ...))
}

#' @importFrom ggplot2 autoplot .data
#' @export
#' @rdname plot.kma_qts
autoplot.kma_qts <- function(x, ...) {
  data <- as_qts_sample(c(x$qts_centers, x$qts_aligned))
  n <- length(x$qts_aligned)
  k <- length(x$qts_centers)
  memb <- c(1:k, x$best_kma_result$labels)
  high <- c(rep(TRUE, k), rep(FALSE, n))
  autoplot(data, memberships = memb, highlighted = high) +
    ggplot2::labs(
      title = "K-Means Alignment Clustering Results",
      subtitle = cli::pluralize("Using {k} cluster{?s}")
    )
}