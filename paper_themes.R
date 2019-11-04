
# source this file into your script and add the theme to figures

library(tidyverse)

paper_base_theme_ <- theme(panel.border = element_blank(),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
		panel.background = element_rect(fill = "white"),
                axis.line = element_line(colour = "#170a45", size = .5),
                axis.ticks = element_line(colour = "#170a45", size = .2),
                axis.text = element_text(color = '#170a45'))
