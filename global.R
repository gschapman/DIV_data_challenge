library(neonUtilities)
library(lubridate)
library(ggplot2)
library(tidyr)
library(dplyr)
library(plotly)
library(viridis)
library(shiny)
library(DT)

# Suppress dplyr::summarise info
options(dplyr.summarise.inform = F)

# Domain and site list for selections
sites <- readRDS("sites.rds")

# Define colors for 'otherVariables'
colors.otherVars <- c(
  biocrustDarkCyanobacteria = "#00994d", biocrustLichen = "#b3ffec", biocrustLightCyanobacteria = "#e6fff2",
  biocrustMoss = "#adebad", fungi = "#d6d6c2", lichen = "#aaff33", litter = "#ffaa33", moss = "#88aa33", other = "#ff99dd",
  otherNonVascular = "#ccccff", rock = "#777777", scat = "#996633", soil = "#883311", standingDead = "#ccccb3",
  standingDeadHerbaceous = "#fff7e6", standingDeadWoody = "#8a8a5c", water = "#99e6ff", wood = "#cc8833",
  Traces = "#cccccc", missing = "#000000"
)

# colors.otherVars <- data.frame(
#   Other.vars = names(colors.otherVars), color = colors.otherVars
# )