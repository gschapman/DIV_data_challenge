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