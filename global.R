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


## Shared styles
sty.maintable <- "padding: 10px 10px 0px 10px; font-size: 90%; overflow-x: auto;"

## DT options

sty.dt.compact <- list(
  paging = F, dom = 'iftr', scrollY = "70vh", scrollX = T,
  fixedColumns = list(leftColumns = 1),
  initComplete = DT::JS("function(){$(this).addClass('compact');}"),
  columnDefs = list(list(className = "dt-center", targets = "_all"))
)