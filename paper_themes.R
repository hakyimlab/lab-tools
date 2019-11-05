
# source this file into your script and add the theme to figures

library(tidyverse)

scatter_base_theme_ = function(base_size=15)
{
  theme_bw(base_size = base_size) + 
  theme(panel.border = element_blank(),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(colour = "#170a45", size = .5),
  axis.ticks = element_line(colour = "#170a45", size = .2),
  axis.text = element_text(color = '#170a45'))
}

bar_base_theme_ = function(base_size=15)
{
  list(theme_bw(base_size = base_size),
  theme(panel.border = element_blank(),
  panel.grid.major = element_blank(),
  panel.grid.minor = element_blank(),
  axis.line = element_line(colour = "#170a45", size = .5),
  axis.ticks = element_line(colour = "#170a45", size = .2),
  axis.text = element_text(color = '#170a45')),
  scale_y_continuous(expand=c(0,0)))
}