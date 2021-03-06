#' Take specifications and render a single chart
#'
#' @title plot_simple
#' @param ...
#'
#' @return
plot_simple<-function(...){

  spec_list<-list(...)

  #getting rid of an empty element in the spec list
  if(names(spec_list)[1] == ""){
    spec_list<-spec_list[-1]
  }


  #check, has the user specified anything that overwrites the default parameters?
  default_specs<-append(gevitr_env$plot_param_defaults,gevitr_env$plot_internal_defaults)
  over_write_default_idx<-match(names(spec_list),names(default_specs))
  over_write_default_idx<-over_write_default_idx[!is.na(over_write_default_idx)]

  #if yes, then use user's specification and not default
  if(length(over_write_default_idx)>0){
    default_specs[over_write_default_idx]<-NULL
    default_specs<-base::Filter(Negate(is.null), default_specs)
  }

  spec_list<-append(spec_list,default_specs)

  #check if user has provided a gevitR object or not
  data<-spec_list[["data"]]

  #if a character has been passed as the name, get that variable from the environment
  if(!is.data.frame(data)  && (class(data) %in% c("character","factor"))){
    data<-get(data,envir = globalenv())  #get data from the global environment
  }


  #now check if data is a gevitR object
  if(!is.data.frame(data)  && class(data) == "gevitDataObj"){
    tmp<-data@data[[1]]
    #if the user hasn't specific any metadata,
    #check if there's some already associated with the object
    if(is.na(spec_list[["metadata"]]) & length(data@data)>1){
      metadata<-if (!is.null(data@data$metadata)) data@data$metadata else NA
      spec_list[["metadata"]]<-metadata
    }
    #if its an image, also include the image details
    if(spec_list[["chart_type"]] == "image"){
      spec_list[["imgDetails"]]<-data@data$imgDetails
    }

    data<-tmp
  }

  # check if there is a directive from the combo to overwrite any of the data
  # in favour the axis data provided by the combo function
  if(!(is.null(spec_list$combo_axis_var))){
    if(is.data.frame(data)){
      #add a new variable to the data
      #in proper order
      idx_order<-match(data[,as.character(spec_list$combo_axis_var$common_var)],spec_list$combo_axis_var$var_lab)

      data$combo_axis_var<-spec_list$combo_axis_var$var[idx_order]

      #make that the variable to visualize on
      spec_list[[spec_list$combo_axis_var$var_match]]<-"combo_axis_var"
    }else{
      if(!(gsub(" ","_",spec_list$chart_type) %in% gevitr_env$lead_chart_types)){
        # -- TO DO : expand in future --
        if(spec_list$chart_type == "alignment"){
          spec_list[[spec_list$combo_axis_var$var_match]]<-"combo_axis_var"
        }else{
          print("Axis modification for non-tabular data currently not supported")
        }
      }

    }
  }


  spec_list[["data"]]<-data


  #call the rendering functions to make a single chart
  chart<-switch(spec_list[["chart_type"]],
         #common statistical charts types
         "bar" = do.call(render_bar,args = spec_list,envir = parent.frame()),
         "pie" = do.call(render_pie,args = spec_list,envir = parent.frame()),
         "line" = do.call(render_line,args = spec_list,envir = parent.frame()),
         "scatter" = do.call(render_scatter,args = spec_list,envir = parent.frame()),
         "histogram" = do.call(render_histogram,args = spec_list,envir = parent.frame()),
         "pdf" = do.call(render_1D_density,args = spec_list,envir = parent.frame()),
         "boxplot" = do.call(render_boxplot,args = spec_list,envir = parent.frame()),
         "swarmplot" = do.call(render_swarm_plot,args = spec_list,envir = parent.frame()),
         #colour charts types
         "heatmap" = do.call(render_heatmap,args = spec_list,envir = parent.frame()),
         "category stripe" = do.call(render_category_stripe,args = spec_list,envir = parent.frame()),
         "density" = do.call(render_1D_density,args = spec_list,envir = parent.frame()),
         #tree chart types
         "phylogenetic tree" = do.call(render_phylogenetic_tree,args = spec_list,envir = parent.frame()),
         "dendrogram" = do.call(render_dendrogram,args = spec_list,envir = parent.frame()),
         #relational chart types
         "node-link" = do.call(render_node_link,args = spec_list,envir = parent.frame()),
         "chord" = do.call(render_chord,args = spec_list,envir = parent.frame()),
         #spatial chart types - to revise
         "choropleth" = do.call(render_choropleth,args = spec_list,envir = parent.frame()),
         "geographic map"= do.call(render_geographic_map,args = spec_list,envir = parent.frame()),
         #temporal chart types
         "timeline" = do.call(render_timeline,args = spec_list,envir = parent.frame()),
         #genomic chart types
         "alignment" = do.call(render_alignment,args = spec_list,envir = parent.frame()),
         "sequence logo" = do.call(render_seqlogo,args = spec_list,envir = parent.frame()),
         #other char types
         "image" = do.call(render_image,args = spec_list,envir = parent.frame()),
          NULL)

    return(chart)
}

