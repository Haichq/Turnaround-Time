call_data <- read.csv("DataSets/2022_H_5AcTy.csv", sep = ",", header = TRUE)

OrderNumber <- as.character(c(call_data$OrderNumber))
ActionType <- as.numeric(c(call_data$ActionType))
Creation <- as.POSIXct(call_data$Creation)

#dataframe
df <- data.frame(OrderNumber,ActionType, Creation)

subsets <- split(df, df$OrderNumber)
#print(subsets)

deleted_subsets <- c()
negative_ <- c()

for(subsets_name in names(subsets)){
  subset <- subsets[[subsets_name]]
  #print(subset)
  rows <- nrow(subset)
  for (i in 2:rows){
    # delete the events which turnaround time is negative
    deleted_subsets_tmp <- subset$OrderNumber[subset$Creation[i] < subset$Creation[i-1]]
    #sum of turnaround time for each event
    sum_turnaround_eachEvents <-as.numeric(sum(subset$Creation[i] - subset$Creation[i-1]))
    negative_tmp <- subset$OrderNumber[sum_turnaround_eachEvents < 0]
    
    if(length(negative_tmp)>0){
      negative_ <- c(negative_, negative_tmp)
      
    }
  }
 
  deleted_subsets <- c(deleted_subsets, deleted_subsets_tmp)
  
}

deleted_subsets <- unique(deleted_subsets)  # 416
#print(length(deleted_subsets))
unique_df_OrderN <- unique(df$OrderNumber)  # 3297
#print(length(unique_df_OrderN))
unique_negative_ <- unique(negative_)  # 1598
#print(length(unique_negative_))

filtered_req_OrderN <- unique_df_OrderN[(!(unique_df_OrderN %in% deleted_subsets))  & (!(unique_df_OrderN %in% unique_negative_))] # ordernumber which needed/filtered

final_result_1699 <- df[df$OrderNumber %in% filtered_req_OrderN, ]
#print(final_result_1699)
#View(final_result_1699)
#write.csv(final_result_1699, file = "C:\\Users\\hao\\R/2022_H_1699_R.csv",fileEncoding = "UTF-8", row.names = FALSE)

amount_filtered_events <- length(final_result_1699$OrderNumber) / 5  #1699
print(amount_filtered_events)
