# Server logic
server <- function(input, output){
  
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
        include.provisional = T,
        token = Sys.getenv("NEON_PAT"),
        check.size = F)
      
      # Get 1m2 df, create 'year' variable
      data.div_1m2.ret <- data.portal[["div_1m2Data"]] %>%
        mutate(year = year(endDate))
      
      # Update 'nativeStatus' based on code
      nativeStat <- data.frame(
        nativeStatusCode = c("N", "I", "UNK", "NI"),
        nativeStatus = c("Native", "Introduced", "Unknown", "Native/Introduced")
      )
      
      data.div_1m2.ret <- merge(
        data.div_1m2.ret, nativeStat,
        by = "nativeStatusCode", all.x = T
      )
      
      # Cache
      data$div_1m2 <- rbind(data$div_1m2, data.div_1m2.ret)
      
      removeModal()
      
    } else # Load cached data if available
      data.div_1m2.ret <- data$div_1m2[data$div_1m2$siteID == site,]
    
    return(list(div_1m2 = data.div_1m2.ret))
  })
  
  
  # Update available bouts and plotIDs
  observe({
    
    if(input$site == ""){
      
      updateSelectInput(inputId = "plot", choices = "")
      updateSelectInput(inputId = "bout", choices = "")
      
    } else {
      
      data <- getData()$div_1m2
      data <- data[!is.na(data$percentCover),] # Remove plots with only SI records
      
      # Update plotIDs
      site_plots <- sort(unique(data$plotID))
      updateSelectInput(inputId = "plot", choices = c("", site_plots))
      
      # Update bouts
      site_bouts <- sort(unique(data$boutNumber))
      updateSelectInput(inputId = "bout", choices = site_bouts, selected = site_bouts[1])
    }
  })
  
  
  # Main processing of all 1m2 data
  portal_1m2_summary_all <- reactive({
    
    req(input$site, input$bout)
    
    bout <- input$bout
    
    df <- getData()$div_1m2 %>% 
      filter(
        !is.na(percentCover) # Removes e.g. 'sampling impractical' records
        & !subplotID %in% c("31_1_4", "41_1_1") # Makes pre-2019 data comparable
        & boutNumber == bout
      )
    
    # Species table
    df.spp <- df %>% 
      filter(divDataType == "plantSpecies") %>% 
      group_by(plotID, taxonID, scientificName, year, nativeStatus) %>% 
      summarise(percentCover_sum = sum(percentCover)) %>% 
      arrange(plotID, year, scientificName) %>% 
      ungroup()
    
    # otherVariables table
    df.var <- df %>% 
      filter(
        divDataType == "otherVariables"
        & !otherVariables %in% "overstory" # Deprecated, only present in very old data
      ) %>% 
      group_by(plotID, otherVariables, year) %>% 
      summarise(percentCover_sum = sum(percentCover)) %>% 
      arrange(plotID, year, otherVariables) %>% 
      ungroup()
    
    # Nativity status table
    df.nat <- df %>% 
      filter(divDataType == "plantSpecies") %>% 
      group_by(plotID, year, nativeStatus) %>% 
      summarise(percentCover_sum = sum(percentCover)) %>% 
      arrange(plotID, year, nativeStatus) %>% 
      ungroup()
    
    return(list(df.spp = df.spp, df.var = df.var, df.nat = df.nat))
  })
  
  
  # Filter to selected plot, generate long and wide tables
  portal_1m2_plot_tables <- reactive({
    
    req(input$plot)
    
    plot <- input$plot
    dataType <- input$portal_data_type
    
    if(dataType == "Plant Taxa") df <- portal_1m2_summary_all()$df.spp
    if(dataType == "Other Variables") df <- portal_1m2_summary_all()$df.var
    if(dataType == "Nativity Status") df <- portal_1m2_summary_all()$df.nat
    
    # Filter to plot, remove plotID col
    df.plot.long <- df %>%
      filter(plotID == plot) %>% 
      select(!plotID)
    
    # Table with year values wide, easier to see trends across time when viewed as table
    df.plot.wide <- df.plot.long %>% 
      pivot_wider(names_from = year, values_from = percentCover_sum) %>% 
      mutate_if(is.numeric, ~replace_na(., 0)) # Replace NA values with 0
    
    if(dataType == "Plant Taxa") df.plot.wide <- df.plot.wide %>% arrange(scientificName)
    if(dataType == "Other Variables") df.plot.wide <- df.plot.wide %>% arrange(otherVariables)
    if(dataType == "Nativity Status") df.plot.wide <- df.plot.wide %>% arrange(nativeStatus)
    
    # Back to long form, now with '0' values when not observed in a bout
    df.plot.long <- df.plot.wide %>% 
      pivot_longer(
        cols = colnames(df.plot.wide)[grepl("^[[:digit:]]+$", colnames(df.plot.wide))],
        names_to = "year", values_to = "percentCover_sum"
      ) %>% 
      mutate(year = as.numeric(year))
    
    return(list(long = df.plot.long, wide = df.plot.wide))
  })
  
  
  # Output plot species table (wide)
  output$spp_plot_summary <- renderDT({
    
    req(input$plot)
    
    data <- portal_1m2_plot_tables()$wide
    dataType <- input$portal_data_type
    plot <- input$plot
    
    # Make the table
    dt <- datatable(
      data,
      caption = tags$caption(
        style = "color: black; font-weight: bold;",
        paste0("Table: ", plot, ", ", dataType, ", Summed Percent Cover, per year"),
        selection = list(mode = "multiple")
      ),
      options = list(
        paging = F, dom = 'iftr', scrollY = "30vh", scrollX = T,
        initComplete = DT::JS("function(){$(this).addClass('compact');}"),
        columnDefs = list(list(className = "dt-center", targets = "_all"))
      ),
      filter = "top", rownames = F, class = "display compact cell-border stripe"
    ) %>%
      formatStyle(names(data)[names(data) %in% "scientificName"], fontSize = "80%") %>%
      formatStyle(
        colnames(data)[grepl("^[[:digit:]]+$", colnames(data))],
        backgroundColor = styleInterval(0, c("#ffffb8", "#ccffcc")),
        color = styleInterval(0, c("lightgrey", "black"))
      )
  })
  
  # 'De-select All Rows' button
  observeEvent(
    input$spp_plot_summary_ds_all, DT::selectRows(DT::dataTableProxy("spp_plot_summary"), NULL)
  )
  
  
  # Output plotly graph
  output$spp_plot_plotly <- renderPlotly({
    
    req(input$plot)
    
    data <- portal_1m2_plot_tables()
    data.long <- data$long
    dataType <- input$portal_data_type
    plot <- input$plot
    transform_y <- input$transform_y
    row.sel <- input$spp_plot_summary_rows_selected # Index of selected rows from table
    
    # Filter plotted values based on selected rows; show all if none selected
    # Using index values since name of first column is variable
    if(!is.null(row.sel)){
      data.wide <- data$wide
      sel <- data.wide[row.sel,][[1]] # Vec of selected values from first column
      data.long <- data.long[data.long[[1]] %in% sel,] # Filter first column of plotted values
    }
    
    # Year range for plot title
    years <- range(data.long$year)
    
    ## Make the plot
    
    # Data and certain display values adjusted per selected data type
    if(dataType == "Plant Taxa")
      p <- ggplot(
        data.long, aes(
          x = year, y = percentCover_sum, group = taxonID, color = taxonID,
          text = paste0(
            "<b>Year:</b> ", year, "<br>",
            "<b>Taxon ID:</b> ", taxonID, "<br>",
            "<b>Scientific Name:</b> ", scientificName, "<br>",
            "<b>Summed Percent Cover:</b> ", percentCover_sum
          ))) +
      scale_color_viridis(discrete = T)
    
    if(dataType == "Other Variables")
      p <- ggplot(
        data.long, aes(
          x = year, y = percentCover_sum, group = otherVariables, color = otherVariables,
          text = paste0(
            "<b>Year:</b> ", year, "<br>",
            "<b>Variable</b> ", otherVariables, "<br>",
            "<b>Summed Percent Cover:</b> ", percentCover_sum
          ))) +
      scale_color_manual(values = colors.otherVars)
    
    if(dataType == "Nativity Status")
      p <- ggplot(
        data.long, aes(
          x = year, y = percentCover_sum, group = nativeStatus, color = nativeStatus,
          text = paste0(
            "<b>Year:</b> ", year, "<br>",
            "<b>Nativity Status:</b> ", nativeStatus, "<br>",
            "<b>Summed Percent Cover:</b> ", percentCover_sum
          ))) +
      scale_color_manual(values = colors.nativeStat)
    
    # Consistent plotting parameters
    p <- p +
      # geom_line(stat = "smooth", method = "loess", linewidth = 0.5, alpha = 0.7, se = F, span = 0.3) +
      geom_line(linewidth = 0.5, alpha = 0.7) +
      geom_jitter(width = 0.001, height = 0, size = 1, alpha = 1) + # Distinguish overlapping data points on zoom
      scale_x_continuous(expand = c(0.005, 0.005), breaks = unique(data.long$year)) +
      theme_light() +
      labs(
        title = paste0(plot, ", ", dataType, ", Summed Percent Cover, ", years[1], " to ", years[2]),
        x = "<b>Year</b>", y = "<b>Summed Percent Cover</b>")
    
    # Transform y-values to log2 if selected, which expands visibility of small values
    # h/t https://stackoverflow.com/questions/40219639/ for how to preserve '0' values
    if(transform_y == "Log (Base 2)")
      p <- p + scale_y_continuous(trans = scales::pseudo_log_trans(base = 2))
    
    # Convert to plotly graph, for interactivity
    p <- ggplotly(p, tooltip = "text")
  })
  
}