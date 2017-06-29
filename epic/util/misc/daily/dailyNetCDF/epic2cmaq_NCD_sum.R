########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
source("functions_dailyWETH.r")

# get file names
scen     <- Sys.getenv("CASE")
day_dir  <- Sys.getenv("DAYDIR")
metfile  <- Sys.getenv("METFILE")
beldfile <- Sys.getenv("BELDFILE")
outfile <- Sys.getenv("OUTFILE")
print(paste(">>== met file:   ",  metfile))

# obtain M3 file and file information
projinfo <- get.proj.info.M3(metfile)
gridinfo <- get.grid.info.M3(metfile)
print(projinfo)
print(gridinfo)
ncols <- gridinfo$ncols
nrows <- gridinfo$nrows
ncrops <- gridinfo$nlays
grids <- nrows*ncols
garea <- (gridinfo$x.cell.width)*(gridinfo$y.cell.width)

# extract crops
temcrops <- Sys.getenv("CROPS")
temcrops <- toupper(temcrops)
crops    <- (strsplit(temcrops, " +"))[[1]]

allcrops <- c("HAY", "ALFALFA", "OTHER_GRASS", "BARLEY", "EBEANS", "CORNG", "CORNS", "COTTON", "OATS", "PEANUTS", "POTATOES", "RICE", "RYE", "SORGHUMG", "SORGHUMS", "SOYBEANS", "SWHEAT", "WWHEAT", "OTHER_CROP", "CANOLA", "BEANS")

# calculate all crops
if ( "ALL" %in% crops ) crops  <- allcrops
print( crops )

# calculate selected crops
indexs <- which(allcrops %in% crops)
tlays  <- c(indexs*2-1, indexs*2)
tlays  <- sort(tlays)
print( tlays )

id <- c(1:grids)

# get crop fraction
beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

# Extract crop data from yearfile
#FLODAY         Q    Runoff(mm) to m3
#SEDDAY         MUSL Sediment  (kg/ha) to kg
#ORGNDAY        YON  N Loss with Sediment(kg/ha) to kg
#ORGPDAY        YP   P Loss with Sediment(kg/ha to kg
#NO3DAY         QNO3 N Loss in Surface Runoff(kg/ha to kg
#MINPDAY        QAP  Labile P Loss in Runoff(kg/ha to kg
#NH3DAY
#NO2DAY

