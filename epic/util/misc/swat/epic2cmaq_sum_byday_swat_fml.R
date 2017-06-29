########################################
# Calculate total by regions, crops, and species
# Developed by: Limei Ran & Dongmei Yang
# UNC Institute for the Environment
########################################

# Load required libraries 
if(! require(M3)) stop("Required package M3 could not be loaded")
#library(data.table)

# get file names
scen     <- Sys.getenv("CASE")
day_dir  <- Sys.getenv("DAYDIR")
yearfile <- Sys.getenv("YEARFILE")
sitefile <- Sys.getenv("SITEFILE")
beldfile <- Sys.getenv("BELDFILE")
outname_csv <- Sys.getenv("OUTFILE")
print(paste(">>== year file:   ", yearfile))
print(paste(">>== output file: ", outname_csv))

#region   <- Sys.getenv("REG")
#print(paste(">>== Sum by ", region))

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

# obtain M3 file and file information
projinfo <- get.proj.info.M3(yearfile)
gridinfo <- get.grid.info.M3(yearfile)
print(projinfo)
print(gridinfo)
ncols <- gridinfo$ncols
nrows <- gridinfo$nrows
ncrops <- gridinfo$nlays
grids <- nrows*ncols
garea <- (gridinfo$x.cell.width)*(gridinfo$y.cell.width)

# set up id from bottomleft to upright
id <- c(1:grids)  

# site file: GRIDID,XLONG,YLAT,ELEVATION,SLOPE_P,HUC8,REG10,STFIPS,CNTYFIPS,GRASS,CROPS,TOTAL,COUNTRY,CNTY_PROV
sitetable <- data.frame(read.csv(sitefile,header=TRUE, sep=",", skip=0, na.strings="NA", strip.white=TRUE, nrows=-1))
str(sitetable)

# get crop fraction
beldf <- nc_open(beldfile)
beld.var.names <- names(beldf$var)
print(beld.var.names)
frac.data <- get.M3.var(file = beldfile,
           var="CROPF")  # Time, crop_cat, row, col)

#out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC8=sitetable$HUC8)

# Extract crop data from yearfile
#FLODAY   	Q, QDRN, SSF
#SEDDAY  	MUSL
#ORGNDAY 	YON
#ORGPDAY  	YP
#NO3DAY  	QNO3, SSFN, DRNN
#MINPDAY 	QAP, SSFP?,DRNP?
#NH3DAY  	
#NO2DAY	

# NCD file: Y ,M ,D ,PRCP,   QNO3,   SSFN,   PRKN,     DN,    DN2,   AVOL,    HMN,   NFIX,   FER
# SWAT file: DAY YEAR FLODAY SEDDDAY ORGNDAY ORGPDAY NO3DAY NH3DAY NO2DAY MINPDAY CBODDAY DISOXDAY CHLADAY SOLPSTDAY SRBPSTDAY BACTPDAY BACTLPDAY CMTL1DAY CMTL2DAY CMTL3DAY
#cnames<-c("QNO3")

