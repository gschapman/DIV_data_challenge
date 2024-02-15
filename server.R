# Server logic
server <- function(input, output) {
  
  # Observers to update selection lists - domain and site
  # Plot id selections available after data download
  observe({
    domains <- unique(sites$domainid)
    updateSelectInput(inputId = "domain", choices = c("", domains))
  })
  
  observe({
    domain_sites <- unique(sites[sites$domainid == input$domain,]$siteid)
    updateSelectInput(inputId = "site", choices = c("", domain_sites))
  })
  
  
  
  ##### Get Portal data #####
  
  data <- reactiveValues() # For cacheing
  data$div_1m2 <- data.frame() # 1m2 data cache
  # data$div_10m2_100m2 <- data.frame() # 10m2/100m2 data cache
  
  # D/l data if needed, or load from cache
  getData <- reactive({
    
    req(input$site)
    
    site <- input$site
    
    data.div_1m2.ret <- data.frame()
    
    ## DL if needed
    if(!site %in% data$div_1m2$siteID){
      
      showModal(modalDialog("Downloading DIV Portal Data...", footer = NULL))
      
      # Download
      data.portal  <- loadByProduct(
        dpID = "DP1.10058.001",
        site = site,
        check.size = F
      )
      
      # Get 1m2 df, create 'year' variable
      data.div_1m2.ret <- data.portal[["div_1m2Data"]] %>%
        mutate(year = year(endDate))
      
      # Cache
      data$div_1m2 <- rbind(data$div_1m2, data.div_1m2.ret)
      
      removeModal()
      
    } else {
      
      # Load cached data if found in cache
      data.div_1m2.ret <- data$div_1m2[data$div_1m2$siteID == site,]
    }
    
    return(list(div_1m2 = data.div_1m2.ret))
  })
  
  
  
  # Update available plotIDs
  observe({
    data <- getData()$div_1m2
    site_plots <- sort(unique(data[data$siteID == input$site,]$plotID))
    updateSelectInput(inputId = "plot", choices = c("", site_plots))
  })
  
  
  
  # Main processing of all 1m2 data
  portal_1m2_summary_all <- reactive({
    
    req(input$site)
    
    df <- getData()$div_1m2
    
    df.spp <- df %>% 
      filter(
        divDataType == "plantSpecies"
        & !is.na(percentCover)
        & !subplotID %in% c("31_1_4", "41_1_1") # Makes pre-2019 data comparable
      ) %>% 
      group_by(plotID, taxonID, scientificName, year) %>% 
      summarise(
        percentCover_sum = sum(percentCover),
      ) %>% 
      arrange(plotID, year, scientificName)
    
    return(df.spp)
  })
  
  
  # Filter to selected plot, generate long and wide tables
  portal_1m2_plot_tables <- reactive({
    
    req(input$plot)
    
    plot <- input$plot
    
    df <- portal_1m2_summary_all()
    
    # Filter to plot
    df.plot.long <- df %>% filter(plotID == plot)
    
    # Table with year values wide, easier to see trends across time when viewed as table
    df.plot.wide <- df.plot.long %>% 
      pivot_wider(names_from = year, values_from = percentCover_sum) %>% 
      arrange(scientificName) %>% 
      ungroup()
    
    return(list(long = df.plot.long, wide = df.plot.wide))
  })
  
  
  # Output plot species table (wide)
  output$spp_plot_summary <- renderDT({
    
    req(input$plot)
    
    data <- portal_1m2_plot_tables()$wide
    
    # Replace NA values in numeric columns w/ 0
    # h/t https://stackoverflow.com/questions/19379081
    data <- data %>% mutate_if(is.numeric, ~replace_na(., 0))
    
    dt <- datatable(
      data,
      caption = "Table: Summed percent cover, per species, per year",
      options = list(
        paging = F, dom = 'iftr', scrollY = "30vh", scrollX = T,
        initComplete = DT::JS("function(){$(this).addClass('compact');}"),
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      ),
      filter = "top", rownames = F, class = "display compact cell-border stripe"
    ) %>%
      formatStyle("scientificName", fontSize = "80%") %>%
      formatStyle(
        colnames(data)[grepl("^[[:digit:]]+$", colnames(data))],
        backgroundColor = styleInterval(0, c("#ffffb8", "#ccffcc")),
        color = styleInterval(0, c("lightgrey", "black"))
      )
  })
  
  
  output$spp_plot_plotly <- renderPlotly({
    
    req(input$plot)
    
    data <- portal_1m2_plot_tables()$long
    
    # Year range for plot title
    years <- range(data$year)
    
    p <- ggplot(
      data, aes(
        # x = year, y = percentCover_sum, group = scientificName, color = scientificName,
        x = year, y = percentCover_sum, group = taxonID, color = taxonID,
        text = paste0(
          "<b>Year:</b> ", year, "<br>",
          "<b>Taxon ID:</b> ", taxonID, "<br>",
          "<b>Scientific Name:</b> ", scientificName, "<br>",
          "<b>Summed Percent Cover:</b> ", percentCover_sum
        ))) +
      geom_line(linewidth = 0.5, alpha = 0.5) +
      # geom_point(size = 1, alpha = 0.5) +
      geom_jitter(width = 0.001, height = 0.001, size = 1, alpha = 0.5) + # Distinguish overlapping data points on zoom
      scale_x_continuous(expand = c(0.005, 0.005)) +
      scale_color_viridis(discrete = T) +
      theme_light() +
      labs(
        title = paste0(input$plot, ", Summed Percent Cover by Species, ", years[1], " to ", years[2]),
        x = "<b>Year</b>", y = "<b>Summed Percent Cover</b>"
      )
    
    p <- ggplotly(p, tooltip = "text")
  })
  
}