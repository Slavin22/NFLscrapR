### Make sure you have nflscrapR, sqldf, reshape2, plyr, dplyr packages installed/loaded
### Make sure you have csv's from github.com/Slavin22/NFLscrapR saved in current directory

# Read in Dates + Rosters csv's
dates<-read.csv(file="NFLScrapR_Dates.csv",header=TRUE)
dates$Date<-as.Date(dates$Date)
rosters<-read.csv(file="NFLScrapR_Rosters.csv",header=TRUE)
names(dates)[1]<-"Date"
names(rosters)[1]<-"GSIS_ID"

# Get updated 2018 PBP data
## Instead of pulling straight from nflscrapR, I have manually edited plays that weren't updated after overturned review
## If you want to pull straight from nflscrapR, run: pbp_2018<-season_play_by_play(2018)
pbp_2018<-read.csv(file="PBP_2018_10_18.csv",header=TRUE)
pbp_2018$Date<-as.Date(pbp_2018$Date)

# Get passing data
pbp_passing_2018<-pbp_2018[pbp_2018$PassAttempt==1,]
pbp_passing_2018<-pbp_passing_2018[pbp_passing_2018$PlayType=="Pass",]
pbp_passing_2018<-pbp_passing_2018[is.na(pbp_passing_2018$TwoPointConv),]
pbp_passing_query_2018<-sqldf('select Passer_ID as GSIS_ID, Date, AirYards, Reception, "Yards.Gained", Touchdown, InterceptionThrown from pbp_passing_2018')
pbp_passing_query_2018$Yards.Gained[pbp_passing_query_2018$Reception==0]<-0
pbp_passing_query_2018$Touchdown[pbp_passing_query_2018$Reception==0]<-0
pbp_passing_query_2018$Touchdown[pbp_passing_query_2018$EPA<0]<-0
i<-(-10)
pbp_passing_query_2018$AirYards[pbp_passing_query_2018$AirYards<i]<-i
j<-(-15)
pbp_passing_query_2018$Yards.Gained[pbp_passing_query_2018$Yards.Gained<j]<-j
passing_query_2018<-sqldf('select GSIS_ID, Date, count(GSIS_ID) as PassAttempts, sum(AirYards) as PassAirYards, sum(Reception) as Completions,
                          sum("Yards.Gained") as PassYards, sum(Touchdown) as PassTDs, sum(InterceptionThrown) as INTs
                          from pbp_passing_query_2018 group by GSIS_ID, Date order by GSIS_ID, Date')

# Get rushing data
pbp_rushing_2018<-pbp_2018[pbp_2018$RushAttempt==1,]
pbp_rushing_2018<-pbp_rushing_2018[pbp_rushing_2018$PlayType=="Run",]
pbp_rushing_2018<-pbp_rushing_2018[is.na(pbp_rushing_2018$TwoPointConv),]
pbp_rushing_2018<-pbp_rushing_2018[pbp_rushing_2018$ydstogo>0,]
pbp_rushing_2018$Touchdown[pbp_rushing_2018$EPA<0]<-0
pbp_rushing_query_2018<-sqldf('select Rusher_ID as GSIS_ID, Date, "Yards.Gained", Touchdown, down from pbp_rushing_2018')
j<-(-15)
pbp_rushing_query_2018$Yards.Gained[pbp_rushing_query_2018$Yards.Gained<j]<-j
rushing_query_2018<-sqldf('select GSIS_ID, Date, count(GSIS_ID) as Rushes, sum("Yards.Gained") as RushYards, sum(Touchdown) as RushTDs
                          from pbp_rushing_query_2018 group by GSIS_ID, Date order by GSIS_ID, Date')

# Get receiving data
pbp_receiving_2018<-pbp_2018[pbp_2018$PassAttempt==1,]
pbp_receiving_2018<-pbp_receiving_2018[pbp_receiving_2018$PlayType=="Pass",]
pbp_receiving_2018<-pbp_receiving_2018[is.na(pbp_receiving_2018$TwoPointConv),]
pbp_receiving_query_2018<-sqldf('select Receiver_ID as GSIS_ID, Date, AirYards, Reception, "Yards.Gained", Touchdown from pbp_receiving_2018')
pbp_receiving_query_2018$Yards.Gained[pbp_receiving_query_2018$Reception==0]<-0
pbp_receiving_query_2018$Touchdown[pbp_receiving_query_2018$Reception==0]<-0
pbp_receiving_query_2018$Touchdown[pbp_receiving_query_2018$EPA<0]<-0
i<-(-10)
pbp_receiving_query_2018$AirYards[pbp_receiving_query_2018$AirYards<i]<-i
j<-(-15)
pbp_receiving_query_2018$Yards.Gained[pbp_receiving_query_2018$Yards.Gained<j]<-j
receiving_query_2018<-sqldf('select GSIS_ID, Date, count(GSIS_ID) as Targets, sum(AirYards) as RecAirYards, sum(Reception) as Receptions,
                            sum("Yards.Gained") as RecYards, sum(Touchdown) as RecTDs
                            from pbp_receiving_query_2018 group by GSIS_ID, Date order by GSIS_ID, Date')

# Combine passing/rushing/receiving data + join to get week/player data
weekly<-full_join(passing_query_2018,rushing_query_2018)
weekly<-full_join(weekly,receiving_query_2018)
weekly[is.na(weekly)]<-0
weekly<-left_join(weekly,rosters)
weekly<-left_join(weekly,dates)
weekly<-weekly[weekly$GSIS_ID!="None",]
weekly<-weekly[,c(17:20,3:16)]

# Write output to csv
write.csv(file="NFLScrapR_Weekly.csv",header=TRUE)