firstfile <- TRUE 
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
   #daytable <- data.frame(read.csv(dayfile,header=TRUE, sep=",", skip=0, na.strings="NA"))
   #tmp1 = system(paste("cut -f1-41 -d','", dayfile), intern = TRUE)
   daytable = read.csv(pipe(paste("cut -f1-41 -d','", dayfile )), header=TRUE, sep=",")
   if ( length(daytable$Y) == 0 )  next

   str(daytable)
   # get grid ids, 11677030/1000; transfer date to Jdate
   daytable$GRIDID <- floor(daytable$RUN.NAME/1000)
   if ( grepl('FML', scen)>0 ) daytable$GRIDID <- floor(daytable$RUN.NAME/10000)

   indic <- daytable$Y == 2002 
   daytable <- daytable[indic,]
   daytable$DATE   <- paste(daytable$M,daytable$D,daytable$Y, sep="/")
   daytable$DATE   <- as.Date(daytable$DATE, "%m/%d/%Y")
   daytable$DATE   <- format(daytable$DATE, "%m/%d/%Y")
   #daytable$JDATE  <- as.numeric(format(daytable$DATE, "%j"))
   daytable$Floday <- daytable$Q+daytable$QDRN+daytable$SSF
   daytable$Q      <- NULL
   daytable$QDRN   <- NULL
   daytable$SSF    <- NULL
   daytable$No3day <- daytable$QNO3+daytable$SSFN+daytable$DRNN
   daytable$QNO3   <- NULL
   daytable$SSFN   <- NULL
   daytable$DRNN   <- NULL
   daytable$Minpday <- daytable$QAP+daytable$DRNP

   day.df <- data.frame(GRIDID=daytable$GRIDID,DATE=daytable$DATE,Floday=daytable$Floday,Sedday=daytable$MUSL,Orgnday=daytable$YON,Orgpday=daytable$YP,No3day=daytable$No3day,Nh3day=0.0,No2day=0.0,Minpday=daytable$Minpday,Cbodday=0.0,Disoxday=0.0,Chladay=0.0,Solpstday=0.0,Srbpstday=0.0,Bactpday=0.0,Bactlpday=0.0,Cmtl1day=0.0,Cmtl2day=0.0,Cmtl3day=0.0)

   str(day.df)
   # percent file
   perc.df <- data.frame(GRIDID=id, PERC=as.vector(as.matrix(frac.data$data[,,i])))
     
   #rm(daytable)
   perc.df <- na.omit(perc.df)
   crop.df <- merge(x=day.df, y=perc.df, by="GRIDID" )

   #merge with site file to get HUC8 values
   out.df <- data.frame(GRIDID=sitetable$GRIDID, HUC8=sitetable$HUC8)
   out.df <- merge(x=crop.df, y=out.df, by="GRIDID" )

   out.df$AREA <- out.df$PERC*0.01*garea*0.0001
   #FLODAY - Contribution to streamflow for the day (m3)  -Q VAR(14) IN mm PER DAY MUST BE CONVERTED TO M3 I.E.  HECTARES IN GRID CELL IN HUC*10,000 M2*Q/1000 ?

   out.df$Floday  <- out.df$Floday*out.df$AREA*10  
   out.df$Sedday  <- out.df$Sedday*out.df$AREA
   out.df$Orgnday <- out.df$Orgnday*out.df$AREA
   out.df$Orgpday <- out.df$Orgpday*out.df$AREA
   out.df$No3day  <- out.df$No3day*out.df$AREA
   out.df$Minpday <- out.df$Minpday*out.df$AREA

   out.df$GRIDID <- NULL
   out.df$PERC   <- NULL
   out.df$AREA   <- NULL

   str(out.df)
   temp.com.df <-aggregate(.~DATE+HUC8, data=out.df, sum, na.rm=TRUE)

   # separate it by HUC8, save
   if (firstfile)  
   {
     com.df <- temp.com.df
     firstfile <- FALSE
   }

   if ( !firstfile)  
   {
     temp.com.df<- rbind(com.df, temp.com.df)
     com.df <- aggregate(. ~ DATE+HUC8, data=temp.com.df, FUN=sum)
   }
   
}

#com.df$HUC8 <- NULL
spt_huc8  <- split(com.df, com.df$HUC8)
#lapply(names(spt_huc8), function(x){spt_huc8[[x]]["HUC8"]<-NULL; x})  
print(names(spt_huc8))
for ( huc in names(spt_huc8) ) {
    tt.df <-  spt_huc8[[huc]] 
    tt.df$HUC8 <- NULL
    str(tt.df)
    write.table(tt.df, file = paste(outname_csv, huc,"_",scen,".csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")
} 
#lapply(names(spt_huc8), function(x){write.table(spt_huc8[[x]], file = paste(outname_csv, x,"_2002.csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")})

# for QA
com.df$DAY <- NULL
com.df$YEAR<- NULL
com.df$HUC2<- floor(com.df$HUC8/1000000)  
com.df$HUC8 <- NULL

com_huc2.df <- aggregate(. ~ HUC2, data=com.df, FUN=sum)
write.table(com_huc2.df, file = paste(outname_csv, scen,"_QA.csv", sep =""), col.names=T,row.names=F, append=F, quote=F, sep=",")


