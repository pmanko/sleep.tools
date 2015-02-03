## Entering here is: sleep_data, subjects, periods, and nrem_cycles


## Set up for plotting
setup_raster_data <- function(sleep_data, episodes, cycles, bedrest_episodes) {
  
  sleep_data.v <<- copy(sleep_data)
  convert_stage_for_raster(sleep_data.v)
  
  episodes.v <<- copy(episodes)
  
  cycles.v <<- copy(cycles)
  
  bedrest_episodes.v <<- copy(bedrest_episodes)
  
  ## Get Labtimes
  episodes.v[,`:=`(length=convert_length_to_minutes(length))]
  cycles.v[,`:=`(length=convert_length_to_minutes(length))]
  
  ## Set up Days and Day labtimes
  sleep_data.v[,c('day_number','day_labtime'):=set_days(labtime)]
  
  episodes.v[,c('start_day_number', 'start_day_labtime', 'end_day_number', 'end_day_labtime'):=c(set_days(start_labtime),set_days(end_labtime))]
  cycles.v[,c('start_day_number', 'start_day_labtime', 'end_day_number', 'end_day_labtime'):=c(set_days(start_labtime),set_days(end_labtime))]
  bedrest_episodes.v[,c('start_day_number', 'start_day_labtime', 'end_day_number', 'end_day_labtime'):=c(set_days(start_labtime),set_days(end_labtime))]
  
  ## Deal with blocks that span multiple days
  episodes.v <- rbindlist(list(episodes.v[start_day_number==end_day_number], split_day_spanning_blocks(episodes.v[start_day_number!=end_day_number])))
  cycles.v <- rbindlist(list(cycles.v[start_day_number==end_day_number], split_day_spanning_blocks(cycles.v[start_day_number!=end_day_number])))
  bedrest_episodes.v <- rbindlist(list(bedrest_episodes.v[start_day_number==end_day_number], split_day_spanning_blocks(bedrest_episodes.v[start_day_number!=end_day_number])))
  
  ## Re-scale day numbers
  episodes.v[,day_number:=start_day_number]
  bedrest_episodes.v[,day_number:=start_day_number]
  cycles.v[,day_number:=start_day_number]
  episodes.v[,`:=`(start_day_number=NULL, end_day_number=NULL)]
  bedrest_episodes.v[,`:=`(start_day_number=NULL, end_day_number=NULL)]
  cycles.v[,`:=`(start_day_number=NULL, end_day_number=NULL)]
  
  # TODO
  
  

  NULL
}

## Raster plots!
# Plotting
plot_raster <- function(subject_code, epoch_length=EPOCH_LENGTH, output_dir="/home/pwm4/Desktop/", l="",
                        number_of_days=NA, 
                        first_day=1, 
                        cycle_types=c("NREM")
                        ) {  
  # Limit by subject
  subject_list <- c(subject_code)
  
  # Limit by day
  days_to_graph <- unique(sleep_data.v[subject_code %in% subject_list]$day_number)
  if(!is.na(number_of_days))
    days_to_graph <- days_to_graph[first_day:(first_day+number_of_days-1)]
  
  print(days_to_graph)
  
  graph_data <- copy(sleep_data.v[subject_code %in% subject_list & day_number %in% days_to_graph])
  graph_episodes <- copy(episodes.v[subject_code %in% subject_list & day_number %in% days_to_graph & activity_or_bedrest_episode > 0])
  graph_cycles <- copy(cycles.v[subject_code %in% subject_list & day_number %in% days_to_graph & activity_or_bedrest_episode > 0 & type %in% cycle_types])
  graph_bedrest_episodes <- copy(bedrest_episodes.v[subject_code %in% subject_list & day_number %in% days_to_graph])
  
  # Draw
  .e <- environment()

  # Main Plot
  plot <- ggplot(graph_data, aes(x=day_labtime, y=stage_for_raster, group=day_number), environment = .e)
  
  # Labels and theming
  plot <- plot + ggtitle(subject_code)
  plot <- plot + theme(axis.title.y=element_blank(), legend.title=element_blank())
  plot <- plot + xlab("Time (hours)")
  
  # Faceting
  plot <- plot + facet_grid(day_number ~ .)
  
  # Scaling and Margins
  #plot <- plot + theme(panel.margin = unit(0, "npc"))
  y_breaks <- c(-5,-3,-1,0,.5,1.5,2,2.5,3,4)

  plot <- plot + scale_x_continuous(limits=c(0 - epoch_length, 24 + epoch_length), expand=c(0,0), breaks=c(0,12,24), minor_breaks=c(3,6,9,15,18,21)) 
  plot <- plot + scale_y_continuous(limits=c(-6, 4), breaks=y_breaks, labels=lapply(y_breaks,y_axis_formatter))
  
  # Colors
  plot <- plot + scale_fill_manual(values=cbbPalette) + scale_colour_manual(values=cbbPalette)

 
  
  #plot <- plot + scale_fill_manual(values=alpha(c("blue", "red", "black", "purple", "green", "yellow"), 0.8))
  
  ## Episodes and Cycles
  methods <- c('classic', 'iterative', 'changepoint')
  r <- foreach(i=1:length(methods)) %do% {
    end_pos <- i * -2    
    text_y_pos <- end_pos + 0.5
    
    for_this_graph <- graph_cycles[method==methods[i]]
    #print(nrow(for_this_graph))
    #print(end_pos)
    plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length, fill = label), ymin = end_pos+1, ymax = end_pos+2, data = graph_episodes[method==methods[i]])
    plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length), fill=NA, color='black', ymin = end_pos, ymax = end_pos+1, data=for_this_graph)    
    plot <- plot + geom_text(aes(x=(start_day_labtime+end_day_labtime)/2, label=cycle_number), y=text_y_pos, data=for_this_graph)
  }  
  
