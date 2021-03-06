source("R/sources.R")
source("R/plotting/rasters/raster_plot.R")

# Subject Info
subjects <- as.data.table(read.xls("/I/Projects/Forced Desynchrony data projects/FD-info 2016a.xls"))
setnames(subjects, c("Subject", "Age.Group", "Study"), c("subject_code", "age_group", "study"))
subjects[,file_path:=paste("/home/pwm4/Documents/DATAMISSING/", subject_code, "/Sleep/", subject_code, "Slp.01.csv", sep="")]

subjects[,X:=NULL]
subjects[,study:=as.character(study)]
subjects[,subject_code:=as.character(subject_code)]

number_cols <- c('Hab.Wake', 'FD.T.cycle', 'FD.SP.length', 'FD.WP.Length', 'Start.analysis', 'End.Analysis', 'Mel.Tau', 'Mel.Comp.Amp', 'MelAmp.Circad', 'Mel.Comp.Max', 'Mel.Fund.Max', 'CBT.Tau', 'CBT.Comp.Ampl', 'CBTAmp.Circad', 'CBT.Comp.Min', 'CBT.Fund.Min')
for (c in number_cols) set(subjects,j=c,value=as.double(as.character(subjects[[c]])))

setkey(subjects, subject_code)

allowed_subject_codes <- as.character(subjects[grep('Y', get('Permission.'))]$subject_code)

# Protocol Info
protocol_info <- as.data.table(read.xlsx("/X/Manuscripts/Original Report/Inprep/Mankowski Sleep Episode Structure/Figures/subject_rasters/raster_notes.xlsx"))
protocol_info <- protocol_info[use == "Y"]
protocol_info[,c('entrained_from', 'entrained_to'):=as.list(as.numeric(strsplit(entrained, split = ':')[[1]])), by='subject_code']
protocol_info[,c('fd_from', 'fd_to'):=as.list(as.numeric(strsplit(fd, split = ':')[[1]])), by='subject_code']
protocol_info[,c('post_from', 'post_to'):=as.list(as.numeric(strsplit(post, split = ':')[[1]])), by='subject_code']
setkey(protocol_info, subject_code)

## Sleep Data
load_data(subjects = subjects)

##

sleep_episodes <<- sleep_data[activity_or_bedrest_episode>0,data.table(start_labtime=min(labtime), end_labtime=max(labtime)),by='subject_code,activity_or_bedrest_episode']

setup_episodes(sleep_data=sleep_data, full_sleep_data=sleep_data)
setup_cycles(sleep_data, episodes)
setup_melatonin_phase(subjects, sleep_episodes)

setup_raster_data(sleep_data, episodes, cycles, melatonin_phase, normalize_labtime=TRUE, plot_double=FALSE)
plot_raster("3450GX", plot_double=FALSE, labels = FALSE)

subjects[subject_code %in% unique(sleep_data$subject_code),{ plot_raster(subject_code, plot_double=FALSE, labels=FALSE) },by='study,subject_code']


subjects
View(subjects)