#'Many types general plot
#'
#'@param ... Any number of lists of arguments to generate a plot
#'@return plots to display
plot_many_types_general <- function(...) {
  args_list <- list(...)
  combo_plots<-arrange_plots(args_list, labels = "AUTO")

  return(combo_plots)
}

#' Plot small multiples
#' @title plot_small_multiples
#' @param ...
#'
#' @return
plot_small_multiples <- function(...) {

  spec_list<-list(...)

  #getting the data into a workable form
  #check if user has provided a gevitR object or not
  data<-spec_list[["data"]]

  #if a character has been passed as the name, get that variable from the environment
  if(!is.data.frame(data)  && (class(data) %in% c("character","factor"))){
    data<-get(data,envir = globalenv())  #get data from the global environment
  }

  #now check if data is a gevitR object
  if(!is.data.frame(data)  && class(data) == "gevitDataObj"){
    data_type<-data@type
    data<-data@data

    if(!is.null(data$metadata)){
      metadata<-data$metadata
    }

    data<-data[[1]]

  }else if(is.data.frame(data)){
    data_type<-"table"
    metadata<-ifelse(is.na(spec_list$metadata),NA,spec_list$metadata)
  }else{
    data_type<-NA
  }


  #Only tabular data can be meaningfully subsetted
  #other data types, cannot be, and the whole original
  #chart must be shown, but only with specific subsets
  #of the data on it, which for other charts types
  #means that some metadta must be associated with it
  #that is subsetable
  if(data_type == "table"){
    #make sure the data has the same points in x and y
    #then send it off
    all_data_plot<-do.call(plot_simple,spec_list,envir=parent.frame())
    spec_list<-ggplot_scale_info(all_data_plot,spec_list)

    #generate charts for each subgroup
    facet_var<-spec_list$facet_by

    all_plots<-c()

    for(grpItem in as.character(unique(data[,facet_var]))){

      tmp<-data %>% dplyr::filter_(.dots = paste0(facet_var, "=='", grpItem, "'"))

      spec_list$data<-tmp
      spec_list$title<-grpItem
      all_plots[[grpItem]]<-do.call(plot_simple,args=spec_list,envir = parent.frame())
    }

    combo_plots<-arrange_plots(all_plots,combo_type="small_multiple")
  }else{
    #For non-tabular data types, you must provide some additional metadata
    if(is.null(metadata)){
      stop("To make a small multiple for this chart you need to provide additional metadata")
    }

    if(!(spec_list$chart_type %in% c("phylogenetic tree"))){
      stop("Small multiples have not yet been implemented for you chart type")
    }

    #make a simple plot, but indicate that it's for a combination
    spec_list$combo<-"small multiples"
    #generate charts for each subgroup
    facet_var<-spec_list$facet_by
    all_plots<-c()

    for(grpItem in unique(metadata[,facet_var])){
      #works for phylo tree, but need to test on others
      meta_sub<-metadata %>%
        dplyr::mutate_(.dots = paste0("show_var = ifelse(",facet_var," =='", grpItem,"','",grpItem,"','Other')"))

      #a small cheat
      colnames(meta_sub)<-c(head(colnames(meta_sub),-1),"show_var")
      meta_sub$show_var<-factor(meta_sub$show_var,levels=c(grpItem,"Other"))

      spec_list$data<-data
      spec_list$metadata<-meta_sub
      spec_list$title<-grpItem

      #just call a simple plot
      all_plots[[grpItem]]<-do.call(plot_simple,args=spec_list,envir = parent.frame())
    }
    combo_plots<-arrange_plots(all_plots,combo_type="small_multiple")
  }
  return(combo_plots)
}


