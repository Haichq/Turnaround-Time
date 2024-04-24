
call_data <- read.csv("DataSets/2022_H_1699_R.csv", sep = ",", header = TRUE)

OrderNumber <- as.character(c(call_data$OrderNumber))
ActionType <- as.numeric(c(call_data$ActionType))
Creation <- as.POSIXct(call_data$Creation)

#dataframe
final_result_1699 <- data.frame(OrderNumber,ActionType, Creation)
amount_filtered_events <- length(final_result_1699$OrderNumber) / 5  #1699
#print(amount_filtered_events)


at17 <- which(final_result_1699$ActionType == 17)
at2 <- which(final_result_1699$ActionType == 2)
at31 <- which(final_result_1699$ActionType == 31)
at68 <- which(final_result_1699$ActionType == 68)
at71 <- which(final_result_1699$ActionType == 71)

creation17 <- final_result_1699$Creation[at17]
creation2 <- final_result_1699$Creation[at2]
creation31 <- final_result_1699$Creation[at31]
creation68 <- final_result_1699$Creation[at68]
creation71 <- final_result_1699$Creation[at71]

avg_anl_erf <- as.numeric(sum((difftime(creation2, creation17, units = "mins")) / amount_filtered_events)) #29.29814 mins
#print(avg_anl_erf)
avg_erf_dik <- as.numeric(sum((difftime(creation31, creation2, units = "mins")) / amount_filtered_events)) #1109.772 mins
#print(avg_erf_dik)
avg_dik_frei <- as.numeric(sum((difftime(creation68, creation31, units = "mins")) / amount_filtered_events)) #2570.859 mins
#print(avg_dik_frei)
avg_frei_mik <- as.numeric(sum((difftime(creation71, creation68, units = "mins")) / amount_filtered_events)) #1089.234mins
#print(avg_frei_mik)
avg_total <- sum(c(avg_anl_erf, avg_erf_dik, avg_dik_frei, avg_frei_mik)) #4799.163 mins
#print(avg_total)

#####################faster/slower Events####################
### faster events: turnaround time less then avg. total time
### slower events: turnaround time more than avg. total time


subsets <- split(final_result_1699, final_result_1699$OrderNumber)
#print(subsets)
init_time <- numeric(length(subsets))

sum_turnaround_eachEvents <- c()

#faster
faster_events <- c()
#slower
slower_events <- c()
#####################################################################

for(i in 1:length(subsets)){
  subset <- subsets[[i]]
  diff_time <-  difftime(subset$Creation[5], subset$Creation[1], units = "mins")
  init_time[i] <- sum(as.numeric(diff_time))
  
  #faster
  faster_events_tmp <- subset$OrderNumber[init_time[i] <= avg_total]
  if(length(faster_events_tmp) > 0){
    faster_events <- c(faster_events, faster_events_tmp)
  }
  #slower
  slower_events_tmp <- subset$OrderNumber[init_time[i] > avg_total]
  if(length(slower_events_tmp) > 0){
    slower_events <- c(slower_events, slower_events_tmp)
  }
  
}

faster_events <- unique(faster_events)
slower_events <- unique(slower_events)
amount_faster <- length(faster_events) #1072 Evetns  faster 
#print(amount_faster) 
amount_slower <- length(slower_events) #627 events slower
#print(amount_slower)
