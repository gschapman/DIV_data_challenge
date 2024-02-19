rm(list=ls()) # Clear global environment
graphics.off() # Close plots/figures

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

site <- "SCBI"

DIV.portal <- loadByProduct(
  dpID = "DP1.10058.001",
  site = site,
  check.size = F
)

DIV.1m2 <- DIV.portal[["div_1m2Data"]] %>%
  mutate(year = year(endDate))

nativeStat <- data.frame(
  nativeStatusCode = c("N", "I", "UNK", "NI"),
  nativeStatus = c("Native", "Introduced", "Unknown", "Native/Introduced")
)

DIV.1m2 <- merge(
  DIV.1m2, nativeStat,
  by = "nativeStatusCode", all.x = T
)

df.spp <- DIV.1m2 %>% 
  filter(divDataType == "plantSpecies") %>% 
  group_by(plotID, taxonID, scientificName, year) %>% 
  summarise(percentCover_sum = sum(percentCover)) %>% 
  arrange(plotID, year, scientificName) %>% 
  ungroup()

df.spp.nat <- DIV.1m2 %>% 
  filter(divDataType == "plantSpecies") %>% 
  group_by(plotID, taxonID, scientificName, year, nativeStatus) %>% 
  summarise(percentCover_sum = sum(percentCover)) %>% 
  arrange(plotID, year, scientificName) %>% 
  ungroup()


# 
# # This would be selectable
# plots <- unique(DIV.1m2$plotID)
# plot <- plots[12]
# 
# DIV.spp <- DIV.1m2 %>% 
#   filter(
#     divDataType == "plantSpecies"
#     & !is.na(percentCover)
#     & !subplotID %in% c("31_1_4", "41_1_1") # Makes pre-2019 data comparable
#   ) %>% 
#   group_by(plotID, taxonID, scientificName, year) %>% 
#   summarise(
#     percentCover_sum = sum(percentCover),
#     # # >1 summarizations causes 'unexpected results' per documentation
#     # n = n(),
#     # percentCover_mean = mean(percentCover)
#   ) %>% 
#   arrange(plotID, year, scientificName)
# 
# DIV.spp.plot <- DIV.spp %>% 
#   filter(plotID == plot)
# 
# # Table with year values wide, easier to see trends across time when viewed as table
# DIV.spp.wide <- DIV.spp.plot %>% 
#   pivot_wider(names_from = year, values_from = percentCover_sum)
#   
# years <- range(DIV.spp.plot$year)
# 
# p <- ggplot(
#   DIV.spp.plot, aes(
#     x = year, y = percentCover_sum, group = scientificName, color = scientificName
#   )
# ) +
#   geom_line(linewidth = 0.5, alpha = 0.5) +
#   # geom_point(size = 1, alpha = 0.5) +
#   geom_jitter(width = 0.001, height = 0.001, size = 1, alpha = 0.5) +
#   scale_x_continuous(expand = c(0.005, 0.005)) +
#   scale_color_viridis(discrete = T) +
#   labs(
#     title = paste0(plot, ", Cumulative Percent Cover by Species, ", years[1], " to ", years[2]),
#     x = "<b>Cumulative Percent Cover</b>", y = "<b>Year</b>"
#   )
# 
# print(ggplotly(p))
# 
# # DIV.spp <- DIV.1m2[DIV.1m2$taxonID %in% "ALPE4"
# #                    & !is.na(DIV.1m2$percentCover),]
# # 
# # DIV.spp$percentCover <- as.numeric(DIV.spp$percentCover)
# # 
# # ggplot(DIV.spp, aes(x = year, y = percentCover)) +
# #   geom_boxplot()
# 