plot_composite<-function(...){
  spec_list<-list(...)

  all_plots<-c()

  chart_info <- spec_list$chart_info %>%
    dplyr::mutate(isLead = ifelse(chart_type %in% gevitr_env$master_chart_types,TRUE,FALSE)) %>%
    dplyr::arrange(desc(isLead))


  # CHART ORDER
  # order charts, beginning with lead chart in initital position
  # data frame is already ordered from the arrange step
  # all specifications are valid with only one lead chart
  # all charts must align on a common variable
  chart_order<-chart_info$chart_name

  # FLIP COORD
  #Make sure that all chart co-ordinates are flipped to match
  #the lead chart - this will depend upon alignment direction
  #default is horizontal (align all the y-axis)

  #this is soley for a weird gevitrec call..
  #for some reason, the common var is established
  #within mincombinr, but not for gevitRec..
  #temporary back stop until error is found
  #within minCombinR this will never be null
  if(is.null(spec_list$common_var)){spec_list$common_var<- "gevitR_checkID"}


  if(!is.null(spec_list$alignment)){
    align_dir<-ifelse(tolower(spec_list$alignment) %in% c("h","v"),
                      spec_list$alignment,
                      "h")
  }else{
    align_dir<-"h"
  }

  if(align_dir == "h"){
    chart_info<- chart_info %>%
      mutate(flip_coord = ifelse(y == spec_list$common_var | is.na(y),FALSE,
                                ifelse(grepl("gevitR_checkID",x),
                                       FALSE,TRUE)))
  }else{
    chart_info<- chart_info %>%
      mutate(flip_coord = ifelse(x == spec_list$common_var | is.na(x),FALSE,
                                ifelse(grepl("gevitR_checkID",x),
                                       FALSE,TRUE)))
  }

  # PLOTTING FUNCTIONS
  # Generate the lead plot first, use that information to modify axis

  #if there is no lead chart pick one chart
  #but make sure the common axis is
  flip_lead_chart<-FALSE
  if(all(!chart_info$isLead)){
    #pick the first chart that doesn't need to flip co-ordinates
    leadChart<-chart_info %>% dplyr::filter(flip_coord == FALSE)
    if(nrow(leadChart)>0){
      leadChart<-leadChart[1,]$chart_name
    }else{
      #flip strongly flip the first chart
      leadChart<-chart_info[1,]$chart_name
      flip_lead_chart<-TRUE
    }

  }else{
    leadChart<-chart_info[which(chart_info$isLead),]$chart_name
  }

  if(length(leadChart)>1){
    stop("For some reason, this specification has two lead charts. This is not correct - specify_combination should have caught this error.")
  }else if(length(leadChart)==0){
    #If there's not lead chart, take the first chart and assign to be lead
   leadChart<-chart_order[1]
  }

  #If there is a lead chart, plot that first
  leadChart_baseSpecs<-get(leadChart,envir = globalenv())

  if(flip_lead_chart){
    leadChart_baseSpecs<-flip_coord<-TRUE
  }

  all_plots[[leadChart]]<-list(plotItem = do.call(plot_simple,args=leadChart_baseSpecs,envir = environment()))
  lead_axis_info<-get_axis_info(all_plots[[leadChart]]$plotItem,align = align_dir)


  #re-generate *all* charts. Its not enough to just use the lead
  #chart as is, need to pass explicit param to it too

  for(chart in chart_order){

     baseSpecs<-get(chart,envir = globalenv())
     tmp_info<-dplyr::filter(chart_info,chart_name == chart)

     #make sure axes align with leadChart breaks (if there is a lead chart)
     #again, assume primarily categorical variables, should change to support continous alignments
     if(grepl("gevitR_checkID",as.character(spec_list$common_var))){
       # -- TO DO: Make a bit better, but generally, these are in Y for composite --
       var_match<-"y"
     }else{
       var_match<-c("x","y")[match(spec_list$common_var,unlist(tmp_info[,c("x","y")]))]
     }

     #order and overlap of axis items
     if(chart != leadChart){
       supp_chart<-get(tmp_info$data,envir = globalenv())
       if(is.data.frame(supp_chart)){
          lab_dat<-supp_chart
       }else{
         lab_dat<-get_raw_data(supp_chart)
       }

       #Accept either exact matches, or instances where
       #One dataset is a complete and perfect subset of the other
       if(is.data.frame(lab_dat)){
         match_order<-match(lab_dat[,as.character(spec_list$common_var)],lead_axis_info$y_labels)
       }else{
         match_order<-match(get_raw_data(supp_chart),lead_axis_info$y_labels)
       }

       #this is one exception of alignments otherwise
       #everything must be a perfect match
       if(length(match_order)<length(lead_axis_info$y_labels)){
         #instances where one dataset is a perfect subset of the other
         baseSpecs$combo_axis_var<-list(var = lead_axis_info$y_break[match_order],
                                        var_lab = lead_axis_info$y_label[match_order],
                                        var_match=var_match,
                                        y_limits=c(min(lead_axis_info$y_break),max(lead_axis_info$y_break)),
                                        common_var = spec_list$common_var)
       }else{
         #instances of exact matches
         baseSpecs$combo_axis_var<-list(var = lead_axis_info$y_break,
                                        var_lab = lead_axis_info$y_label,
                                        var_match=var_match,
                                        common_var = spec_list$common_var)
       }
     }else{
       baseSpecs$combo_axis_var<-list(var = lead_axis_info$y_break,
                                      var_lab = lead_axis_info$y_label,
                                      var_match=var_match,
                                      common_var = spec_list$common_var)
     }

     #flip chart co-ordinates if necessary
     baseSpecs$flip_coord<-tmp_info$flip_coord

     #remove axis labels
      if(align_dir == "h"){
         baseSpecs$rm_y_labels<-TRUE
      }else{
        baseSpecs$rm_x_labels<-TRUE
      }

     #shrink plot margins on all combinations
     baseSpecs$shrink_plot_margin <-TRUE

     #generate the single chart
     #note, composites only support equal sets, or situations where one set is a total
     #and complete subset of the other.. in the latter case, there needs to be
     #more adjustment of the axis
     tmp<-do.call(plot_simple,args=baseSpecs,envir = parent.frame())
     all_plots[[chart]]<-list(plotItem = tmp) #need to store as list
  }

  #return the composite plot
  combo_plots<-arrange_plots(chart_list = all_plots,align_dir = align_dir,combo_type="spatially_aligned")

  return(combo_plots)

}


