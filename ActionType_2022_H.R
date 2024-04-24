call_data <- read.csv("DataSets/2022_H_SQL.csv", sep = ",", header = TRUE)

# type anpassen
OrderNumber <- as.character(c(call_data$OrderNumber))
ActionType <- as.numeric(c(call_data$ActionType))
Creation <- as.POSIXct(call_data$Creation)

#dataframe
df <- data.frame(OrderNumber,ActionType, Creation)

#check types: OrderNumber - factor; Actiontype - numeric
types_ <- sapply(df, class)

############################################################################################################
# 17-Anlage; 2-Erfassung; 31-diktat; 68-Freigegeben; 71-Mikroskopie
target_actionType <- c(17,2)
t17 <- c(17)
t2 <- c(2)
t31 <- c(31)   #for 2023 is 69-Makroskopie
t68 <- c(68)
t71 <- c(71)

# create a vector to record Events which showed
visited_events <- c()
visited_events_mint31 <- c()
visited_events_mint68 <- c()
visited_events_mint71 <- c()

target_OrderNumber  <- c()
target_Ordernumber_mint31 <- c()
target_Ordernumber_mint68 <- c()
target_Ordernumber_mint71 <- c()

for(value in df$OrderNumber){
  if(value %in% visited_events){
    next
  }
  
  duplicated_rows <- df[df$OrderNumber == value, ]
  #target_OrderNumber <- duplicated_rows[ave(duplicated_rows$ActionType %in% target_actionType,
  #                                        duplicated_rows$OrderNumber,FUN=all), ]
  
  target_OrderNumber_tmp <- duplicated_rows[duplicated_rows$ActionType %in% target_actionType,]
  
  
  if(nrow(target_OrderNumber_tmp) > 0 && any(target_OrderNumber_tmp$ActionType ==  t17)
     && any(target_OrderNumber_tmp$ActionType == t2) ){
    
    target_OrderNumber <- rbind(target_OrderNumber, target_OrderNumber_tmp)
  }
  
  visited_events <- c(visited_events, value)
}
target_OrderNumber <- target_OrderNumber[order(target_OrderNumber$OrderNumber, -target_OrderNumber$ActionType), ]
#print(target_OrderNumber)
#View(target_OrderNumber)
#print(visited_events) 

#print(length(visited_events))  

##########################first Diktat 31################################

for(value_mint31 in df$OrderNumber){
  if(value_mint31 %in% visited_events_mint31){
    next
  }
  duplicated_rows_mint31 <- df[df$OrderNumber == value_mint31, ]
  
  target_Ordernumber_mint31_tmp <- duplicated_rows_mint31[duplicated_rows_mint31$ActionType %in% t31, ]
  #print(target_Ordernumber_mint31_tmp)

  if(nrow(target_Ordernumber_mint31_tmp > 0) && any(target_Ordernumber_mint31_tmp$ActionType == t31)){
    
    min_t31<- min(target_Ordernumber_mint31_tmp$Creation[target_Ordernumber_mint31_tmp$ActionType == t31])
    
    target_Ordernumber_mint31_ <- target_Ordernumber_mint31_tmp[target_Ordernumber_mint31_tmp$Creation == min_t31, ]
    target_Ordernumber_mint31 <- rbind(target_Ordernumber_mint31, target_Ordernumber_mint31_)
    # print(target_Ordernumber_mint31_)
    
  }
  visited_events_mint31 <- c(visited_events_mint31, value_mint31)
  
}
#print(target_Ordernumber_mint31)

##########################first Freigegeben 68 ################################

for(value_mint68 in df$OrderNumber){
  if(value_mint68 %in% visited_events_mint68){
    next
  }
  
  duplicated_rows_mint68 <- df[df$OrderNumber == value_mint68, ]
  
  target_Ordernumber_mint68_tmp <- duplicated_rows_mint68[duplicated_rows_mint68$ActionType %in% t68, ]
  #print(target_Ordernumber_mint68_tmp)
  if(nrow(target_Ordernumber_mint68_tmp > 0) && any(target_Ordernumber_mint68_tmp$ActionType == t68)){
    
    min_t68<- min(target_Ordernumber_mint68_tmp$Creation[target_Ordernumber_mint68_tmp$ActionType == t68])
   
    target_Ordernumber_mint68_ <- target_Ordernumber_mint68_tmp[target_Ordernumber_mint68_tmp$Creation == min_t68, ]
    target_Ordernumber_mint68 <- rbind(target_Ordernumber_mint68, target_Ordernumber_mint68_)
    # print(target_Ordernumber_mint68_)
  }
  
  visited_events_mint68 <- c(visited_events_mint68, value_mint68)
  
}


##########################first Mikroskopie 71 ################################
for(value_mint71 in df$OrderNumber){
  if(value_mint71 %in% visited_events_mint71){
    next
  }

  duplicated_rows_mint71 <- df[df$OrderNumber == value_mint71, ]
  
  target_Ordernumber_mint71_tmp <- duplicated_rows_mint71[duplicated_rows_mint71$ActionType %in% t71, ]
  
  if(nrow(target_Ordernumber_mint71_tmp > 0) && any(target_Ordernumber_mint71_tmp$ActionType == t71)){
    
    min_t71<- min(target_Ordernumber_mint71_tmp$Creation[target_Ordernumber_mint71_tmp$ActionType == t71])
    
    target_Ordernumber_mint71_ <- target_Ordernumber_mint71_tmp[target_Ordernumber_mint71_tmp$Creation == min_t71, ]
    target_Ordernumber_mint71 <- rbind(target_Ordernumber_mint71, target_Ordernumber_mint71_)
  
  }
  visited_events_mint71 <- c(visited_events_mint71, value_mint71)

}

#print(target_Ordernumber_mint71)

#17,2,31
result_ <- rbind(target_OrderNumber[target_OrderNumber$OrderNumber %in% target_Ordernumber_mint31$OrderNumber, ],
                 target_Ordernumber_mint31[target_Ordernumber_mint31$OrderNumber %in% target_OrderNumber$OrderNumber, ])

#print(result_)
#View(result_)
#17,2,31,68
result_1 <- rbind(result_[result_$OrderNumber %in% target_Ordernumber_mint68$OrderNumber, ],
                  target_Ordernumber_mint68[target_Ordernumber_mint68$OrderNumber %in% result_$OrderNumber, ])

#17,2,31,68,71
result_2 <- rbind(result_1[result_1$OrderNumber %in% target_Ordernumber_mint71$OrderNumber, ],
                  target_Ordernumber_mint71[target_Ordernumber_mint71$OrderNumber %in% result_1$OrderNumber, ])

#ordered_result <- result_[order(result_$OrderNumber), ]
#ordered_result_1 <- result_1[order(result_1$OrderNumber), ]
ordered_result_2_R <- result_2[order(result_2$OrderNumber), ]


# 5 Minuten -- end_table of H-2022
print(ordered_result_2_R)
View(ordered_result_2_R)
#write.csv(ordered_result_2_R, file = "C:\\Users\\hao\\R/2022_H_5AcTy.csv",fileEncoding = "UTF-8", row.names = FALSE)