#  plot <- plot + geom_text(aes(x=(start_day_labtime+end_day_labtime)/2, y=-1.5, label=cycle_number), data=graph_cyles[method=='classic'])
#   plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length, fill = label), ymin = -3, ymax = -2, data = graph_periods[method=="iterative"])
#   plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length), ymin = -4, ymax = -3, data = graph_cyles[method=="iterative"])
#   
#   plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length, fill = label), ymin = -5, ymax = -4, data = graph_periods[method=="changepoint"])
#   plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length), ymin = -6, ymax = -5, data = graph_cyles[method=="changepoint"])
  
  ## Bedrest Episodes
  plot <- plot + geom_rect(aes(NULL, NULL, xmin = start_day_labtime, xmax = end_day_labtime + epoch_length), ymin = 0, ymax = 4, alpha=.5, data = graph_bedrest_episodes)
  
  
  
  #plot <- plot + geom_point(shape='.', size=2)
  plot <- plot + geom_line() #aes(colour=epoch_type)
  
  file_name = file.path(output_dir, paste(subject_code, "_", l, '.svg', sep=''))
  print(file_name)
  print(length(days_to_graph))
  ggsave(plot=plot, file=file_name, height=(length(days_to_graph)*1 + 0.5), width=7, scale=2.5, limitsize=FALSE)
  
  plot

}





## Helpers






split_day_spanning_blocks <- function(dt, t_cycle=T_CYCLE, epoch_length=EPOCH_LENGTH){
  first_division <- dt
  second_division <- copy(dt)
  
  new_end_day_labtime <- t_cycle-epoch_length
  
  first_division[,`:=`(end_day_number=start_day_number, end_day_labtime=new_end_day_labtime)]
  second_division[,`:=`(start_day_number=end_day_number, start_day_labtime=0)]
  
  rbindlist(list(first_division, second_division))
}


convert_length_to_minutes <- function(lengths, epoch_length=EPOCH_LENGTH) {
  lengths * epoch_length * 60
} 

convert_to_labtimes <- function(indeces, sleep_data) {
  sleep_data$labtime[indeces]
  
}

set_days <- function(labtimes, t_cycle=T_CYCLE) {
  day_numbers <- floor(labtimes / t_cycle)
  day_labtimes <- (labtimes - (day_numbers * t_cycle))

  list(day_numbers, day_labtimes)
}

convert_stage_for_raster <- function(d) {
  conv_map <- c(1.5,2,2.5,3,.5,4)
  
  d[epoch_type!='UNDEF', stage_for_raster:=conv_map[stage]]
  d[epoch_type=='UNDEF', stage_for_raster:=0]
}

y_axis_formatter <- function(x) {
  if (x == .5) { res <- "WAKE" }
  else if (x == 1.5) { res <- "Stage 1" }
  else if (x == 2) { res <- "Stage 2" }
  else if (x == 2.5) { res <- "Stage 3" }
  else if (x == 3) { res <- "Stage 4" }
  else if (x == 4) { res <- "REM" }
  else if (x == 0) { res <- "UNDEF"}
  else if (x == -1) { res <- "Classic"}
  else if (x == -3) { res <- "Iterative"}
  else if (x == -5) { res <- "Changepoint"}
  else { res <- as.character(x) }
  
  res
}