plot_many_linked<-function(...){
  spec_list<-list(...)
  all_plots<-c()

  for(spec_name in spec_list$base_charts){
    baseSpecs<-get(spec_name,envir = globalenv())
    baseSpecs$color<-spec_list$link_by

    all_plots[[spec_name]]<-do.call(plot_simple,args=baseSpecs,envir = environment())
  }

  combo_plots<-arrange_plots(all_plots,combo_type="color_aligned")

  return(combo_plots)

}

#'Helper function to arrange plots for displaying
#'@title arrange_plots
#'@param chart_list A list of charts
arrange_plots <- function(chart_list, labels = NULL,align_dir=NULL, combo_type=NULL) {
  chart_list <- lapply(chart_list, function(chart) {
    chart<-if("list" %in% class(chart)) chart[[1]] else chart
    chart_class<-class(chart)
    chart
    # if ('ggtree' %in% chart_class) {
    #   cowplot::plot_to_gtable(chart)
    # } else if('gg' %in% chart_class) {
    #   cowplot::plot_to_gtable(chart)
    #   # ggplotify::as.grob(chart)
    # } else if ('data.frame' %in% chart_class){
    #   multipanelfigure::capture_base_plot(chart)
    # } else if ('htmlwidget' %in% chart_class) {
    #   grid::grid.grabExpr(print(chart))
    # } else {
    #   chart
    # }
  })

  if(!is.null(combo_type)){
    if(combo_type == "color_aligned"){
      for(i in 1:(length(chart_list)-1)){
        chart_list[[i]]<-chart_list[[i]]+theme(legend.position="none")
      }
    }
  }


  #NOTES: in order to add a shared legend, pass in shared_legend = TRUE in the ...
  if(!is.null(align_dir)){
    if(align_dir == "h"){
      combo<-cowplot::plot_grid(plotlist = chart_list, labels = labels, nrow=1,align  = "h",scale=0.97)
    }else if(algin_dir == "v"){
      combo<-cowplot::plot_grid(plotlist = chart_list, ncol=1,labels = labels, align="v")
    }
  }else{
    combo<-cowplot::plot_grid(plotlist = chart_list,labels = labels)
  }

  return(combo)
}

#'
#' Helper function to extract x and y scales from ggplot entity
#' @title ggplot_scale_info
#' @param chart
#'
ggplot_scale_info<-function(chart = NULL,spec_list = NULL){
  chart_info<-ggplot2::ggplot_build(chart)

  x_scale<-chart_info$layout$panel_scales_x[[1]]
  y_scale<-chart_info$layout$panel_scales_y[[1]]


  #x axis
  if("ScaleContinuous" %in% class(x_scale)){
    spec_list$x_limits<-x_scale$range$range
  }else if("ScaleDiscrete" %in% class(x_scale)){
    spec_list$x_labels <- x_scale$range$range
  }

  #y axis
  if("ScaleContinuous" %in% class(y_scale)){
    spec_list$y_limits<-y_scale$range$range
  }else if("ScaleDiscrete" %in% class(y_scale)){
    spec_list$y_labels <- y_scale$range$range
  }

  return(spec_list)

}


