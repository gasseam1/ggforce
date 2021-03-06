% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/position-jitternormal.R
\name{position_jitternormal}
\alias{position_jitternormal}
\title{Jitter points with normally distributed random noise}
\usage{
position_jitternormal(sd_x = NULL, sd_y = NULL)
}
\arguments{
\item{sd_x, sd_y}{Standard deviation to add along the x and y axes. The 
  function uses \code{\link[stats]{rnorm}} with \code{mean = 0} behind 
  the scenes. 

  If omitted, defaults to 0.15. As with \code{\link[ggplot2]{geom_jitter}}, 
  categorical data is aligned on the integers, so a standard deviation of 
  more than 0.2 will spread the data so it's not possible to see the 
  distinction between the categories.}
}
\description{
\code{\link[ggplot2]{geom_jitter}} adds random noise to points using a 
uniform distribution. When many points are plotted, they appear in a 
rectangle. This position jitters points using a normal distribution instead,
resulting in more circular clusters.
}
\examples{
# Example data
df <- data.frame(x = sample(1:3, 1500, TRUE),
                 y = sample(1:3, 1500, TRUE))

# position_jitter results in rectangular clusters
ggplot(df, aes(x = x, y = y)) + 
  geom_point(position = position_jitter())

# geom_jitternormal results in more circular clusters
ggplot(df, aes(x = x, y = y)) + 
  geom_point(position = position_jitternormal())

# You can adjust the standard deviations along both axes
# Tighter circles
ggplot(df, aes(x = x, y = y)) + 
  geom_point(position = position_jitternormal(sd_x = 0.08, sd_y = 0.08))

# Oblong shapes
ggplot(df, aes(x = x, y = y)) + 
  geom_point(position = position_jitternormal(sd_x = 0.2, sd_y = 0.08))

# Only add random noise to one dimension
ggplot(df, aes(x = x, y = y)) + 
  geom_point(position = position_jitternormal(sd_x = 0.15, sd_y = 0),
             alpha = 0.1)
}