firstfile <- TRUE
com.df    <- NULL
for ( i in tlays ) {
   print(i)
   dayfile <- paste(day_dir, "/",i,".NCD", sep="")
   print(paste("day file: ",dayfile, sep="") )

   # check if file exist
   if ( file.exists(dayfile))
   {
      print(paste("processing file ", dayfile))
   }
   else
   {
     print(paste("Waring: ", dayfile, " doesn't exist. "))
     next
   }

   # check if file is empty
   if ( file.info(dayfile)$size == 0 ) {
     print(paste("Waring: ", dayfile, " has zero line. "))
     next
   }

   # check if there are any data in file
   daytable <- data.frame(read.csv(dayfile,header=TRUE, sep=",", skip=0, na.strings="NA"))
   if ( length(daytable$Y) == 0 )  next

   #str(daytable)
   # get grid ids, 11677030/1000; transfer date to Jdate
   daytable$GRIDID <- floor(daytable$RUN.NAME/1000)
   if ( grepl('FML', scen)>0 ) daytable$GRIDID <- floor(daytable$RUN.NAME/10000)

   indic <- daytable$Y == 2002
   daytable <- daytable[indic,]
   #daytable$DATE   <- paste(daytable$M,daytable$D,daytable$Y, sep="/")
   #daytable$DATE   <- as.Date(daytable$DATE, "%m/%d/%Y")
   #daytable$DATE   <- format(daytable$DATE, "%m/%d/%Y")
   daytable$DATE <- do.call(paste, list(daytable$M,daytable$D,daytable$Y))
   daytable$DATE <- as.Date(daytable$DATE, format=c("%m %d %Y"))
   daytable$JDATE <- as.numeric(format(daytable$DATE, "%j"))

  #day.df <- data.frame(GRIDID=daytable$GRIDID,DATE=daytable$DATE,Floday=daytable$Q,Sedday=daytable$MUSL,Orgnday=daytable$YON,Orgpday=daytable$YP,No3day=daytable$QNO3,Nh3day=0.0,No2day=0.0,Minpday=daytable$QAP,Cbodday=0.0,Disoxday=0.0,Chladay=0.0,Solpstday=0.0,Srbpstday=0.0,Bactpday=0.0,Bactlpday=0.0,Cmtl1day=0.0,Cmtl2day=0.0,Cmtl3day=0.0)
  day.df <- data.frame(GRIDID=daytable$GRIDID,Q=daytable$Q,MUSL=daytable$MUSL,YON=daytable$YON,YP=daytable$YP,QNO3=daytable$QNO3,QAP=daytable$QAP,L1_ANO3=daytable$L1.ANO3,L1_ANH3=daytable$L1.ANH3,L1_AON=daytable$L1.AON,L1_AMP=daytable$L1.AP,L1_AOP=daytable$L1.AOP,L2_ANO3=daytable$L2.ANO3,L2_ANH3=daytable$L2.ANH3,L2_AON=daytable$L2.AON,L2_AMP=daytable$L2.AP,L2_AOP=daytable$L2.AOP,DATE=daytable$JDATE)

   str(day.df)
   # percent file
   perc.df <- data.frame(GRIDID=id, PERC=as.vector(as.matrix(frac.data$data[,,i])))

   #rm(daytable)
   perc.df <- na.omit(perc.df)
   crop.df <- merge(x=day.df, y=perc.df, by="GRIDID" )

   crop.df$AREA <- crop.df$PERC*0.01*garea*0.0001
   #FLODAY - Contribution to streamflow for the day (m3)  -Q VAR(14) IN mm PER DAY MUST BE CONVERTED TO M3 I.E.  HECTARES IN GRID CELL IN HUC*10,000 M2*Q/1000 ?

   crop.df$Q    <- crop.df$Q*crop.df$AREA*10
   crop.df$MUSL <- crop.df$MUSL*crop.df$AREA
   crop.df$YON  <- crop.df$YON*crop.df$AREA
   crop.df$YP   <- crop.df$YP*crop.df$AREA
   crop.df$QNO3 <- crop.df$QNO3*crop.df$AREA
   crop.df$QAP  <- crop.df$QAP*crop.df$AREA
   crop.df$L1_ANO3 <- crop.df$L1_ANO3*crop.df$AREA
   crop.df$L1_ANH3 <- crop.df$L1_ANH3*crop.df$AREA
   crop.df$L1_AON  <- crop.df$L1_AON*crop.df$AREA
   crop.df$L1_AMP  <- crop.df$L1_AMP*crop.df$AREA
   crop.df$L1_AOP  <- crop.df$L1_AOP*crop.df$AREA
   crop.df$L2_ANO3 <- crop.df$L2_ANO3*crop.df$AREA
   crop.df$L2_ANH3 <- crop.df$L2_ANH3*crop.df$AREA
   crop.df$L2_AON  <- crop.df$L2_AON*crop.df$AREA
   crop.df$L2_AMP  <- crop.df$L2_AMP*crop.df$AREA
   crop.df$L2_AOP  <- crop.df$L2_AOP*crop.df$AREA


   #crop.df$GRIDID <- NULL
   crop.df$PERC   <- NULL
   crop.df$AREA   <- NULL

   #com.df <- aggregate(. ~ DATE, data=crop.df, FUN=sum)
   #if ( !firstfile)
   #{
     com.df<- rbind(com.df, crop.df)
     com.df <- aggregate(. ~ GRIDID + DATE, data=com.df, FUN=sum)
   #}

   #if (firstfile)
   #{
   #  com.df <- crop.df
   #  firstfile <- FALSE
   #}

} 

crop.df$col    <- crop.df$GRIDID %% ncols
crop.df$row    <- floor(crop.df$GRIDID/ncols) + 1
crop.df$GRIDID <- NULL

# Extract crop data from yearfile
#FLODAY         Q    Runoff(mm) to m3
#SEDDAY         MUSL Sediment  (kg/ha) to kg
#ORGNDAY        YON  N Loss with Sediment(kg/ha) to kg
#ORGPDAY        YP   P Loss with Sediment(kg/ha to kg
#NO3DAY         QNO3 N Loss in Surface Runoff(kg/ha to kg
#MINPDAY        QAP  Labile P Loss in Runoff(kg/ha to kg
#NH3DAY
#NO2DAY


cat("m**3, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha, kg/ha\n", file=outfile, append=F)
desc <- paste("Runoff", "Sediment", "N Loss with Sediment","P Loss with Sediment","N Loss in Surface Runoff","Labile P Loss in Runoff", "Layer1 N-NO3 AppRate", "Layer1 N-NH3 AppRate","Layer1 ON AppRate", "Layer1 MP AppRate", "Layer1 OP AppRate", "Layer2 N-NO3 AppRate", "Layer2 N-NH3 AppRate","Layer2 ON AppRate", "Layer2 MP AppRate", "Layer2 OP AppRate", sep=",")
cat(desc,"\n", file=outfile, append=T)
write.table(crop.df, file = outfile, col.names=T,row.names=F, append=T, quote=F, sep=",")

