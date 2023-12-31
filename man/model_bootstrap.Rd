% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_bootstrap.R
\name{model_bootstrap}
\alias{model_bootstrap}
\title{model_bootstrap.R}
\usage{
model_bootstrap(
  data,
  model = NULL,
  ...,
  model_call_string = NULL,
  boot_it = 100,
  seed = 0,
  boot_alpha = 0.05,
  boot_centre = "mean",
  output = c("ale", "model_stats", "model_coefs"),
  ale_options = list(),
  tidy_options = list(),
  glance_options = list(),
  silent = FALSE
)
}
\arguments{
\item{data}{dataframe. Dataset that will be bootstrapped.}

\item{model}{See documentation for \code{\link[=ale]{ale()}}}

\item{...}{not used. Inserted to require explicit naming of subsequent arguments.}

\item{model_call_string}{character string. If NULL, \code{\link[=model_bootstrap]{model_bootstrap()}} tries to
automatically detect and construct the call for bootstrapped datasets. If it cannot, the
function will fail early. In that case, a character string of the full call
for the model must be provided that includes \code{boot_data} as the data argument for the call.
See examples.}

\item{boot_it}{integer from 0 to Inf. Number of bootstrap iterations.
If boot_it = 0, then the model is run as normal once on the full \code{data} with
no bootstrapping.}

\item{seed}{integer. Random seed. Supply this between runs to assure identical
bootstrap samples are generated each time on the same data.}

\item{boot_alpha}{numeric. The confidence level for the bootstrap confidence intervals is
1 - boot_alpha. For example, the default 0.05 will give a 95\% confidence
interval, that is, from the 2.5\% to the 97.5\% percentile.}

\item{boot_centre}{See See documentation for \code{\link[=ale]{ale()}}}

\item{output}{character vector. Which types of bootstraps to calculate and return:
\itemize{
\item 'ale': Calculate and return bootstrapped ALE data and plot.
\item 'model_stats': Calculate and return bootstrapped overall model statistics.
\item 'model_coefs': Calculate and return bootstrapped model coefficients.
\item 'boot_data': Return full data for all bootstrap iterations. This data will always be calculated
because it is needed for the bootstrap averages. By default, it is not returned
except if included in this \code{output} argument.
}}

\item{ale_options, tidy_options, glance_options}{list of named arguments.
Arguments to pass to the \code{\link[=ale]{ale()}}, \code{\link[broom:reexports]{broom::tidy()}}, or \code{\link[broom:reexports]{broom::glance()}} functions, respectively,
beyond (or overriding) the defaults. In particular, to obtain p-values for ALE
statistics, see the details.}

\item{silent}{See documentation for \code{\link[=ale]{ale()}}}
}
\value{
list with tibbles of the following elements (depending on values requested in
the \code{output} argument:
\itemize{
\item model_stats: bootstrapped results from \code{\link[broom:reexports]{broom::glance()}}
\item model_coefs: bootstrapped results from \code{\link[broom:reexports]{broom::tidy()}}
\item ale: bootstrapped ALE results
\itemize{
\item data: ALE data (see \code{\link[=ale]{ale()}} for details about the format)
\item stats: ALE statistics. The same data is duplicated with different views
that might be variously useful. The column
\itemize{
\item by_term: statistic, estimate, conf.low, median, mean, conf.high.
("term" means variable name.)
The column names are compatible with the \code{broom} package. The confidence intervals
are based on the \code{\link[=ale]{ale()}} function defaults; they can be changed with the
\code{ale_options} argument. The estimate is the median or the mean, depending
on the \code{boot_centre} argument.
\item by_statistic: term, estimate, conf.low, median, mean, conf.high.
\item estimate: term, then one column per statistic Provided with the default
estimate. This view does not present confidence intervals.
}
\item plots: ALE plots (see \code{\link[=ale]{ale()}} for details about the format)
}
\item boot_data: full bootstrap data (not returned by default)
\item other values: the \code{boot_it}, \code{seed}, \code{boot_alpha}, and \code{boot_centre} arguments that
were originally passed are returned for reference.
}
}
\description{
Execute full model bootstrapping with ALE calculation on each bootstrap run
}
\details{
No modelling results, with or without ALE, should be considered reliable without
being bootstrapped.
For large datasets with clear separation between training and testing samples,
\code{\link[=ale]{ale()}} bootstraps the ALE results of the test data. However, when a dataset
is too small to be subdivided into training and test sets, then the entire
model should be bootstrapped. That is, multiple models should be trained,
one on each bootstrap sample. The reliable results are the average results
of all the bootstrap models, however many there are. For details, see
the vignette on small datasets or the details and examples below.

\code{\link[=model_bootstrap]{model_bootstrap()}} automatically carries out full-model bootstrapping suitable
for small datasets. Specifically, it:
\itemize{
\item Creates multiple bootstrap samples (default 100; the user can specify any number);
\item Creates a model on each bootstrap sample;
\item Calculates model overall statistics, variable coefficients, and ALE values
for each model on each bootstrap sample;
\item Calculates the mean, median, and lower and upper confidence intervals for
each of those values across all bootstrap samples.
}

\strong{P-values}
The \code{\link[broom:reexports]{broom::tidy()}} summary statistics will provide p-values as normal, but the
situation is somewhat complicated with p-values for ALE statistics. The challenge
is that the procedure for obtaining their p-values is very slow: it involves
retraining the model 1000 times. Thus, it is not efficient to calculate p-values
on every execution of \code{model_bootstrap()}. Although the \code{\link[=ale]{ale()}} function provides
an 'auto' option for creating p-values,
that option is disabled in \code{model_bootstrap()} because it would be far too slow:
it would involve retraining the model 1000 times the number of bootstrap iterations.
Rather, you must first create a p-values function object using the procedure
described in \code{help(create_p_funs)}. If the name of your p-values object is
\code{p_funs}, you can then request p-values each time you run \code{model_bootstrap()}
by passing it the argument \code{ale_options = list(p_values = p_funs)}.
}
\examples{

# attitude dataset
attitude

## ALE for general additive models (GAM)
## GAM is tweaked to work on the small dataset.
gam_attitude <- mgcv::gam(rating ~ complaints + privileges + s(learning) +
                            raises + s(critical) + advance,
                          data = attitude)
summary(gam_attitude)

# Full model bootstrapping
# Only 3 bootstrap iterations for a rapid example; default is 100
# Increase value of boot_it for more realistic results
mb_gam <- model_bootstrap(
  attitude,
  gam_attitude,
  boot_it = 3
)

\donttest{
# If the model is not standard, supply model_call_string with
# 'data = boot_data' in the string (not as a direct argument to [model_bootstrap()])
mb_gam <- model_bootstrap(
  attitude,
  model_call_string = 'mgcv::gam(
    rating ~ complaints + privileges + s(learning) +
      raises + s(critical) + advance,
    data = boot_data
  )',
  boot_it = 3
)

# Model statistics and coefficients
mb_gam$model_stats
mb_gam$model_coefs

# Plot ALE
gridExtra::grid.arrange(grobs = mb_gam$ale$plots, ncol = 2)
}




}
\references{
Okoli, Chitu. 2023.
“Statistical Inference Using Machine Learning and Classical Techniques Based
on Accumulated Local Effects (ALE).” arXiv. \url{https://arxiv.org/abs/2310.09877}.
}
